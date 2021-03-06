//
//  MockViewModelDelegate.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 06/04/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation
import Sudoku__

class MockViewModelDelegate: MainViewModelDelegate, Mock
{
    
    
    enum MockMethod: Int
    {
        case numberSelection
        case pencilMarkSelection
        case clearButton
        case removeHighlights
        case sudokuCellsCellState
        case sudokuCellsButtonState
        case setNumber
        case showPencilMarks
        case timerTextDidChange
        case undoStateChanged
        case gameStateChanged
        case setPuzzleStateChanged
        case newGameStarted
        case difficultyTextDidChange
        case cellAtIndexValidityChanged
    }
    
    func numberSelection(newState: ButtonState, forNumber: Int?)
    {
        registerInvocation(.numberSelection, args: newState, forNumber)
    }
    
    func pencilMarkSelection(newState: ButtonState, forNumber: Int?)
    {
        registerInvocation(.pencilMarkSelection, args: newState, forNumber)
    }
    
    func clearButton(newState: ButtonState)
    {
        registerInvocation(.clearButton, args: newState)
    }
    
    func removeHighlights()
    {
        registerInvocation(.removeHighlights)
    }
    
    func sudokuCells(atIndexes: [SudokuBoardIndex], newState: SudokuCellState)
    {
        registerInvocation(.sudokuCellsCellState, args: atIndexes, newState)
    }
    
    func sudokuCells(atIndexes: [SudokuBoardIndex], newState: ButtonState)
    {
        registerInvocation(.sudokuCellsButtonState, args: atIndexes, newState)
    }
    
    func setNumber(_ number: String, forCellAt: SudokuBoardIndex)
    {
        registerInvocation(.setNumber, args: number, forCellAt)
    }
    
    func showPencilMarks(_ pencilMarks: [Int], forCellAt: SudokuBoardIndex)
    {
        registerInvocation(.showPencilMarks, args: pencilMarks, forCellAt)
    }
    
    func timerTextDidChange(_ text: String)
    {
        registerInvocation(.timerTextDidChange, args: text)
    }
    
    func undoStateChanged(_ canUndo: Bool)
    {
        registerInvocation(.undoStateChanged, args: canUndo)
    }
    
    func gameStateChanged(_ newState: GameState)
    {
        registerInvocation(.gameStateChanged, args: newState)
    }
    
    func setPuzzleStateChanged(_ state: SetPuzzleState)
    {
        registerInvocation(.setPuzzleStateChanged, args: state)
    }
    
    func newGameStarted(
        newState: [(index: SudokuBoardIndex, state: SudokuCellState, number: String, pencilMarks: [Int])]) {
        registerInvocation(.newGameStarted, args: newState)
    }
    
    func difficultyTextDidChange(_ text: String, accessibleText: String)
    {
        registerInvocation(.difficultyTextDidChange, args: text, accessibleText)
    }
    
    func cell(atIndex: SudokuBoardIndex, isValid: Bool)
    {
        registerInvocation(.cellAtIndexValidityChanged, args: atIndex, isValid)
    }
    
    init() { }
    required init?(coder aDecoder: NSCoder) { return nil }
    func encode(with aCoder: NSCoder) { }
}
