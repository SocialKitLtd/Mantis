//
//  ProxyView.swift
//  MantisExample
//
//  Created by Roi Mulia on 27/09/2021.
//  Copyright © 2021 Echo. All rights reserved.
//

import UIKit

final class ProxyView: UIView {
   
    var target: UIView?
//​
    init(target: UIView) {
        super.init(frame: .zero)
        self.target = target
    }
//​
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
//
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        if view === self {
            return target
        }
        
        return view
    }

}
