//
//  DetailViewController.swift
//  LessonBook
//
//  Created by Michael Toth on 1/27/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import UIKit
import CloudKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!


    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.text = detail.timestamp!.description
            }
        }
    }
    
    func configureStudentView() {
        if let student = studentItem {
            if let label = detailDescriptionLabel {
                label.text = student.value(forKey: "firstName") as? String
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureStudentView()
    }

    var detailItem: Event? {
        didSet {
            // Update the view.
            configureView()
        }
    }

    var studentItem: CKRecord? {
        didSet {
            configureStudentView()
        }
    }

}

