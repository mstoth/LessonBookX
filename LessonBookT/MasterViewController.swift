//
//  MasterViewController.swift
//  LessonBookT
//
//  Created by Michael Toth on 2/2/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    private var database = CKContainer.default().privateCloudDatabase
    let zoneID = CKRecordZone.ID(zoneName: "LessonBook", ownerName: CKCurrentUserDefaultName)
    
    var z:ZoneOperations? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        let containerIdentifier = String(CKContainer.default().containerIdentifier!)
//        let lessonBookLoc = containerIdentifier.lastIndex(of: "k")!
//        let newContainerIdentifier = containerIdentifier[...lessonBookLoc]
//        database = CKContainer.init(identifier: String(newContainerIdentifier)).privateCloudDatabase

        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        z = ZoneOperations()

        // print(database)
        // [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(newCloudData) name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil];
//        let predicate = NSPredicate(value: true)
//        //let subscription = CKQuerySubscription(recordType: "Student", predicate: predicate,options:.firesOnRecordUpdate | .firesOnRecordDeletion | .firesOnRecordCreation)
//        let subscription = CKQuerySubscription(recordType: "Student", predicate: predicate,options:.firesOnRecordCreation)
//        let notificationObject = CKSubscription.NotificationInfo.init()
//        notificationObject.alertLocalizationKey = "Student Created"
//        subscription.notificationInfo = notificationObject
        
//        database.fetchAllSubscriptions(completionHandler: {(sub,err) in
//            for s:CKSubscription in sub! {
//                self.database.delete(withSubscriptionID: s.subscriptionID, completionHandler: {(sub,err) in
//                    if let err = err {
//                        print(err.localizedDescription)
//                    } else {
//                        // nothing to do
//                        print("Deleted subscription")
//                        print(s.subscriptionID)
//                    }
//                })
//            }
//
//            let notificationInfo:CKSubscription.NotificationInfo = CKSubscription.NotificationInfo.init()
//            notificationInfo.alertLocalizationKey = "Student Changed"
//            notificationInfo.shouldBadge = true
//
//            subscription.notificationInfo = notificationInfo
//            self.database.save(subscription, completionHandler: {(s,error) in
//                if ((error) != nil) {
//                    print("Subscription error")
//                    print(error?.localizedDescription as Any)
//                } else {
//                    print("Subscribed")
//                    print(s!.subscriptionID)
//                }
//            })
//
//        })
        
        //NotificationCenter.default.addObserver(self, selector: #selector(newCloudData), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil)
        
        
    }

    func setDataBase(_ db:CKDatabase) {
        database = db
    }
    
    @objc func newCloudData(notification:Notification) {
        let userInfo = notification.userInfo
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    func updateLocalRecords(changedRecords: [CKRecord], deletedRecordIDs: [CKRecord.ID]) {
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        delegate.updateContext.perform {
            
            let changedRecordNames = changedRecords.map { $0.recordID.recordName }
            let deletedRecordNames = deletedRecordIDs.map { $0.recordName }
            self.updateObject(students: changedRecordNames)
            self.deleteObject(students: deletedRecordNames)
            self.saveUpdateContext()
        }
    }
    
    func updateObject(students:[String]) {
        
    }
    
    func deleteObject(students:[String]) {
        
    }
    
    func saveUpdateContext() {
        
    }
    
    @objc
    func insertNewObject(_ sender: Any) {
        let context = self.fetchedResultsController.managedObjectContext
        //let newEvent = Event(context: context)
        let newStudent = Student(context: context)
        newStudent.prepareForCloudKit()
        let ccr = newStudent.cloudKitRecord()
        
        newStudent.firstName = "New"
        newStudent.lastName = "Student"
        newStudent.phone = ""
        newStudent.recordID = newStudent.ckrecordID
        
        ccr!.setValue("New", forKey: "firstName")
        ccr!.setValue("Student", forKey: "lastName")
        ccr!.setValue("", forKey: "phone")
        // If appropriate, configure the new managed object.
        // newEvent.timestamp = Date()
        // let insertedObjects = context.insertedObjects
        // let modifiedObjects = context.updatedObjects
        // let deletedRecordIDs = context.deletedObjects.map { ($0 as! CloudKitManagedObject).cloudKitRecordID() }
        if context.hasChanges {
            do {
                try context.save()
                print("new student saved to core data")
            } catch {
                print(error.localizedDescription)
            }
            // let insertedObjectIDs = insertedObjects.map { $0 .objectID }
            // let modifiedObjectIDs = modifiedObjects.map { $0 .objectID }
            
            database.save(ccr!, completionHandler: {(rec,err) in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("new student saved to cloud")
                }
            })
            
        }
        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    
    func addCloudKitRecordToCoreData(_ ckRecord:CKRecord) {
        //let delegate = NSApp.delegate as! AppDelegate
        //let context = delegate.persistentContainer.viewContext
        
        let newStudent = Student(context: managedObjectContext!)
        newStudent.prepareForCloudKitWithCloudKitRecord(ckRecord.recordID)
        newStudent.firstName = ckRecord["firstName"]
        newStudent.lastName = ckRecord["lastName"]
        newStudent.phone = ckRecord["phone"]
        
        do {
            try managedObjectContext?.save()
//            coreDataStudents.append(newStudent)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }

    
    
    func fetchAndAddRecordToCoreData(_ recordID:CKRecord.ID) {
        database.fetch(withRecordID: recordID, completionHandler: { (r,err) in
            if let err = err {
                print(err.localizedDescription)
            } else {
                self.addCloudKitRecordToCoreData(r!)
                print(r?.value(forKey: "firstName") ?? "No Name")
                
            }
        })
    }
    
    
    func updateRecordInCoreData(_ recordID:CKRecord.ID) {
        let recordName = recordID.recordName
        let predicate = NSPredicate(format: "recordName == %@", recordName)
        let fetchRequest = NSFetchRequest<Student>(entityName: "Student")
        fetchRequest.predicate = predicate
        do {
            let students = try managedObjectContext?.fetch(fetchRequest)
            for s:Student in students! {
                database.fetch(withRecordID: s.cloudKitRecordID()!, completionHandler: {(r,err) in
                    if let err = err {
                        print(err.localizedDescription)
                    } else {
                        s.firstName = r?["firstName"]
                        s.lastName = r?["lastName"]
                        s.phone = r?["phone"]
                    }
                })
            }
            DispatchQueue.main.async {
                do {
                    try self.managedObjectContext!.save()
                    self.tableView.reloadData()
                } catch {
                    print(error.localizedDescription)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    
    
    func recordRemovedFromCloudKit(_ recordID:CKRecord.ID) {
        // var row = 0
        let recordName = recordID.recordName
        let predicate = NSPredicate(format: "recordName == %@", recordName)
        let fetchRequest = NSFetchRequest<Student>(entityName: "Student")
        fetchRequest.predicate = predicate
        do {
            let students = try managedObjectContext?.fetch(fetchRequest)
            for s:Student in students! {
                managedObjectContext?.delete(s)
            }
        } catch {
            print(error)
        }
//        for s:Student in coreDataStudents {
//            if s.cloudKitRecordID() == recordID {
//                context?.delete(s)
//                do {
//                    try context?.save()
//                    coreDataStudents.remove(at: row)
//                } catch {
//                    print(error.localizedDescription)
//                }
//            }
//            row = row + 1
//        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
            let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let event = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withEvent: event)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = fetchedResultsController.managedObjectContext
            
            let studentToDelete = fetchedResultsController.object(at: indexPath)
            let ckRecordToDelete = CKRecord(recordType: "Student", recordID: studentToDelete.cloudKitRecordID()!)
            database.delete(withRecordID: ckRecordToDelete.recordID, completionHandler: {(id,err) in
                if let err = err {
                    print(err)
                }
            })
//            if studentToDelete.recordName != nil {
//                studentToDelete.ckrecordID = studentToDelete.recordID
//                database.delete(withRecordID: studentToDelete.cloudKitRecordID()!, completionHandler: {id,err in
//                    if let err = err {
//                        print(err.localizedDescription)
//                    } else {
//                        print("record deleted from cloud")
//                    }
//                })
//
//            }
            
            
            context.delete(fetchedResultsController.object(at: indexPath))
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func configureCell(_ cell: UITableViewCell, withEvent student: Student) {
        cell.textLabel!.text = student.fullName()
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<Student> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Student> = Student.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "lastName", ascending: false)
        
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
    var _fetchedResultsController: NSFetchedResultsController<Student>? = nil

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
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Student)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Student)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         tableView.reloadData()
     }
     */

}

