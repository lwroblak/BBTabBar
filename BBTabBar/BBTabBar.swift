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

@IBDesignable class BBTabBar: UITabBar {
    
    @IBInspectable var color: UIColor?
    @IBInspectable var radii: CGFloat = 15.0
    
    private var state: State = .normal
    
    private var shapeLayer: CALayer?
    private var contentView: UIView?

    private var magicHeight: CGFloat  = 65
    private var magicOriginY: CGFloat = 0
    
    private var tabBarHeightNormal: CGFloat! = 65
    private var tabBarHeightExtended: CGFloat! = 265
    private var totalScreenHeight: CGFloat! = UIScreen.main.bounds.height
    
    private var isAnimating: Bool = false
    
    override func draw(_ rect: CGRect) {
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
        shapeLayer.shadowPath =  UIBezierPath(roundedRect: bounds, cornerRadius: radii).cgPath
        
        if let oldShapeLayer = self.shapeLayer {
            layer.replaceSublayer(oldShapeLayer, with: shapeLayer)
        } else {
            layer.insertSublayer(shapeLayer, at: 0)
        }
        
        self.shapeLayer = shapeLayer
    }
    
    public func initContentView(controller: UIViewController, marginTop: CGFloat = 20, marginBottom: CGFloat = 20, marginLeft: CGFloat = 20, marginRight: CGFloat = 20, height: CGFloat? = nil) {
        
        let contentHeight = height != nil ? height! : controller.view.bounds.height
        
        contentView = UIView(frame: CGRect(x: marginLeft, y: marginTop, width: frame.width-marginLeft-marginRight, height: contentHeight));
        contentView!.backgroundColor = .gray
        tabBarHeightExtended = tabBarHeightNormal + contentHeight + marginTop + marginBottom
        UIView.addChildToContainer(parent: contentView!, child: controller.view)
    }
    
    private func createPath() -> CGPath {
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radii, height: 0.0))
        return path.cgPath
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.isTranslucent = true
        var tabFrame            = self.frame
        tabFrame.size.height    = magicHeight + (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? CGFloat.zero)
        tabFrame.origin.y       = magicOriginY != 0 ? magicOriginY : self.frame.origin.y +   ( self.frame.height - magicHeight - (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? CGFloat.zero))
        
        self.layer.cornerRadius = 20
        self.frame            = tabFrame
        self.items?.forEach({ $0.titlePositionAdjustment = UIOffset(horizontal: 0.0, vertical: -5.0) })
        
    }
    
    public func updateLayout(origin: CGFloat, height: CGFloat) {
        var tabFrame            = self.frame
        tabFrame.size.height    = height
        tabFrame.origin.y       = origin
        self.layer.cornerRadius = 20
        self.frame            = tabFrame
        self.layoutSubviews()
    }
    
    public func showNormal() {
        guard isAnimating == false else {
            return
        }
        isAnimating = true
        hideTabBar(state: .extended)
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            self.showTabBar(state: .normal) {
                self.isAnimating = false
            }
        }
    }
    
    public func showExtended() {
        guard isAnimating == false else {
            return
        }
        isAnimating = true
        hideTabBar(state: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: {
            self.showTabBar(state: .extended) {
                self.isAnimating = false
            }
        })
    }
    
    private func hideTabBar(state: State) {
        guard contentView != nil else {
            print("TabBarBB: Content controller not set")
            return
        }
        
        var frame = self.frame
        frame.origin.y = totalScreenHeight
        
        magicOriginY = totalScreenHeight
        magicHeight = state == .normal ? tabBarHeightNormal :tabBarHeightExtended
        
        UIView.animate(withDuration: 0.5, animations: {
            self.frame = frame
        }) { _ in
            self.contentView?.removeFromSuperview()
        }
    }
    
    private func showTabBar(state: State, onCompleted: @escaping ()->()) {
        guard contentView != nil else {
            print("TabBarBB: Content controller not set")
            return
        }
        if state == .extended {
            self.addSubview(contentView!)
        }
        
        var frame = self.frame
        frame.origin.y = self.totalScreenHeight - (state == .normal ? tabBarHeightNormal :tabBarHeightExtended)
        frame.size.height = state == .normal ? tabBarHeightNormal :tabBarHeightExtended
        
        magicOriginY = totalScreenHeight - (state == .normal ? tabBarHeightNormal :tabBarHeightExtended)
        magicHeight = state == .normal ? tabBarHeightNormal :tabBarHeightExtended
        
        UIView.animate(withDuration: 0.5, animations: {
            self.frame = frame
        }) { _ in
            self.layoutSubviews()
            onCompleted()
        }
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
