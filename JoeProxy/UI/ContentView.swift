//
//  ContentView.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: LogViewModel
    
    init(loggingService: LoggingService) {
        _viewModel = StateObject(wrappedValue: LogViewModel(loggingService: loggingService))
    }
    
    var body: some View {
        LogView(viewModel: viewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(loggingService: MockLoggingService())
    }
}
