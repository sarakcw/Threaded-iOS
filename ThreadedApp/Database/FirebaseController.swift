//
//  FirebaseController.swift
//  ThreadedApp
//
//  Created by Sara Kok on 16/9/2025.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseController: NSObject, FirebaseDatabaseProtocol {
    
    // Listeners to listen for any changes
    var listeners = MulticastDelegate<FirebaseDatabaseListener>()
    
    var eventsList: [Event]
    let DEFAULT_USEREVENT_USERID = "DefaultUser"

    
    // Setup reference to Firebase Authentication System
    var authController: Auth
    var database: Firestore
    var eventsRef: CollectionReference?
    var userEventsRef: CollectionReference?
    var currentUser: FirebaseAuth.User?
    var userEvents: UserEvents
    
    weak var authListener : AuthListener?
    
    var eventsListener: ListenerRegistration?
    var userEventsListener: ListenerRegistration?
    
    override init(){
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
        eventsList = [Event]()
        userEvents = UserEvents()
        super.init()
        
    }
    
    // MARK: -Authentication
    func logIn(email: String, password: String) {
           Task{
               do{
                   let authDataResult = try await authController.signIn(withEmail: email, password: password)
                   currentUser = authDataResult.user
                   
                   cleanup()
                   self.setupEventsListener()
                   self.setupUserEventsListener()
                   authListener?.signingIn()
                   
               }
               catch{
                   authListener?.authFailed(error: error)
               }
           }

       }
    
    func signUp(firstName:String, lastName:String, email: String, password: String){
        Task{
            do {
                let authDataResult = try await authController.createUser(withEmail: email, password: password)
                currentUser = authDataResult.user
                
                // Unwrap userId
                guard let userId = currentUser?.uid else {
                    print("No user ID found")
                    return
                }
                // Create new userEvents array for new user
                let userEvents = database.collection("UserEvents").document(userId)
                try await userEvents.setData([
                    "events": [],
                    "userId": userId

                ])
                print (userEvents)

                // Add new user to firebase
                let userDoc = database.collection("Users").document(userId)
                try await userDoc.setData([
                    "email": email,
                    "firstName": firstName,
                    "lastName": lastName,
                ])
                
                
                self.setupEventsListener()
                self.setupUserEventsListener()

                authListener?.signingIn()

            }
            catch{
                authListener?.authFailed(error: error)
            }
        }
    
    }

    func signOut(){
        do {
            try authController.signOut()
            self.cleanup()
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
    }
    
    func fetchUserName(uid: String)  async -> String? {
        let userRef = database.collection("Users").document(uid)
        
        do {
            let userSnapshot = try await userRef.getDocument()
            guard let userData = userSnapshot.data() else{return nil}
            
            let firstName = userData["firstName"] as? String ?? ""
            let lastName = userData["lastName"] as? String ?? ""
            return "\(firstName) \(lastName)"
                
        } catch {
            return nil
        }
        
    }
    
    //MARK: -Listeners
    func addListener(listener: FirebaseDatabaseListener){
        listeners.addDelegate(listener) //adds the new database listener to the list of listeners
        
        if listener.listenerType == .userEvents || listener.listenerType == .all {
            listener.onUserEventsChange(change: .update, userEvents: userEvents.events ?? [])
                            // provide the listener with initial immediate results depending on what type of listener it is
                }
        if listener.listenerType == .events || listener.listenerType == .all {
               listener.onAllEventsChange(change: .update, events: eventsList)
                       // provide the listener with initial immediate results depending on what type of listener it is
           }

    }
    
    func removeListener(listener: FirebaseDatabaseListener){
        listeners.removeDelegate(listener)

    }
    
    func cleanup(){
        eventsList.removeAll()
        userEvents = UserEvents() // Reset
        
        // Remove listeners
        eventsListener?.remove()
        eventsListener = nil
           
       userEventsListener?.remove()
       userEventsListener = nil
           
       // Clear delegate list
       listeners = MulticastDelegate<FirebaseDatabaseListener>()
           
    }
    
    func addEvent(name: String, about: String, datetime: Date, address: String, artType: Int, skillLevel:Int, capacity: Int, latitude: Double?, longitude: Double? ) -> Event {
    
        // Get userId
       guard let userId = currentUser?.uid else { return Event()}
    
        //  Create an event object
        let event = Event()
        event.name = name
        event.about = about
        event.datetime = datetime
        event.address = address
        event.artType = artType
        event.skillLevel = skillLevel
        event.capacity = capacity
        event.host = userId
        event.latitude = latitude
        event.longitude = longitude

        // Attempt to add it to Firestore
        do {
            if let eventRef = try eventsRef?.addDocument(from: event) {
                event.id = eventRef.documentID
                
            }
        } catch {
            print("Failed to serialize event")
        }
        
        userEventsRef = database.collection("UserEvents")

        // Get the current user's events array ("events")
        userEventsRef?.whereField("userId", isEqualTo: userId).getDocuments { userEventSnapshot, error in
            
            var currentUserEvents = UserEvents()
            // Look for at least one document
            if let doc = userEventSnapshot?.documents.first {
                // Find existing UserEvents
                currentUserEvents.id = doc.documentID
                currentUserEvents.userId = userId
            } else {
                // No UserEvents found, create it
                print("no user events found")
                currentUserEvents = self.addUserEvents()
            }
            // Add new event to user events
            let result = self.addEventToUserEvents(event: event, userEvents: currentUserEvents)
            print("Add event to user events result: \(result)")
                

        }
        
        return event

    }
    
    func addUserEvents() -> UserEvents{
            guard let userId = currentUser?.uid else { return UserEvents()}

            let userEvents = UserEvents()
            userEvents.events = []
            
            if let userEventRef = userEventsRef?.addDocument(data: [
                "events": [],
                "userId": userId

            ]) {
                userEvents.id = userEventRef.documentID
            }
            
            return userEvents
        }

    
    func getUserEvents() async -> UserEvents? {
        guard let userUid = currentUser?.uid else { return nil }
        
        userEventsRef = database.collection("UserEvents")
        
        do{
            let userEventSnapshot = try await
            // Get the current user's events array ("events")
            userEventsRef?.whereField("userId", isEqualTo: userUid).getDocuments()
                guard let doc = userEventSnapshot?.documents.first else {
                    print("No UserEvents found for current user")
                    return nil
                }
                
                // Convert Firebase data to UserEvents object
                let userEvents = UserEvents()
                userEvents.id = doc.documentID
                userEvents.userId = userUid
                
                return userEvents
            }catch{
                print("Error fetching UserEvents:", error.localizedDescription)
                        return nil
            }
    
    }
    
    func addEventToUserEvents(event: Event, userEvents: UserEvents) -> Bool{
        guard let eventID = event.id, let userEventsID = userEvents.id else {
                    return false
                }
            
        // Manually handle relationships
        if let newEventRef = eventsRef?.document(eventID) {
            userEventsRef?.document(userEventsID).updateData(
                ["events" : FieldValue.arrayUnion([newEventRef])]
            )
            return true
        }
        return false

    }
    func deleteEvent(event: Event){
        if let eventId = event.id{
            eventsRef?.document(eventId).delete()
            
            guard let userId = currentUser?.uid else { return}

            // Get the current user's events array ("events")
            userEventsRef?.whereField("userId", isEqualTo: userId).getDocuments { userEventSnapshot, error in
                
                // Look for at least one document
                guard let doc = userEventSnapshot?.documents.first else {
                    print("No UserEvents found for current user")
                    return
                }
                
                let userEvents = UserEvents()
                userEvents.id = doc.documentID
                userEvents.userId = userId
                
                // Remove event from user events
                let result = self.removeEventFromUserEvents(event: event, userEvents: userEvents)
                print("Removed event to user events result: \(result)")
                    

            }
        }
    }
    func deleteUserEvents(userEvents: UserEvents){
        if let userEventsId = userEvents.id{
            userEventsRef?.document(userEventsId).delete()
        }
    }
    func removeEventFromUserEvents(event: Event, userEvents: UserEvents){
    
//     Check if userevent contains the event
        if ((userEvents.events?.contains(event)) != nil), let userEventsId = userEvents.id, let eventId = event.id {
            if let removedEventRef = eventsRef?.document(eventId) {
                userEventsRef?.document(userEventsId).updateData(
                    ["events": FieldValue.arrayRemove([removedEventRef])]
                )
            }
        }

    }
    
    // MARK: - Firebase Controller Specific Methods
    func getEventById(_ id: String) -> Event?{
        for event in eventsList {
            if event.id == id {
                return event
            }
        }
        return nil
    }
    func setupEventsListener(){
        // Get reference to events collection from firebase
        eventsRef = database.collection("Events")
        
        // Listen for changes
        eventsListener = eventsRef?.addSnapshotListener() {
            (querySnapshot, error) in
            
            // Ensure snapshot is valid
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            self.parseEventSnapshot(snapshot: querySnapshot)
        }
        if self.userEventsRef == nil {
            self.setupUserEventsListener()
        }
    }
    func setupUserEventsListener(){
        guard let userId = currentUser?.uid else { return }
        //Get the reference to the user evenets collection from firebase
        userEventsRef = database.collection("UserEvents")
        
        // Get the UserEvents ref where the user is "DefaultUser"
        userEventsListener = userEventsRef?.whereField("userId", isEqualTo: userId).addSnapshotListener {
            (querySnapshot, error) in
            guard let querySnapshot = querySnapshot, let userEventSnapshot =
                querySnapshot.documents.first else {
                
                print("Error fetching user events: \(String(describing: error))")
                return
            }
            // Handle parsing from Firestore
            self.parseUserEventSnapshot(snapshot: userEventSnapshot)
        }
    }
    
    
    func parseEventSnapshot(snapshot: QuerySnapshot){
        
        //Loop through each change
        snapshot.documentChanges.forEach { (change) in
            var event: Event
            do {
                event = try change.document.data(as: Event.self)
            } catch {
                fatalError("Unable to decode event: \(error.localizedDescription)")
            }
            
            // Handle modifications and deletions
            if change.type == .added {
                eventsList.insert(event, at: Int(change.newIndex))
            }
            else if change.type == .modified {
                eventsList.remove(at: Int(change.oldIndex))
                eventsList.insert(event, at: Int(change.newIndex))
            }
            else if change.type == .removed {
                eventsList.remove(at: Int(change.oldIndex))
            }
            // Use multicast delegate to invoke method to call onAllEventsChange
            listeners.invoke { (listener) in
            if listener.listenerType == ListenerType.events || listener.listenerType == ListenerType.all {
                listener.onAllEventsChange(change: .update, events: eventsList)
                }
            }
        }
        
    }
    func parseUserEventSnapshot(snapshot: QueryDocumentSnapshot){
        
        userEvents = UserEvents()
        userEvents.userId = snapshot.data()["userId"] as? String
        userEvents.id = snapshot.documentID
        
        if let eventReferences = snapshot.data()["events"] as? [DocumentReference] {
            for reference in eventReferences {
                if let event = getEventById(reference.documentID) {
                    if userEvents.events == nil {
                        userEvents.events = []
                    }
                    userEvents.events?.append(event)
                }
            }
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.userEvents || listener.listenerType == ListenerType.all {
                    listener.onUserEventsChange(change: .update, userEvents: userEvents.events ?? [])
                }
            }
            
        }
    }


}
