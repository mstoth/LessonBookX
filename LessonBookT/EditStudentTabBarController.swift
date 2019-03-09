//
//  EditStudentTabBarController.swift
//  LessonBookT
//
//  Created by Michael Toth on 3/2/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//
import CoreData
import UIKit
import CloudKit

class EditStudentTabBarController: UITabBarController {

    var studentToEdit:Student? = nil
    var context:NSManagedObjectContext? = nil
    var recordName:String? = nil
    var masterViewController:MasterViewController? = nil
    var objectID:NSManagedObjectID? = nil
    var photoController:StudentPhotoViewController? = nil
    var addressController:StudentEditViewController? = nil
    var phoneController:StudentPhoneViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //tabBar.items?.first?.image = UIImage(imageLiteralResourceName: "phoneIconSmall")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .save, target: self, action: #selector(saveChanges))
        studentToEdit = context?.object(with: objectID!) as? Student
        tabBar.items?.first?.image = UIImage(named: "photoIconSmall")
        tabBar.items?[1].image = UIImage(named: "phoneIconSmall")
        tabBar.items?[2].image = UIImage(named: "homeIconSmall")

        let controllers = self.viewControllers

        for controller in controllers! {
            if controller.restorationIdentifier == "studentPhone" {
                phoneController = controller as? StudentPhoneViewController
                //phoneController?.student = studentToEdit
                phoneController?.context = context
                //phoneController?.recordName = recordName
                phoneController?.objectID = objectID
                phoneController?.changesWereMade = false
            }
            if controller.restorationIdentifier == "studentPhoto" {
                photoController = controller as? StudentPhotoViewController
                photoController?.student = studentToEdit
                photoController?.context = context
                photoController?.objectID = objectID
                photoController?.recordName = recordName
                
            }
            if controller.restorationIdentifier == "address" {
                addressController = controller as? StudentEditViewController
                //addressController?.student = studentToEdit
                addressController?.context = context
                //addressController?.recordName = recordName
                addressController?.objectID = objectID
                addressController?.changesWereMade = false
            }
        }
    }
    
    @objc func saveChanges() {
        print("in saveChanges")
        print("Telling addressController to save.")
        addressController?.saveChanges()
        print("Telling phoneController to save.")
        phoneController?.saveChanges()
    }

    
    // MARK: - Navigation
    override func viewWillDisappear(_ animated: Bool) {
        //addressController?.saveChanges()
        //phoneController?.saveChanges()

    }
    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let id = segue.identifier
//        print(id)
//        if segue.identifier == "editDetail" {
//            let destination = segue.destination as! StudentEditViewController
//            destination.student = studentToEdit
//            destination.context = context
//        }
//
//        
//        // Get the new view controller using segue.destination.
//        // Pass the selected object to the new view controller.
//    }

}
