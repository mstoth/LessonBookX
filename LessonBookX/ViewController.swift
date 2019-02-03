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

    @IBOutlet weak var tableView: NSTableView!
    var storeChangeObserver:AnyObject? = nil
    var students:[CKRecord] = []
    var coreDataStudents:[Student] = []
    let delegate = NSApp.delegate
    
    //private var database = CKContainer.init(identifier: "iCloud.com.virtualpianist.LessonBook").privateCloudDatabase
    private var database = CKContainer.default().privateCloudDatabase

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let containerIdentifier = String(CKContainer.default().containerIdentifier!)
        let lessonBookLoc = containerIdentifier.lastIndex(of: "k")!
        let newContainerIdentifier = containerIdentifier[...lessonBookLoc]
        database = CKContainer.init(identifier: String(newContainerIdentifier)).privateCloudDatabase
        
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: "Student", predicate: predicate,options:.firesOnRecordUpdate)
        database.fetchAllSubscriptions(completionHandler: {(sub,err) in
            for s:CKSubscription in sub! {
                self.database.delete(withSubscriptionID: s.subscriptionID, completionHandler: {(sub,err) in
                    // nothing to do
                    print("Deleted")
                    print(s)
                })
            }
            let notificationInfo:CKSubscription.NotificationInfo = CKSubscription.NotificationInfo.init()
            notificationInfo.alertLocalizationKey = "Student Changed"
            notificationInfo.shouldBadge = true
            subscription.notificationInfo = notificationInfo
            self.database.save(subscription, completionHandler: {(s,error) in
                if ((error) != nil) {
                    print("Subscription error")
                    print(error?.localizedDescription as Any)
                } else {
                    print("Subscribed")
                }
            })
        
        })

        
        
        database.save(subscription, completionHandler: {(s,error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Subscribed")
                DispatchQueue.main.sync {
                    self.tableView.reloadData()
                }
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
            coreDataStudents = results
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
                            let ls = NSLocalizedString("new-student", tableName: "Localizable.strings", bundle: Bundle.main, value: "New Student", comment: "new-student")
                            print(ls)
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
}

