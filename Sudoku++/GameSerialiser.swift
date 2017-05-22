//
//  GameSerialiser.swift
//  Sudoku++
//
//  Created by Maarut Chandegra on 12/05/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

protocol Archivable
{
    init?(fromArchive: NSDictionary)
    func archivableFormat() -> NSDictionary
}

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
        do { try fileManager.removeItem(at: path.deletingLastPathComponent()) }
        catch { NSLog("Unable to delete saved state file") }
    }
    
    func save(_ model: Archivable) throws
    {
        self.removeOldSavedState()
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: path.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        let codedData = NSKeyedArchiver.archivedData(withRootObject: model.archivableFormat())
        do {
            try codedData.write(to: path, options: .atomic)
        }
        catch let error as NSError {
            NSLog("Couldn't write file to path: \(path.path)")
            NSLog("\(error.localizedDescription)\n\(error)")
        }
        
    }
    
    func load<T: Archivable>() -> T?
    {
        var game: T?
        do {
            let loadedData = try Data(contentsOf: path)
            if let dict = NSKeyedUnarchiver.unarchiveObject(with: loadedData) as? NSDictionary {
                game = T(fromArchive: dict)
            }
        }
        catch let error as NSError {
            NSLog("\(error.localizedDescription)\n\(error)")
        }
        return game
    }
}
