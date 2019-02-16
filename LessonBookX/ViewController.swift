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
    
    
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let delegate = NSApp.delegate as! AppDelegate
        context = delegate.persistentContainer.viewContext
        
        let containerIdentifier = String(CKContainer.default().containerIdentifier!)
        let lessonBookLoc = containerIdentifier.lastIndex(of: "k")!
        let newContainerIdentifier = containerIdentifier[...lessonBookLoc]
        container = CKContainer.init(identifier: String(newContainerIdentifier))
        database = CKContainer.init(identifier: String(newContainerIdentifier)).privateCloudDatabase
        
        // resetAllRecords(in: "Student")
        
        let predicate = NSPredicate(value: true)
        
        let qSubscription = CKQuerySubscription(recordType: "Student", predicate: predicate, subscriptionID: "lessonbook",
                                                options: [.firesOnRecordCreation,.firesOnRecordUpdate, .firesOnRecordDeletion])
        
        qSubscription.notificationInfo?.shouldSendMutableContent = true
        
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.shouldSendMutableContent = true
        notificationInfo.shouldBadge = true
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = ["firstName","lastName","phone","recordName"]
        // notificationInfo.perform(#selector(handleCloudKitNotification))
        qSubscription.notificationInfo = notificationInfo
        database.save(qSubscription, completionHandler: {(sub,err) in
            if let err = err {
                print(err.localizedDescription)
            } else {
                print("saved subscription")
            }
        })
        z = ZoneOperations()
        
        NotificationCenter.default.addObserver(self, selector: #selector(contextObjectsDidChange(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
//        fetchStudentsFromCoreData()
        
    }

    
    
    
    
    
    
    func addCloudKitRecordToCoreData(_ ckRecord:CKRecord) {
        //let delegate = NSApp.delegate as! AppDelegate
        //let context = delegate.persistentContainer.viewContext

        let newStudent = Student(context: context!)
        newStudent.prepareForCloudKitWithCloudKitRecord(ckRecord.recordID)
        newStudent.firstName = ckRecord["firstName"]
        newStudent.lastName = ckRecord["lastName"]
        newStudent.phone = ckRecord["phone"]
        newStudent.recordName = ckRecord["recordName"]
        // newStudent.recordName = ckRecord.recordID.recordName
        do {
            try context?.save()
            //coreDataStudents.append(newStudent)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        } catch {
            print(error.localizedDescription)
        }
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
                // if recordName is nil, need to send it up to the cloud
                if s.recordName == nil {
                    s.prepareForCloudKit()
                    s.recordName = s.cloudKitRecordID()?.recordName
                    let ccr = s.cloudKitRecord()
                    ccr?["firstName"]=s.firstName
                    ccr?["lastName"]=s.lastName
                    ccr?["phone"]=s.phone
                    ccr?["recordName"]=s.recordName
//                    database.save(ccr!, completionHandler: {(r,err) in
//                        if err == nil {
//                            print("saved new record to cloud")
//                        }
//                    })
                }
                DispatchQueue.main.async {
                    do {
                        try self.context?.save()
                    } catch {
                        print(error)
                    }
                }
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
            }
            // print(inserts)
        }
        
        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<Student>, updates.count > 0 {
            print("Core Data Changed Notification")
            for s:Student in updates {
                let recordName=s.recordName
                let recordID = CKRecord.ID(recordName: recordName!)
                database.fetch(withRecordID: recordID, completionHandler: {(r,err) in
                    if err != nil {
                        // didn't find record. upload
                        let ckerror = err as! CKError
                        if ckerror.code == CKError.unknownItem {
                            let r = s.cloudKitRecord(s.recordName!)
                            
                            r?["phone"]=s.phone
                            r?["firstName"]=s.firstName
                            r?["lastName"]=s.lastName
                            r?["recordName"]=s.recordName
                            DispatchQueue.main.async {
                                self.database.save(r!, completionHandler: {(r,err) in
                                    if let err = err {
                                        print("error from saving update to cloud")
                                        print(err.localizedDescription)
                                    } else {
                                        print("saved record to cloud for update")
                                        print(s.recordName)
                                    }
                                })
                                
                            }

                        } else {
                            print("Unknown error from fetch.")
                            print(ckerror.localizedDescription)
                        }
                    } else {
                        if !(r?["phone"]==s.phone && r?["firstName"]==s.firstName &&
                            r?["recordName"]==s.recordName && r?["lastName"]==s.lastName) {
                            r?["phone"]=s.phone
                            r?["firstName"]=s.firstName
                            r?["lastName"]=s.lastName
                            r?["recordName"]=s.recordName
                            let recordArray = [r!]
                            let modifyRecords = CKModifyRecordsOperation.init()
                            modifyRecords.recordsToSave = recordArray
                            modifyRecords.savePolicy = .allKeys
                            modifyRecords.qualityOfService = .background
                            self.database.add(modifyRecords)
                            

                        }
                    }
                })

            }
        }
        
        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<Student>, deletes.count > 0 {
            // print(deletes)
            for s:Student in deletes {
                database.delete(withRecordID: s.cloudKitRecordID()!, completionHandler: {(rid,err) in
                    if let err = err {
                        print(err.localizedDescription)
                    } else {
                        print("student deleted from cloud")
                    }
                })
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
                                s.firstName = r?["firstName"]
                                s.lastName = r?["lastName"]
                                s.phone = r?["phone"]
                                s.recordName = r?["recordName"]
                                DispatchQueue.main.async {
                                    do {
                                        try self.context?.save()
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

