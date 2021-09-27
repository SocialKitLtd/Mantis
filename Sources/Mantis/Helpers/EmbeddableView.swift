//
//  EmbeddableView.swift
//  Mantis
//
//  Created by Roi Mulia on 27/09/2021.
//

import UIKit

public protocol EmbeddableView: UIView {
    func contains(rect: CGRect, fromView view: UIView, tolerance: CGFloat) -> Bool
    var representableSize: CGSize { get }
    var ratio: CGFloat { get }
}

extension EmbeddableView {
    func contains(rect: CGRect, fromView view: UIView, tolerance: CGFloat = 1e-6) -> Bool {
        let newRect = view.convert(rect, to: self)
        
        let p1 = newRect.origin
        let p2 = CGPoint(x: newRect.maxX, y: newRect.maxY)
        
        let refBounds = bounds.insetBy(dx: -tolerance, dy: -tolerance)
        
        return refBounds.contains(p1) && refBounds.contains(p2)
    }
}
