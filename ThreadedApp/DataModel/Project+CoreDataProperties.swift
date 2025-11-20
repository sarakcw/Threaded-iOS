//
//  Project+CoreDataProperties.swift
//  ThreadedApp
//
//  Created by Sara Kok on 8/11/2025.
//
//

import Foundation
import CoreData


extension Project {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Project> {
        return NSFetchRequest<Project>(entityName: "Project")
    }

    @NSManaged public var hookSize: Double
    @NSManaged public var imageFile: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var name: String?
    @NSManaged public var needleSize: Double
    @NSManaged public var yarnName: String?
    @NSManaged public var yarnType: String?
    @NSManaged public var yarnWeight: String?
    @NSManaged public var projectOwner: String?

}

extension Project : Identifiable {

}
