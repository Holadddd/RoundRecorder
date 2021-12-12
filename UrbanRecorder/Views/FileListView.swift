//
//  FileListView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/10.
//

import SwiftUI

struct FileListView: View {
    
    @FetchRequest(entity: RecordedData.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \RecordedData.timestamp, ascending: false)],
                  predicate: nil,
                  animation: .default)
    var recordedDatas: FetchedResults<RecordedData>
    
    
    var body: some View {
        return VStack {
            ForEach(recordedDatas) { data in
                
                HStack {
                    Text("\(data.fileName!)")
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
        FileListView()
    }
}
