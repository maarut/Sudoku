//
//  RatingRequestTableViewCell.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 19/04/2018.
//  Copyright © 2018 Maarut Chandegra. All rights reserved.
//

import UIKit

class RatingRequestTableViewCell: UITableViewCell
{
    static let reuseIdentifier = "ratings"
    
    init()
    {
        super.init(style: .default, reuseIdentifier: RatingRequestTableViewCell.reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
