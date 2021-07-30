//
//  BBTabBar.swift
//  BBTabBar
//
//  Created by Łukasz Wróblak on 05/07/2021.
//

import Foundation
import UIKit

enum State {
    case normal
    case extended
}

@IBDesignable public class BBTabBar: UITabBar {
    
    @IBInspectable var color: UIColor?
    @IBInspectable var cornerRadius: CGFloat = 15.0
    @IBInspectable var pauseBeforeShow = 0.2
    
    private var shapeLayer: CALayer?
    private var contentView: UIView?
    
    //size metrics - default values
    private var currentHeight: CGFloat  = 65
    private var currentOriginY: CGFloat = 0
    private var tabBarHeightNormal: CGFloat! = 65
    private var tabBarHeightExtended: CGFloat! = 265
    private var contentHeight: CGFloat = 0
    
    //tabbar item frames
    private var tItemFrames = [UITabBarItem : CGRect]()
    private var tItemFramesMutable = [UITabBarItem : CGRect]()
    
    private var totalScreenHeight = { () -> CGFloat in
        return  UIScreen.main.bounds.height
    }
    
    private var totalScreenHeightWithoutInsets = { () -> CGFloat in
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            let topPadding = window?.safeAreaInsets.top
            return window?.safeAreaInsets.bottom != nil ? UIScreen.main.bounds.height - window!.safeAreaInsets.bottom : UIScreen.main.bounds.height
        }
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows[0]
            let topPadding = window.safeAreaInsets.top
            return UIScreen.main.bounds.height - window.safeAreaInsets.bottom
        }
        return  UIScreen.main.bounds.height
    }
    
    private var isAnimating: Bool = false
    private var state: State = .normal
    
    public override func draw(_ rect: CGRect) {
        addShape()
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    public override init(frame:CGRect) {
        super.init(frame: frame)
    }
    
    private func addShape() {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = createPath()
        shapeLayer.strokeColor = UIColor.gray.withAlphaComponent(0.1).cgColor
        shapeLayer.fillColor = color?.cgColor ?? UIColor.white.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.shadowColor = UIColor.black.cgColor
        shapeLayer.shadowOffset = CGSize(width: 0   , height: -3);
        shapeLayer.shadowOpacity = 0.2
        shapeLayer.shadowPath =  UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        
        if let oldShapeLayer = self.shapeLayer {
            layer.replaceSublayer(oldShapeLayer, with: shapeLayer)
        } else {
            layer.insertSublayer(shapeLayer, at: 0)
        }
        
        self.shapeLayer = shapeLayer
    }
    
    public func initContentView(controller: UIViewController, marginTop: CGFloat = 20, marginBottom: CGFloat = 20, marginLeft: CGFloat = 20, marginRight: CGFloat = 20, height: CGFloat? = nil) {
        contentHeight = height != nil ? height! : controller.view.bounds.height
        contentView = UIView(frame: CGRect(x: marginLeft, y: marginTop, width: frame.width-marginLeft-marginRight, height: contentHeight));
        contentView!.backgroundColor = .gray
        tabBarHeightExtended = tabBarHeightNormal + contentHeight + marginTop + marginBottom
        UIView.addChildToContainer(parent: contentView!, child: controller.view)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.isTranslucent = true
        var tabFrame            = self.frame
        tabFrame.size.height    = currentHeight + (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? CGFloat.zero)
        tabFrame.origin.y       = currentOriginY != 0 ? currentOriginY : self.frame.origin.y +   ( self.frame.height - currentHeight - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? CGFloat.zero))
        self.layer.cornerRadius = cornerRadius
        self.frame = tabFrame
        self.items?.forEach({ $0.titlePositionAdjustment = UIOffset(horizontal: 0.0, vertical: -5.0) })
        if tItemFrames.isEmpty {
            for item in self.items! {
                tItemFrames[item] = (item.value(forKey: "view") as! UIView).frame
                tItemFramesMutable[item] = (item.value(forKey: "view") as! UIView).frame
            }
        } else {
            self.items?.forEach({ item in
                (item.value(forKey: "view") as! UIView).frame = tItemFramesMutable[item]!
            })
        }
    }
    
    public func showNormal(duration: Double = 0.5) {
        guard isAnimating == false else {
            return
        }
        isAnimating = true
        state = .normal
        hideTabBar(state: .extended, duration: duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + pauseBeforeShow) {
            self.showTabBar(state: .normal, duration: duration) {
                
                self.isAnimating = false
            }
        }
    }
    
    public func showExtended(duration: Double = 0.5) {
        guard isAnimating == false else {
            return
        }
        isAnimating = true
        state = .extended
        hideTabBar(state: .normal, duration: duration)
        DispatchQueue.main.asyncAfter(deadline: .now()+duration+pauseBeforeShow, execute: {
            self.showTabBar(state: .extended, duration: duration) {
                self.isAnimating = false
            }
        })
    }
    
    private func hideTabBar(state: State, duration: Double = 0.5) {
        guard contentView != nil else {
            print("TabBarBB: Content controller not set")
            return
        }
        
        var frame = self.frame
        frame.origin.y = totalScreenHeight()
        
        currentOriginY = totalScreenHeight()
        currentHeight = state == .normal ? tabBarHeightNormal :tabBarHeightExtended
        
        UIView.animate(withDuration: duration, animations: {
            self.frame = frame
        }) { _ in
            self.contentView?.removeFromSuperview()
        }
    }
    
    private func showTabBar(state: State, duration: Double = 0.5, onCompleted: @escaping ()->()) {
        guard contentView != nil else {
            print("TabBarBB: Content controller not set")
            return
        }
        if state == .extended {
            self.addSubview(contentView!)
        }
        
        var frame = self.frame
        frame.origin.y = self.totalScreenHeightWithoutInsets() - (state == .normal ? tabBarHeightNormal :tabBarHeightExtended)
        frame.size.height = state == .normal ? tabBarHeightNormal :tabBarHeightExtended
        
        currentOriginY = totalScreenHeightWithoutInsets() - (state == .normal ? tabBarHeightNormal :tabBarHeightExtended)
        currentHeight = state == .normal ? tabBarHeightNormal :tabBarHeightExtended
        
        tItemFramesMutable = tItemFrames.mapValues({ frame in
            var newFrame = frame
            newFrame.origin.y = state == .extended ? newFrame.origin.y + contentHeight + 40 : newFrame.origin.y
            return newFrame
        })
        
        UIView.animate(withDuration: duration, animations: {
            self.frame = frame
        }) { _ in
            onCompleted()
        }
    }
    
    public func isExtended() -> Bool {
        return state == .extended ? true : false
    }
    
    private func createPath() -> CGPath {
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: cornerRadius, height: 0.0))
        return path.cgPath
    }
    
}


public extension UIView {
    
    static func addChildToContainer(parent container: UIView, child childView: UIView) {
        container.addSubview(childView)
        
        childView.alpha = 0
        UIView.animate(withDuration: 0.27) {
            childView.alpha = 1
        }
        
        childView.translatesAutoresizingMaskIntoConstraints = false
        let views = Dictionary(dictionaryLiteral: ("childView", childView),("container", container))
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[childView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
        container.addConstraints(horizontalConstraints)
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[childView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
        container.addConstraints(verticalConstraints)
    }
    
}


