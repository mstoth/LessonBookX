//
//  Student+CoreDataProperties.swift
//  LessonBookX
//
//  Created by Michael Toth on 2/2/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//
//

import Foundation
import CoreData


extension Student {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Student> {
        return NSFetchRequest<Student>(entityName: "Student")
    }

    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var street1: String?
    @NSManaged public var street2: String?
    @NSManaged public var city: String?
    @NSManaged public var state: String?
    @NSManaged public var zip: String?
    @NSManaged public var email: String?
    @NSManaged public var phone: String?
    @NSManaged public var uniqueIdentifier: String?
    @NSManaged public var balance: Float
    @NSManaged public var cell: String?
    @NSManaged public var photo: NSData?
    @NSManaged public var metaData: NSData?
    // @NSManaged public var recordID: String?
    @NSManaged public var recordName: String?
    // @NSManaged public var recordType: String?
    @NSManaged public var lastUpdate: Date?
}
