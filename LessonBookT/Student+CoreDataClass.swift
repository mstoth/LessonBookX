//
//  Student+CoreDataClass.swift
//  LessonBookX
//
//  Created by Michael Toth on 2/2/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//
//

import Foundation
import CoreData
import CloudKit

@objc(Student)
public class Student: NSManagedObject,  CloudKitManagedObject {
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
    
    func fullName() -> String {
        let fn = self.firstName ?? "No"
        let ln = self.lastName ?? "Name"
        return fn + " " + ln
    }

}
