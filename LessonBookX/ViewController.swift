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

class StudentModel {
    //private let database = CKContainer.init(identifier: "iCloud.com.virtualpianist.LessonBook").privateCloudDatabase
}


class ViewController: NSViewController {

    //var detailViewController: DetailViewController? = nil
    @objc dynamic var managedObjectContext: NSManagedObjectContext? = nil
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
        notificationInfo.desiredKeys = ["firstName","lastName","phone"]
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
        fetchStudentsFromCoreData()
        
    }

    
    
    
    
    
    
    func addCloudKitRecordToCoreData(_ ckRecord:CKRecord) {
        let delegate = NSApp.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext

        let newStudent = Student(context: context)
        newStudent.prepareForCloudKitWithCloudKitRecord(ckRecord.recordID)
        newStudent.firstName = ckRecord["firstName"]
        newStudent.lastName = ckRecord["lastName"]
        newStudent.phone = ckRecord["phone"]
        
        do {
            try context.save()
            coreDataStudents.append(newStudent)
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
                print(rec?.value(forKey:"RecordName"))
            }
        })
        
    }
    
    func recordRemovedFromCloudKit(_ recordID:CKRecord.ID) {
        var row = 0
        for s:Student in coreDataStudents {
            if s.cloudKitRecordID() == recordID {
                context?.delete(s)
                do {
                    try context?.save()
                    coreDataStudents.remove(at: row)
                } catch {
                    print(error.localizedDescription)
                }
            }
            row = row + 1
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
        guard let userInfo = notification.userInfo else { return }
        
        // print(notification)
        

        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<Student>, inserts.count > 0 {
            for s:Student in inserts {
                s.prepareForCloudKit()
                database.save(s.cloudKitRecord()!, completionHandler: {(r,err) in
                    if let err = err {
                        print(err.localizedDescription)
                    } else {
                        print("Saved record to cloud")
                    }
                })
            }
            // print(inserts)
        }
        
        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<Student>, updates.count > 0 {
            for s:Student in updates {
                database.fetch(withRecordID: s.cloudKitRecordID()!, completionHandler: {(r,err) in
                    if let err = err {
                        print(err.localizedDescription)
                    } else {
                        r?["phone"]=s.phone
                        r?["firstName"]=s.firstName
                        r?["lastName"]=s.lastName
                        
                        self.database.save(r!, completionHandler: {(r,err) in
                            if let err = err {
                                print(err.localizedDescription)
                            } else {
                                print("saved record to cloud for update")
                            }
                        })

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
        
        DispatchQueue.main.async {
            do {
                try self.context?.save()
            } catch {
                print(error.localizedDescription)
            }
        }
        //fetchStudentsFromCoreData()
    }
    
    
    func fetchStudentsFromCoreData() {
        let predicate = NSPredicate(value: true)
        
        let request = NSFetchRequest<Student>.init(entityName: "Student")
        request.predicate = predicate

        do {
            let results = try context?.fetch(request)
            for r:Student in results! {
                r.ckrecordID = r.recordID
            }
            coreDataStudents = results!
            
            print("\(coreDataStudents.count) Students")
            self.tableView.reloadData()
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    
    func fetchStudentsFromCloud() {
        
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
            self.students.removeAll(keepingCapacity: true)
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
                print(err.localizedDescription)
            } else {
                self.addCloudKitRecordToCoreData(r!)
                print(r?.value(forKey: "firstName") ?? "No Name")
                
            }
        })
    }
    
    
    @objc func handleCloudKitNotification(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {

        guard let ck = userInfo["ck"] as? [String: AnyObject] else {
            return
        }

        guard let qry = ck["qry"] as? [String: AnyObject] else {
            return
        }

        let recordIDString = qry["rid"] as! String
        let id = CKRecord.ID(recordName: recordIDString)
        let record = CKRecord(recordType: "Student", recordID: id)

        let options = CKQuerySubscription.Options( rawValue: qry["fo"] as! UInt )
        switch options {
        case .firesOnRecordCreation:
            print("FIRE ON RECORD CREATION")
            // addedCloudKitRecord(record)
            break
        case .firesOnRecordDeletion:
            print("FIRE ON RECORD DELETE")
            break
        case .firesOnRecordUpdate:
            print("FIRE ON UPDATE")
            break
        case [.firesOnRecordCreation, .firesOnRecordUpdate]:
            print("FIRE ON DELETE")
        default:
            print("DEFAULT \(options)")
        }
    }

}

