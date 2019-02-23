//
//  EditStudentProfileController.swift
//  LessonBookX
//
//  Created by Michael Toth on 2/22/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import Cocoa
import CoreData
import CloudKit
import UserNotifications

class EditStudentProfileController: NSViewController {

    @objc dynamic var studentToEdit:Student? = nil
    var context:NSManagedObjectContext? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
    }
    
}
