//
//  MainScreenNumberPickerTests.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 06/04/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import XCTest
import SudokuEngine
@testable import Sudoku__

class MainScreenNumberPickerTests: XCTestCase
{
    fileprivate var emptySudokuBoardIndexArray: AnyEquatable {
        return AnyEquatable(base: Array<SudokuBoardIndex>(), equatableImpl: { rhs in
            return (rhs as? [SudokuBoardIndex]) != nil
        } )
    }
    
    fileprivate var emptyIntArray: AnyEquatable { return AnyEquatable(base: [Int]()) }
    
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
    
    func testNumberSelectedCorrectCellsHighlighted()
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
        viewModel.selectNumber(1, event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
    
    func testNumberSelectionChangedCorrectCellsHighlighted()
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
        
        viewModel.selectNumber(2, event: .releaseActivate)
        
        mockViewModelDelegate.verify()
    }
    
    func testNumberSelected()
    {
        mockViewModelDelegate.expect(.pencilMarkSelection,
            withArgs: AnyEquatable(base: ButtonState.normal), AnyEquatable(base: nil as Int?))
        mockViewModelDelegate.expect(.numberSelection,
            withArgs: AnyEquatable(base: ButtonState.selected), AnyEquatable(base: 1))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.selected))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.normal))
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.normal))
        viewModel.selectNumber(1, event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
    
    func testNumberSelectionChanged()
    {
        
        viewModel.selectNumber(1, event: .releaseActivate)
        mockViewModelDelegate.resetMock()
        
        mockViewModelDelegate.expect(.pencilMarkSelection,
            withArgs: AnyEquatable(base: ButtonState.normal), AnyEquatable(base: nil as Int?))
        mockViewModelDelegate.expect(.numberSelection,
            withArgs: AnyEquatable(base: ButtonState.selected), AnyEquatable(base: 2))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.selected))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.normal))
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.normal))
        viewModel.selectNumber(2, event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
    
    func testNumberSelectionCleared()
    {
        viewModel.selectNumber(1, event: .releaseActivate)
        mockViewModelDelegate.resetMock()
        
        mockViewModelDelegate.expect(.removeHighlights)
        
        viewModel.selectNumber(1, event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
    
    func testNumberSelectionMadeAfterCellSelected()
    {
        let cell = Cell()
        let index = SudokuBoardIndex(row: 0, column: 0)
        sudokuBoard.stub(.cellAtIndex, andReturn: cell as Cell?)
        viewModel.selectCell(atIndex: index)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.setNumber, withArgs: AnyEquatable(base: "3"), AnyEquatable(base: index))
        mockViewModelDelegate.expect(.showPencilMarks, withArgs: emptyIntArray, AnyEquatable(base: index))
        mockViewModelDelegate.expect(.pencilMarkSelection,
            withArgs: AnyEquatable(base: ButtonState.normal), AnyEquatable(base: nil as Int?))
        mockViewModelDelegate.expect(.numberSelection,
            withArgs: AnyEquatable(base: ButtonState.normal), AnyEquatable(base: nil as Int?))
        
        viewModel.selectNumber(3, event: .releaseActivate)
        mockViewModelDelegate.verify()
        XCTAssertEqual(3, cell.number, "Number not set")
        XCTAssertEqual(cell.pencilMarks, [], "Pencilmarks not cleared")
    }
    
    func testNumberSelectionMadeAfterPencilSelection()
    {
        viewModel.selectPencilMark(1, event: .releaseActivate)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.pencilMarkSelection,
            withArgs: AnyEquatable(base: ButtonState.normal), AnyEquatable(base: nil as Int?))
        mockViewModelDelegate.expect(.numberSelection,
            withArgs: AnyEquatable(base: ButtonState.selected), AnyEquatable(base: 1))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.selected))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.normal))
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.normal))
        viewModel.selectNumber(1, event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
    
    func testNumberSelectionMadeAfterClearSelected()
    {
        viewModel.selectClear(event: .releaseActivate)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.pencilMarkSelection,
            withArgs: AnyEquatable(base: ButtonState.normal), AnyEquatable(base: nil as Int?))
        mockViewModelDelegate.expect(.numberSelection,
            withArgs: AnyEquatable(base: ButtonState.selected), AnyEquatable(base: 1))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.selected))
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: emptySudokuBoardIndexArray, AnyEquatable(base: ButtonState.normal))
        mockViewModelDelegate.expect(.clearButton, withArgs: AnyEquatable(base: ButtonState.normal))
        viewModel.selectNumber(1, event: .releaseActivate)
        mockViewModelDelegate.verify()
    }
}

