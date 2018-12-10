//
//  MessageMenu.swift
//  BitbonSpace
//
//  Created by Гранченко Юрий on 12/7/18.
//  Copyright © 2018 Simcord. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import StreamView
import SnapKit

let menuHeight = 44.0
let menuIconSpacing: CGFloat = 5.0

enum TouchPositionable {
    case begining, middle, ended
}
typealias BeginingPoint = (TouchPositionable, Bool)

class MessageMenu: UIScrollView {
    
    private let disposeBag = DisposeBag()
    private var collectionArray = ["Photo", "Music", "Digital", "AppStore", "Clock", "Pay", "Planet", "More"]
    
    private let horizontalStackView = specify(UIStackView()) {
        $0.axis  = .horizontal
        $0.distribution  = .fillEqually
        $0.alignment = .leading
        $0.spacing   = 5.0
    }
    
    convenience init () {
        self.init(frame: CGRect.zero)
        setupUI()
    }
    
    private func setupUI() {
        self.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        self.showsHorizontalScrollIndicator = false
        
        add(horizontalStackView, {
            $0.left.width.equalTo(self).inset(5)
            $0.top.height.equalTo(self)
        })
        let collectionImages = collectionArray.map({ imageName -> UIImageView in
            let imageView = UIImageView(image: UIImage(named: imageName))
            imageView.contentMode = .scaleAspectFit
            return imageView
        })
        let collectionTitle = collectionArray.map({ imageName -> Label in
            let label = Label()
            label.text = imageName
            label.textColor = .darkGray
            label.font = UIFont.medium(11.0)
            return label
        })
        let verticalStackList = collectionArray.enumerated().map({ index, _ -> UIStackView in
            let verticalStackView = specify(UIStackView()) {
                $0.axis  = .vertical
                $0.layoutMargins = UIEdgeInsets(top: 0.1, left: 0, bottom: 0, right: 0)
                $0.isLayoutMarginsRelativeArrangement = true
                $0.alignment = .center
            }
            verticalStackView.addArrangedSubview(collectionImages[index])
            verticalStackView.addArrangedSubview(collectionTitle[index])
            return verticalStackView
        })
        verticalStackList.forEach({horizontalStackView.addArrangedSubview($0)})
    }
    
    public func setupBindings() {
        let isRunning = Variable(false)
        let animationHelper: ((BeginingPoint) -> Void) = { [unowned self] arg in
            isRunning.value = arg.1
            self.horizontalStackView.spacing = arg.1 ? menuIconSpacing * 5 : menuIconSpacing
            self.horizontalStackView.arrangedSubviews
                .forEach({ ($0 as? UIStackView)?.spacing = arg.1 ? -5 : 0 })
            self.snp.updateConstraints({
                $0.height.equalTo( arg.1 ? menuHeight * 2 : menuHeight)
                $0.width.equalTo(Constants.screenWidth * (arg.1 ? 2 : 1))
            })
            
            UIView.animate(withDuration: 0.33, delay: 0.0, options: .curveEaseInOut, animations: {
                self.superview?.layoutIfNeeded()
                self.contentSize = CGSize(width: Constants.screenWidth * (arg.1 ? 3 : 1),
                                                     height: self.height)
                if arg.1 {
                    switch arg.0 {
                    case .begining:
                        self.setMinimumContentOffsetAnimated(false)
                    case .middle:
                        self.setContentOffset(CGPoint(x: self.maximumContentOffset.x/2,
                                                                 y: self.maximumContentOffset.y),
                                                         animated: false)
                    case .ended:
                        self.setMaximumContentOffsetAnimated(false)
                    }
                }
            }, completion: { _ in
                isRunning.value = true
            })
        }
        self.rx.didScroll
            .subscribe(onNext: {
                isRunning.value = false
            }).disposed(by: disposeBag)
        self.rx.didEndDecelerating
            .subscribe(onNext: { _ in
                isRunning.value = true
            }).disposed(by: disposeBag)
        self.rx.didEndDragging
            .subscribe(onNext: { _ in
                isRunning.value = true
            }).disposed(by: disposeBag)
        
        isRunning.asObservable()
            .flatMapLatest {  isRunning in
                isRunning ? Observable<Int>.interval(2.0, scheduler: MainScheduler.instance) : .empty()
            }
            .enumerated().flatMap { _, index in Observable.just(index) }
            .subscribe(onNext: { _ in
                animationHelper((TouchPositionable.begining, false))
            }).disposed(by: self.disposeBag)
        
        self.rx.anyGesture(.longPress(), .pan())
            .when(.began)
            .subscribe(onNext: { gesture in
                let touchPoint = gesture.location(in: self)
                let width = Constants.screenWidth
                let position = touchPoint.x > width/3 ? touchPoint.x > width/1.5 ?
                    TouchPositionable.ended : TouchPositionable.middle : TouchPositionable.begining
                animationHelper((position, true))
            }).disposed(by: self.disposeBag)
        
    }
    
}
