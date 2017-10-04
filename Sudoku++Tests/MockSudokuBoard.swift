//
//  MockSudokuBoard.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 06/04/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation
import SudokuEngine

class MockSudokuBoard: NSObject, Mock, SudokuBoardProtocol
{

    enum MockMethod: Int
    {
        case order
        case dimensionality
        case board
        case difficulty
        case difficultyScore
        case isSolved
        case isValid
        case solutionDescription
        case solve
        case markupBoard
        case unmarkBoard
        case setPuzzle
        case cellAtIndex
        case isCellAtIndexValid
    }
    
    var order: Int { return registerInvocation(.order, returning: 0) }
    var dimensionality: Int { return registerInvocation(.dimensionality, returning: 0) }
    var board: [Cell] { return registerInvocation(.board, returning: []) }
    var difficulty: PuzzleDifficulty { return registerInvocation(.difficulty, returning: .blank) }
    var difficultyScore: Int { return registerInvocation(.difficultyScore, returning: 0) }
    var isValid: Bool { return registerInvocation(.isValid, returning: true) }
    var isSolved: Bool { return registerInvocation(.isSolved, returning: false) }
    
    func solve() -> Bool { return registerInvocation(.solve, returning: true) }
    func markupBoard() { registerInvocation(.markupBoard) }
    func unmarkBoard() { registerInvocation(.unmarkBoard) }
    func setPuzzle() -> PuzzleDifficulty { return registerInvocation(.setPuzzle, returning: PuzzleDifficulty.blank) }
    
    func cellAt(_ index: SudokuBoardIndex) -> Cell?
    {
        return registerInvocation(.cellAtIndex, args: index, returning: { (_: Any?...) in nil } )
    }
    
    func isCellAtIndexValid(_ index: SudokuBoardIndex) -> Bool
    {
        return registerInvocation(.isCellAtIndexValid, args: index, returning: false)
    }
    
    override init() { }
    required init?(coder aDecoder: NSCoder) { return nil }
    func encode(with aCoder: NSCoder) { }
}
