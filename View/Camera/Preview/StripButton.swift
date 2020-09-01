//
//  SaveButton.swift
//  AR_Camera
//
//  Created by Justin Lee on 5/12/20.
//  Copyright © 2020 com.lee. All rights reserved.
//



import UIKit

class StripButton: UIButton {
    
    private var stripIcon: UIImageView = UIImageView()
    private var label: UILabel = UILabel()
    
    init(){
        var minYLabelLine : CGFloat = CGFloat()
        minYLabelLine = screenHeight * 0.0625
        
        var stripButtonDimension: CGFloat = CGFloat()
        stripButtonDimension = screenHeight/10
        
        super.init(frame: CGRect(x: (screenWidth-stripButtonDimension) + 10,
                                 y: screenHeight * 0.20,
                                 width: stripButtonDimension,
                                 height: stripButtonDimension))
        
        self.layer.cornerRadius = 6
        
        self.stripIcon.frame = CGRect(x: self.frame.height*0.25, y: self.frame.height*0.125, width: self.frame.height*0.5, height: self.frame.height*0.5);
        self.stripIcon.image = UIImage(named: "AddFrame");
        self.addSubview(self.stripIcon)
        
        self.label.attributedText = self.generateAttributedTitle(string: "Add to Strip", size: 12);
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

 
