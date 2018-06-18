//
//  PopupView.swift
//  CustomViews
//
//  Created by Yura Granchenko on 6/18/18.
//  Copyright © 2018 Yura Granchenko. All rights reserved.
//

import Foundation
import SnapKit
import RxGesture
import RxSwift
import RxCocoa

enum Position {
    case top, bottom
}

let popupWidth = IS_iPAD ? UIScreen.main.bounds.size.width/2 : UIScreen.main.bounds.size.width - 20

protocol TextRepresentable {
    var representingText: String { get set }
}

class PopupView<T: UIView & TextRepresentable>: UIView {
    internal let contentView = UIView()
    var containerView = T()
    let triangleView = TriangleView()
    var selectedItemBlock: ((String) -> Void)?
    internal var successBlock: Block?
    internal var cancelBlock: Block?
    fileprivate let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.init(white: 0, alpha: 0.75)
        contentView.backgroundColor = .clear
        containerView.backgroundColor = kPopupColor
        triangleView.backgroundColor = kPopupColor
        triangleView.contentMode = .top
        containerView.cornerRadius = 10.0
        containerView.clipsToBounds = true
        
        setupSubViews()
    }
    
    func setupSubViews() {
        handleTap()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleTap() {
        self.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [unowned self] (gesture) in
                if !self.containerView.frame.contains(gesture.location(in: self)) {
                    self.hide()
                }
            }).disposed(by: disposeBag)
    }
    
    func showInView(_ view: UIView = UIApplication.topViewController()?.view ?? UIView(),
                    sourceView: UIView? = nil,
                    text: String = "",
                    success: Block? = nil,
                    cancel: Block? = nil) {
        
        let ySourceView: CGFloat = sourceView?.y ?? 0.0
        let trianglePosition: Position = ySourceView/view.height < 0.5 ? .top : .bottom
        successBlock = success
        cancelBlock  = cancel
        containerView.representingText = text
        view.add(self, {
            $0.edges.equalTo(view)
        })
        add(contentView) {
            guard let sourceView = sourceView else {
                $0.center.equalTo(self)
                $0.width.equalTo(popupWidth)
                return
            }
            $0.centerX.equalTo(self)
            if trianglePosition == .bottom {
                $0.bottom.equalTo(sourceView.snp.bottom).inset(-20)
            } else {
                $0.top.equalTo(sourceView.snp.bottom).inset(-20)
            }
            $0.top.equalTo(sourceView.snp.bottom).inset(-20)
            $0.width.equalTo(popupWidth)
            
        }
        contentView.add(containerView) {
            $0.edges.equalTo(contentView)
        }
        triangleView.contentMode = trianglePosition == .bottom ? .bottom : .top
        contentView.add(triangleView) {
            $0.centerX.equalTo(sourceView!)
            if trianglePosition == .bottom {
                $0.bottom.equalTo(contentView).inset(-8)
            } else {
                $0.top.equalTo(contentView).inset(-8)
            }
            $0.size.equalTo(CGSize(width: 16, height: 8))
        }
        
        layoutIfNeeded()
        
        backgroundColor = UIColor.clear
        contentView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        contentView.alpha = 0.0
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: {
            self.contentView.transform = CGAffineTransform.identity
        }, completion: nil)
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: { () -> Void in
            self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            self.contentView.alpha = 1.0
        }, completion: nil)
    }
    
    internal func cancel(_ sender: AnyObject) {
        cancelBlock?()
        hide()
    }
    
    internal func success(_ sender: AnyObject) {
        successBlock?()
        hide()
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: {
            self.contentView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.contentView.alpha = 0.0
            self.backgroundColor = UIColor.clear
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}

class ContainerView: UIView, TextRepresentable {
    
    var representingText: String = "" {
        willSet {
            self.textView.text = newValue
            setNeedsLayout()
        }
    }
    
    var heightTextView: CGFloat {
        return self.textView.text.heightWithFont(self.textView.font!, width: popupWidth)
    }
    
    let textView = specify(UITextView(), {
        $0.textAlignment = .center
        $0.isEditable = false
        $0.backgroundColor = kPopupColor
        $0.font = UIFont(name:"Roboto-Regular", size:18)
    })
    
    let topGradientView = GradientView(startColor: kPopupColor, endColor: kPopupColor.withAlphaComponent(0.5) , contentMode: .top)
    let bottomGradientView = GradientView(startColor: kPopupColor, endColor: kPopupColor.withAlphaComponent(0.5), contentMode: .bottom)
    
    let view = specify(UIView(), {
        $0.backgroundColor = kPopupColor
    })
    
    override func layoutSubviews() {
        add(view, {
            $0.edges.equalTo(self)
        })
        view.add(textView, {
            $0.edges.equalTo(view)
            $0.height.equalTo(min(UIScreen.main.bounds.height/2, heightTextView))
        })
        view.add(topGradientView) {
            $0.leading.top.trailing.equalTo(view)
            $0.height.equalTo(10)
        }
        view.add(bottomGradientView) {
            $0.leading.bottom.trailing.equalTo(view)
            $0.height.equalTo(10)
        }
    }
}
