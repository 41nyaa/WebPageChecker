//
//  ContentView.swift
//  WebPageChecker
//
//  Created by 41nyaa on 2020/11/29.
//
import SwiftUI
import CoreData

struct ContentView: View {
    @State var url: String = "https://"
    @State var invalidUrl: Bool = false
    @State var isShowingSetting : Bool = false
    @State var isShowingDetail : Bool = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: PageViewModel
    
    var body: some View {
        VStack {
            TextField(
                "Please type url down...",
                text: $url,
                onCommit: {add(url: url)}
            )
            .autocapitalization(.none)
            .keyboardType(.URL)
            .alert(isPresented: $invalidUrl) {
                Alert(title: Text("Invalid url"), dismissButton: .default(Text("OK")))
            }
            List {
                ForEach (self.viewModel.pages.reversed(), id:\.self) { page in
                    HStack{
                        Button(page.url /*+ " " + page.changed*/) {
                            UIApplication.shared.open(URL(string: page.url)!)
                            self.viewModel.beChecked(page.id)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .foregroundColor(page.checked ? (colorScheme == .dark ? Color.white : Color.black) : Color.red )
                        Spacer()
                        Button(action: {self.isShowingDetail.toggle()}) {
                            Label("", systemImage: "chevron.right.2")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .sheet(isPresented: self.$isShowingDetail) {
                            PageDataView(model: page)
                        }
                    }
                }
                .onDelete(perform: delete)
                
            }
            .listStyle(PlainListStyle())
            if self.viewModel.checkedTime != nil {
                Text(self.viewModel.checkedTime!)
            }
            HStack {
                Button("Check") {
                    self.viewModel.check()
                }
                .padding()
                Button(self.viewModel.timer == nil ? "Start" : "Stop") {
                    if self.viewModel.timer == nil {
                        self.viewModel.startTimer()
                    } else {
                        self.viewModel.cancelTimer()
                    }
                }
                .padding()
                Button("Setting") {
                    self.isShowingSetting.toggle()
                }
                .sheet(isPresented: self.$isShowingSetting) {
                    SettingView()
                }
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }

    func add(url: String) {
        self.invalidUrl = true
        if self.viewModel.isRegistered(url: url) {
            return
        }
        guard let newUrl = URL(string:url) else {
            return
        }
        let canOpen = UIApplication.shared.canOpenURL(newUrl)
        if canOpen {
            self.invalidUrl = false
            self.viewModel.add(url: url)
            self.url="https://"
        }
    }
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            self.viewModel.delete(index: index)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
