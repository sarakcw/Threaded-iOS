//
//  DatabaseProtocol.swift
//  ThreadedApp
//
//  Created by Sara Kok on 16/9/2025.
//

import Foundation

// Define the type of change done to the database
enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case events
    case userEvents
    case all
}

protocol AuthListener: AnyObject{
    func signingIn()
    func authFailed(error: Error)
    
    
}

// Define a database listener
protocol FirebaseDatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    func onUserEventsChange(change: DatabaseChange, userEvents: [Event]) // Events the user has RSVP'd
    func onAllEventsChange(change: DatabaseChange, events: [Event]) // All created events in the database
    
}

protocol FirebaseDatabaseProtocol: AnyObject {
    func cleanup()
    func addListener(listener: FirebaseDatabaseListener)
    func removeListener(listener: FirebaseDatabaseListener)
    
    // TBC
    func addEvent(name: String, about: String, datetime: Date, address: String, artType: Int, skillLevel:Int, capacity: Int, latitude: Double?, longitude: Double?) -> Event
    func deleteEvent(event: Event)
    func addUserEvents()-> UserEvents
    func getUserEvents() async -> UserEvents?
    func deleteUserEvents (userEvents: UserEvents)
    
    func addEventToUserEvents(event: Event, userEvents: UserEvents) -> Bool
    func removeEventFromUserEvents(event: Event, userEvents: UserEvents)
    
    //Authentication
    var authListener: AuthListener? {get set}

    func logIn(email: String, password: String)
    func signUp(firstName:String, lastName:String, email: String, password:String)
    func signOut()
    func fetchUserName(uid: String) async -> String? 

}
