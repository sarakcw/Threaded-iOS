//
//  UserEvents.swift
//  ThreadedApp
//
//  Created by Sara Kok on 17/9/2025.
//

import UIKit
import FirebaseFirestore

class UserEvents: NSObject, Codable {
    
    @DocumentID var id: String?
    
    var events: [Event]? = []
    var userId: String?

}
