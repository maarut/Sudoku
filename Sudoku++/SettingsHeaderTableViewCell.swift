//
//  SettingsHeaderTableViewCell.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 19/04/2018.
//  Copyright © 2018 Maarut Chandegra. All rights reserved.
//

import UIKit

class SettingsHeaderTableViewCell: UITableViewCell
{
    static let reuseIdentifier = "SettingsHeader"
    public let titleLabel: UILabel
    public let headerBar: UIView
    
    init()
    {
        titleLabel = UILabel()
        headerBar = UIView()
        super.init(style: .default, reuseIdentifier: SettingsHeaderTableViewCell.reuseIdentifier)
        initialise()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        titleLabel = UILabel()
        headerBar = UIView()
        super.init(style: .default, reuseIdentifier: SettingsHeaderTableViewCell.reuseIdentifier)
        initialise()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        titleLabel = aDecoder.decodeObject(forKey: "titleLabel") as! UILabel
        headerBar =  aDecoder.decodeObject(forKey: "headerBar") as! UIView
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(titleLabel, forKey: "titleLabel")
        aCoder.encode(headerBar, forKey: "headerBar")
    }
    
    private func initialise()
    {
        headerBar.backgroundColor = .black

        headerBar.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(headerBar)
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: headerBar.topAnchor),
            headerBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            headerBar.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            headerBar.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            headerBar.heightAnchor.constraint(equalToConstant: 10)
        ])
        contentView.setNeedsLayout()
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }

    

}
