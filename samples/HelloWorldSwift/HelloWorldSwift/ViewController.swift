//
//  Copyright (c) 2011-2014 orbotix. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, RKOvalControlDelegate {
  var robot: RKConvenienceRobot!
  var ledON = false
  var ovalControl: RKOvalControl?

  var cheerAlert : AVAudioPlayer?
  var warnAlert : AVAudioPlayer?
  
  @IBOutlet var connectionLabel: UILabel!
  @IBOutlet weak var noConnWarnLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
   
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "appWillResignActive:", name: UIApplicationWillResignActiveNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "appDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
    
    RKRobotDiscoveryAgent.sharedAgent().addNotificationObserver(self, selector: "handleRobotStateChangeNotification:")
    
    if let cheerAlert = self.setupAudioPlayerWithFile("claps", type:"wav") {
      self.cheerAlert = cheerAlert
    }
    
    if let warnAlert = self.setupAudioPlayerWithFile("tiger", type:"wav") {
      self.warnAlert = warnAlert
    }
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      connectionLabel = nil;
  }

  required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
  }
  
  func appWillResignActive(note: NSNotification) {
    RKRobotDiscoveryAgent.disconnectAll()
    stopDiscovery()
  }
  
  func appDidBecomeActive(note: NSNotification) {
    startDiscovery()
  }
    
  func handleRobotStateChangeNotification(notification: RKRobotChangedStateNotification) {
    let noteRobot = notification.robot
    
    switch (notification.type) {
    case .Connecting:
      connectionLabel.text = "\(notification.robot.name()) Connecting"
      break
    case .Online:
      let conveniencerobot = RKConvenienceRobot(robot: noteRobot);
      
      if (UIApplication.sharedApplication().applicationState != .Active) {
        conveniencerobot.disconnect()
        noConnWarnLabel.hidden = false
      } else {
        noConnWarnLabel.hidden = true
        self.robot = RKConvenienceRobot(robot: noteRobot);
        self.ovalControl = RKOvalControl(robot: notification.robot, delegate: self)
        self.ovalControl!.resetOvmAndLibrary(true)
        sendOvalProgram()
        connectionLabel.text = noteRobot.name()
      }
      break
    case .Disconnected:
      connectionLabel.text = "Disconnected"
      startDiscovery()
      robot = nil;
      break
    default:
        NSLog("State change with state: \(notification.type)")
    }
  }
    
  func startDiscovery() {
    connectionLabel.text = "Discovering Robots"
    RKRobotDiscoveryAgent.startDiscovery()
  }
  
  func stopDiscovery() {
    RKRobotDiscoveryAgent.stopDiscovery()
  }
    
  func togleLED() {
    if let robot = self.robot {
      if (ledON) {
        robot.setLEDWithRed(0.0, green: 0.0, blue: 0.0)
      } else {
        robot.setLEDWithRed(0.0, green: 0.0, blue: 1.0)
      }
      ledON = !ledON
      
      let delay = Int64(0.5 * Float(NSEC_PER_SEC))
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_main_queue(), { () -> Void in
        self.togleLED();
      })
    }
  }
  
  func sendOvalProgram() {
    let source = try? NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("CommonFunctions", ofType: "oval")!, encoding: NSUTF8StringEncoding)
    if let unwrappedSource = source {
      self.ovalControl?.sendOvalPrograms([unwrappedSource])
    }
  }
  
  func highAlert() {
    let source = "TigerJump"
    sendProgram(source)
  }
  
  func clapsJump() {
    let source = "ClapsJump"
    sendProgram(source)
  }
  
  func sendGreenLight() {
    let source = "GreenLight"
    sendProgram(source)
  }
  
  func sendOrangeLight() {
    let source = "OrangeLight"
    sendProgram(source)
  }
  
  
  func sendProgram(source: String) {
    let source = try? NSString(contentsOfFile: NSBundle.mainBundle().pathForResource(source, ofType: "oval")!, encoding: NSUTF8StringEncoding)
    if let unwrappedSource = source {
      if let ovalControl = self.ovalControl {
        ovalControl.sendOvalPrograms([unwrappedSource])
      } else {
        print("no ovalcontrol")
        noConnWarnLabel.hidden = false
      }
    }

  }

  @IBAction func sendHighAlert(sender: AnyObject) {
    highAlert()
    if let alert = self.warnAlert {
      alert.prepareToPlay()
      alert.play()
    }
  }
  
  @IBAction func sendCheerAlert(sender: AnyObject) {
    clapsJump()
    if let alert = self.cheerAlert {
      alert.prepareToPlay()
      alert.play()
    }
  }
  
  @IBAction func sendGreenAlert(sender: UIButton) {
    sendGreenLight()
  }
  
  
  @IBAction func sendOrangeAlert(sender: AnyObject) {
    sendOrangeLight()
  }
  
  //MARK: RKOvalControlDelegate
  
  func ovalControlDidFinishSendingProgram(control: RKOvalControl!) {
    NSLog("Oval successfully sent")
  }
  
  func ovalControlDidResetOvm(control: RKOvalControl!) {
    NSLog("OVM Reset")
  }
  
  func ovalControl(control: RKOvalControl!, receivedOvalNotification notification: RKOvalDeviceBroadcast!) {
    NSLog("Did receive oval async with floats: \(notification.floats) ints: \(notification.ints)")
  }
  
  func ovalControl(control: RKOvalControl!, receivedVmRuntimeError notification: RKOvalErrorBroadcast!) {
    NSLog("Did receive OVM Error: \(notification.errorDescription())")
  }
  
  func ovalControl(control: RKOvalControl!, didFailToSendProgramWithMessage message: String!) {
    NSLog("Failed to send program with message: \(message)")
  }
  
  
  func setupAudioPlayerWithFile(file:NSString, type:NSString) -> AVAudioPlayer?  {
    let path = NSBundle.mainBundle().pathForResource(file as String, ofType: type as String)
    let url = NSURL.fileURLWithPath(path!)
    
    var audioPlayer:AVAudioPlayer?
    
    do {
      try audioPlayer = AVAudioPlayer(contentsOfURL: url)
    } catch {
      print("Player not available")
    }
    
    return audioPlayer
  }


}

