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
        if let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank) {
            for (i, number) in puzzle.enumerated() {
                let row = i / board.dimensionality
                let column = i % board.dimensionality
                board.cellAt(SudokuBoardIndex(row: row, column: column))?.number = number == 0 ? nil : number
            }
            XCTAssertTrue(board.solve())
        }
        else {
            XCTFail("Board not created")
        }
    }
    
    func testSolve()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .insane)!
        self.measure {
            let b = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
            for row in 0 ..< b.dimensionality {
                for column in 0 ..< b.dimensionality {
                    let index = SudokuBoardIndex(row: row, column: column)
                    b.cellAt(index)!.number = board.cellAt(index)!.number
                    b.cellAt(index)!.isGiven = board.cellAt(index)!.isGiven
                }
            }
            XCTAssertTrue(b.solve())
            XCTAssertEqual(b.difficulty, board.difficulty)
        }
    }
    
    func testSudokuBoardIsSolved()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .easy)!
        for row in 0 ..< board.dimensionality {
            for column in 0 ..< board.dimensionality {
                let cell = board.cellAt(SudokuBoardIndex(row: row, column: column))!
                cell.number = cell.solution
            }
        }
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
        XCTAssertTrue(board.difficulty.isSolvable())
    }
    
    func testBlankSudokuBoardHasNoSolution()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        XCTAssertFalse(board.difficulty.isSolvable())
    }
    
    func testFilledSetBlankSudokuBoardHasSolution()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        for (i, number) in puzzle.enumerated() {
            if number == 0 { continue }
            let row = i / board.dimensionality
            let column = i % board.dimensionality
            let cell = board.cellAt(SudokuBoardIndex(row: row, column: column))!
            cell.number = number
        }
        let difficulty = board.setPuzzle()
        XCTAssertTrue(difficulty.isSolvable())
        XCTAssertTrue(board.difficulty.isSolvable())
    }
    
    func testFilledUnsetBlankSudokuBoardHasSolution()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        for (i, number) in puzzle.enumerated() {
            if number == 0 { continue }
            let row = i / board.dimensionality
            let column = i % board.dimensionality
            let cell = board.cellAt(SudokuBoardIndex(row: row, column: column))!
            cell.number = number
        }
        XCTAssertFalse(board.difficulty.isSolvable())
    }
    
    func testMarkupBoard()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        board.markupBoard()
        let pencilMarks = Set(1 ... board.dimensionality)
        for row in 0 ..< board.dimensionality {
            for column in 0 ..< board.dimensionality {
                let cell = board.cellAt(SudokuBoardIndex(row: row, column: column))!
                XCTAssertEqual(pencilMarks, cell.pencilMarks)
            }
        }
    }
    
    func testUnmarkBoard()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        board.markupBoard()
        for row in 0 ..< board.dimensionality {
            for column in 0 ..< board.dimensionality {
                let cell = board.cellAt(SudokuBoardIndex(row: row, column: column))!
                XCTAssertFalse(cell.pencilMarks.isEmpty)
            }
        }
        board.unmarkBoard()
        for row in 0 ..< board.dimensionality {
            for column in 0 ..< board.dimensionality {
                let cell = board.cellAt(SudokuBoardIndex(row: row, column: column))!
                XCTAssertTrue(cell.pencilMarks.isEmpty)
            }
        }
    }
    
    func testSetPuzzle()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        for row in 0 ..< board.dimensionality {
            for column in 0 ..< board.dimensionality {
                let cell = board.cellAt(SudokuBoardIndex(row: row, column: column))!
                let index = row * board.dimensionality + column
                if puzzle[index] > 0 { cell.number = puzzle[index] }
            }
        }
        
        let difficulty = board.setPuzzle()
        for row in 0 ..< board.dimensionality {
            for column in 0 ..< board.dimensionality {
                let cell = board.cellAt(SudokuBoardIndex(row: row, column: column))!
                let index = row * board.dimensionality + column
                XCTAssertEqual(puzzle[index] != 0, cell.isGiven)
            }
        }
        XCTAssertEqual(.insane, board.difficulty)
        XCTAssertEqual(.insane, difficulty)
    }
    
    func testSetPuzzleWithInvalidPuzzle()
    {
        let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
        for row in 0 ..< board.dimensionality {
            for column in 0 ..< board.dimensionality {
                let cell = board.cellAt(SudokuBoardIndex(row: row, column: column))!
                let index = row * board.dimensionality + column
                if puzzle[index] > 0 { cell.number = puzzle[index] }
            }
        }
        board.cellAt(SudokuBoardIndex(row: 8, column: 8))?.number = nil
        
        let difficulty = board.setPuzzle()
        XCTAssertEqual(.multipleSolutions, difficulty)
        XCTAssertEqual(.blank, board.difficulty)
    }
}
