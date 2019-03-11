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
    @objc dynamic var lessons:NSMutableSet? = nil
    @objc dynamic var lessonArray:[Lesson]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lessons = student?.lessons?.mutableCopy() as? NSMutableSet
        if lessons == nil {
            lessonLabel.stringValue = "No Lessons, Add a lesson"
            lessonArray = []
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
        lessons = student?.lessons as? NSMutableSet
        context?.delete(selectedLesson)
        lessonArray = lessons?.sortedArray(using: [NSSortDescriptor(key: "date", ascending: true)]) as? [Lesson]
        tableView.reloadData()
    }

    @IBAction func addLesson(_ sender: Any) {
        let delegate = NSApplication.shared.delegate as! AppDelegate
        context = delegate.persistentContainer.viewContext
        let lessonEntity = NSEntityDescription.entity(forEntityName: "Lesson", in: context!)
        
        let newLesson = NSManagedObject(entity: lessonEntity!, insertInto: context) as! Lesson
        
        newLesson.setValue(NSDate(), forKey: "date")
        newLesson.setValue("No Comment", forKey: "comment")
        
        print("adding lesson to student.")
        student?.addToLessons(newLesson)
        lessonArray?.append(newLesson)
        lessonArray = lessons?.sortedArray(using: [NSSortDescriptor(key: "date", ascending: true)]) as? [Lesson]
        print("lessonArray is now ",lessonArray as Any)
//        do {
//            try context?.save()
//        } catch {
//            print(error)
//        }
        tableView.reloadData()
    }


}
