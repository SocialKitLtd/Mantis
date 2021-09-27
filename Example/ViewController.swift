//
//  ViewController.swift
//  Mantis
//
//  Created by Echo on 10/19/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit
import Mantis
var image = UIImage(named: "Rectangle.png")

class ViewController: UIViewController, CropViewControllerDelegate {
    
    @IBOutlet weak var croppedImageView: UIImageView!
    
   
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
   
    
    @IBAction func normalPresent(_ sender: Any) {
        
        let vc = VC()
        
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
        
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
   

    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation) {
        print(transformation);
        croppedImageView.image = cropped
        self.dismiss(animated: true)
    }
    
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
        self.dismiss(animated: true)
    }
}


class VC: UIViewController {
    
    lazy var proxyView: ProxyView = {
        return ProxyView(target: cropViewController.targetCropView)
    }()
    let cropViewController = Mantis.cropViewController(image: image!,
                                                       config: Mantis.Config())
    let container = UIView()
    
    let ratio: CGFloat = 1
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(proxyView)
        view.addSubview(container)
        container.backgroundColor = .red
        view.backgroundColor = .blue
        
        cropViewController.view.alpha = 0.4
        cropViewController.view.clipsToBounds = false
        container.clipsToBounds = false
        cropViewController.addAsChildTo(parentVc: self, inside: container)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        proxyView.frame = view.bounds
        container.bounds.size.width = 100
        container.bounds.size.height = 100 * ratio
        
        
        container.center = view.center
    
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
