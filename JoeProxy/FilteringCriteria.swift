//
//  FilteringCriteria.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//

import Foundation

struct FilteringCriteria {
    let urls: [String]
    let filterType: FilterType
    
    enum FilterType {
        case allow, block
    }
    
    func shouldAllow(url: String) -> Bool {
        switch filterType {
        case .allow:
            return urls.contains { url.contains($0) }
        case .block:
            return !urls.contains { url.contains($0) }
        }
    }
}
