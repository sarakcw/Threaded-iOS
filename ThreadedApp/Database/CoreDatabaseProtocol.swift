//
//  CoreDatabaseProtocol.swift
//  ThreadedApp
//
//  Created by Sara Kok on 21/10/2025.
//

import Foundation

enum CoreDatabaseChange{
    case add
    case remove
    case update
}

enum CoreListenerType{
    case projects
}

protocol CoreDatabaseListener: AnyObject{
    var listenerType: CoreListenerType { get }
    func onAllProjectsChange(change: CoreDatabaseChange, projects: [Project])
}

//Define the behaviours of the database
protocol CoreDatabaseProtocol: AnyObject{
    func cleanup()
    func resetCache()
    
    func addListener(listener: CoreDatabaseListener)
    func removeListener(listener: CoreDatabaseListener)
    
    func addProject(name: String, yarnName: String?, yarnType: String?, yarnWeight: String?, hookSize: Double?, needleSize: Double?, isCompleted: Bool, imageFile: String, projectOwner: String) -> Project
    func deleteProject(project: Project)
    func toggleProjectCompletion(_ project: Project)
}
