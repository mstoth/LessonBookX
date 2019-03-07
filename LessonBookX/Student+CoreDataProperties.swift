//
//  Student+CoreDataProperties.swift
//  
//
//  Created by Michael Toth on 3/4/19.
//
//

import Foundation
import CoreData


extension Student {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Student> {
        return NSFetchRequest<Student>(entityName: "Student")
    }

    @NSManaged public var balance: Float
    @NSManaged public var birthday: NSDate?
    @NSManaged public var cell: String?
    @NSManaged public var city: String?
    @NSManaged public var email: String?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var lastUpdate: NSDate?
    @NSManaged public var phone: String?
    @NSManaged public var photo: NSData?
    //@NSManaged public var recordID: NSData?
    @NSManaged public var recordName: String?
    @NSManaged public var state: String?
    @NSManaged public var street1: String?
    @NSManaged public var street2: String?
    @NSManaged public var uniqueIdenfier: String?
    @NSManaged public var zip: String?
    @NSManaged public var lessons: NSSet?

}

// MARK: Generated accessors for lessons
extension Student {

    @objc(addLessonsObject:)
    @NSManaged public func addToLessons(_ value: Lesson)

    @objc(removeLessonsObject:)
    @NSManaged public func removeFromLessons(_ value: Lesson)

    @objc(addLessons:)
    @NSManaged public func addToLessons(_ values: NSSet)

    @objc(removeLessons:)
    @NSManaged public func removeFromLessons(_ values: NSSet)

}
