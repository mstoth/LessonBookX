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
}

