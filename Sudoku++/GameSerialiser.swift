//
//  GameSerialiser.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 12/05/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

class GameSerialiser
{
    private let path: URL
    
    init(withFileName fileName: String)
    {
        let fileManager = FileManager.default
        let directories = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        self.path = directories.first!.appendingPathComponent(fileName)
    }
    
    private func removeOldSavedState()
    {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path.path) {
            do { try fileManager.removeItem(at: path) }
            catch { NSLog("Unable to delete saved state file") }
        }
    }
    
    func saveGame(_ model: NSCoding) throws
    {
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: path.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        let codedData = NSKeyedArchiver.archivedData(withRootObject: model)
        self.removeOldSavedState()
        do {
            try codedData.write(to: path, options: .atomic)
        }
        catch let error as NSError {
            NSLog("Couldn't write file to path: \(path.path)")
            NSLog("\(error.localizedDescription)\n\(error)")
        }
        
    }
    
    func loadGame() -> NSCoding?
    {
        var game: NSCoding?
        do {
            let loadedData = try Data.init(contentsOf: path)
            game = NSKeyedUnarchiver.unarchiveObject(with: loadedData) as? NSCoding
        }
        catch let error as NSError {
            NSLog("\(error.localizedDescription)\n\(error)")
        }
        return game
    }
}
