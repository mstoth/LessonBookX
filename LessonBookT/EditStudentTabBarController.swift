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

        //tabBar.items?.first?.image = UIImage(imageLiteralResourceName: "phoneIconSmall")
        
        tabBar.items?.first?.image = UIImage(named: "photoIconSmall")
        tabBar.items?[1].image = UIImage(named: "phoneIconSmall")
        tabBar.items?[2].image = UIImage(named: "homeIconSmall")
        let controllers = self.viewControllers
        for controller in controllers! {
            if controller.restorationIdentifier == "studentPhone" {
                (controller as! StudentPhoneViewController).student = studentToEdit
                (controller as! StudentPhoneViewController).context = context
                (controller as! StudentPhoneViewController).recordName = recordName
            }
            if controller.restorationIdentifier == "studentPhoto" {
                (controller as! StudentPhotoViewController).student = studentToEdit
                (controller as! StudentPhotoViewController).context = context
                (controller as! StudentPhotoViewController).recordName = recordName
            }
            if controller.restorationIdentifier == "address" {
                (controller as! StudentEditViewController).student = studentToEdit
                (controller as! StudentEditViewController).context = context
                (controller as! StudentEditViewController).recordName = recordName
            }
        }
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
