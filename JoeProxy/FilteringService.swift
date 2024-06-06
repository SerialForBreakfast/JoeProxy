//
//  FilteringService.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//

import Foundation

protocol FilteringService {
    func shouldAllowRequest(url: String) -> Bool
}

class DefaultFilteringService: FilteringService {
    private let criteria: FilteringCriteria
    
    init(criteria: FilteringCriteria) {
        self.criteria = criteria
    }
    
    func shouldAllowRequest(url: String) -> Bool {
        return criteria.shouldAllow(url: url)
    }
}
