//
//  MainScreenSudokuBoardTests.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 08/04/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import XCTest
import SudokuEngine
@testable import Sudoku__

class MainScreenSudokuBoardTests: XCTestCase
{
    
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
    
    func testBlankCellHighlighted()
    {
        let cells = [Cell(), Cell(), Cell(), Cell()] as [Cell?]
        let highlightedIndex = SudokuBoardIndex(row: 0, column: 0)
        let normalIndexes = [SudokuBoardIndex(row: 0, column: 1), SudokuBoardIndex(row: 1, column: 0),
            SudokuBoardIndex(row: 1, column: 1)]
        sudokuBoard.stub(.cellAtIndex, andIterateThroughReturnValues: cells)
        sudokuBoard.stub(.dimensionality, andReturn: 2)
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: AnyEquatable(base: [highlightedIndex]), AnyEquatable(base: ButtonState.selected))
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: AnyEquatable(base: normalIndexes), AnyEquatable(base: ButtonState.normal))
        
        viewModel.selectCell(atIndex: highlightedIndex)
        mockViewModelDelegate.verify()
    }
    
    func testBlankCellSelectionChanged()
    {
        let cells = [Cell(), Cell(), Cell(), Cell()] as [Cell?]
        let highlightedIndex = SudokuBoardIndex(row: 0, column: 0)
        let normalIndexes = [SudokuBoardIndex(row: 0, column: 1), SudokuBoardIndex(row: 1, column: 0),
            SudokuBoardIndex(row: 1, column: 1)]
        cells.first??.number = 1
        cells.dropFirst().forEach( { $0?.number = 2 } )
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[0],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 0, column: 0)))
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[1],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 0, column: 1)))
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[2],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 1, column: 0)))
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[3],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 1, column: 1)))
        sudokuBoard.stub(.dimensionality, andReturn: 2)
        
        viewModel.selectCell(atIndex: SudokuBoardIndex(row: 1, column: 1))
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: AnyEquatable(base: [highlightedIndex]), AnyEquatable(base: ButtonState.selected))
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: AnyEquatable(base: normalIndexes), AnyEquatable(base: ButtonState.normal))
        
        viewModel.selectCell(atIndex: highlightedIndex)
        mockViewModelDelegate.verify()
    }
    
    func testCellWithNumberAllCellsWithNumberHighlighted()
    {
        let cells = [Cell(), Cell(), Cell(), Cell()] as [Cell?]
        let normalIndex = SudokuBoardIndex(row: 0, column: 0)
        let highlightedIndexes = [SudokuBoardIndex(row: 0, column: 1), SudokuBoardIndex(row: 1, column: 0),
            SudokuBoardIndex(row: 1, column: 1)]
        cells.first??.number = 1
        cells.dropFirst().forEach( { $0?.number = 2 } )
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[0],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 0, column: 0)))
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[1],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 0, column: 1)))
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[2],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 1, column: 0)))
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[3],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 1, column: 1)))
        sudokuBoard.stub(.dimensionality, andReturn: 2)
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: AnyEquatable(base: highlightedIndexes), AnyEquatable(base: ButtonState.selected))
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: AnyEquatable(base: [normalIndex]), AnyEquatable(base: ButtonState.normal))
        viewModel.selectCell(atIndex: SudokuBoardIndex(row: 1, column: 1))
        
        mockViewModelDelegate.verify()
    }
    
    func testCellWithPencilMarksOnlyHighlighted()
    {
        let cells = [Cell(), Cell(), Cell(), Cell()] as [Cell?]
        cells.first??.pencilMarks = [1, 2, 3]
        cells.last??.number = 3
        let highlightedIndex = SudokuBoardIndex(row: 0, column: 0)
        let normalIndexes = [SudokuBoardIndex(row: 0, column: 1), SudokuBoardIndex(row: 1, column: 0),
            SudokuBoardIndex(row: 1, column: 1)]
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[0],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 0, column: 0)))
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[1],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 0, column: 1)))
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[2],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 1, column: 0)))
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[3],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 1, column: 1)))
        sudokuBoard.stub(.dimensionality, andReturn: 2)
        
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: AnyEquatable(base: [highlightedIndex]), AnyEquatable(base: ButtonState.selected))
        mockViewModelDelegate.expect(.sudokuCellsButtonState,
            withArgs: AnyEquatable(base: normalIndexes), AnyEquatable(base: ButtonState.normal))
        
        viewModel.selectCell(atIndex: highlightedIndex)
        
        mockViewModelDelegate.verify()
    }
    
    func testDeselectCell()
    {
        let cells = [Cell(), Cell(), Cell(), Cell()] as [Cell?]
        let indexes = [SudokuBoardIndex(row: 0, column: 0), SudokuBoardIndex(row: 0, column: 1),
            SudokuBoardIndex(row: 1, column: 0), SudokuBoardIndex(row: 1, column: 1)]
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[0],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 0, column: 0)))
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[1],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 0, column: 1)))
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[2],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 1, column: 0)))
        sudokuBoard.stub(.cellAtIndex, andReturn: cells[3],
            expectingArguments: AnyEquatable(base: SudokuBoardIndex(row: 1, column: 1)))
        sudokuBoard.stub(.dimensionality, andReturn: 2)
        viewModel.selectCell(atIndex: indexes.first!)
        mockViewModelDelegate.resetMock()
        mockViewModelDelegate.expect(.removeHighlights)
        
        viewModel.selectCell(atIndex: indexes.first!)
        mockViewModelDelegate.verify()
    }
    
    func testAddPencilMarksWhenGameIsSolved()
    {
        sudokuBoard.stub(.isSolved, andReturn: true)
        viewModel.fillInPencilMarks()
        sudokuBoard.verify()
        mockViewModelDelegate.verify()
    }
}
