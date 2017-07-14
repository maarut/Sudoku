//
//  SettingsViewController.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 16/06/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

class SettingsViewController: CardViewController
{
    
    weak var tipButton: UIButton!
    weak var tipText: UILabel!
    weak var feedbackButton: UIButton!
    weak var feedbackText: UILabel!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        view.backgroundColor = UIColor.lightGray
        
        let tipButton = UIButton()
        let tipText = UILabel()
        tipText.text = "Tip Text"
        tipText.frame.size = tipText.intrinsicContentSize
        tipText.frame.origin = CGPoint(x: 30, y: 30)
        let feedBackButton = UIButton()
        let feedBackText = UILabel()
        feedBackText.text = "Feedback Text"
        feedBackText.frame.size = feedBackText.intrinsicContentSize
        feedBackText.frame.origin = CGPoint(x: 30, y: 100)

        self.tipButton = tipButton
        self.tipText = tipText
        self.feedbackButton = feedBackButton
        self.feedbackText = feedBackText
        
        view.addSubview(tipText)
        view.addSubview(tipButton)
        view.addSubview(feedBackButton)
        view.addSubview(feedBackText)
        
        definesPresentationContext = true
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        tipButton = aDecoder.decodeObject(forKey: "tipButton") as? UIButton
        tipText = aDecoder.decodeObject(forKey: "tipText") as? UILabel
        feedbackButton = aDecoder.decodeObject(forKey: "feedbackButton") as? UIButton
        feedbackText = aDecoder.decodeObject(forKey: "feedbackText") as? UILabel
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder)
    {
        super.encode(with: aCoder)
        aCoder.encode(tipButton, forKey: "tipButton")
        aCoder.encode(tipText, forKey: "tipText")
        aCoder.encode(feedbackButton, forKey: "feedbackButton")
        aCoder.encode(feedbackText, forKey: "feedbackText")
    }
    
}
