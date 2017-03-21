//
//  ViewController.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 03/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit
import SudokuEngine

private let order = 3

private let MARGIN: CGFloat = 10

fileprivate func convertNumberToString(_ number: Int) -> String
{
    return number < 10 ? "\(number)" : "\(Character(UnicodeScalar(55 + number)!))"
}

class MainViewController: UIViewController
{
    var sudokuBoard: SudokuBoard!
    
    weak var sudokuView: SudokuView!
    weak var numberSelectionView: NumberSelectionView!
    weak var pencilSelectionView: NumberSelectionView!
    weak var tabBar: UIView!
    weak var newGameButton: UIButton!
    weak var undoButton: UIButton!
    weak var setPuzzleButton: UIButton!
    weak var settingsButton: UIButton!
    weak var clearCellButton: UIButton!
    
    fileprivate var currentState = MainScreenState.begin
    
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
        let clearCellButton = UIButton(type: .system)
        clearCellButton.setTitle("C", for: .normal)
        clearCellButton.frame.size = clearCellButton.intrinsicContentSize
        clearCellButton.addTarget(self, action: #selector(clearButtonTapped(_:)), for: .touchUpInside)
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
        sudokuBoard = SudokuBoard.generatePuzzle(ofOrder: order, difficulty: .easy)!
        sudokuBoard.markupBoard()
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
        for (i, c) in sudokuBoard.board.enumerated() {
            let row = i / sudokuBoard.dimensionality
            let column = i % sudokuBoard.dimensionality
            let cellView = sudokuView.cellAt(row: row, column: column)!
            if let number = c.number { cellView.setNumber(number: convertNumberToString(number)) }
            else { for pm in c.pencilMarks { cellView.showPencilMark(inPosition: pm - 1) } }
        }
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
    func clearButtonTapped(_ sender: UIButton)
    {
        switch currentState {
        case .highlightCell(row: let row, column: let column):  clearCellAt(row: row, column: column)
        default:                                                break
        }
        currentState = currentState.advanceWith(action: .selectedClear)
        switch currentState {
        case .highlightClear:
            break // highlight clear button
        case .highlightCell(row: let row, column: let column):
            highlightCellAt((row, column))
            break
        default:
            break
        }
    }
}

// MARK: - SudokuViewDelegate Implementation
extension MainViewController: SudokuViewDelegate
{
    func sudokuView(_ view: SudokuView, didSelectCellAt index: (row: Int, column: Int))
    {
        switch currentState {
        case .highlightNumber(let number):          setNumber(number, forCellAt: index)
        case .highlightPencilMark(let pencilMark):  setPencilMark(pencilMark, forCellAt: index)
        case .highlightClear:                       clearCellAt(index)
        default:                                    break
        }
        currentState = currentState.advanceWith(action: .selectedCell(row: index.row, column: index.column))
        switch currentState {
        case .begin:                                            removeHighlights()
        case .highlightNumber(let number):                      highlightCellsContaining(number)
        case .highlightPencilMark(let pencilMark):              highlightCellsContaining(pencilMark)
        case .highlightClear:                                   break
        case .highlightCell(row: let row, column: let column):  highlightCellAt((row, column))
        }
    }
}

// MARK: - NumberSelectionViewDelegate Implementation
extension MainViewController: NumberSelectionViewDelegate
{
    func numberSelectionView(_ view: NumberSelectionView, didSelect number: Int)
    {
        switch view {
        case numberSelectionView:   numberSelectionView(selectedNumber: number)
        case pencilSelectionView:   pencilMarkSelectionView(selectedNumber: number)
        default:                    break
        }
        
    }
}

// MARK: - Private Functions
fileprivate extension MainViewController
{
    func numberSelectionView(selectedNumber number: Int)
    {
        switch currentState {
        case .highlightCell(row: let row, column: let column):
            setNumber(number, forCellAt: (row, column))
            break
        default:
            break
        }
        
        currentState = currentState.advanceWith(action: .selectedNumber(number))
        
        switch currentState {
        case .begin:
            removeHighlights()
            break
        case .highlightCell(row: _, column: _):
            numberSelectionView.clearSelection()
            pencilSelectionView.clearSelection()
            break
        case .highlightNumber(let number):
            highlightCellsContaining(number)
            numberSelectionView.highlight(number: number)
            pencilSelectionView.clearSelection()
            break
        default:
            break
        }
    }
    
    func pencilMarkSelectionView(selectedNumber number: Int)
    {
        switch currentState {
        case .highlightCell(row: let row, column: let column):
            setPencilMark(number, forCellAt: (row, column))
            break
        default:
            break
        }
        
        currentState = currentState.advanceWith(action: .selectedPencilMark(number))
        
        switch currentState {
        case .begin:
            removeHighlights()
            break
        case .highlightCell(row: let row, column: let column):
            highlightCellAt((row, column))
            numberSelectionView.clearSelection()
            pencilSelectionView.clearSelection()
            break
        case .highlightPencilMark(let number):
            highlightCellsContaining(number)
            pencilSelectionView.highlight(number: number)
            numberSelectionView.clearSelection()
            break
        default:
            break
        }
    }
    
    func setPencilMark(_ number: Int, forCellAt index: (row: Int, column: Int))
    {
        let cell = sudokuBoard.cellAt(row: index.row, column: index.column)!
        let cellView = sudokuView.cellAt(row: index.row, column: index.column)!
        if !cell.isGiven && cell.number == nil {
            if cell.pencilMarks.contains(number) {
                cell.pencilMarks.remove(number)
                cellView.hidePencilMark(inPosition: number - 1)
            }
            else {
                cell.pencilMarks.insert(number)
                cellView.showPencilMark(inPosition: number - 1)
            }
        }
    }
    
    func setNumber(_ number: Int, forCellAt index: (row: Int, column: Int))
    {
        let cell = sudokuBoard.cellAt(row: index.row, column: index.column)!
        let cellView = sudokuView.cellAt(row: index.row, column: index.column)!
        if !cell.isGiven {
            if cell.number == number {
                cell.number = nil
                cellView.setNumber(number: "")
                highlightCellAt(index)
            }
            else {
                cell.number = number
                cell.pencilMarks.removeAll()
                cellView.setNumber(number: convertNumberToString(number))
                cellView.highlight()
                highlightCellsContaining(number)
            }
        }
    }
    
    func removeHighlights()
    {
        for i in 0 ..< sudokuBoard.board.count {
            let row = i / sudokuBoard.dimensionality
            let column = i % sudokuBoard.dimensionality
            let cellView = sudokuView.cellAt(row: row, column: column)!
            cellView.unhighlight()
        }
        numberSelectionView.clearSelection()
        pencilSelectionView.clearSelection()
    }
    
    func highlightCellsContaining(_ number: Int)
    {
        for (i, cell) in sudokuBoard.board.enumerated() {
            let row = i / sudokuBoard.dimensionality
            let column = i % sudokuBoard.dimensionality
            let cellView = sudokuView.cellAt(row: row, column: column)!
            if shouldHighlight(cellView: cellView, given: cell, and: number) { cellView.highlight() }
            if shouldUnhighlight(cellView: cellView, given: cell, and: number) { cellView.unhighlight() }
        }
    }
    
    func clearCellAt(_ index: (row: Int, column: Int))
    {
        let cell = sudokuBoard.cellAt(row: index.row, column: index.column)!
        let cellView = sudokuView.cellAt(row: index.row, column: index.column)!
        if !cell.isGiven {
            cell.number = nil
            cellView.setNumber(number: "")
            for pm in cell.pencilMarks { cellView.hidePencilMark(inPosition: pm - 1) }
            cell.pencilMarks.removeAll()
        }
    }
    
    func highlightCellAt(_ index: (row: Int, column: Int))
    {
        let cell = sudokuBoard.cellAt(row: index.row, column: index.column)!
        if cell.number != nil { highlightCellsContaining(cell.number!) }
        else {
            for i in 0 ..< sudokuBoard.board.count {
                let r = i / sudokuBoard.dimensionality
                let c = i % sudokuBoard.dimensionality
                let cellView = sudokuView.cellAt(row: r, column: c)!
                if index.row == r && index.column == c { cellView.highlight() }
                else { cellView.unhighlight() }
            }
        }
        pencilSelectionView.clearSelection()
        numberSelectionView.clearSelection()
    }
    
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
    
    func shouldHighlight(cellView: CellView, given cell: Cell, and number: Int) -> Bool
    {
        return cell.number == number || cell.pencilMarks.contains(number)
    }
    
    func shouldUnhighlight(cellView: CellView, given cell: Cell, and number: Int) -> Bool
    {
        return cell.number != number && (cell.number != nil || !cell.pencilMarks.contains(number))
    }
}

