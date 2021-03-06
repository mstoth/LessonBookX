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
    var ckrecordID: Data? { get set }
    //@NSManaged public var recordID: NSData?
    var ckrecordName: String? { get set }
    var recordType: String? { get set }
    //var lastUpdate: Data? { get set }
    
    func managedObjectToRecord() -> CKRecord
}

extension CloudKitManagedObject {
    
    var customZone: CKRecordZone {
        return CKRecordZone(zoneName: "LessonBook")
    }
    
    func prepareForCloudKit() {
        let uuid = UUID()
        ckrecordName = recordType! + "." + uuid.uuidString
        let _recordID = CKRecord.ID(recordName: ckrecordName!, zoneID: customZone.zoneID)
        do {
            self.ckrecordID = try NSKeyedArchiver.archivedData(withRootObject: _recordID, requiringSecureCoding: false)
            // try recordID = NSKeyedArchiver.archivedData(withRootObject: _recordID, requiringSecureCoding: false)  // NSKeyedArchiver.archivedData(withRootObject: _recordID)
            // try recordID = NSKeyedArchiver.value(forKey: <#T##String#>)
        } catch {
            print("Error preparing for cloud kit")
        }
    }
    
    func prepareForCloudKitWithCloudKitRecord(_ recordID:CKRecord.ID) {
        do {
            self.ckrecordID = try NSKeyedArchiver.archivedData(withRootObject: recordID, requiringSecureCoding: false)
        } catch {
            print(error)
        }
        ckrecordName = recordID.recordName
        
    }
    func zoneID() -> CKRecordZone.ID{
        return customZone.zoneID
    }
    
    func setCloudKitRecordID(_ id:CKRecord.ID) {
        do {
            self.ckrecordID = try NSKeyedArchiver.archivedData(withRootObject: id, requiringSecureCoding: false)
        } catch {
            print("Error encoding id")
        }
    }
    
    func cloudKitRecord(_ recordName:String) -> CKRecord? {
        let id = CKRecord.ID(recordName: recordName)
        return(CKRecord(recordType: "Student", recordID: id))
    }
    
    func cloudKitRecord() -> CKRecord? {
        return CKRecord(recordType: recordType!, recordID: cloudKitRecordID()!)
    }
    
    func cloudKitRecordID() -> CKRecord.ID? {
        //let r = try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [Data.self as! AnyObject.Type], from: recordID!) as! CKRecord.ID
        do {
            if (ckrecordID == nil) {
                return CKRecord.ID(recordName: ckrecordName ?? "None")
            }
            let r = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(ckrecordID!)
            return r as? CKRecord.ID
        } catch {
            return nil
        }
        
        //return NSKeyedUnarchiver.unarchiveObject(with: recordID!) as! CKRecord.ID
    }
}
