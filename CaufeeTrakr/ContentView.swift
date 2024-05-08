//
//  ContentView.swift
//  CaufeeTrakr
//
//  Created by Jeff Martin on 5/7/24.
//

import os
import SwiftUI

// A wrapper view that simplifies adding the main view to the hosting controller.
struct ContentView: View {
    
    let logger = Logger(subsystem: "lol.jmtechwork.CaufeeTrakr.ContentView", category: "Root View")
    
    @Environment(\.scenePhase) private var scenePhase
    
    // Access the shared model object.
    let data = CoffeeData.shared
    
    // Create the main view, and pass the model.
    var body: some View {
        CoffeeTrackerView()
            .environmentObject(data)
            .onChange(of: scenePhase, initial: true) { (_, newPhase) in
                switch newPhase {
                
                case .inactive:
                    logger.debug("Scene became inactive.")
                
                case .active:
                    logger.debug("Scene became active.")
                    
                    Task {
                        // Make sure the app has requested authorization.
                        let model = CoffeeData.shared
                        let success = await model.healthKitController.requestAuthorization()
                        
                        // Check for errors.
                        if !success { fatalError("*** Unable to authenticate HealthKit ***") }
                        
                        // Check for updates from HealthKit.
                        await model.healthKitController.loadNewDataFromHealthKit()
                    }
                    
                case .background:
                    logger.debug("Scene moved to the background.")
                    
                @unknown default:
                    logger.debug("Scene entered unknown state.")
                    assertionFailure()
                }
            }
    }
    
}

// The preview for the content view.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
