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
    
    func configureView() {
        // Update the user interface for the detail item.
        if let student = detailItem {
            if let label = detailDescriptionLabel {
                label.text = student.fullName()
                self.title = student.fullName()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
    }

    var detailItem: Student? {
        didSet {
            // Update the view.
            configureView()
        }
    }
    
    var studentItem:  Student? {
        didSet {
            configureView()
        }
    }

    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editDetail" {
            let controller = segue.destination as!  StudentEditViewController
            controller.student = studentToEdit
            controller.context = context
            //controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            //controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }
}


