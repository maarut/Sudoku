//
//  Sudoku__Tests.swift
//  Sudoku++Tests
//
//  Created by Maarut Chandegra on 03/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import XCTest
@testable import Sudoku__

private let puzzle = [0, 0, 0, 0, 0, 0, 0, 0, 0,
              9, 0, 0, 0, 0, 0, 0, 8, 4,
              0, 6, 2, 3, 0, 0, 0, 5, 0,
              0, 0, 0, 6, 0, 0, 0, 4, 5,
              3, 0, 0, 0, 1, 0, 0, 0, 6,
              0, 0, 0, 9, 0, 0, 0, 7, 0,
              0, 0, 0, 1, 0, 0, 0, 0, 0,
              4, 0, 5, 0, 0, 2, 0, 0, 0,
              0, 3, 0, 8, 0, 0, 0, 0, 9]

class Sudoku__Tests: XCTestCase
{
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPerformanceCCreate()
    {
        self.measure {
            for _ in 0 ..< 10000 {
                let b = generatePuzzleWithOrder(3, MCPuzzleDifficultyZero)
                destroyContext(b)
            }
        }
    }
    
    func testGenerate()
    {
        self.measure {
            for _ in 0 ..< 1 {
                let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .insane)
                XCTAssertNotNil(board)
//                NSLog("\(board?.description ?? "")")
            }
        }
    }
    
    func testSolve()
    {
        self.measure {
            for _ in 0 ..< 100 {
                let board = SudokuBoard.generatePuzzle(ofOrder: 3, difficulty: .blank)!
                for (index, cell) in board.board.enumerated() {
                    cell.number = puzzle[index]
                    cell.isGiven = puzzle[index] != 0
                }
                XCTAssertTrue(board.solve())
            }
        }
    }
    
    func testSolveC()
    {
        let board = generatePuzzleWithOrder(3, MCPuzzleDifficultyInsane)!
        for _ in 0 ..< 100 {
            let b = generatePuzzleWithOrder(3, MCPuzzleDifficultyZero)!
            for i in 0 ..< Int(b.pointee.cellCount) { b.pointee.problem[i] = board.pointee.problem[i] }
            XCTAssertTrue(solveContext(b) != 0)
            XCTAssertEqual(b.pointee.difficulty, board.pointee.difficulty)
            XCTAssertEqual(b.pointee.difficultyScore, board.pointee.difficultyScore)
        }
    }
}
