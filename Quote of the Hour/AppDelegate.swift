//  AppDelegate.swift
//  Quote of the Hour
//
//  Created by Peter Wallroth on 23/3/2023.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusBarItem: NSStatusItem!
    var statusBarMenu: NSMenu!
    var timer: Timer?
    var preferencesWindowController: PreferencesWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        preferencesWindowController = PreferencesWindowController()
        setupStatusBar()
        fetchQuote()
        setupTimer()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarMenu = NSMenu(title: "Quote of the Hour")
        
        statusBarItem.menu = statusBarMenu
        statusBarItem.button?.title = "Fetching quote…"

        let quoteMenuItem = NSMenuItem(title: "", action: #selector(fetchQuote), keyEquivalent: "")
        statusBarMenu.addItem(quoteMenuItem)
        
        let preferencesMenuItem = NSMenuItem(title: "Preferences..", action: #selector(openPreferences), keyEquivalent: "")
        preferencesMenuItem.target = self
        statusBarMenu.addItem(preferencesMenuItem)

        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusBarMenu.addItem(quitMenuItem)
    }

    @objc func fetchQuote() {
            let url = URL(string: "https://api.quotable.io/random")!
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data, error == nil else {
                    print("Error fetching quote:", error ?? "Unknown error")
                    return
                }

                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let content = jsonResponse["content"] as? String, let author = jsonResponse["author"] as? String {
                            
                            // Check if the quote length is more than 150 characters
                            if content.count > 150 {
                                // If the quote length is more than 150 characters, fetch a new quote
                                self.fetchQuote()
                            } else {
                                DispatchQueue.main.async {
                                    self.statusBarItem.button?.title = "\(author)"
                                    let quoteMenuItem = self.statusBarMenu.item(at: 0)
                                    quoteMenuItem?.title = "\"\(content)\" — \(author)"
                                    quoteMenuItem?.action = #selector(self.fetchQuote)
                                }
                            }
                        }
                    }
                } catch {
                    print("Error parsing JSON:", error)
                }
            }
            task.resume()
        }

    func setupTimer() {
        timer?.invalidate()
        let timeInterval = preferencesWindowController?.getSelectedTimeInterval() ?? 3600
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            self.fetchQuote()
        }
    }

    @objc func openPreferences() {
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

