//
//  RavelryAPI.swift
//  ThreadedApp
//
//  Created by Sara Kok on 3/10/2025.
//

import Foundation

final class RavelryAPI{
    
    var MAX_PER_PAGE  = 10
    
    private let baseURL = URL(string: "https://api.ravelry.com/")!
    private let username: String
    private let password: String
    private let session: URLSession
    
    init(username: String, password: String, session: URLSession = .shared) {
            self.username = username
            self.password = password
            self.session = session
    }
    
    // Create the Authorization header for Basic Auth
    private var authorizationHeader: String {
            let login = "\(username):\(password)"
            guard let data = login.data(using: .utf8) else { return "" }
            return "Basic \(data.base64EncodedString())"
    }
    
    // Retrieve the full details of a pattern
    func fetchPatternDetail(id: Int) async throws -> PatternData {
        // Endpoint: patterns/{id}.json
        let url = baseURL.appendingPathComponent("patterns/\(id).json")

        // Create GET request with the auth header
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")

        // Make the network async call
        let (data, response) = try await session.data(for: request)
        // Make sure the code is 2xx (OK)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        // Use decoder to decode the JSON response
        let decoder = JSONDecoder()

        // The detail response is wrapped, like: { "pattern": { ... } }
        struct PatternDetailResponse: Decodable {
            let pattern: PatternData
        }

        let detail = try decoder.decode(PatternDetailResponse.self, from: data)
        return detail.pattern
    }

    // Using the API to search for free patterns
    func fetchFreeDownloadablePatterns(query: String = "", page: Int = 1) async throws -> [PatternData] {
        
        // Build the search URL
        var comps = URLComponents(url: baseURL.appendingPathComponent("patterns/search.json"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "availability", value: "ravelry"), // filter Ravelry Download to retrieve pdf url easily
            URLQueryItem(name: "sort", value: "most_popular"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: "\(MAX_PER_PAGE)")
        ]
        guard let url = comps.url else { throw URLError(.badURL) }
        
        // Create a GET request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        
        // Send request
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Decode the response
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(PatternsResponseData.self, from: data)
        let searchedPatterns = searchResponse.patterns ?? [] // The response recieved is all the patterns in an array
        let freePatterns = searchedPatterns.filter { $0.free == true } // Filter to get free patterns
        
        
        // Fetch details for each free pattern in parallel for faster loading times
        let detailedPatterns: [PatternData] = await withTaskGroup(of: PatternData?.self) { group in
            for searchedPattern in freePatterns {
                if let id = searchedPattern.id {
                    group.addTask {
                        do {
                            return try await self.fetchPatternDetail(id: id)
                        } catch {
                            print("Failed to fetch detail for id \(searchedPattern.id!): \(error)")
                            return nil
                        }
                    }
                }
            }
            // Succesfully fetched results
            var results: [PatternData] = []
            for await detail in group {
                if let detail = detail {
                    results.append(detail)
                }
            }
            
            return results
        }
        
        return detailedPatterns

    }
}
