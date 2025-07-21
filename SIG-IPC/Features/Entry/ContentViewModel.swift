//
//  ContentViewModel.swift
//  SIG-IPC
//
//  Created by Adeline Charlotte Augustinne on 21/07/25.
//

import Foundation

class ContentViewModel: ObservableObject {
    @Published var displayMap: Bool = false
    
    func toggleMap() {
        self.displayMap = !self.displayMap
    }
}
