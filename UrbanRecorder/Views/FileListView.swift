//
//  FileListView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/10.
//

import SwiftUI

struct FileListView: View {
    
    @Binding var dataInfoList: [RecordDataInfo]
    
    var body: some View {
        return VStack {
            ForEach(dataInfoList.indices, id: \.self) { index in
                
                HStack {
                    let dataInfo = dataInfoList[index]
                    Text("\(dataInfo.dataName)")
                        .foregroundColor(.black)
                        .background(.clear)
                    
                }.padding(20)
                    .softOuterShadow()
            }
        }
    }
    
    private func getRecorderTimeFormat(_ seconds: UInt) -> String {
        let timeUnit = seconds.toHoursMinutesSeconds()
        
        let hourUnit = timeUnit.0
        let minuteUnit = timeUnit.1.toTimeUnit()
        let secondUnit = timeUnit.2.toTimeUnit()
        
        if timeUnit.0 > 0 {
            return "\(hourUnit):\(minuteUnit):\(secondUnit)"
        } else {
            return "\(minuteUnit):\(secondUnit)"
        }
    }
}

struct FileListView_Previews: PreviewProvider {
    static var previews: some View {
        FileListView(dataInfoList: .constant([RecordDataInfo(dataName: "Test",
                                                             data: Data(),
                                                             movingDistance: 12.3,
                                                             recordDuration: 66)]))
    }
}
