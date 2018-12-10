//
//  ProgressBar.swift
//  BitbonSpace
//
//  Created by Гранченко Юрий on 12/10/18.
//  Copyright © 2018 Simcord. All rights reserved.
//

import Foundation

class ProgressBar: UIView {
    
    override final class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
    
    private var animation = CABasicAnimation(keyPath: "strokeEnd")
    
    @IBInspectable var lineWidth: CGFloat = 10
    
    var renderedSize: CGSize = CGSize.zero
    
    private var _progress: CGFloat = 0
    var progress: CGFloat {
        set {
            setProgress(progress: newValue, animated: false)
        }
        get { return _progress }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        clipsToBounds = true
        guard let layer = layer as? CAShapeLayer else { return }
        layer.masksToBounds = true
        layer.rasterizationScale = UIScreen.main.scale
        layer.shouldRasterize = true
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.blue.cgColor
        layer.strokeStart = 0.0
        layer.strokeEnd = 0.0
        layer.lineCap = CAShapeLayerLineCap.round
        layer.lineJoin = CAShapeLayerLineJoin.round
        layer.shadowRadius = 4.0
        layer.shadowOpacity = 0.9
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowColor = UIColor.cyan.cgColor
        updatePath()
        layer.actions = ["strokeEnd":NSNull()]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePathIfNeeded()
    }
    
    private func updatePathIfNeeded() {
        if renderedSize != bounds.size {
            updatePath()
        }
    }
    
    private func updatePath() {
        guard let layer = layer as? CAShapeLayer else { return }
        let size = bounds.size
        let path = UIBezierPath()
        if size.width > size.height {
            layer.lineWidth = self.lineWidth > 0 ? self.lineWidth : 4
            path.move(layer.lineWidth ^ size.height/2.0).line(size.width - layer.lineWidth ^ size.height/2.0)
        } else {
            layer.lineWidth = 2
            path.addArc(withCenter: size.width/2.0 ^ size.height/2.0,
                        radius: size.width/2 - 1,
                        startAngle: -CGFloat(Double.pi/2),
                        endAngle: CGFloat(3 * (Double.pi/2)),
                        clockwise: true)
        }
        layer.path = path.cgPath
        renderedSize = size
    }
    
    func setProgress(progress: CGFloat, animated: Bool) {
        let progress = max(0, min(1, progress))
        if (_progress != progress) {
            _progress = progress
            updateProgress(animated: animated)
        }
    }
    
    private static let animationKey = "strokeAnimation"
    
    func updateProgress(animated: Bool) {
        guard let layer = layer as? CAShapeLayer else { return }
        if animated {
            let fromValue = layer.presentation()?.strokeEnd ?? 0
            animation.duration = CFTimeInterval(abs(_progress - fromValue))
            animation.fromValue = fromValue
            animation.toValue = _progress
            layer.removeAnimation(forKey: ProgressBar.animationKey)
            layer.strokeEnd = _progress
            layer.add(animation, forKey: ProgressBar.animationKey)
        } else {
            layer.removeAnimation(forKey: ProgressBar.animationKey)
            layer.strokeEnd = _progress
        }
    }
    
    func uploadProgress() -> ((Progress) -> Void) {
        return { [weak self] progress in
            let completed = CGFloat(progress.completedUnitCount)
            let total = CGFloat(progress.totalUnitCount)
            let value = 0.45 * completed/total
            self?.setProgress(progress: 0.1 + value, animated: true)
        }
    }
    
    func downloadProgress() -> ((Progress) -> Void) {
        return { [weak self] progress in
            let completed = CGFloat(progress.completedUnitCount)
            let total = CGFloat(progress.totalUnitCount)
            let value = 0.45 + 0.45 * completed/total
            self?.setProgress(progress: 0.1 + value, animated: true)
        }
    }
}
