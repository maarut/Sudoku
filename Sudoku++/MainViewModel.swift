//
//  MainViewModel.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 15/03/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation
import SudokuEngine

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

// MARK: - SetPuzzleState Definition
public enum SetPuzzleState
{
    case canSet
    case isSet
    case failed(String)
}

// MARK: - GameState Definition
public enum GameState
{
    case playing
    case successfullySolved
    case finished
}

// MARK: - DisplayableDifficulty Implementation
public struct DisplayablePuzzleDifficulty
{
    let displayableText: String
    let accessibleText: String
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
    func cell(atIndex: SudokuBoardIndex, isValid: Bool)
    func setNumber(_: String, forCellAt: SudokuBoardIndex)
    func showPencilMarks(_: [Int], forCellAt: SudokuBoardIndex)
    
    func timerTextDidChange(_: String)
    func difficultyTextDidChange(_: String, accessibleText: String)
    func undoStateChanged(_ canUndo: Bool)
    func setPuzzleStateChanged(_: SetPuzzleState)
    func gameStateChanged(_: GameState)
    func newGameStarted(newState: [
        (index: SudokuBoardIndex, state: SudokuCellState, number: String, pencilMarks: [Int])
        ])
}

// MARK: - MainViewModel Implementation
public class MainViewModel: Archivable
{
    weak var delegate: MainViewModelDelegate?
    fileprivate var currentState = MainScreenState.begin
    fileprivate var sudokuBoard: SudokuBoardProtocol
    fileprivate var timer: Timer!
    fileprivate var counter = 0
    fileprivate let undoManager = UndoManager()
    fileprivate var invalidCells: [SudokuBoardIndex]
    
    var newGameDifficulties: [DisplayablePuzzleDifficulty] = {
        var difficulties = [DisplayablePuzzleDifficulty]()
        for count in PuzzleDifficulty.blank.rawValue ..< Int.max {
            guard let difficulty = PuzzleDifficulty(rawValue: count) else { break }
            switch difficulty {
            case .blank, .easy, .normal, .hard, .insane:
                difficulties.append(DisplayablePuzzleDifficulty(
                    displayableText: difficulty.description(),
                    accessibleText: difficulty.accessibleDescription()))
                break
            default:
                break
            }
        }
        return difficulties
    }()

    init(withSudokuBoard b: SudokuBoardProtocol)
    {
        sudokuBoard = b
        invalidCells = []
    }
    
    public required init?(fromArchive archive: NSDictionary)
    {
        if let sudokuBoard = archive["sudokuBoard"] as? SudokuBoard,
            let counter = archive["counter"] as? Int,
            let rows = archive["invalidRows"] as? [Int],
            let columns = archive["invalidColumns"] as? [Int] {
            self.sudokuBoard = sudokuBoard
            self.counter = counter
            self.invalidCells = zip(rows, columns).map( { SudokuBoardIndex(row: $0.0, column: $0.1) } )
        }
        else {
            return nil
        }
    }
    
    func archivableFormat() -> NSDictionary
    {
        let representation: [String: AnyObject] = [
            "sudokuBoard": sudokuBoard,
            "counter": counter as NSNumber,
            "invalidRows": invalidCells.map( { $0.row } ) as NSArray,
            "invalidColumns": invalidCells.map( { $0.column } ) as NSArray,
        ]
        return representation as NSDictionary
    }
    
    func undo()
    {
        undoManager.undo()
        delegate?.undoStateChanged(undoManager.canUndo)
    }
    
    func startTimer()
    {
        if timer == nil && sudokuBoard.difficulty != .blank && !sudokuBoard.isSolved {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerFired(_:)),
                userInfo: nil, repeats: true)
        }
        sendNewTimerText()
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
        for invalidCell in invalidCells { delegate?.cell(atIndex: invalidCell, isValid: true) }
        invalidCells = []
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
        delegate?.gameStateChanged(.playing)
        delegate?.difficultyTextDidChange(sudokuBoard.difficulty.emojiDescription(),
            accessibleText: sudokuBoard.difficulty.accessibleDescription())
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
                let index = SudokuBoardIndex(row: row, column: column)
                let cell = sudokuBoard.cellAt(index)!
                if let number = cell.number { delegate?.setNumber(convertNumberToString(number), forCellAt: index) }
                else { delegate?.showPencilMarks(Array(cell.pencilMarks), forCellAt: index) }
                if cell.isGiven { givenCells.append(index) }
                else            { editableCells.append(index) }
            }
        }
        for index in invalidCells { delegate?.cell(atIndex: index, isValid: false) }
        for index in allCellsExcluding(invalidCells) { delegate?.cell(atIndex: index, isValid: true) }
        delegate?.sudokuCells(atIndexes: givenCells, newState: .given)
        delegate?.sudokuCells(atIndexes: editableCells, newState: .editable)
        delegate?.undoStateChanged(undoManager.canUndo)
        delegate?.setPuzzleStateChanged(sudokuBoard.difficulty.isSolvable() ? .isSet : .canSet)
        delegate?.difficultyTextDidChange(sudokuBoard.difficulty.emojiDescription(),
            accessibleText: sudokuBoard.difficulty.accessibleDescription())
        delegate?.gameStateChanged(sudokuBoard.isSolved ? .finished : .playing)
        sendCurrentState()
    }
    
    func fillInPencilMarks()
    {
        guard !sudokuBoard.isSolved else { return }
        undoManager.registerUndo(withTarget: self, handler: { undoSelf in
            undoSelf.sudokuBoard.unmarkBoard()
            undoSelf.sendPencilMarks()
            undoSelf.updateStateDuringUndoOperation()
        })
        sudokuBoard.markupBoard()
        sendPencilMarks()
        delegate?.undoStateChanged(undoManager.canUndo)
        
    }
    
    func revealSolution()
    {
        guard !sudokuBoard.isSolved else { return }
        stopTimer()
        for row in 0 ..< sudokuBoard.dimensionality {
            for column in 0 ..< sudokuBoard.dimensionality {
                let index = SudokuBoardIndex(row: row, column: column)
                let cell = sudokuBoard.cellAt(index)!
                if cell.number != cell.solution {
                    cell.number = cell.solution
                    cell.pencilMarks.removeAll()
                    delegate?.setNumber(convertNumberToString(cell.number), forCellAt: index)
                }
            }
        }
        sendCurrentState()
        delegate?.gameStateChanged(.finished)
        undoManager.removeAllActions()
        delegate?.undoStateChanged(undoManager.canUndo)
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
        case newGameDifficulties[1].displayableText:    return .easy
        case newGameDifficulties[2].displayableText:    return .normal
        case newGameDifficulties[3].displayableText:    return .hard
        case newGameDifficulties[4].displayableText:    return .insane
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
        if !sudokuBoard.isCellAtIndexValid(index) && !invalidCells.contains(index) {
            invalidCells.append(index)
            delegate?.cell(atIndex: index, isValid: false)
        }
        else if sudokuBoard.isCellAtIndexValid(index) && invalidCells.contains(index) {
            invalidCells.removeFirst(element: index)
            delegate?.cell(atIndex: index, isValid: true)
        }
        delegate?.showPencilMarks(Array(cell.pencilMarks), forCellAt: index)
        delegate?.setNumber(convertNumberToString(cell.number), forCellAt: index)
        delegate?.undoStateChanged(undoManager.canUndo)
        if sudokuBoard.isSolved {
            stopTimer()
            delegate?.gameStateChanged(.successfullySolved)
            delegate?.gameStateChanged(.finished)
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
            undoManager.registerUndo(withTarget: self) {
                [pencilMarks = cell.pencilMarks, number = cell.number] undoSelf in
                if number != nil { undoSelf.setNumber(number!, forCellAt: index) }
                for pencilMark in pencilMarks { undoSelf.setPencilMark(pencilMark, forCellAt: index) }
                undoSelf.updateStateDuringUndoOperation()
            }
            cell.number = nil
            cell.pencilMarks.removeAll()
            delegate?.setNumber(convertNumberToString(cell.number), forCellAt: index)
            delegate?.showPencilMarks(Array(cell.pencilMarks), forCellAt: index)
            delegate?.undoStateChanged(undoManager.canUndo)
            if let i = invalidCells.removeFirst(element: index) {
                delegate?.cell(atIndex: i, isValid: true)
            }
        }
    }
    
    func allCells() -> [SudokuBoardIndex]
    {
        var indexes = [SudokuBoardIndex]()
        for row in 0 ..< sudokuBoard.dimensionality {
            for column in 0 ..< sudokuBoard.dimensionality {
                indexes.append(SudokuBoardIndex(row: row, column: column))
            }
        }
        return indexes
    }
    
    func allCellsExcluding(_ indexes: [SudokuBoardIndex]) -> [SudokuBoardIndex]
    {
        var cells = allCells()
        for index in indexes {
            cells.removeFirst(element: index)
        }
        return cells
    }
    
    func allCellsExcluding(_ index: SudokuBoardIndex) -> [SudokuBoardIndex]
    {
        return allCellsExcluding([index])
    }
    
    func updateStateDuringUndoOperation()
    {
        switch currentState {
        case .highlightCell(let index):                                         highlightCellAt(index)
        case .highlightNumber(let number), .highlightPencilMark(let number):    highlightCellsContaining(number)
        default:                                                                delegate?.removeHighlights()
        }
    }
    
    func sendPencilMarks()
    {
        for (index, cell) in allCells().map( { ($0, sudokuBoard.cellAt($0)!) } ) {
            if cell.number == nil {
                delegate?.showPencilMarks(Array(cell.pencilMarks), forCellAt: index)
            }
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
        case .blank:                return "Blank \(emojiDescription())"
        case .noSolution:           return "No Solution \(emojiDescription())"
        case .multipleSolutions:    return "Multiple Solutions \(emojiDescription())"
        case .easy:                 return "Easy \(emojiDescription())"
        case .normal:               return "Normal \(emojiDescription())"
        case .hard:                 return "Hard \(emojiDescription())"
        case .insane:               return "Insane \(emojiDescription())"
        }
    }
    
    func accessibleDescription() -> String
    {
        switch self {
        case .blank:                return "Blank"
        case .noSolution:           return "No Solution"
        case .multipleSolutions:    return "Multiple Solutions"
        case .easy:                 return "Easy"
        case .normal:               return "Normal"
        case .hard:                 return "Hard"
        case .insane:               return "Insane"
        }
    }
}
