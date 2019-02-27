//
//  EditStudentProfileController.swift
//  LessonBookX
//
//  Created by Michael Toth on 2/22/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import Cocoa
import CoreData
import CloudKit
import UserNotifications



class EditStudentProfileController: NSViewController {

    @objc dynamic var studentToEdit:Student? = nil
    var context:NSManagedObjectContext? = nil
    @IBOutlet weak var studentPhotoView: NSImageView!
    var asset:CKAsset? = nil
    @IBOutlet weak var firstNameTextField: NSTextField!
    @IBOutlet weak var lastNameTextField: NSTextField!
    @IBOutlet weak var street1TextField: NSTextField!
    @IBOutlet weak var cellTextField: NSTextField!
    @IBOutlet weak var street2TextField: NSTextField!
    @IBOutlet weak var emailTextField: NSTextField!
    @IBOutlet weak var cityTextField: NSTextField!
    @IBOutlet weak var phoneTextField: NSTextField!
    @IBOutlet weak var stateTextField: NSTextField!
    @IBOutlet weak var zipTextField: NSTextField!
    
    @IBOutlet weak var selectPhotoButton: NSButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let imageData = studentToEdit?.photo
        
        if (imageData != nil) {
            let tmpDir = FileManager.init().temporaryDirectory
            let photoUrl = tmpDir.appendingPathComponent("\(studentToEdit?.recordName).jpg")
            do {
                try imageData?.write(to: photoUrl, options: .atomic)
                let image = NSImage(contentsOf: photoUrl)
                studentPhotoView.image = image
            } catch  {
                print(error)
            }
        }
        
        firstNameTextField.placeholderString = NSLocalizedString("first-name", comment: "First Name")
        lastNameTextField.placeholderString = NSLocalizedString("last-name", comment: "Last Name")
        street1TextField.placeholderString = NSLocalizedString("street1", comment: "Street")
        street2TextField.placeholderString = NSLocalizedString("street2", comment: "Apartment")
        cityTextField.placeholderString = NSLocalizedString("city", comment: "City")
        stateTextField.placeholderString = NSLocalizedString("state", comment: "State")
        zipTextField.placeholderString = NSLocalizedString("zip", comment: "Zip Code")
        phoneTextField.placeholderString = NSLocalizedString("phone", comment: "Phone")
        cellTextField.placeholderString = NSLocalizedString("cell", comment: "Cell Phone")
        emailTextField.placeholderString = NSLocalizedString("email", comment: "Email")
        selectPhotoButton.title = NSLocalizedString("select-photo", comment: "Select Photo")
    }
    
    @IBAction func selectPhoto(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a .jpg file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["jpg","png","tif","bmp"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let image = NSImage(byReferencing: result!)
                print("image width and height are ",image.width,image.height)
                let smallImage = image.resizeMaintainingAspectRatio(withSize: NSSize(width: 200, height: 266))
                print("small image width and height are ",smallImage?.width as Any, smallImage?.height as Any)
                let fm = FileManager.init()
                let tmp = fm.temporaryDirectory
                
                studentPhotoView.image = smallImage
                let url = tmp.appendingPathComponent("\(studentToEdit?.recordName).jpg")
                do {
                    try smallImage?.savePngTo(url: url)
                } catch  {
                    print(error)
                }
                asset = CKAsset(fileURL: url)
                let data = NSData(contentsOf: url)
                studentToEdit?.photo = data
                do {
                    try context?.save()
                } catch  {
                    print(error)
                }
            }
        } else {
            // User clicked on "Cancel"
            return
        }

    }
    
    
    
}
