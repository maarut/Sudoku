//
//  MCSudokuEngineBridge.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 03/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation
import SudokuEngineC

// MARK: - Type Aliases
public struct SudokuBoardIndex: Equatable
{
    public let row: Int
    public let column: Int
    
    public init(row: Int, column: Int) { self.row = row; self.column = column }
    
    public static func ==(lhs: SudokuBoardIndex, rhs: SudokuBoardIndex) -> Bool
    {
        return lhs.column == rhs.column && lhs.row == rhs.row
    }
}

// MARK: - SudokuBoardProtocol Definition
public protocol SudokuBoardProtocol: NSCoding
{
    var order: Int { get }
    var dimensionality: Int { get }
    var difficulty: PuzzleDifficulty { get }
    var difficultyScore: Int { get }
    
    var isSolved: Bool { get }
    
    func solve() -> Bool
    func markupBoard()
    func unmarkBoard()
    func setPuzzle() -> PuzzleDifficulty
    func cellAt(_ index: SudokuBoardIndex) -> Cell?
    
}

// MARK: - PuzzleDifficulty Enum
public enum PuzzleDifficulty: Int
{
    case blank
    case noSolution
    case multipleSolutions
    case easy
    case normal
    case hard
    case insane
    
    fileprivate init(difficulty: MCPuzzleDifficulty)
    {
        switch difficulty {
        case MCPuzzleDifficultyEasy:    self = .easy
        case MCPuzzleDifficultyNormal:  self = .normal
        case MCPuzzleDifficultyHard:    self = .hard
        case MCPuzzleDifficultyInsane:  self = .insane
        default:                        self = .blank
        }
    }
    
    fileprivate func toMCPuzzleDifficulty() -> MCPuzzleDifficulty
    {
        switch self {
        case .easy:     return MCPuzzleDifficultyEasy
        case .normal:   return MCPuzzleDifficultyNormal
        case .hard:     return MCPuzzleDifficultyHard
        case .insane:   return MCPuzzleDifficultyInsane
        default:        return MCPuzzleDifficultyZero
        }
    }
    
    public func isSolvable() -> Bool
    {
        switch self {
        case .easy, .normal, .hard, .insane:    return true
        default:                                return false
        }
    }
}

// MARK: - Cell Implementation
public class Cell: NSObject, NSCoding
{
    public var number: Int?
    internal (set) public var solution: Int?
    public var pencilMarks = Set<Int>()
    internal (set) public var neighbours = [SudokuBoardIndex]()
    internal (set) public var isGiven = false
    
    public override init() { }
    
    public required init?(coder aDecoder: NSCoder)
    {
        number = aDecoder.decodeObject(forKey: "number") as! Int?
        solution = aDecoder.decodeObject(forKey: "solution") as! Int?
        pencilMarks = aDecoder.decodeObject(forKey: "pencilMarks") as! Set<Int>
        let rows = aDecoder.decodeObject(forKey: "rows") as! [Int]
        let columns = aDecoder.decodeObject(forKey: "columns") as! [Int]
        neighbours = zip(rows, columns).map( { SudokuBoardIndex(row: $0.0, column: $0.1) } )
        isGiven = aDecoder.decodeBool(forKey: "isGiven")
    }
    
    public func encode(with aCoder: NSCoder)
    {
        aCoder.encode(number, forKey: "number")
        aCoder.encode(solution, forKey: "solution")
        aCoder.encode(pencilMarks, forKey: "pencilMarks")
        aCoder.encode(neighbours.map( { $0.row } ), forKey: "rows")
        aCoder.encode(neighbours.map( { $0.column } ), forKey: "columns")
        aCoder.encode(isGiven, forKey: "isGiven")
    }
}

// MARK: - SudokuBoard Implementation
public class SudokuBoard: NSObject, SudokuBoardProtocol
{
    public let order: Int
    public let dimensionality: Int
    fileprivate let board: [Cell]
    private (set) public var difficulty = PuzzleDifficulty.blank
    private (set) public var difficultyScore = 0
 
    public var isSolved: Bool {
        return difficulty.isSolvable() && !board.contains(where: { $0.number != $0.solution } )
    }
    
    public var solutionDescription: String {
        return description {
            let number = board[$0].solution
            switch number ?? 0 {
            case 1 ... 9:   return "\(number!)"
            case 10 ... 36: return "\(UnicodeScalar(55 + number!)!)"
            default:        return nil
            }
        }
    }
    
    // MARK: - Class Functions
    public class func generatePuzzle(ofOrder order: Int, difficulty: PuzzleDifficulty) -> SudokuBoard?
    {
        if [.multipleSolutions, .noSolution].contains(difficulty) { return nil }
        let cOrder = CUnsignedInt(order)
        let cDifficulty = difficulty.toMCPuzzleDifficulty()
        if let puzzle = generatePuzzleWithOrder(cOrder, cDifficulty) {
            defer { destroyContext(puzzle) }
            return SudokuBoard(withPuzzle: puzzle.pointee)
        }
        return nil
    }
    
    // MARK: - Public Functions
    public func solve() -> Bool
    {
        var context = generatePuzzleWithOrder(CUnsignedInt(order), MCPuzzleDifficultyZero)!
        defer { destroyContext(context) }
        for (i, cell) in board.enumerated() { context.pointee.problem[i] = CUnsignedInt(cell.number ?? 0) }
        if solveContext(context) == 0 {
            for (i, cell) in board.enumerated() {
                context.pointee.problem[i] = cell.isGiven ? CUnsignedInt(cell.number ?? 0) : 0
            }
            if solveContext(context) == 0 {
                difficulty = context.pointee.solutionCount > 0 ? .multipleSolutions : .noSolution
                return false
            }
        }
        for (i, cell) in board.enumerated() { cell.solution = Int(context.pointee.solution[i]) }
        difficulty = PuzzleDifficulty(difficulty: context.pointee.difficulty)
        difficultyScore = Int(context.pointee.difficultyScore)
        return true
    }
    
    public func markupBoard()
    {
        let allPencilMarks = Set(1 ... dimensionality)
        
        board.forEach { if $0.number == nil { $0.pencilMarks = allPencilMarks } }
        board.forEach { cell in
            if let number = cell.number {
                cell.neighbours.forEach { self.cellAt($0)?.pencilMarks.remove(number) }
            }
        }
    }
    
    public func unmarkBoard()
    {
        board.forEach { $0.pencilMarks.removeAll() }
    }
    
    public func setPuzzle() -> PuzzleDifficulty
    {
        guard difficulty == .blank else { return difficulty }
        board.forEach { $0.isGiven = $0.number != nil }
        if !solve() {
            let reason = difficulty
            board.forEach { $0.isGiven = false }
            difficulty = .blank
            return reason
        }
        return difficulty
    }
    
    public func cellAt(_ index: SudokuBoardIndex) -> Cell?
    {
        guard index.row < dimensionality && index.column < dimensionality else { return nil }
        return board[index.row * dimensionality + index.column]
    }
    
    // MARK: - Lifecycle
    fileprivate convenience init?(withPuzzle puzzle : MCSudokuSolveContext)
    {
        self.init(withOrder: Int(puzzle.order))
        difficulty = PuzzleDifficulty(difficulty: puzzle.difficulty)
        difficultyScore = Int(puzzle.difficultyScore)
        for (i, cell) in board.enumerated() {
            let number = Int(puzzle.problem[i])
            let solution = Int(puzzle.solution[i])
            cell.number = number == 0 ? nil : number
            cell.solution = solution == 0 ? nil : solution
            cell.isGiven = number != 0
        }
    }
    
    private init?(withOrder order : Int)
    {
        guard order > 1 else {
            self.order = 0
            self.dimensionality = 0
            self.board = []
            return nil
        }
        var context = generatePuzzleWithOrder(CUnsignedInt(order), MCPuzzleDifficultyZero)!
        defer { destroyContext(context) }
        self.order = order
        self.dimensionality = order * order
        difficulty = PuzzleDifficulty(difficulty: context.pointee.difficulty)
        difficultyScore = Int(context.pointee.difficultyScore)
        var board = [Cell]()
        for _ in 0 ..< context.pointee.cellCount { board.append(Cell()) }
        for (i, cell) in board.enumerated() {
            for j in 0 ..< Int(context.pointee.neighbourCount) {
                let index = Int(context.pointee.neighbourMap[i]![j])
                let row = index / dimensionality
                let column = index % dimensionality
                cell.neighbours.append(SudokuBoardIndex(row: row, column: column))
            }
        }
        self.board = board
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        order = aDecoder.decodeInteger(forKey: "order")
        dimensionality = aDecoder.decodeInteger(forKey: "dimensionality")
        board = aDecoder.decodeObject(forKey: "board") as! [Cell]
        difficulty = PuzzleDifficulty(rawValue: aDecoder.decodeInteger(forKey: "difficulty"))!
        difficultyScore = aDecoder.decodeInteger(forKey: "difficultyScore")
    }
    
    public func encode(with aCoder: NSCoder)
    {
        aCoder.encode(order, forKey: "order")
        aCoder.encode(dimensionality, forKey: "dimensionality")
        aCoder.encode(board, forKey: "board")
        aCoder.encode(difficulty.rawValue, forKey: "difficulty")
        aCoder.encode(difficultyScore, forKey: "difficultyScore")
    }
    
    deinit
    {
        board.forEach { $0.neighbours.removeAll() }
    }
}

// MARK: - SudokuBoard Private Functions
fileprivate extension SudokuBoard
{
    func description(using function: (Int) -> String?) -> String
    {
        var lineBreak = ""
        for i in 0 ..< dimensionality {
            if i % order == 0{
                lineBreak += "+"
            }
            lineBreak += "-"
        }
        lineBreak += "+\n"
        var description = ""
        for i in 0 ..< board.count {
            let row = i / dimensionality, column = i % dimensionality
            if column == 0 {
                if row % order == 0 {
                    description += lineBreak
                }
                description += "|"
            }
            if let number = function(i) { description += number }
            else { description += "." }
            if (column + 1) % order == 0 {
                description += "|";
                if (column + 1) == dimensionality {
                    description += "\n"
                }
            }
        }
        description += lineBreak + "\n"
        return description
    }
}

// MARK: - CustomStringConvertible Implementation
extension SudokuBoard
{
    public override var description: String {
        get {
            return description {
                let number = board[$0].number
                switch number ?? 0 {
                case 1 ... 9:   return "\(number!)"
                case 10 ... 36: return "\(UnicodeScalar(55 + number!)!)"
                default:        return nil
                }
            }
        }
    }
}
