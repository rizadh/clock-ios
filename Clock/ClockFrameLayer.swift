//
//  ClockFrameLayer.swift
//  Clock
//
//  Created by Rizadh Nizam on 2017-02-27.
//  Copyright © 2017 Rizadh Nizam. All rights reserved.
//

import UIKit

class ClockFrameLayer: CALayer {
    var frameColor: CGColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    var innerColor: CGColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    var tickColor: CGColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var frameRadiusFactor: CGFloat {
        didSet {
            setNeedsDisplay()
        }
    }
    var frameWidthFactor: CGFloat {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var tickLengthFactor: CGFloat? {
        didSet {
            setNeedsDisplay()
        }
    }
    var tickWidthFactor: CGFloat? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(in ctx: CGContext) {
        guard let frameColor = frameColor, let innerColor = innerColor, let tickColor = tickColor  else {
            return
        }
        
        let radius = CGFloat.minimum(bounds.width, bounds.height) / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        let frameRadius = radius * frameRadiusFactor
        let frameWidth = radius * frameWidthFactor
        
        ctx.setFillColor(innerColor)
        ctx.addArc(center: center, radius: frameRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        ctx.fillPath()
        
        ctx.setLineCap(.round)
        
        if let tickLengthFactor = tickLengthFactor, let tickWidthFactor = tickWidthFactor {
            let tickEnd = radius * (frameRadiusFactor - tickLengthFactor)
            let tickWidth = radius * tickWidthFactor
            for tickNum in 0..<60 {
                let tickAngle = CGFloat(tickNum) * .pi / 30
                
                if tickNum % 5 == 0 {
                    ctx.setStrokeColor(frameColor)
                    ctx.setLineWidth(frameWidth)
                } else {
                    ctx.setStrokeColor(tickColor)
                    ctx.setLineWidth(tickWidth)
                }
                
                ctx.move(to: CGPoint(
                    x: center.x + sin(tickAngle) * tickEnd,
                    y: center.y - cos(tickAngle) * tickEnd
                ))
                
                ctx.addLine(to: CGPoint(
                    x: center.x + sin(tickAngle) * frameRadius,
                    y: center.y - cos(tickAngle) * frameRadius
                ))
                
                ctx.strokePath()
            }
        }
        
        ctx.setStrokeColor(frameColor)
        ctx.setLineWidth(frameWidth)
        ctx.addArc(center: center, radius: frameRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        ctx.strokePath()
    }
    
    init(radius radiusFactor: CGFloat, width widthFactor: CGFloat) {
        self.frameRadiusFactor = radiusFactor
        self.frameWidthFactor = widthFactor
        
        super.init()
        
        contentsScale = UIScreen.main.scale
    }
    
    convenience init(radius radiusFactor: CGFloat, width widthFactor: CGFloat, tickLength tickLengthFactor: CGFloat, tickWidth tickWidthFactor: CGFloat) {
        self.init(radius: radiusFactor, width: widthFactor)
        
        self.frameRadiusFactor = radiusFactor
        self.frameWidthFactor = widthFactor
        self.tickLengthFactor = tickLengthFactor
        self.tickWidthFactor = tickWidthFactor
    }
    
    override init(layer: Any) {
        if let layer = layer as? ClockFrameLayer {
            self.frameColor = layer.frameColor
            self.innerColor = layer.innerColor
            self.tickColor = layer.tickColor
            self.frameRadiusFactor = layer.frameRadiusFactor
            self.frameWidthFactor = layer.frameWidthFactor
            self.tickLengthFactor = layer.tickLengthFactor
            self.tickWidthFactor = layer.tickWidthFactor
            
            super.init(layer: layer)
        } else {
            fatalError("Bad layer type")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
