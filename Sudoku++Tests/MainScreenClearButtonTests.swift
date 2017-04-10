//
//  MainViewModelTests.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 28/03/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import XCTest
import SudokuEngine
@testable import Sudoku__

class MainScreenClearButtonTests: XCTestCase
{
    var emptyIntArray: AnyEquatable = AnyEquatable(base: [Int]())
    
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
    
    func testBeginningStateClearButtonPressed()
    {
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.highlighted))
        viewModel.selectClear(event: .press)
        mockViewModelDelegate.verify()
    }
    
    func testBeginningStateClearButtonActivated()
    {
        mockViewModelDelegate.expect(.removeHighlights)
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.selected))
        viewModel.selectClear(event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
    
    func testBeginningStateClearButtonReleasedNotActivated()
    {
        viewModel.selectClear(event: .press)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.normal))
        viewModel.selectClear(event: .release)
        mockViewModelDelegate.verify()
    }
    
    func testClearButtonSelectedClearButtonPressed()
    {
        viewModel.selectClear(event: .releaseActivate)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.highlighted))
        viewModel.selectClear(event: .press)
        mockViewModelDelegate.verify()
    }
    
    func testClearButtonSelectedClearButtonActivated()
    {
        viewModel.selectClear(event: .releaseActivate)
        viewModel.selectClear(event: .press)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.normal))
        viewModel.selectClear(event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
    
    func testClearButtonPressedButtonReleased()
    {
        viewModel.selectClear(event: .releaseActivate)
        viewModel.selectClear(event: .press)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.selected))
        viewModel.selectClear(event: .release)
        mockViewModelDelegate.verify()
    }
    
    func testClearButtonPressedNumberSelectionActive()
    {
        viewModel.selectNumber(1, event: .releaseActivate)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.highlighted))
        viewModel.selectClear(event: .press)
        mockViewModelDelegate.verify()
    }
    
    func testClearButtonReleasedNumberSelectionActive()
    {
        viewModel.selectNumber(1, event: .releaseActivate)
        viewModel.selectClear(event: .press)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.normal))
        viewModel.selectClear(event: .release)
        mockViewModelDelegate.verify()
    }
    
    func testClearButtonActivatedCellSelected()
    {
        let cell = Cell()
        cell.number = 3
        let index = SudokuBoardIndex(row: 0, column: 0)
        sudokuBoard.stub(.cellAtIndex, andReturn: cell as Cell?)
        viewModel.selectCell(atIndex: index)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.highlighted))
        viewModel.selectClear(event: .press)
        mockViewModelDelegate.verify()
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.normal))
        mockViewModelDelegate.expect(.setNumber, withArgs: AnyEquatable(base: ""), AnyEquatable(base: index))
        mockViewModelDelegate.expect(.showPencilMarks, withArgs: emptyIntArray, AnyEquatable(base: index))
        viewModel.selectClear(event: .releaseActivate)
        mockViewModelDelegate.verify()
        XCTAssertNil(cell.number, "Number not cleared")
        XCTAssertEqual(cell.pencilMarks, [], "Pencilmarks not cleared")
    }
    
    
}




