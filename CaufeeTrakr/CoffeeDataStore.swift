//
//  CoffeeDataStore.swift
//  CaufeeTrakr
//
//  Created by Jeff Martin on 5/7/24.
//

import os
import Foundation

actor CoffeeDataStore {
    let logger = Logger(subsystem: "ccom.fwps.CaufeeTrakr.CoffeeDataStore", category: "ModelIO")
    
    // Use this value to determine whether you have changes that can be saved to disk.
    private var savedValue: [Drink] = []
    
    // Begin saving the drink data to disk.
    func save(_ currentDrinks: [Drink]) {
        
        // Don't save the data if there haven't been any changes.
        if currentDrinks == savedValue {
            logger.debug("The drink list hasn't changed. No need to save.")
            return
        }
        
        // Save as a binary plist file.
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data: Data
        
        do {
            // Encode the currentDrinks array.
            data = try encoder.encode(currentDrinks)
        } catch {
            logger.error("An error occurred while encoding the data: \(error.localizedDescription)")
            return
        }
        
        do {
            // Write the data to disk
            try data.write(to: self.dataURL, options: [.atomic])
            
            // Update the saved value.
            self.savedValue = currentDrinks
            
            self.logger.debug("Saved!")
        } catch {
            self.logger.error("An error occurred while saving the data: \(error.localizedDescription)")
        }
    }
    
    // Begin loading the data from disk.
    func load() -> [Drink] {
        logger.debug("Loading the model.")
        
        let drinks: [Drink]
        
        do {
            // Load the drink data from a binary plist file.
            let data = try Data(contentsOf: self.dataURL)
            
            // Decode the data.
            let decoder = PropertyListDecoder()
            drinks = try decoder.decode([Drink].self, from: data)
            logger.debug("Data loaded from disk")
        } catch CocoaError.fileReadNoSuchFile {
            logger.debug("No file found--creating an empty drink list.")
            drinks = []
        } catch {
            fatalError("*** An unexpected error occurred while loading the drink list: \(error.localizedDescription) ***")
        }
        
        // Update the saved value.
        savedValue = drinks
        return drinks
    }

    // Returns the URL for the plist file that stores the drink data.
    private var dataURL: URL {
        get throws {
            try FileManager
                   .default
                   .url(for: .documentDirectory,
                        in: .userDomainMask,
                        appropriateFor: nil,
                        create: false)
                   // Append the file name to the directory.
                   .appendingPathComponent("CoffeeTracker.plist")
        }
    }
}
