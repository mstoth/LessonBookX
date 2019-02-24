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
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstNameTextField.text = student?.firstName
        lastNameTextField.text = student?.lastName
        phoneTextField.text = student?.phone
        let imageData = student?.photo
        if (imageData != nil) {
            let tmpDir = FileManager.init().temporaryDirectory
            let photoUrl = tmpDir.appendingPathComponent("studentPhoto.png")
            do {
                try imageData?.write(to: photoUrl, options: .atomic)
                photoView.image = UIImage(contentsOfFile: photoUrl.path)
            } catch  {
                print(error)
            }
        }

        firstNameTextField.delegate = self
        // Do any additional setup after loading the view.
    }
    override func viewWillDisappear(_ animated: Bool) {
        student?.firstName = firstNameTextField.text
        student?.lastName = lastNameTextField.text
        student?.phone = phoneTextField.text
        
        do {
            try context!.save()
        } catch  {
            print(error)
        }
    }


    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let myURL = url as URL
        print("import result : \(myURL)")
        let image = UIImage(contentsOfFile: myURL.path)
        let smallImage = image?.resizeImageWith(newSize: CGSize(width: 200, height: 266))
        photoView.image = smallImage
        
        guard let data = smallImage!.pngData() else {
            return
        }
        let docURL = FileManager.default.temporaryDirectory
        let fileURL = docURL.appendingPathComponent("studentPhoto.png")
        do {
            try data.write(to: fileURL)
        } catch {
            print(error)
        }
        asset = CKAsset(fileURL: fileURL)
        let data2 = NSData(contentsOf: fileURL)
        student?.photo = data2
        do {
            try context?.save()
        } catch  {
            print(error)
        }

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
        let documentViewController = UIDocumentPickerViewController(documentTypes: [kUTTypeBMP as String,kUTTypeGIF as String,kUTTypePNG as String,kUTTypeJPEG as String], in: .import)
        documentViewController.delegate = self
        documentViewController.modalPresentationStyle = .formSheet
        self.present(documentViewController, animated: true, completion: nil)
        
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
