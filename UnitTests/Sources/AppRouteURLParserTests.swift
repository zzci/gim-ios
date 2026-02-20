//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

class AppRouteURLParserTests: XCTestCase {
    var appSettings: AppSettings!
    var appRouteURLParser: AppRouteURLParser!
    
    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        appRouteURLParser = AppRouteURLParser(appSettings: appSettings)
    }
    
    
    func testMatrixUserURL() {
        let userID = "@test:matrix.org"
        guard let url = URL(string: "https://matrix.to/#/\(userID)") else {
            XCTFail("Invalid url")
            return
        }
        
        let route = appRouteURLParser.route(from: url)
        
        XCTAssertEqual(route, .userProfile(userID: userID))
    }
    
    func testMatrixRoomIdentifierURL() {
        let id = "!abcdefghijklmnopqrstuvwxyz1234567890:matrix.org"
        guard let url = URL(string: "https://matrix.to/#/\(id)") else {
            XCTFail("Invalid url")
            return
        }
        
        let route = appRouteURLParser.route(from: url)
        
        XCTAssertEqual(route, .room(roomID: id, via: []))
    }
    
    func testWebRoomIDURL() {
        let id = "!abcdefghijklmnopqrstuvwxyz1234567890:matrix.org"
        guard let url = URL(string: "https://app.element.io/#/room/\(id)") else {
            XCTFail("URL invalid")
            return
        }
        
        let route = appRouteURLParser.route(from: url)
        
        XCTAssertEqual(route, .room(roomID: id, via: []))
    }
    
    func testWebUserIDURL() {
        let id = "@alice:matrix.org"
        guard let url = URL(string: "https://develop.element.io/#/user/\(id)") else {
            XCTFail("URL invalid")
            return
        }
        
        let route = appRouteURLParser.route(from: url)
        
        XCTAssertEqual(route, .userProfile(userID: id))
    }
}
