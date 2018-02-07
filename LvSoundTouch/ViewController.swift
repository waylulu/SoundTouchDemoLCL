//
//  ViewController.swift
//  LvSoundTouch
//
//  Created by lv on 2018/2/3.
//  Copyright © 2018年 ss. All rights reserved.
//

import UIKit

class ViewController: UIViewController,AVAudioPlayerDelegate,AudioConvertDelegate,DotimeManageDelegate {
    //录音时长
    @IBOutlet weak var timeL: UILabel!
    @IBOutlet weak var RecordButton: UIButton!
    @IBOutlet weak var StartRecordButton: UIButton!
    //速度
    @IBOutlet weak var tempoChangeLabel: UILabel!
    //音频
    @IBOutlet weak var pitchSemitonesLabel: UILabel!
    //速率
    @IBOutlet weak var rateChangeLabel: UILabel!
    //获取音频会话单例
    fileprivate let audioSession = AVAudioSession.sharedInstance()
    
    var outputFormat:AudioConvertOutputFormat!//输出音频格式
    
    //录音
    var audioPalyer:AVAudioPlayer!
    
    //控制音变
    var soundTouchTempoChange:Int!//速度 <变速不变调> 范围 -50 ~ 100
    var soundTouchPitch:Int!  //音调  范围 -12 ~ 12
    var soundTouchRate:Int! ////声音速率 范围 -50 ~ 100

    //录音时间
    var timeManager:DotimeManage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
      //设置初始值
         self.RecordButton.isSelected = false
         self.StartRecordButton.isSelected = false
         timeManager = DotimeManage.default()
         timeManager.delegate = self
        
         self.soundTouchTempoChange = 0
         self.soundTouchRate = 0
         self.soundTouchPitch = 0
    }
    
    
 // MARK:#  - 时间改变(录音时间)
    
    func timerActionValueChange(_ time: Int32) {
        self.timeL.text = self.timeFormate(CGFloat(time))
    }
    
    //时间格式转换(ss转hh:mm:ss)
      func timeFormate(_ time :CGFloat) -> String{
        let t = Int(time)
        var timeStr = ""
        if t < 3000 {
            timeStr = String.init(format: "%02d:%02d", t / 60 , t % 60)
        }else{
            timeStr = String.init(format: "%02d:%02d:02d", t / 3600 ,t / 3600 / 60, (t / 3600 / 60 ) % 60)
        }
        return timeStr
    }
    
    
    // MARK:#  -调整变声参数
   
    //速度
    @IBAction func tempoChangeValue(_ sender: UISlider) {
        let value = Int(sender.value)
        self.soundTouchTempoChange = Int(value)
        self.tempoChangeLabel.text = "速度:\(value)"
    }
    //音频
    @IBAction func pitchSemitonesValue(_ sender: UISlider) {
        let value = Int(sender.value)
        self.soundTouchPitch = Int(value)
        self.pitchSemitonesLabel.text = "音频:\(value)"
        
    }
    //速率
    @IBAction func rateChangeValue(_ sender: UISlider) {
        let value = Int(sender.value)
        self.soundTouchRate = Int(value)
        self.rateChangeLabel.text = "速率:\(value)"
        
    }
    
    
    // MARK:#  - 录音
    
    //录音事件
    @IBAction func RecordButtonEvent(_ sender:UIButton) {
        self.stopAudio()
        sender.isSelected = !sender.isSelected
        //录音
        if sender.isSelected == true {
             Recorder.share().startRecord()
             timeManager.timeValue = 30
             timeManager.startTime()
             self.RecordButton.setTitle("停止录音", for: UIControlState.normal)
            return
        }

        //停止录音
        if sender.isSelected == false {
            timeManager.stopTimer()
            Recorder.share().stopRecord()
             self.RecordButton.isSelected = false
             self.RecordButton.setTitle("录音", for: UIControlState.normal)
            return
        }
    }

    

 // MARK:#  - 播放
    
    //开始播放
    @IBAction func StartRecordEvent(_ sender: UIButton) {
        
          if Recorder.share().filePath == nil{
              SVProgressHUD.showError(withStatus: "请先录音")
             return
          }
        
        sender.isSelected = !sender.isSelected
        //开始播放
        if sender.isSelected == true {
            self.StartRecordButton.setTitle("停止播放", for: UIControlState.normal)
            
            self.stopAudio()
            
            let p = Recorder.share().filePath
            Recorder.share().stopRecord()
            
            var dconfig = AudioConvertConfig()
            dconfig.sourceAuioPath = (p! as NSString).utf8String
            dconfig.outputFormat = Int32(AudioConvertOutputFormat.MP3.rawValue)  //输出音频格式
            dconfig.outputChannelsPerFrame = 1
            dconfig.outputSampleRate = 22050
            dconfig.soundTouchTempoChange = Int32(self.soundTouchTempoChange)
            dconfig.soundTouchPitch = Int32(self.soundTouchPitch)
            dconfig.soundTouchRate = Int32(self.soundTouchRate)
            // -25 7 20
            AudioConvert.share().audioConvertBegin(dconfig, withCallBackDelegate: self)
            return
        }
        
      if sender.isSelected == false {
            self.StartRecordButton.setTitle("开始播放", for: UIControlState.normal)
            self.stopAudio()
            self.StartRecordButton.isSelected = false
            return
        }
    }
    
    
    //停止播放
    func stopAudio(){
        if audioPalyer != nil{
            self.audioPalyer.stop()
        }
    }
    

    //播放
    func playAudio(path:NSString){
        
        self.stopAudio()
        
        let audioName = path.lastPathComponent as NSString
        let range = audioName.range(of: "amr")
        if range.length > 0 {
            let alertView = UIAlertView(title: "提示" , message: "输出音频: %@ \n iOS 设备不能直接播放amr 格式音频", delegate: nil, cancelButtonTitle: "取消", otherButtonTitles: "好的")
            alertView.show()
            SVProgressHUD.dismiss()
            self.stopAudio()
        }else{
            SVProgressHUD.showSuccess(withStatus: "文件名:"+"\(audioName)")
        }
        
        let url = URL.init(string:path as String)
        audioPalyer = try! AVAudioPlayer.init(contentsOf: url!)
        audioPalyer.delegate=self
        audioPalyer.play()

    }
    
// MARK:#  - 播放回调代理
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.stopAudio()
        SVProgressHUD.showSuccess(withStatus:"播放完成")
        self.StartRecordButton.setTitle("开始播放", for: UIControlState.normal)
        self.StartRecordButton.isSelected = false
    }
    

// MARK:# - AudioConvertDelegate
    
    /**
     * 是否只对音频文件进行解码 默认 NO 分快执行时 不会调用此方法
     * return YES : 只解码音频 并且回调 "对音频解码动作的回调"  NO : 对音频进行变声 不会 回调 "对音频解码动作的回调"
     **/
    func audioConvertOnlyDecode() -> Bool {
        return false
    }
    
    /**
     * 是否只对音频文件进行编码 默认 YES 分快执行时 不会调用此方法
     * return YES : 需要编码音频 并且回调 "对音频编码动作的回调"  NO : 不对音频进行编码 不会回调 "变声处理结果的回调"
     **/
    func audioConvertHasEnecode() -> Bool {
        return true
    }
    
    
    /**
     * 对音频编码动作的回调
     **/
    
    //解码成功
    func audioConvertEncodeSuccess(_ audioPath: String!) {
        self.playAudio(path: audioPath! as NSString)
    }
    
    //解码失败
    func audioConvertEncodeFaild() {
        SVProgressHUD.showError(withStatus: "解码失败")
        self.stopAudio()
    }
    
    
    /**
     * 对音频解码动作的回调
     **/

    //解码成功
    func audioConvertDecodeSuccess(audioPath:String){
        self.playAudio(path: audioPath as NSString)
    }

    //解码失败
    func audioConvertDecodeFaild() {
        SVProgressHUD.showError(withStatus: "解码失败")
        self.stopAudio()
    }


    /**
     * 对音频变声动作的回调
     **/

    //变声成功
    func audioConvertSoundTouchSuccess(_ audioPath: String!) {
        self.playAudio(path: audioPath! as NSString)
    }

    //变声失败
    func audioConvertSoundTouchFail() {
        SVProgressHUD.showError(withStatus: "解码失败")
        self.stopAudio()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

