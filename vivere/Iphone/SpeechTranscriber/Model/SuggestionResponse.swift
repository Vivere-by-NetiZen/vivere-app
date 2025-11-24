//
//  SuggestionResponse.swift
//  vivere
//
//  Created by Ahmed Nizhan Haikal on 10/11/25.
//

import Foundation

struct SuggestionResponse: Decodable {
    let suggestions: [String]
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.suggestions = try c.decodeIfPresent([String].self, forKey: .suggestions) ?? []
    }
    private enum CodingKeys: String, CodingKey { case suggestions }
}

