//
//  SettingView.swift
//  WebPageChecker
//
//  Created by 41nyaa on 2021/01/23.
//

import SwiftUI

struct SettingView: View {
    @State var interval : Int = UserDefaults.standard.integer(forKey: "interval")
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(selection: self.$interval, label: Text("")) {
                        Text("5 min").tag(5)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                        Text("60 min").tag(60)
                        Text("180 min").tag(180)
                        Text("360 min").tag(360)
                        Text("720 min").tag(720)
                    }
                }
                .onChange(of: self.interval, perform: { value in
                    UserDefaults.standard.setValue(value, forKey: "interval")
                })
            }
            .navigationBarTitle("The Least Check Interval")
        }
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
