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


class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    //var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    private var database = CKContainer.default().privateCloudDatabase
    private var container = CKContainer.default()
    let zoneID = CKRecordZone.ID(zoneName: "LessonBook", ownerName: CKCurrentUserDefaultName)
    @IBOutlet weak var tableView: NSTableView!
    
    func addCloudKitRecordToCoreData(_ ckRecord:CKRecord) {
        let delegate = NSApp.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext

        let newStudent = Student(context: context)
        newStudent.firstName = ckRecord.value(forKey: "firstName") as? String
        newStudent.lastName = ckRecord.value(forKey: "lastName") as? String
        newStudent.phone = ckRecord.value(forKey: "phone") as? String
        do {
            newStudent.recordID = try NSKeyedArchiver.archivedData(withRootObject: ckRecord.recordID, requiringSecureCoding: false)
        } catch {
            print(error.localizedDescription)
        }
        newStudent.recordName = ckRecord.value(forKey: "recordName") as? String
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
            }
        })
        
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
            coreDataStudents.remove(at: row)
            
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
    
    var storeChangeObserver:AnyObject? = nil
    var students:[CKRecord] = []
    var coreDataStudents:[Student] = []
    let delegate = NSApp.delegate
    
    //private var database = CKContainer.init(identifier: "iCloud.com.virtualpianist.LessonBook").privateCloudDatabase
    //private var database = CKContainer.default().privateCloudDatabase

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let containerIdentifier = String(CKContainer.default().containerIdentifier!)
        let lessonBookLoc = containerIdentifier.lastIndex(of: "k")!
        let newContainerIdentifier = containerIdentifier[...lessonBookLoc]
        container = CKContainer.init(identifier: String(newContainerIdentifier))
        database = CKContainer.init(identifier: String(newContainerIdentifier)).privateCloudDatabase
        
        //  let predicate = NSPredicate(value: true)
//        let subscription = CKQuerySubscription(recordType: "Student", predicate: predicate,options:.firesOnRecordCreation)
//        database.fetchAllSubscriptions(completionHandler: {(sub,err) in
//            DispatchQueue.main.sync {
//                for s:CKSubscription in sub! {
//                    self.database.delete(withSubscriptionID: s.subscriptionID, completionHandler: {(sub,err) in
//                        // nothing to do
//                        if let err = err {
//                            print(err.localizedDescription)
//                        } else {
//                            print("Deleted subscription")
//                            print(s)
//                            let notificationInfo:CKSubscription.NotificationInfo = CKSubscription.NotificationInfo.init()
//                            notificationInfo.alertLocalizationKey = "Student Changed"
//                            notificationInfo.shouldBadge = true
//                            subscription.notificationInfo = notificationInfo
//                            self.database.save(subscription, completionHandler: {(s,error) in
//                                if ((error) != nil) {
//                                    print("Subscription error")
//                                    print(error?.localizedDescription as Any)
//                                } else {
//                                    print("Subscribed")
//                                }
//                            })
//
//                        }
//                    })
//                }
//            }
//        })


        let predicate = NSPredicate(value: true)
        
        let qSubscription = CKQuerySubscription(recordType: "Student", predicate: predicate, subscriptionID: "test",
                                                options: [.firesOnRecordCreation,.firesOnRecordUpdate, .firesOnRecordDeletion])
        
        qSubscription.notificationInfo?.shouldSendMutableContent = true
        
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        notificationInfo.shouldSendMutableContent = true
        notificationInfo.shouldBadge = true
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = ["firstName","lastName","phone"]
        
        // notificationInfo.perform(#selector(handleNotification))
        qSubscription.notificationInfo = notificationInfo
        
        database.save(qSubscription,completionHandler: {(sub,error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Saved Subscription")
            }
        })

        // Do any additional setup after loading the view.
        CKContainer.default().fetchUserRecordID(completionHandler: {(record,error) in
            if let error = error {
                print(error)
            } else {
                print(record.debugDescription)
            }
        })
        fetchStudentsFromCoreData()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func fetchStudentsFromCoreData() {
        let delegate = NSApp.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        let request = NSFetchRequest<Student>.init(entityName: "Student")
        do {
            let results = try context.fetch(request)
            for r:Student in results {
                r.ckrecordID = r.recordID
            }
            coreDataStudents = results
            
            //for s:Student in coreDataStudents {
                //context.delete(s)
            //}
            // try! context.save()
            
            // coreDataStudents.removeAll()
            print("\(coreDataStudents.count) Students")
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
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.coreDataStudents.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        if (tableColumn?.title == "Name") {
            if let returnVal = coreDataStudents[row].value(forKey: "firstName") as! String? {
                do {
                    if let ln = coreDataStudents[row].value(forKey: "lastName") as! String? {
                        let s = returnVal + " " + ln
                        if (s == "New Student") {
                            //let ls = NSLocalizedString("new-student", tableName: "Localizable.strings", bundle: Bundle.main, value: "New Student", comment: "new-student")
                            // print(ls)
                            return NSLocalizedString("new-student", tableName: "Localizable.strings", bundle: Bundle.main, value: "New Student", comment: "new-student")
                        } else {
                            return returnVal + " " + ln
                        }
                    } else {
                        return returnVal
                    }
                }
            } else {
                return "NA"
            }
        } else {
            
            if let returnVal = coreDataStudents[row].value(forKey: "phone") as! String?  {
                do {
                    return returnVal
                }
            } else {
                return "NA"
            }
        }
    }
    
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
//    @objc func handleNotification(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
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
//            addedCloudKitRecord(record)
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

