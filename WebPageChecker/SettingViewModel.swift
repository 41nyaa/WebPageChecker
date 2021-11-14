//
//  SettingViewModel.swift
//  WebPageChecker
//
//  Created by 41nyaa on 2021/05/09.
//

import Foundation
import SwiftUI

final class SettingViewModel: ObservableObject {
    var setting : SettingModel = SettingModel()
    @State var interval: Int

    init() {
        self.interval = setting.get()
    }
    
    func set() {
        setting.set(interval: self.interval)
    }
}
