//
//  LessonViewController.swift
//  LessonBookX
//
//  Created by Michael Toth on 3/4/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import Cocoa
import CloudKit
import CoreData
import NotificationCenter


class LessonViewController: NSViewController {

    @IBOutlet weak var lessonLabel: NSTextField!
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet weak var tableView: NSTableView!
    var student:Student? = nil
    var context:NSManagedObjectContext? = nil
    var recordName:String? = nil
    @objc dynamic var lessons:NSSet? = nil
    @objc dynamic var lessonArray:[Lesson]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lessons = student?.lessons
        if lessons == nil {
            lessonLabel.stringValue = "No Lessons, Add a lesson"
        } else {
            lessonLabel.stringValue = "\(lessons!.count) Lessons"
            lessonArray = lessons?.sortedArray(using: [NSSortDescriptor(key: "date", ascending: true)]) as? [Lesson]
        }
    }
    
    @IBAction func removeLesson(_ sender: Any) {
        let selectedLessons = arrayController.selectedObjects
        let selectedLesson = selectedLessons?.first as! Lesson
        let lessonSet = student?.lessons?.mutableCopy() as! NSMutableSet
        lessonSet.remove(selectedLesson)
        student?.lessons = lessonSet.copy() as? NSSet
        context?.delete(selectedLesson)
        lessonArray = lessons?.sortedArray(using: [NSSortDescriptor(key: "date", ascending: true)]) as? [Lesson]
        
    }

    @IBAction func addLesson(_ sender: Any) {
        let newLesson = Lesson(context: context!)
        newLesson.date = NSDate()
        newLesson.comment = "No Comment"
        student?.addToLessons(newLesson)
        lessonArray = lessons?.sortedArray(using: [NSSortDescriptor(key: "date", ascending: true)]) as? [Lesson]
    }
}
