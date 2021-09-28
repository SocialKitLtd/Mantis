//
//  ViewController.swift
//  Mantis
//
//  Created by Echo on 10/19/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit
import Mantis
import AVFoundation
var image = UIImage(named: "Rectangle.png")

class ViewController: UIViewController, CropViewControllerDelegate {
    
    @IBOutlet weak var croppedImageView: UIImageView!
    
   
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
   
    
    @IBAction func normalPresent(_ sender: Any) {
        
        let vc = VC()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)

       
    }
    
    @IBAction func presentWithPresetTransformation(_ sender: Any) {
        guard let image = image else {
            return
        }
        
        var config = Mantis.Config()
        
        
        let transform = Transformation(offset: CGPoint(x: 231.66666666666666, y: 439.6666666666667),
                                       rotation: 0.5929909348487854,
                                       scale: 2.841958076098717,
                                       manualZoomed: true,
                                       intialMaskFrame: CGRect(x: 14.0, y: 62.25, width: 347.0, height: 520.5),
                                       maskFrame: CGRect(x: 59.47694524495677, y: 14.0, width: 256.04610951008647, height: 617.0),
                                       scrollBounds: CGRect(x: 231.66666666666666, y: 439.6666666666667, width: 557.1387432741491, height: 654.7511809035641))
        
        
        config.presetTransformationType = .presetInfo(info: transform)
        
//        let cropViewController = Mantis.cropViewController(image: image,
//                                                           config: config)
//        cropViewController.modalPresentationStyle = .fullScreen
//        cropViewController.delegate = self
//        present(cropViewController, animated: true)
    }
    
   

    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation) {
        print(transformation);
        croppedImageView.image = cropped
        self.dismiss(animated: true)
    }
    
    func cropViewControllerDidCancel(_ cropViewController: CropViewController) {
        self.dismiss(animated: true)
    }
}




public extension UIViewController {
    func addAsChildTo(parentVc: UIViewController, inside container: UIView, offset: CGPoint = .zero) {
        parentVc.addChild(self)
        self.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(self.view)
        
        view.bindFrameToSuperviewBounds(offset: offset)
        didMove(toParent: parentVc)
    }
    
    func removeChildViewController() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
    func addAsSafeAreaChildTo(parentVc: UIViewController, inside container: UIView) {
          parentVc.addChild(self)
          self.view.translatesAutoresizingMaskIntoConstraints = false
          container.addSubview(self.view)
          
          view.bindMarginsToSuperviewWithBottomSafeArea()
          didMove(toParent: parentVc)
      }
    
}

extension PlayerView: EmbeddableView {
  
    public var representableSize: CGSize {
        return .init(width: 1080, height: 1920)
    }
    
    public var ratio: CGFloat {
        return 1080.0 / 1920.0
    }
    
    
}
