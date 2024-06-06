//
//  FilteringCriteria.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//

import Foundation

enum FilterType {
    case allow
    case block
}

struct FilteringCriteria {
    let urls: [String]
    let filterType: FilterType
    
    func shouldAllow(url: String) -> Bool {
        let matches = urls.contains { url.contains($0) }
        return filterType == .allow ? matches : !matches
    }
}
