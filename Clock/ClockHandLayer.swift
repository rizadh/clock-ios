import UIKit

class ClockHandLayer: CALayer {
    var handColor: CGColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var handLengthFactor: CGFloat
    var handWidthFactor: CGFloat
    var pinRadiusFactor: CGFloat?
    var pinFillColor: CGColor?
    
    override func draw(in ctx: CGContext) {
        guard let handColor = handColor else {
            return
        }
        
        let radius = CGFloat.minimum(bounds.width, bounds.height) / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let handLength = radius * handLengthFactor
        let handWidth = radius * handWidthFactor
        
        ctx.setLineCap(.round)
        ctx.setStrokeColor(handColor)
        ctx.setLineWidth(handWidth)
        ctx.move(to: CGPoint(x: center.x, y: center.y - handLength))
        
        if let pinRadiusFactor = pinRadiusFactor, let pinFillColor = pinFillColor {
            let pinRadius = radius * pinRadiusFactor
            
            ctx.addLine(to: CGPoint(x: center.x, y: center.y - pinRadius))
            ctx.strokePath()
            
            ctx.addArc(center: center, radius: pinRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
            ctx.setFillColor(pinFillColor)
            ctx.fillPath()
            
            ctx.addArc(center: center, radius: pinRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
            ctx.setFillColor(pinFillColor)
            ctx.strokePath()
        } else {
            ctx.addLine(to: center)
            ctx.strokePath()
        }
    }
    
    init(width widthFactor: CGFloat, length lengthFactor: CGFloat) {
        self.handWidthFactor = widthFactor
        self.handLengthFactor = lengthFactor
        
        super.init()
        
        contentsScale = UIScreen.main.scale
    }
    
    convenience init(width widthFactor: CGFloat, length lengthFactor: CGFloat, pinRadius pinRadiusFactor: CGFloat) {
        self.init(width: widthFactor, length: lengthFactor)
        
        self.pinRadiusFactor = pinRadiusFactor
        
        contentsScale = UIScreen.main.scale
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(layer: Any) {
        if let layer = layer as? ClockHandLayer {
            self.handColor = layer.handColor
            self.handLengthFactor = layer.handLengthFactor
            self.handWidthFactor = layer.handWidthFactor
            self.pinFillColor = layer.pinFillColor
            self.pinRadiusFactor = layer.pinRadiusFactor
            
            super.init(layer: layer)
        } else {
            fatalError("Bad layer type")
        }
    }
}
