//
//  MasterViewController.swift
//  LessonBook
//
//  Created by Michael Toth on 1/27/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import UIKit
import CoreData
import CloudKit


class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    
    
    
    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    var students:[CKRecord] = []
    private var database = CKContainer.default().privateCloudDatabase


    let container = CKContainer.default()

    // Store these to disk so that they persist across launches
    var createdCustomZone = false
    var subscribedToPrivateChanges = false
    var subscribedToSharedChanges = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let privateDB = container.privateCloudDatabase
        let sharedDB = container.sharedCloudDatabase

        // Use a consistent zone ID across the user's devices
        // CKCurrentUserDefaultName specifies the current user's ID when creating a zone ID
        let zoneID = CKRecordZone.ID(zoneName: "LessonBook", ownerName: CKCurrentUserDefaultName)
        
        
        let privateSubscriptionId = "private-changes"
        let sharedSubscriptionId = "shared-changes"

        
        let createZoneGroup = DispatchGroup()
        
        if !self.createdCustomZone {
            createZoneGroup.enter()
            
            let customZone = CKRecordZone(zoneID: zoneID)
            
            let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [] )
            
            createZoneOperation.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
                if (error == nil) { self.createdCustomZone = true }
                // else custom error handling
                createZoneGroup.leave()
            }
            createZoneOperation.qualityOfService = .userInitiated
            
            privateDB.add(createZoneOperation)
        }

        if !self.subscribedToPrivateChanges {
            let createSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId: privateSubscriptionId)
            createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
                if error == nil { self.subscribedToPrivateChanges = true }
                // else custom error handling
            }
            privateDB.add(createSubscriptionOperation)
        }
        
        if !self.subscribedToSharedChanges {
            let createSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId: sharedSubscriptionId)
            createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
                if error == nil { self.subscribedToSharedChanges = true }
                // else custom error handling
            }
            sharedDB.add(createSubscriptionOperation)
        }
        
        // Fetch any changes from the server that happened while the app wasn't running
        createZoneGroup.notify(queue: DispatchQueue.global()) {
            if self.createdCustomZone {
                self.fetchChanges(in: .private) {}
                //self.fetchChanges(in: .shared) {}
            }
        }
        
        
        
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        CKContainer.default().fetchUserRecordID(completionHandler: {(record,error) in
            if let error = error {
                print(error)
            } else {
                print(record!)
            }
        })
        fetchStudents()
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    func insertNewStudent(_ sender: Any) {
        
    }
    @objc
    func insertNewObject(_ sender: Any) {
        //let context = self.fetchedResultsController.managedObjectContext
        //let newStudent = Student(context: context)
        let newStudent = CKRecord.init(recordType: "Student")
        
        // If appropriate, configure the new managed object.
        newStudent.setValue("New", forKey: "firstName")
        newStudent.setValue("Student", forKey: "lastName")
        
        students.append(newStudent)
       
        print("appended")
        database.save(newStudent, completionHandler: {r,err in
            if let err = err {
                print(err.localizedDescription)
            } else {
                print("Student Saved")
                DispatchQueue.main.sync {
                    self.tableView.reloadData()
                }
            }
        })
        


    }
    
    
    
    func fetchDatabaseChanges(database: CKDatabase, databaseTokenKey: String, completion: @escaping () -> Void) {
        var changedZoneIDs: [CKRecordZone.ID] = []
        
        let changeToken = UserDefaults.standard.serverChangeToken
        // Read change token from disk
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)
        
        operation.recordZoneWithIDChangedBlock = { (zoneID) in
            changedZoneIDs.append(zoneID)
        }
        
        operation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
            // Write this zone deletion to memory
        }
        
        operation.changeTokenUpdatedBlock = { (token) in
            // Flush zone deletions for this database to disk
            
            // Write this new database change token to memory
            UserDefaults.standard.serverChangeToken = token
        }
        
        operation.fetchDatabaseChangesCompletionBlock = { (token, moreComing, error) in
            if let error = error {
                print("Error during fetch shared database changes operation", error)
                completion()
                return
            }
            // Flush zone deletions for this database to disk
            // Write this new database change token to memory
            
            
            self.fetchZoneChanges(database: database, databaseTokenKey: databaseTokenKey, zoneIDs: changedZoneIDs) {
                // Flush in-memory database change token to disk
                completion()
            }
        }
        operation.qualityOfService = .userInitiated
        
        database.add(operation)
    }
    
    func fetchChanges(in databaseScope: CKDatabase.Scope, completion: @escaping () -> Void) {
        switch databaseScope {
        case .private:
            fetchDatabaseChanges(database: self.privateDB, databaseTokenKey: "private", completion: completion)
        case .shared:
            fetchDatabaseChanges(database: self.sharedDB, databaseTokenKey: "shared", completion: completion)
        case .public:
            fatalError()
        }
    }
    
    
    
    
    func createDatabaseSubscriptionOperation(subscriptionId: String) -> CKModifySubscriptionsOperation {
        let subscription = CKDatabaseSubscription.init(subscriptionID: subscriptionId)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        // send a silent notification
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.qualityOfService = .utility
        
        return operation
    }
    
    
    
    
    // MARK: - Student Operations
    func fetchStudents() {
        
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "Student", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [unowned self] results, error in
            if let error = error {
                DispatchQueue.main.async {
                    //self.delegate?.errorUpdating(error as NSError)
                    print("Cloud Query Error - Fetch Establishments: \(error)")
                }
                return
            }
            self.students.removeAll(keepingCapacity: false)
            results?.forEach({ (record: CKRecord) in
                self.students.append(record)
            })
            DispatchQueue.main.async {
                //self.delegate?.modelUpdated()
                print("Retrieved \(self.students.count) students")
                self.tableView.reloadData()
            }
        }
    }


    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let student = students[indexPath.row]
                
                //let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.studentItem = student
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: -- TABLE VIEW
    func numberOfRows(in tableView: UITableView) -> Int {
        return self.students.count
    }
    
     // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.students.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let student = students[indexPath.row]
        // configureCell(cell, withEvent: event)
        configureStudentCell(cell, withStudent: student)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let student = students[indexPath.row]
            students.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            database.delete(withRecordID: student.recordID, completionHandler: {id,err in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("record deleted")
                }
            })
            
        }
    }

    func configureCell(_ cell: UITableViewCell, withEvent event: Event) {
        cell.textLabel!.text = event.timestamp!.description
    }
    
    func configureStudentCell(_ cell: UITableViewCell, withStudent student: CKRecord) {
        cell.textLabel!.text = (student.value(forKey: "firstName") as? String)! + " " + (student.value(forKey: "lastName") as? String)!
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<Event> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             let nserror = error as NSError
             fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController<Event>? = nil

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Event)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Event)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    func fetchStudents(_ location:CLLocation, radiusInMeters:CLLocationDistance) {
        
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "Student", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [unowned self] results, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("Cloud Query Error - Fetch Students: \(error)")
                }
                return
            }
            self.students.removeAll(keepingCapacity: true)
            results?.forEach({ (record: CKRecord) in
                self.students.append(record)
            })
            DispatchQueue.main.async {
                self.studentsUpdated()
            }
        }
    }
    
    func studentsUpdated() {
        
    }
    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         tableView.reloadData()
     }
     */

}


public extension UserDefaults {
    
    public var serverChangeToken: CKServerChangeToken? {
        get {
            guard let data = self.value(forKey: "ChangeToken") as? Data else {
                return nil
            }
            
            let token: CKServerChangeToken?
            do {
                token = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
            } catch {
                token = nil
            }
            
            return token
        }
        set {
            if let token = newValue {
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false)
                    self.set(data, forKey: "ChangeToken")
                } catch {
                    // handle error
                }
            } else {
                self.removeObject(forKey: "ChangeToken")
            }
        }
    }
}
