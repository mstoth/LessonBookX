//
//  LessonTableViewController.swift
//  LessonBookT
//
//  Created by Michael Toth on 3/11/19.
//  Copyright © 2019 Michael Toth. All rights reserved.
//

import UIKit
import CoreData
import CloudKit


class LessonTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var context:NSManagedObjectContext? = nil
    var student:Student? = nil
    var detailViewController: DetailViewController? = nil
    var z:ZoneOperations? = nil
    @objc dynamic var lessons:NSMutableSet? = nil
    var lessonArray:[Lesson]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        lessons = student?.lessons?.mutableCopy() as? NSMutableSet
        let sortDesc = NSSortDescriptor(key: "date", ascending: true)
        lessonArray = lessons?.sortedArray(using: [sortDesc]) as? [Lesson]
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
//        navigationItem.leftBarButtonItem = editButtonItem
//        if let split = splitViewController {
//            let controllers = split.viewControllers
//            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
//        }

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
//        z = ZoneOperations()
        //managedObjectContext = self.fetchedResultsController.managedObjectContext

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return (lessonArray?.count)!
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "lessonCell", for: indexPath)
        let lesson = lessonArray?[indexPath.row]
        let d = lesson!.date! as Date
        let s = DateFormatter.localizedString(from: d, dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.medium)
        cell.textLabel!.text = s
        return cell
    }

    @objc
    func insertNewObject(_ sender: Any) {
        // let context = self.fetchedResultsController.managedObjectContext
        //let newEvent = Event(context: context)
        let newLesson = Lesson(context: context!)
        newLesson.prepareForCloudKit()
        newLesson.date = NSDate()
        newLesson.comment = "No Comment"
        newLesson.recordName = newLesson.cloudKitRecordID().recordName
        lessonArray?.append(newLesson)
        student?.addToLessons(newLesson)
        // newStudent.lastUpdate = Date()
        do {
            try context?.save()
        } catch {
            print(error)
        }
        tableView.reloadData()
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            student?.removeFromLessons((lessonArray?[indexPath.row])!)
            lessonArray?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! LessonDetailViewController
        let indexPath = tableView.indexPathForSelectedRow
        let row = indexPath?.row
        let lesson = lessonArray?[row!]
        controller.lesson = lesson
        controller.context = context
    }
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
//    @objc
//    func insertNewObject(_ sender: Any) {
//        let context = self.fetchedResultsController.managedObjectContext
//        //let newEvent = Event(context: context)
//        let newLesson = Lesson(context: context)
//        newLesson.prepareForCloudKit()
//        newLesson.date = NSDate()
//        newLesson.comment = "No Comment"
//        // newStudent.lastUpdate = Date()
//        DispatchQueue.main.async {
//            do {
//                try self.managedObjectContext!.save()
//                self.tableView.reloadData()
//            } catch {
//                print(error)
//            }
//        }
//    }
//    // MARK: - Table View
//
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return fetchedResultsController.sections?.count ?? 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let sectionInfo = fetchedResultsController.sections![section]
//        return sectionInfo.numberOfObjects
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
//        let event = fetchedResultsController.object(at: indexPath)
//        configureCell(cell, withEvent: event)
//        return cell
//    }
//
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        // Return false if you do not want the specified item to be editable.
//        return true
//    }
//
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            // let context = fetchedResultsController.managedObjectContext
//
//            if editingStyle == .delete {
//                let context = fetchedResultsController.managedObjectContext
//                context.delete(fetchedResultsController.object(at: indexPath))
//                DispatchQueue.main.async {
//                    do {
//                        try self.managedObjectContext?.save()
//                    } catch {
//                        // Replace this implementation with code to handle the error appropriately.
//                        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                        let nserror = error as NSError
//                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//                    }
//                }
//            }
//        }
//    }
//
//
//    // MARK: - Fetched results controller
//
//    var fetchedResultsController: NSFetchedResultsController<Lesson> {
//        if _fetchedResultsController != nil {
//            return _fetchedResultsController!
//        }
//
//        let fetchRequest: NSFetchRequest<Lesson> = Lesson.fetchRequest()
//
//        // Set the batch size to a suitable number.
//        fetchRequest.fetchBatchSize = 20
//
//        // Edit the sort key as appropriate.
//        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
//
//        fetchRequest.sortDescriptors = [sortDescriptor]
//
//        // Edit the section name key path and cache name if appropriate.
//        // nil for section name key path means "no sections".
//        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
//        aFetchedResultsController.delegate = self
//        _fetchedResultsController = aFetchedResultsController
//
//        do {
//            try _fetchedResultsController!.performFetch()
//        } catch {
//            // Replace this implementation with code to handle the error appropriately.
//            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            let nserror = error as NSError
//            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//        }
//
//        return _fetchedResultsController!
//    }
//    var _fetchedResultsController: NSFetchedResultsController<Lesson>? = nil
//
//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        tableView.beginUpdates()
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
//        switch type {
//        case .insert:
//            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
//        case .delete:
//            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
//        default:
//            return
//        }
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        switch type {
//        case .insert:
//            tableView.insertRows(at: [newIndexPath!], with: .fade)
//        case .delete:
//            tableView.deleteRows(at: [indexPath!], with: .fade)
//        case .update:
//            if tableView.cellForRow(at: indexPath!) ==  nil {
//                return
//            }
//            configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Lesson)
//        case .move:
//            configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Lesson)
//            tableView.moveRow(at: indexPath!, to: newIndexPath!)
//        }
//    }
//
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        tableView.endUpdates()
//    }
//
//
//    func configureCell(_ cell: UITableViewCell, withEvent lesson: Lesson) {
//        cell.textLabel!.text = lesson.date?.description
//    }


}
