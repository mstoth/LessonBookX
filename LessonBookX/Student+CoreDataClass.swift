//
//  Student+CoreDataClass.swift
//  LessonBookX
//
//  Created by Michael Toth on 1/27/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//
//

import Foundation
import CoreData
import CloudKit

protocol StudentDelegate {
    func errorUpdating(_ error: NSError)
    func modelUpdated()
}

@objc(Student)
public class Student: NSManagedObject, CloudKitManagedObject {
    var ckrecordName: String?
    var ckrecordID: Data?
    
    @NSManaged public var recordID: Data?
    
    
    var recordType: String = "Student"
    //var lastUpdate: Data?
    
    func managedObjectToRecord() -> CKRecord {
        guard let firstName = firstName, let lastName = lastName, let phone = phone else {
            fatalError("Required properties for record not set")
        }
        
        let studentRecord = cloudKitRecord()
        studentRecord!["firstName"] = firstName as CKRecordValue
        studentRecord!["lastName"] = lastName as CKRecordValue
        studentRecord!["phone"] = phone as CKRecordValue
        return studentRecord!
    }
    
    func updateWithRecord(_ record: CKRecord) {
        firstName = record["firstName"] as? String
        lastName = record["lastName"] as? String
        phone = record["phone"] as? String
        recordName = record.recordID.recordName
        // recordID = try? NSKeyedArchiver.archivedData(withRootObject: record.recordID, requiringSecureCoding: false)
        do {
            recordID = try NSKeyedArchiver.archivedData(withRootObject: record.recordID, requiringSecureCoding: false)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func fullName() -> String {
        let fn = self.firstName ?? "No"
        let ln = self.lastName ?? "Name"
        return fn + " " + ln
    }
}
