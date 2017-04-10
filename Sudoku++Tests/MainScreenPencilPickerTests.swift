//
//  MainScreenPencilPickerTests.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 07/04/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import XCTest
import SudokuEngine
@testable import Sudoku__

class MainScreenPencilPickerTests: XCTestCase
{
    fileprivate var emptySudokuBoardIndexArray: AnyEquatable {
        return AnyEquatable(base: Array<SudokuBoardIndex>(), equatableImpl: { rhs in
            return (rhs as? [SudokuBoardIndex]) != nil
        } )
    }
    
    fileprivate var intArrayWithThree: AnyEquatable { return AnyEquatable(base: [3]) }
    
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
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        mockViewModelDelegate.resetMock()
        sudokuBoard.resetMock()
        
    }
    
    func testPencilMarkSelectedCorrectCellsHighlighted()
    {
        let fourCells: [Cell?] = [Cell(), Cell(), Cell(), Cell()]
        fourCells[0]!.number = 1
        fourCells[1]!.pencilMarks.insert(1)
        let highlightedIndexes = [SudokuBoardIndex(row: 0, column: 0), SudokuBoardIndex(row: 0, column: 1)]
        let normalIndexes = [SudokuBoardIndex(row: 1, column: 0), SudokuBoardIndex(row: 1, column: 1)]
        sudokuBoard.stub(.dimensionality, andReturn: 2)
        sudokuBoard.stub(.cellAtIndex, andIterateThroughReturnValues: fourCells)
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: AnyEquatable(base: highlightedIndexes), AnyEquatable(base: ButtonState.selected))
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: AnyEquatable(base: normalIndexes), AnyEquatable(base: ButtonState.normal))
        viewModel.selectPencilMark(1, event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
    
    func testPencilMarkSelectionChangedCorrectCellsHighlighted()
    {
        let fourCells: [Cell?] = [Cell(), Cell(), Cell(), Cell()]
        fourCells[0]!.number = 1
        fourCells[1]!.pencilMarks.insert(1)
        fourCells[2]!.number = 2
        
        let highlightedIndexes = [SudokuBoardIndex(row: 1, column: 0)]
        let normalIndexes = [SudokuBoardIndex(row: 0, column: 0), SudokuBoardIndex(row: 0, column: 1),
            SudokuBoardIndex(row: 1, column: 1)]
        sudokuBoard.stub(.dimensionality, andReturn: 2)
        sudokuBoard.stub(.cellAtIndex, andIterateThroughReturnValues: fourCells)
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: AnyEquatable(base: highlightedIndexes), AnyEquatable(base: ButtonState.selected))
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: AnyEquatable(base: normalIndexes), AnyEquatable(base: ButtonState.normal))
        
        viewModel.selectPencilMark(2, event: .releaseActivate)
        
        mockViewModelDelegate.verify()
    }
    
    func testPencilMarkSelected()
    {
        mockViewModelDelegate.expect(.pencilMarkSelection,
            withArgs: AnyEquatable(base: ButtonState.selected), AnyEquatable(base: 1))
        mockViewModelDelegate.expect(.numberSelection,
            withArgs: AnyEquatable(base: ButtonState.normal), AnyEquatable(base: nil as Int?))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.selected))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.normal))
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.normal))
        viewModel.selectPencilMark(1, event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
    
    func testPencilMarkSelectionChanged()
    {
        viewModel.selectPencilMark(1, event: .releaseActivate)
        mockViewModelDelegate.resetMock()
        
        mockViewModelDelegate.expect(.pencilMarkSelection,
            withArgs: AnyEquatable(base: ButtonState.selected), AnyEquatable(base: 2))
        mockViewModelDelegate.expect(.numberSelection,
            withArgs: AnyEquatable(base: ButtonState.normal), AnyEquatable(base: nil as Int?))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.selected))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.normal))
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.normal))
        viewModel.selectPencilMark(2, event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
    
    func testPencilMarkSelectionCleared()
    {
        viewModel.selectPencilMark(1, event: .releaseActivate)
        mockViewModelDelegate.resetMock()
        
        mockViewModelDelegate.expect(.removeHighlights)
        
        viewModel.selectPencilMark(1, event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
    
    func testPencilMarkSelectionMadeAfterCellSelected()
    {
        let cell = Cell()
        let index = SudokuBoardIndex(row: 0, column: 0)
        sudokuBoard.stub(.cellAtIndex, andReturn: cell as Cell?)
        viewModel.selectCell(atIndex: index)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.showPencilMarks, withArgs: intArrayWithThree, AnyEquatable(base: index))
        mockViewModelDelegate.expect(.pencilMarkSelection,
            withArgs: AnyEquatable(base: ButtonState.normal), AnyEquatable(base: nil as Int?))
        mockViewModelDelegate.expect(.numberSelection,
            withArgs: AnyEquatable(base: ButtonState.normal), AnyEquatable(base: nil as Int?))
        
        viewModel.selectPencilMark(3, event: .releaseActivate)
        mockViewModelDelegate.verify()
        XCTAssertNil(cell.number, "Number set")
        XCTAssertEqual(cell.pencilMarks, [3], "Pencilmark not set")
    }
    
    func testPencilSelectionMadeAfterNumberSelection()
    {
        viewModel.selectNumber(1, event: .releaseActivate)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.pencilMarkSelection,
            withArgs: AnyEquatable(base: ButtonState.selected), AnyEquatable(base: 1))
        mockViewModelDelegate.expect(.numberSelection,
            withArgs: AnyEquatable(base: ButtonState.normal), AnyEquatable(base: nil as Int?))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.selected))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.normal))
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.normal))
        viewModel.selectPencilMark(1, event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
    
    func testPencilSelectionMadeAfterClearSelected()
    {
        viewModel.selectClear(event: .releaseActivate)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.pencilMarkSelection,
            withArgs: AnyEquatable(base: ButtonState.selected), AnyEquatable(base: 1))
        mockViewModelDelegate.expect(.numberSelection,
            withArgs: AnyEquatable(base: ButtonState.normal), AnyEquatable(base: nil as Int?))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.selected))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.normal))
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.normal))
        viewModel.selectPencilMark(1, event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
}


