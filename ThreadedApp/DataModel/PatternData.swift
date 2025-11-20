//
//  PatternData.swift
//  ThreadedApp
//
//  Created by Sara Kok on 3/10/2025.
//

import UIKit

struct Photo: Decodable {
    let medium2URL: String?

    private enum CodingKeys: String, CodingKey {
        case medium2URL = "medium2_url"
    }
}

class PatternData: NSObject, Decodable {
    var id: Int?
    var name: String?
    var patternAuthor: String?
    var craft: String?
    var photos: [Photo]?
    var patternNeedleSizes: [NeedleSize]
    var sizesAvailable: String
    var yarnWeightDescription: String
    var yardage: Int?
    var difficultyAverage: Double?
    var permalink: String?
    var patternUrl: URL? { // Create the url to ravelry by using the permalink
        if let p = permalink {
            return URL(string: "https://ravelry.com/patterns/library/\(p)")
        }
        return nil
    }
    var free: Bool?


    private enum PatternKeys: String, CodingKey {
        case id, name, craft, photos, yardage, free, permalink
        case patternAuthor = "pattern_author"
        case patternNeedleSizes = "pattern_needle_sizes"
        case sizesAvailable = "sizes_available"
        case yarnWeightDescription = "yarn_weight_description"
        case difficultyAverage = "difficulty_average"
        
        
    }

    private enum PatternAuthorKeys: String, CodingKey{
        case name
        
    }
    private enum CraftKeys: String, CodingKey {
        case name
    }

    struct NeedleSize: Decodable {
        let id: Int
        let hook: String?
        let metric: Float?
        let needle_name: String?
        let needle_size_id: Int?
        let us: String?
    }

    required init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: PatternKeys.self)

        // Use 'decodeIfPresent' to safely decode and return nil if empty
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        photos = try container.decodeIfPresent([Photo].self, forKey: .photos)
        patternNeedleSizes = try container.decodeIfPresent([NeedleSize].self, forKey: .patternNeedleSizes) ?? []
        sizesAvailable = try container.decodeIfPresent(String.self, forKey: .sizesAvailable) ?? ""
        yarnWeightDescription = try container.decodeIfPresent(String.self, forKey: .yarnWeightDescription) ?? ""
        yardage = try container.decodeIfPresent(Int.self, forKey: .yardage)
        difficultyAverage = try container.decodeIfPresent(Double.self, forKey: .difficultyAverage)
        free = try container.decode(Bool.self, forKey: .free)
        permalink = try container.decode(String.self, forKey: .permalink)
        
        //Get container for craft
        if let craftContainer = try? container.nestedContainer(keyedBy: CraftKeys.self, forKey: .craft) {
            craft = try craftContainer.decodeIfPresent(String.self, forKey: .name)
        }
        
        // Get nested container for designer
        if let patternAuthorContainer = try? container.nestedContainer(keyedBy: PatternAuthorKeys.self, forKey: .patternAuthor) {
            patternAuthor = try patternAuthorContainer.decodeIfPresent(String.self, forKey: .name)
        }

        super.init()

    }
}
