//
//  ViewController.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 03/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit
import GoogleMobileAds

private let order = 3

private let MARGIN: CGFloat = 16
private let MAX_SUDOKU_VIEW_SIZE: CGFloat = 512
private let TABBAR_HEIGHT: CGFloat = 44
fileprivate func convertNumberToString(_ number: Int) -> String
{
    return number < 10 ? "\(number)" : "\(Character(UnicodeScalar(55 + number)!))"
}

private class MarkupButtonMenuStateMachine
{
    private let lock = NSLock()
    private var shouldShowRevealSolution = false
    private var timer: Timer?
    private var completionTimer: Timer?
    
    func startPress(usingLongPressInterval interval: TimeInterval = 0.5,
        afterTotalDurationForPress duration: TimeInterval = 1.0,
        call block: @escaping () -> Void = {})
    {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: { _ in
            self.lock.lock()
            self.shouldShowRevealSolution = true
            self.lock.unlock()
            self.timer = nil
        })
        completionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { _ in
            self.timer?.invalidate()
            self.timer = nil
            self.lock.lock()
            self.shouldShowRevealSolution = false
            self.lock.unlock()
            block()
        })
    }
    
    func endPress() -> Bool
    {
        timer?.invalidate()
        timer = nil
        completionTimer?.invalidate()
        completionTimer = nil
        lock.lock()
        let shouldShowMenu = shouldShowRevealSolution
        shouldShowRevealSolution = false
        lock.unlock()
        return shouldShowMenu
    }
    
    func cancel()
    {
        timer?.invalidate()
        timer = nil
        completionTimer?.invalidate()
        completionTimer = nil
        lock.lock()
        shouldShowRevealSolution = false
        lock.unlock()
    }
}

class MainViewController: UIViewController
{
    fileprivate let markupButtonStateMachine = MarkupButtonMenuStateMachine()
    weak var viewModel: MainViewModel! {
        didSet {
            viewModel.delegate = self
            viewModel.sendState()
        }
    }
    
    weak var sudokuView: SudokuView!
    weak var numberSelectionView: NumberSelectionView!
    weak var pencilSelectionView: NumberSelectionView!
    weak var tabBar: UIView!
    weak var newGameButton: UIButton!
    weak var undoButton: UIButton!
    weak var markupButton: UIButton!
    weak var settingsButton: UIButton!
    weak var clearCellButton: HighlightableButton!
    weak var timerLabel: UILabel!
    weak var difficultyLabel: UILabel!
    weak var startButton: UIButton!
    weak var adBanner: GADBannerView!
    
    convenience init(withViewModel viewModel: MainViewModel)
    {
        self.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUpSubviews()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        sudokuView = aDecoder.decodeObject(forKey: "sudokuView") as? SudokuView
        numberSelectionView = aDecoder.decodeObject(forKey: "numberSelectionView") as? NumberSelectionView
        pencilSelectionView = aDecoder.decodeObject(forKey: "pencilSelectionView") as? NumberSelectionView
        tabBar = aDecoder.decodeObject(forKey: "tabBar") as? UIView
        newGameButton = aDecoder.decodeObject(forKey: "newGameButton") as? UIButton
        undoButton = aDecoder.decodeObject(forKey: "undoButton") as? UIButton
        markupButton = aDecoder.decodeObject(forKey: "markupButton") as? UIButton
        settingsButton = aDecoder.decodeObject(forKey: "settingsButton") as? UIButton
        clearCellButton = aDecoder.decodeObject(forKey: "clearCellButton") as? HighlightableButton
        timerLabel = aDecoder.decodeObject(forKey: "timerLabel") as? UILabel
        difficultyLabel = aDecoder.decodeObject(forKey: "difficultyLabel") as? UILabel
        startButton = aDecoder.decodeObject(forKey: "startButton") as? UIButton
        adBanner = aDecoder.decodeObject(forKey: "adBanner") as? GADBannerView

        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder)
    {
        super.encode(with: aCoder)
        aCoder.encode(sudokuView, forKey: "sudokuView")
        aCoder.encode(numberSelectionView, forKey: "numberSelectionView")
        aCoder.encode(pencilSelectionView, forKey: "pencilSelectionView")
        aCoder.encode(tabBar, forKey: "tabBar")
        aCoder.encode(newGameButton, forKey: "newGameButton")
        aCoder.encode(undoButton, forKey: "undoButton")
        aCoder.encode(markupButton, forKey: "markupButton")
        aCoder.encode(settingsButton, forKey: "settingsButton")
        aCoder.encode(clearCellButton, forKey: "clearCellButton")
        aCoder.encode(timerLabel, forKey: "timerLabel")
        aCoder.encode(difficultyLabel, forKey: "difficultyLabel")
        aCoder.encode(startButton, forKey: "startButton")
        aCoder.encode(adBanner, forKey: "adBanner")
    }
    
    override func loadView()
    {
        view = UIView()
        view.backgroundColor = UIColor.white
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        numberSelectionView.delegate = self
        pencilSelectionView.delegate = self
        sudokuView.delegate = self
        adBanner.adUnitID = kAdMobAdUnitId
        adBanner.delegate = self
        adBanner.rootViewController = self
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        viewModel.startTimer()
        requestAds()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        viewModel.stopTimer()
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        layoutSubviews()
    }
}

// MARK: - Private Functions
fileprivate extension MainViewController
{
    func setUpSubviews()
    {
        let titles = (1 ... order * order).map( { convertNumberToString($0) } )
        let sudokuView = SudokuView(frame: CGRect.zero, order: order, pencilMarkTitles: titles)
        let numberSelectionView = NumberSelectionView(frame: CGRect.zero, order: order, buttonTitles: titles,
            displayLargeNumbers: true, accessibilityLabel: "Number toggle")
        let pencilSelectionView = NumberSelectionView(frame: CGRect.zero, order: order, buttonTitles: titles,
            displayLargeNumbers: false, accessibilityLabel: "Pencil mark toggle")
        let tabBar = UIView()
        let difficultyLabel = UILabel()
        difficultyLabel.text = "Multiple Solutions"
        difficultyLabel.textAlignment = .center
        difficultyLabel.frame.size = difficultyLabel.intrinsicContentSize
        difficultyLabel.frame.size.height *= 1.2
        difficultyLabel.frame.size.width *= 1.2
        difficultyLabel.text = ""
        difficultyLabel.accessibilityLabel = "Puzzle Difficulty"
        difficultyLabel.accessibilityHint = "The difficulty of the current puzzle"
        difficultyLabel.accessibilityValue = "Blank"
        let timerLabel = UILabel()
        timerLabel.text = "00:00:00"
        timerLabel.textAlignment = .center
        timerLabel.frame.size = timerLabel.intrinsicContentSize
        timerLabel.frame.size.height *= 1.2
        timerLabel.frame.size.width *= 1.2
        timerLabel.text = "00:00"
        timerLabel.accessibilityLabel = "Elapsed time"
        let newGameButton = UIButton(type: .system)
        newGameButton.setTitle("🌟", for: .normal)
        newGameButton.frame.size = newGameButton.intrinsicContentSize
        newGameButton.addTarget(self, action: #selector(newGameButtonTapped(_:)), for: .touchUpInside)
        newGameButton.accessibilityLabel = "New game button"
        newGameButton.accessibilityHint = "Starts a new game"
        let undoButton = UIButton(type: .system)
        undoButton.setTitle("⏮", for: .normal)
        undoButton.titleLabel?.textAlignment = .center
        undoButton.frame.size = undoButton.intrinsicContentSize
        undoButton.addTarget(self, action: #selector(undoTapped(_:)), for: .touchUpInside)
        undoButton.accessibilityLabel = "Undo button"
        undoButton.accessibilityHint = "Undoes the previous action"
        undoButton.accessibilityTraits = UIAccessibilityTraits.notEnabled
        let markupButton = UIButton(type: .system)
        markupButton.setTitle("✏️", for: .normal)
        markupButton.titleLabel?.textAlignment = .center
        markupButton.frame.size = markupButton.intrinsicContentSize
        markupButton.addTarget(self, action: #selector(markupButtonTouchUp(_:)), for: .touchUpInside)
        markupButton.addTarget(self, action: #selector(markupButtonDragOutside(_:)), for: .touchDragExit)
        markupButton.addTarget(self, action: #selector(markupButtonTouchDown(_:forEvent:)),
            for: [.touchDown, .touchDragEnter])
        markupButton.layer.transform = CATransform3DRotate(CATransform3DIdentity, CGFloat.pi, 0.0, 1.0, 0.0)
        markupButton.accessibilityLabel = "Fill pencilmarks button"
        markupButton.accessibilityHint = "Add pencil marks to unfilled cells"
        let settingsButton = UIButton(type: .system)
        settingsButton.setTitle("⚙", for: .normal)
        settingsButton.titleLabel?.textAlignment = .center
        settingsButton.frame.size = settingsButton.intrinsicContentSize
        settingsButton.addTarget(self, action: #selector(settingsTapped(_:)), for: .touchUpInside)
        settingsButton.accessibilityLabel = "Settings button"
        settingsButton.accessibilityHint = "Opens the settings screen"
        let clearCellButton = HighlightableButton()
        clearCellButton.setTitle("✕", for: .normal)
        clearCellButton.titleLabel?.textAlignment = .center
        clearCellButton.frame.size = clearCellButton.intrinsicContentSize
        clearCellButton.frame.size.width = clearCellButton.frame.height
        clearCellButton.addTarget(self, action: #selector(clearButtonTouchUpInside(_:)), for: .touchUpInside)
        clearCellButton.addTarget(self, action: #selector(clearButtonDragExit(_:)),
            for: [.touchDragExit, .touchUpOutside])
        clearCellButton.addTarget(self, action: #selector(clearButtonTouchDown(_:)), for: .touchDown)
        clearCellButton.accessibilityLabel = "Clear cell button"
        clearCellButton.accessibilityHint = "Clears the contents of an editable cell"
        
        let startButton = UIButton(type: .system)
        startButton.setTitle("Start", for: .normal)
        startButton.frame.size = startButton.intrinsicContentSize
        startButton.addTarget(self, action: #selector(startButtonTapped(_:)), for: .touchUpInside)
        startButton.isHidden = true
        startButton.accessibilityHint = "Sets the puzzle and starts the game"
        
        let adBanner = GADBannerView(adSize: kGADAdSizeBanner)
        
        tabBar.addSubview(newGameButton)
        tabBar.addSubview(undoButton)
        tabBar.addSubview(markupButton)
        tabBar.addSubview(settingsButton)
        tabBar.layoutIfNeeded()
        
        self.sudokuView = sudokuView
        self.numberSelectionView = numberSelectionView
        self.pencilSelectionView = pencilSelectionView
        self.tabBar = tabBar
        self.newGameButton = newGameButton
        self.undoButton = undoButton
        self.markupButton = markupButton
        self.settingsButton = settingsButton
        self.clearCellButton = clearCellButton
        self.timerLabel = timerLabel
        self.difficultyLabel = difficultyLabel
        self.startButton = startButton
        self.adBanner = adBanner
        view.addSubview(numberSelectionView)
        view.addSubview(pencilSelectionView)
        view.addSubview(sudokuView)
        view.addSubview(tabBar)
        view.addSubview(clearCellButton)
        view.addSubview(timerLabel)
        view.addSubview(difficultyLabel)
        view.addSubview(startButton)
        view.addSubview(adBanner)
    }
    
    func showRevealSolutionMenu(near sender: UIView)
    {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Reveal Solution", style: .default, handler: { _ in
            self.viewModel.revealSolution()
        }))
        alertController.addAction(UIAlertAction(title: "Fill Pencil Marks", style: .default, handler: { _ in
            self.viewModel.fillInPencilMarks()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alertController.popoverPresentationController?.sourceView = sender
        alertController.popoverPresentationController?.sourceRect = sender.bounds
        present(alertController, animated: true)
    }
    
    func requestAds()
    {
        let request = GADRequest()
        request.testDevices = MCConstants.adMobTestDevices()
        adBanner.load(request)
    }
}

// MARK: - Event Handlers
extension MainViewController
{
    @objc func newGameButtonTapped(_ sender: UIButton)
    {
        let difficulties = viewModel.newGameDifficulties
        let alertController = UIAlertController(title: "New Game",
            message: "Select a difficulty for the new game", preferredStyle: .actionSheet)
        for difficulty in difficulties {
            let action = UIAlertAction(title: difficulty.displayableText, style: .default, handler: {
                self.viewModel.newGame(withTitle: $0.title ?? "")
            })
            action.accessibilityLabel = difficulty.accessibleText
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = sender
        alertController.popoverPresentationController?.sourceRect = sender.bounds
        alertController.accessibilityLabel = "New game menu"
        alertController.accessibilityHint = "Select a difficulty to start a new game of that difficulty"
        present(alertController, animated: true)
    }
    
    @objc func undoTapped(_ sender: UIButton)
    {
        viewModel.undo()
    }
    
    @objc func startButtonTapped(_ sender: UIButton)
    {
        viewModel.setPuzzle()
    }
    
    @objc func markupButtonTouchDown(_ sender: UIButton, forEvent event: UIEvent)
    {
        markupButtonStateMachine.startPress(call: {
            sender.cancelTracking(with: event)
            self.showRevealSolutionMenu(near: sender)
        })
    }
    
    @objc func markupButtonDragOutside(_ sender: UIButton)
    {
        markupButtonStateMachine.cancel()
    }
    
    @objc func markupButtonTouchUp(_ sender: UIButton)
    {
        if markupButtonStateMachine.endPress() {
            showRevealSolutionMenu(near: sender)
        }
        else {
            viewModel.fillInPencilMarks()
        }
    }
    
    @objc func settingsTapped(_ sender: UIButton)
    {
        let vc = SettingsViewController()
        vc.delegate = self
        present(vc, animated: true, completion: nil)
        viewModel.stopTimer()
    }
    
    @objc func clearButtonDragExit(_ sender: HighlightableButton)
    {
        viewModel.selectClear(event: .release)
    }
    
    @objc func clearButtonTouchDown(_ sender: HighlightableButton)
    {
        viewModel.selectClear(event: .press)
    }
    
    @objc func clearButtonTouchUpInside(_ sender: HighlightableButton)
    {
        viewModel.selectClear(event: .releaseActivate)
    }
}

// MARK: - SudokuViewDelegate Implementation
extension MainViewController: SudokuViewDelegate
{
    func sudokuView(_ view: SudokuView, didSelectCellAt index: (row: Int, column: Int))
    {
        viewModel.selectCell(atIndex: SudokuBoardIndex(row: index.row, column: index.column))
    }
}

// MARK: - NumberSelectionViewDelegate Implementation
extension MainViewController: NumberSelectionViewDelegate
{
    func numberSelectionView(_ view: NumberSelectionView, didSelect number: Int)
    {
        switch view {
        case numberSelectionView:   viewModel.selectNumber(number, event: .releaseActivate)
        case pencilSelectionView:   viewModel.selectPencilMark(number, event: .releaseActivate)
        default:                    break
        }
    }
}

// MARK: -  CardViewControllerDelegate Implementation
extension MainViewController: CardViewControllerDelegate
{
    func didSelectDismiss(_ cardViewController: CardViewController)
    {
        viewModel.startTimer()
    }
}

// MARK: - Layout Functions
fileprivate extension MainViewController
{
    func resizeUsing(sudokuHeight: CGFloat)
    {
        if sudokuHeight == sudokuView.frame.height { return }
        let selectionHeight = sudokuHeight / 2.75
        let clearButtonHeight = selectionHeight * 0.3
        sudokuView.frame = CGRect(x: 0, y: 0, width: sudokuHeight, height: sudokuHeight)
        numberSelectionView.frame = CGRect(x: 0, y: 0, width: selectionHeight, height: selectionHeight)
        pencilSelectionView.frame = CGRect(x: 0, y: 0, width: selectionHeight, height: selectionHeight)
        clearCellButton.frame = CGRect(x: 0, y: 0, width: clearButtonHeight, height: clearButtonHeight)
        clearCellButton.titleLabel?.font = clearCellButton.titleLabel?.font.withSize(clearButtonHeight * 0.6)
    }
    
    func resizeForPortrait()
    {
        let availableHeight = view.frame.height - statusBarHeight() - safetyArea.bottom - TABBAR_HEIGHT -
            adBanner.frame.height - difficultyLabel.frame.height - timerLabel.frame.height - MARGIN * 2
        let availableWidth = view.frame.width - MARGIN * 2
        var sudokuHeight = min(MAX_SUDOKU_VIEW_SIZE, (availableHeight * 11 / 15))
        if sudokuHeight > availableWidth { sudokuHeight = availableWidth }
        resizeUsing(sudokuHeight: sudokuHeight)
    }
    
    func resizeForLandscape()
    {
        let availableHeight = view.frame.height - statusBarHeight() - safetyArea.bottom - adBanner.frame.height -
            MARGIN * 2
        let sudokuHeight = min(MAX_SUDOKU_VIEW_SIZE, availableHeight)
        resizeUsing(sudokuHeight: sudokuHeight)
    }
    
    func layoutSubviews()
    {
        UIView.animate(withDuration: 0.25) {
            if self.view.frame.height > self.view.frame.width { self.setLayoutPortrait(); return }
            switch UIApplication.shared.statusBarOrientation {
            case .portrait, .portraitUpsideDown:    self.setLayoutPortrait()
            case .landscapeLeft:                    self.setLayoutLandscapeRight()
            case .landscapeRight:                   self.setLayoutLandscapeLeft()
            case .unknown:                          self.setLayoutUnknown()
            }
        }
    }
    
    func setLayoutPortrait()
    {
        resizeForPortrait()
        let buttonCount = CGFloat(tabBar.subviews.count)
        let midX = view.frame.width / 2
        adBanner.center.x = midX
        adBanner.frame.origin.y = statusBarHeight()
        tabBar.frame = CGRect(x: 0, y: view.frame.height - TABBAR_HEIGHT - safetyArea.bottom,
            width: view.frame.width, height: TABBAR_HEIGHT)
        let buttonSpacing = tabBar.frame.width / (buttonCount * 2)
        for (i, button) in [newGameButton, undoButton, markupButton, settingsButton].enumerated() {
            button?.center = CGPoint(x: CGFloat(i * 2 + 1) * buttonSpacing, y: 22)
        }
        
        timerLabel.center = CGPoint(x: midX, y: tabBar.frame.origin.y - timerLabel.frame.height / 2)
        startButton.center = timerLabel.center
        difficultyLabel.center = CGPoint(x: midX,
            y: timerLabel.frame.origin.y - difficultyLabel.frame.height / 2)
        
        let selectionYCenter = difficultyLabel.frame.origin.y - numberSelectionView.frame.height / 2
        numberSelectionView.center.y = selectionYCenter
        pencilSelectionView.center.y = selectionYCenter
        clearCellButton.center = CGPoint(x: midX, y: selectionYCenter)
        
        sudokuView.center = CGPoint(x: midX,
            y: numberSelectionView.frame.origin.y - MARGIN - sudokuView.frame.height / 2)
        let gap = sudokuView.frame.origin.y - (adBanner.frame.origin.y + adBanner.frame.height)
        sudokuView.frame.origin.y = adBanner.frame.origin.y + adBanner.frame.height + gap * 2 / 3
        numberSelectionView.frame.origin.x = sudokuView.frame.origin.x
        pencilSelectionView.frame.origin.x =
            sudokuView.frame.origin.x + sudokuView.frame.width - pencilSelectionView.frame.width
        
    }
    
    func setLayoutLandscapeLeft()
    {
        resizeForLandscape()
        let buttonCount = CGFloat(tabBar.subviews.count)
        let yOrigin = statusBarHeight() - view.frame.origin.y
        let yCenter = yOrigin + TABBAR_HEIGHT + (view.frame.height - yOrigin - TABBAR_HEIGHT - safetyArea.bottom) / 2
        adBanner.frame.origin.y = statusBarHeight()
        adBanner.center.x = view.frame.width / 2
        sudokuView.center = CGPoint(x: MARGIN + sudokuView.frame.width / 2 + safetyArea.left, y: yCenter)
        tabBar.frame = CGRect(x: view.frame.width - TABBAR_HEIGHT, y: 0,
            width: TABBAR_HEIGHT, height: view.frame.height)
        let buttonSpacing = tabBar.frame.height / (buttonCount * 2)
        for (i, button) in [newGameButton, undoButton, markupButton, settingsButton].enumerated() {
            button?.center = CGPoint(x: 22, y: CGFloat(i * 2 + 1) * buttonSpacing)
        }
        let height = numberSelectionView.frame.height
        let endOfSudokuFrame = sudokuView.frame.origin.x + sudokuView.frame.width
        let beginningOfToolbar = tabBar.frame.origin.x
        let midX = endOfSudokuFrame + ((beginningOfToolbar - endOfSudokuFrame) / 2)
        numberSelectionView.center = CGPoint(x: midX, y: sudokuView.frame.origin.y + height / 2)
        pencilSelectionView.center = CGPoint(x: midX,
            y: sudokuView.frame.origin.y + sudokuView.frame.height - height / 2)
        clearCellButton.center = CGPoint(x: midX, y: yCenter)
        timerLabel.center.y = yCenter + (timerLabel.frame.height / 2)
        timerLabel.frame.origin.x = beginningOfToolbar - timerLabel.frame.width - MARGIN
        difficultyLabel.center.y = yCenter - (difficultyLabel.frame.height / 2)
        difficultyLabel.center.x = timerLabel.center.x
        startButton.center = timerLabel.center
    }
    
    func setLayoutLandscapeRight()
    {
        resizeForLandscape()
        let buttonCount = CGFloat(tabBar.subviews.count)
        let sudokuViewXCenter = view.frame.width - MARGIN - safetyArea.right - sudokuView.frame.width / 2
        let yOrigin = statusBarHeight() - view.frame.origin.y
        let yCenter = yOrigin + TABBAR_HEIGHT + (view.frame.height - safetyArea.bottom - yOrigin - TABBAR_HEIGHT) / 2
        adBanner.frame.origin.y = statusBarHeight()
        adBanner.center.x = view.frame.width / 2
        sudokuView.center = CGPoint(x: sudokuViewXCenter, y: yCenter)
        tabBar.frame = CGRect(x: 0, y: 0, width: 44, height: view.frame.height)
        let buttonSpacing = tabBar.frame.height / (buttonCount * 2)
        for (i, button) in [newGameButton, undoButton, markupButton, settingsButton].enumerated() {
            button?.center = CGPoint(x: 22, y: CGFloat(i * 2 + 1) * buttonSpacing)
        }
        let height = numberSelectionView.frame.height
        let beginningOfSudokuFrame = sudokuView.frame.origin.x
        let endOfToolbar = tabBar.frame.width
        let midX = endOfToolbar + ((beginningOfSudokuFrame - endOfToolbar) / 2)
        numberSelectionView.center = CGPoint(x: midX, y: sudokuView.frame.origin.y + height / 2)
        pencilSelectionView.center = CGPoint(x: midX,
            y: sudokuView.frame.origin.y + sudokuView.frame.height - height / 2)
        clearCellButton.center = CGPoint(x: midX, y: yCenter)
        timerLabel.center.y = yCenter + (timerLabel.frame.height / 2)
        timerLabel.frame.origin.x = endOfToolbar + MARGIN
        difficultyLabel.center.y = yCenter - (difficultyLabel.frame.height / 2)
        difficultyLabel.center.x = timerLabel.center.x
        startButton.center = timerLabel.center
    }
    
    func setLayoutUnknown()
    {
        let width = view.frame.width
        let height = view.frame.height
        if width > height { setLayoutLandscapeLeft() }
        else { setLayoutPortrait() }
    }
    
    func showPuzzleSetError(_ error: String)
    {
        let title = "Set puzzle failed"
        let alertController = UIAlertController(title: title, message: error, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alertController, animated: true)
    }
}

// MARK: - MainViewModelDelegate Implementation
extension MainViewController: MainViewModelDelegate
{
    func newGameStarted(
        newState: [(index: SudokuBoardIndex, state: SudokuCellState, number: String, pencilMarks: [Int])])
    {
        DispatchQueue.main.async {
            for (index, state, number, pencilMarks) in newState {
                let newState: CellViewState
                switch state {
                case .editable: newState = .editable
                case .given:    newState = .given
                }
                let cell = self.sudokuView.cellAt(tupleRepresentation(index))!
                
                cell.flipTo(number: number, newState: newState,
                    showingPencilMarksAtPositions: pencilMarks.map( { $0 - 1 } ))
            }
            
            self.timerLabel.accessibilityTraits = UIAccessibilityTraits.updatesFrequently
        }
    }
    
    func difficultyTextDidChange(_ newText: String, accessibleText: String)
    {
        DispatchQueue.main.async {
            self.difficultyLabel.text = newText
            self.difficultyLabel.accessibilityValue = accessibleText
        }
    }
    
    func setPuzzleStateChanged(_ state: SetPuzzleState)
    {
        DispatchQueue.main.async {
            switch state {
            case .isSet:
                if !self.startButton.isHidden {
                    self.startButton.isHidden = true
                    self.timerLabel.isHidden = false
                    self.viewModel.startTimer()
                }
                break
            case .canSet:
                if self.startButton.isHidden {
                    self.startButton.isHidden = false
                    self.timerLabel.isHidden = true
                }
                break
            case .failed(let error):
                self.showPuzzleSetError(error)
                break
            }
            
        }
    }
    
    func gameStateChanged(_ newState: GameState)
    {
        switch newState {
        case .playing:
            sudokuView.isUserInteractionEnabled = true
            timerLabel.accessibilityTraits = UIAccessibilityTraits.updatesFrequently
            break
        case .finished:
            sudokuView.isUserInteractionEnabled = false
            timerLabel.accessibilityTraits = UIAccessibilityTraits.staticText
            break
        case .successfullySolved:
            timerLabel.accessibilityTraits = UIAccessibilityTraits.staticText
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.sudokuView.gameEnded()
            }
            break
        }
    }
    
    func undoStateChanged(_ canUndo: Bool)
    {
        DispatchQueue.main.async {
            self.undoButton.isEnabled = canUndo
            self.undoButton.setTitle(canUndo ? "⏮" : "", for: .normal)
            self.undoButton.accessibilityTraits = canUndo ? UIAccessibilityTraits.button : UIAccessibilityTraits.notEnabled
        }
    }
    
    func timerTextDidChange(_ text: String)
    {
        DispatchQueue.main.async {
            self.timerLabel.text = text
            self.timerLabel.accessibilityLabel =  "Elapsed time \(text)"
        }
    }
    
    func numberSelection(newState state: ButtonState, forNumber number: Int?)
    {
        DispatchQueue.main.async {
            switch number {
            case .some(let n):
                switch state {
                case .highlighted, .selected: self.numberSelectionView.select(number: n)
                case .normal:                 self.numberSelectionView.clearSelection()
                }
                break
            case .none:
                self.numberSelectionView.clearSelection()
                break
            }
        }
    }
    
    func pencilMarkSelection(newState state: ButtonState, forNumber number: Int?)
    {
        DispatchQueue.main.async {
            switch number {
            case .some(let n):
                switch state {
                case .highlighted, .selected: self.pencilSelectionView.select(number: n)
                case .normal:                 self.pencilSelectionView.clearSelection()
                }
                break
            case .none:
                self.pencilSelectionView.clearSelection()
                break
            }
        }
    }
    
    func clearButton(newState state: ButtonState)
    {
        DispatchQueue.main.async {
            switch state {
            case .highlighted:  self.clearCellButton.highlight()
            case .selected:     self.clearCellButton.select()
            case .normal:       self.clearCellButton.reset()
            }
        }
    }
    
    func removeHighlights()
    {
        DispatchQueue.main.async {
            for row in 0 ..< self.sudokuView.dimensionality {
                for column in 0 ..< self.sudokuView.dimensionality {
                    let cellView = self.sudokuView.cellAt((row: row, column: column))!
                    cellView.deselect()
                }
            }
            self.clearCellButton.reset()
            self.numberSelectionView.clearSelection()
            self.pencilSelectionView.clearSelection()
        }
    }
    
    func sudokuCells(atIndexes indexes: [SudokuBoardIndex], newState state: ButtonState)
    {
        let idxs = indexes.map { tupleRepresentation($0) }
        DispatchQueue.main.async {
            switch state {
            case .normal:                   for index in idxs { self.sudokuView.cellAt(index)!.deselect() }
            case .selected, .highlighted:   for index in idxs { self.sudokuView.cellAt(index)!.select() }
            }
        }
    }
    
    func sudokuCells(atIndexes indexes: [SudokuBoardIndex], newState state: SudokuCellState)
    {
        DispatchQueue.main.async {
            for i in indexes {
                let cell = self.sudokuView.cellAt((i.row, i.column))!
                switch state {
                case .given:
                    cell.state = .given
                    cell.textColour = UIColor.black
                    cell.highlightedCellBackgroundColour = UIColor.white
                    cell.highlightedCellTextColour = UIColor.red
                    cell.highlightedCellBorderColour = UIColor.red
                    cell.setNeedsDisplay()
                    break
                case .editable:
                    cell.state = .editable
                    cell.textColour = UIColor.black
                    cell.highlightedCellBackgroundColour = UIColor.white
                    cell.highlightedCellTextColour = UIColor.red
                    cell.highlightedCellBorderColour = UIColor.red
                    cell.setNeedsDisplay()
                    break
                }
            }
        }
    }
    
    func setNumber(_ number: String, forCellAt index: SudokuBoardIndex)
    {
        DispatchQueue.main.async {
            let cellView = self.sudokuView.cellAt(tupleRepresentation(index))!
            cellView.setNumber(number: number)
        }
    }
    
    func showPencilMarks(_ pencilMarks: [Int], forCellAt index: SudokuBoardIndex)
    {
        DispatchQueue.main.async {
            let cellView = self.sudokuView.cellAt(tupleRepresentation(index))!
            cellView.showPencilMarks(inPositions: pencilMarks.map( { $0 - 1 } ))
        }
    }
    
    func cell(atIndex index: SudokuBoardIndex, isValid: Bool)
    {
        DispatchQueue.main.async {
            let cellView = self.sudokuView.cellAt(tupleRepresentation(index))!
            if isValid { cellView.reset() }
            else { cellView.flash() }
        }
    }
}

// MARK: - GADBannerViewDelegate Implementation
extension MainViewController: GADBannerViewDelegate
{
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError)
    {
        NSLog("Ad Retrieval Failed")
    }
}

private func tupleRepresentation(_ index: SudokuBoardIndex) -> (row: Int, column: Int)
{
    return (index.row, index.column)
}
