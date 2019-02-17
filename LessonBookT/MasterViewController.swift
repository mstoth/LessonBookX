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
        managedObjectContext = self.fetchedResultsController.managedObjectContext

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
        
        // NotificationCenter.default.addObserver(self, selector: #selector(newCloudData), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil)
        if let managedObjectContext = managedObjectContext {
            // Add Observer
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
            notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsWillSave), name: NSNotification.Name.NSManagedObjectContextWillSave, object: managedObjectContext)
            notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidSave), name: NSNotification.Name.NSManagedObjectContextDidSave, object: managedObjectContext)
        }
    
        
        
    }


    @objc func managedObjectContextObjectsWillSave(notification: NSNotification) {
        // guard let userInfo = notification.userInfo else { return }
        
    }
    

    @objc func managedObjectContextObjectsDidSave(notification: NSNotification) {
        // guard let userInfo = notification.userInfo else { return }
    }
    


    @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
        print("Context Object Did Change.")
        guard let userInfo = notification.userInfo else { return }
        
        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<Student>, inserts.count > 0 {
            for s:Student in inserts {
                //addCoreDataRecordToCloud(s)
                if s.recordName == nil {
                    s.prepareForCloudKit()
                    s.recordName = s.cloudKitRecordID()?.recordName
                    let ccr = s.cloudKitRecord()
                    ccr?["firstName"]=s.firstName
                    ccr?["lastName"]=s.lastName
                    ccr?["phone"]=s.phone
                    ccr?["recordName"]=s.recordName
                    database.save(ccr!, completionHandler: {(r,err) in
                        if let err = err {
                            print(err)
                        } else {
                            print("Saved record to cloud")
                        }
                    })
                    
                } else {
                    let ccr = s.cloudKitRecord()
                    ccr?["firstName"]=s.firstName
                    ccr?["lastName"]=s.lastName
                    ccr?["phone"]=s.phone
                    ccr?["recordName"]=s.recordName
                    database.save(ccr!, completionHandler: {(r,err) in
                        if let err = err {
                            print(err)
                        } else {
                            print("Saved record to cloud")
                        }
                    })

                }
                DispatchQueue.main.async {
                    do {
                        try self.managedObjectContext?.save()
                    } catch {
                        print(error)
                    }
                }
            }
        }
        
        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<Student>, updates.count > 0 {
            print("Core Data Changed Notification")
            for s:Student in updates {
                let recordName = s.recordName
                let recordID=s.cloudKitRecordID()
                print(recordName as Any)
                database.fetch(withRecordID: recordID!, completionHandler: {(r,err) in
                    if err != nil {
                        let ckerror = err as! CKError
                        if ckerror.code == CKError.unknownItem {
                            // let ckr = s.cloudKitRecord()
                            print("Unknown Item")
                            let recordID = CKRecord.ID(recordName: s.recordName!, zoneID: s.zoneID())
                            let r = CKRecord(recordType: "Student", recordID: recordID)
                            
                            r["phone"]=s.phone
                            r["firstName"]=s.firstName
                            r["lastName"]=s.lastName
                            r["recordName"]=s.cloudKitRecordID()?.recordName
                            
                            self.database.save(r, completionHandler: {(r,err) in
                                if let err = err {
                                    print("error from saving update to cloud")
                                    print(err.localizedDescription)
                                } else {
                                    print("saved record to cloud for update")
                                    print(s.cloudKitRecord()?.recordID.recordName as Any)
                                }
                            })

                        } else {
                            print("Unknown error from fetch.")
                            print(ckerror.localizedDescription)
                        }
                        
                    } else {
                        print("Setting Record Values")
//                        let recordID = CKRecord.ID(recordName: s.recordName!, zoneID: s.zoneID())
//                        let r = CKRecord(recordType: "Student", recordID: recordID)

                        r?["phone"]=s.phone
                        r?["firstName"]=s.firstName
                        r?["lastName"]=s.lastName
                        r?["recordName"]=s.recordName
//                        self.save(record: r!, completion:{ e in
//                            if e != nil {
//                                print(e as Any)
//                            }
//                        })
                        let recordArray = [r!]
                        print(String(describing: recordArray))
                        let modifyRecords = CKModifyRecordsOperation.init(recordsToSave: recordArray, recordIDsToDelete: [])
                        // modifyRecords.recordsToSave = recordArray
                        modifyRecords.savePolicy = .allKeys
                        modifyRecords.qualityOfService = .background
                        self.database.add(modifyRecords)
//                        let saveOper = CKModifyRecordsOperation()
//                        saveOper.recordsToSave = [r!]
//                        saveOper.savePolicy = .allKeys
//                        // let deletedRecordIDs:[CKRecord.ID] = []
//                        saveOper.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
//                            if error != nil {
//                                print(error as Any)
//                            }
//                            if saveOper.isFinished == true {
//                                print("save operation is true")
//                            }
//                        }
//                        self.database.add(saveOper)
                        self.database.save(r!, completionHandler: {(r,err) in
                            if err != nil {
                                print(err as Any)
                            } else {
                                print("Saved record to cloud.")
                            }
                        })
                    }
                })
                //updateRecordOnCloud(s.cloudKitRecordID()!)
            }
        }
        
        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<Student>, deletes.count > 0 {
            for s:Student in deletes {
                let recordID = CKRecord.ID(recordName: s.recordName!, zoneID: s.zoneID())
                database.delete(withRecordID: recordID, completionHandler: {(rid,err) in
                    if let err = err {
                        print(err.localizedDescription)
                    } else {
                        print("student deleted from cloud")
                    }
                })
            }
        }
    }

    public func save(record: CKRecord, completion: @escaping (Error?) -> Void)
    {
        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: [])
        modifyRecordsOperation.modifyRecordsCompletionBlock = { _, _, error in
            guard error == nil else {
                guard let ckerror = error as? CKError else {
                    completion(error)
                    return
                }
                if ckerror.code == .partialFailure {
                    // This is a multiple-issue error. Check the underlying array
                    // of errors to see if it contains a match for the error in question.
                    guard let errors = ckerror.partialErrorsByItemID else {
                        completion(error)
                        return
                    }
                    for (_, error) in errors {
                        if let currentError = error as? CKError {
                            if currentError.code == CKError.zoneNotFound {
                                self.createZone() { error in
                                    guard error == nil else {
                                        completion(error)
                                        return
                                    }
                                    // Call save after creating the zone
                                    self.save(record: record, completion: completion)
                                    return
                                }
                                return
                            }
                        }
                    }
                }
                completion(error)
                return
            }
            // The record has been saved without errors
            completion(nil)
        }
        self.database.add(modifyRecordsOperation)
    }

    func createZone(completion: @escaping (Error?) -> Void) -> CKRecordZone{
        return CKRecordZone(zoneID: (z?.zoneID)!)
    }
    
    func deleteCloudRecordFromStudent(_ recordID:CKRecord.ID) {
        database.fetch(withRecordID: recordID, completionHandler:{ (r,err) in
            if err != nil {
                print("can't find record on cloud to delete.")
                print(err?.localizedDescription as Any)
            } else {
                self.database.delete(withRecordID: recordID, completionHandler: {(id,err) in
                    if err != nil {
                        print("failed deleting cloud record")
                    } else {
                        print("deleted cloud record")
                    }
                })
            }
        })
    }
    
    
    func setDataBase(_ db:CKDatabase) {
        database = db
    }
    
    @objc func newCloudData(notification:Notification) {
        // let userInfo = notification.userInfo
        print("In newCloudData")
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

//    func updateLocalRecords(changedRecords: [CKRecord], deletedRecordIDs: [CKRecord.ID]) {
//        
//        let delegate = UIApplication.shared.delegate as! AppDelegate
//        
//        delegate.updateContext.perform {
//            
//            let changedRecordNames = changedRecords.map { $0.recordID.recordName }
//            let deletedRecordNames = deletedRecordIDs.map { $0.recordName }
//            self.updateObject(students: changedRecordNames)
//            self.deleteObject(students: deletedRecordNames)
//            self.saveUpdateContext()
//        }
//    }
    
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
        newStudent.firstName = "New"
        newStudent.lastName = "Student"
        newStudent.phone = ""
        newStudent.recordName = newStudent.cloudKitRecordID()?.recordName
        DispatchQueue.main.async {
            do {
                try self.managedObjectContext!.save()
                self.tableView.reloadData()
            } catch {
                print(error)
            }
            
        }

//
//        ccr!.setValue("New", forKey: "firstName")
//        ccr!.setValue("Student", forKey: "lastName")
//        ccr!.setValue("", forKey: "phone")
//        ccr!.setValue(newStudent.recordName, forKey: "uniqueIdentifier")
//        // If appropriate, configure the new managed object.
//        // newEvent.timestamp = Date()
//        // let insertedObjects = context.insertedObjects
//        // let modifiedObjects = context.updatedObjects
//        // let deletedRecordIDs = context.deletedObjects.map { ($0 as! CloudKitManagedObject).cloudKitRecordID() }
//        if context.hasChanges {
//            do {
//                try context.save()
//                print("new student saved to core data")
//            } catch {
//                print(error.localizedDescription)
//            }
//            // let insertedObjectIDs = insertedObjects.map { $0 .objectID }
//            // let modifiedObjectIDs = modifiedObjects.map { $0 .objectID }
//
////            database.save(ccr!, completionHandler: {(rec,err) in
////                if let err = err {
////                    print(err.localizedDescription)
////                } else {
////                    print("new student saved to cloud")
////                }
////            })
//
//        }
        // Save the context.
//        do {
//            try context.save()
//        } catch {
//            // Replace this implementation with code to handle the error appropriately.
//            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            let nserror = error as NSError
//            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//        }
    }

    
    func addCloudKitRecordToCoreData(_ ckRecord:CKRecord) {
        //let delegate = NSApp.delegate as! AppDelegate
        //let context = delegate.persistentContainer.viewContext
        print("making new student for core data")
        let newStudent = Student(context: managedObjectContext!)
        newStudent.prepareForCloudKitWithCloudKitRecord(ckRecord.recordID)
        newStudent.firstName = ckRecord["firstName"]
        newStudent.lastName = ckRecord["lastName"]
        newStudent.phone = ckRecord["phone"]
        newStudent.recordName = newStudent.ckrecordName
        DispatchQueue.main.async {
            do {
                print("saving new record to core data")
                try self.managedObjectContext?.save()
                //            coreDataStudents.append(newStudent)
                print("student \(String(describing: newStudent.recordName)) saved to core")
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func addCoreDataRecordToCloud(_ student:Student) {
        // make sure it's not there
        database.fetch(withRecordID: student.cloudKitRecordID()!, completionHandler: {(r,err) in
            if err != nil {
                // not on cloud, add it
                if (student.recordName == nil) {
                    student.prepareForCloudKit()
                    student.ckrecordName = student.recordName
                }
                let ccr = student.cloudKitRecord()
                ccr?["firstName"] = student.firstName
                ccr?["lastName"] = student.lastName
                ccr?["phone"] = student.phone
                ccr?["uniqueIdentifier"] = student.uniqueIdentifier
                student.ckrecordName = student.recordName
                self.database.save(ccr!, completionHandler: {(r,err) in
                    if let err = err {
                        print(err)
                    } else {
                        print("Saved core data record to cloud")
                    }
                })
            }
        })
    }
    
    func updateCloudRecordWithCoreDataRecord(_ student:Student) {
        database.fetch(withRecordID: student.cloudKitRecordID()!, completionHandler: {(r,err) in
            if err != nil {
                // not found, ignore update
                print("cloud record to update not found.")
            } else {
                r?["firstName"]=student.firstName
                r?["lastName"]=student.lastName
                r?["phone"]=student.phone
                self.database.save(r!, completionHandler: {(r,err) in
                    if let err = err {
                        print(err)
                    } else {
                        print("updated cloud kit record with core data record")
                    }
                })
            }
        })
    }
    
    func fetchAndAddRecordToCoreData(_ recordID:CKRecord.ID) {
        print("getting record from cloud")
        database.fetch(withRecordID: recordID, completionHandler: { (r,err) in
            if let err = err {
                print("didn't find record on cloud \(recordID.recordName)")
                print(err.localizedDescription)
            } else {
                print("found record on cloud")
                self.addCloudKitRecordToCoreData(r!)
                print(r?.value(forKey: "firstName") ?? "No Name")
                
            }
        })
    }

    func updateRecordOnCloud(_ recordID:CKRecord.ID) {
        database.fetch(withRecordID: recordID, completionHandler: {(r,err) in
            if let err = err {
                print(err)
            } else {
                let predicate = NSPredicate(format: "recordName == %@", recordID.recordName)
                let request = NSFetchRequest<Student>(entityName: "Student")
                request.predicate = predicate
                do {
                    let results = try self.managedObjectContext?.fetch(request)
                    for s:Student in results! {
                        self.database.fetch(withRecordID: s.cloudKitRecordID()!, completionHandler: {(ckr,err) in
                            if let err = err {
                                print(err)
                            } else {
                                ckr?["firstName"]=s.firstName
                                ckr?["lastName"]=s.lastName
                                ckr?["phone"]=s.phone
                                self.database.save(ckr!, completionHandler: {(r,err) in
                                    if let err = err {
                                        print(err)
                                    } else {
                                        print("Updated record on cloud.")
                                    }
                                })
                            }
                        })
                    }
                } catch {
                    print(error)
                }

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
            if students != nil {
                for s:Student in students! {
                    if s.recordName == recordName {
                        database.fetch(withRecordID: recordID, completionHandler: {(r,err) in
                            if let err = err {
                                print(err.localizedDescription)
                            } else {
                                s.firstName = r?["firstName"]
                                s.lastName = r?["lastName"]
                                s.phone = r?["phone"]
                                s.recordName = r?["recordName"]
                                DispatchQueue.main.async {
                                    do {
                                        try self.managedObjectContext?.save()
                                        self.tableView.reloadData()
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                        })
                    }
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
            
            print("getting student from core data for deletion")
            let students = try managedObjectContext?.fetch(fetchRequest)
            //let modifyRecords = CKModifyRecordsOperation.init()

            print("found student")
            for s:Student in students! {
                managedObjectContext?.delete(s)
            }
            print("deleted student")
            DispatchQueue.main.async {
                do {
                    try self.managedObjectContext?.save()
                } catch {
                    print("trouble saving context after delete.")
                    print(error)
                }

            }
        } catch {
            print(error)
        }
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
                controller.context = managedObjectContext
                controller.studentItem = object
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
            // let context = fetchedResultsController.managedObjectContext
            
            if editingStyle == .delete {
                let context = fetchedResultsController.managedObjectContext
                context.delete(fetchedResultsController.object(at: indexPath))
                DispatchQueue.main.async {
                    do {
                        try self.managedObjectContext?.save()
                    } catch {
                        // Replace this implementation with code to handle the error appropriately.
                        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                        let nserror = error as NSError
                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    }

                }
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
                if tableView.cellForRow(at: indexPath!) ==  nil {
                    return
                }
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

