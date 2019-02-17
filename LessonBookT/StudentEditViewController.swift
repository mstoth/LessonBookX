//
//  StudentEditControllerViewController.swift
//  LessonBookT
//
//  Created by Michael Toth on 2/13/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import UIKit
import CoreData

class StudentEditViewController: UIViewController {

    var student:Student? = nil
    var context:NSManagedObjectContext? = nil
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        firstNameTextField.text = student?.firstName
        lastNameTextField.text = student?.lastName
        phoneTextField.text = student?.phone
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func save(_ sender: Any) {
        student?.firstName = firstNameTextField.text
        student?.lastName = lastNameTextField.text
        student?.phone = phoneTextField.text
        DispatchQueue.main.async {
            do {
                try self.context?.save()
                print("context saved in student edit view controller")
            } catch {
                print(error)
            }
        }
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
