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
    weak var setPuzzleButton: UIButton!
    weak var settingsButton: UIButton!
    weak var clearCellButton: HighlightableButton!
    
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
        tabBar.backgroundColor = UIColor.lightGray
        let newGameButton = UIButton(type: .system)
        newGameButton.setTitle("N", for: .normal)
        newGameButton.frame.size = newGameButton.intrinsicContentSize
        let undoButton = UIButton(type: .system)
        undoButton.setTitle("U", for: .normal)
        undoButton.frame.size = undoButton.intrinsicContentSize
        let setPuzzleButton = UIButton(type: .system)
        setPuzzleButton.setTitle("T", for: .normal)
        setPuzzleButton.frame.size = setPuzzleButton.intrinsicContentSize
        let settingsButton = UIButton(type: .system)
        settingsButton.setTitle("S", for: .normal)
        settingsButton.frame.size = settingsButton.intrinsicContentSize
        let clearCellButton = HighlightableButton()
        clearCellButton.setTitle("C", for: .normal)
        clearCellButton.frame.size = clearCellButton.intrinsicContentSize
        clearCellButton.frame.size.width = clearCellButton.frame.height
        clearCellButton.addTarget(self, action: #selector(clearButtonTouchUpInside(_:)), for: .touchUpInside)
        clearCellButton.addTarget(self, action: #selector(clearButtonDragExit(_:)),
            for: [.touchDragExit, .touchUpOutside])
        clearCellButton.addTarget(self, action: #selector(clearButtonTouchDown(_:)), for: .touchDown)
        
        tabBar.addSubview(newGameButton)
        tabBar.addSubview(undoButton)
        tabBar.addSubview(setPuzzleButton)
        tabBar.addSubview(settingsButton)
        tabBar.layoutIfNeeded()
        view.addSubview(sudokuView)
        view.addSubview(numberSelectionView)
        view.addSubview(pencilSelectionView)
        view.addSubview(tabBar)
        view.addSubview(clearCellButton)
        self.sudokuView = sudokuView
        self.numberSelectionView = numberSelectionView
        self.pencilSelectionView = pencilSelectionView
        self.tabBar = tabBar
        self.newGameButton = newGameButton
        self.undoButton = undoButton
        self.setPuzzleButton = setPuzzleButton
        self.settingsButton = settingsButton
        self.clearCellButton = clearCellButton
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
        let selectionWidth = bounds.width / 2.75
        sudokuView.frame = CGRect(x: 0, y: 0, width: bounds.width - (2 * MARGIN), height: 0)
        numberSelectionView.frame = CGRect(x: 0, y: 0, width: selectionWidth, height: selectionWidth)
        pencilSelectionView.frame = CGRect(x: 0, y: 0, width: selectionWidth, height: selectionWidth)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:         setLayoutPortrait()
        case .landscapeLeft:    setLayoutLandscapeLeft()
        case .landscapeRight:   setLayoutLandscapeRight()
        case .unknown:          setLayoutUnknown()
        default:                break
        }
    }
}

// MARK: - Event Handlers
extension MainViewController
{
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
    func sudokuView(_ view: SudokuView, didSelectCellAt index: SudokuBoardIndex)
    {
        viewModel.selectCell(atIndex: index)
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
    func setLayoutPortrait()
    {
        let buttonCount = CGFloat(tabBar.subviews.count)
        sudokuView.frame.origin.y = UIApplication.shared.statusBarFrame.height + MARGIN
        sudokuView.frame.origin.x = MARGIN
        tabBar.frame = CGRect(x: 0, y: view.frame.height - 44, width: view.frame.width, height: 44)
        let buttonSpacing = tabBar.frame.width / (buttonCount * 2)
        for (i, button) in [newGameButton, undoButton, setPuzzleButton, settingsButton].enumerated() {
            button?.center = CGPoint(x: CGFloat(i * 2 + 1) * buttonSpacing, y: 22)
        }
        let width = numberSelectionView.frame.width
        let endOfSudokuFrame = sudokuView.frame.origin.y + sudokuView.frame.width
        let beginningOfToolbar = tabBar.frame.origin.y
        let midY = endOfSudokuFrame + ((beginningOfToolbar - endOfSudokuFrame) / 2)
        numberSelectionView.center = CGPoint(x: MARGIN + width / 2, y: midY)
        pencilSelectionView.center = CGPoint(x: view.frame.width - MARGIN - width / 2, y: midY)
        let endOfNumberSelectionFrame = numberSelectionView.frame.origin.y + numberSelectionView.frame.height
        let clearCellCenterY = endOfNumberSelectionFrame + (beginningOfToolbar - endOfNumberSelectionFrame) / 2
        clearCellButton.center = CGPoint(x: view.frame.width / 2, y: clearCellCenterY)
    }
    
    func setLayoutLandscapeLeft()
    {
        let buttonCount = CGFloat(tabBar.subviews.count)
        sudokuView.frame.origin.y = UIApplication.shared.statusBarFrame.height + MARGIN
        sudokuView.frame.origin.x = MARGIN
        tabBar.frame = CGRect(x: view.frame.width - 44, y: 0, width: 44, height: view.frame.height)
        let buttonSpacing = tabBar.frame.height / (buttonCount * 2)
        for (i, button) in [newGameButton, undoButton, setPuzzleButton, settingsButton].enumerated() {
            button?.center = CGPoint(x: 22, y: CGFloat(i * 2 + 1) * buttonSpacing)
        }
        let height = numberSelectionView.frame.height
        let endOfSudokuFrame = sudokuView.frame.origin.x + sudokuView.frame.width
        let beginningOfToolbar = tabBar.frame.origin.x
        let midX = endOfSudokuFrame + ((beginningOfToolbar - endOfSudokuFrame) / 2)
        numberSelectionView.center = CGPoint(x: midX, y: MARGIN + height / 2)
        pencilSelectionView.center = CGPoint(x: midX, y: view.frame.height - MARGIN - height / 2)
        let endOfNumberSelectionFrame = numberSelectionView.frame.origin.x + numberSelectionView.frame.width
        let clearCellCenterX = endOfNumberSelectionFrame + (beginningOfToolbar - endOfNumberSelectionFrame) / 2
        clearCellButton.center = CGPoint(x: clearCellCenterX, y: view.frame.height / 2)
    }
    
    func setLayoutLandscapeRight()
    {
        let buttonCount = CGFloat(tabBar.subviews.count)
        sudokuView.frame.origin.y = UIApplication.shared.statusBarFrame.height + MARGIN
        sudokuView.frame.origin.x = view.frame.width - MARGIN - sudokuView.frame.width
        tabBar.frame = CGRect(x: 0, y: 0, width: 44, height: view.frame.height)
        let buttonSpacing = tabBar.frame.height / (buttonCount * 2)
        for (i, button) in [newGameButton, undoButton, setPuzzleButton, settingsButton].enumerated() {
            button?.center = CGPoint(x: 22, y: CGFloat(i * 2 + 1) * buttonSpacing)
        }
        let height = numberSelectionView.frame.height
        let beginningOfSudokuFrame = sudokuView.frame.origin.x
        let endOfToolbar = tabBar.frame.width
        let midX = endOfToolbar + ((beginningOfSudokuFrame - endOfToolbar) / 2)
        numberSelectionView.center = CGPoint(x: midX, y: MARGIN + height / 2)
        pencilSelectionView.center = CGPoint(x: midX, y: view.frame.height - MARGIN - height / 2)
        let beginningOfNumberSelectionFrame = numberSelectionView.frame.origin.x
        let clearCellCenterX = endOfToolbar + (beginningOfNumberSelectionFrame - endOfToolbar) / 2
        clearCellButton.center = CGPoint(x: clearCellCenterX, y: view.frame.height / 2)
    }
    
    func setLayoutUnknown()
    {
        let width = view.frame.width
        let height = view.frame.height
        if width > height { setLayoutLandscapeLeft() }
        else { setLayoutPortrait() }
    }
}

// MARK: - MainViewModelDelegate Implementation
extension MainViewController: MainViewModelDelegate
{
    func numberSelection(newState state: ButtonState, forNumber number: Int?)
    {
        switch number {
        case .some(let n):
            switch state {
            case .highlighted, .selected: numberSelectionView.select(number: n)
            case .normal:                 numberSelectionView.clearSelection()
            }
            break
        case .none:
            numberSelectionView.clearSelection()
            break
        }
    }
    
    func pencilMarkSelection(newState state: ButtonState, forNumber number: Int?)
    {
        switch number {
        case .some(let n):
            switch state {
            case .highlighted, .selected: pencilSelectionView.select(number: n)
            case .normal:                 pencilSelectionView.clearSelection()
            }
            break
        case .none:
            pencilSelectionView.clearSelection()
            break
        }
    }
    
    func clearButton(newState state: ButtonState)
    {
        switch state {
        case .highlighted:  clearCellButton.highlight()
        case .selected:     clearCellButton.select()
        case .normal:       clearCellButton.reset()
        }
    }
    
    func removeHighlights()
    {
        for row in 0 ..< sudokuView.dimensionality {
            for column in 0 ..< sudokuView.dimensionality {
                let cellView = sudokuView.cellAt(row: row, column: column)!
                cellView.deselect()
            }
        }
        clearCellButton.reset()
        numberSelectionView.clearSelection()
        pencilSelectionView.clearSelection()
    }
    
    func sudokuCells(atIndexes indexes: [SudokuBoardIndex], newState state: ButtonState)
    {
        switch state {
        case .normal:                   for index in indexes { sudokuView.cellAt(index)!.deselect() }
        case .selected, .highlighted:   for index in indexes { sudokuView.cellAt(index)!.select() }
        }
    }
    
    func sudokuCells(atIndexes indexes: [SudokuBoardIndex], newState state: SudokuCellState)
    {
        for i in indexes {
            let cell = sudokuView.cellAt(i)!
            switch state {
            case .given:
                cell.cellColour = UIColor(hexValue: 0xE0E0CC)
                cell.textColour = UIColor.black
                cell.highlightedCellBackgroundColour = UIColor.white
                cell.highlightedCellTextColour = UIColor.red
                cell.highlightedCellBorderColour = UIColor.red
                cell.setNeedsDisplay()
                break
            case .editable:
                cell.cellColour = UIColor(hexValue: 0xF0F0DC)
                cell.textColour = UIColor.black
                cell.highlightedCellBackgroundColour = UIColor.white
                cell.highlightedCellTextColour = UIColor.red
                cell.highlightedCellBorderColour = UIColor.red
                cell.setNeedsDisplay()
                break
            }
        }
    }
    
    func setNumber(_ number: String, forCellAt index: SudokuBoardIndex)
    {
        let cellView = sudokuView.cellAt(index)!
        cellView.setNumber(number: number)
    }
    
    func showPencilMarks(_ pencilMarks: [Int], forCellAt index: SudokuBoardIndex)
    {
        var sortedPencilMarks = pencilMarks.sorted(by: <).makeIterator()
        let cellView = sudokuView.cellAt(index)!
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

