//
//  MainScreenUndoTests.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 11/04/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import XCTest
import SudokuEngine
@testable import Sudoku__

class MainScreenUndoTests: XCTestCase {
        
    fileprivate var mockViewModelDelegate: MockViewModelDelegate!
    fileprivate var sudokuBoard: MockSudokuBoard!
    fileprivate var viewModel: MainViewModel!
    
    override func setUp()
    {
        super.setUp()
        mockViewModelDelegate = MockViewModelDelegate()
        sudokuBoard = MockSudokuBoard()
        viewModel = MainViewModel(withSudokuBoard: sudokuBoard)
        viewModel.delegate = mockViewModelDelegate
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown()
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        mockViewModelDelegate.resetMock()
        sudokuBoard.resetMock()
        
    }
    
    func testUndoNotAvailableAtStart()
    {
        mockViewModelDelegate.expect(.undoStateChanged, withArgs: AnyEquatable(base: false))
        viewModel.undo()
        mockViewModelDelegate.verify()
    }
    
    func testUndoOfNumberEntry()
    {
        let cell = Cell()
        sudokuBoard.stub(.cellAtIndex, andReturn: cell as Cell?)
        viewModel.selectNumber(1, event: .releaseActivate)
        viewModel.selectCell(atIndex: SudokuBoardIndex(row: 0, column: 0))
        
        viewModel.undo()
        XCTAssertNil(cell.number)
    }
    
    func testUndoOfNumberWithPencilMarksVisible()
    {
        let cell = Cell()
        cell.pencilMarks = [1,2,3]
        sudokuBoard.stub(.cellAtIndex, andReturn: cell as Cell?)
        viewModel.selectNumber(1, event: .releaseActivate)
        viewModel.selectCell(atIndex: SudokuBoardIndex(row: 0, column: 0))
        
        XCTAssertEqual(1, cell.number)
        XCTAssertEqual([], cell.pencilMarks)
        
        viewModel.undo()
        XCTAssertNil(cell.number)
        XCTAssertEqual([1,2,3], cell.pencilMarks)
    }
    
    func testUndoOfPencilMarkEntry()
    {
        let cell = Cell()
        cell.pencilMarks = [1,2,3]
        sudokuBoard.stub(.cellAtIndex, andReturn: cell as Cell?)
        viewModel.selectPencilMark(4, event: .releaseActivate)
        viewModel.selectCell(atIndex: SudokuBoardIndex(row: 0, column: 0))
        
        XCTAssertEqual([1,2,3,4], cell.pencilMarks)
        
        viewModel.undo()
        XCTAssertNil(cell.number)
        XCTAssertEqual([1,2,3], cell.pencilMarks)
        
    }
}
