//
//  ViewController.swift
//  LessonBookX
//
//  Created by Michael Toth on 1/27/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import Cocoa
import CloudKit
import NotificationCenter
import CoreData

class StudentModel {
    //private let database = CKContainer.init(identifier: "iCloud.com.virtualpianist.LessonBook").privateCloudDatabase
}


class ViewController: NSViewController {

    //var detailViewController: DetailViewController? = nil
    //@objc dynamic var managedObjectContext: NSManagedObjectContext? = nil
    private var database = CKContainer.default().privateCloudDatabase
    private var container = CKContainer.default()
    let zoneID = CKRecordZone.ID(zoneName: "LessonBook", ownerName: CKCurrentUserDefaultName)
    @IBOutlet weak var tableView: NSTableView!
    var storeChangeObserver:AnyObject? = nil
    var students:[CKRecord] = []
    var coreDataStudents:[Student] = []
    let delegate = NSApp.delegate
    @objc dynamic var context: NSManagedObjectContext? = nil
    var z:ZoneOperations? = nil
    var subscribedToPrivateChanges:Bool = false
    var createdCustomZone:Bool = false

    let privateSubscriptionId = "LessonBook"

    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let delegate = NSApp.delegate as! AppDelegate
        context = delegate.persistentContainer.viewContext
        delegate.viewController = self
        let containerIdentifier = String(CKContainer.default().containerIdentifier!)
        let lessonBookLoc = containerIdentifier.lastIndex(of: "k")!
        let newContainerIdentifier = containerIdentifier[...lessonBookLoc]
        container = CKContainer.init(identifier: String(newContainerIdentifier))
        database = CKContainer.init(identifier: String(newContainerIdentifier)).privateCloudDatabase
        
        // resetAllRecords(in: "Student")
        
//        let predicate = NSPredicate(value: true)
//
//        let qSubscription = CKQuerySubscription(recordType: "Student", predicate: predicate, subscriptionID: "lessonbook",
//                                                options: [.firesOnRecordCreation,.firesOnRecordUpdate, .firesOnRecordDeletion])
//
//        qSubscription.notificationInfo?.shouldSendMutableContent = true
//
//        let notificationInfo = CKQuerySubscription.NotificationInfo()
//        notificationInfo.shouldSendMutableContent = true
//        notificationInfo.shouldBadge = true
//        notificationInfo.shouldSendContentAvailable = true
//        notificationInfo.desiredKeys = ["firstName","lastName","phone","recordName","lastUpdate"]
//        // notificationInfo.perform(#selector(handleCloudKitNotification))
//        qSubscription.notificationInfo = notificationInfo
//        database.save(qSubscription, completionHandler: {(sub,err) in
//            if let err = err {
//                print(err.localizedDescription)
//            } else {
//                print("saved subscription")
//            }
//        })
        z = ZoneOperations()
        
        
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
        
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(self, selector: #selector(self.contextObjectsDidChange(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: nil)

        }
        
        fetchChangesInDataBase()
//        fetchZoneChanges(database: database, databaseTokenKey: "private", zoneIDs: [(z?.zoneID)!]) {
//            print("In fetchZoneChanges completion.")
//        }
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
    
    
    
    func addCloudKitRecordToCoreData(_ ckRecord:CKRecord) {
        //let delegate = NSApp.delegate as! AppDelegate
        //let context = delegate.persistentContainer.viewContext

        DispatchQueue.main.async {
            do {

                let newStudent = Student(context: self.context!)
                newStudent.prepareForCloudKitWithCloudKitRecord(ckRecord.recordID)
                newStudent.firstName = ckRecord["firstName"]
                newStudent.lastName = ckRecord["lastName"]
                newStudent.phone = ckRecord["phone"]
                newStudent.recordName = ckRecord["recordName"]
                newStudent.lastUpdate = Date()
                // newStudent.recordName = ckRecord.recordID.recordName
                NotificationCenter.default.removeObserver(self, name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
                try self.context?.save()
                //coreDataStudents.append(newStudent)
                self.tableView.reloadData()
                NotificationCenter.default.addObserver(self, selector: #selector(self.contextObjectsDidChange(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: nil)

            } catch {
                    print(error.localizedDescription)
            }
        }
    }
    
    
    
    func fetchChanges(in databaseScope: CKDatabase.Scope, completion: @escaping () -> Void) {
        
        switch databaseScope {
        case .private:
            // fetchDatabaseChanges(database: self.database, completion: completion)
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
        let zoneConfiguration = CKFetchRecordZoneChangesOperation.ZoneConfiguration(previousServerChangeToken: previousToken, resultsLimit: nil, desiredKeys: ["firstName","lastName","phone","recordName"])
        let zoneID = z?.zoneID
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [(z?.zoneID)!], configurationsByRecordZoneID: [zoneID!:zoneConfiguration])
        operation.fetchAllChanges = true
        
        operation.recordWithIDWasDeletedBlock = { (recordID,recordType) in
            print("Record deleted:", recordID)
            // write this record deletion to memory
            let predicate = NSPredicate(format: "recordName == %@", recordID.recordName)
            let fetchRequest = Student.fetchRequest() as NSFetchRequest
            fetchRequest.predicate = predicate
            do {
                let student = try self.context?.fetch(fetchRequest)
                for s in student! {
                    self.context?.delete(s)
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
            print("in recordZoneFetchCompletionBlock")
            let tokenData = try! NSKeyedArchiver.archivedData(withRootObject: serverChangeToken as Any, requiringSecureCoding: true)
            UserDefaults.standard.set(tokenData, forKey: "\(self.zoneID.zoneName) databaseChangeToken")

        }
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            print("in fetchRecordZoneChangesCompletionBlock")
            if (error != nil) {
                print(error)
            }
        }
        operation.recordChangedBlock = { (record) in
            print("Record changed:", record["recordName"] as Any)
            // Write this record change to memory
            let recordName = record.recordID.recordName
            let predicate = NSPredicate(format: "recordName == %@", recordName)
            let fetchRequest = NSFetchRequest<Student>(entityName: "Student")
            fetchRequest.predicate = predicate
            let students = try! self.context?.fetch(fetchRequest)
            for s:Student in students! {
                s.firstName = record["firstName"]
                s.lastName = record["lastName"]
                s.phone = record["phone"]
                s.recordName = recordName
            }
            DispatchQueue.main.async {
                do {
                    try self.context?.save()
                    self.tableView.reloadData()
                } catch {
                    print(error)
                }
            }
        }
        database.add(operation)

    }

    
    func fetchDatabaseChanges(database: CKDatabase, completion: @escaping () -> Void) {

        var changedZoneIDs: [CKRecordZone.ID] = []
//        //let changeTokenData = UserDefaults.standard.value(forKey: "\(zoneID.zoneName) databaseChangeToken") as? Data // Read change token from disk
//
        var changeToken:CKServerChangeToken? = nil
        // let changeToken = getPreviousServerChangeToken()  // Read change token from disk
//        let changeTokenData = UserDefaults.standard.value(forKey: "\(zoneID.zoneName) zoneChangeToken")
//        if changeTokenData != nil {
//            do {
//                changeToken = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(changeTokenData as! Data) as! CKServerChangeToken
//            } catch {
//                changeToken = nil
//            }
//        } else {
//            changeToken = nil
//        }
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)
        
        operation.recordZoneWithIDChangedBlock = { (zoneID) in
            changedZoneIDs.append(zoneID)
            print("in recordZoneWithIDChangedBlock")
        }
        operation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
            // Write this zone deletion to memory
            print("in recordZoneWithIDWasDeletedBlock")
        }

        operation.changeTokenUpdatedBlock = { (token) in
            print("in changeTokenUpdatedBlock")
            do {
                let changeTokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                UserDefaults.standard.set(changeTokenData, forKey: "\(self.zoneID.zoneName) databaseChangeToken")
            } catch {
                print(error)
            }

            // Flush zone deletions for this database to disk
            // Write this new database change token to memory
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
//            var changeToken:CKServerChangeToken? = nil
//            // let changeToken = getPreviousServerChangeToken()  // Read change token from disk
//            let changeTokenData = UserDefaults.standard.value(forKey: "\(self.zoneID.zoneName) databaseChangeToken")
//            if changeTokenData != nil {
//                changeToken = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(changeTokenData as! Data) as! CKServerChangeToken
//            }

            self.fetchZoneChanges(database: database, zoneIDs: changedZoneIDs) {
                // Flush in-memory database change token to disk
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


    func getPreviousServerChangeToken() -> CKServerChangeToken? {
        var tokenFile = getDocumentsDirectory()
        tokenFile.appendPathComponent("token.dat")
        do {
            let data:Data = try Data(contentsOf: tokenFile)
            let token = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
            return token as? CKServerChangeToken
        } catch {
            print(error)
        }
        return nil
    }
    
    
    func fetchZoneChanges(database: CKDatabase, zoneIDs: [CKRecordZone.ID], completion: @escaping () -> Void) {
        // Look up the previous change token for each zone
        var optionsByRecordZoneID:[CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration] = [:]
        var changeToken:CKServerChangeToken? = nil
        // let changeToken = getPreviousServerChangeToken()  // Read change token from disk
        let changeTokenData = UserDefaults.standard.value(forKey: "\(zoneID.zoneName) databaseChangeToken")
        if changeTokenData != nil {
            do {
                changeToken = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(changeTokenData as! Data) as! CKServerChangeToken
            } catch {
                changeToken = nil
            }
        } else {
            changeToken = nil
        }

        for zoneID in zoneIDs {
            let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            let changeTokenData = UserDefaults.standard.value(forKey: "\(zoneID.zoneName) databaseChangeToken") as? Data // Read change token from disk
            if changeTokenData != nil {
                do {
                    let changeToken = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(changeTokenData!)
                    options.previousServerChangeToken = changeToken as? CKServerChangeToken // changeToken as? CKServerChangeToken// Read change token from disk
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
            let recordName = record.recordID.recordName
            let predicate = NSPredicate(format: "recordName == %@", recordName)
            let fetchRequest = NSFetchRequest<Student>(entityName: "Student")
            fetchRequest.predicate = predicate
            let students = try! self.context?.fetch(fetchRequest)
            for s:Student in students! {
                s.firstName = record["firstName"]
                s.lastName = record["lastName"]
                s.phone = record["phone"]
            }
            DispatchQueue.main.async {
                do {
                    try self.context?.save()
                    self.tableView.reloadData()
                } catch {
                    print(error)
                }
            }
        }

        operation.recordWithIDWasDeletedBlock = { (recordID,recordType) in
            print("Record deleted:", recordID)
            // write this record deletion to memory
            let predicate = NSPredicate(format: "recordName == %@", recordID.recordName)
            let fetchRequest = Student.fetchRequest() as NSFetchRequest
            fetchRequest.predicate = predicate
            do {
                let student = try self.context?.fetch(fetchRequest)
                for s in student! {
                    self.context?.delete(s)
                    print("Deleted student in core data")
                }
            } catch {
                print(error)
            }
        }


        operation.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
            // Flush record changes and deletions for this zone to disk
            // Write this new zone change token to disk
            let tokenData = try! NSKeyedArchiver.archivedData(withRootObject: token as Any, requiringSecureCoding: true)
            UserDefaults.standard.set(tokenData, forKey: "\(self.zoneID.zoneName) databaseChangeToken")

        }



        operation.recordZoneFetchCompletionBlock = { (zoneId, changeToken, _, _, error) in

            if let error = error {
                print("Error fetching zone changes for the database:", error)
                return
            }
//            if (changeToken != nil) {
//                let tokenData = try! NSKeyedArchiver.archivedData(withRootObject: changeToken as Any, requiringSecureCoding: true)
//                UserDefaults.standard.set(tokenData, forKey: "\(self.zoneID.zoneName) zoneChangeToken")
//            }
            let tokenData = try! NSKeyedArchiver.archivedData(withRootObject: changeToken as Any, requiringSecureCoding: true)
            UserDefaults.standard.set(tokenData, forKey: "\(self.zoneID.zoneName) databaseChangeToken")

            // Flush recoxrd changes and deletions for this zone to disk
            // Write this new zone change token to disk
        }



        operation.fetchRecordZoneChangesCompletionBlock = { (error) in

            if let error = error {
                print("Error fetching zone changes for the database:", error)
            }
            completion()
        }
        database.add(operation)
        //completion()
    }


    
    
    @IBAction func addNewStudent(_ sender: Any) {
        let delegate = NSApp.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        let newStudent = Student(context:context)
        newStudent.prepareForCloudKit()
        let ccr = newStudent.cloudKitRecord()
        
        newStudent.firstName = "New"
        newStudent.lastName = "Student"
        newStudent.phone = ""
        newStudent.recordID = newStudent.ckrecordID
        newStudent.recordName = newStudent.cloudKitRecordID()?.recordName
        newStudent.lastUpdate = Date()
        ccr!.setValue("New",forKey: "firstName")
        ccr!.setValue("Student",forKey: "lastName")
        ccr!.setValue("", forKey: "phone")
        do {
            try context.save()
            coreDataStudents.append(newStudent)
            print("New student saved to core data")
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }

        } catch {
            print(error.localizedDescription)
        }
        database.save(ccr!, completionHandler: {(rec,err) in
            if let err = err {
                print(err.localizedDescription)
            } else {
                print("new student saved to cloud")
                print(rec?.value(forKey:"RecordName") as Any)
            }
        })
        
    }
    
    func recordRemovedFromCloudKit(_ recordID:CKRecord.ID) {
        
        let predicate = NSPredicate(format: "recordName=%@", recordID.recordName)
        let fetchRequest = NSFetchRequest<Student>(entityName: "Student")
        fetchRequest.predicate = predicate
        do {
            let results = try context?.fetch(fetchRequest)
            for s:Student in results! {
                context?.delete(s)
            }
        } catch {
            print(error.localizedDescription)
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func rowOfCoreDataStudent(_ student:Student) -> Int {
        var i:Int
        i = 0
        for s:Student in coreDataStudents {
            if s.recordName == student.recordName {
                return i
            } else {
                i = i + 1
            }
        }
        return -1
    }
    
    
    @IBAction func removeSelectedStudent(_ sender: Any) {
        let delegate = NSApp.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext

        let row = tableView.selectedRow
        if (row < 0) {
            print("select a student")
        } else {
            let selectedStudent = coreDataStudents[row]
            context.delete(selectedStudent)
            do {
                try context.save()
                print("Deleted student from core data")
            } catch {
                print(error.localizedDescription)
            }
            //coreDataStudents.remove(at: row)
            
            database.delete(withRecordID: selectedStudent.cloudKitRecordID()!, completionHandler: {(id,err) in
                if let err = err {
                    print("problem deleting record on cloud")
                    print(err.localizedDescription)
                } else {
                    print("deleting record on cloud successful")
                }
            })
            tableView.reloadData()

        }
    }
    
    func resetAllRecords(in entity : String) // entity = Your_Entity_Name
    {
        
        //let context = ( UIApplication.shared.delegate as! AppDelegate ).persistentContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do
        {
            try context?.execute(deleteRequest)
            try context?.save()
        }
        catch
        {
            print ("There was an error")
        }
    }
    //private var database = CKContainer.init(identifier: "iCloud.com.virtualpianist.LessonBook").privateCloudDatabase
    //private var database = CKContainer.default().privateCloudDatabase

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @objc func contextObjectsDidChange(_ notification:NSNotification) {
        print("Context Objects Did Change.")
        guard let userInfo = notification.userInfo else { return }
        
        // print(notification)
        
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
                    ccr?["lastUpdate"]=Date()
                    database.save(ccr!, completionHandler: {(r,err) in
                        if let err = err {
                            print(err)
                        } else {
                            print("Saved record to cloud")
                        }
                    })
                    
                } else {
                    let ccr = s.cloudKitRecord()
                    if !(ccr?["firstName"]==s.firstName && ccr?["lastName"]==s.lastName && ccr?["phone"]==s.phone ) {
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
                    
                }
                DispatchQueue.main.async {
                    do {
                        try self.context?.save()
                    } catch {
                        print(error)
                    }
                }
            }
        }

//        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<Student>, inserts.count > 0 {
//            for s:Student in inserts {
//                // if recordName is nil, need to send it up to the cloud
//                if s.recordName == nil {
//                    s.prepareForCloudKit()
//                    s.recordName = s.cloudKitRecordID()?.recordName
//                    let ccr = s.cloudKitRecord()
//
//                    ccr?["firstName"]=s.firstName! as CKRecordValue
//                    ccr?["lastName"]=s.lastName! as CKRecordValue
//                    ccr?["phone"]=s.phone! as CKRecordValue
//                    ccr?["recordName"]=s.recordName! as CKRecordValue
//                    //ccr?["lastUpdate"]=Date() as CKRecordValue
//                    database.save(ccr!, completionHandler: {(rec,err) in
//                        if err != nil {
//                            print(err)
//                        } else {
//                            print("record saved to cloud")
//                        }
//                    })
////                    database.save(ccr!, completionHandler: {(r,err) in
////                        if err == nil {
////                            print("saved new record to cloud")
////                        }
////                    })
//                }
//            }
//        }
//                DispatchQueue.main.async {
//                    do {
//                        try self.context?.save()
//                    } catch {
//                        print(error)
//                    }
//                }
//                database.fetch(withRecordID: s.cloudKitRecordID()!, completionHandler: {(r,err) in
//                    if err != nil {
//                        s.prepareForCloudKit()
//                        let ccr = s.cloudKitRecord()
//                        s.recordName = s.cloudKitRecordID()?.recordName
//                        ccr?["firstName"] = s.firstName
//                        ccr?["lastName"] = s.lastName
//                        ccr?["phone"] = s.phone
//                        self.database.save(ccr!, completionHandler: {(r,err) in
//                            if let err = err {
//                                print(err.localizedDescription)
//                            } else {
//                                print("Saved record to cloud")
//                                print(s.cloudKitRecord()?.recordID.recordName as Any)
//                                do {
//                                    try self.context?.save()
//                                    print("saved record to core data")
//                                    print(s.recordName as Any)
//                                } catch {
//                                    print(error)
//                                }
//                            }
//                        })
//                    } else {
//                        // it's there, don't send it again
//                    }
//                })
//            }
//            // print(inserts)
//        }
        
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
                            r["lastUpdate"]=Date()
                            self.database.save(r, completionHandler: {(r,err) in
                                if let err = err {
                                    print("error from saving update to cloud")
                                    print(err.localizedDescription)
                                } else {
                                    print("saved record to cloud for update")
                                    print(s.cloudKitRecord()?.recordID.recordName as Any)
                                }
                            })
                        }
                    } else {
                        for r:CKRecord in recs! {
                            if !(r["phone"]==s.phone && r["firstName"]==s.firstName && r["lastName"]==s.lastName) {
                                print("Setting Record Values")
                                
                                r["phone"]=s.phone
                                r["firstName"]=s.firstName
                                r["lastName"]=s.lastName
                                r["recordName"]=s.recordName
                                r["lastUpdate"]=Date()
                                
                                let recordArray = [r]
                                print(String(describing: recordArray))
                                let modifyRecords = CKModifyRecordsOperation.init(recordsToSave: recordArray, recordIDsToDelete: [])
                                // modifyRecords.recordsToSave = recordArray
                                modifyRecords.savePolicy = .allKeys
                                modifyRecords.qualityOfService = .background
                                self.database.add(modifyRecords)
                                self.database.save(r, completionHandler: {(r,err) in
                                    if err != nil {
                                        print(err as Any)
                                    } else {
                                        print("Saved record to cloud.")
                                    }
                                })
                            }
                        }
                    }
                })
            }
        }

        
//        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<Student>, updates.count > 0 {
//            print("Core Data Changed Notification (updates)")
//            for s:Student in updates {
//                let recordName=s.recordName
//
//                let predicate = NSPredicate(format: "recordName == %@", recordName!)
//                let query = CKQuery(recordType: "Student", predicate: predicate)
//                database.perform(query, inZoneWith: z?.zoneID, completionHandler: {(recs,err) in
//                    if err != nil {
//                        print(err)
//                    } else {
//                        for r:CKRecord in recs! {
//                            if !(r["phone"]==s.phone && r["firstName"]==s.firstName && r["lastName"]==s.lastName) {
//                                r["phone"]=s.phone as CKRecordValue?
//                                r["firstName"]=s.firstName as CKRecordValue?
//                                r["lastName"]=s.lastName as CKRecordValue?
//                                r["recordName"]=s.recordName as CKRecordValue?
//                                //r["lastUpdate"]=Date()
//                                self.database.save(r, completionHandler: {(rec,err) in
//                                    if err != nil {
//                                        print(err)
//                                    } else {
//                                        print("record updated to cloud")
//                                    }
//                                })
//                            }
//                        }
//                    }
//                })
//            }
//        }
        
                
                
                
//                print("Making record ID with \(String(describing: recordName))")
//                let recordID = CKRecord.ID.init(recordName: recordName!, zoneID: s.zoneID())
//
//                // DispatchQueue.main.async {
//                    self.database.fetch(withRecordID: recordID, completionHandler: {(r,err) in
//                        if err != nil {
//                            // didn't find record. upload
//                            let ckerror = err as! CKError
//                            print(ckerror.localizedDescription)
//                            if ckerror.code == CKError.unknownItem {
//                                print("Unknown Item")
//                                let ckr=CKRecord(recordType: "Student", recordID: recordID)
//
//                                ckr["phone"]=s.phone as CKRecordValue?
//                                ckr["firstName"]=s.firstName as CKRecordValue?
//                                ckr["lastName"]=s.lastName as CKRecordValue?
//                                ckr["recordName"]=s.recordName as CKRecordValue?
//                                ckr["lastUpdate"]=Date()
//                                self.database.save(ckr, completionHandler: {(r,err) in
//                                    if let err = err {
//                                        print("error from saving update to cloud")
//                                        print(err.localizedDescription)
//                                    } else {
//                                        print("saved record to cloud for update")
//                                        print(s.recordName as Any)
//                                    }
//                                })
//
//                            } else {
//                                print("Unknown error from fetch.")
//                                print(ckerror.localizedDescription)
//                            }
//                        } else {
//                            if !(r?["phone"]==s.phone && r?["firstName"]==s.firstName &&
//                                r?["recordName"]==s.recordName && r?["lastName"]==s.lastName) {
//                                r?["phone"]=s.phone
//                                r?["firstName"]=s.firstName
//                                r?["lastName"]=s.lastName
//                                r?["recordName"]=s.recordName
//                                r?["lastUpdate"]=Date()
//                                let recordArray = [r!]
//                                let modifyRecords = CKModifyRecordsOperation.init()
//                                modifyRecords.recordsToSave = recordArray
//                                modifyRecords.savePolicy = .allKeys
//                                modifyRecords.qualityOfService = .background
//                                self.database.add(modifyRecords)
//                            }
//                        }
//                    })
//            }
//        }
        
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
            do {
                try context!.save()
            } catch {
                print(error)
            }
        }
        
//        DispatchQueue.main.async {
//            do {
//                try self.context?.save()
//                self.tableView.reloadData()
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
        //fetchStudentsFromCoreData()
    }
    
    
//    func fetchStudentsFromCoreData() {
//        let predicate = NSPredicate(value: true)
//
//        let request = NSFetchRequest<Student>.init(entityName: "Student")
//        request.predicate = predicate
//
//        do {
//            let results = try context?.fetch(request)
//            for r:Student in results! {
//                r.ckrecordID = r.recordID
//            }
//            coreDataStudents = results!
//
//            print("\(coreDataStudents.count) Students")
//            self.tableView.reloadData()
//        } catch {
//            print(error.localizedDescription)
//        }
//
//    }
    
    
//    func fetchStudentsFromCloud() {
//
//        let predicate = NSPredicate(value: true)
//
//        let query = CKQuery(recordType: "Student", predicate: predicate)
//
//        database.perform(query, inZoneWith: nil) { [unowned self] results, error in
//            if let error = error {
//                DispatchQueue.main.async {
//                    //self.delegate?.errorUpdating(error as NSError)
//                    print("Cloud Query Error - Fetch Students: \(error)")
//                }
//                return
//            }
//            self.students.removeAll(keepingCapacity: true)
//            results?.forEach({ (record: CKRecord) in
//                self.students.append(record)
//            })
//            DispatchQueue.main.async {
//                //self.delegate?.modelUpdated()
//                print("Retrieved \(self.students.count) students")
//                self.tableView.reloadData()
//            }
//        }
//    }
    
    
    func updateRecordInCoreData(_ recordID:CKRecord.ID) {
        let recordName = recordID.recordName
        //let predicate = NSPredicate(format: "recordName == %@", recordName)
        let predicate = NSPredicate(format: "recordName == %@", recordName)
        let fetchRequest = NSFetchRequest<Student>(entityName: "Student")
        fetchRequest.predicate = predicate
        do {
            let students = try context?.fetch(fetchRequest)
            if students != nil {
                for s:Student in students! {
                    if s.recordName == recordName {
                        database.fetch(withRecordID: recordID, completionHandler: {(r,err) in
                            if let err = err {
                                print(err.localizedDescription)
                            } else {
                                print("Modifying core data on Mac")
                                s.firstName = r?["firstName"]
                                s.lastName = r?["lastName"]
                                s.phone = r?["phone"]
                                s.recordName = r?["recordName"]
                                s.lastUpdate = Date()
                                DispatchQueue.main.async {
                                    do {
                                        NotificationCenter.default.removeObserver(self)
                                        try self.context?.save()
                                        self.tableView.reloadData()
                                        NotificationCenter.default.addObserver(self, selector: #selector(self.contextObjectsDidChange(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: nil)

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

    // MARK: -- TABLE VIEW
//    func numberOfRows(in tableView: NSTableView) -> Int {
//        // return self.coreDataStudents.count
//        context?.registeredObjects.count
//    }
//
//    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//
//    }
//    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//
//        if (tableColumn?.title == "Name") {
//            if let returnVal = coreDataStudents[row].value(forKey: "firstName") as! String? {
//                do {
//                    if let ln = coreDataStudents[row].value(forKey: "lastName") as! String? {
//                        let s = returnVal + " " + ln
//                        if (s == "New Student") {
//                            //let ls = NSLocalizedString("new-student", tableName: "Localizable.strings", bundle: Bundle.main, value: "New Student", comment: "new-student")
//                            // print(ls)
//                            return NSLocalizedString("new-student", tableName: "Localizable.strings", bundle: Bundle.main, value: "New Student", comment: "new-student")
//                        } else {
//                            return returnVal + " " + ln
//                        }
//                    } else {
//                        return returnVal
//                    }
//                }
//            } else {
//                return "NA"
//            }
//        } else {
//
//            if let returnVal = coreDataStudents[row].value(forKey: "phone") as! String?  {
//                do {
//                    return returnVal
//                }
//            } else {
//                return "NA"
//            }
//        }
//    }
    
    // MARK: -- Handle Cloud Kit Notifications

    func deletedCloudKitRecord(_ id:String) {
        
    }
    
    func changedCloudKitRecord(_ id:String) {
        
    }
    
    func fetchAndAddRecordToCoreData(_ recordID:CKRecord.ID) {
        database.fetch(withRecordID: recordID, completionHandler: { (r,err) in
            if let err = err {
                print(err)
            } else {
                self.addCloudKitRecordToCoreData(r!)
                print(r?.value(forKey: "firstName") ?? "No Name")
                
            }
        })
    }
    
    
//    @objc func handleCloudKitNotification(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
//
//        guard let ck = userInfo["ck"] as? [String: AnyObject] else {
//            return
//        }
//
//        guard let qry = ck["qry"] as? [String: AnyObject] else {
//            return
//        }
//
//        let recordIDString = qry["rid"] as! String
//        let id = CKRecord.ID(recordName: recordIDString)
//        let record = CKRecord(recordType: "Student", recordID: id)
//
//        let options = CKQuerySubscription.Options( rawValue: qry["fo"] as! UInt )
//        switch options {
//        case .firesOnRecordCreation:
//            print("FIRE ON RECORD CREATION")
//            // addedCloudKitRecord(record)
//            break
//        case .firesOnRecordDeletion:
//            print("FIRE ON RECORD DELETE")
//            break
//        case .firesOnRecordUpdate:
//            print("FIRE ON UPDATE")
//            break
//        case [.firesOnRecordCreation, .firesOnRecordUpdate]:
//            print("FIRE ON DELETE")
//        default:
//            print("DEFAULT \(options)")
//        }
//    }

}

