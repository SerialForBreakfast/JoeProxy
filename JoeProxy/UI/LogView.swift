//
//  LogView.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//

import SwiftUI
import Combine

struct LogView: View {
    @ObservedObject var viewModel: LogViewModel
    
    var body: some View {
        NavigationView {
            List(viewModel.logs, id: \.self) { log in
                Text(log)
            }
            .navigationTitle("Network Logs")
        }
    }
}

class LogViewModel: ObservableObject {
    @Published var logs: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(loggingService: LoggingService) {
        loggingService.logsPublisher
            .sink { [weak self] newLogs in
                self?.logs = newLogs
            }
            .store(in: &cancellables)
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView(viewModel: LogViewModel(loggingService: MockLoggingService()))
    }
}

// Mock Logging Service for Preview
class MockLoggingService: LoggingService {
    var logsPublisher: AnyPublisher<[String], Never> {
        Just(["Log 1", "Log 2", "Log 3"]).eraseToAnyPublisher()
    }
    
    func log(_ message: String, level: LogLevel) {}
    var logs: [String] = []
}
