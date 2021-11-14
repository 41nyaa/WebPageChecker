//
//  PageDataView.swift
//  WebPageChecker
//
//  Created by 41nyaa on 2021/09/19.
//

import SwiftUI

struct PageDataView: View {
    @State var model: PageModel
    
    var body: some View {
        ScrollView {
            VStack {
                HStack{
                    Text(model.url)
                        .font(.title2)
                    Spacer()
                }
                HStack{
                    Text("Updated at " + model.changed)
                        .font(.title3)
                    Spacer()
                }
                ForEach(Array(model.body.split(separator: "\n").enumerated()), id: \.element) {index, line in
                    HStack {
                        if model.diffLines.contains(index) {
                            Text(line)
                                .font(.caption)
                                .foregroundColor(Color.red)
                        } else {
                            Text(line)
                                .font(.caption)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding()
    }
}

//struct PageDataView_Previews: PreviewProvider {
//    static var previews: some View {
//        PageDataView(data: "Preview")
//    }
//}
