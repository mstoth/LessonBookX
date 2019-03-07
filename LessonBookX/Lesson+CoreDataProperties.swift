//
//  Lesson+CoreDataProperties.swift
//  
//
//  Created by Michael Toth on 3/4/19.
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
    @NSManaged public var paid: Bool
    @NSManaged public var place: String?
    @NSManaged public var comment: String?
    @NSManaged public var duration: Float
    @NSManaged public var student: Student?

}
