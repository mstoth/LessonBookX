//
//  CloudKitManagedObject.swift
//  LessonBookT
//
//  Created by Michael Toth on 2/2/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import Foundation
import CloudKit

@objc protocol CloudKitManagedObject {
    var recordID: Data? { get set }
    var recordName: String? { get set }
    var recordType: String { get }
    //var lastUpdate: Data? { get set }
    
    func managedObjectToRecord() -> CKRecord
}

extension CloudKitManagedObject {
    
    var customZone: CKRecordZone {
        return CKRecordZone(zoneName: "LessonBook")
    }
    
    func prepareForCloudKit() {
        let uuid = UUID()
        recordName = recordType + "." + uuid.uuidString
        let _recordID = CKRecord.ID(recordName: recordName!, zoneID: customZone.zoneID)
        do {
            try recordID = NSKeyedArchiver.archivedData(withRootObject: _recordID, requiringSecureCoding: false)  // NSKeyedArchiver.archivedData(withRootObject: _recordID)
        } catch {
            print("Error preparing for cloud kit")
        }
    }
    
    func cloudKitRecord() -> CKRecord {
        return CKRecord(recordType: recordType, recordID: cloudKitRecordID())
    }
    
    func cloudKitRecordID() -> CKRecord.ID {
        
        let r = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [Data.self as! AnyObject.Type], from: recordID!) as! CKRecord.ID
        return r
        //return NSKeyedUnarchiver.unarchiveObject(with: recordID!) as! CKRecord.ID
    }
}
