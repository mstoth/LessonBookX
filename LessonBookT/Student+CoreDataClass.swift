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
    var recordID: Data?
    
    
    var recordType: String = "Student"
    //var lastUpdate: Data?
    
    func managedObjectToRecord() -> CKRecord {
        guard let firstName = firstName, let lastName = lastName, let phone = phone else {
            fatalError("Required properties for record not set")
        }
        
        let categoryRecord = cloudKitRecord()
        categoryRecord["firstName"] = firstName as CKRecordValue
        categoryRecord["lastName"] = lastName as CKRecordValue
        categoryRecord["phone"] = phone as CKRecordValue
        return categoryRecord
    }
    

}
