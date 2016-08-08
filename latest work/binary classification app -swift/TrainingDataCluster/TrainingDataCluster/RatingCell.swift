//
//  RatingCell.swift
//  Panda
//
//  Created by Xuefeng Peng on 04/08/2016.
//  Copyright © 2016 XFOffice. All rights reserved.
//

import UIKit
import StepSlider


class RatingCell: UITableViewCell {
    
    let steper = StepSlider()
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.detailTextLabel?.textAlignment = .Right
        self.detailTextLabel?.font = UIFont.systemFontOfSize(14)
        
        self.textLabel?.text = ""
        
        // add step slider to cell
        steper.maxCount = 4
        steper.frame = CGRectMake(10, 0, (2/3) * self.frame.width, self.frame.height)
        steper.tintColor = UIColor(red: 143/255.0, green: 179/255.0, blue: 247/255.0, alpha: 1)
        steper.sliderCircleRadius = 8
        steper.sliderCircleColor = UIColor.lightGrayColor()
        self.addSubview(steper)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
