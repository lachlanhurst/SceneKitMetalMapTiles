//
//  MaptileManager.swift
//  SceneKitMetalMaptiles
//
//  Created by Lachlan Hurst on 11/3/17.
//  Copyright © 2017 Lachlan Hurst. All rights reserved.
//

import Foundation
import Metal
import UIKit

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

protocol MapTileMaker {
    func newMapTile(zoomLevel:Int, xIndex:Int, yIndex:Int) -> MapTile
}

class MapTileMakerDefault: MapTileMaker {
    func newMapTile(zoomLevel: Int, xIndex: Int, yIndex: Int) -> MapTile {
        return MapTile(zoomLevel: zoomLevel, xIndex: xIndex, yIndex: yIndex)
    }
}

class MapTileMakerImage: MapTileMaker {
    func newMapTile(zoomLevel: Int, xIndex: Int, yIndex: Int) -> MapTile {
        return MapTileImage(zoomLevel: zoomLevel, xIndex: xIndex, yIndex: yIndex)
    }
}

class MapTileMakerTexture: MapTileMaker {
    func newMapTile(zoomLevel: Int, xIndex: Int, yIndex: Int) -> MapTile {
        return MapTileTexture(zoomLevel: zoomLevel, xIndex: xIndex, yIndex: yIndex)
    }
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

class MapTileImage:MapTile {
    var _image:UIImage?

    override init(zoomLevel:Int, xIndex:Int, yIndex:Int) {
        super.init(zoomLevel: zoomLevel, xIndex: xIndex, yIndex: yIndex)
    }

    var image:UIImage {
        get {
            if let img = _image {
                return img
            } else {
                let text =  "\(self.description)\n \(self.zoomLevel)  "
                let img = Utils.textToImage(text, size: CGSize(width: 45, height: 45), atPoint: CGPoint(x: 0, y: 0))
                _image = img
                return img
            }
        }
    }

    var initialised:Bool {
        return _image != nil
    }
}

class MapTileTexture:MapTile {
    var _texture:MTLTexture? = nil

    override init(zoomLevel:Int, xIndex:Int, yIndex:Int) {
        super.init(zoomLevel: zoomLevel, xIndex: xIndex, yIndex: yIndex)
    }

    var texture:MTLTexture {
        get {
            if let tex = _texture {
                return tex
            } else {
                let text =  "\(self.description)\n\(self.zoomLevel)  "
                let img = Utils.textToImage(text, size: CGSize(width: 45, height: 45), atPoint: CGPoint(x: 0, y: 0))
                let tex = Utils.imageToTexture(image: img)
                _texture = tex
                return tex
            }
        }
    }

    var initialised:Bool {
        return _texture != nil
    }
}

protocol MapTileManagerDelegate: class {
    func mapTilesShifted(dX:Int, dY:Int)
    func mapTilesZoomed(dZoomLevel:Int)
}

class MaptileManager {
    var _zoomLevel:Int


    var gridSize:Int
    var mapTiles:[[MapTile?]]
    var mapTileCentre:MapTile!

    var maxZoomLevel:Int = 15
    var minZoomLevel:Int = 0

    var tileMakerFactory:MapTileMaker

    weak var delegate:MapTileManagerDelegate? = nil

    var _globalLocation:GlobalMtLocation

    init(mapTileGridSize:Int, tileMaker:MapTileMaker) {
        assert(mapTileGridSize % 2 == 1, "mapTileGridSize must be odd number")

        _zoomLevel = 0
        gridSize = mapTileGridSize
        _globalLocation = GlobalMtLocation(x: 0.5, y: 0.5)
        mapTiles = Array(repeating:Array(repeating:nil, count:gridSize), count:gridSize)
        tileMakerFactory = tileMaker
        setupMapTiles()
    }

    var globalLocation:GlobalMtLocation {
        get {
            return _globalLocation
        }
        set(newLocation) {
            //print("\(newLocation.x), \(newLocation.y)")
            let newCentreMt = mapTileForLocation(location: newLocation, zoom: zoomLevel)
            //print(newCentreMt.description)
            if newCentreMt != mapTileCentre {
                //then grid needs update
                let dX = newCentreMt.xIndex - mapTileCentre.xIndex
                let dY = newCentreMt.yIndex - mapTileCentre.yIndex
                shiftMapTiles(dX: dX, dY: dY)
            }
            _globalLocation = newLocation
        }
    }

    var zoomLevel:Int {
        get {
            return _zoomLevel
        }
        set(newZoomLevel) {
            guard newZoomLevel >= minZoomLevel && newZoomLevel <= maxZoomLevel else {
                return
            }
            guard newZoomLevel != _zoomLevel else {
                return
            }
            let zoomIn = newZoomLevel > _zoomLevel // is the map being zoomed in
            let beforeZoomCentre = mapTileForLocation(location: _globalLocation, zoom: zoomLevel)
            print("before z = \(beforeZoomCentre.description)")

            _zoomLevel = newZoomLevel
            //print("zl = \(_zoomLevel)")
            let dZoomLevel = newZoomLevel - _zoomLevel



            setupMapTiles()
            let afterZoomCentre = mapTileForLocation(location: _globalLocation, zoom: zoomLevel)
            print("after z = \(afterZoomCentre.description)")

            if let delegate = self.delegate {
                delegate.mapTilesZoomed(dZoomLevel: dZoomLevel)
            }

            /*if zoomIn {
                let expectedCentreX = beforeZoomCentre.xIndex * 2
                let expectedCentreY = beforeZoomCentre.yIndex * 2

                //let deltaExpX = afterZoomCentre.xIndex - expectedCentreX
                //let deltaExpY = afterZoomCentre.yIndex - expectedCentreY
                let deltaExpX = expectedCentreX - afterZoomCentre.xIndex //+ 1
                let deltaExpY = expectedCentreY - afterZoomCentre.yIndex //+ 1
                //print("mtc = \(self.mapTileCentre.description)")
                print("delta zoom shoft = \(deltaExpX), \(deltaExpY)")
                shiftMapTiles(dX: deltaExpX, dY: deltaExpY)
                //print("mtc after = \(self.mapTileCentre.description)")
            }*/
        }
    }

    func shiftMapTiles(dX:Int, dY:Int) {
        var newMapTiles:[[MapTile?]] = Array(repeating:Array(repeating:nil, count:gridSize), count:gridSize)

        for i in 0..<gridSize {
            for j in 0..<gridSize {
                let oldXindex = i + dX
                let oldYindex = j + dY
                var mt:MapTile? = nil
                if oldXindex >= 0 && oldXindex < gridSize && oldYindex >= 0 && oldYindex < gridSize {
                    mt = mapTiles[oldXindex][oldYindex]
                } else if oldXindex < 0 && oldYindex < 0 {
                    let closest = mapTiles[0][0]!
                    mt = tileMakerFactory.newMapTile(zoomLevel: zoomLevel, xIndex: closest.xIndex - 1, yIndex: closest.yIndex - 1)
                } else if oldXindex >= gridSize && oldYindex >= gridSize {
                    let closest = mapTiles[gridSize - 1][gridSize - 1]!
                    mt = tileMakerFactory.newMapTile(zoomLevel: zoomLevel, xIndex: closest.xIndex + 1, yIndex: closest.yIndex + 1)
                } else if oldXindex < 0 && oldYindex >= gridSize {
                    let closest = mapTiles[0][gridSize - 1]!
                    mt = tileMakerFactory.newMapTile(zoomLevel: zoomLevel, xIndex: closest.xIndex - 1, yIndex: closest.yIndex + 1)
                } else if oldXindex >= gridSize && oldYindex < 0 {
                    let closest = mapTiles[gridSize - 1][0]!
                    mt = tileMakerFactory.newMapTile(zoomLevel: zoomLevel, xIndex: closest.xIndex + 1, yIndex: closest.yIndex - 1)
                } else if oldXindex < 0 {
                    let closest = mapTiles[0][oldYindex]!
                    mt = tileMakerFactory.newMapTile(zoomLevel: zoomLevel, xIndex: closest.xIndex - 1, yIndex: closest.yIndex)
                } else if oldYindex < 0 {
                    let closest = mapTiles[oldXindex][0]!
                    mt = tileMakerFactory.newMapTile(zoomLevel: zoomLevel, xIndex: closest.xIndex, yIndex: closest.yIndex - 1)
                } else if oldXindex >= gridSize {
                    let closest = mapTiles[gridSize - 1][oldYindex]!
                    mt = tileMakerFactory.newMapTile(zoomLevel: zoomLevel, xIndex: closest.xIndex + 1, yIndex: closest.yIndex)
                } else if oldYindex >= gridSize {
                    let closest = mapTiles[oldXindex][gridSize - 1]!
                    mt = tileMakerFactory.newMapTile(zoomLevel: zoomLevel, xIndex: closest.xIndex, yIndex: closest.yIndex + 1)
                }
                newMapTiles[i][j] = mt
            }
        }

        let centerIndex = (gridSize - 1) / 2
        mapTileCentre = newMapTiles[centerIndex][centerIndex]

        mapTiles = newMapTiles

        if let delegate = self.delegate {
            delegate.mapTilesShifted(dX: dX, dY: dY)
        }
    }

    func setupMapTiles() {
        let centerMt = mapTileForLocation(location: _globalLocation, zoom: zoomLevel)
        let offset = (gridSize - 1) / 2

        let startRangeX = centerMt.xIndex - offset
        let endRangeX = centerMt.xIndex + offset
        let startRangeY = centerMt.yIndex - offset
        let endRangeY = centerMt.yIndex + offset

        var i:Int = 0
        for x in startRangeX...endRangeX {
            var j:Int = 0
            for y in startRangeY...endRangeY {
                let newMt = tileMakerFactory.newMapTile(zoomLevel: zoomLevel, xIndex: x, yIndex: y)
                mapTiles[i][j] = newMt
                if newMt == centerMt {
                    self.mapTileCentre = newMt
                }
                j = j + 1
            }
            i = i + 1
        }

    }

    var mapTileGlobalSize:Float {
        get {
            let totalTileSize = pow(2, Float(zoomLevel))
            return 1 / totalTileSize
        }
    }

    func mapTileForLocation(location:GlobalMtLocation, zoom:Int) -> MapTile {
        let totalTileSize = pow(2, Double(zoom))
        let xD = location.x * totalTileSize
        let yD = location.y * totalTileSize

        let xIndex = Int(floor(xD))
        let yIndex = Int(floor(yD))

        let mt = tileMakerFactory.newMapTile(zoomLevel: zoom, xIndex: xIndex, yIndex: yIndex)
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
