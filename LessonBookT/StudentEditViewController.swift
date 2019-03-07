//
//  StudentEditControllerViewController.swift
//  LessonBookT
//
//  Created by Michael Toth on 2/13/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices
import Foundation
import CloudKit
import iOSUtilitiesSource
import SkyFloatingLabelTextField

class EntryTextField:UITextField {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.placeholder = "PlaceHolder"
        self.text = "Text"
    }



}
extension UIImage{
    
    func resizeImageWith(newSize: CGSize) -> UIImage {
        
        let horizontalRatio = newSize.width / size.width
        let verticalRatio = newSize.height / size.height
        
        let ratio = max(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
        draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    
}

class StudentEditViewController: UIViewController, UITextFieldDelegate,UIDocumentPickerDelegate,UINavigationControllerDelegate {

    var student:Student? = nil
    var context:NSManagedObjectContext? = nil
    var asset:CKAsset? = nil
    var smallImage:UIImage? = nil
    var selectingPhoto:Bool = false
    var keyboardHeight:CGFloat = 0
    var recordName:String? = nil
    var activeField:UITextField? = nil
    var objectID:NSManagedObjectID? = nil
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
            
        }
    }
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var firstNameTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var selectPhotoButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollHeight: NSLayoutConstraint!
    
    @IBOutlet weak var lastNameTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var street1TextField: SkyFloatingLabelTextField!
    @IBOutlet weak var street2TextField: SkyFloatingLabelTextField!
    @IBOutlet weak var cityTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var stateTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var zipTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var cellTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.enableAllOrientations = false

        student = context?.object(with: objectID!) as? Student
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
//        if recordName != nil {
//            let predicate = NSPredicate(format: "recordName == %@", recordName!)
//            let fetchRequest = NSFetchRequest<Student>(entityName: "Student")
//            fetchRequest.predicate = predicate
//            do {
//                let results = try context?.fetch(fetchRequest)
//
//                student = results?.first
        
                firstNameTextField.text = student?.firstName
                lastNameTextField.text = student?.lastName
                street1TextField.text = student?.street1
                street2TextField.text = student?.street2
                cityTextField.text = student?.city
                stateTextField.text = student?.state
                zipTextField.text = student?.zip
//
                firstNameTextField.title = NSLocalizedString("first-name", comment: "First Name")
                lastNameTextField.title = NSLocalizedString("last-name", comment: "Last Name")
                street1TextField.title = NSLocalizedString("street1", comment: "Street")
                street2TextField.title = NSLocalizedString("street2", comment: "Apartment")
                cityTextField.title = NSLocalizedString("city", comment: "City")
                stateTextField.title = NSLocalizedString("state", comment: "State")
                zipTextField.title = NSLocalizedString("zip", comment: "Zip Code")
//
//
                firstNameTextField.placeholder = NSLocalizedString("first-name", comment: "First Name")
                lastNameTextField.placeholder = NSLocalizedString("last-name", comment: "Last Name")
                street1TextField.placeholder = NSLocalizedString("street1", comment: "Street")
                street2TextField.placeholder = NSLocalizedString("street2", comment: "Apartment")
                cityTextField.placeholder = NSLocalizedString("city", comment: "City")
                stateTextField.placeholder = NSLocalizedString("state", comment: "State")
                zipTextField.placeholder = NSLocalizedString("zip", comment: "Zip Code")
                
                hideKeyboardWhenTappedAround()
                //iOSKeyboardShared.shared.keyBoardShowHide(view: self.scrollView)
                
                
//            } catch {
//                print(error)
//                return
//            }
        
//        }
        
//        firstNameTextField.text = student?.firstName
//        lastNameTextField.text = student?.lastName
////        phoneTextField.text = student?.phone
//        street1TextField.text = student?.street1
//        street2TextField.text = student?.street2
//        cityTextField.text = student?.city
//        stateTextField.text = student?.state
//        zipTextField.text = student?.zip
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if selectingPhoto {
            selectingPhoto = false
            return
        }
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.enableAllOrientations = true

//        do {
//            let predicate = NSPredicate(format: "recordName == %@", recordName!)
//            let fetchReq = NSFetchRequest<Student>(entityName: "Student")
//            fetchReq.predicate = predicate
//            let results = try context?.fetch(fetchReq)
//            if results!.count > 0 {
//                student = results?.first
        student = context?.object(with: objectID!) as? Student
        student?.firstName = firstNameTextField.text
        student?.lastName = lastNameTextField.text
        //        student?.phone = phoneTextField.text
        student?.street1 = street1TextField.text
        student?.street2 = street2TextField.text
        student?.city = cityTextField.text
        student?.state = stateTextField.text
        student?.zip = zipTextField.text
//            }
//            try context?.save()
//            print("Saved address to core data")
//        } catch {
//            print(error)
//        }
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
//        student?.cell = cellTextField.text
//        student?.email = emailTextField.text
        
//        guard let data = photoView.image?.pngData() else {
//            return
//        }
//        student?.photo = data as NSData
//
        
        DispatchQueue.main.async {
            do {
                try self.context!.save()
                print("Saved edited student to core data.")
            } catch  {
                print(error)
            }
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("Setting active field")
        activeField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        print("clearing active field")
        activeField = nil
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let myURL = url as URL
        print("import result : \(myURL)")
        let image = UIImage(contentsOfFile: myURL.path)
        smallImage = image?.resizeImageWith(newSize: CGSize(width: 200, height: 266))
        photoView.image = smallImage
        
        guard let data = smallImage!.pngData() else {
            return
        }
        let docURL = FileManager.default.temporaryDirectory
        let name = student!.recordName
        let fileName = "\(name).png"
        let fileURL = docURL.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
        } catch {
            print(error)
        }
        // asset = CKAsset(fileURL: fileURL)
        let data2 = NSData(contentsOf: fileURL)
        student?.photo = data2
    }
    
    
//    public func documentMenu(_ documentMenu:UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
//        documentPicker.delegate = self
//        present(documentPicker, animated: true, completion: nil)
//    }
    
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectPhoto(_ sender: Any) {
        selectingPhoto = true
        let documentViewController = UIDocumentPickerViewController(documentTypes: [kUTTypeBMP as String,kUTTypeGIF as String,kUTTypePNG as String,kUTTypeJPEG as String], in: .import)
        documentViewController.delegate = self
        documentViewController.modalPresentationStyle = .formSheet
        self.present(documentViewController, animated: true, completion: nil)
        
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            //let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            scrollHeight.constant = 562
            view.setNeedsLayout()
        }
    }

    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            //UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
            let contentInsets:UIEdgeInsets = UIEdgeInsets(top: 0.0,left: 0.0,bottom: keyboardSize.height, right: 0.0)
            scrollView.contentInset = contentInsets;
            scrollView.scrollIndicatorInsets = contentInsets;
            // If active text field is hidden by keyboard, scroll it so it's visible
            // Your app might not need or want this behavior.
            
            //CGRect aRect = self.view.frame;
            var aRect:CGRect = self.view.frame;
            aRect.size.height -= keyboardSize.height;
//            print("Height is \(keyboardSize.height)")
//            print("Origin is ",activeField?.frame.origin)
//            print("aRect is ",aRect)
//            if (!aRect.contains((activeField?.frame.origin)!)) {
                //[self.scrollView scrollRectToVisible:activeField.frame animated:YES];
                //self.scrollView.scrollRectToVisible((activeField?.frame)!, animated: true)
                self.scrollView.scrollRectToVisible((activeField?.frame)!, animated: true)
                view.setNeedsLayout()
//            }
            //let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)

            //let keyboardEndFrame:CGRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
            //let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
            //let options:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: (curve << 16)  | UIView.AnimationOptions.beginFromCurrentState.rawValue)
            //let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            
//            keyboardHeight = keyboardSize.height
//            scrollHeight.constant = 562 - keyboardHeight
//            view.setNeedsLayout()
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
