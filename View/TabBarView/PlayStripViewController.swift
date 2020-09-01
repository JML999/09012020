//
//  PlayStripViewController.swift
//  AR_Camera
//
//  Created by Justin Lee on 8/19/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import UIKit
import AVFoundation

class PlayStripViewController: UIViewController {
    
    @IBOutlet weak var imgView: UIImageView?
    @IBOutlet weak var ffwButton: UIButton?
    @IBOutlet weak var rrwButton: UIButton?
    @IBOutlet weak var returnButton: UIButton?
    
    var strip: [Cel]?
    var queueCounter = 0
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerQueue : AVQueuePlayer?
    private var queuePlayerLayer: AVPlayerLayer?
    var playerLooper: NSObject?
    
    var isReturningToCurrentUserView = false
    var isReturningToProfileView = false

    override func viewDidLoad() {
        super.viewDidLoad()
        print(strip?.count)
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.playerQueue?.currentItem, queue: .main) { _ in
                      self.playerQueue?.seek(to: CMTime.zero)
                      self.playerQueue?.play()
        }
        playStrip()
    }
    
    func playStrip(){
        guard strip != nil else {return}
        if !((strip!.count) <= queueCounter){
            print("Current Strip Gif: ", strip![queueCounter].isGif)
            print("Current Strip Pic: ", strip![queueCounter].isPicture)
            print("Current Strip Vid: ", strip![queueCounter].isVideo)
            let currentCel = strip![queueCounter]
            displayCel(currentCel: currentCel)
        } else {
            queueCounter = 0
            print("0 Index of Gif: ")
            print("Current Strip Gif: ", strip![queueCounter].isGif)
            print("Current Strip Pic: ", strip![queueCounter].isPicture)
            print("Current Strip Vid: ", strip![queueCounter].isVideo)
            let currentCel = strip![queueCounter]
            displayCel(currentCel: currentCel)
        }
    }
    
    func displayCel(currentCel: Cel){
        if currentCel.isPicture {
            imgView?.sd_setImage(with: URL(string: currentCel.urlString), completed: {(img, err, c, url) in})
        } else if currentCel.isVideo {
            let vidURL = URL(string: currentCel.urlString)
            createStripVideo(url: vidURL!)
        } else if currentCel.isGif {
            imgView?.sd_setImage(with: URL(string: currentCel.urlString), completed: {(img, err, c, url) in})
        }
    }
    
    func createStripVideo(url: URL){
        guard url.absoluteString != "" else {
            print("No video url")
            return
        }
        
        self.playerQueue = AVQueuePlayer.init()
        self.playerQueue!.removeAllItems()
        
        let playerItem = AVPlayerItem.init(url: url)
        self.playerQueue!.insert(playerItem, after: nil)
        
        self.queuePlayerLayer = AVPlayerLayer()
        self.queuePlayerLayer = AVPlayerLayer(player: playerQueue)
        playerLooper = AVPlayerLooper(player: self.playerQueue!, templateItem: playerItem)
        self.queuePlayerLayer?.frame = self.view.layer.bounds
        self.queuePlayerLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view!.layer.addSublayer(queuePlayerLayer!)
        
        // Bring UI to front
        DispatchQueue.main.async {
            self.view.addSubview(self.ffwButton!)
            self.view.addSubview(self.rrwButton!)
            self.view.addSubview(self.returnButton!)
            self.playerQueue!.play();
        }
    }
    
    @IBAction func ffButtonPressed(_ sender: UIButton){
        let currentCel = strip![queueCounter]
        if currentCel.isVideo{
            self.playerQueue!.pause();
            self.queuePlayerLayer?.removeFromSuperlayer();
            self.playerQueue = nil;
            self.queuePlayerLayer = nil;
        }
        queueCounter += 1
        playStrip()
    }
    
    @IBAction func rrwButtonPressed(){
        if (queueCounter == 0){
            return
        }
        let currentCel = strip![queueCounter]
        if currentCel.isVideo{
            self.playerQueue!.pause();
            self.queuePlayerLayer?.removeFromSuperlayer();
            self.playerQueue = nil;
            self.queuePlayerLayer = nil;
        }
        queueCounter -= 1
        playStrip()
    }
    
    @IBAction func backButtonPressed(){
        if self.playerQueue != nil {
            self.playerQueue?.pause()
            self.playerQueue!.removeAllItems()
            self.queuePlayerLayer?.removeFromSuperlayer()
            self.playerQueue = nil
        }
        if (self.imgView != nil) {
            self.imgView!.image = nil
            self.imgView!.removeFromSuperview()
        }
        navigationController?.popViewController(animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

