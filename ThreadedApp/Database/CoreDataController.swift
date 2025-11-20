//
//  CoreDataController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 21/10/2025.
//

import UIKit
import CoreData

class CoreDataController: NSObject, CoreDatabaseProtocol, NSFetchedResultsControllerDelegate  {
    
    var listeners = MulticastDelegate<CoreDatabaseListener>()
//    var eventsListener: ListenerRegistration?

    var persistentContainer: NSPersistentContainer
    
    // Monitor changes
    var allProjectsFetchedResultsController: NSFetchedResultsController<Project>?
    
    override init(){
        
        persistentContainer = NSPersistentContainer(name: "ProjectModel")
        persistentContainer.loadPersistentStores() { (description, error ) in
            if let error = error {
                fatalError("Failed to load Core Data Stack with error: \(error)")
            }
        }
        super.init()
        
    }
    
    func cleanup() {
        // Check if there are any changes to be saved inside the view context
        if persistentContainer.viewContext.hasChanges {
            do {
                // Save inside the view context
                try persistentContainer.viewContext.save()
            } catch {
                fatalError("Failed to save changes to Core Data with error: \(error)")
            }
        }
    }
    
    func resetCache(){
        // Clean listeners list
        listeners = MulticastDelegate<CoreDatabaseListener>()
        
        allProjectsFetchedResultsController?.delegate = nil
        allProjectsFetchedResultsController = nil

        
    }
    
    // MARK: - Add, Delete, Retrieve Project Methods

    // Take in all the details of the project and generate a new Project object then return it.
    func addProject(name: String, yarnName: String? = nil, yarnType: String? = nil , yarnWeight: String? = nil, hookSize: Double? = 0.00, needleSize: Double? = 0.00, isCompleted: Bool, imageFile: String, projectOwner: String) -> Project{
        
        
        let project = Project(context: persistentContainer.viewContext)
        project.name = name
        project.yarnName = yarnName ?? "Not Specified"
        project.yarnType = yarnType ?? "Not Specified"
        project.yarnWeight = yarnWeight ?? "Not Specified"
        project.hookSize = hookSize ?? 0.00
        project.needleSize = needleSize ?? 0.00
        project.isCompleted = isCompleted
        project.imageFile = imageFile
        project.projectOwner = projectOwner
        
        print("saving project owner: \(projectOwner)")
        
        return project
    }
    
    // Delete the given project
    func deleteProject(project: Project){
        
        // Remove from managed object context
        persistentContainer.viewContext.delete(project)
    }
    
    // Retrieve all Projects stored within the persistent memory
    func fetchAllProjects() -> [Project] {
        
        // Check if Fetch Results Controller is instantiated
        if allProjectsFetchedResultsController == nil{
            
            // Create a fetch request for all Projects
            let request: NSFetchRequest<Project> = Project.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [nameSortDescriptor]
            
            // Initialise Fetched Results Controller
            allProjectsFetchedResultsController =
            NSFetchedResultsController<Project>(fetchRequest: request,
            managedObjectContext: persistentContainer.viewContext,
            sectionNameKeyPath: nil, cacheName: nil)
            
            // Set this class to be the results delegate
            allProjectsFetchedResultsController?.delegate = self
            
            // Perform fetch request
            do {
                try allProjectsFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
            
        }
        
        // Check if it contains the fetched objects
        if let projects = allProjectsFetchedResultsController?.fetchedObjects{
            return projects
        }
        
        return [Project]()
    }
    
    // MARK: - Fetched Results Controller Protocol methods
    func controllerDidChangeContent(_ controller:
    NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == allProjectsFetchedResultsController {
            
            // call the MulticastDelegate’s invoke method
            listeners.invoke() { listener in
                if listener.listenerType == .projects { // Check if listening for changes for projects
                    // Pass updated list of projects
                    listener.onAllProjectsChange(change: .update, projects: fetchAllProjects())
                }
            }
        }
    }
    
    // MARK: - Add and Remove Listener Methods
    /*
     Adds the given listener to the list of listeners
     and provide the information depending on the listener type.
     */
    func addListener(listener: CoreDatabaseListener){
        
        // Add database to list of listeners
        listeners.addDelegate(listener)
        
        // If listener type is projects, fetch all projects
        if listener.listenerType == .projects{
            listener.onAllProjectsChange(change: .update, projects: fetchAllProjects())
        }
    }
    
    /* Remove the given listener from the list of listeners */
    func removeListener(listener: CoreDatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    // Mark project as complete or WIP
    func toggleProjectCompletion(_ project: Project) {
        project.isCompleted.toggle()
        
        // Save the context
        do {
            try persistentContainer.viewContext.save()
        } catch {
            print("Failed to toggle project completion status: \(error)")
        }
    }


}
