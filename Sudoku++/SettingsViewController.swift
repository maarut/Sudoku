//
//  SettingsViewController.swift
//  Screen that shows the tip text, ratings text, about information, and help tutorial
//  Sudoku++
//
//  Created by Maarut Chandegra on 16/06/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

class SettingsViewController: CardViewController
{
    weak var tableView: UITableView!
    fileprivate var startPanGestureOffset: CGFloat = 0.0
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        view.backgroundColor = UIColor.lightGray
        
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.allowsSelection = false
        tableView.backgroundColor = .white
        self.tableView = tableView
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        NSLayoutConstraint.activate([
            tableView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0),
            tableView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.95),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0.0)
        ])
        view.setNeedsLayout()
        definesPresentationContext = true
        tableView.panGestureRecognizer.addTarget(self, action: #selector(panRecognised(_:)))
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        tableView = aDecoder.decodeObject(forKey: "tableView") as? UITableView
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder)
    {
        super.encode(with: aCoder)
        aCoder.encode(tableView, forKey: "tableView")
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        let contentSize = tableView.contentSize
        tableView.isScrollEnabled = contentSize.height > tableView.frame.height
    }
}

extension SettingsViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell: UITableViewCell = UITableViewCell()
        /*if indexPath.row == 0 {
            let headerCell: SettingsHeaderTableViewCell
            if let c = tableView.dequeueReusableCell(
                withIdentifier: SettingsHeaderTableViewCell.reuseIdentifier) as? SettingsHeaderTableViewCell {
                headerCell = c
            }
            else {
                headerCell = SettingsHeaderTableViewCell()
            }
            headerCell.titleLabel.text = "Hello \(indexPath.section)"
            cell = headerCell
        }
        else {
            if let c = tableView.dequeueReusableCell(withIdentifier: "first") {
                cell = c
            }
            else {
                cell = UITableViewCell(style: .default, reuseIdentifier: "first")
            }
            cell.textLabel?.text = "\(indexPath.section) \(indexPath.row)"
        }*/
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 5
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String?
    {
        switch section {
        case 2:
            return """
            Found a bug? Need support? Please send an email.
            
            I read all emails, but am only able to respond to a handful. Please bare with me if you don't hear back \
            straight away.
            """
        case 3:
            return """
            Sudoku++ relies on your support for continued development.
            
            If this app tickles your brain and you have fun solving puzzles, please consider leaving a small tip. \
            I would really appreciate it.
            
            Any tip given will also remove ads from the app.
            
            Thanks
            """
        case 4:
            return """
            If you enjoy using this app, please take some time to leave a review on the App Store. \
            It really helps others find the app.
            """
        default:
            return "\(section) - Footer"
        }
    }
}

extension SettingsViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let headerCell = SettingsHeaderTableViewCell()
        headerCell.titleLabel.text = "Hello \(section)"
        headerCell.headerBar.backgroundColor = .blue
        return headerCell
    }
}

// MARK: - Action Handlers
extension SettingsViewController
{
    @objc func panRecognised(_ gestureRecogniser: UIPanGestureRecognizer)
    {
        let translation = gestureRecogniser.translation(in: view)
        switch gestureRecogniser.state {
        case .began:
            if tableView.contentOffset.y <= 0 {
                tableView.setContentOffset(.zero, animated: false)
                startPanGestureOffset = translation.y
                updateInteractionDismissal(state: .began, translation: translation)
            }
            break
        case .changed:
            if (tableView.contentOffset.y <= 0) || (view.frame.origin.y >= 0 && isBeingDismissed) {
                if startPanGestureOffset == 0 { startPanGestureOffset = translation.y }
                tableView.setContentOffset(.zero, animated: false)
                updateInteractionDismissal(state: .changed,
                                           translation: CGPoint(x: translation.x,
                                                                y: translation.y - startPanGestureOffset))
            }
            else {
                startPanGestureOffset = 0.0
                updateInteractionDismissal(state: .cancelled, translation: .zero)
            }
            break
        case .ended:
            startPanGestureOffset = 0.0
            updateInteractionDismissal(state: .ended, translation: .zero)
            break
        case .cancelled:
            startPanGestureOffset = 0.0
            updateInteractionDismissal(state: .cancelled, translation: .zero)
            break
        default:
            break
        }
    }
}
