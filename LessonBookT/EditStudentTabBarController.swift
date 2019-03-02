//
//  EditStudentTabBarController.swift
//  LessonBookT
//
//  Created by Michael Toth on 3/2/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//
import CoreData
import UIKit

class EditStudentTabBarController: UITabBarController {

    var studentToEdit:Student? = nil
    var context:NSManagedObjectContext? = nil
    var recordName:String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let controllers = self.viewControllers
        for controller in controllers! {
        
            if controller.restorationIdentifier == "address" {
                print(studentToEdit)
                (controller as! StudentEditViewController).student = studentToEdit
                (controller as! StudentEditViewController).context = context
                (controller as! StudentEditViewController).recordName = recordName
            }
        }
        // Do any additional setup after loading the view.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let id = segue.identifier
        print(id)
        if segue.identifier == "editDetail" {
            let destination = segue.destination as! StudentEditViewController
            destination.student = studentToEdit
            destination.context = context
        }

        
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
