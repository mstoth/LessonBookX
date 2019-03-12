//
//  Lesson+CoreDataProperties.swift
//  LessonBookT
//
//  Created by Michael Toth on 3/11/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//
//

import Foundation
import CoreData


extension Lesson {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Lesson> {
        return NSFetchRequest<Lesson>(entityName: "Lesson")
    }

    @NSManaged public var date: NSDate?
    @NSManaged public var fee: Float
    @NSManaged public var duration: Float
    @NSManaged public var paid: Bool
    @NSManaged public var comment: String?
    @NSManaged public var place: String?
    @NSManaged public var student: Student?

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
