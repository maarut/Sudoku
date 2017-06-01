//
//  ViewController.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 03/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

private let order = 3

private let MARGIN: CGFloat = 10
private let MAX_SUDOKU_VIEW_SIZE: CGFloat = 512
private let EDITABLE_CELL_COLOUR = UIColor(hexValue: 0xF2F8FF)
private let GIVEN_CELL_COLOUR = UIColor(hexValue: 0xD8EBFF)

fileprivate func convertNumberToString(_ number: Int) -> String
{
    return number < 10 ? "\(number)" : "\(Character(UnicodeScalar(55 + number)!))"
}

class MainViewController: UIViewController
{
    weak var viewModel: MainViewModel!
    
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
    
    convenience init(withViewModel viewModel: MainViewModel)
    {
        self.init()
        self.viewModel = viewModel
    }
    
    override func loadView()
    {
        view = UIView()
        view.backgroundColor = UIColor.white
        
        let titles = (1 ... order * order).map( { convertNumberToString($0) } )
        let sudokuView = SudokuView(frame: CGRect.zero, order: order, pencilMarkTitles: titles)
        let numberSelectionView = NumberSelectionView(frame: CGRect.zero, order: order, buttonTitles: titles,
            displayLargeNumbers: true)
        let pencilSelectionView = NumberSelectionView(frame: CGRect.zero, order: order, buttonTitles: titles,
            displayLargeNumbers: false)
        let tabBar = UIView()
        let difficultyLabel = UILabel()
        difficultyLabel.text = "Multiple Solutions"
        difficultyLabel.textAlignment = .center
        difficultyLabel.frame.size = difficultyLabel.intrinsicContentSize
        difficultyLabel.frame.size.height *= 1.2
        difficultyLabel.frame.size.width *= 1.2
        difficultyLabel.text = ""
        let timerLabel = UILabel()
        timerLabel.text = "00:00:00"
        timerLabel.textAlignment = .center
        timerLabel.frame.size = timerLabel.intrinsicContentSize
        timerLabel.frame.size.height *= 1.2
        timerLabel.frame.size.width *= 1.2
        timerLabel.text = "00:00"
        let newGameButton = UIButton(type: .system)
        newGameButton.setTitle("🌟", for: .normal)
        newGameButton.frame.size = newGameButton.intrinsicContentSize
        newGameButton.addTarget(self, action: #selector(newGameButtonTapped(_:)), for: .touchUpInside)
        let undoButton = UIButton(type: .system)
        undoButton.setTitle("⏮", for: .normal)
        undoButton.titleLabel?.textAlignment = .center
        undoButton.frame.size = undoButton.intrinsicContentSize
        undoButton.addTarget(self, action: #selector(undoTapped(_:)), for: .touchUpInside)
        let markupButton = UIButton(type: .system)
        markupButton.setTitle("✏️", for: .normal)
        markupButton.titleLabel?.textAlignment = .center
        markupButton.frame.size = markupButton.intrinsicContentSize
        markupButton.addTarget(self, action: #selector(markupButtonTapped(_:)), for: .touchUpInside)
        markupButton.layer.transform = CATransform3DRotate(CATransform3DIdentity, CGFloat.pi, 0.0, 1.0, 0.0)
        let settingsButton = UIButton(type: .system)
        settingsButton.setTitle("⚙", for: .normal)
        settingsButton.titleLabel?.textAlignment = .center
        settingsButton.frame.size = settingsButton.intrinsicContentSize
        settingsButton.addTarget(self, action: #selector(settingsTapped(_:)), for: .touchUpInside)
        let clearCellButton = HighlightableButton()
        clearCellButton.setTitle("✕", for: .normal)
        clearCellButton.titleLabel?.textAlignment = .center
        clearCellButton.frame.size = clearCellButton.intrinsicContentSize
        clearCellButton.frame.size.width = clearCellButton.frame.height
        clearCellButton.addTarget(self, action: #selector(clearButtonTouchUpInside(_:)), for: .touchUpInside)
        clearCellButton.addTarget(self, action: #selector(clearButtonDragExit(_:)),
            for: [.touchDragExit, .touchUpOutside])
        clearCellButton.addTarget(self, action: #selector(clearButtonTouchDown(_:)), for: .touchDown)
        
        let startButton = UIButton(type: .system)
        startButton.setTitle("Start", for: .normal)
        startButton.frame.size = startButton.intrinsicContentSize
        startButton.addTarget(self, action: #selector(startButtonTapped(_:)), for: .touchUpInside)
        startButton.isHidden = true
        
        tabBar.addSubview(newGameButton)
        tabBar.addSubview(undoButton)
        tabBar.addSubview(markupButton)
        tabBar.addSubview(settingsButton)
        tabBar.layoutIfNeeded()
        view.addSubview(numberSelectionView)
        view.addSubview(pencilSelectionView)
        view.addSubview(sudokuView)
        view.addSubview(tabBar)
        view.addSubview(clearCellButton)
        view.addSubview(timerLabel)
        view.addSubview(difficultyLabel)
        view.addSubview(startButton)
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
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        viewModel.delegate = self
        viewModel.sendState()
        numberSelectionView.delegate = self
        pencilSelectionView.delegate = self
        sudokuView.delegate = self
        var bounds = UIScreen.main.nativeBounds
        bounds.size.width /= UIScreen.main.nativeScale
        bounds.size.height /= UIScreen.main.nativeScale
        let sudokuViewWidth = min(MAX_SUDOKU_VIEW_SIZE, bounds.width - (2 * MARGIN))
        let selectionWidth = sudokuViewWidth / 2.75
        sudokuView.frame = CGRect(x: 0, y: 0, width: sudokuViewWidth, height: 0)
        numberSelectionView.frame = CGRect(x: 0, y: 0, width: selectionWidth, height: selectionWidth)
        pencilSelectionView.frame = CGRect(x: 0, y: 0, width: selectionWidth, height: selectionWidth)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        viewModel.startTimer()
        
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

// MARK: - Event Handlers
extension MainViewController
{
    func newGameButtonTapped(_ sender: UIButton)
    {
        let difficulties = viewModel.newGameDifficulties
        let alertController = UIAlertController(title: "New Game",
            message: "Select a difficulty for the new game", preferredStyle: .actionSheet)
        for difficulty in difficulties {
            let action = UIAlertAction(title: difficulty, style: .default, handler: {
                self.viewModel.newGame(withTitle: $0.title ?? "")
            })
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = sender
        alertController.popoverPresentationController?.sourceRect = sender.bounds
        present(alertController, animated: true)
    }
    
    func undoTapped(_ sender: UIButton)
    {
        viewModel.undo()
    }
    
    func startButtonTapped(_ sender: UIButton)
    {
        viewModel.setPuzzle()
    }
    
    func markupButtonTapped(_ sender: UIButton)
    {
        viewModel.fillInPencilMarks()
    }
    
    func settingsTapped(_ sender: UIButton)
    {
        gameStateChanged(.successfullySolved)
    }
    
    func clearButtonDragExit(_ sender: HighlightableButton)
    {
        viewModel.selectClear(event: .release)
    }
    
    func clearButtonTouchDown(_ sender: HighlightableButton)
    {
        viewModel.selectClear(event: .press)
    }
    
    func clearButtonTouchUpInside(_ sender: HighlightableButton)
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

// MARK: - Layout Functions
fileprivate extension MainViewController
{
    func layoutSubviews()
    {
        UIView.animate(withDuration: 0.25) {
            switch UIApplication.shared.statusBarOrientation {
            case .portrait, .portraitUpsideDown:    self.setLayoutPortrait()
            case .landscapeLeft:                    self.setLayoutLandscapeLeft()
            case .landscapeRight:                   self.setLayoutLandscapeRight()
            case .unknown:                          self.setLayoutUnknown()
            }
        }
    }
    
    func setLayoutPortrait()
    {
        let buttonCount = CGFloat(tabBar.subviews.count)
        let sudokuViewYOrigin = statusBarHeight() + MARGIN - view.frame.origin.y
        sudokuView.center = CGPoint(x: view.frame.width / 2, y: sudokuViewYOrigin + (sudokuView.frame.height / 2))
        tabBar.frame = CGRect(x: 0, y: view.frame.height - 44, width: view.frame.width, height: 44)
        let buttonSpacing = tabBar.frame.width / (buttonCount * 2)
        for (i, button) in [newGameButton, undoButton, markupButton, settingsButton].enumerated() {
            button?.center = CGPoint(x: CGFloat(i * 2 + 1) * buttonSpacing, y: 22)
        }
        let endOfSudokuFrame = sudokuView.frame.origin.y + sudokuView.frame.width
        let beginningOfToolbar = tabBar.frame.origin.y
        let width = numberSelectionView.frame.width
        let midY = endOfSudokuFrame + (beginningOfToolbar - endOfSudokuFrame) / 2
        numberSelectionView.center = CGPoint(x: sudokuView.frame.origin.x + width / 2, y: midY)
        pencilSelectionView.center = CGPoint(x: sudokuView.frame.origin.x + sudokuView.frame.width - width / 2, y: midY)
        clearCellButton.center = CGPoint(x: view.frame.width / 2, y: midY)
        let endOfNumberSelectionFrame = numberSelectionView.frame.origin.y + numberSelectionView.frame.height
        let labelCenterY = endOfNumberSelectionFrame + (beginningOfToolbar - endOfNumberSelectionFrame) / 2
        difficultyLabel.center = CGPoint(x: view.frame.width / 2, y: labelCenterY - difficultyLabel.frame.height / 2)
        timerLabel.center = CGPoint(x: view.frame.width / 2, y: labelCenterY + timerLabel.frame.height / 2)
        startButton.center = timerLabel.center
    }
    
    func setLayoutLandscapeLeft()
    {
        let buttonCount = CGFloat(tabBar.subviews.count)
        let yOrigin = statusBarHeight() - view.frame.origin.y
        let sudokuViewYCenter = yOrigin + (view.frame.height - yOrigin) / 2
        sudokuView.center = CGPoint(x: MARGIN + sudokuView.frame.width / 2, y: sudokuViewYCenter)
        tabBar.frame = CGRect(x: view.frame.width - 44, y: 0, width: 44, height: view.frame.height)
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
        clearCellButton.center = CGPoint(x: midX, y: view.frame.height / 2)
        timerLabel.center.y = (view.frame.height + timerLabel.frame.height) / 2
        timerLabel.frame.origin.x = beginningOfToolbar - timerLabel.frame.width - MARGIN
        difficultyLabel.center.y = (view.frame.height - difficultyLabel.frame.height) / 2
        difficultyLabel.center.x = timerLabel.center.x
        startButton.center = timerLabel.center
    }
    
    func setLayoutLandscapeRight()
    {
        let buttonCount = CGFloat(tabBar.subviews.count)
        let sudokuViewXCenter = view.frame.width - MARGIN - sudokuView.frame.width / 2
        let yOrigin = statusBarHeight() - view.frame.origin.y
        let sudokuViewYCenter = yOrigin + (view.frame.height - yOrigin) / 2
        sudokuView.center = CGPoint(x: sudokuViewXCenter, y: sudokuViewYCenter)
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
        pencilSelectionView.center = CGPoint(x: midX,// y: view.frame.height - MARGIN - height / 2)
            y: sudokuView.frame.origin.y + sudokuView.frame.height - height / 2)
        clearCellButton.center = CGPoint(x: midX, y: view.frame.height / 2)
        timerLabel.center.y = (view.frame.height + timerLabel.frame.height) / 2
        timerLabel.frame.origin.x = endOfToolbar + MARGIN
        difficultyLabel.center.y = (view.frame.height - difficultyLabel.frame.height) / 2
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
        for (index, state, number, pencilMarks) in newState {
            let colour: UIColor
            switch state {
            case .editable: colour = EDITABLE_CELL_COLOUR
            case .given:    colour = GIVEN_CELL_COLOUR
            }
            let cell = sudokuView.cellAt(tupleRepresentation(index))!
            
            cell.flipTo(number: number, backgroundColour: colour,
                showingPencilMarksAtPositions: pencilMarks.map( { $0 - 1 } ))
        }
    }
    
    func difficultyTextDidChange(_ newText: String)
    {
        DispatchQueue.main.async {
            self.difficultyLabel.text = newText
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
            break
        case .finished:
            sudokuView.isUserInteractionEnabled = false
            break
        case .successfullySolved:
            viewModel.stopTimer()
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
        }
    }
    
    func timerTextDidChange(_ text: String)
    {
        DispatchQueue.main.async {
            self.timerLabel.text = text
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
                    let cellView = self.sudokuView.cellAt(row: row, column: column)!
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
                    cell.cellColour = GIVEN_CELL_COLOUR
                    cell.textColour = UIColor.black
                    cell.highlightedCellBackgroundColour = UIColor.white
                    cell.highlightedCellTextColour = UIColor.red
                    cell.highlightedCellBorderColour = UIColor.red
                    cell.setNeedsDisplay()
                    break
                case .editable:
                    cell.cellColour = EDITABLE_CELL_COLOUR
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
            var sortedPencilMarks = pencilMarks.sorted(by: <).makeIterator()
            let cellView = self.sudokuView.cellAt(tupleRepresentation(index))!
            var pencilMark = sortedPencilMarks.next()
            for i in 0 ..< cellView.pencilMarkCount {
                if pencilMark == (i + 1) {
                    cellView.showPencilMark(inPosition: i)
                    pencilMark = sortedPencilMarks.next()
                }
                else {
                    cellView.hidePencilMark(inPosition: i)
                }
            }
        }
    }
    
    func cell(atIndex index: SudokuBoardIndex, didChangeValidityTo isValid: Bool)
    {
        DispatchQueue.main.async {
            let cellView = self.sudokuView.cellAt(tupleRepresentation(index))!
            if isValid { cellView.reset() }
            else { cellView.flash() }
            
        }
    }
}

private func tupleRepresentation(_ index: SudokuBoardIndex) -> (row: Int, column: Int)
{
    return (index.row, index.column)
}
