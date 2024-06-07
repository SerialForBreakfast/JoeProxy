//
//  FilteringServiceTests.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/6/24.
//
import XCTest
@testable import JoeProxy

class FilteringServiceTests: XCTestCase {

    func testAllowListFiltering() {
        let criteria = FilteringCriteria(urls: ["example.com"], filterType: .allow)
        let filteringService = DefaultFilteringService(criteria: criteria)

        XCTAssertTrue(filteringService.shouldAllowRequest(url: "https://example.com/test"))
        XCTAssertFalse(filteringService.shouldAllowRequest(url: "https://other.com/test"))
    }

    func testBlockListFiltering() {
        let criteria = FilteringCriteria(urls: ["example.com"], filterType: .block)
        let filteringService = DefaultFilteringService(criteria: criteria)

        XCTAssertFalse(filteringService.shouldAllowRequest(url: "https://example.com/test"))
        XCTAssertTrue(filteringService.shouldAllowRequest(url: "https://other.com/test"))
    }

    func testEmptyAllowList() {
        let criteria = FilteringCriteria(urls: [], filterType: .allow)
        let filteringService = DefaultFilteringService(criteria: criteria)

        XCTAssertFalse(filteringService.shouldAllowRequest(url: "https://example.com/test"))
        XCTAssertFalse(filteringService.shouldAllowRequest(url: "https://other.com/test"))
    }

    func testEmptyBlockList() {
        let criteria = FilteringCriteria(urls: [], filterType: .block)
        let filteringService = DefaultFilteringService(criteria: criteria)

        XCTAssertTrue(filteringService.shouldAllowRequest(url: "https://example.com/test"))
        XCTAssertTrue(filteringService.shouldAllowRequest(url: "https://other.com/test"))
    }
}

class MockFilteringService: FilteringService {
    private let shouldAllow: Bool

    init(shouldAllow: Bool) {
        self.shouldAllow = shouldAllow
    }

    func shouldAllowRequest(url: String) -> Bool {
        return shouldAllow
    }
}
