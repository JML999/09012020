
import UIKit

class StopMotionButton: UIButton {
    
    private var addIcon: UIImageView = UIImageView()
    
    init(){
        var stopMotionButtonDimension: CGFloat = CGFloat()
        stopMotionButtonDimension = screenHeight/6
        
        super.init(frame: CGRect(x: (screenWidth-stopMotionButtonDimension) / 2,
                                 y: screenHeight * 0.7325,
                                 width: stopMotionButtonDimension,
                                 height: stopMotionButtonDimension))
        
        self.layer.cornerRadius = 6
        
        self.addIcon.frame = CGRect(x: self.frame.height*0.25, y: self.frame.height*0.125, width: self.frame.height*0.5, height: self.frame.height*0.5);
        self.addIcon.image = UIImage(named: "StopMotionAdd");
        self.addSubview(self.addIcon)
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

 
