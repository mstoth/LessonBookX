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
    var subscribedToPrivateChanges:Bool = false
    var createdCustomZone:Bool = false
    var changesFromCloud:Bool = false
    let privateSubscriptionId = "LessonBook"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        z = ZoneOperations()
        managedObjectContext = self.fetchedResultsController.managedObjectContext

        let createZoneGroup = DispatchGroup()
        
        if !self.createdCustomZone {
            createZoneGroup.enter()
            let customZone = CKRecordZone(zoneID: z!.zoneID!)
            let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [] )
            createZoneOperation.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
                if (error == nil) { self.createdCustomZone = true }
                // else custom error handling
                createZoneGroup.leave()
            }
            createZoneOperation.qualityOfService = .userInitiated
            self.database.add(createZoneOperation)
        }
        
        if !self.subscribedToPrivateChanges {
            let createSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId: privateSubscriptionId)
            createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
                if error == nil {
                    self.subscribedToPrivateChanges = true
                } else {
                    print(error as Any)
                }
                // else custom error handling
            }
            self.database.add(createSubscriptionOperation)
        }
        // NotificationCenter.default.addObserver(self, selector: #selector(newCloudData), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil)
        if let managedObjectContext = managedObjectContext {
            // Add Observer
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
        }
        
        fetchChangesInDataBase()
    }


    func createDatabaseSubscriptionOperation(subscriptionId: String) -> CKModifySubscriptionsOperation {
        
        let subscription = CKDatabaseSubscription.init(subscriptionID: privateSubscriptionId)
        let notificationInfo = CKSubscription.NotificationInfo()
        
        // send a silent notification
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.qualityOfService = .utility
        return operation
    }

    
    
    func fetchChanges(in databaseScope: CKDatabase.Scope, completion: @escaping () -> Void) {
        
        switch databaseScope {
        case .private:
            fetchChangesInDataBase()
            
        case .shared:
            print("Shared scope.")
            //fetchDatabaseChanges(database: self.sharedDB, databaseTokenKey: "shared", completion: completion)
            
        case .public:
            fatalError()
            
        }
    }

    
    func fetchChangesInDataBase() {
        var previousToken:CKServerChangeToken?
        let changeTokenData = UserDefaults.standard.value(forKey: "LessonBook databaseChangeToken") as? Data // Read change token from disk
        if (changeTokenData != nil) {
            do {
                previousToken = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(changeTokenData!) as? CKServerChangeToken
            } catch {
                previousToken = nil
            }
        }
        let zoneConfiguration = CKFetchRecordZoneChangesOperation.ZoneConfiguration(previousServerChangeToken: previousToken, resultsLimit: nil, desiredKeys: ["firstName","lastName","phone","recordName","street1","street2","city","state","zip","cell","email","photo"])
        let zone = CKRecordZone(zoneName: "LessonBook")
        let zoneID = zone.zoneID
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], configurationsByRecordZoneID: [zoneID:zoneConfiguration])
        operation.fetchAllChanges = true
        
        operation.recordWithIDWasDeletedBlock = { (recordID,recordType) in
            print("Record deleted:", recordID)
            // write this record deletion to memory
            let predicate = NSPredicate(format: "recordName == %@", recordID.recordName)
            let fetchRequest = Student.fetchRequest() as NSFetchRequest
            fetchRequest.predicate = predicate
            do {
                let student = try self.managedObjectContext?.fetch(fetchRequest)
                for s in student! {
                    self.managedObjectContext?.delete(s)
                    print("Deleted student in core data")
                }
            } catch {
                print(error)
            }
        }
        operation.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
            // Flush record changes and deletions for this zone to disk
            // Write this new zone change token to disk
            print("in recordZoneChangeTokensUpdatedBlock", token as Any)
            let tokenData = try! NSKeyedArchiver.archivedData(withRootObject: token as Any, requiringSecureCoding: true)
            UserDefaults.standard.set(tokenData, forKey: "\(self.zoneID.zoneName) databaseChangeToken")
            
        }
        
        operation.recordZoneFetchCompletionBlock = {
            (zoneID: CKRecordZone.ID,
            serverChangeToken: CKServerChangeToken?,
            clientChangeTokenData: Data?,
            moreComing: Bool,
            error: Error?) in
            // do something with the token??
            if (error != nil) {
                print("Error in recordZoneFetchCompletionBlock")
                print(error as Any)
                return
            }
            print("in recordZoneFetchCompletionBlock")
            let tokenData = try! NSKeyedArchiver.archivedData(withRootObject: serverChangeToken as Any, requiringSecureCoding: true)
            UserDefaults.standard.set(tokenData, forKey: "\(self.zoneID.zoneName) databaseChangeToken")
            DispatchQueue.main.async {
                let notificationCenter = NotificationCenter.default
                notificationCenter.removeObserver(self)

                do {
                    try self.managedObjectContext?.save()
                    self.tableView.reloadData()
                } catch {
                    print(error)
                }
                notificationCenter.addObserver(self, selector: #selector(self.managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext)

            }

        }
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            print("in fetchRecordZoneChangesCompletionBlock")
            if (error != nil) {
                print(error as Any)
            }
        }
        operation.recordChangedBlock = { (record) in
            print("Record changed:", record["recordName"] as Any)
            // Write this record change to memory
            let recordName = record.recordID.recordName
            let predicate = NSPredicate(format: "recordName == %@", recordName)
            let fetchRequest = NSFetchRequest<Student>(entityName: "Student")
            fetchRequest.predicate = predicate
            let students = try! self.managedObjectContext?.fetch(fetchRequest)
            if students?.count == 0 {
                let s=Student(context: self.managedObjectContext!)
                s.prepareForCloudKitWithCloudKitRecord(record.recordID)
                s.firstName = record["firstName"]
                s.lastName = record["lastName"]
                s.phone = record["phone"]
                s.street1 = record["street1"]
                s.street2 = record["street2"]
                s.city = record["city"]
                s.state = record["state"]
                s.zip = record["zip"]
                s.cell = record["cell"]
                s.email = record["email"]
                if let asset = record["photo"] as? CKAsset,
                    let data = NSData(contentsOf: (asset.fileURL)) {
                    s.photo = data
                }
                    
                s.recordName = recordName
                
            } else {
                for s:Student in students! {
                    s.firstName = record["firstName"]
                    s.lastName = record["lastName"]
                    s.phone = record["phone"]
                    s.street1 = record["street1"]
                    s.street2 = record["street2"]
                    s.city = record["city"]
                    s.state = record["state"]
                    s.zip = record["zip"]
                    s.cell = record["cell"]
                    s.email = record["email"]
                    if (record["photo"] != nil) {
                        if let asset = record["photo"] as? CKAsset,
                            let data = NSData(contentsOf: (asset.fileURL)) {
                            s.photo = data
                        }
                    }
                    s.recordName = recordName
                }
            }
        }
        database.add(operation)
        
    }
    
    
    func fetchDatabaseChanges(database: CKDatabase, databaseTokenKey: CKServerChangeToken, completion: @escaping () -> Void) {
        
        var changedZoneIDs: [CKRecordZone.ID] = []
        _ = UserDefaults.standard.value(forKey: "\(zoneID.zoneName) databaseChangeToken") as? Data // Read change token from disk
        
//        var zoneChangeToken:CKServerChangeToken?
//        if (changeTokenData != nil){
//            try! zoneChangeToken = NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: changeTokenData!)  // unarchiveObject(with: changeTokenData!)as! CKServerChangeToken?
//        }
        
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: databaseTokenKey)
        operation.recordZoneWithIDChangedBlock = { (zoneID) in
            changedZoneIDs.append(zoneID)
        }
        operation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
            // Write this zone deletion to memory
            print("in recordZoneWithIDWasDeletedBlock")
        }
        
        operation.changeTokenUpdatedBlock = { (token) in
            print("in changeTokenUpdatedBlock")
            // Flush zone deletions for this database to disk
            // Write this new database change token to memory
            do {
                let changeTokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                UserDefaults.standard.set(changeTokenData, forKey: "\(self.zoneID.zoneName) databaseChangeToken")
            } catch {
                print(error)
            }
        }
        
        operation.fetchDatabaseChangesCompletionBlock = { (token, moreComing, error) in
            print("in fetchDatabaseChangesCompletionBlock")
            if let error = error {
                print("Error during fetch shared database changes operation", error)
                completion()
                return
            }
            // Flush zone deletions for this database to disk
            // Write this new database change token to memory
            
            self.fetchZoneChanges(database: database, databaseTokenKey: token!, zoneIDs: changedZoneIDs) {
                // Flush in-memory database change token to disk
                do {
                    let changeTokenData = try NSKeyedArchiver.archivedData(withRootObject: databaseTokenKey, requiringSecureCoding: true)
                    UserDefaults.standard.set(changeTokenData, forKey: "\(self.zoneID.zoneName) databaseChangeToken")
                } catch {
                    print(error)
                }
                completion()
            }
        }
        operation.qualityOfService = .userInitiated
        database.add(operation)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    // MARK -- Zone Operations
    
    
    
    func fetchZoneChanges(database: CKDatabase, databaseTokenKey: CKServerChangeToken, zoneIDs: [CKRecordZone.ID], completion: @escaping () -> Void) {
        // Look up the previous change token for each zone
        var optionsByRecordZoneID:[CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration] = [:]
        //var optionsByRecordZoneID = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        for zoneID in zoneIDs {
            let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            let changeTokenData = UserDefaults.standard.value(forKey: "\(zoneID.zoneName) zoneChangeToken") as? Data // Read change token from disk
            if changeTokenData != nil {
                do {
                    let changeToken = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(changeTokenData!)
                    options.previousServerChangeToken = changeToken as? CKServerChangeToken// Read change token from disk
                    optionsByRecordZoneID[zoneID] = options

                } catch {
                    print(error)
                }
            }
        }
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIDs, configurationsByRecordZoneID: optionsByRecordZoneID)

        operation.recordChangedBlock = { (record) in
            print("Record changed:", record)
            // Write this record change to memory
            let predicate = NSPredicate(format: "recordName == %@", record.recordID.recordName)
            let fetchRequest = Student.fetchRequest() as NSFetchRequest
            fetchRequest.predicate = predicate
            do {
                let student = try self.managedObjectContext?.fetch(fetchRequest)
                for s in student! {
                    var changed:Bool = false
                    
                    if s.firstName != record["firstName"] {
                        s.firstName = record["firstName"]
                        changed = true
                    }
                    if s.lastName != record["lastName"] {
                        s.lastName = record["lastName"]
                        changed = true
                    }
                    if s.phone != record["phone"] {
                        s.phone = record["phone"]
                        changed = true
                    }
                    if changed {
                        do {
                            try self.managedObjectContext?.save()
                        } catch {
                            print(error)
                        }
                    }
                }
            } catch {
                print(error)
            }
        }
        
        operation.recordWithIDWasDeletedBlock = { (recordID,recordType) in
            print("Record deleted:", recordID)
            // write this record deletion to memory
            let predicate = NSPredicate(format: "recordName == %@", recordID.recordName)
            let fetchRequest = Student.fetchRequest() as NSFetchRequest
            fetchRequest.predicate = predicate
            do {
                let student = try self.managedObjectContext?.fetch(fetchRequest)
                for s in student! {
                    self.managedObjectContext?.delete(s)
                    print("Deleted student in core data")
                }
            } catch {
                print(error)
            }

        }
        
        
        operation.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
            // Flush record changes and deletions for this zone to disk
            // Write this new zone change token to disk
        }
        
        
        
        operation.recordZoneFetchCompletionBlock = { (zoneId, changeToken, _, _, error) in
            
            if let error = error {
                print("Error fetching zone changes for \(databaseTokenKey) database:", error)
                return
            }
            // Flush record changes and deletions for this zone to disk
            // Write this new zone change token to disk
        }
        
        
        
        operation.fetchRecordZoneChangesCompletionBlock = { (error) in
            
            if let error = error {
                print("Error fetching zone changes for \(databaseTokenKey) database:", error)
            }
            completion()
        }
        database.add(operation)
    }
    

    @objc func managedObjectContextObjectsWillSave(notification: NSNotification) {
        // guard let userInfo = notification.userInfo else { return }
        
    }
    

    @objc func managedObjectContextObjectsDidSave(notification: NSNotification) {
        // guard let userInfo = notification.userInfo else { return }
    }
    


    @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
        
        print("Context Objects Did Change.")
        if changesFromCloud {
            changesFromCloud = false
            return
        }
        guard let userInfo = notification.userInfo else { return }
        
        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<Student>, inserts.count > 0 {
            print("Inserting Student")
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
                    //ccr?["lastUpdate"]=Date()
                    ccr?["street1"]=s.street1
                    ccr?["street2"]=s.street2
                    ccr?["city"]=s.city
                    ccr?["state"]=s.state
                    ccr?["zip"]=s.zip
                    ccr?["cell"]=s.cell
                    ccr?["email"]=s.email
                    if (s.photo != nil) {
                        do {
                            try s.photo?.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("\(String(describing: s.recordName)).png"), options: .atomic)
                            let asset = CKAsset(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(String(describing: s.recordName)).png"))
                            ccr?["photo"]=asset
                        } catch  {
                            print(error)
                        }
                    }
                    let modificationObject = CKModifyRecordsOperation(recordsToSave: [ccr!], recordIDsToDelete: nil)
                    
                    modificationObject.isAtomic = true
                    modificationObject.modifyRecordsCompletionBlock = { (recs,rIDs,error) in
                        if (error != nil) {
                            print("ERROR IN MODIFYING CLOUD")
                            print(error)
                        } else {
                            print("MODIFIED CLOUD")
                        }
                    }
                    
                    database.add(modificationObject)
                } else {
                    let ccr = s.cloudKitRecord()
                    //if !(ccr?["firstName"]==s.firstName && ccr?["lastName"]==s.lastName && ccr?["phone"]==s.phone ) {
                    ccr?["firstName"]=s.firstName
                    ccr?["lastName"]=s.lastName
                    ccr?["phone"]=s.phone
                    ccr?["recordName"]=s.recordName
                    ccr?["street1"]=s.street1
                    ccr?["street2"]=s.street2
                    ccr?["city"]=s.city
                    ccr?["state"]=s.state
                    ccr?["zip"]=s.zip
                    ccr?["cell"]=s.cell
                    ccr?["email"]=s.email
                    if (s.photo != nil) {
                        do {
                            try s.photo?.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("\(String(describing: s.recordName)).png"), options: .atomic)
                            let asset = CKAsset(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(String(describing: s.recordName)).png"))
                            ccr?["photo"]=asset
                        } catch  {
                            print(error)
                        }
                    }
                    let modifyRecords = CKModifyRecordsOperation.init(recordsToSave: [ccr!], recordIDsToDelete: [])
                    // modifyRecords.recordsToSave = recordArray
                    modifyRecords.savePolicy = .allKeys
                    modifyRecords.isAtomic = true
                    modifyRecords.qualityOfService = .userInitiated
                    modifyRecords.modifyRecordsCompletionBlock = { (recs,rIDs,error) in
                        if (error != nil) {
                            print("ERROR IN MODIFYING CLOUD")
                            print(error)
                        } else {
                            print("MODIFIED CLOUD")
                        }
                    }
                    
                    self.database.add(modifyRecords)
                    
                    //database.add(CKModifyRecordsOperation(recordsToSave: [ccr!], recordIDsToDelete: nil))
                    //                        database.save(ccr!, completionHandler: {(r,err) in
                    //                            if let err = err {
                    //                                print(err)
                    //                            } else {
                    //                                print("Saved record to cloud")
                    //                            }
                    //                        })
                    //}
                    
                }
//                DispatchQueue.main.async {
//                    do {
//                        try self.managedObjectContext?.save()
//                    } catch {
//                        print(error)
//                    }
//                }
            }
        }
        
        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<Student>, updates.count > 0 {
            print("Core Data Changed Notification")
            for s:Student in updates {
                let recordName = s.recordName
                // let recordID = CKRecord.ID(recordName: recordName)
                // let recordID=s.cloudKitRecordID()
                let predicate = NSPredicate(format: "recordName == %@", recordName!)
                let query = CKQuery(recordType: "Student", predicate: predicate)
                database.perform(query, inZoneWith: z?.zoneID, completionHandler: {(recs,err) in
                    if err != nil {
                        let ckerror = err as! CKError
                        if ckerror.code == CKError.unknownItem {
                            print("Unknown Item")
                            let recordID = CKRecord.ID(recordName: s.recordName!, zoneID: s.zoneID())
                            let r = CKRecord(recordType: "Student", recordID: recordID)
                            
                            r["phone"]=s.phone
                            r["firstName"]=s.firstName
                            r["lastName"]=s.lastName
                            r["recordName"]=s.cloudKitRecordID()?.recordName
                            //r["lastUpdate"]=Date()
                            r.setValue("",forKey: "street1")
                            r.setValue("",forKey: "street2")
                            r.setValue("",forKey: "city")
                            r.setValue("",forKey: "state")
                            r.setValue("",forKey: "zip")
                            r.setValue("",forKey: "email")
                            r.setValue("",forKey: "cell")
                            do {
                                try s.photo?.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("\(String(describing: s.recordName)).png"), options: .atomic)
                                let asset = CKAsset(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(String(describing: s.recordName)).png"))
                                r["photo"]=asset
                            } catch  {
                                print(error)
                            }
                            
                            let modifyRecords = CKModifyRecordsOperation.init(recordsToSave: [r], recordIDsToDelete: [])
                            // modifyRecords.recordsToSave = recordArray
                            modifyRecords.isAtomic = true
                            modifyRecords.modifyRecordsCompletionBlock = { (recs,rIDs,error) in
                                if (error != nil) {
                                    print("ERROR IN MODIFYING CLOUD")
                                    print(error)
                                } else {
                                    print("MODIFIED CLOUD")
                                }
                            }
                            
                            modifyRecords.savePolicy = .allKeys
                            modifyRecords.qualityOfService = .background
                            self.database.add(modifyRecords)
                            
                        }
                    } else {
                        for r:CKRecord in recs! {
                            //if !(r["phone"]==s.phone && r["firstName"]==s.firstName && r["lastName"]==s.lastName) {
                            print("Setting Record Values")
                            
                            r["phone"]=s.phone
                            r["firstName"]=s.firstName
                            r["lastName"]=s.lastName
                            r["recordName"]=s.recordName
                            //r["lastUpdate"]=Date()
                            r.setValue("",forKey: "street1")
                            r.setValue("",forKey: "street2")
                            r.setValue("",forKey: "city")
                            r.setValue("",forKey: "state")
                            r.setValue("",forKey: "zip")
                            r.setValue("",forKey: "email")
                            r.setValue("",forKey: "cell")
                            do {
                                try s.photo?.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("\(String(describing: s.recordName)).png"), options: .atomic)
                                let asset = CKAsset(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(String(describing: s.recordName)).png"))
                                r["photo"]=asset
                            } catch  {
                                print(error)
                            }
                            
                            let recordArray = [r]
                            // print(String(describing: recordArray))
                            let modifyRecords = CKModifyRecordsOperation.init(recordsToSave: recordArray, recordIDsToDelete: [])
                            // modifyRecords.recordsToSave = recordArray
                            modifyRecords.savePolicy = .allKeys
                            modifyRecords.isAtomic = true
                            
                            modifyRecords.modifyRecordsCompletionBlock = { (recs,rIDs,error) in
                                if (error != nil) {
                                    print("ERROR IN MODIFYING CLOUD")
                                    print(error)
                                } else {
                                    print("MODIFIED CLOUD")
                                }
                            }
                            
                            modifyRecords.qualityOfService = .userInitiated
                            self.database.add(modifyRecords)
                        }
                    }
                })
            }
        }
        
        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<Student>, deletes.count > 0 {
            // print(deletes)
            for s:Student in deletes {
                let recordName=s.recordName
                let recordID = CKRecord.ID.init(recordName: recordName!, zoneID: s.zoneID())
                
                database.delete(withRecordID: recordID, completionHandler: {(rid,err) in
                    if let err = err {
                        print(err.localizedDescription)
                    } else {
                        print("student deleted from cloud")
                    }
                })
            }
            DispatchQueue.main.async {
                do {
                    try self.managedObjectContext!.save()
                } catch {
                    print(error)
                }

            }
        }

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
        // newStudent.lastUpdate = Date()
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
        // newStudent.lastUpdate = Date()
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
                // ccr?["lastUpdate"]=Date()
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
                                //s.lastUpdate = r?["lastUpdate"]
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
                controller.studentToEdit = object
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

