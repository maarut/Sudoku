//
//  MainScreenUIStateMachine.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 15/03/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

enum MainScreenAction
{
    case selectedCell(row: Int, column: Int)
    case selectedPencilMark(Int)
    case selectedNumber(Int)
    case selectedClear
}

enum MainScreenState
{
    case highlightCell(row: Int, column: Int)
    case highlightPencilMark(Int)
    case highlightNumber(Int)
    case highlightClear
    case begin
    
    func advanceWith(action: MainScreenAction) -> MainScreenState
    {
        switch self {
        case .highlightCell(row: let row, column: let column):
            switch action {
            case .selectedClear, .selectedNumber(_), .selectedPencilMark(_): return self
            case .selectedCell(row: let newRow, column: let newColumn):
                return (row != newRow || column != newColumn) ? .highlightCell(row: newRow, column: newColumn) : .begin
            }
        case .highlightPencilMark(let pencilMark):
            switch action {
            case .selectedCell(row: _, column: _):          return self
            case .selectedClear:                            return .highlightClear
            case .selectedNumber(let number):               return .highlightNumber(number)
            case .selectedPencilMark(let newPencilMark):
                return pencilMark == newPencilMark ? .begin : .highlightPencilMark(newPencilMark)
            }
        case .highlightNumber(let number):
            switch action {
            case .selectedCell(row: _, column: _):          return self
            case .selectedClear:                            return .highlightClear
            case .selectedPencilMark(let newPencilMark):    return .highlightPencilMark(newPencilMark)
            case .selectedNumber(let newNumber):
                return number == newNumber ? .begin : .highlightNumber(newNumber)
            }
        case .highlightClear:
            switch action {
            case .selectedCell(row: _, column: _):      return self
            case .selectedClear:                        return .begin
            case .selectedNumber(let number):           return .highlightNumber(number)
            case .selectedPencilMark(let pencilMark):   return .highlightPencilMark(pencilMark)
            }
        case .begin:
            switch action {
            case .selectedCell(row: let row, column: let column):   return .highlightCell(row: row, column: column)
            case .selectedClear:                                    return .highlightClear
            case .selectedNumber(let number):                       return .highlightNumber(number)
            case .selectedPencilMark(let pencilMark):               return .highlightPencilMark(pencilMark)
            }
        }
    }
}
