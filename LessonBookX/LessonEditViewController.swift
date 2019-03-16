//
//  LessonEditViewController.swift
//  LessonBookX
//
//  Created by Michael Toth on 3/11/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import Cocoa


class LessonEditViewController: NSViewController, NSDatePickerCellDelegate {

    public var context:NSManagedObjectContext? = nil
    @objc dynamic var lesson:Lesson? = nil
    @IBOutlet weak var datePicker: NSDatePicker!
    @objc dynamic var currentDate:NSDate? = nil
    @objc dynamic var currentComment:String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentDate = lesson?.date
        datePicker.dateValue = currentDate! as Date
        currentComment = lesson?.comment
        
        // Do view setup here.
    }
    
    override func viewWillDisappear() {
        lesson?.comment = currentComment
        lesson?.date = currentDate
        do {
            try context?.save()
        } catch {
            print(error)
        }
        // let z = ZoneOperations()
        // z.saveLessonToCloud(lesson!)
    }
    
    func datePickerCell(_ datePickerCell: NSDatePickerCell, validateProposedDateValue proposedDateValue: AutoreleasingUnsafeMutablePointer<NSDate>, timeInterval proposedTimeInterval: UnsafeMutablePointer<TimeInterval>?) {

        currentDate = proposedDateValue.pointee
    }
    
    @IBAction func dateChanged(_ sender: Any) {
        lesson?.date = datePicker.dateValue as NSDate
    }
}
