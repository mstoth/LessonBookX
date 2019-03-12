//
//  LessonDetailViewController.swift
//  LessonBookT
//
//  Created by Michael Toth on 3/12/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import UIKit
import CoreData


class LessonDetailViewController: UIViewController {

    var lesson:Lesson? = nil
    var context:NSManagedObjectContext? = nil
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var commentTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let d = lesson?.date as Date?
        datePicker.setDate(d!, animated: true)
        commentTextView.text = lesson?.comment
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        lesson?.comment = commentTextView.text

        do {
            try context?.save()
        } catch {
            print(error)
        }
    }

    @IBAction func dateChanged(_ sender: Any) {
        //let df = DateFormatter.localizedString(from: datePicker.date, dateStyle: .medium, timeStyle: .medium)
        lesson?.date = datePicker.date as NSDate
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
