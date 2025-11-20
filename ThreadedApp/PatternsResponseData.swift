//
//  PatternsResponseData.swift
//  ThreadedApp
//
//  Created by Sara Kok on 3/10/2025.
//

import UIKit

class PatternsResponseData: NSObject, Decodable {
    var patterns: [PatternData]?
    
    private enum CodingKeys: String, CodingKey {
    case patterns = "patterns"
    }
    
    required init(from decoder: Decoder) throws {
        
       let container = try decoder.container(keyedBy: CodingKeys.self)
       patterns = try container.decode([PatternData].self, forKey: .patterns)
       super.init()
   }
    
}
