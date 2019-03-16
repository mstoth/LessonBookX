//
//  ZoneOperations.swift
//  LessonBookX
//
//  Created by Michael Toth on 2/12/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import Foundation
import NotificationCenter
import CloudKit


public enum CKErrorCode : Int {
    case InternalError /* CloudKit.framework encountered an error.  This is a non-recoverable error. */
    case PartialFailure /* Some items failed, but the operation succeeded overall */
    case NetworkUnavailable /* Network not available */
    case NetworkFailure /* Network error (available but CFNetwork gave us an error) */
    case BadContainer /* Un-provisioned or unauthorized container. Try provisioning the container before retrying the operation. */
    case ServiceUnavailable /* Service unavailable */
    case RequestRateLimited /* Client is being rate limited */
    case MissingEntitlement /* Missing entitlement */
    case NotAuthenticated /* Not authenticated (writing without being logged in, no user record) */
    case PermissionFailure /* Access failure (save or fetch) */
    case UnknownItem /* Record does not exist */
    case InvalidArguments /* Bad client request (bad record graph, malformed predicate) */
    case ResultsTruncated /* Query results were truncated by the server */
    case ServerRecordChanged /* The record was rejected because the version on the server was different */
    case ServerRejectedRequest /* The server rejected this request.  This is a non-recoverable error */
    case AssetFileNotFound /* Asset file was not found */
    case AssetFileModified /* Asset file content was modified while being saved */
    case IncompatibleVersion /* App version is less than the minimum allowed version */
    case ConstraintViolation /* The server rejected the request because there was a conflict with a unique field. */
    case OperationCancelled /* A CKOperation was explicitly cancelled */
    case ChangeTokenExpired /* The previousServerChangeToken value is too old and the client must re-sync from scratch */
    case BatchRequestFailed /* One of the items in this batch operation failed in a zone with atomic updates, so the entire batch was rejected. */
    case ZoneBusy /* The server is too busy to handle this zone operation. Try the operation again in a few seconds. */
    case BadDatabase /* Operation could not be completed on the given database. Likely caused by attempting to modify zones in the public database. */
    case QuotaExceeded /* Saving a record would exceed quota */
    case ZoneNotFound /* The specified zone does not exist on the server */
    case LimitExceeded /* The request to the server was too large. Retry this request as a smaller batch. */
    case UserDeletedZone /* The user deleted this zone through the settings UI. Your client should either remove its local data or prompt the user before attempting to re-upload any data to this zone. */
}



class ZoneOperations {
    var zoneID:CKRecordZone.ID? = nil
    var container:CKContainer? = nil
    var database:CKDatabase? = nil
    
    init() {
        let zone = CKRecordZone(zoneName: "LessonBook")
        zoneID = zone.zoneID
        //let fetchResult = CKFetchRecordZonesOperation(recordZoneIDs: [zone.zoneID])
        
        let containerIdentifier = String(CKContainer.default().containerIdentifier!)
        let lessonBookLoc = containerIdentifier.lastIndex(of: "k")!
        let newContainerIdentifier = containerIdentifier[...lessonBookLoc]
        container = CKContainer.init(identifier: String(newContainerIdentifier))
        database = CKContainer.init(identifier: String(newContainerIdentifier)).privateCloudDatabase
        fetchAllZones(completion: {e in
            if let e = e {
                print(e.localizedDescription)
            }
        })

        }
    
    func errorCodeToString(_ errorCode:CKErrorCode) -> String {
        switch errorCode {
        case CKErrorCode.InternalError:
            return "CloudKit.framework encountered an error.  This is a non-recoverable error."
        case CKErrorCode.PartialFailure:
            return "Some items failed, but the operation succeeded overall "
        case CKErrorCode.NetworkUnavailable:
            return "Some items failed, but the operation succeeded overall "
        case CKErrorCode.NetworkFailure:
            return "Network error (available but CFNetwork gave us an error)"
        case CKErrorCode.BadContainer:
            return "Un-provisioned or unauthorized container. Try provisioning the container before retrying the operation."
        case CKErrorCode.ServiceUnavailable:
            return "Service unavailable"
        case CKErrorCode.RequestRateLimited:
            return "Client is being rate limited "
        case CKErrorCode.MissingEntitlement:
            return "Client is being rate limited "
        case CKErrorCode.NotAuthenticated: /* Not authenticated (writing without being logged in, no user record) */
            return "Not authenticated (writing without being logged in, no user record)"
        case CKErrorCode.PermissionFailure: /* Access failure (save or fetch) */
            return " /* Access failure (save or fetch) */"
        case CKErrorCode.UnknownItem: /* Record does not exist */
            return " /* Record does not exist */"
        case CKErrorCode.InvalidArguments: /* Bad client request (bad record graph, malformed predicate) */
            return " /* Bad client request (bad record graph, malformed predicate) */"
        case CKErrorCode.ResultsTruncated: /* Query results were truncated by the server */
            return " /* Query results were truncated by the server */"
        case CKErrorCode.ServerRecordChanged: /* The record was rejected because the version on the server was different */
            return " /* The record was rejected because the version on the server was different */"
        case CKErrorCode.ServerRejectedRequest: /* The server rejected this request.  This is a non-recoverable error */
            return " /* The server rejected this request.  This is a non-recoverable error */"
        case CKErrorCode.AssetFileNotFound: /* Asset file was not found */
            return " /* Asset file was not found */"
        case CKErrorCode.AssetFileModified:  /* Asset file content was modified while being saved */
            return " /* Asset file content was modified while being saved */"
        case CKErrorCode.IncompatibleVersion: /* App version is less than the minimum allowed version */
            return " /* App version is less than the minimum allowed version */"
        case CKErrorCode.ConstraintViolation: /* The server rejected the request because there was a conflict with a unique field. */
            return " /* The server rejected the request because there was a conflict with a unique field. */"
        case CKErrorCode.OperationCancelled: /* A CKOperation was explicitly cancelled */
            return " /* A CKOperation was explicitly cancelled */"
        case CKErrorCode.ChangeTokenExpired: /* The previousServerChangeToken value is too old and the client must re-sync from scratch */
            return " /* The previousServerChangeToken value is too old and the client must re-sync from scratch */"
        case CKErrorCode.BatchRequestFailed: /* One of the items in this batch operation failed in a zone with atomic updates, so the entire batch was rejected. */
            return " /* One of the items in this batch operation failed in a zone with atomic updates, so the entire batch was rejected. */"
        case CKErrorCode.ZoneBusy: /* The server is too busy to handle this zone operation. Try the operation again in a few seconds. */
            return " /* The server is too busy to handle this zone operation. Try the operation again in a few seconds. */"
        case CKErrorCode.BadDatabase: /* Operation could not be completed on the given database. Likely caused by attempting to modify zones in the public database. */
            return " /* Operation could not be completed on the given database. Likely caused by attempting to modify zones in the public database. */"
        case CKErrorCode.QuotaExceeded: /* Saving a record would exceed quota */
            return " /* Saving a record would exceed quota */"
        case CKErrorCode.ZoneNotFound: /* The specified zone does not exist on the server */
            return " /* The specified zone does not exist on the server */"
        case CKErrorCode.LimitExceeded: /* The request to the server was too large. Retry this request as a smaller batch. */
            return " /* The request to the server was too large. Retry this request as a smaller batch. */"
        case CKErrorCode.UserDeletedZone: /* The user deleted this zone through the settings UI. Your client should either remove its local data or prompt the user before attempting to re-upload any data to this zone. */
            return " /* The user deleted this zone through the settings UI. Your client should either remove its local data or prompt the user before attempting to re-upload any data to this zone. */"
//        default:
//            return "unknown error code"
        }
    }

    func fetchAllZones(completion: @escaping (Error?) -> Void)
    {
        // Check if zone already exists
        //var fetchedRecordZones: [CKRecordZone.ID : CKRecordZone]? = nil
        let fetchZonesOperation = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
        fetchZonesOperation.fetchRecordZonesCompletionBlock = {
            (recordZones: [CKRecordZone.ID : CKRecordZone]?, error: Error?) -> Void in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            if let recordZones = recordZones {
                //fetchedRecordZones = recordZones
                
                for recordID in recordZones.keys {
                    if recordID.zoneName == "LessonBook" {
                        self.zoneID = recordID
                        print("LessonBook Zone Exists.")
                        break
                    }
                    let zone = CKRecordZone(zoneName: "LessonBook")
                    self.zoneID = zone.zoneID
                    
                    self.database?.save(zone, completionHandler: {(z,err) in
                        if let err = err {
                            print(err.localizedDescription)
                            let cke = err as! CKError
                            let code = CKErrorCode(rawValue: cke.errorCode)
                            print(self.errorCodeToString(code!))
                        } else {
                            print("Zone saved.")
                            print(zone.zoneID.zoneName)
                        }
                    })
                }
            }
            completion(nil)
        }
        fetchZonesOperation.qualityOfService = .utility
//        container = CKContainer.default()
//        let db = container?.privateCloudDatabase
//        db?.add(fetchZonesOperation)
        database?.add(fetchZonesOperation)

    }
    
    func saveLessonToCloud(_ lesson:Lesson, student:Student, calledBy:String = "Unknown") {
        let predicate = NSPredicate(format: "recordName == %@", lesson.recordName!)
        let req = NSFetchRequest<Lesson>(entityName: "Lesson")
        req.predicate = predicate
        let z = ZoneOperations()
        let ckid = CKRecord.ID(recordName: lesson.recordName!, zoneID: z.zoneID!)
        database?.fetch(withRecordID: ckid, completionHandler: {(rec,err) in
            if let err = err {
                print(err)
            } else {
                rec?["date"]=lesson.date
                rec?["comment"]=lesson.comment
                let ckid = CKRecord.ID(recordName: student.recordName!)
                let ref = CKRecord.Reference(recordID: ckid, action: .none)
                rec?["student"]=ref
                let modifyRec = CKModifyRecordsOperation(recordsToSave: [rec!], recordIDsToDelete: [])
                modifyRec.modifyRecordsCompletionBlock = { (recs,ids,err) in
                    if (err == nil) {
                        print("Modify Records Success.")
                    } else {
                        print(err as Any)
                    }
                }
                print("Attempting to modify lesson.")
                self.database?.add(modifyRec)
            }
        })
    }
    
    func saveStudentToCloud(_ student:Student, calledBy:String = "Unknown") {
        if student.recordName == nil {
            student.recordType = "Student"
            student.prepareForCloudKit()
            student.ckrecordName = student.recordName
        }
        let ccr = student.cloudKitRecord()
        //if !(ccr?["firstName"]==s.firstName && ccr?["lastName"]==s.lastName && ccr?["phone"]==s.phone ) {
        ccr?["firstName"]=student.firstName
        ccr?["lastName"]=student.lastName
        ccr?["phone"]=student.phone
        ccr?["recordName"]=student.recordName
        ccr?["street1"]=student.street1
        ccr?["street2"]=student.street2
        ccr?["city"]=student.city
        ccr?["state"]=student.state
        ccr?["zip"]=student.zip
        ccr?["cell"]=student.cell
        ccr?["email"]=student.email
        if (student.photo != nil) {
            do {
                try student.photo?.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("\(String(describing: student.recordName)).png"), options: .atomic)
                let asset = CKAsset(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(String(describing: student.recordName)).png"))
                ccr?["photo"]=asset
            } catch  {
                print(error)
            }
        }
        let modifyRecords = CKModifyRecordsOperation.init(recordsToSave: [ccr!], recordIDsToDelete: [])
        // modifyRecords.recordsToSave = recordArray
        modifyRecords.savePolicy = .allKeys
        
        modifyRecords.isAtomic = true
        modifyRecords.qualityOfService = .utility
        modifyRecords.modifyRecordsCompletionBlock = { (recs,rIDs,error) in
            print("Called by ",calledBy)
            if (error != nil) {
                print("ERROR IN MODIFYING CLOUD")
                let cke = error as! CKError
                let code = CKErrorCode(rawValue: cke.errorCode)
                print(self.errorCodeToString(code!))
            } else {
                print(recs?.count as Any," Students")
                print(recs?.first?.value(forKey: "recordName") as Any)
                print("MODIFIED CLOUD")
            }
        }
        print("Adding modifyRecords operation.")
        
        database?.add(modifyRecords)
        
    }
}

