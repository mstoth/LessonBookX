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
            let predicate = NSPredicate(format: "recordName == %@", recordName!)
            let fetchReq = NSFetchRequest<Student>(entityName: "Student")
            do {
                studentToEdit = try context?.fetch(fetchReq).first
            } catch {
                print(error)
            }
            controller.studentToEdit = studentToEdit
            controller.recordName = recordName
            controller.context = context
            controller.masterViewController = masterViewController
            controller.objectID = objectID
            //controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            //controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }
}


