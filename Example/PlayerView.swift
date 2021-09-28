//
//  PlayerView.swift
//  MantisExample
//
//  Created by Roi Mulia on 28/09/2021.
//  Copyright © 2021 Echo. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

open class PlayerView: UIView {

    public var player: AVPlayer? {
        get {
            return playerLayer?.player
        }
        set {
            playerLayer?.videoGravity = .resizeAspectFill
            playerLayer?.player = newValue
        }
    }
    
    public weak var playerLayer: AVPlayerLayer? {
        return layer as? AVPlayerLayer
    }
    
    // Override UIView property
    override public static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
