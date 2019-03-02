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
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var selectPhotoButton: UIButton!

    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var street1TextField: UITextField!
    @IBOutlet weak var street2TextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var zipTextField: UITextField!
    @IBOutlet weak var cellTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        firstNameTextField.text = student?.firstName
//        lastNameTextField.text = student?.lastName
//        phoneTextField.text = student?.phone
//        street1TextField.text = student?.street1
//        street2TextField.text = student?.street2
//        cityTextField.text = student?.city
//        stateTextField.text = student?.state
//        zipTextField.text = student?.zip
//        cellTextField.text = student?.cell
//        emailTextField.text = student?.email

//        let imageData = student?.photo
//        if (imageData != nil) {
//            let tmpDir = FileManager.init().temporaryDirectory
//            let name = student!.recordName
//            let fileName = "\(name).png"
//            let photoUrl = tmpDir.appendingPathComponent(fileName)
//            do {
//                try imageData?.write(to: photoUrl, options: .atomic)
//                photoView.image = UIImage(contentsOfFile: photoUrl.path)
//            } catch  {
//                print(error)
//            }
//        }
//
        firstNameTextField.placeholder =  NSLocalizedString("first-name", comment: "First Name")
//        lastNameTextField.placeholder = NSLocalizedString("last-name", comment: "Last Name")
//        street1TextField.placeholder = NSLocalizedString("street1", comment: "Street")
//        street2TextField.placeholder = NSLocalizedString("street2", comment: "Apartment")
//        cityTextField.placeholder = NSLocalizedString("city", comment: "City")
//        stateTextField.placeholder = NSLocalizedString("state", comment: "State")
//        zipTextField.placeholder = NSLocalizedString("zip", comment: "Zip Code")
//        phoneTextField.placeholder = NSLocalizedString("phone", comment: "Phone")
//        cellTextField.placeholder = NSLocalizedString("cell", comment: "Cell Phone")
//        emailTextField.placeholder = NSLocalizedString("email", comment: "Email")
        
        
        selectPhotoButton.setTitle(NSLocalizedString("select-photo", comment: "Select Photo"), for: .normal)
//
//        firstNameTextField.delegate = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if selectingPhoto {
            selectingPhoto = false
            return
        }
        student?.firstName = firstNameTextField.text
//        student?.lastName = lastNameTextField.text
//        student?.phone = phoneTextField.text
//        student?.street1 = street1TextField.text
//        student?.street2 = street2TextField.text
//        student?.city = cityTextField.text
//        student?.state = stateTextField.text
//        student?.zip = zipTextField.text
//        student?.cell = cellTextField.text
//        student?.email = emailTextField.text
        
        guard let data = photoView.image?.pngData() else {
            return
        }
        student?.photo = data as NSData
//
//        do {
//            try context!.save()
//            print("Saved edited student to core data.")
//        } catch  {
//            print(error)
//        }
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
    
    

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            //let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            
            var frame = self.view.frame
            frame.origin.y = frame.origin.y - keyboardSize.height + 167
            self.view.frame = frame
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
