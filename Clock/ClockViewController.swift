import UIKit
import AudioToolbox

class ClockViewController: UIViewController {
    static let ArchiveURL = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("themeHue")

    var clockView: ClockView {
        get {
            return view as! ClockView
        }
    }

    var lastTouchAngle: CGFloat = 0

    var themeHue: CGFloat = ClockView.defaultHue {
        didSet {
            themeHue = themeHue.truncatingRemainder(dividingBy: 1)

            while themeHue < 0 { self.themeHue += 1 }

            if themeHue.isNaN { themeHue = 0 }
            
            setLayerColors()
        }
    }
    
    func setLayerColors() {
        let primary = UIColor(hue: themeHue, saturation: 0.8889, brightness: 0.72, alpha: 1)
        let primaryDark = UIColor(hue: themeHue, saturation: 0.889, brightness: 0.54, alpha: 1)
        let primaryLight = UIColor(hue: themeHue, saturation: 0.4211, brightness: 0.76, alpha: 1)
        let secondary = UIColor(hue: themeHue, saturation: 0.1818, brightness: 0.88, alpha: 1)
        let accent = UIColor(hue: secondaryHue, saturation: 0.6957, brightness: 0.92, alpha: 1)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        clockView.backgroundColor = primary
        clockView.frameLayer.innerColor = primaryDark.cgColor
        clockView.frameLayer.frameColor = secondary.cgColor
        clockView.frameLayer.tickColor = primaryLight.cgColor
        clockView.minuteHandLayer.handColor = primaryLight.cgColor
        clockView.hourHandLayer.handColor = secondary.cgColor
        clockView.secondHandLayer.handColor = accent.cgColor
        clockView.secondHandLayer.pinFillColor = primaryDark.cgColor
        CATransaction.commit()
    }

    private var secondaryHue: CGFloat {
        get {
            return (themeHue + 0.5).truncatingRemainder(dividingBy: 1)
        }
    }

    var skewAngle: CGFloat = 0 {
        willSet {
            if newValue < 0 || newValue > .pi / 6 {
                AudioServicesPlaySystemSound(1104)
                print(newValue)
            }
        }
        didSet {
            skewAngle = skewAngle.truncatingRemainder(dividingBy: .pi / 6)

            while skewAngle < 0 {
                skewAngle += .pi / 6
            }

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            clockView.frameLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(rotationAngle: skewAngle))
            CATransaction.commit()
        }
    }

    @objc private func updateHands() {
        setHandAngles(getClockHandAngles())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view = ClockView(frame: view.frame)
        clockView.topAnchor.constraint(equalTo: view.topAnchor)
        clockView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        clockView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        clockView.trailingAnchor.constraint(equalTo: view.trailingAnchor)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(useDefaultHue as (Void) -> Void))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delaysTouchesEnded = false
        clockView.addGestureRecognizer(doubleTap)

        if let storedHue = NSKeyedUnarchiver.unarchiveObject(withFile: ClockViewController.ArchiveURL.path) as? CGFloat {
            themeHue = storedHue
        }

        // Update hands on every screen refresh
        let displayLink = CADisplayLink(target: self, selector: #selector(updateHands as (Void) -> Void))
        displayLink.add(to: .current, forMode: .commonModes)
        
        setLayerColors()
    }

    func saveClockHue() {
        NSKeyedArchiver.archiveRootObject(themeHue, toFile: ClockViewController.ArchiveURL.path)
    }

    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }

    func handleShortcutItem(withName shortcutName: String) {
        switch (shortcutName) {
        case "useDefaultTheme":
            useDefaultHue()
        case "useRandomTheme":
            themeHue = CGFloat(arc4random()) / CGFloat(UINT32_MAX)
        default:
            fatalError("Invalid shortcut type")
        }
    }

    func useDefaultHue() {
        themeHue = ClockView.defaultHue
    }

    private func getClockHandAngles() -> (hour: CGFloat, minute: CGFloat, second: CGFloat) {
        let date = NSDate()
        let calendar = NSCalendar.current

        let nanoseconds = CGFloat(calendar.component(.nanosecond, from: date as Date))
        let seconds = CGFloat(calendar.component(.second, from: date as Date)) + nanoseconds / 1e9
        let minutes = CGFloat(calendar.component(.minute, from: date as Date)) + seconds / 60
        let hours = (CGFloat(calendar.component(.hour, from: date as Date)) + minutes / 60)

        return (hour: hours * .pi / 6, minute: minutes * .pi / 30, second: seconds * .pi / 30)
    }

    // MARK: Touch handlers (UIResponder methods)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchAngle = getTouchAngle(to: touches.first!.preciseLocation(in: clockView))
        clockView.frameLayer.removeAnimation(forKey: "skew")
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let currentAngle = getTouchAngle(to: touches.first!.preciseLocation(in: clockView))

        if currentAngle != CGFloat.infinity && !currentAngle.isNaN {
            skewAngle += currentAngle - lastTouchAngle
            themeHue += (currentAngle - lastTouchAngle) / .pi / 2
            lastTouchAngle = currentAngle
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetSkewAngle()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetSkewAngle()
    }

    private func resetSkewAngle() {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = skewAngle
        if (skewAngle < .pi / 12) {
            animation.toValue = CGFloat(0.0)
        } else {
            animation.toValue = CGFloat(0.5)
        }

        CATransaction.begin()
        CATransaction.setValue(CGFloat(0.2), forKey: kCATransactionAnimationDuration)
        CATransaction.setValue(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut), forKey: kCATransactionAnimationTimingFunction)
        clockView.frameLayer.add(animation, forKey: "skew")
        CATransaction.commit()

        skewAngle = 0
    }

    private func getTouchAngle(to touchPosition: CGPoint) -> CGFloat {
        let x = touchPosition.x - clockView.center.x
        let y = touchPosition.y - clockView.center.y

        return (x < 0 ? 1 : 2) * .pi + atan(y / x)
    }


    func setHandAngles(_ hands: (hour: CGFloat, minute: CGFloat, second: CGFloat)) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        clockView.minuteHandLayer.transform = CATransform3DMakeRotation(hands.minute, 0, 0, 1)
        clockView.hourHandLayer.transform = CATransform3DMakeRotation(hands.hour, 0, 0, 1)
        clockView.secondHandLayer.transform = CATransform3DMakeRotation(hands.second, 0, 0, 1)
        CATransaction.commit()
    }
}

