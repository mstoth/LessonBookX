//
//  StudentPhotoViewController.swift
//  LessonBookT
//
//  Created by Michael Toth on 3/4/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class StudentPhotoViewController: UIViewController,UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    var recordName:String? = nil
    var context:NSManagedObjectContext? = nil
    var student:Student? = nil
    @IBOutlet weak var studentPhoto: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if recordName != nil {
            let predicate = NSPredicate(format: "recordName == %@", recordName!)
            let fetchReq = NSFetchRequest<Student>(entityName: "Student")
            fetchReq.predicate = predicate
            do {
                let results = try context?.fetch(fetchReq)
                student = results?.first
                if student?.photo != nil {
                    let fileURL = FileManager.default.temporaryDirectory
                    let filePath = fileURL.appendingPathComponent(recordName! + ".png")
                    do {
                        try student?.photo?.write(to: URL(fileURLWithPath: filePath.path), options: .atomic)
                        studentPhoto.image = UIImage(contentsOfFile: filePath.path)
                    } catch {
                        print(error)
                    }
                    
                }
            } catch {
                print(error)
                return
            }
        }
        // Do any additional setup after loading the view.
    }

    
    @IBAction func selectPhoto(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let smallImage = pickedImage.resizeImageWith(newSize: CGSize(width: 200, height: 266))
            studentPhoto.image = smallImage
            guard let data = smallImage.pngData() else {
                return
            }
            let docURL = FileManager.default.temporaryDirectory
            let name = student!.recordName
            let fileName = "\(String(describing: name)).png"
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
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let myURL = url as URL
        print("import result : \(myURL)")
        let image = UIImage(contentsOfFile: myURL.path)
        let smallImage = image?.resizeImageWith(newSize: CGSize(width: 200, height: 266))
        studentPhoto.image = smallImage
        
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
