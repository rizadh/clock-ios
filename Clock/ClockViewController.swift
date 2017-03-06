import UIKit

class ClockViewController: UIViewController {
    static let ArchiveURL = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("themeHue")
    
    var clockView: ClockView {
        get {
            return view as! ClockView
        }
    }
    
    var displayLink: CADisplayLink?
    
    @objc private func updateHands() {
        clockView.setHandAngles(getClockHandAngles())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let clockView = ClockView(frame: view.frame)
        clockView.topAnchor.constraint(equalTo: view.topAnchor)
        clockView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        clockView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        clockView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        
        let doubleTap = UITapGestureRecognizer(target: clockView, action: #selector(clockView.useDefaultHue as (Void) -> Void))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delaysTouchesEnded = false
        clockView.addGestureRecognizer(doubleTap)
        
        if let storedHue = NSKeyedUnarchiver.unarchiveObject(withFile: ClockViewController.ArchiveURL.path) as! CGFloat? {
            clockView.themeHue = storedHue
        }
        
        // Update hands on every screen refresh
        displayLink = CADisplayLink(target: self, selector: #selector(updateHands as (Void) -> Void))
        displayLink?.add(to: .current, forMode: .commonModes)
        
        view = clockView
    }
    
    func saveClockHue() {
        NSKeyedArchiver.archiveRootObject(clockView.themeHue, toFile: ClockViewController.ArchiveURL.path)
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    func handleShortcutItem(withName shortcutName: String) {
        switch (shortcutName) {
        case "useDefaultTheme":
            clockView.useDefaultHue()
        case "useRandomTheme":
            clockView.themeHue = CGFloat(arc4random()) / CGFloat(UINT32_MAX)
        case "activateDiscoMode":
            clockView.discoMode = true
        default:
            fatalError("Invalid shortcut type")
        }
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
}

