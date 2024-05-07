//
//  ContentView.swift
//  CaufeeTrakr
//
//  Created by Jeff Martin on 5/7/24.
//

import os
import SwiftUI

struct ContentView: View {
    let logger = Logger(subsystem: "lol.jmtechwork.CaufeeTrakr.ContentView", category: "Root View")

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
