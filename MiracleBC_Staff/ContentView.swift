//
//  ContentView.swift
//  MiracleBC_Staff
//
//  Created by EVGENY ANTROPOV on 16.06.2019.
//  Copyright © 2019 Eugene Antropov. All rights reserved.
//

import SwiftUI
import Combine

struct ContentView : View {
    @State var image: UIImage?
    @State var lastDate: Date?
    @State var skipFirstFrames: Int = 0
    
    var body: some View {
        Group {
            if self.image != nil {
                UserInfoView(image: image)
            } else {
                VisionView(image: $image,  lastDate: $lastDate, skipFirstFrames: $skipFirstFrames)
            }
        }
        
    }
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
