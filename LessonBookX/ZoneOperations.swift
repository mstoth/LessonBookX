//
//  ZoneOperations.swift
//  LessonBookX
//
//  Created by Michael Toth on 2/12/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import Foundation
import Cocoa
import CloudKit
import NotificationCenter

class ZoneOperations {
    var zoneID:CKRecordZone.ID? = nil
    var container:CKContainer? = nil
    var database:CKDatabase? = nil
    
    init() {
        let zone = CKRecordZone(zoneName: "LessonBook")
        let fetchResult = CKFetchRecordZonesOperation(recordZoneIDs: [zone.zoneID])
        
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
        var fetchedRecordZones: [CKRecordZone.ID : CKRecordZone]? = nil
        let fetchZonesOperation = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
        fetchZonesOperation.fetchRecordZonesCompletionBlock = {
            (recordZones: [CKRecordZone.ID : CKRecordZone]?, error: Error?) -> Void in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            if let recordZones = recordZones {
                fetchedRecordZones = recordZones
                
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

