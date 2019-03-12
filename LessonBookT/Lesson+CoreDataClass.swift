//
//  Lesson+CoreDataClass.swift
//  LessonBookT
//
//  Created by Michael Toth on 3/11/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//
//

import Foundation
import CoreData
import CloudKit


@objc(Lesson)
public class Lesson: NSManagedObject, CloudKitManagedObject {
    var ckrecordID: Data?
    
    var ckrecordName: String?
    
    var recordType: String = "Lesson"
    
    func managedObjectToRecord() -> CKRecord {
        guard let date = date, let comment = comment else {
            fatalError("Required properties for record not set")
        }
        
        let lessonRecord = cloudKitRecord()
        lessonRecord!["date"] = date as CKRecordValue
        lessonRecord!["comment"] = comment as CKRecordValue
        return lessonRecord!    }
    
    
}

