//
//  MainScreenUIStateMachine.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 15/03/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation
import SudokuEngine

fileprivate func convertNumberToString(_ number: Int?) -> String
{
    switch number ?? 0 {
    case 0:         return ""
    case 1 ..< 10:  return "\(number!)"
    default:        return "\(Character(UnicodeScalar(55 + number!)!))"
    }
}

typealias SudokuBoardIndex = (row: Int, column: Int)

func ==(lhs: SudokuBoardIndex, rhs: SudokuBoardIndex) -> Bool
{
    return lhs.row == rhs.row && lhs.column == rhs.column
}

private enum MainScreenAction
{
    case selectedCell(SudokuBoardIndex)
    case selectedPencilMark(Int)
    case selectedNumber(Int)
    case selectedClear
}

private enum MainScreenState
{
    case highlightCell(SudokuBoardIndex)
    case highlightPencilMark(Int)
    case highlightNumber(Int)
    case highlightClear
    case begin
    
    func advanceWith(action: MainScreenAction) -> MainScreenState
    {
        switch self {
        case .highlightCell(let index):
            switch action {
            case .selectedClear, .selectedNumber(_), .selectedPencilMark(_): return self
            case .selectedCell(let newIndex): return (index != newIndex) ? .highlightCell(newIndex) : .begin
            }
        case .highlightPencilMark(let pencilMark):
            switch action {
            case .selectedCell(_):                          return self
            case .selectedClear:                            return .highlightClear
            case .selectedNumber(let number):               return .highlightNumber(number)
            case .selectedPencilMark(let n):                return pencilMark == n ? .begin : .highlightPencilMark(n)
            }
        case .highlightNumber(let number):
            switch action {
            case .selectedCell(_):                          return self
            case .selectedClear:                            return .highlightClear
            case .selectedPencilMark(let newPencilMark):    return .highlightPencilMark(newPencilMark)
            case .selectedNumber(let n):                    return number == n ? .begin : .highlightNumber(n)
            }
        case .highlightClear:
            switch action {
            case .selectedCell(_):                      return self
            case .selectedClear:                        return .begin
            case .selectedNumber(let number):           return .highlightNumber(number)
            case .selectedPencilMark(let pencilMark):   return .highlightPencilMark(pencilMark)
            }
        case .begin:
            switch action {
            case .selectedCell(let index):              return .highlightCell(index)
            case .selectedClear:                        return .highlightClear
            case .selectedNumber(let number):           return .highlightNumber(number)
            case .selectedPencilMark(let pencilMark):   return .highlightPencilMark(pencilMark)
            }
        }
    }
}

enum ButtonEvent
{
    case press
    case releaseActivate
    case release
}

enum ButtonState
{
    case normal
    case highlighted
    case selected
}

enum SudokuCellState
{
    case given
    case editable
}

protocol MainViewModelDelegate: class
{
    func numberSelection(newState: ButtonState, forNumber: Int?)
    func pencilMarkSelection(newState: ButtonState, forNumber: Int?)
    func clearButton(newState: ButtonState)
    func removeHighlights()
    
    func sudokuCells(atIndexes: [SudokuBoardIndex], newState: SudokuCellState)
    func sudokuCells(atIndexes: [SudokuBoardIndex], newState: ButtonState)
    func setNumber(_: String, forCellAt: SudokuBoardIndex)
    func showPencilMarks(_: [Int], forCellAt: SudokuBoardIndex)
}

class MainViewModel
{
    weak var delegate: MainViewModelDelegate?
    fileprivate var currentState = MainScreenState.begin
    fileprivate var sudokuBoard: SudokuBoard
    
    init(withSudokuBoard b: SudokuBoard)
    {
        sudokuBoard = b
    }
    
    func selectCell(atIndex index: SudokuBoardIndex)
    {
        switch currentState {
        case .highlightNumber(let number):          setNumber(number, forCellAt: index)
        case .highlightPencilMark(let pencilMark):  setPencilMark(pencilMark, forCellAt: index)
        case .highlightClear:                       clearCellAt(index)
        default:                                    break
        }
        currentState = currentState.advanceWith(action: .selectedCell(index))
        switch currentState {
        case .begin:                                delegate?.removeHighlights()
        case .highlightNumber(let number):          highlightCellsContaining(number)
        case .highlightPencilMark(let pencilMark):  highlightCellsContaining(pencilMark)
        case .highlightCell(let cell):              highlightCellAt(cell)
        case .highlightClear:                       break
        }
    }
    
    func selectPencilMark(_ number: Int, event: ButtonEvent)
    {
        switch currentState {
        case .highlightCell(let index): setPencilMark(number, forCellAt: index)
        default:                        break
        }
        
        currentState = currentState.advanceWith(action: .selectedPencilMark(number))
        
        switch currentState {
        case .begin:
            delegate?.removeHighlights()
            break
        case .highlightCell(row: let row, column: let column):
            highlightCellAt((row, column))
            delegate?.numberSelection(newState: .normal, forNumber: nil)
            delegate?.pencilMarkSelection(newState: .normal, forNumber: nil)
            delegate?.clearButton(newState: .normal)
            break
        case .highlightPencilMark(let number):
            highlightCellsContaining(number)
            delegate?.pencilMarkSelection(newState: .selected, forNumber: number)
            delegate?.numberSelection(newState: .normal, forNumber: nil)
            delegate?.clearButton(newState: .normal)
            break
        default:
            break
        }
    }
    
    func selectNumber(_ number: Int, event: ButtonEvent)
    {
        guard event == .releaseActivate else { return }
        switch currentState {
        case .highlightCell(let index): setNumber(number, forCellAt: index)
        default:                        break
        }
        
        currentState = currentState.advanceWith(action: .selectedNumber(number))
        
        switch currentState {
        case .begin:
            delegate?.removeHighlights()
            break
        case .highlightCell(_):
            delegate?.numberSelection(newState: .normal, forNumber: nil)
            delegate?.pencilMarkSelection(newState: .normal, forNumber: nil)
            delegate?.clearButton(newState: .normal)
            break
        case .highlightNumber(let number):
            highlightCellsContaining(number)
            delegate?.numberSelection(newState: .selected, forNumber: number)
            delegate?.pencilMarkSelection(newState: .normal, forNumber: nil)
            delegate?.clearButton(newState: .normal)
            break
        default:
            break
        }
    }
    
    func selectClear(event: ButtonEvent)
    {
        switch event {
        case .press:            clearPress()
        case .release:          clearRelease()
        case .releaseActivate:  clearReleaseActivate()
        }
    }
    
    func sendState()
    {
        delegate?.removeHighlights()
        var givenCells = [SudokuBoardIndex]()
        var editableCells = [SudokuBoardIndex]()
        for row in 0 ..< sudokuBoard.dimensionality {
            for column in 0 ..< sudokuBoard.dimensionality {
                let cell = sudokuBoard.cellAt((row, column))!
                if let number = cell.number {
                    delegate?.setNumber(convertNumberToString(number), forCellAt: (row, column))
                }
                else {
                    delegate?.showPencilMarks(Array(cell.pencilMarks), forCellAt: (row, column))
                }
                if cell.isGiven { givenCells.append((row, column)) }
                else            { editableCells.append((row, column)) }
            }
        }
        delegate?.sudokuCells(atIndexes: givenCells, newState: .given)
        delegate?.sudokuCells(atIndexes: editableCells, newState: .editable)
        switch currentState {
        case .highlightCell(let index):
            highlightCellAt(index)
            break
        case .highlightClear:
            delegate?.clearButton(newState: .selected)
            break
        case .highlightNumber(let number):
            delegate?.numberSelection(newState: .selected, forNumber: number)
            highlightCellsContaining(number)
            break
        case .highlightPencilMark(let pencilMark):
            delegate?.pencilMarkSelection(newState: .selected, forNumber: pencilMark)
            highlightCellsContaining(pencilMark)
            break
        default:
            break
        }
    }
}

// MARK: - Clear Button State
fileprivate extension MainViewModel
{
    func clearRelease()
    {
        switch currentState {
        case .highlightClear:   delegate?.clearButton(newState: .selected)
        default:                delegate?.clearButton(newState: .normal)
        }
    }
    
    func clearPress()
    {
        delegate?.clearButton(newState: .highlighted)
    }
    
    func clearReleaseActivate()
    {
        switch currentState {
        case .highlightCell(let index): clearCellAt(index)
        default:                        break
        }
        currentState = currentState.advanceWith(action: .selectedClear)
        switch currentState {
        case .highlightClear:
            delegate?.removeHighlights()
            delegate?.clearButton(newState: .selected)
            break
        case .highlightCell(let index):
            highlightCellAt(index)
            fallthrough
        default:
            delegate?.clearButton(newState: .normal)
            break
        }
    }
}

// MARK: - Private Functions
fileprivate extension MainViewModel
{
    func setNumber(_ number: Int, forCellAt index: SudokuBoardIndex)
    {
        let cell = sudokuBoard.cellAt(index)!
        if cell.isGiven { return }
        if cell.number == number {
            cell.number = nil
            highlightCellAt(index)
        }
        else {
            cell.pencilMarks.removeAll()
            cell.number = number
            highlightCellsContaining(number)
        }
        delegate?.showPencilMarks(Array(cell.pencilMarks), forCellAt: index)
        delegate?.setNumber(convertNumberToString(cell.number ?? 0), forCellAt: index)
    }
    
    func setPencilMark(_ number: Int, forCellAt index: SudokuBoardIndex)
    {
        let cell = sudokuBoard.cellAt(index)!
        if cell.isGiven { return }
        if cell.pencilMarks.contains(number)    { cell.pencilMarks.remove(number) }
        else                                    { cell.pencilMarks.insert(number) }
        delegate?.showPencilMarks(Array(cell.pencilMarks), forCellAt: index)
    }
    
    func highlightCellAt(_ index: SudokuBoardIndex)
    {
        let cell = sudokuBoard.cellAt(index)!
        if cell.number != nil {
            highlightCellsContaining(cell.number!)
        }
        else {
            delegate?.sudokuCells(atIndexes: [index], newState: .selected)
            delegate?.sudokuCells(atIndexes: allCellsExcluding(index), newState: .normal)
        }
        delegate?.numberSelection(newState: .normal, forNumber: nil)
        delegate?.pencilMarkSelection(newState: .normal, forNumber: nil)
    }
    
    func highlightCellsContaining(_ number: Int)
    {
        var selectedIndexes = [SudokuBoardIndex]()
        var normalIndexes = [SudokuBoardIndex]()
        for row in 0 ..< sudokuBoard.dimensionality {
            for column in 0 ..< sudokuBoard.dimensionality {
                let cell = sudokuBoard.cellAt((row, column))!
                if cell.number == number || cell.pencilMarks.contains(number) {
                    selectedIndexes.append((row, column))
                }
                else {
                    normalIndexes.append((row, column))
                }
            }
        }
        delegate?.sudokuCells(atIndexes: selectedIndexes, newState: .selected)
        delegate?.sudokuCells(atIndexes: normalIndexes, newState: .normal)
    }
    
    func clearCellAt(_ index: SudokuBoardIndex)
    {
        let cell = sudokuBoard.cellAt(index)!
        if !cell.isGiven {
            cell.number = nil
            cell.pencilMarks.removeAll()
            delegate?.setNumber(convertNumberToString(cell.number), forCellAt: index)
            delegate?.showPencilMarks(Array(cell.pencilMarks), forCellAt: index)
        }
    }
    
    func allCellsExcluding(_ index: SudokuBoardIndex) -> [SudokuBoardIndex]
    {
        var indexes = [SudokuBoardIndex]()
        for row in 0 ..< sudokuBoard.dimensionality {
            for column in 0 ..< sudokuBoard.dimensionality {
                if (row, column) != index { indexes.append((row, column)) }
            }
        }
        return indexes
    }
}
