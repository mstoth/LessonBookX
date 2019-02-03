//
//  DetailViewController.swift
//  LessonBookT
//
//  Created by Michael Toth on 2/2/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!


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


}

