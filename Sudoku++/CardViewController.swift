//
//  CardViewController.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 21/06/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

protocol CardViewControllerDelegate: NSObjectProtocol
{
    func didSelectDismiss(_ cardViewController: CardViewController)
}

open class CardViewController: UIViewController
{
    override open var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    weak var delegate: CardViewControllerDelegate?
    var roundedCorners: UIRectCorner = [.topLeft, .topRight] {
        didSet {
            guard let view = view as? RoundedRectView else {
                fatalError("CardViewController constructed incorrectly")
            }
            view.roundedCorners = roundedCorners
        }
    }
    
    private weak var dismissButton: UIButton!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("﹀", for: .normal)
        dismissButton.setTitleColor(UIColor.black.withAlphaComponent(0.75), for: .normal)
        dismissButton.frame.size = dismissButton.intrinsicContentSize
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.addTarget(self, action: #selector(dismissTapped(_:)), for: .touchUpInside)
        self.dismissButton = dismissButton
        view.addSubview(dismissButton)
        NSLayoutConstraint.activate([
            dismissButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dismissButton.topAnchor.constraint(equalTo: view.topAnchor)
            ])
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        delegate = aDecoder.decodeObject(forKey: "delegate") as? CardViewControllerDelegate
        dismissButton = aDecoder.decodeObject(forKey: "dismissButton") as? UIButton
        super.init(coder: aDecoder)
    }
    
    override open func encode(with aCoder: NSCoder)
    {
        super.encode(with: aCoder)
        aCoder.encode(delegate, forKey: "delegate")
        aCoder.encode(dismissButton, forKey: "dismissButton")
    }
    
    /// Do not override this method! The visuals will be affected.
    override open func loadView()
    {
        let view = RoundedRectView()
        view.roundedCorners = roundedCorners
        self.view = view
    }
    
    override open func viewDidLoad()
    {
        super.viewDidLoad()
        modalPresentationCapturesStatusBarAppearance = true
    }
    
    override open func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        delegate?.didSelectDismiss(self)
        
    }
    
    func dismissTapped(_ sender: UIButton)
    {
        dismiss(animated: true, completion: nil)
        delegate?.didSelectDismiss(self)
    }
}
