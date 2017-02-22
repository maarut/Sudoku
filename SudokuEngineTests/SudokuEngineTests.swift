//
//  SudokuEngineTests.swift
//  SudokuEngineTests
//
//  Created by Maarut Chandegra on 03/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import XCTest
@testable import SudokuEngine

private let puzzle = [0, 0, 0, 0, 0, 0, 0, 0, 0,
                      9, 0, 0, 0, 0, 0, 0, 8, 4,
                      0, 6, 2, 3, 0, 0, 0, 5, 0,
                      0, 0, 0, 6, 0, 0, 0, 4, 5,
                      3, 0, 0, 0, 1, 0, 0, 0, 6,
                      0, 0, 0, 9, 0, 0, 0, 7, 0,
                      0, 0, 0, 1, 0, 0, 0, 0, 0,
                      4, 0, 5, 0, 0, 2, 0, 0, 0,
                      0, 3, 0, 8, 0, 0, 0, 0, 9]

class SudokuEngineTests: XCTestCase
{
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGenerate()
    {
        self.measure {
            let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .insane)
            XCTAssertNotNil(board)
        }
    }
    
    func testGenerateFailure()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 0, difficulty: .easy)
        XCTAssertNil(board)
    }
    
    func testSolveInvalidPuzzle()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)
        for (i, number) in puzzle.enumerated() { board?.board[i].number = number == 0 ? nil : number }
        XCTAssertTrue(board?.solve() ?? false)
    }
    
    func testSolve()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .insane)!
        self.measure {
            let b = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
            for i in 0 ..< Int(b.board.count) {
                b.board[i].number = board.board[i].number
                b.board[i].isGiven = board.board[i].isGiven
            }
            XCTAssertTrue(b.solve())
            XCTAssertEqual(b.difficulty, board.difficulty)
        }
    }
    
    func testSudokuBoardIsSolved()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .easy)!
        board.board.forEach { $0.number = $0.solution }
        XCTAssertTrue(board.isSolved)
    }
    
    func testSudokuBoardIsNotSolved()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .easy)!
        XCTAssertFalse(board.isSolved)
    }
    
    func testSudokuBoardHasSolution()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .easy)!
        XCTAssertTrue(board.hasUniqueSolution)
    }
    
    func testBlankSudokuBoardHasNoSolution()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        XCTAssertFalse(board.hasUniqueSolution)
    }
    
    func testFilledSetBlankSudokuBoardHasSolution()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        for (i, cell) in board.board.enumerated() {
            cell.number = puzzle[i]
        }
        board.setPuzzle()
        XCTAssertTrue(board.hasUniqueSolution)
    }
    
    func testFilledUnsetBlankSudokuBoardHasSolution()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        for (i, cell) in board.board.enumerated() {
            cell.number = puzzle[i]
        }
        XCTAssertFalse(board.hasUniqueSolution)
    }
    
    func testMarkupBoard()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        board.markupBoard()
        let pencilMarks = Set(1 ... board.dimensionality)
        for cell in board.board {
            XCTAssertEqual(pencilMarks, cell.pencilMarks)
        }
    }
    
    func testUnmarkBoard()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        board.markupBoard()
        for cell in board.board {
            XCTAssertFalse(cell.pencilMarks.isEmpty)
        }
        board.unmarkBoard()
        for cell in board.board {
            XCTAssertTrue(cell.pencilMarks.isEmpty)
        }
    }
    
    func testSetPuzzle()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        for (i, cell) in board.board.enumerated() { if puzzle[i] > 0 { cell.number = puzzle[i] } }
        
        board.setPuzzle()
        
        for (i, cell) in board.board.enumerated() { XCTAssertEqual(puzzle[i] != 0, cell.isGiven) }
        XCTAssertEqual(.insane, board.difficulty)
    }
    
    func testSetPuzzleWithInvalidPuzzle()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        for (i, cell) in board.board.enumerated() { if puzzle[i] > 0 { cell.number = puzzle[i] } }
        board.board.last?.number = 0
        
        board.setPuzzle()
        XCTAssertEqual(.multipleSolutions, board.difficulty)
    }
}
