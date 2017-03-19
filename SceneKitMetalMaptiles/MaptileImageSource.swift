//
//  MaptileImageSource.swift
//  SceneKitMetalMaptiles
//
//  Created by Lachlan Hurst on 18/3/17.
//  Copyright © 2017 Lachlan Hurst. All rights reserved.
//

import Foundation
import UIKit

import AlamofireImage

enum MaptileImageType {
    case diffuse
    case heightmap
    case normalmap
}

typealias maptileProgressUpdateClosure = (
    _ maptile:MapTile,
    _ imageType:MaptileImageType,
    _ progress:Float
) -> (Void)

typealias maptileImageCompleteClosure = (
    _ maptile:MapTile,
    _ imageType:MaptileImageType,
    _ image:UIImage
) -> (Void)

protocol MaptileImageSource {

    func isWithinBounds(mapTile:MapTile) -> Bool

    func urlFrom(mapTile:MapTile, imageType:MaptileImageType) -> String

    func requestMaptile(
        maptile:MapTile,
        imageType:MaptileImageType,
        progress:maptileProgressUpdateClosure?,
        complete: @escaping maptileImageCompleteClosure)
}

class StamenMapsImageSource: MaptileImageSource {

    //example tile url
    //http://d.tile.stamen.com/watercolor/0/0/0.jpg
    // or via https
    //https://stamen-tiles.a.ssl.fastly.net/watercolor/0/0/0.jpg

    var downloader:ImageDownloader!

    init() {
        downloader = ImageDownloader(
            configuration: ImageDownloader.defaultURLSessionConfiguration(),
            downloadPrioritization: .fifo,
            maximumActiveDownloads: 4,
            imageCache: AutoPurgingImageCache()
        )
    }

    internal func isWithinBounds(mapTile: MapTile) -> Bool {
        let maxDimension = Int(pow(2, Double(mapTile.zoomLevel)))
        let x = mapTile.xIndex
        let y = mapTile.yIndex * -1

        return x >= 0 && x < maxDimension && y >= 0 && y < maxDimension
    }

    internal func urlFrom(mapTile: MapTile, imageType: MaptileImageType) -> String {
        assert(imageType == .diffuse, "Only diffuse image type is supported")

        let zoom = mapTile.zoomLevel
        let x = mapTile.xIndex
        let y = mapTile.yIndex * -1

        let url = "https://stamen-tiles.a.ssl.fastly.net/watercolor/\(zoom)/\(x)/\(y).jpg"
        return url
    }

    internal func requestMaptile(
        maptile: MapTile,
        imageType:MaptileImageType,
        progress: maptileProgressUpdateClosure?,
        complete: @escaping (MapTile, MaptileImageType, UIImage) -> (Void))
    {
        let urlString = urlFrom(mapTile: maptile, imageType: imageType)
        print("requesting \(urlString)")
        let urlRequest = URLRequest(url: URL(string: urlString)!)

        downloader.download(urlRequest) { response in
            //print(response.request)
            //print(response.response)
            //debugPrint(response.result)

            if let image = response.result.value {
                //print(image)
                complete(maptile, imageType, image)
            }
        }
    }



}
