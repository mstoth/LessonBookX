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
            controller.studentToEdit = studentToEdit
            controller.recordName = recordName
            controller.context = context
            //controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            //controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }
}


