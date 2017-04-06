//
//  MCSudokuEngine.c
//  Sudoku++
//
//  Created by Maarut Chandegra on 03/02/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

#include "MCSudokuEngine.h"
#include <stdlib.h>
#include <dispatch/dispatch.h>
#include <string.h>
#include <limits.h>

#pragma mark Typedefs

// This shouldn't really be a type, but it sits in MCSudokuSolveContext.opaque.
typedef struct _MCSudokuSolveContextStopSolve {
    char stopSolve;
    dispatch_semaphore_t lock;
} MCSudokuSolveContextStopSolve;

typedef struct _MCPencilMarkSet {
    uint pencilMark;
    uint countIndexes;
    uint *indexes;
} MCPencilMarkSet;

#pragma mark Debug Logging

#ifdef DEBUG

#include <stdio.h>

typedef enum _MCSudokuSolveContextAspect {
    MCSudokuSolveContextAspectBoard,
    MCSudokuSolveContextAspectSolution,
    MCSudokuSolveContextAspectProblem
} MCSudokuSolveContextAspect;

char *createLineBreak(MCSudokuSolveContext *context)
{
    int sizeOfLineBreak = context->dimensionality + context->order + 2;
    char *lineBreak = malloc(sizeof(char) * sizeOfLineBreak);
    for (int i = 0; i < (sizeOfLineBreak - 1); i++) {
        if (i % (context->order + 1) == 0) { lineBreak[i] = '+'; }
        else { lineBreak[i] = '-'; }
    }
    lineBreak[sizeOfLineBreak - 1] = '\n';
    return lineBreak;
}

void MCLogContext(MCSudokuSolveContext *context, MCSudokuSolveContextAspect aspect)
{
    if (context->dimensionality == 0) { return; }
    
    char *linebreak = createLineBreak(context);
    for (uint i = 0; i < context->cellCount; i++) {
        uint row = i / context->dimensionality, column = i % context->dimensionality;
        uint number = 0;
        switch (aspect) {
            case MCSudokuSolveContextAspectBoard:
                number = context->board[i];
                break;
            case MCSudokuSolveContextAspectSolution:
                number = context->solution[i];
                break;
            case MCSudokuSolveContextAspectProblem:
                number = context->problem[i];
                break;
        }
        if (column == 0) {
            if (row % context->order == 0) {
                printf("%s", linebreak);
            }
            printf("|");
        }
        if (number == 0) { printf("."); }
        else { printf("%u", number); }
        if (++column % context->order == 0) {
            printf("|");
            if (column == context->dimensionality) {
                printf("\n");
            }
        }
    }
    printf("%s\n", linebreak);
}

#endif // DEBUG

#pragma mark Single Reduction

static int reduceSingle(MCSudokuSolveContext *context)
{
    for (uint i = 0; i < context->cellCount; i++) {
        uint pencilMarkCount = 0;
        uint number = 0;
        if (context->board[i] > 0) { continue; }
        for (uint j = 0; j < context->maxNumberForPencils; j++) {
            if (context->pencilMarks[i][j]) {
                pencilMarkCount++;
                number = j + 1;
                if (pencilMarkCount > 1) {
                    break;
                }
            }
        }
        if (pencilMarkCount == 1) {
            context->board[i] = number;
            for (uint j = 0; j < context->neighbourCount; j++) {
                context->pencilMarks[context->neighbourMap[i][j]][number - 1] = 0;
            }
            return 1;
        }
    }
    return 0;
}

static void mapPencilMarkToCells(MCSudokuSolveContext *context, uint *region, MCPencilMarkSet *map)
{
    for (uint i = 0; i < context->maxNumberForPencils; i++) {
        memset(map[i].indexes, 0, sizeof(uint) * map[i].countIndexes);
        map[i].countIndexes = 0;
    }
    
    for (uint i = 0; i < context->dimensionality; i++) {
        for (uint j = 0; j < context->maxNumberForPencils; j++) {
            uint num = context->board[region[i]];
            if (num == 0 && context->pencilMarks[region[i]][j]) {
                map[j].indexes[map[j].countIndexes++] = region[i];
            }
        }
    }
}

static int reduceHiddenSingleForRegion(MCSudokuSolveContext *context, uint *region, MCPencilMarkSet *map)
{
    int didChange = 0;
    
    mapPencilMarkToCells(context, region, map);
    
    for (uint i = 0; i < context->maxNumberForPencils; i++) {
        if (map[i].countIndexes == 1) {
            uint index = map[i].indexes[0];
            context->board[index] = map[i].pencilMark;
            didChange = 1;
            for (uint j = 0; j < context->neighbourCount; j++) {
                context->pencilMarks[context->neighbourMap[index][j]][i] = 0;
            }
            break;
        }
    }
    
    return didChange;
}

static int reduceHiddenSingle(MCSudokuSolveContext *context)
{
    int didChange = 0;
    MCPencilMarkSet *pencilMarkSet = malloc(sizeof(MCPencilMarkSet) * context->maxNumberForPencils);
    for (uint i = 0; i < context->maxNumberForPencils; i++) {
        pencilMarkSet[i].pencilMark = i + 1;
        pencilMarkSet[i].countIndexes = 0;
        pencilMarkSet[i].indexes = malloc(sizeof(uint) * context->maxNumberForPencils);
    }
    
    for (uint i = 0; i < context->dimensionality; i++) {
        // boxes
        if (reduceHiddenSingleForRegion(context, context->boxMap[i], pencilMarkSet)) {
            didChange = 1;
            break;
        }
        // rows
        if (reduceHiddenSingleForRegion(context, context->rowMap[i], pencilMarkSet)) {
            didChange = 1;
            break;
        }
        // columns
        if (reduceHiddenSingleForRegion(context, context->columnMap[i], pencilMarkSet)) {
            didChange = 1;
            break;
        }
    }
    
    for (uint i = 0; i < context->maxNumberForPencils; i++) { free(pencilMarkSet[i].indexes); }
    free(pencilMarkSet);
    
    return didChange;
}

#pragma mark Pencil Mark Reduction

static MCPencilMarkSet *createPencilMarkMap(MCSudokuSolveContext *context)
{
    MCPencilMarkSet *pencilMarkSet = malloc(sizeof(MCPencilMarkSet) * context->maxNumberForPencils);
    for (int i = 0; i < context->maxNumberForPencils; i++) {
        pencilMarkSet[i].pencilMark = i + 1;
        pencilMarkSet[i].countIndexes = 0;
        pencilMarkSet[i].indexes = malloc(sizeof(uint) * context->maxNumberForPencils);
    }
    return pencilMarkSet;
}

static void destroyPencilMarkMap(MCSudokuSolveContext *context, MCPencilMarkSet *pencilMarkMap)
{
    for (int i = 0; i < context->maxNumberForPencils; i++) {
        free(pencilMarkMap[i].indexes);
    }
    free(pencilMarkMap);
}

static uint countPencilMarks(char *pencilMarkSet, uint maxNumberForPencils)
{
    uint count = 0;
    for (uint i = 0; i < maxNumberForPencils; i++) {
        if (pencilMarkSet[i]) { count++; }
    }
    return count;
}

static uint mapPencilMarksToCells(MCSudokuSolveContext *context, uint *region, uint *indexes)
{
    uint count = 0;
    for (uint i = 0; i < context->dimensionality - 1; i++) {
        if (context->board[region[i]] != 0) { continue; }
        char *pencilMarkSet;
        memset(indexes, 0, sizeof(uint) * context->dimensionality);
        count = 0;
        pencilMarkSet = context->pencilMarks[region[i]];
        indexes[count++] = region[i];
        for (uint j = i + 1; j < context->dimensionality; j++) {
            uint idx = region[j];
            if (context->board[idx] == 0 &&
                !memcmp(pencilMarkSet, context->pencilMarks[idx], sizeof(char) * context->maxNumberForPencils)) {
                indexes[count++] = idx;
            }
        }
        if (count == countPencilMarks(pencilMarkSet, context->maxNumberForPencils)) { break; }
    }
    return count;
}

static int reducePencilMarksForRegion(MCSudokuSolveContext *context, uint *region, uint *indexes)
{
    int didChange = 0;
    uint count = mapPencilMarksToCells(context, region, indexes);
    char *pencilMarkSet = context->pencilMarks[indexes[0]];
    if (count == countPencilMarks(pencilMarkSet, context->maxNumberForPencils)) {
        for (int j = 0; j < context->dimensionality; j++) {
            if (context->board[region[j]] == 0 &&
                memcmp(pencilMarkSet, context->pencilMarks[region[j]], sizeof(char) * context->maxNumberForPencils)) {
                for (int k = 0; k < context->maxNumberForPencils; k++) {
                    if (pencilMarkSet[k] && context->pencilMarks[region[j]][k]) {
                        context->pencilMarks[region[j]][k] = 0;
                        didChange = 1;
                    }
                }
            }
        }
    }
    return didChange;
}

static int reducePencilMarks(MCSudokuSolveContext *context)
{
    int didChange = 0;
    uint *indexes = calloc(context->dimensionality, sizeof(uint));
    for (uint i = 0; i < context->dimensionality; i++) {
        if (reducePencilMarksForRegion(context, context->boxMap[i], indexes)) {
            didChange = 1;
            break;
        }
        if (reducePencilMarksForRegion(context, context->columnMap[i], indexes)) {
            didChange = 1;
            break;
        }
        if (reducePencilMarksForRegion(context, context->rowMap[i], indexes)) {
            didChange = 1;
            break;
        }
    }
    free(indexes);
    return didChange;
}

static int reduceHiddenPencilMarksForRegion(MCSudokuSolveContext *context, uint *region,
    MCPencilMarkSet *pencilMarkSet, uint *cellSet)
{
    int didChange = 0;
    memset(cellSet, 0, sizeof(uint) * context->dimensionality);
    mapPencilMarkToCells(context, region, pencilMarkSet);
    
    uint currentCellSet = UINT_MAX;
    uint count = 0;
    
    // Invert the pencil mark to cells map
    for (uint i = 0; i < context->maxNumberForPencils - 1; i++) {
        currentCellSet = i;
        cellSet[count++] = i;
        for (uint j = i + 1; j < context->maxNumberForPencils; j++) {
            if (!memcmp(pencilMarkSet[i].indexes, pencilMarkSet[j].indexes, sizeof(uint) * context->dimensionality)) {
                cellSet[count++] = j;
            }
        }
        if (count > 1 && pencilMarkSet[currentCellSet].countIndexes == count) { break; }
        memset(cellSet, 0, sizeof(uint) * count);
        count = 0;
    }
    
    if (count > 0) {
        uint *indexesToModify = calloc(sizeof(uint), context->dimensionality);
        memcpy(indexesToModify, region, sizeof(uint) * context->dimensionality);
        for (uint i = 0; i < context->dimensionality; i++) {
            if (context->board[indexesToModify[i]] != 0) {
                indexesToModify[i] = -1;
            }
            else {
                for (uint j = 0; j < count; j++) {
                    if (indexesToModify[i] == pencilMarkSet[currentCellSet].indexes[j]) {
                        indexesToModify[i] = -1;
                        break;
                    }
                }
            }
        }
        
        for (uint i = 0; i < context->dimensionality; i++) {
            if (indexesToModify[i] != -1) {
                for (uint j = 0; j < count; j++) {
                    if (context->pencilMarks[indexesToModify[i]][cellSet[j]]) {
                        context->pencilMarks[indexesToModify[i]][cellSet[j]] = 0;
                        didChange = 1;
                    }
                }
            }
        }
        free(indexesToModify);
    }
    return didChange;
}

static int reduceHiddenPencilMarks(MCSudokuSolveContext *context)
{
    int didChange = 0;
    MCPencilMarkSet *pencilMarkSet = createPencilMarkMap(context);
    uint *cellSetToPencilMarks = malloc(sizeof(uint) * context->dimensionality);
    
    for (uint i = 0; i < context->dimensionality; i++) {
        if (reduceHiddenPencilMarksForRegion(context, context->boxMap[i], pencilMarkSet, cellSetToPencilMarks)) {
            didChange = 1;
            break;
        }
        if (reduceHiddenPencilMarksForRegion(context, context->rowMap[i], pencilMarkSet, cellSetToPencilMarks)) {
            didChange = 1;
            break;
        }
        if (reduceHiddenPencilMarksForRegion(context, context->columnMap[i], pencilMarkSet, cellSetToPencilMarks)) {
            didChange = 1;
            break;
        }
    }
    destroyPencilMarkMap(context, pencilMarkSet);
    free(cellSetToPencilMarks);
    return didChange;
}

static inline int markupBoxCrossSection(MCSudokuSolveContext *context, uint box, uint pencilMark, uint *idxsToModify)
{
    for (int j = 0; j < context->dimensionality; j++) {
        uint index = idxsToModify[j];
        uint r = index / context->dimensionality;
        uint c = index % context->dimensionality;
        uint b = (r / context->order) * context->order + (c / context->order);
        if (b == box || !context->pencilMarks[index][pencilMark]) { continue; }
        context->pencilMarks[index][pencilMark] = 0;
        return 1;
    }
    return 0;
}

static int reducePencilMarksBoxCrossSectionForBox(MCSudokuSolveContext *context, uint box,
    MCPencilMarkSet *pencilMarkSet)
{
    int didChange = 0;
    uint *boxIdxs = context->boxMap[box];
    mapPencilMarkToCells(context, boxIdxs, pencilMarkSet);
    
    char *rows = calloc(sizeof(char), context->order), *cols = calloc(sizeof(char), context->order);
    
    for (uint i = 0; i < context->maxNumberForPencils; i++) {
        // Does this pencilMark exist entirely in a row or col?
        for (int j = 0; j < pencilMarkSet[i].countIndexes; j++) {
            uint index = pencilMarkSet[i].indexes[j];
            uint rowInBox = (index / context->dimensionality) % context->order;
            uint colInBox = index % context->order;
            rows[rowInBox] = 1;
            cols[colInBox] = 1;
        }
        uint countOfPencilMarkPerRow = 0, countOfPencilMarkPerCol = 0;
        for (int j = 0; j < context->order; j++) {
            countOfPencilMarkPerRow += rows[j] ? 1 : 0;
            countOfPencilMarkPerCol += cols[j] ? 1 : 0;
        }
        if (countOfPencilMarkPerRow == 1) {
            uint rowToModify = pencilMarkSet[i].indexes[0] / context->dimensionality;
            didChange = markupBoxCrossSection(context, box, i, context->rowMap[rowToModify]);
            break;
        }
        else if (countOfPencilMarkPerCol == 1) {
            uint colToModify = pencilMarkSet[i].indexes[0] % context->dimensionality;
            didChange = markupBoxCrossSection(context, box, i, context->columnMap[colToModify]);
            break;
        }
        else {
            memset(rows, 0, sizeof(char) * context->order);
            memset(cols, 0, sizeof(char) * context->order);
        }
    }
    free(rows);
    free(cols);
    
    return didChange;
}

static int reducePencilMarksBoxCrossSection(MCSudokuSolveContext *context)
{
    int didChange = 0;
    MCPencilMarkSet *pencilMarkMap = createPencilMarkMap(context);
    for (int i = 0; i < context->dimensionality; i++) {
        if (reducePencilMarksBoxCrossSectionForBox(context, i, pencilMarkMap)) {
            didChange = 1;
            break;
        }
    }
    destroyPencilMarkMap(context, pencilMarkMap);
    return didChange;
}

#pragma mark Solving Helper Functions

static int isPuzzleValid(MCSudokuSolveContext *context)
{
    int isValid = 1;
    for (int i = 0; i < context->cellCount; i++) {
        for (int j = 0; j < context->neighbourCount; j++) {
            if (context->problem[i] != 0 && context->problem[i] == context->problem[context->neighbourMap[i][j]]) {
                return 0;
            }
        }
    }
    return isValid;
}

static void markup(MCSudokuSolveContext *context)
{
    for (uint i = 0; i < context->cellCount; i++) {
        memset(context->pencilMarks[i], 1, sizeof(char) * context->maxNumberForPencils);
    }
    for (uint i = 0; i < context->cellCount; i++) {
        if (context->board[i] > 0) {
            memset(context->pencilMarks[i], 0, sizeof(char) * context->maxNumberForPencils);
            for (uint j = 0; j < context->neighbourCount; j++) {
                uint neighbourIndex = context->neighbourMap[i][j];
                if (context->board[neighbourIndex] == 0) {
                    context->pencilMarks[neighbourIndex][context->board[i] - 1] = 0;
                }
            }
        }
    }
}

static uint cellWithFewestPencilMarks(MCSudokuSolveContext *context, uint *pencilMarkCount)
{
    uint leastMarks = UINT_MAX, index = UINT_MAX, count = 0;
    uint *indexes = calloc(sizeof(uint), context->cellCount);
    for (int i = 0; i < context->cellCount; i++) {
        if (context->board[i] > 0) { continue; }
        uint markCount = 0;
        for (int j = 0; j < context->maxNumberForPencils; j++) {
            if (context->pencilMarks[i][j]) {
                markCount++;
            }
        }
        if (markCount != 0 && markCount <= leastMarks) {
            if (markCount < leastMarks) {
                leastMarks = markCount;
                memset(indexes, 0, sizeof(uint) * count);
                count = 0;
            }
            indexes[count++] = i;
        }
    }
    index = indexes[arc4random() % count];
    free(indexes);
    *pencilMarkCount = leastMarks;
    return index;
}

static int valid(MCSudokuSolveContext *context)
{
    int isValid = 1;
    char *seenNumbers = malloc(sizeof(char) * context->dimensionality);
    for (uint i = 0; i < context->dimensionality; i++) {
        uint *boxIdxs = context->boxMap[i];
        uint count = 0;
        memset(seenNumbers, 0, sizeof(char) * context->dimensionality);
        for (uint j = 0; j < context->dimensionality; j++) {
            seenNumbers[context->board[boxIdxs[j]] - 1] = 1;
        }
        for (uint j = 0; j < context->dimensionality; j++) {
            if (seenNumbers[j]) { count++; }
        }
        if (count != context->dimensionality) {
            isValid = 0;
            break;
        }
    }
    free(seenNumbers);
    return isValid;
}

static int isSolved(MCSudokuSolveContext *context)
{
    for (uint i = 0; i < context->cellCount; i++) {
        if (context->board[i] == 0) { return 0; }
    }
    return 1;
}

static int pencilMarksValid(MCSudokuSolveContext *context)
{
    for (uint i = 0; i < context->cellCount; i++) {
        if (context->board[i] > 0) { continue; }
        uint count = 0;
        for (uint j = 0; j < context->maxNumberForPencils; j++) {
            if (context->pencilMarks[i][j]) {
                count++;
                break;
            }
        }
        if (count == 0) { return 0; }
    }
    return 1;
}

static void prepareForTrial(MCSudokuSolveContext *dest, MCSudokuSolveContext *src)
{
    *dest = *src;
    size_t boardSize = sizeof(uint) * src->cellCount,
    pencilMarkSize = sizeof(char) * src->maxNumberForPencils;
    dest->board = malloc(boardSize);
    memcpy(dest->board, src->board, boardSize);
    dest->pencilMarks = malloc(sizeof(char *) * src->cellCount);
    dest->pencilMarks[0] = malloc(pencilMarkSize * src->cellCount);
    dest->solution = malloc(boardSize);
    memcpy(dest->pencilMarks[0], src->pencilMarks[0], pencilMarkSize * src->cellCount);
    for (uint j = 1; j < src->cellCount; j++) {
        dest->pencilMarks[j] = &dest->pencilMarks[0][j * pencilMarkSize];
    }
    MCSudokuSolveContextStopSolve *stopSolve = malloc(sizeof(MCSudokuSolveContextStopSolve));
    stopSolve->lock = dispatch_semaphore_create(1);
    stopSolve->stopSolve = 0;
    dest->opaque = stopSolve;
}

static void destroyTrial(MCSudokuSolveContext *trial)
{
    free(trial->board);
    free(trial->solution);
    free(trial->pencilMarks[0]);
    free(trial->pencilMarks);
    dispatch_release(((MCSudokuSolveContextStopSolve *)trial->opaque)->lock);
    free(trial->opaque);
}

static void stopGuessing(MCSudokuSolveContext trials[], uint trialCount)
{
    for (int i = 0; i < trialCount; i++) {
        MCSudokuSolveContextStopSolve *stopSolve = trials[i].opaque;
        dispatch_semaphore_wait(stopSolve->lock, DISPATCH_TIME_FOREVER);
        stopSolve->stopSolve = 1;
        dispatch_semaphore_signal(stopSolve->lock);
    }
}

static void solveContextRecursive(MCSudokuSolveContext *context);
static void makeGuess(MCSudokuSolveContext *context)
{
    uint trialCount = 0;
    uint guessSquare = cellWithFewestPencilMarks(context, &trialCount);

    MCSudokuSolveContext *trials = malloc(sizeof(MCSudokuSolveContext) * trialCount);
    for (uint i = 0, j = 0; i < context->maxNumberForPencils; i++) {
        if (!context->pencilMarks[guessSquare][i]) { continue; }
        prepareForTrial(&trials[j], context);
        trials[j].board[guessSquare] = i + 1;
        for (uint k = 0; k < context->neighbourCount; k++) {
            trials[j].pencilMarks[context->neighbourMap[guessSquare][k]][i] = 0;
        }
        j++;
    }
    dispatch_semaphore_t solutionsLock = dispatch_semaphore_create(1);
    __block int solutions = 0;
    dispatch_apply(trialCount, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^(size_t i) {
        MCSudokuSolveContext *trial = &trials[i];
        solveContextRecursive(trial);
        if (trial->solutionCount == 0) { return; }
        dispatch_semaphore_wait(solutionsLock, DISPATCH_TIME_FOREVER);
        solutions += trial->solutionCount;
        memcpy(context->solution, trial->solution, sizeof(uint) * context->cellCount);
        if (solutions > 1) { stopGuessing(trials, trialCount); }
        else { context->difficultyScore = trial->difficultyScore + 100; }
        dispatch_semaphore_signal(solutionsLock);
        
    });
    context->solutionCount = solutions;
    dispatch_release(solutionsLock);
    for (uint i = 0; i < trialCount; i++) { destroyTrial(&trials[i]); }
    free(trials);
}

#pragma mark Main Solve Functions

static int shouldStopSolve(MCSudokuSolveContext *context)
{
    MCSudokuSolveContextStopSolve *stopSolve = context->opaque;
    dispatch_semaphore_wait(stopSolve->lock, DISPATCH_TIME_FOREVER);
    int shouldStop = stopSolve->stopSolve;
    dispatch_semaphore_signal(stopSolve->lock);
    return shouldStop;
}

static void solveContextRecursive(MCSudokuSolveContext *context)
{
    if (shouldStopSolve(context)) { return; }
    if (isSolved(context) && valid(context)) {
        if (context->solutionCount == 0) {
            memcpy(context->solution, context->board, sizeof(uint) * context->cellCount);
        }
        context->solutionCount++;
        return;
    }
    if (!pencilMarksValid(context)) { return; }
    
    if      (reduceSingle(context))                     { context->difficultyScore += 1;    }
    else if (reduceHiddenSingle(context))               { context->difficultyScore += 10;   }
    else if (reducePencilMarks(context))                { context->difficultyScore += 25;   }
    else if (reduceHiddenPencilMarks(context))          { context->difficultyScore += 50;   }
    else if (reducePencilMarksBoxCrossSection(context)) { context->difficultyScore += 50;   }
    else                                                { makeGuess(context); return;       }
    
    solveContextRecursive(context);
}

#pragma mark Generating Puzzles

static MCPuzzleDifficulty convertDifficultyScore(uint difficultyScore, uint order)
{   
    if      (difficultyScore < (MCPuzzleDifficultyEasy   * order))  { return MCPuzzleDifficultyZero;    }
    else if (difficultyScore < (MCPuzzleDifficultyNormal * order))  { return MCPuzzleDifficultyEasy;    }
    else if (difficultyScore < (MCPuzzleDifficultyHard   * order))  { return MCPuzzleDifficultyNormal;  }
    else if (difficultyScore < (MCPuzzleDifficultyInsane * order))  { return MCPuzzleDifficultyHard;    }
    
    return MCPuzzleDifficultyInsane;
}

static uint targetDifficultyScore(MCPuzzleDifficulty difficulty, uint order)
{
    switch (difficulty) {
        case MCPuzzleDifficultyEasy:
        {
            uint score = arc4random() % (order * (MCPuzzleDifficultyNormal - MCPuzzleDifficultyEasy));
            return MCPuzzleDifficultyEasy * order + score;
        }
        case MCPuzzleDifficultyNormal:
        {
            uint score = arc4random() % (order * (MCPuzzleDifficultyHard - MCPuzzleDifficultyNormal));
            return MCPuzzleDifficultyNormal * order + score;
        }
        case MCPuzzleDifficultyHard:
        {
            uint score = arc4random() % (order * (MCPuzzleDifficultyInsane - MCPuzzleDifficultyHard));
            return MCPuzzleDifficultyHard * order + score;
        }
        case MCPuzzleDifficultyInsane:
        {
            uint score = arc4random() % (order * MCPuzzleDifficultyInsane);
            return MCPuzzleDifficultyInsane * order + score;
        }
        case MCPuzzleDifficultyZero:
        default:
            return 0;
    }
}

static void removeNumbersFromBoard(MCSudokuSolveContext *context, MCPuzzleDifficulty expectedDifficulty)
{
    dispatch_semaphore_t lock = dispatch_semaphore_create(1);
    
    uint targetDifficulty = targetDifficultyScore(expectedDifficulty, context->order);
    
    uint *allIndexes = calloc(sizeof(uint), context->cellCount);
    for (uint i = 0; i < context->cellCount; i++) {
        allIndexes[i] = i;
    }
    
    size_t puzzleSize = sizeof(uint) * context->cellCount;
    
    uint *targetProblem = malloc(puzzleSize);
    __block uint hardestDifficulty = 0;
    
    void (^generationLoop)(size_t) = ^(size_t iter) {
        MCSudokuSolveContext *testContext = malloc(sizeof(MCSudokuSolveContext));
        memcpy(testContext, context, sizeof(MCSudokuSolveContext));
        
        MCSudokuSolveContextStopSolve *stopSolve = malloc(sizeof(MCSudokuSolveContextStopSolve));
        stopSolve->stopSolve = 0;
        stopSolve->lock = dispatch_semaphore_create(1);
        testContext->opaque = stopSolve;
        
        testContext->problem = malloc(puzzleSize);
        testContext->solution = malloc(puzzleSize);
        testContext->board = malloc(puzzleSize);
        testContext->pencilMarks = malloc(sizeof(char*) * context->cellCount);
        testContext->pencilMarks[0] = malloc(sizeof(char) * context->cellCount * context->maxNumberForPencils);
        for (uint i = 1; i < context->cellCount; i++) {
            testContext->pencilMarks[i] = &testContext->pencilMarks[0][i * context->maxNumberForPencils];
        }
        
        memcpy(testContext->problem, context->problem, puzzleSize);
        
        int startIndex = 0, endIndex = context->cellCount;
        uint *indexes = malloc(puzzleSize);
        memcpy(indexes, allIndexes, puzzleSize);
        
        while (endIndex - startIndex > 0) {
            uint indexToIndex = startIndex + (arc4random() % (endIndex - startIndex));
            uint index = indexes[indexToIndex];
            if ((indexToIndex - startIndex) < (endIndex - indexToIndex - 1)) {
                memmove(indexes + startIndex + 1, indexes + startIndex, sizeof(uint) * (indexToIndex - startIndex));
                startIndex++;
            }
            else {
                memmove(indexes + indexToIndex, indexes + indexToIndex + 1,
                    sizeof(uint) * (endIndex - indexToIndex - 1));
                endIndex--;
            }
            testContext->problem[index] = 0;
            
            if (solveContext(testContext) &&
                convertDifficultyScore(testContext->difficultyScore, testContext->order) <= expectedDifficulty) {
                
                dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
                uint targetDeltaMagnitude = targetDifficulty < testContext->difficultyScore ?
                    testContext->difficultyScore - targetDifficulty :
                    targetDifficulty - testContext->difficultyScore;
                uint hardestDeltaMagnitude = targetDifficulty < hardestDifficulty ?
                    hardestDifficulty - targetDifficulty :
                    targetDifficulty - hardestDifficulty;
                if (targetDeltaMagnitude < hardestDeltaMagnitude) {
                    hardestDifficulty = testContext->difficultyScore;
                    memcpy(targetProblem, testContext->problem, puzzleSize);
                }
                dispatch_semaphore_signal(lock);
            }
            else {
                testContext->problem[index] = context->solution[index];
            }
        }
        dispatch_release(stopSolve->lock);
        free(stopSolve);
        free(testContext->problem);
        free(testContext->solution);
        free(testContext->board);
        free(testContext->pencilMarks[0]);
        free(testContext->pencilMarks);
        free(testContext);
        free(indexes);
    };
    
    dispatch_apply(20, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), generationLoop);
    memcpy(context->problem, targetProblem, sizeof(uint) * context->cellCount);
    context->difficultyScore = hardestDifficulty;
    context->difficulty = convertDifficultyScore(context->difficultyScore, context->order);
    dispatch_release(lock);
    free(targetProblem);
    free(allIndexes);
}

#pragma mark Private Functions - Context set up

static void setUpRegions(MCSudokuSolveContext *context)
{
    for (int i = 0; i < context->cellCount; i++) {
        int row = i / context->dimensionality;
        int column = i % context->dimensionality;
        int box = (row / context->order) * context->order + (column / context->order);
        
        context->rowMap[row][column] = i;
        context->columnMap[column][row] = i;
        context->boxMap[box][(row % context->order) * context->order + (column % context->order)] = i;
    }
}

static void setUpNeighbours(MCSudokuSolveContext *context)
{
    char *indexSet = malloc(sizeof(char) * context->cellCount);
    for (int i = 0; i < context->cellCount; i++) {
        memset(indexSet, 0, sizeof(char) * context->cellCount);
        uint row = i / context->dimensionality;
        uint column = i % context->dimensionality;
        uint box = (row / context->order) * context->order + (column / context->order);
        
        for (int j = 0; j < context->dimensionality; j++) {
            uint rowIndex = context->rowMap[row][j],
            colIndex = context->columnMap[column][j],
            boxIndex = context->boxMap[box][j];
            indexSet[rowIndex] = rowIndex != i;
            indexSet[colIndex] = colIndex != i;
            indexSet[boxIndex] = boxIndex != i;
        }
        
        int neighbourIndex = 0;
        for (uint j = 0; j < context->cellCount; j++) {
            if (indexSet[j]) {
                context->neighbourMap[i][neighbourIndex++] = j;
            }
        }
    }
    free(indexSet);
}

static MCSudokuSolveContext *createContextWithOrder(uint order)
{
    MCSudokuSolveContext *context = malloc(sizeof(MCSudokuSolveContext));
    context->difficultyScore = 0;
    context->difficulty = MCPuzzleDifficultyZero;
    context->maxNumberForPencils = order * order;
    context->order = order;
    context->dimensionality = context->maxNumberForPencils;
    context->cellCount = context->dimensionality * context->dimensionality;
    context->neighbourCount = order * (3 * order - 2) - 1;
    context->solutionCount = 0;
    
    context->problem = calloc(context->cellCount, sizeof(uint));
    context->solution = calloc(context->cellCount, sizeof(uint));
    context->board = calloc(context->cellCount, sizeof(uint));
    
    context->boxMap = malloc(sizeof(uint*) * context->dimensionality);
    context->rowMap = malloc(sizeof(uint*) * context->dimensionality);
    context->columnMap = malloc(sizeof(uint*) * context->dimensionality);
    context->boxMap[0] = malloc(sizeof(uint) * context->cellCount);
    context->rowMap[0] = malloc(sizeof(uint) * context->cellCount);
    context->columnMap[0] = malloc(sizeof(uint) * context->cellCount);
    for (uint i = 1; i < context->dimensionality; i++) {
        context->boxMap[i] = &context->boxMap[0][i * context->dimensionality];
        context->rowMap[i] = &context->rowMap[0][i * context->dimensionality];
        context->columnMap[i] = &context->columnMap[0][i * context->dimensionality];
    }
    
    context->neighbourMap = malloc(sizeof(uint*) * context->cellCount);
    context->pencilMarks = malloc(sizeof(char*) * context->cellCount);
    context->neighbourMap[0] = malloc(sizeof(uint) * context->neighbourCount * context->cellCount);
    context->pencilMarks[0] = malloc(sizeof(char) * context->maxNumberForPencils * context->cellCount);
    MCSudokuSolveContextStopSolve *stopSolve = malloc(sizeof(MCSudokuSolveContextStopSolve));
    stopSolve->lock = dispatch_semaphore_create(1);
    stopSolve->stopSolve = 0;
    context->opaque = stopSolve;
    for (uint i = 1; i < context->cellCount; i++) {
        context->neighbourMap[i] = &context->neighbourMap[0][i * context->neighbourCount];
        context->pencilMarks[i] = &context->pencilMarks[0][i * context->maxNumberForPencils];
    }
    
    setUpRegions(context);
    setUpNeighbours(context);
    return context;
}

#pragma mark Public Functions

void destroyContext(MCSudokuSolveContext *context)
{
    if (context == NULL) { return; }
    dispatch_release(((MCSudokuSolveContextStopSolve *)context->opaque)->lock);
    free(context->boxMap[0]);
    free(context->rowMap[0]);
    free(context->columnMap[0]);
    free(context->neighbourMap[0]);
    free(context->pencilMarks[0]);
    free(context->problem);
    free(context->solution);
    free(context->board);
    free(context->boxMap);
    free(context->rowMap);
    free(context->columnMap);
    free(context->neighbourMap);
    free(context->pencilMarks);
    free(context->opaque);
    free(context);
}

int solveContext(MCSudokuSolveContext *context)
{
    if (context == NULL) { return 0; }
    if (context->problem == NULL) { return 0; }
    context->solutionCount = 0;
    context->difficultyScore = 0;
    memcpy(context->board, context->problem, sizeof(uint) * context->cellCount);
    markup(context);
    if (isPuzzleValid(context)) { solveContextRecursive(context); }
    context->difficulty = convertDifficultyScore(context->difficultyScore, context->order);
    return context->solutionCount == 1;
}

MCSudokuSolveContext *generatePuzzleWithOrder(uint order, MCPuzzleDifficulty expectedDifficulty)
{
    if (order == 0) { return NULL; }
    MCSudokuSolveContext *context = createContextWithOrder(order);
    if (expectedDifficulty == MCPuzzleDifficultyZero) { return context; }
    solveContext(context);
    memcpy(context->problem, context->solution, sizeof(uint) * context->cellCount);
    removeNumbersFromBoard(context, expectedDifficulty);
    memcpy(context->board, context->problem, sizeof(uint) * context->cellCount);
    return context;
}
