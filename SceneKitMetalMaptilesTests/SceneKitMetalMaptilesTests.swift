//
//  SceneKitMetalMaptilesTests.swift
//  SceneKitMetalMaptilesTests
//
//  Created by Lachlan Hurst on 11/3/17.
//  Copyright © 2017 Lachlan Hurst. All rights reserved.
//

import XCTest
@testable import SceneKitMetalMaptiles

class SceneKitMetalMaptilesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSetupMapTiles() {
        let mtm = MaptileManager(mapTileGridSize: 3, tileMaker: MapTileMakerDefault())
        print(mtm.description)
        print()
        mtm.shiftMapTiles(dX: 1, dY: -1)
        print(mtm.description)

        print()
        mtm.shiftMapTiles(dX: -1, dY: 1)
        print(mtm.description)
    }

    func testMapTileForLocation() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        let zeroMt = MapTile(zoomLevel: 0, xIndex: 0, yIndex: 0)

        let mtm = MaptileManager(mapTileGridSize: 3, tileMaker: MapTileMakerDefault())
        var ltMt = mtm.mapTileForLocation(location: GlobalMtLocation(x:0,y:0), zoom: 0)
        var midMt = mtm.mapTileForLocation(location: GlobalMtLocation(x:0.5,y:0.5), zoom: 0)
        var bmMt = mtm.mapTileForLocation(location: GlobalMtLocation(x:0.5,y:0.99), zoom: 0)
        var brMt = mtm.mapTileForLocation(location: GlobalMtLocation(x:0.99,y:0.99), zoom: 0)

        XCTAssert(ltMt == zeroMt)
        XCTAssert(midMt == zeroMt)
        XCTAssert(bmMt == zeroMt)
        XCTAssert(brMt == zeroMt)

        mtm.zoomLevel = 1
        ltMt = mtm.mapTileForLocation(location: GlobalMtLocation(x:0,y:0), zoom: mtm.zoomLevel)
        midMt = mtm.mapTileForLocation(location: GlobalMtLocation(x:0.5,y:0.5), zoom: mtm.zoomLevel)
        bmMt = mtm.mapTileForLocation(location: GlobalMtLocation(x:0.5,y:0.99), zoom: mtm.zoomLevel)
        brMt = mtm.mapTileForLocation(location: GlobalMtLocation(x:0.99,y:0.99), zoom: mtm.zoomLevel)

        XCTAssert(ltMt == MapTile(zoomLevel: 1, xIndex: 0, yIndex: 0))
        XCTAssert(midMt == MapTile(zoomLevel: 1, xIndex: 1, yIndex: 1))
        XCTAssert(bmMt == MapTile(zoomLevel: 1, xIndex: 1, yIndex: 1))
        XCTAssert(brMt == MapTile(zoomLevel: 1, xIndex: 1, yIndex: 1))

        mtm.zoomLevel = 2
        ltMt = mtm.mapTileForLocation(location: GlobalMtLocation(x:0,y:0), zoom: mtm.zoomLevel)
        midMt = mtm.mapTileForLocation(location: GlobalMtLocation(x:0.5,y:0.5), zoom: mtm.zoomLevel)
        bmMt = mtm.mapTileForLocation(location: GlobalMtLocation(x:0.5,y:0.99), zoom: mtm.zoomLevel)
        brMt = mtm.mapTileForLocation(location: GlobalMtLocation(x:0.99,y:0.99), zoom: mtm.zoomLevel)

        XCTAssert(ltMt == MapTile(zoomLevel: 2, xIndex: 0, yIndex: 0))
        XCTAssert(midMt == MapTile(zoomLevel: 2, xIndex: 2, yIndex: 2))
        XCTAssert(bmMt == MapTile(zoomLevel: 2, xIndex: 2, yIndex: 3))
        XCTAssert(brMt == MapTile(zoomLevel: 2, xIndex: 3, yIndex: 3))

    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
