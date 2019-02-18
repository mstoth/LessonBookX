//
//  AppDelegate.swift
//  LessonBookX
//
//  Created by Michael Toth on 1/27/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import Cocoa
import CloudKit
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    var viewController:ViewController? = nil
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert], completionHandler: {(granted,err) in
            if granted {
                print("authorization granted")
            } else {
                print("authorization not granted")
            }
            if let err = err {
                print(err.localizedDescription)
            }
        })
        
        guard let mainWindow = NSApplication.shared.mainWindow else {
            return
        }
        guard let contentViewController = mainWindow.contentViewController else {
            return
        }
        viewController = contentViewController as? ViewController
    }
    
    
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.registerForRemoteNotifications()
        
    }
    
    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
        var recordID:CKRecord.ID
        let notification: CKNotification =
            CKNotification(fromRemoteNotificationDictionary:
                userInfo as! [String : NSObject])

        
        if notification.notificationType == CKNotification.NotificationType.query {
            print("query notification")
            let queryNotification = notification as! CKQueryNotification
            recordID = queryNotification.recordID!
            
            guard let ck = userInfo["ck"] as? [String: AnyObject] else {
                return
            }
            
            guard let qry = ck["qry"] as? [String: AnyObject] else {
                return
            }

            let options = CKQuerySubscription.Options( rawValue: qry["fo"] as! UInt )
            switch options {
            case .firesOnRecordCreation:
                print("FIRE ON RECORD CREATION")
                viewController?.fetchAndAddRecordToCoreData(recordID)
                break
            case .firesOnRecordDeletion:
                print("FIRE ON RECORD DELETE")
                viewController?.recordRemovedFromCloudKit(recordID)
                break
            case .firesOnRecordUpdate:
                print("FIRE ON UPDATE")
                //NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
                viewController!.updateRecordInCoreData(recordID)
                break
            case [.firesOnRecordCreation, .firesOnRecordUpdate]:
                print("FIRE ON DELETE")
                viewController?.recordRemovedFromCloudKit(recordID)
                break
            default:
                print("DEFAULT \(options)")
            }

            
        }
        
        if notification.notificationType == CKNotification.NotificationType.database {
            print("Database notification")
        }
    }
    
    
    
    var rootViewController: ViewController? {
        return NSApplication.shared.mainWindow?.contentViewController as? ViewController
    }
//
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//
//        //let viewController: ViewController =
//        guard let viewController = NSApp.mainWindow?.contentViewController as NSViewController else {
//            return
//        }
//            //self.window?.rootViewController as! ViewController
//
//        let notification: CKNotification =
//            CKNotification(fromRemoteNotificationDictionary:
//                userInfo as! [String : NSObject])
//
//        if (notification.notificationType ==
//            CKNotificationType.query) {
//
//            let queryNotification =
//                notification as! CKQueryNotification
//
//            let recordID = queryNotification.recordID
//
//            viewController.fetchRecord(recordID!)
//        }
//    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "LessonBookX")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving and Undo support
    
    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            DispatchQueue.main.async {
                do {
                    try context.save()
                } catch {
                    // Customize this code block to include application-specific recovery steps.
                    let nserror = error as NSError
                    NSApplication.shared.presentError(nserror)
                }

            }
        }
    }
    
    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            
            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}


