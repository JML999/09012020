//
//  SaveToStripButton.swift
//  AR_Camera
//
//  Created by Justin Lee on 8/19/20.
//  Copyright © 2020 com.lee. All rights reserved.
//

import Foundation
import UIKit

class UploadButton: UIButton {
    
    private var saveIcon: UIImageView = UIImageView()
    private var label: UILabel = UILabel()
    
    init(){
        var saveButtonDimension: CGFloat = CGFloat()
        saveButtonDimension = screenHeight/8
        
        super.init(frame: CGRect(x: (screenWidth-saveButtonDimension) + 18,
                                 y: screenHeight * 0.20,
                                 width: saveButtonDimension,
                                 height: saveButtonDimension))
        
        self.layer.cornerRadius = 6
        
        self.saveIcon.frame = CGRect(x: self.frame.height*0.25, y: self.frame.height*0.125, width: self.frame.height*0.5, height: self.frame.height*0.5);
        self.saveIcon.image = UIImage(named: "upload");
        self.addSubview(self.saveIcon)
        
        self.label.attributedText = self.generateAttributedTitle(string: "Publish", size: 12);
        self.label.sizeToFit()
        self.label.textAlignment = .center;
        self.label.frame = CGRect(x: 0, y: self.frame.height*0.70, width: self.frame.width-5, height: self.label.frame.height);
        self.addSubview(self.label);
        
    }
    
    override init(frame: CGRect){
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
    }
    
    func generateAttributedTitle(string:String, size:CGFloat) -> NSMutableAttributedString{
        return NSMutableAttributedString(string: string, attributes:  [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Helvetica", size: size) as Any]);
    }
    
}
