//
//  CoffeeData.swift
//  CaufeeTrakr
//
//  Created by Jeff Martin on 5/7/24.
//

import Foundation
import os
import SwiftUI

@MainActor
class CoffeeData: ObservableObject {
    private let floatFormatter = FloatingPointFormatStyle<Double>().precision(.significantDigits(1...3))
    let logger = Logger(subsystem: "com.fwps.CaufeeTrakr.CoffeeData", category: "Model")
    
    // The data model needs to be accessed both from the app extension
    // and from the complication controller.
    static let shared = CoffeeData()
    lazy var healthKitController = HealthKitController(withModel: self)
    
    // An actor used to save and load the model data away from the main thread.
    private let store = CoffeeDataStore()
    
    // The list of drinks consumed.
    // Because this is @Published property,
    // Combine notifies any observers when a change occurs.
    @Published public private(set) var currentDrinks: [Drink] = []
    
    private func drinksUpdated() async {
        logger.debug("A value has been assigned to the current drinks property.")
        
        // Begin saving the data.
        await store.save(currentDrinks)
    }
    
    // The current level of caffeine in milligrams.
    // This property is calculated based on the currentDrinks array.
    public var currentMGCaffeine: Double {
        mgCaffeine(atDate: Date())
    }
    
    // A user-readable string representing the current amount of
    // caffeine in the user's body.
    public var currentMGCaffeineString: String {
        currentMGCaffeine.formatted(floatFormatter)
    }
    
    // Calculate the amount of caffeine in the user's system at the specified date.
    // The amount of caffeine is calculated from the currentDrinks array.
    public func mgCaffeine(atDate date: Date) -> Double {
        currentDrinks.reduce(0.0) {
            total, drink in total + drink.caffeineRemaining(at: date)
        }
    }

    // Return a user-readable string that describes the amount of caffeine in the user's
    // system at the specified date.
    public func mgCaffeineString(atDate date: Date) -> String {
        mgCaffeine(atDate: date).formatted(floatFormatter)
    }
    
    // Return the total number of drinks consumed today.
    // The value is in the equivalent number of 8 oz. cups of coffee.
    public var totalCupsToday: Double {
        
        // Calculate midnight this morning.
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date())
        
        // Filter the drinks.
        let drinks = currentDrinks.filter { midnight < $0.date }
        
        // Get the total caffeine dose.
        let totalMG = drinks.reduce(0.0) { $0 + $1.mgCaffeine }
        
        // Convert mg caffeine to equivalent cups.
        return totalMG / DrinkType.smallCoffee.mgCaffeinePerServing
    }
    
    // Return the total equivalent cups of coffee as a user-readable string.
    public var totalCupsTodayString: String {
        totalCupsToday.formatted(floatFormatter)
    }
    
    // Return green, yellow, or red depending on the caffeine dose.
    public func color(forCaffeineDose dose: Double) -> UIColor {
        if dose < 200.0 {
            return .green
        } else if dose < 400.0 {
            return .yellow
        } else {
            return .red
        }
    }
    
    // Return green, yellow, or red depending on the total daily cups of  coffee.
    public func color(forTotalCups cups: Double) -> UIColor {
        if cups < 3.0 {
            return .green
        } else if cups < 5.0 {
            return .yellow
        } else {
            return .red
        }
    }
    
    // Add a drink to the list of drinks.
    public func addDrink(mgCaffeine: Double, onDate date: Date) {
        logger.debug("Adding a drink.")
        
        // Create a local array to hold the changes.
        var drinks = currentDrinks
        
        // Create a new drink and add it to the array.
        let drink = Drink(mgCaffeine: mgCaffeine, onDate: date)
        drinks.append(drink)
        
        // Get rid of any drinks that are 24 hours old.
        drinks.removeOutdatedDrinks()
        
        currentDrinks = drinks
        
        // Save drink information to HealthKit.
        Task {
            await self.healthKitController.save(drink: drink)
            await self.drinksUpdated()
        }
    }
    
    // Update the model.
    public func updateModel(newDrinks: [Drink], deletedDrinks: Set<UUID>) async {
        
        guard !newDrinks.isEmpty && !deletedDrinks.isEmpty else {
            logger.debug("No drinks to add or delete from HealthKit.")
            return
        }
        
        // Remove the deleted drinks.
        var drinks = currentDrinks.filter { deletedDrinks.contains($0.uuid) }
        
        // Add the new drinks.
        drinks += newDrinks
        
        // Sort the array by date.
        drinks.sort { $0.date < $1.date }
        
        currentDrinks = drinks
        await drinksUpdated()
    }

    // MARK: - Private Methods
    
    // The model's initializer. Do not call this method.
    // Use the shared instance instead.
    private init() {
        
        // Begin loading the data from disk.
        Task { await load() }
    }
    
    // Begin loading the data from disk.
    func load() async {
        var drinks = await store.load()
        
        // Drop old drinks
        drinks.removeOutdatedDrinks()
                
        // Assign loaded drinks to model
        currentDrinks = drinks
        await drinksUpdated()
                
        // Load new data from HealthKit.
        guard await healthKitController.requestAuthorization() else {
            logger.debug("Unable to authorize HealthKit.")
            return
        }
            
        await self.healthKitController.loadNewDataFromHealthKit()
    }
}

extension Array where Element == Drink {
    // Filter array to only the drinks in the last 24 hours.
    fileprivate mutating func removeOutdatedDrinks() {
        let endDate = Date()
        
        // The date and time 24 hours ago.
        let startDate = endDate.addingTimeInterval(-24.0 * 60.0 * 60.0)

        // The date range of drinks to keep
        let today = startDate...endDate
        
        // Return an array of drinks with a date parameter between
        // the start and end dates.
        self.removeAll { drink in
            !today.contains(drink.date)
        }
    }
}
