//
//  CancelButton.swift
//  AR_Camera
//
//  Created by Justin Lee on 5/12/20.
//  Copyright © 2020 com.lee. All rights reserved.
//



import UIKit

class CancelButton : UIButton {
    
    private var label: UILabel = UILabel()
    
    init(){
        var resetButtonDimension: CGFloat = CGFloat()
        resetButtonDimension = screenWidth * 0.125
        
        var resetButtonMinY : CGFloat = CGFloat()
        resetButtonMinY = screenWidth * 0.125
        
        var minYLabelLine : CGFloat = CGFloat()
        minYLabelLine = screenHeight * 0.0625
        
        var buttonGap : CGFloat = CGFloat()
        buttonGap = screenWidth * 0.048
        
        super.init(frame: CGRect(x: buttonGap/2,
                                 y:resetButtonMinY,
                                 width: resetButtonDimension,
                                 height: resetButtonDimension))
        
        self.layer.cornerRadius = 6;
        
        self.label.attributedText = self.generateAttributedTitle(string: "X", size: 24)
        self.label.sizeToFit();
        self.label.frame = CGRect(x: 0,
                                  y: minYLabelLine - self.frame.minY,
                                  width: self.label.frame.width,
                                  height: self.label.frame.height)
        
        self.addSubview(self.label);

    }
    
    required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
    }
    
    func generateAttributedTitle(string:String, size:CGFloat) -> NSMutableAttributedString{
        return NSMutableAttributedString(string: string, attributes:  [NSAttributedString.Key.foregroundColor: UIColor.white,
                                                                       NSAttributedString.Key.font: UIFont(name: "Helvetica", size: size) as Any]);
    }
    
    
}

