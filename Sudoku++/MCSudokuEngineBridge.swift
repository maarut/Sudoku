//
//  MCSudokuEngineBridge.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 03/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

// MARK: - PuzzleDifficulty Enum
enum PuzzleDifficulty: Int
{
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
    
    func isSolvable() -> Bool
    {
        switch self {
        case .easy, .normal, .hard, .insane:    return true
        default:                                return false
        }
    }
    
    case blank
    case noSolution
    case multipleSolutions
    case easy
    case normal
    case hard
    case insane
}

// MARK: - Cell Implementation
class Cell: NSCoding
{
    var number: Int?
    var solution: Int?
    var pencilMarks = Set<Int>()
    var neighbours = [Cell]()
    var isGiven = false
    
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
class SudokuBoard: NSCoding
{
    let order: Int
    let dimensionality: Int
    var board = [Cell]()
    var difficulty = PuzzleDifficulty.blank
    var difficultyScore = 0
 
    var isSolved: Bool {
        get {
            if hasSolution {
                for cell in board {
                    if cell.number != cell.solution { return false }
                }
                return true
            }
            return false
        }
    }
    
    var hasSolution: Bool { get { return difficulty.isSolvable() } }
    
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
    static func generatePuzzle(ofOrder order: Int, difficulty: PuzzleDifficulty) -> SudokuBoard?
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
    func solve() -> Bool
    {
        var context = generatePuzzleWithOrder(CUnsignedInt(order), MCPuzzleDifficultyZero)!
        defer { destroyContext(context) }
        for i in 0 ..< board.count {
            context.pointee.problem[i] = CUnsignedInt(board[i].number ?? 0)
        }
        if solveContext(context) == 0 {
            for i in 0 ..< board.count {
                context.pointee.problem[i] = board[i].isGiven ? CUnsignedInt(board[i].number ?? 0) : 0
            }
            if solveContext(context) == 0 {
                difficulty = context.pointee.solutionCount > 0 ? .multipleSolutions : .noSolution
                return false
            }
        }
        for i in 0 ..< board.count {
            board[i].solution = Int(context.pointee.solution[i])
        }
        difficulty = PuzzleDifficulty(difficulty: context.pointee.difficulty)
        difficultyScore = Int(context.pointee.difficultyScore)
        return true
    }
    
    func markupBoard()
    {
        let allPencilMarks = Set(1 ... dimensionality)
        
        board.forEach { cell in
            if cell.number == nil {
                cell.pencilMarks = allPencilMarks
            }
        }
        board.forEach { cell in
            if let number = cell.number {
                cell.neighbours.forEach { $0.pencilMarks.remove(number) }
            }
        }
    }
    
    func unmarkBoard()
    {
        board.forEach { $0.pencilMarks.removeAll() }
    }
    
    // MARK: - Lifecycle
    fileprivate convenience init?(withPuzzle puzzle : MCSudokuSolveContext)
    {
        self.init(withOrder: Int(puzzle.order), dimensionality: Int(puzzle.dimensionality))
        difficulty = PuzzleDifficulty(difficulty: puzzle.difficulty)
        difficultyScore = Int(puzzle.difficultyScore)
        for i in 0 ..< board.count {
            let number = Int(puzzle.problem[i])
            let solution = Int(puzzle.solution[i])
            board[i].number = number == 0 ? nil : number
            board[i].solution = solution == 0 ? nil : solution
            board[i].isGiven = number != 0
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
        for i in 0 ..< board.count {
            for j in 0 ..< Int(context.pointee.neighbourCount) {
                board[i].neighbours.append(board[Int(context.pointee.neighbourMap[i]![j])])
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
