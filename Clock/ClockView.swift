import UIKit

class ClockView: UIView {
    
    private let defaultHue = 0.53 as CGFloat
    private var beingTouched = false
    private var displayLink: CADisplayLink!
    var themeHue: CGFloat! {
        didSet {
            themeHue = themeHue.truncatingRemainder(dividingBy: 1)
        }
    }
    var secondaryHue: CGFloat {
        get {
            return (self.themeHue + 0.5).truncatingRemainder(dividingBy: 1)
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        guard let context = UIGraphicsGetCurrentContext() else {
            fatalError("Could not get graphics context")
        }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        let radius = CGFloat.minimum(rect.width, rect.height) / 2
        
        let hues = [
            "primary": UIColor(hue: themeHue, saturation: 0.8889, brightness: 0.72, alpha: 1),
            "primaryDark": UIColor(hue: themeHue, saturation: 0.889, brightness: 0.54, alpha: 1),
            "primaryLight": UIColor(hue: themeHue, saturation: 0.4211, brightness: 0.76, alpha: 1),
            "secondary": UIColor(hue: themeHue, saturation: 0.1818, brightness: 0.88, alpha: 1),
            "accent": UIColor(hue: secondaryHue, saturation: 0.6957, brightness: 0.92, alpha: 1)
        ]
        
        let radii = [
            "longHand": 0.65 * radius,
            "shortHand": 0.45 * radius,
            "tickEnd": 0.75 * radius,
            "frame": 0.8 * radius,
            "pin": 0.04 * radius
        ]
        
        let strokeWidth = [
            "thick": radius / 20,
            "thin": radius / 40
        ]
        
        let handAngles = getClockHandAngles()
        
        let handPositions = [
            "second": CGPoint(
                x: center.x + sin(CGFloat(handAngles["second"]!)) * radii["longHand"]!,
                y: center.y - cos(CGFloat(handAngles["second"]!)) * radii["longHand"]!
            ),
            "minute": CGPoint(
                x: center.x + sin(CGFloat(handAngles["minute"]!)) * radii["longHand"]!,
                y: center.y - cos(CGFloat(handAngles["minute"]!)) * radii["longHand"]!
            ),
            "hour": CGPoint(
                x: center.x + sin(CGFloat(handAngles["hour"]!)) * radii["shortHand"]!,
                y: center.y - cos(CGFloat(handAngles["hour"]!)) * radii["shortHand"]!
            )
        ]
        
        context.setLineCap(.round)
        
        hues["primary"]!.setFill()
        context.fill(rect)
        
        hues["primaryDark"]!.setFill()
        context.addArc(center: center, radius: radii["frame"]!, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        context.fillPath()
        
        for tickNum in 0..<60 {
            let tickAngle = CGFloat(tickNum) * .pi / 30
            
            if tickNum % 5 == 0 {
                hues["secondary"]!.setStroke()
                context.setLineWidth(strokeWidth["thick"]!)
            } else {
                hues["primaryLight"]!.setStroke()
                context.setLineWidth(strokeWidth["thin"]!)
            }
            
            context.move(to: CGPoint(
                x: center.x + sin(tickAngle) * radii["tickEnd"]!,
                y: center.y - cos(tickAngle) * radii["tickEnd"]!
            ))
            context.addLine(to: CGPoint(
                x: center.x + sin(tickAngle) * radii["frame"]!,
                y: center.y - cos(tickAngle) * radii["frame"]!
            ))
            
            context.strokePath()
        }
        
        hues["secondary"]!.setStroke()
        context.setLineWidth(strokeWidth["thick"]!)
        context.addArc(center: center, radius: radii["frame"]!, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        context.strokePath()
        
        hues["primaryLight"]!.setStroke()
        context.setLineWidth(strokeWidth["thick"]!)
        context.move(to: center)
        context.addLine(to: handPositions["minute"]!)
        context.strokePath()
        
        hues["secondary"]!.setStroke()
        context.setLineWidth(strokeWidth["thick"]!)
        context.move(to: center)
        context.addLine(to: handPositions["hour"]!)
        context.strokePath()
        
        hues["accent"]!.setStroke()
        context.setLineWidth(strokeWidth["thin"]!)
        context.move(to: center)
        context.addLine(to: handPositions["second"]!)
        context.strokePath()
        
        hues["primaryDark"]!.setFill()
        context.addArc(center: center, radius: radii["pin"]!, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        context.fillPath()
        
        hues["accent"]!.setStroke()
        context.setLineWidth(strokeWidth["thin"]!)
        context.addArc(center: center, radius: radii["pin"]!, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
        context.strokePath()
        
        if beingTouched {
            themeHue = (themeHue + 1 / 360).truncatingRemainder(dividingBy: 1)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        themeHue = defaultHue
        
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.isOpaque = true;
        
        displayLink = CADisplayLink(target: self, selector: #selector(setNeedsDisplay as (Void) -> Void))
        displayLink.add(to: .current, forMode: .commonModes)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if touch.tapCount > 1 {
                themeHue = defaultHue
            } else {
                beingTouched = true
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        beingTouched = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        beingTouched = false
    }
    
    private func getClockHandAngles() -> [String: Float] {
        let date = NSDate()
        let calendar = NSCalendar.current
        
        let nanoseconds = Float(calendar.component(.nanosecond, from: date as Date))
        let seconds = Float(calendar.component(.second, from: date as Date)) + nanoseconds / 1e9
        let minutes = Float(calendar.component(.minute, from: date as Date)) + seconds / 60
        let hours = (Float(calendar.component(.hour, from: date as Date)) + minutes / 60).truncatingRemainder(dividingBy: 12)
        
        let handAngles = [
            "hour": 2 * .pi * hours / 12,
            "minute": 2 * .pi * minutes / 60,
            "second": 2 * .pi * seconds / 60
        ]
        
        return handAngles
    }
    
}
