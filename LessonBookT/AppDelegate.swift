//
//  AppDelegate.swift
//  LessonBookT
//
//  Created by Michael Toth on 2/2/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var sids:[CKSubscription] = []
    var window: UIWindow?
    private var database = CKContainer.default().privateCloudDatabase
    private var container = CKContainer.default()
    var viewController:MasterViewController? = nil
    var enableAllOrientations = true
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let containerIdentifier = String(CKContainer.default().containerIdentifier!)
        let lessonBookLoc = containerIdentifier.lastIndex(of: "k")!
        let newContainerIdentifier = containerIdentifier[...lessonBookLoc]
        let sID = String(newContainerIdentifier)
        database = CKContainer.init(identifier: sID).privateCloudDatabase

        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self

        let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
        let controller = masterNavigationController.topViewController as! MasterViewController
        controller.managedObjectContext = self.persistentContainer.viewContext
        controller.setDataBase(database)
        viewController = controller
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert], completionHandler: {(granted,err) in
            if granted {
                print("authorization granted")
                DispatchQueue.main.sync {
                    application.registerForRemoteNotifications()
                }
                
            } else {
                print("authorization not granted")
            }
            if let err = err {
                print(err.localizedDescription)
            }
        })
//        application.registerUserNotificationSettings(UIUserNotificationSettings(types: .alert, categories: nil))
//        application.registerForRemoteNotifications()
        

        // Register for push notifications
//        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:nil];
//        [application registerUserNotificationSettings:notificationSettings];
//        [application registerForRemoteNotifications];
        let studentZone = CKRecordZone(zoneName: "LessonBook")
        let zoneID = studentZone.zoneID
        let predicate = NSPredicate(value: true)
//
        let qSubscription = CKQuerySubscription(recordType: "Student", predicate: predicate, subscriptionID: "lessonbook", options: [.firesOnRecordCreation,.firesOnRecordUpdate, .firesOnRecordDeletion])
        qSubscription.notificationInfo?.shouldSendMutableContent = true
        qSubscription.zoneID = zoneID
        //        subscription.recordType = "Student"
        //
        //let notificationInfo = CKSubscription.NotificationInfo()
        let notificationInfo = CKQuerySubscription.NotificationInfo()
        
        notificationInfo.shouldSendMutableContent = true
        notificationInfo.shouldBadge = true
        notificationInfo.shouldSendContentAvailable = true
        qSubscription.notificationInfo = notificationInfo
        
        //let subscription = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: "test")
        //subscription.recordType = "Student"

        //let notificationInfo = CKSubscription.NotificationInfo()
        //notificationInfo.shouldBadge = true
        //notificationInfo.shouldSendMutableContent = true
        //subscription.notificationInfo = notificationInfo
        database.save(qSubscription, completionHandler: {(s,err) in
            if let err = err {
                print(err.localizedDescription)
            }
        })
//        let op = CKModifyRecordZonesOperation(recordZonesToSave: [studentZone], recordZoneIDsToDelete: [])
//        database.add(op)
//        database.save(studentZone, completionHandler: {(rz,err) in
//            if let err = err {
//                print(err.localizedDescription)
//            }
//        })
        
//        database.save(qSubscription,completionHandler: {(sub,error) in
//            if let error = error {
//                print(error.localizedDescription)
//            } else {
//                print("Saved Subscription")
//            }
//        })

//        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
//        operation.modifySubscriptionsCompletionBlock = { savedSubscriptions, deletedSubscriptionIDs, operationError in
//            if operationError != nil {
//                print(operationError ?? "Error")
//                return
//            } else {
//                print("Subscribed")
//            }
//        }
        
        

        return true
    }

    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if enableAllOrientations {
            return UIInterfaceOrientationMask([.portrait,.landscapeRight,.landscapeLeft])
        }
        return UIInterfaceOrientationMask([.portrait])
    }
//    func application(application: UIApplication!, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]!)
//    {
//        // <- this method will invoked
//        print("Got New Student Notification")
//        print(userInfo)
//    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Received Notification")
        //var recordID:CKRecord.ID
        //var recordName:String
        let notification: CKNotification =
            CKNotification(fromRemoteNotificationDictionary:
                userInfo as! [String : NSObject])
        
        
        if notification.notificationType == CKNotification.NotificationType.query {
            print("query notification")
            //let queryNotification = notification as! CKQueryNotification
            //recordID = queryNotification.recordID!
            //recordFields = queryNotification.r
        
            guard let ck = userInfo["ck"] as? [String: AnyObject] else {
                return
            }
            
            guard let qry = ck["qry"] as? [String: AnyObject] else {
                return
            }
            
            
            //let storyboard = NSStoryboard(name: "Main", bundle: nil)
            //            guard let mainWindow = NSApplication.shared.mainWindow else {
            //                return
            //            }
            //            guard let contentViewController = mainWindow.contentViewController else {
            //                return
            //            }
            //            let viewController = contentViewController as! ViewController
            //let viewController = NSApplication.shared.mainWindow?.contentViewController as! ViewController
            
            
            let options = CKQuerySubscription.Options( rawValue: qry["fo"] as! UInt )
            switch options {
            case .firesOnRecordCreation:
                print("FIRE ON RECORD CREATION")
                //viewController?.fetchAndAddRecordToCoreData(recordID)
                completionHandler(UIBackgroundFetchResult.noData)

                //viewController.addedCloudKitRecord(record)
                break
            case .firesOnRecordDeletion:
                print("FIRE ON RECORD DELETE")
                //viewController?.recordRemovedFromCloudKit(recordID)
                completionHandler(UIBackgroundFetchResult.noData)

                break
            case .firesOnRecordUpdate:
                print("FIRE ON UPDATE")
                // NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
                //viewController?.updateRecordInCoreData(recordID)
                completionHandler(UIBackgroundFetchResult.noData)
                break
            case [.firesOnRecordCreation, .firesOnRecordUpdate]:
                print("FIRE ON DELETE")
                //viewController?.recordRemovedFromCloudKit(recordID)
                completionHandler(UIBackgroundFetchResult.noData)

                break
            default:
                print("DEFAULT \(options)")
            }
            
            
        }
        
        if notification.notificationType == CKNotification.NotificationType.database {
            print("Database notification")
            let dbNotification = notification as! CKDatabaseNotification
            //let recordID = dbNotification.
            print(String(describing: dbNotification))
            // let notificationID = dbNotification.notificationID
            let dict = userInfo as! [String: NSObject]
            guard let notification:CKDatabaseNotification = CKNotification(fromRemoteNotificationDictionary:dict) as? CKDatabaseNotification else { return }
            viewController!.changesFromCloud = true
            viewController!.fetchChanges(in: notification.databaseScope) {
            }
            completionHandler(UIBackgroundFetchResult.noData)

        }

        // print(userInfo)
        //completionHandler(nil)
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
       //  let subscription = CKQuerySubscription(recordType: "Student", predicate: NSPredicate(format: "TRUEPREDICATE"), options: .firesOnRecordCreation)
        
//        let info = CKSubscription.NotificationInfo()
//        info.alertBody = "A new student has been added"
//        info.shouldBadge = true
//        info.soundName = "default"
//
//        subscription.notificationInfo = info
//
//
//        database.save(subscription, completionHandler: { subscription, error in
//            if error == nil {
//                print("Saved Subscription")
//            } else {
//                print(error!.localizedDescription)
//            }
//        })
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("registration failed")
        print(error.localizedDescription)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
        
        let op = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
        let c = op.configuration as CKOperation.Configuration
        c.container = container
        op.configuration = c
        op.fetchSubscriptionCompletionBlock = { (subs,err) in
            // print("*** fetched subs: \(subs)")
            
            for s:(key: CKSubscription.ID,value:CKSubscription) in subs! {
                self.sids.append(s.value)
//                DispatchQueue.main.sync {
//                    self.database.delete(withSubscriptionID: s.value.subscriptionID, completionHandler: {(s,err) in
//                        if let err = err {
//                            print(err.localizedDescription)
//                        } else {
//                            print(s!)
//                        }
//                    })
//                }
            }
        }
        op.database = database
        
        let q = OperationQueue()
        q.addOperation(op)
        q.waitUntilAllOperationsAreFinished()
        
        let op1 = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
        let c1 = op1.configuration as CKOperation.Configuration
        c1.container = container
        op1.configuration = c1

        if sids.count > 0 {
            op1.fetchSubscriptionCompletionBlock  = { (subs,err) in
                self.database.delete(withSubscriptionID: self.sids[0].subscriptionID, completionHandler: {(s,err) in
                    if let err = err {
                        print(err.localizedDescription)
                    } else {
                        print(s!)
                    }
                })
            }
            let q1 = OperationQueue()
            q1.addOperation(op1)
            q1.waitUntilAllOperationsAreFinished()
        }
//        database.fetchAllSubscriptions(completionHandler: {(sub,err) in
//            if let err = err {
//                print(err.localizedDescription)
//            }
//            for s:CKSubscription in sub! {
//                self.database.delete(withSubscriptionID: s.subscriptionID, completionHandler: {(s,err) in
//                    if let err = err {
//                        print(err.localizedDescription)
//                    }
//                })
//            }
//        })
        self.saveContext()
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.studentToEdit == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
    // MARK: - Core Data stack

    lazy var viewContext: NSManagedObjectContext = {
        return self.persistentContainer.viewContext
    }()
    
    lazy var cacheContext: NSManagedObjectContext = {
        return self.persistentContainer.newBackgroundContext()
    }()
    
    lazy var updateContext: NSManagedObjectContext = {
        let _updateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        _updateContext.parent = self.viewContext
        return _updateContext
    }()
    
    
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "LessonBookT")
        // container.persistentStoreCoordinator.migratePersistentStore(<#T##store: NSPersistentStore##NSPersistentStore#>, to: <#T##URL#>, options: <#T##[AnyHashable : Any]?#>, withType: <#T##String#>)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
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
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

