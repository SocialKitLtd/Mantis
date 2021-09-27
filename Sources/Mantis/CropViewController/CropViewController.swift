//
//  CropViewController.swift
//  Mantis
//
//  Created by Echo on 10/30/18.
//  Copyright © 2018 Echo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

public protocol CropViewControllerDelegate: AnyObject {
    func cropViewControllerDidCrop(_ cropViewController: CropViewController,
                                   cropped: UIImage, transformation: Transformation)
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController)
    func cropViewControllerDidCancel(_ cropViewController: CropViewController)
    
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController)
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, cropInfo: CropInfo)    
}

public extension CropViewControllerDelegate where Self: UIViewController {
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController) {}
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {}
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, cropInfo: CropInfo) {}   
}

public class CropViewController: UIViewController {
    /// When a CropViewController is used in a storyboard,
    /// passing an image to it is needed after the CropViewController is created.
//    public var image: UIImage! {
//        didSet {
//            cropView.image = image
//        }
//    }
//
    
    
    
    
    public weak var delegate: CropViewControllerDelegate?
    public var config = Mantis.Config()
    
    let cropView: CropView
    private var initialLayout = false
    
    deinit {
        print("CropViewController deinit.")
    }
    
    public var targetCropView: UIView {
        return cropView.scrollView
    }
    
    public init(embeddableView: EmbeddableView,
         config: Mantis.Config = Mantis.Config()) {
        
        self.cropView = .init(embeddableView: embeddableView, viewModel: CropViewModel())
        
        self.config = config

        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
        super.init(coder: aDecoder)
        
    }
    
 
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        createCropView()
     
        initLayout()
        
        cropView.clipsToBounds = false
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initialLayout == false {
            initialLayout = true
            view.layoutIfNeeded()
            cropView.adaptForCropBox()
        }
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.top, .bottom]
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        cropView.prepareForDeviceRotation()
    }    
    

    private func setFixedRatio(_ ratio: Double, zoom: Bool = true) {
        cropView.aspectRatioLockEnabled = true
        
        if (cropView.viewModel.aspectRatio != CGFloat(ratio)) {
            cropView.viewModel.aspectRatio = CGFloat(ratio)
//
//            if case .alwaysUsingOnePresetFixedRatio = config.presetFixedRatioType {
//                self.cropView.setFixedRatioCropBox(zoom: zoom)
//            } else {
//                UIView.animate(withDuration: 0.5) {
//                    self.cropView.setFixedRatioCropBox(zoom: zoom)
//                }
//            }
            
        }
    }
    
    private func createCropView() {
       
        cropView.delegate = self
        cropView.clipsToBounds = true
        cropView.cropVisualEffectType = config.cropVisualEffectType
        

    }
    
    private func processPresetTransformation(completion: (Transformation)->Void) {
        if case .presetInfo(let transformInfo) = config.presetTransformationType {
            var newTransform = getTransformInfo(byTransformInfo: transformInfo)
            
            // The first transform is just for retrieving the final cropBoxFrame
            cropView.transform(byTransformInfo: newTransform, rotateDial: false)
            
            // The second transform is for adjusting the scale of transformInfo
            let adjustScale = (cropView.viewModel.cropBoxFrame.width / cropView.viewModel.cropOrignFrame.width) / (transformInfo.maskFrame.width / transformInfo.intialMaskFrame.width)
            newTransform.scale *= adjustScale
            cropView.transform(byTransformInfo: newTransform)
            completion(transformInfo)
        } else if case .presetNormalizedInfo(let normailizedInfo) = config.presetTransformationType {
            let transformInfo = getTransformInfo(byNormalizedInfo: normailizedInfo);
            cropView.transform(byTransformInfo: transformInfo)
            cropView.scrollView.frame = transformInfo.maskFrame
            completion(transformInfo)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        processPresetTransformation() { [weak self] transform in
//            guard let self = self else { return }
//            if case .alwaysUsingOnePresetFixedRatio(let ratio) = self.config.presetFixedRatioType {
//                self.cropView.aspectRatioLockEnabled = true
//                
//                if ratio == 0 {
//                    self.cropView.viewModel.aspectRatio = transform.maskFrame.width / transform.maskFrame.height
//                } else {
//                    self.cropView.viewModel.aspectRatio = CGFloat(ratio)
//                    self.cropView.setFixedRatioCropBox(zoom: false, cropBox: cropView.viewModel.cropBoxFrame)
//                }
//            }
//        }
    }
    
    private func getTransformInfo(byTransformInfo transformInfo: Transformation) -> Transformation {
        let cropFrame = cropView.viewModel.cropOrignFrame
        let contentBound = cropView.getContentBounds()
        
        let adjustScale: CGFloat
        var maskFrameWidth: CGFloat
        var maskFrameHeight: CGFloat
        
        if ( transformInfo.maskFrame.height / transformInfo.maskFrame.width >= contentBound.height / contentBound.width ) {
            maskFrameHeight = contentBound.height
            maskFrameWidth = transformInfo.maskFrame.width / transformInfo.maskFrame.height * maskFrameHeight
            adjustScale = maskFrameHeight / transformInfo.maskFrame.height
        } else {
            maskFrameWidth = contentBound.width
            maskFrameHeight = transformInfo.maskFrame.height / transformInfo.maskFrame.width * maskFrameWidth
            adjustScale = maskFrameWidth / transformInfo.maskFrame.width
        }
        
        var newTransform = transformInfo
        
        newTransform.offset = CGPoint(x:transformInfo.offset.x * adjustScale,
                                      y:transformInfo.offset.y * adjustScale)
        
        newTransform.maskFrame = CGRect(x: cropFrame.origin.x + (cropFrame.width - maskFrameWidth) / 2,
                                        y: cropFrame.origin.y + (cropFrame.height - maskFrameHeight) / 2,
                                        width: maskFrameWidth,
                                        height: maskFrameHeight)
        newTransform.scrollBounds = CGRect(x: transformInfo.scrollBounds.origin.x * adjustScale,
                                           y: transformInfo.scrollBounds.origin.y * adjustScale,
                                           width: transformInfo.scrollBounds.width * adjustScale,
                                           height: transformInfo.scrollBounds.height * adjustScale)
        
        return newTransform
    }
    
    private func getTransformInfo(byNormalizedInfo normailizedInfo: CGRect) -> Transformation {
        let cropFrame = cropView.viewModel.cropBoxFrame
        
        let scale: CGFloat = min(1/normailizedInfo.width, 1/normailizedInfo.height)
        
        var offset = cropFrame.origin
        offset.x = cropFrame.width * normailizedInfo.origin.x * scale
        offset.y = cropFrame.height * normailizedInfo.origin.y * scale
        
        var maskFrame = cropFrame
        
        if (normailizedInfo.width > normailizedInfo.height) {
            let adjustScale = 1 / normailizedInfo.width
            maskFrame.size.height = normailizedInfo.height * cropFrame.height * adjustScale
            maskFrame.origin.y += (cropFrame.height - maskFrame.height) / 2
        } else if (normailizedInfo.width < normailizedInfo.height) {
            let adjustScale = 1 / normailizedInfo.height
            maskFrame.size.width = normailizedInfo.width * cropFrame.width * adjustScale
            maskFrame.origin.x += (cropFrame.width - maskFrame.width) / 2
        }
        
        let manualZoomed = (scale != 1.0)
        let transformantion = Transformation(offset: offset,
                                             rotation: 0,
                                             scale: scale,
                                             manualZoomed: manualZoomed,
                                             intialMaskFrame: .zero,
                                             maskFrame: maskFrame,
                                             scrollBounds: .zero)
        return transformantion
    }
    
    private func handleCancel() {
        self.delegate?.cropViewControllerDidCancel(self)
    }
    
    private func resetRatioButton() {
        cropView.aspectRatioLockEnabled = false
    }
    

    
    private func handleReset() {
        resetRatioButton()
        cropView.reset()
    }
    
    private func handleAlterCropper90Degree() {
        let ratio = Double(cropView.gridOverlayView.frame.height / cropView.gridOverlayView.frame.width)
        
        cropView.viewModel.aspectRatio = CGFloat(ratio)
        
        UIView.animate(withDuration: 0.5) {
            self.cropView.setFixedRatioCropBox()
        }
    }
    

}

// Auto layout
extension CropViewController {
    fileprivate func initLayout() {

        view.addSubview(cropView)
        cropView.translatesAutoresizingMaskIntoConstraints = false
        
        cropView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        cropView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        cropView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        cropView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
    }
    
  
}

extension CropViewController: CropViewDelegate {
    
    func cropViewDidBecomeResettable(_ cropView: CropView) {
    }
    
    func cropViewDidBecomeUnResettable(_ cropView: CropView) {
    }
    
    func cropViewDidBeginResize(_ cropView: CropView) {
        delegate?.cropViewControllerDidBeginResize(self)
    }
    
    func cropViewDidEndResize(_ cropView: CropView) {
        delegate?.cropViewControllerDidEndResize(self, cropInfo: cropView.getCropInfo())
    }
}
