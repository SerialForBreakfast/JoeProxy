//
//  LogTableViewController.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/8/24.
//
import SwiftUI
import AppKit

class LogTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    var logs: [LogEntry] = []
    var onSelectLog: ((LogEntry) -> Void)?

    private var tableView: NSTableView!

    init(logs: [LogEntry]) {
        self.logs = logs
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true

        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self

        let timestampColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Timestamp"))
        timestampColumn.title = "Timestamp"
        tableView.addTableColumn(timestampColumn)

        let requestColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Request"))
        requestColumn.title = "Request"
        tableView.addTableColumn(requestColumn)

        let headersColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Headers"))
        headersColumn.title = "Headers"
        tableView.addTableColumn(headersColumn)

        let responseColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Response"))
        responseColumn.title = "Response"
        tableView.addTableColumn(responseColumn)

        let statusCodeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("StatusCode"))
        statusCodeColumn.title = "Status Code"
        tableView.addTableColumn(statusCodeColumn)

        scrollView.documentView = tableView
        self.view = scrollView
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return logs.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row >= 0 && row < logs.count else {
            print("Attempted to load LogTableViewController with row \(row)")
            return nil
        }

        let log = logs[row]
        let identifier = tableColumn?.identifier.rawValue

        let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: identifier ?? "Cell")
        var cell = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTextField

        if cell == nil {
            cell = NSTextField(labelWithString: "")
            cell?.identifier = cellIdentifier
        }

        switch identifier {
        case "Timestamp":
            cell?.stringValue = log.timestampString
        case "Request":
            cell?.stringValue = log.request
        case "Headers":
            cell?.stringValue = log.headers
        case "Response":
            cell?.stringValue = log.response
        case "StatusCode":
            cell?.stringValue = log.statusCodeString
        default:
            cell?.stringValue = ""
        }

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 && selectedRow < logs.count {
            let selectedLog = logs[selectedRow]
            onSelectLog?(selectedLog)
        }
    }

    func updateLogs(_ newLogs: [LogEntry]) {
        DispatchQueue.main.async {
            self.logs = newLogs
            self.tableView.reloadData()
        }
    }
}

struct LogTableView: NSViewControllerRepresentable {
    var logs: [LogEntry]
    var onSelectLog: ((LogEntry) -> Void)?

    func makeNSViewController(context: Context) -> LogTableViewController {
        let logTableViewController = LogTableViewController(logs: logs)
        logTableViewController.onSelectLog = onSelectLog
        return logTableViewController
    }

    func updateNSViewController(_ nsViewController: LogTableViewController, context: Context) {
        nsViewController.updateLogs(logs)
    }
}

struct PrototypeAView: View {
    @ObservedObject var viewModel: LogViewModel
    @ObservedObject var networkingViewModel: NetworkingServiceViewModel

    @State private var filterText: String = ""
    @State private var isPaused: Bool = false

    var body: some View {
        VStack {
            HStack {
                TextField("Filter logs...", text: $filterText)
                    .padding()
                    .onChange(of: filterText) { newValue in
                        viewModel.updateFilteredLogs(with: newValue)
                    }
                Button(isPaused ? "Resume" : "Pause") {
                    isPaused.toggle()
                }
                .padding()
                Button("Save Logs") {
                    viewModel.saveLogsToFile()
                }
                .padding()
            }
            LogTableView(logs: viewModel.filteredLogs)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            viewModel.loadLogs()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

