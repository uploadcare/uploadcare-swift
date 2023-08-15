//
//  Webhook.swift
//  
//
//  Created by Sergey Armodin on 19.07.2020.
//  Copyright © 2020 Uploadcare, Inc. All rights reserved.
//

import Foundation

/// Webhook.
public struct Webhook: Codable {
    
    /// Webhook ID.
    public var id: Int
    
    /// Webhook creation date-time.
    public var created: Date
    
    /// Webhook update date-time.
    public var updated: Date
    
    /// Webhook event.
    public var event: String
    
    /// Where webhook data will be posted.
    public var targetUrl: String
    
    /// Webhook project ID.
    public var project: Int
    
    /// Is the webhook active or not.
    public var isActive: Bool
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case created
        case updated
        case event
        case targetUrl = "target_url"
        case project
        case isActive = "is_active"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        
        // Date formatter for parsing
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        var dateCreated = Date(timeIntervalSince1970: 0)
        let dateCreatedString = try container.decodeIfPresent(String.self, forKey: .created)
        if let val = dateCreatedString, let date = dateFormatter.date(from: val) {
            dateCreated = date
        }
        created = dateCreated
        
        var dateUpdated = Date(timeIntervalSince1970: 0)
        let dateUpdatedString = try container.decodeIfPresent(String.self, forKey: .updated)
        if let val = dateUpdatedString, let date = dateFormatter.date(from: val) {
            dateUpdated = date
        }
        updated = dateUpdated
        
        event = try container.decodeIfPresent(String.self, forKey: .event) ?? ""
        targetUrl = try container.decodeIfPresent(String.self, forKey: .targetUrl) ?? ""
        project = try container.decodeIfPresent(Int.self, forKey: .project) ?? 0
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
        
    }
}
