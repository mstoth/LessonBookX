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


class ViewController: NSViewController, NSTableViewDelegate {

    //var detailViewController: DetailViewController? = nil
    //@objc dynamic var managedObjectContext: NSManagedObjectContext? = nil
    @IBOutlet var studentArrayController: NSArrayController!
    @IBOutlet var lessonArrayController: NSArrayController!
    @IBOutlet weak var lessonTableView: NSTableView!
    @IBOutlet weak var studentTableView: NSTableView!
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
    var changesFromCloud:Bool = false
    let privateSubscriptionId = "LessonBook"
    @objc dynamic var lessons:NSMutableSet? = nil
    @objc dynamic var lessonArray:[Lesson]? = nil
    @objc dynamic var selectedStudent:Student? = nil
    
    @IBOutlet var arrayController: NSArrayController!
    
    @IBOutlet weak var studentLabel: NSTextField!
    @IBOutlet weak var lessonLabel: NSTextField!
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
        
        lessonTableView.delegate = self
        studentTableView.delegate = self
        
        
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
    }

    @IBAction func addLesson(_ sender: Any) {
        let newLesson = Lesson(context:context!)
        lessonArray?.append(newLesson)
        let student = studentArrayController.selectedObjects.first as! Student
        student.addToLessons(newLesson)
        do {
            try context?.save()
        } catch {
            print(error)
        }
    }
    @IBAction func removeLesson(_ sender: Any) {
        let lessonToRemove = lessonArrayController.selectedObjects.first as! Lesson
        context?.delete(lessonToRemove)
        lessonArray?.remove(at: lessonTableView.selectedRow)
        do {
            try context?.save()
        } catch {
            print(error)
        }
        //let student = studentArrayController.selectedObjects.first as! Student
        //student.removeFromLessons(lessonToRemove)
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let table = notification.object as! NSTableView
        if table.identifier?.rawValue == "lessonTableView"  {
            return
        }
        if table.identifier?.rawValue == "studentTableView" {
            // let row = studentTableView.selectedRow
            if studentArrayController.selectedObjects.count > 0 {
                let student = studentArrayController.selectedObjects.first as! Student
                selectedStudent = student
                let predicate = NSPredicate { (rec, props) -> Bool in
                    let lsn = rec as! Lesson
                    if lsn.student?.recordName == self.selectedStudent?.recordName {
                        return true
                    }
                    return false
                }
                lessonArrayController.filterPredicate = predicate
                lessonArray = lessonArrayController.arrangedObjects as? [Lesson]
                lessonTableView.reloadData()
                let studentArray = studentArrayController.arrangedObjects as! [Student]
                var c = studentArray.count
                studentLabel.stringValue = "\(c) Students"
                c = lessonArray!.count
                lessonLabel.stringValue = "\(c) Lessons"
            }
        }
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
            // fetchDatabaseChanges(database: self.database, completion: completion)
            fetchChangesInDataBase()
            
        case .shared:
            print("Shared scope.")
            //fetchDatabaseChanges(database: self.sharedDB, databaseTokenKey: "shared", completion: completion)
            
        case .public:
            fatalError()
            
        }
    }
    
    
    func handleCKErrors(err:CKError) {
        let a: NSAlert = NSAlert()
        a.messageText = "CloudKit Error"
        a.informativeText = err.localizedDescription
        let c:CKError.Code = err.code
        
        a.informativeText.append(String(describing: err.code))
        a.informativeText.append(String(describing:c.hashValue))
        a.addButton(withTitle: "OK")
        a.alertStyle = NSAlert.Style.warning
        
        a.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse: NSApplication.ModalResponse) -> Void in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                // do nothing
            }
        })
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
        print("Using previous token =  ", String(describing: previousToken))
        let zoneConfiguration = CKFetchRecordZoneChangesOperation.ZoneConfiguration(previousServerChangeToken: previousToken, resultsLimit: nil, desiredKeys: ["firstName","lastName","phone","recordName","street1","street2","city","state","zip","cell","email","photo"])
        let zone = CKRecordZone(zoneName: "LessonBook")
        let zoneID = zone.zoneID

        let operation = CKFetchRecordZoneChangesOperation.init()
        operation.recordZoneIDs = [zoneID]
        operation.configurationsByRecordZoneID = [zoneID:zoneConfiguration]
        
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
                self.handleCKErrors(err: error as! CKError)
                // print(error)
            }
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
            // Flush record changes and deletions for this zone to disk
            // Write this new zone change token to disk
            print("in recordZoneChangeTokensUpdatedBlock", token as Any)
            print("Saving token from server = ",String(describing: token))
            let tokenData = try! NSKeyedArchiver.archivedData(withRootObject: token as Any, requiringSecureCoding: true)
            UserDefaults.standard.set(tokenData, forKey: "LessonBook databaseChangeToken")
            
        }
        
        operation.recordZoneFetchCompletionBlock = {
            (zoneID: CKRecordZone.ID,
            serverChangeToken: CKServerChangeToken?,
            clientChangeTokenData: Data?,
            moreComing: Bool,
            error: Error?) in
            // do something with the token??
            print("in recordZoneFetchCompletionBlock")
            print("Saving token = ", String(describing: serverChangeToken))
            let tokenData = try! NSKeyedArchiver.archivedData(withRootObject: serverChangeToken as Any, requiringSecureCoding: true)
            UserDefaults.standard.set(tokenData, forKey: "LessonBook databaseChangeToken")

        }
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            print("in fetchRecordZoneChangesCompletionBlock")
            if (error != nil) {
                self.handleCKErrors(err: error as! CKError)
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
            if students?.count == 0 {
                print("in recordChangedBlock, didn't find the record in core data")
                let s=Student(context: self.context!)
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
                print("in recordChangedBlock, did find the record in core data")

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
                    if let asset = record["photo"] as? CKAsset,
                        let data = NSData(contentsOf: (asset.fileURL)) {
                        s.photo = data
                    }
                    s.recordName = recordName
                }
            }

        }
        
        database.add(operation)

    }

    
    
    @IBAction func editStudent(_ sender: Any) {
        
        
    }
    
    
    @IBAction func addNewStudent(_ sender: Any) {
        let delegate = NSApp.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        let newStudent = Student(context:context)
        newStudent.prepareForCloudKit()
        // let ccr = newStudent.cloudKitRecord()
        print("Adding New Student.")
        newStudent.firstName = "New"
        newStudent.lastName = "Student"
        newStudent.phone = ""
        newStudent.street1 = ""
        newStudent.street2 = ""
        newStudent.city = ""
        newStudent.state = ""
        newStudent.zip = ""
        newStudent.email = ""
        newStudent.cell = ""
        newStudent.recordID = newStudent.ckrecordID
        newStudent.recordName = newStudent.cloudKitRecordID()?.recordName
        do {
            try context.save()
            print("New student saved to core data")
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }

        } catch {
            print(error.localizedDescription)
        }
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

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @objc func contextObjectsDidChange(_ notification:NSNotification) {
        print("Context Objects Did Change.")
        if changesFromCloud {
            changesFromCloud = false
            print("IGNORING")
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
                    self.z?.saveStudentToCloud(s)

                } else {
                    self.z?.saveStudentToCloud(s)
                }
            }
        }

        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<Student>, updates.count > 0 {
            print("Core Data Changed Notification")
            for s:Student in updates {
                self.z?.saveStudentToCloud(s)
//                let recordName = s.recordName
//                // let recordID = CKRecord.ID(recordName: recordName)
//                // let recordID=s.cloudKitRecordID()
//                let predicate = NSPredicate(format: "recordName == %@", recordName!)
//                let query = CKQuery(recordType: "Student", predicate: predicate)
//                database.perform(query, inZoneWith: z?.zoneID, completionHandler: {(recs,err) in
//                    if err != nil {
//                        let ckerror = err as! CKError
//                        if ckerror.code == CKError.unknownItem {
//                            print("Unknown Item")
//                            //let recordID = CKRecord.ID(recordName: s.recordName!, zoneID: s.zoneID())
//
//                            self.z?.saveStudentToCloud(s)
//                        }
//                    } else {
//                        for r:CKRecord in recs! {
//                            //if !(r["phone"]==s.phone && r["firstName"]==s.firstName && r["lastName"]==s.lastName) {
//                            print("Setting Record Values for \(recs!.count) records")
//                            self.z?.saveStudentToCloud(s)
////
//                        }
//                    }
//                })
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
            do {
                try context!.save()
            } catch {
                print(error)
            }
        }
    }

    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        let students = arrayController.selectedObjects
        let student = students?.first as! Student
        let recordName = student.recordName
        
        if segue.identifier == "editStudent" {
            (segue.destinationController as! EditStudentProfileController).context = context
            (segue.destinationController as! EditStudentProfileController).recordName = student.recordName
            (segue.destinationController as! EditStudentProfileController).studentToEdit = student
        }
        
        if segue.identifier == "lessons" {
            (segue.destinationController as! LessonViewController).context = context
            (segue.destinationController as! LessonViewController).recordName = recordName
            (segue.destinationController as! LessonViewController).student = student
        }
    }
    
    
    
    // MARK: -- Handle Cloud Kit Notifications

    func deletedCloudKitRecord(_ id:String) {
    }
    
    func changedCloudKitRecord(_ id:String) {
    }
    

}

