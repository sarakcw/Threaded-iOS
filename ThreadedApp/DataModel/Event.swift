//
//  Event.swift
//  ThreadedApp
//
//  Created by Sara Kok on 16/9/2025.
//

import UIKit
import FirebaseFirestore

//enum ArtType: Int{
//    case knitting = 0
//    case crochet = 1
//    case embroidery = 2
//    
//}
//
//enum SkillLevel: Int{
//    case all = 0
//    case beginner = 1
//    case intermediate = 2
//    case advance = 3
//
//}

class Event: NSObject, Codable {
    @DocumentID var id: String?

    var name: String?
    var about: String?
    var datetime: Date?
    var address: String?
    var artType: Int?
    var skillLevel: Int?
    var capacity: Int?
    var host: String?
    var image: String?
    var latitude: Double?
    var longitude: Double?

    
}
