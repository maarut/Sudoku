//
//  MainScreenUIStateMachine.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 15/03/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation
import SudokuEngine

private class MainViewModelArchive: NSObject, NSCoding
{
    var sudokuBoard: SudokuBoardProtocol
    var counter: Int
    
    init(sudokuBoard: SudokuBoardProtocol, counter: Int)
    {
        self.sudokuBoard = sudokuBoard
        self.counter = counter
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        sudokuBoard = aDecoder.decodeObject(forKey: "sudokuBoard") as! SudokuBoardProtocol
        counter = aDecoder.decodeInteger(forKey: "counter")
    }
    
    public func encode(with aCoder: NSCoder)
    {
        aCoder.encode(counter, forKey: "counter")
        aCoder.encode(sudokuBoard, forKey: "sudokuBoard")
    }
}

// MARK: - Private Functions
fileprivate func convertNumberToString(_ number: Int?) -> String
{
    switch number ?? 0 {
    case 0:         return ""
    case 1 ..< 10:  return "\(number!)"
    default:        return "\(Character(UnicodeScalar(55 + number!)!))"
    }
}

// MARK: - SudokuBoardIndex Definition
public typealias SudokuBoardIndex = SudokuEngine.SudokuBoardIndex

// MARK: - MainScreenAction Definition
private enum MainScreenAction
{
    case selectedCell(SudokuBoardIndex)
    case selectedPencilMark(Int)
    case selectedNumber(Int)
    case selectedClear
}

// MARK: - MainScreenState Definition
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

// MARK: - ButtonEvent Definition
public enum ButtonEvent
{
    case press
    case releaseActivate
    case release
}

// MARK: - ButtonState Definition
public enum ButtonState
{
    case normal
    case highlighted
    case selected
}

// MARK: - SudokuCellState Definition
public enum SudokuCellState
{
    case given
    case editable
}

public enum SetPuzzleState
{
    case canSet
    case isSet
    case failed(String)
}

// MARK: - MainViewModelDelegate Definition
public protocol MainViewModelDelegate: class
{
    func numberSelection(newState: ButtonState, forNumber: Int?)
    func pencilMarkSelection(newState: ButtonState, forNumber: Int?)
    func clearButton(newState: ButtonState)
    func removeHighlights()
    
    func sudokuCells(atIndexes: [SudokuBoardIndex], newState: SudokuCellState)
    func sudokuCells(atIndexes: [SudokuBoardIndex], newState: ButtonState)
    func setNumber(_: String, forCellAt: SudokuBoardIndex)
    func showPencilMarks(_: [Int], forCellAt: SudokuBoardIndex)
    
    func timerTextDidChange(_: String)
    func difficultyTextDidChange(_: String)
    func undoStateChanged(_ canUndo: Bool)
    func setPuzzleStateChanged(_: SetPuzzleState)
    func gameFinished()
    func newGameStarted(newState: [
        (index: SudokuBoardIndex, state: SudokuCellState, number: String, pencilMarks: [Int])
        ])
}

// MARK: - MainViewModel Implementation
public class MainViewModel
{
    weak var delegate: MainViewModelDelegate?
    fileprivate var currentState = MainScreenState.begin
    fileprivate var sudokuBoard: SudokuBoardProtocol
    fileprivate var timer: Timer!
    fileprivate var counter = 0
    fileprivate let undoManager = UndoManager()
    
    var newGameDifficulties: [String] = {
        var difficulties = [String]()
        for count in PuzzleDifficulty.blank.rawValue ..< Int.max {
            guard let difficulty = PuzzleDifficulty(rawValue: count) else { break }
            switch difficulty {
            case .blank, .easy, .normal, .hard, .insane:    difficulties.append(difficulty.description())
            default:                                        break
            }
        }
        return difficulties
    }()

    init(withSudokuBoard b: SudokuBoardProtocol)
    {
        sudokuBoard = b
    }
    
    public init?(fromArchive archive: NSCoding)
    {
        if let archive = archive as? MainViewModelArchive {
            sudokuBoard = archive.sudokuBoard
            counter = archive.counter
        }
        else {
            return nil
        }
    }
    
    func archivableFormat() -> NSCoding
    {
        return MainViewModelArchive(sudokuBoard: sudokuBoard, counter: counter)
    }
    
    func undo()
    {
        undoManager.undo()
        delegate?.undoStateChanged(undoManager.canUndo)
    }
    
    func startTimer()
    {
        if timer == nil && sudokuBoard.difficulty != .blank {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerFired(_:)),
                userInfo: nil, repeats: true)
        }
    }
    
    func stopTimer()
    {
        timer?.invalidate()
        timer = nil
    }
    
    func newGame(withTitle title: String)
    {
        stopTimer()
        counter = 0
        sendNewTimerText()
        if let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: titleToDifficulty(title)) {
            self.sudokuBoard = board
        }
        else if let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank) {
            self.sudokuBoard = board
        }
        else {
            fatalError("Couldn't create a new game. NewGameViewModel.newGame(_:)")
        }
        delegate?.setPuzzleStateChanged(sudokuBoard.difficulty == .blank ? .canSet : .isSet)
        var newState = [(index: SudokuBoardIndex, state: SudokuCellState, number: String, pencilMarks: [Int])]()
        for row in 0 ..< sudokuBoard.dimensionality {
            for column in 0 ..< sudokuBoard.dimensionality {
                let index = SudokuBoardIndex(row: row, column: column)
                let cell = sudokuBoard.cellAt(index)!
                let state = cell.isGiven ? SudokuCellState.given : .editable
                let number = convertNumberToString(cell.number)
                let pencilMarks = Array(cell.pencilMarks)
                newState.append((index, state, number, pencilMarks))
            }
        }
        delegate?.newGameStarted(newState: newState)
        delegate?.difficultyTextDidChange(sudokuBoard.difficulty.emojiDescription())
        sendCurrentState()
        startTimer()
    }
    
    func setPuzzle()
    {
        guard sudokuBoard.difficulty == .blank else { return }
        let difficulty = sudokuBoard.setPuzzle()
        if difficulty.isSolvable() {
            sendState()
            delegate?.setPuzzleStateChanged(.isSet)
        }
        else {
            let reason: String
            switch difficulty {
            case .noSolution:           reason = "No solution available for puzzle."
            case .multipleSolutions:    reason = "Multiple solutions available for puzzle."
            default:                    reason = "An unknown error occured"
            }
            delegate?.setPuzzleStateChanged(.canSet)
            delegate?.setPuzzleStateChanged(.failed(reason))
        }
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
        case .highlightCell(let cell):
            highlightCellAt(cell)
            delegate?.numberSelection(newState: .normal, forNumber: nil)
            delegate?.pencilMarkSelection(newState: .normal, forNumber: nil)
            delegate?.clearButton(newState: .normal)
            break
        case .highlightClear:
            break
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
        case .highlightCell(let index):
            highlightCellAt(index)
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
        case .highlightCell(let index):
            highlightCellAt(index)
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
                let cell = sudokuBoard.cellAt(SudokuBoardIndex(row: row, column: column))!
                if let number = cell.number {
                    delegate?.setNumber(convertNumberToString(number),
                        forCellAt: SudokuBoardIndex(row: row, column: column))
                }
                else {
                    delegate?.showPencilMarks(Array(cell.pencilMarks),
                        forCellAt: SudokuBoardIndex(row: row, column: column))
                }
                if cell.isGiven { givenCells.append(SudokuBoardIndex(row: row, column: column)) }
                else            { editableCells.append(SudokuBoardIndex(row: row, column: column)) }
            }
        }
        delegate?.sudokuCells(atIndexes: givenCells, newState: .given)
        delegate?.sudokuCells(atIndexes: editableCells, newState: .editable)
        delegate?.undoStateChanged(undoManager.canUndo)
        delegate?.setPuzzleStateChanged(sudokuBoard.difficulty.isSolvable() ? .isSet : .canSet)
        delegate?.difficultyTextDidChange(sudokuBoard.difficulty.emojiDescription())
        sendCurrentState()
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

// MARK: - Timer Functions (Private)
fileprivate extension MainViewModel
{
    dynamic func timerFired(_: Timer)
    {
        counter += 1
        sendNewTimerText()
    }
    
    func sendNewTimerText()
    {
        let seconds = counter % 60
        let minutes = (counter / 60) % 60
        let hours = counter / 3600
        let elapsedMinutesAndSeconds = String(format: "%.2i:%.2i", minutes, seconds)
        let hoursString = hours == 0 ? "" : String(format: "%.2i:", hours)
        delegate?.timerTextDidChange(hoursString + elapsedMinutesAndSeconds)
    }
}

// MARK: - New Game Functions
fileprivate extension MainViewModel
{
    func titleToDifficulty(_ title: String) -> PuzzleDifficulty
    {
        switch title {
        case newGameDifficulties[1]:    return .easy
        case newGameDifficulties[2]:    return .normal
        case newGameDifficulties[3]:    return .hard
        case newGameDifficulties[4]:    return .insane
        default:                        return .blank
        }
    }
}

// MARK: - SudokuBoard Modification Private Functions
fileprivate extension MainViewModel
{
    func sendCurrentState()
    {
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
    
    func setNumber(_ number: Int, forCellAt index: SudokuBoardIndex)
    {
        guard let cell = sudokuBoard.cellAt(index) else { return }
        if cell.isGiven { return }
        let neighbours = cell.number != nil ? [] : cell.neighbours.filter( {
            self.sudokuBoard.cellAt($0)?.pencilMarks.contains(number) ?? false
        } )
        undoManager.registerUndo(withTarget: self) { [pms = cell.pencilMarks, n = cell.number] undoSelf in
            undoSelf.setNumber(n ?? number, forCellAt: index)
            for pencilMark in pms { undoSelf.setPencilMark(pencilMark, forCellAt: index) }
            undoSelf.updateStateDuringUndoOperation()
        }
        if cell.number == number {
            cell.number = nil
        }
        else {
            cell.pencilMarks.removeAll()
            cell.number = number
            for neighbour in neighbours { setPencilMark(number, forCellAt: neighbour) }
        }
        delegate?.showPencilMarks(Array(cell.pencilMarks), forCellAt: index)
        delegate?.setNumber(convertNumberToString(cell.number), forCellAt: index)
        delegate?.undoStateChanged(undoManager.canUndo)
        if sudokuBoard.isSolved {
            delegate?.gameFinished()
            undoManager.removeAllActions()
            delegate?.undoStateChanged(undoManager.canUndo)
        }
    }
    
    func setPencilMark(_ number: Int, forCellAt index: SudokuBoardIndex)
    {
        guard let cell = sudokuBoard.cellAt(index) else { return }
        if cell.isGiven { return }
        undoManager.registerUndo(withTarget: self) { undoSelf in
            undoSelf.setPencilMark(number, forCellAt: index)
            undoSelf.updateStateDuringUndoOperation()
        }
        if cell.pencilMarks.contains(number)    { cell.pencilMarks.remove(number) }
        else                                    { cell.pencilMarks.insert(number) }
        delegate?.showPencilMarks(Array(cell.pencilMarks), forCellAt: index)
        delegate?.undoStateChanged(undoManager.canUndo)
    }
    
    func highlightCellAt(_ index: SudokuBoardIndex)
    {
        guard let cell = sudokuBoard.cellAt(index) else { return }
        if cell.number != nil {
            highlightCellsContaining(cell.number!)
        }
        else {
            delegate?.sudokuCells(atIndexes: [index], newState: .selected)
            delegate?.sudokuCells(atIndexes: allCellsExcluding(index), newState: .normal)
        }
    }
    
    func highlightCellsContaining(_ number: Int)
    {
        var selectedIndexes = [SudokuBoardIndex]()
        var normalIndexes = [SudokuBoardIndex]()
        for row in 0 ..< sudokuBoard.dimensionality {
            for column in 0 ..< sudokuBoard.dimensionality {
                let cell = sudokuBoard.cellAt(SudokuBoardIndex(row: row, column: column))!
                if cell.number == number || cell.pencilMarks.contains(number) {
                    selectedIndexes.append(SudokuBoardIndex(row: row, column: column))
                }
                else {
                    normalIndexes.append(SudokuBoardIndex(row: row, column: column))
                }
            }
        }
        delegate?.sudokuCells(atIndexes: selectedIndexes, newState: .selected)
        delegate?.sudokuCells(atIndexes: normalIndexes, newState: .normal)
    }
    
    func clearCellAt(_ index: SudokuBoardIndex)
    {
        guard let cell = sudokuBoard.cellAt(index) else { return }
        if !cell.isGiven {
            undoManager.registerUndo(withTarget: self) { [pencilMarks = cell.pencilMarks] undoSelf in
                if cell.number != nil { undoSelf.setNumber(cell.number!, forCellAt: index) }
                for pencilMark in pencilMarks { undoSelf.setPencilMark(pencilMark, forCellAt: index) }
                undoSelf.updateStateDuringUndoOperation()
            }
            cell.number = nil
            cell.pencilMarks.removeAll()
            delegate?.setNumber(convertNumberToString(cell.number), forCellAt: index)
            delegate?.showPencilMarks(Array(cell.pencilMarks), forCellAt: index)
            delegate?.undoStateChanged(undoManager.canUndo)
        }
    }
    
    func allCellsExcluding(_ index: SudokuBoardIndex) -> [SudokuBoardIndex]
    {
        var indexes = [SudokuBoardIndex]()
        for row in 0 ..< sudokuBoard.dimensionality {
            for column in 0 ..< sudokuBoard.dimensionality {
                if SudokuBoardIndex(row: row, column: column) != index {
                    indexes.append(SudokuBoardIndex(row: row, column: column))
                }
            }
        }
        return indexes
    }
    
    func updateStateDuringUndoOperation()
    {
        switch currentState {
        case .highlightCell(let index):                                         highlightCellAt(index)
        case .highlightNumber(let number), .highlightPencilMark(let number):    highlightCellsContaining(number)
        default:                                                                delegate?.removeHighlights()
        }
    }
}

private extension PuzzleDifficulty
{
    func emojiDescription() -> String
    {
        switch self {
        case .blank:                return "🤷‍♀️"
        case .noSolution:           return "😕"
        case .multipleSolutions:    return "🤔"
        case .easy:                 return "😃"
        case .normal:               return "🙂"
        case .hard:                 return "😖"
        case .insane:               return "😭"
        }
    }
    
    func description() -> String
    {
        switch self {
        case .blank:                return "Blank (\(emojiDescription()))"
        case .noSolution:           return "No Solution (\(emojiDescription()))"
        case .multipleSolutions:    return "Multiple Solutions (\(emojiDescription()))"
        case .easy:                 return "Easy (\(emojiDescription()))"
        case .normal:               return "Normal (\(emojiDescription()))"
        case .hard:                 return "Hard (\(emojiDescription()))"
        case .insane:               return "Insane (\(emojiDescription()))"
        }
    }
}
