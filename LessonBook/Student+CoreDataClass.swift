//
//  Student+CoreDataClass.swift
//  LessonBookX
//
//  Created by Michael Toth on 1/30/19.
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
public class Student: NSManagedObject {
    // MARK: - Properties
    let StudentType = "Student"
    
    static let sharedInstance = Student()
    var delegate: StudentDelegate?
    var items: [Student] = []
    // let userInfo: UserInfo
    
    fileprivate static let recordType = "Student"
    fileprivate static let keys = (firstName : "firstName", lastName : "lastName")
    
    private let database = CKContainer.default().privateCloudDatabase
    @NSManaged public var record : CKRecord
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
        self.record = CKRecord(recordType: Student.recordType)
    }
    
    
    var name : String {
        get {
            //let s = self.record.value(forKey: Student.firstName!) as! String + " " + self.record.value(forKey: Student.lastName!) as! String
            return self.record.value(forKey: Student.keys.firstName) as! String
        }
        set {
            self.record.setValue(newValue, forKey: Student.keys.firstName)
        }
    }
    
    var studentItem:CKRecord? {
        didSet {
            
        }
    }
}
