//
//  StudentPhoneViewController.swift
//  LessonBookT
//
//  Created by Michael Toth on 3/4/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import UIKit
import CoreData
import SkyFloatingLabelTextField


class StudentPhoneViewController: UIViewController, UITextFieldDelegate {

    var student:Student? = nil
    var context:NSManagedObjectContext? = nil
    var recordName:String? = nil
    var changesWereMade:Bool = false
    var objectID:NSManagedObjectID? = nil
    
    @IBOutlet weak var cellTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var phoneTextField: SkyFloatingLabelTextField!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        student = context?.object(with: objectID!) as? Student
        
//        if recordName != nil {
//            let predicate = NSPredicate(format: "recordName == %@", recordName!)
//            let fetchReq = NSFetchRequest<Student>(entityName: "Student")
//            fetchReq.predicate = predicate
//            do {
//                let results = try context?.fetch(fetchReq)
//                student = results?.first
                phoneTextField.title = NSLocalizedString("phone", comment: "Phone")
                cellTextField.title = NSLocalizedString("cell", comment: "Cell Phone")
                emailTextField.title = NSLocalizedString("email", comment: "Email")
                
                phoneTextField.placeholder = NSLocalizedString("phone", comment: "Phone")
                cellTextField.placeholder = NSLocalizedString("cell", comment: "Cell Phone")
                emailTextField.placeholder = NSLocalizedString("email", comment: "Email")

                phoneTextField.text = student?.phone
                cellTextField.text = student?.cell
                emailTextField.text = student?.email
//            } catch {
//                print(error)
//            }
//        }
        // Do any additional setup after loading the view.
        hideKeyboardWhenTappedAround()

    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        changesWereMade = true
    }

    @objc func saveChanges() {

        //if changesWereMade {
            student?.phone = phoneTextField.text
            student?.cell = cellTextField.text
            student?.email = emailTextField.text
            do {
                try context?.save()
            } catch {
                print(error)
            }
        //}
    }

    override func viewWillDisappear(_ animated: Bool) {
        saveChanges()
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
