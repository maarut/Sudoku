//
//  MCSudokuEngineBridge.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 03/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation
import SudokuEngineC

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
    
    fileprivate init(difficulty: MCPuzzleDifficulty) {
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
public class Cell: NSCoding
{
    public var number: Int?
    internal (set) public var solution: Int?
    public var pencilMarks = Set<Int>()
    internal (set) public var neighbours = [Cell]()
    internal (set) public var isGiven = false
    
    public init() { }
    
    public required init?(coder aDecoder: NSCoder)
    {
        number = aDecoder.decodeObject(forKey: "number") as! Int?
        solution = aDecoder.decodeObject(forKey: "solution") as! Int?
        pencilMarks = aDecoder.decodeObject(forKey: "pencilMarks") as! Set<Int>
        neighbours = aDecoder.decodeObject(forKey: "neighbours") as! [Cell]
        isGiven = aDecoder.decodeBool(forKey: "isGiven")
    }
    
    public func encode(with aCoder: NSCoder)
    {
        aCoder.encode(number, forKey: "number")
        aCoder.encode(solution, forKey: "solution")
        aCoder.encode(pencilMarks, forKey: "pencilMarks")
        aCoder.encode(neighbours, forKey: "neighbours")
        aCoder.encode(isGiven, forKey: "isGiven")
    }
}

// MARK: - SudokuBoard Implementation
public class SudokuBoard: NSCoding
{
    public let order: Int
    public let dimensionality: Int
    private (set) public var board = [Cell]()
    private (set) public var difficulty = PuzzleDifficulty.blank
    private (set) public var difficultyScore = 0
 
    public var isSolved: Bool {
        get {
            return difficulty.isSolvable() && !board.contains(where: { $0.number != $0.solution } )
        }
    }
    
    public var solutionDescription: String {
        get {
            return description {
                let number = board[$0].solution
                switch number ?? 0 {
                case 1 ... 9:   return "\(number!)"
                case 10 ... 36: return "\(UnicodeScalar(55 + number!)!)"
                default:        return nil
                }
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
                cell.neighbours.forEach { $0.pencilMarks.remove(number) }
            }
        }
    }
    
    public func unmarkBoard()
    {
        board.forEach { $0.pencilMarks.removeAll() }
    }
    
    public func setPuzzle()
    {
        guard difficulty == .blank else { return }
        board.forEach { $0.isGiven = $0.number != nil }
        let _ = solve()
    }
    
    // MARK: - Lifecycle
    fileprivate convenience init?(withPuzzle puzzle : MCSudokuSolveContext)
    {
        self.init(withOrder: Int(puzzle.order), dimensionality: Int(puzzle.dimensionality))
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
    
    private init?(withOrder order : Int, dimensionality : Int)
    {
        guard order >= 3 else {
            self.order = 0
            self.dimensionality = 0
            return nil
        }
        var context = generatePuzzleWithOrder(CUnsignedInt(order), MCPuzzleDifficultyZero)!
        defer { destroyContext(context) }
        self.order = order
        self.dimensionality = dimensionality
        difficulty = PuzzleDifficulty(difficulty: context.pointee.difficulty)
        difficultyScore = Int(context.pointee.difficultyScore)
        for _ in 0 ..< context.pointee.cellCount { board.append(Cell()) }
        for (i, cell) in board.enumerated() {
            for j in 0 ..< Int(context.pointee.neighbourCount) {
                cell.neighbours.append(board[Int(context.pointee.neighbourMap[i]![j])])
            }
        }
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

// MARK: - CustomStringConvertible
extension SudokuBoard: CustomStringConvertible
{
    public var description: String {
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
