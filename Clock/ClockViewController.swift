import UIKit

class ClockViewController: UIViewController {
    var clockView: ClockView!
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("themeHue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clockView = ClockView(frame: view.frame)
        clockView.backgroundColor = UIColor.clear
        clockView.topAnchor.constraint(equalTo: view.topAnchor)
        clockView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        clockView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        clockView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        
        
        if let storedColor = NSKeyedUnarchiver.unarchiveObject(withFile: ClockViewController.ArchiveURL.path) as! CGFloat? {
            clockView.themeHue = storedColor
        }
        
        print(ClockViewController.ArchiveURL.path)
        
        view.addSubview(clockView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NSKeyedArchiver.archiveRootObject(clockView.themeHue, toFile: ClockViewController.ArchiveURL.path)
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
}

