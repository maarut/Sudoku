//
//  MCSudokuEngine.h
//  Sudoku++
//
//  Created by Maarut Chandegra on 03/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

#ifndef MCSudokuEngine_h
#define MCSudokuEngine_h

#include <pthread.h>

typedef enum {
    MCPuzzleDifficultyZero = 0,
    MCPuzzleDifficultyEasy = 20,
    MCPuzzleDifficultyNormal = 30,
    MCPuzzleDifficultyHard = 50,
    MCPuzzleDifficultyInsane/*InTheMembrane*/ = 85
} MCPuzzleDifficulty;

typedef struct _MCSudokuSolveContext {
    // These values should be readonly once the context has been set up.
    uint cellCount;
    uint maxNumberForPencils;
    uint order;
    uint dimensionality;
    uint neighbourCount;
    
    uint **boxMap;          // boxMap[dimensionality][dimensionality]
    uint **columnMap;       // columnMap[dimensionality][dimensionality]
    uint **rowMap;          // rowMap[dimensionality][dimensionality]
    uint **neighbourMap;    // neighbourMap[cellCount][neighbourCount]
    
    // Variables
    uint solutionCount;
    uint difficultyScore;
    MCPuzzleDifficulty difficulty;
    
    uint *problem;          // problem[cellCount]
    uint *solution;         // solution[cellCount]
    uint *board;            // board[cellCount]
    char **pencilMarks;     // pencilMarks[cellCount][maxNumberOfPencils] boolean values only.
    
    void *opaque;           // Private use
    
} MCSudokuSolveContext;

MCSudokuSolveContext *generatePuzzleWithOrder(uint order, MCPuzzleDifficulty expectedDifficulty);
int solveContext(MCSudokuSolveContext *context);

void destroyContext(MCSudokuSolveContext *context);

#endif /* MCSudokuEngine_h */
