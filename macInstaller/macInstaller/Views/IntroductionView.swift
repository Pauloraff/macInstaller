//
//  IntroductionView.swift
//  macInstaller
//
//  Created by Paulo Raffaelli on 1/23/25.
//
import SwiftUI

struct IntroductionView: View {
   var body: some View {
        VStack(alignment: .leading) {
            Text("BRIEF_OVERVIEW")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("")
            Text("DESCRIPTION")
            Spacer()
        }.frame(maxWidth: 500.0)
            .padding(.leading, 10.0)
            .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            .background(Color.white)
    }
}
