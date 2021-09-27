//
//  CropView.swift
//  Mantis
//
//  Created by Echo on 10/20/18.
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

protocol CropViewDelegate: AnyObject {
    func cropViewDidBecomeResettable(_ cropView: CropView)
    func cropViewDidBecomeUnResettable(_ cropView: CropView)
    func cropViewDidBeginResize(_ cropView: CropView)
    func cropViewDidEndResize(_ cropView: CropView)
}

let cropViewMinimumBoxSize: CGFloat = 42
let minimumAspectRatio: CGFloat = 0
let hotAreaUnit: CGFloat = 32
let cropViewPadding:CGFloat = 3

class CropView: UIView {
    var cropVisualEffectType: CropVisualEffectType = .blurDark
    
    var image: UIImage {
        didSet {
            imageContainer.image = image
        }
    }
    let viewModel: CropViewModel
    
    weak var delegate: CropViewDelegate? {
        didSet {
            checkImageStatusChanged()
        }
    }
    
    var aspectRatioLockEnabled = false

    // Referred to in extension
    let imageContainer: ImageContainer
    let gridOverlayView: CropOverlayView

    lazy var scrollView = CropScrollView(frame: bounds)
    lazy var cropMaskViewManager = CropMaskViewManager(with: self,
                                                       cropRatio: CGFloat(getImageRatioH()),
                                                       cropVisualEffectType: cropVisualEffectType)

    var manualZoomed = false
    private var cropFrameKVO: NSKeyValueObservation?
    var forceFixedRatio = false
    var imageStatusChangedCheckForForceFixedRatio = false
    
    deinit {
        print("CropView deinit.")
    }
    
    init(image: UIImage, viewModel: CropViewModel = CropViewModel()) {
        self.image = image
        self.viewModel = viewModel
        
        imageContainer = ImageContainer()
        gridOverlayView = CropOverlayView()

        super.init(frame: CGRect.zero)
        
        self.viewModel.statusChanged = { [weak self] status in
            self?.render(by: status)
        }
        
        cropFrameKVO = viewModel.observe(\.cropBoxFrame,
                                         options: [.new, .old])
        { [unowned self] _, changed in
            guard let cropFrame = changed.newValue else { return }
            self.gridOverlayView.frame = cropFrame
            
            var cropRatio: CGFloat = 1.0
            if self.gridOverlayView.frame.height != 0 {
                cropRatio = self.gridOverlayView.frame.width / self.gridOverlayView.frame.height
            }
            
            self.cropMaskViewManager.adaptMaskTo(match: cropFrame, cropRatio: cropRatio)
        }
        
        initalRender()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initalRender() {
        setupUI()
        checkImageStatusChanged()
    }
    
    private func render(by viewStatus: CropViewStatus) {
        gridOverlayView.isHidden = false
        
        switch viewStatus {
        case .initial:
            initalRender()
        case .degree90Rotating:
            cropMaskViewManager.showVisualEffectBackground()
            gridOverlayView.isHidden = true
        case .touchImage:
            cropMaskViewManager.showDimmingBackground()
            gridOverlayView.gridLineNumberType = .crop
            gridOverlayView.setGrid(hidden: false, animated: true)
        case .touchCropboxHandle(let tappedEdge):
            gridOverlayView.handleEdgeTouched(with: tappedEdge)
            cropMaskViewManager.showDimmingBackground()
        case .touchRotationBoard:
            gridOverlayView.gridLineNumberType = .rotate
            gridOverlayView.setGrid(hidden: false, animated: true)
            cropMaskViewManager.showDimmingBackground()
        case .betweenOperation:
            gridOverlayView.handleEdgeUntouched()
            cropMaskViewManager.showVisualEffectBackground()
            checkImageStatusChanged()
        }
    }
    
    private func isTheSamePoint(p1: CGPoint, p2: CGPoint) -> Bool {
        let tolerance = CGFloat.ulpOfOne * 10
        if abs(p1.x - p2.x) > tolerance { return false }
        if abs(p1.y - p2.y) > tolerance { return false }
        
        return true
    }
    
    private func imageStatusChanged() -> Bool {
        if viewModel.getTotalRadians() != 0 { return true }
        
        if (forceFixedRatio) {
            if imageStatusChangedCheckForForceFixedRatio {
                imageStatusChangedCheckForForceFixedRatio = false
                return scrollView.zoomScale != 1
            }
        }
        
        if !isTheSamePoint(p1: getImageLeftTopAnchorPoint(), p2: .zero) {
            return true
        }
        
        if !isTheSamePoint(p1: getImageRightBottomAnchorPoint(), p2: CGPoint(x: 1, y: 1)) {
            return true
        }
        
        return false
    }
    
    private func checkImageStatusChanged() {
        if imageStatusChanged() {
            delegate?.cropViewDidBecomeResettable(self)
        } else {
            delegate?.cropViewDidBecomeUnResettable(self)
        }
    }
    
    private func setupUI() {
        setupScrollView()
        imageContainer.image = image
        
        scrollView.addSubview(imageContainer)
        scrollView.imageContainer = imageContainer
        
        setGridOverlayView()
    }
    
    func resetUIFrame() {
        cropMaskViewManager.removeMaskViews()
        cropMaskViewManager.setup(in: self, cropRatio: CGFloat(getImageRatioH()))
        viewModel.resetCropFrame(by: getInitialCropBoxRect())
                
        scrollView.transform = .identity
        scrollView.resetBy(rect: viewModel.cropBoxFrame)
        
        imageContainer.frame = scrollView.bounds
        imageContainer.center = CGPoint(x: scrollView.bounds.width/2, y: scrollView.bounds.height/2)

        gridOverlayView.superview?.bringSubviewToFront(gridOverlayView)
        
        
        if aspectRatioLockEnabled {
            setFixedRatioCropBox()
        }
    }
    
    func adaptForCropBox() {
        resetUIFrame()
    }
    
    private func setupScrollView() {
        scrollView.touchesBegan = { [weak self] in
            self?.viewModel.setTouchImageStatus()
        }
        
        scrollView.touchesEnded = { [weak self] in
            self?.viewModel.setBetweenOperationStatus()
        }
        
        scrollView.delegate = self
        addSubview(scrollView)
    }
    
    private func setGridOverlayView() {
        gridOverlayView.isUserInteractionEnabled = false
        gridOverlayView.gridHidden = true
        addSubview(gridOverlayView)
    }
    
    

    func updateCropBoxFrame(with point: CGPoint) {
        let contentFrame = getContentBounds()
        let newCropBoxFrame = viewModel.getNewCropBoxFrame(with: point, and: contentFrame, aspectRatioLockEnabled: aspectRatioLockEnabled)
        
        let contentBounds = getContentBounds()
        
        guard newCropBoxFrame.width >= cropViewMinimumBoxSize
                && newCropBoxFrame.minX >= contentBounds.minX
                && newCropBoxFrame.maxX <= contentBounds.maxX
                && newCropBoxFrame.height >= cropViewMinimumBoxSize
                && newCropBoxFrame.minY >= contentBounds.minY
                && newCropBoxFrame.maxY <= contentBounds.maxY else {
            return
        }
        
        if imageContainer.contains(rect: newCropBoxFrame, fromView: self) {
            viewModel.cropBoxFrame = newCropBoxFrame
        } else {
            let minX = max(viewModel.cropBoxFrame.minX, newCropBoxFrame.minX)
            let minY = max(viewModel.cropBoxFrame.minY, newCropBoxFrame.minY)
            let maxX = min(viewModel.cropBoxFrame.maxX, newCropBoxFrame.maxX)
            let maxY = min(viewModel.cropBoxFrame.maxY, newCropBoxFrame.maxY)

            var rect: CGRect
            
            rect = CGRect(x: minX, y: minY, width: newCropBoxFrame.width, height: maxY - minY)
            if imageContainer.contains(rect: rect, fromView: self) {
                viewModel.cropBoxFrame = rect
                return
            }
            
            rect = CGRect(x: minX, y: minY, width: maxX - minX, height: newCropBoxFrame.height)
            if imageContainer.contains(rect: rect, fromView: self) {
                viewModel.cropBoxFrame = rect
                return
            }
            
            rect = CGRect(x: newCropBoxFrame.minX, y: minY, width: newCropBoxFrame.width, height: maxY - minY)
            if imageContainer.contains(rect: rect, fromView: self) {
                viewModel.cropBoxFrame = rect
                return
            }

            rect = CGRect(x: minX, y: newCropBoxFrame.minY, width: maxX - minX, height: newCropBoxFrame.height)
            if imageContainer.contains(rect: rect, fromView: self) {
                viewModel.cropBoxFrame = rect
                return
            }
                                                
            viewModel.cropBoxFrame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
    }    
}


// MARK: - Adjust UI
extension CropView {
    private func rotateScrollView() {
        let totalRadians = forceFixedRatio ? viewModel.radians : viewModel.getTotalRadians()
        
        self.scrollView.transform = CGAffineTransform(rotationAngle: totalRadians)
        self.updatePosition(by: totalRadians)
    }
    
    private func getInitialCropBoxRect() -> CGRect {
        guard image.size.width > 0 && image.size.height > 0 else {
            return .zero
        }
        
        let outsideRect = getContentBounds()
        
        let insideRect: CGRect
        
        if viewModel.isUpOrUpsideDown() {
            insideRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        } else {
            insideRect = CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width)
        }
        
        return GeometryHelper.getInscribeRect(fromOutsideRect: outsideRect, andInsideRect: insideRect)
    }
    
    func getContentBounds() -> CGRect {
        let rect = self.bounds
        var contentRect = CGRect.zero
        
        if Orientation.isPortrait {
            contentRect.origin.x = rect.origin.x + cropViewPadding
            contentRect.origin.y = rect.origin.y + cropViewPadding
            
            contentRect.size.width = rect.width - 2 * cropViewPadding
            contentRect.size.height = rect.height - 2 * cropViewPadding
        } else if Orientation.isLandscape {
            contentRect.size.width = rect.width - 2 * cropViewPadding
            contentRect.size.height = rect.height - 2 * cropViewPadding
            
            contentRect.origin.y = rect.origin.y + cropViewPadding
            if Orientation.isLandscapeLeft {
                contentRect.origin.x = rect.origin.x + cropViewPadding
            } else {
                contentRect.origin.x = rect.origin.x + cropViewPadding
            }
        }
        
        return contentRect
    }
    
    fileprivate func getImageLeftTopAnchorPoint() -> CGPoint {
        if imageContainer.bounds.size == .zero {
            return viewModel.cropLeftTopOnImage
        }
        
        let lt = gridOverlayView.convert(CGPoint(x: 0, y: 0), to: imageContainer)
        let point = CGPoint(x: lt.x / imageContainer.bounds.width, y: lt.y / imageContainer.bounds.height)
        return point
    }
    
    fileprivate func getImageRightBottomAnchorPoint() -> CGPoint {
        if imageContainer.bounds.size == .zero {
            return viewModel.cropRightBottomOnImage
        }
        
        let rb = gridOverlayView.convert(CGPoint(x: gridOverlayView.bounds.width, y: gridOverlayView.bounds.height), to: imageContainer)
        let point = CGPoint(x: rb.x / imageContainer.bounds.width, y: rb.y / imageContainer.bounds.height)
        return point
    }
    
    fileprivate func saveAnchorPoints() {
        viewModel.cropLeftTopOnImage = getImageLeftTopAnchorPoint()
        viewModel.cropRightBottomOnImage = getImageRightBottomAnchorPoint()
    }
    
    func adjustUIForNewCrop(contentRect:CGRect,
                            animation: Bool = true,
                            zoom: Bool = true,
                            completion: @escaping ()->Void) {
        
        let scaleX: CGFloat
        let scaleY: CGFloat
        
        scaleX = contentRect.width / viewModel.cropBoxFrame.size.width
        scaleY = contentRect.height / viewModel.cropBoxFrame.size.height
        
        let scale = min(scaleX, scaleY)
        
        let newCropBounds = CGRect(x: 0, y: 0, width: viewModel.cropBoxFrame.width * scale, height: viewModel.cropBoxFrame.height * scale)
        
        let radians = forceFixedRatio ? viewModel.radians : viewModel.getTotalRadians()
        
        // calculate the new bounds of scroll view
        let newBoundWidth = abs(cos(radians)) * newCropBounds.size.width + abs(sin(radians)) * newCropBounds.size.height
        let newBoundHeight = abs(sin(radians)) * newCropBounds.size.width + abs(cos(radians)) * newCropBounds.size.height
        
        // calculate the zoom area of scroll view
        var scaleFrame = viewModel.cropBoxFrame
        
        let refContentWidth = abs(cos(radians)) * scrollView.contentSize.width + abs(sin(radians)) * scrollView.contentSize.height
        let refContentHeight = abs(sin(radians)) * scrollView.contentSize.width + abs(cos(radians)) * scrollView.contentSize.height
        
        if scaleFrame.width >= refContentWidth {
            scaleFrame.size.width = refContentWidth
        }
        if scaleFrame.height >= refContentHeight {
            scaleFrame.size.height = refContentHeight
        }
        
        let contentOffset = scrollView.contentOffset
        let contentOffsetCenter = CGPoint(x: (contentOffset.x + scrollView.bounds.width / 2),
                                          y: (contentOffset.y + scrollView.bounds.height / 2))
        
        
        scrollView.bounds = CGRect(x: 0, y: 0, width: newBoundWidth, height: newBoundHeight)
        
        let newContentOffset = CGPoint(x: (contentOffsetCenter.x - newBoundWidth / 2),
                                       y: (contentOffsetCenter.y - newBoundHeight / 2))
        scrollView.contentOffset = newContentOffset
        
        let newCropBoxFrame = GeometryHelper.getInscribeRect(fromOutsideRect: contentRect, andInsideRect: viewModel.cropBoxFrame)
        
        func updateUI(by newCropBoxFrame: CGRect, and scaleFrame: CGRect) {
            viewModel.cropBoxFrame = newCropBoxFrame
            
            if zoom {
                let zoomRect = convert(scaleFrame,
                                            to: scrollView.imageContainer)
                scrollView.zoom(to: zoomRect, animated: false)
            }
            scrollView.checkContentOffset()
            makeSureImageContainsCropOverlay()
        }
        
        if animation {
            UIView.animate(withDuration: 0.25, animations: {
                updateUI(by: newCropBoxFrame, and: scaleFrame)
            }) {_ in
                completion()
            }
        } else {
            updateUI(by: newCropBoxFrame, and: scaleFrame)
            completion()
        }
                
        manualZoomed = true
    }
    
    func makeSureImageContainsCropOverlay() {
        if !imageContainer.contains(rect: gridOverlayView.frame, fromView: self, tolerance: 0.25) {
            scrollView.zoomScaleToBound(animated: true)
        }
    }
    
    fileprivate func updatePosition(by radians: CGFloat) {
        let width = abs(cos(radians)) * gridOverlayView.frame.width + abs(sin(radians)) * gridOverlayView.frame.height
        let height = abs(sin(radians)) * gridOverlayView.frame.width + abs(cos(radians)) * gridOverlayView.frame.height
        
        scrollView.updateLayout(byNewSize: CGSize(width: width, height: height))
        
        if !manualZoomed || scrollView.shouldScale() {
            scrollView.zoomScaleToBound()
            manualZoomed = false
        } else {
            scrollView.updateMinZoomScale()
        }
        
        scrollView.checkContentOffset()
    }
    
    fileprivate func updatePositionFor90Rotation(by radians: CGFloat) {
                
        func adjustScrollViewForNormalRatio(by radians: CGFloat) -> CGFloat {
            let width = abs(cos(radians)) * gridOverlayView.frame.width + abs(sin(radians)) * gridOverlayView.frame.height
            let height = abs(sin(radians)) * gridOverlayView.frame.width + abs(cos(radians)) * gridOverlayView.frame.height

            let newSize: CGSize
            if viewModel.rotationType == .none || viewModel.rotationType == .counterclockwise180 {
                newSize = CGSize(width: width, height: height)
            } else {
                newSize = CGSize(width: height, height: width)
            }

            let scale = newSize.width / scrollView.bounds.width
            scrollView.updateLayout(byNewSize: newSize)
            return scale
        }
        
        let scale = adjustScrollViewForNormalRatio(by: radians)
                        
        let newZoomScale = scrollView.zoomScale * scale
        scrollView.minimumZoomScale = newZoomScale
        scrollView.zoomScale = newZoomScale
        
        scrollView.checkContentOffset()
    }    
}

// MARK: - internal API
extension CropView {
    func crop(_ image: UIImage) -> (croppedImage: UIImage?, transformation: Transformation) {

        let info = getCropInfo()
        
        let transformation = Transformation(
            offset: scrollView.contentOffset,
            rotation: getTotalRadians(),
            scale: scrollView.zoomScale,
            manualZoomed: manualZoomed,
            intialMaskFrame: getInitialCropBoxRect(),
            maskFrame: gridOverlayView.frame,
            scrollBounds: scrollView.bounds
        )
        
        guard let croppedImage = image.getCroppedImage(byCropInfo: info) else {
            return (nil, transformation)
        }
        
 
        return (croppedImage, transformation)
     
    }
    
    func getCropInfo() -> CropInfo {
        
        let rect = imageContainer.convert(imageContainer.bounds,
                                          to: self)
        let point = rect.center
        let zeroPoint = gridOverlayView.center
        
        let translation =  CGPoint(x: (point.x - zeroPoint.x), y: (point.y - zeroPoint.y))
                
        return CropInfo(
            translation: translation,
            rotation: getTotalRadians(),
            scale: scrollView.zoomScale,
            cropSize: gridOverlayView.frame.size,
            imageViewSize: imageContainer.bounds.size
        )
        
    }
    
    func getTotalRadians() -> CGFloat {
        return forceFixedRatio ? viewModel.radians : viewModel.getTotalRadians()
    }
    
    func crop() -> (croppedImage: UIImage?, transformation: Transformation) {
        return crop(image)
    }
        
    func handleRotate() {
        viewModel.resetCropFrame(by: getInitialCropBoxRect())
        
        scrollView.transform = .identity
        scrollView.resetBy(rect: viewModel.cropBoxFrame)
        
        rotateScrollView()
        
        if viewModel.cropRightBottomOnImage != .zero {
            var lt = CGPoint(x: viewModel.cropLeftTopOnImage.x * imageContainer.bounds.width, y: viewModel.cropLeftTopOnImage.y * imageContainer.bounds.height)
            var rb = CGPoint(x: viewModel.cropRightBottomOnImage.x * imageContainer.bounds.width, y: viewModel.cropRightBottomOnImage.y * imageContainer.bounds.height)
            
            lt = imageContainer.convert(lt, to: self)
            rb = imageContainer.convert(rb, to: self)
            
            let rect = CGRect(origin: lt, size: CGSize(width: rb.x - lt.x, height: rb.y - lt.y))
            viewModel.cropBoxFrame = rect
            
            let contentRect = getContentBounds()
            
            adjustUIForNewCrop(contentRect: contentRect) { [weak self] in
                self?.viewModel.setBetweenOperationStatus()
            }
        }
    }
    
    func rotateBy90(rotateAngle: CGFloat, completion: @escaping ()->Void = {}) {
        viewModel.setDegree90RotatingStatus()
        let rorateDuration = 0.25
        
        if forceFixedRatio {
          
            
            UIView.animate(withDuration: rorateDuration, animations: {
            }) {[weak self] _ in
                guard let self = self else { return }
                self.viewModel.rotateBy90(rotateAngle: rotateAngle)
                self.viewModel.setBetweenOperationStatus()
                completion()
            }
            
            return
        }
        
        var rect = gridOverlayView.frame        
        rect.size.width = gridOverlayView.frame.height
        rect.size.height = gridOverlayView.frame.width
        
        let newRect = GeometryHelper.getInscribeRect(fromOutsideRect: getContentBounds(), andInsideRect: rect)
        
        let radian = rotateAngle
        let transfrom = scrollView.transform.rotated(by: radian)
        
        UIView.animate(withDuration: rorateDuration, animations: {
            self.viewModel.cropBoxFrame = newRect
            self.scrollView.transform = transfrom
            self.updatePositionFor90Rotation(by: radian + self.viewModel.radians)
        }) {[weak self] _ in
            guard let self = self else { return }
            self.scrollView.updateMinZoomScale()
            self.viewModel.rotateBy90(rotateAngle: rotateAngle)
            self.viewModel.setBetweenOperationStatus()
            completion()
        }
    }
    
    func reset() {
        scrollView.removeFromSuperview()
        gridOverlayView.removeFromSuperview()
        
        if forceFixedRatio {
            aspectRatioLockEnabled = true
        } else {
            aspectRatioLockEnabled = false
        }
        
        viewModel.reset(forceFixedRatio: forceFixedRatio)
        resetUIFrame()
        delegate?.cropViewDidBecomeUnResettable(self)
    }
    
    func prepareForDeviceRotation() {
        viewModel.setDegree90RotatingStatus()
        saveAnchorPoints()
    }
    

    func setFixedRatioCropBox(zoom: Bool = true, cropBox: CGRect? = nil) {
        let refCropBox = cropBox ?? getInitialCropBoxRect()
        viewModel.setCropBoxFrame(by: refCropBox, and: getImageRatioH())
        
        let contentRect = getContentBounds()
        adjustUIForNewCrop(contentRect: contentRect, animation: false, zoom: zoom) { [weak self] in
            guard let self = self else { return }
            if self.forceFixedRatio {
                self.imageStatusChangedCheckForForceFixedRatio = true
            }
            self.viewModel.setBetweenOperationStatus()
        }
        
        scrollView.updateMinZoomScale()
    }
    
    
    func getImageRatioH() -> Double {
        if viewModel.rotationType == .none || viewModel.rotationType == .counterclockwise180 {
            return Double(image.ratioH())
        } else {
            return Double(1/image.ratioH())
        }
    }
    
    func transform(byTransformInfo transformation: Transformation, rotateDial: Bool = true) {

        if (transformation.scrollBounds != .zero) {
            scrollView.bounds = transformation.scrollBounds
        }

        manualZoomed = transformation.manualZoomed
        scrollView.zoomScale = transformation.scale
        scrollView.contentOffset = transformation.offset
        viewModel.setBetweenOperationStatus()
        
        if (transformation.maskFrame != .zero) {
            viewModel.cropBoxFrame = transformation.maskFrame
        }

        
    }
}
