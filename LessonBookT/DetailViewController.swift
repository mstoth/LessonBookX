//
//  DetailViewController.swift
//  LessonBookT
//
//  Created by Michael Toth on 2/2/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    var context:NSManagedObjectContext? = nil
    var studentToEdit:Student? = nil
    var recordName:String? = nil
    var masterViewController:MasterViewController? = nil
    var objectID:NSManagedObjectID? = nil
    
    func configureView() {
        // Update the user interface for the detail item.
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }



    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editDetailTabBarController" {
            let controller = segue.destination as!  EditStudentTabBarController
//            controller.recordName = recordName
            controller.context = context
            print("Set context of EditStudentTabBarController")
            print(context as Any)
//            controller.masterViewController = masterViewController
            controller.objectID = objectID
            print("Set objectID of EditStudentTabBarController")
            print(objectID as Any)
            //controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            //controller.navigationItem.leftItemsSupplementBackButton = true
        }
        if segue.identifier == "lessonEdit" {
            let controller = segue.destination as! LessonTableViewController
            controller.context = context
            controller.student = studentToEdit
        }
    }
}


