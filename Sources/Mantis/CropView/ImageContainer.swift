//
//  ImageContainer.swift
//  Mantis
//
//  Created by Echo on 10/29/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

public class ImageContainer: UIView, EmbeddableView {
 
    public var representableSize: CGSize {
        return image.size
    }
    
    public var ratio: CGFloat {
        return image.size.width / image.size.height
    }
    

    lazy private var imageView: UIImageView = {
        let imageView = UIImageView(frame: bounds)
        imageView.layer.minificationFilter = .trilinear
        imageView.accessibilityIgnoresInvertColors = true
        imageView.contentMode = .scaleAspectFit
        
        addSubview(imageView)
        
        return imageView
    } ()

    let image: UIImage
    
    
    public init(image: UIImage) {
        self.image = image
        super.init(frame: .zero)
        imageView.image = image

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
    
}
