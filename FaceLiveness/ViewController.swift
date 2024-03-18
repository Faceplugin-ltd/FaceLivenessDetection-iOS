import UIKit
import AVFoundation
import CoreData

class ViewController: UIViewController, UINavigationControllerDelegate{
    
    static let CORE_DATA_NAME = "Model"
    static let ENTITIES_NAME = "Person"
    static let ATTRIBUTE_NAME = "name"
    static let ATTRIBUTE_FACE = "face"
    static let ATTRIBUTE_TEMPLATES = "templates"

    @IBOutlet weak var warningLbl: UILabel!
    
    @IBOutlet weak var identifyBtnView: UIView!
    @IBOutlet weak var settingsBtnView: UIView!
    @IBOutlet weak var aboutBtnView: UIView!
    
    @IBOutlet weak var personView: UITableView!
    
    var attributeImage: UIImage? = nil
    var attributeFace: FaceBox? = nil
    
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: ViewController.CORE_DATA_NAME)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
            return .lightContent
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    
        //com.faceplugin.faceliveness
        var ret = FaceSDK.setActivation("bgwr6PNJXgutWMmuXPIwObGCkqRZ+PfnyotgwQlKVH5UzmjVJ3fZ0gau9SAemgt4q2wsk0mkBh7A" +
                                        "NKI2zPuBqCPie8O6Ch11eNU/OY0r+4kXICaEeulzeq79ydnyprC/SlowMtNUsrVwTfGnfmA64ihf" +
                                        "E1IS3xjtsKxx3OZJ9wyEcF9VW6yrzmASWo/4d/5Y/9dbCbpGbScwcPt3XlMb0XLEv74TeqWathta" +
                                        "XayVLMrJKAR57QXkEmRgltswRfVeHVp/eUHxhh79LCAR8nUtTGXkRpo4Kq0k5o+TrnLTyJwkC4W6" +
                                        "l+hraUBMp6Jt1eEUGNxeYhnXtzWx307RuWbMYQ==")
        
        
        if(ret == SDK_SUCCESS.rawValue) {
            ret = FaceSDK.initSDK()
        }
        
        if(ret != SDK_SUCCESS.rawValue) {
            warningLbl.isHidden = false
            
            if(ret == SDK_LICENSE_KEY_ERROR.rawValue) {
                warningLbl.text = "Invalid license!"
            } else if(ret == SDK_LICENSE_APPID_ERROR.rawValue) {
                warningLbl.text = "Invalid license!"
            } else if(ret == SDK_LICENSE_EXPIRED.rawValue) {
                warningLbl.text = "License expired!"
            } else if(ret == SDK_NO_ACTIVATED.rawValue) {
                warningLbl.text = "No activated!"
            } else if(ret == SDK_INIT_ERROR.rawValue) {
                warningLbl.text = "Init error!"
            }
        }
        
        SettingsViewController.setDefaultSettings()

    }
    
    
    @IBAction func identify_touch_down(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.identifyBtnView.backgroundColor = UIColor(named: "clr_main_button_bg2") // Change to desired color
        }
    }
    
    @IBAction func identify_touch_up(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.identifyBtnView.backgroundColor = UIColor(named: "clr_main_button_bg1") // Change to desired color
        }
    }
    
    @IBAction func identify_clicked(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.identifyBtnView.backgroundColor = UIColor(named: "AccentColor") // Change to desired color
        }
        
        performSegue(withIdentifier: "camera", sender: self)
    }
    
    
    @IBAction func settings_touch_down(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.settingsBtnView.backgroundColor = UIColor(named: "clr_main_button_bg2")
        }
    }
    
    
    @IBAction func settings_touch_up(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.settingsBtnView.backgroundColor = UIColor(named: "clr_main_button_bg1")
        }
    }
    
    @IBAction func settings_clicked(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.settingsBtnView.backgroundColor = UIColor(named: "AccentColor") // Change to desired color
        }

        performSegue(withIdentifier: "settings", sender: self)
    }
    
    @IBAction func about_touch_down(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.aboutBtnView.backgroundColor = UIColor(named: "clr_main_button_bg2") // Change to desired color
        }
    }
    
    
    @IBAction func about_touch_up(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.aboutBtnView.backgroundColor = UIColor(named: "clr_main_button_bg1") // Change to desired color
        }
    }
    
    @IBAction func about_clicked(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.aboutBtnView.backgroundColor = UIColor(named: "AccentColor") // Change to desired color
        }

        performSegue(withIdentifier: "about", sender: self)
    }
    
    @IBAction func brand_clicked(_ sender: Any) {
        let webURL = URL(string: "https://faceplugin.com")
        UIApplication.shared.open(webURL!, options: [:], completionHandler: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }
}

