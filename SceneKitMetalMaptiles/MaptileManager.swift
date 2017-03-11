//
//  MaptileManager.swift
//  SceneKitMetalMaptiles
//
//  Created by Lachlan Hurst on 11/3/17.
//  Copyright © 2017 Lachlan Hurst. All rights reserved.
//

import Foundation

struct GlobalMtLocation {
    var x:Double
    var y:Double
}

func ==(lhs: MapTile, rhs: MapTile) -> Bool {
    return lhs.zoomLevel == rhs.zoomLevel && lhs.xIndex == rhs.xIndex && lhs.yIndex == rhs.yIndex
}

func !=(lhs: MapTile, rhs: MapTile) -> Bool {
    return lhs.zoomLevel != rhs.zoomLevel || lhs.xIndex != rhs.xIndex || lhs.yIndex != rhs.yIndex
}

class MapTile {
    var zoomLevel:Int
    var xIndex:Int
    var yIndex:Int

    init(zoomLevel:Int, xIndex:Int, yIndex:Int) {
        self.zoomLevel = zoomLevel
        self.xIndex = xIndex
        self.yIndex = yIndex
    }

    public var description: String {
        return "\(xIndex),\(yIndex)"
    }
}

class MaptileManager {
    var zoomLevel:Int
    var gridSize:Int
    var mapTiles:[[MapTile?]]
    var mapTileCentre:MapTile!

    var _globalLocation:GlobalMtLocation

    init(mapTileGridSize:Int) {
        assert(mapTileGridSize % 2 == 1, "mapTileGridSize must be odd number")

        zoomLevel = 0
        gridSize = mapTileGridSize
        _globalLocation = GlobalMtLocation(x: 1.0, y: 0.5)
        mapTiles = Array(repeating:Array(repeating:nil, count:gridSize), count:gridSize)
        setupMapTiles()
    }

    var globalLocation:GlobalMtLocation {
        get {
            return _globalLocation
        }
        set(newLocation) {
            let newCentreMt = mapTileForLocation(location: newLocation, zoom: zoomLevel)
            if newCentreMt != mapTileCentre {
                //then grid needs update
                let dX = newCentreMt.xIndex - mapTileCentre.xIndex
                let dY = newCentreMt.yIndex - mapTileCentre.yIndex
            }
            _globalLocation = newLocation
        }
    }

    func shiftMapTiles(dX:Int, dY:Int) {
        var newMapTiles:[[MapTile?]] = Array(repeating:Array(repeating:nil, count:gridSize), count:gridSize)

        for i in 0..<gridSize {
            for j in 0..<gridSize {
                let oldMt = mapTiles[i][j]
                let newXindex = i + dX
                let newYindex = j + dY
                if newXindex >= 0 && newXindex < gridSize && newYindex >= 0 && newYindex < gridSize {
                    newMapTiles[newXindex][newYindex] = oldMt
                }
            }
        }

        mapTiles = newMapTiles
    }

    func setupMapTiles() {
        let centerMt = mapTileForLocation(location: _globalLocation, zoom: zoomLevel)
        let offset = (gridSize - 1) / 2

        let startRange = centerMt.xIndex - offset
        let endRange = centerMt.xIndex + offset

        var i:Int = 0
        for x in startRange...endRange {
            var j:Int = 0
            for y in startRange...endRange {
                let newMt = MapTile(zoomLevel: zoomLevel, xIndex: x, yIndex: y)
                mapTiles[i][j] = newMt
                if newMt == centerMt {
                    self.mapTileCentre = newMt
                }
                j = j + 1
            }
            i = i + 1
        }

    }

    func mapTileForLocation(location:GlobalMtLocation, zoom:Int) -> MapTile {
        let totalTileSize = pow(2, Double(zoom))
        let xD = location.x * totalTileSize
        let yD = location.y * totalTileSize

        let xIndex = Int(floor(xD))
        let yIndex = Int(floor(yD))

        let mt = MapTile(zoomLevel: zoom, xIndex: xIndex, yIndex: yIndex)
        return mt
    }

    public var description: String {
        var al = ""
        for i in 0..<gridSize {
            var ls = "("
            for j in 0..<gridSize {
                if let mt = mapTiles[j][i] {
                    ls = ls + "[\(mt.description)] "
                } else {
                    ls = ls + "[na] "
                }
            }
            ls = ls + ")\n"
            al = al + ls
        }
        return al
    }
}
