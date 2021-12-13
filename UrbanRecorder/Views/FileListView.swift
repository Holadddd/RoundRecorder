//
//  FileListView.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/12/10.
//

import SwiftUI
import Neumorphic

struct FileListView: View {
    
    @FetchRequest(entity: RecordedData.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \RecordedData.timestamp, ascending: false)],
                  predicate: nil,
                  animation: .default)
    var recordedDatas: FetchedResults<RecordedData>
    
    @State var isEditing: Bool = false
    
    var onPlaying: (RecordedData?)->Void
    
    var onPause: ()->Void
    
    var onSelected: (RecordedData?)->Void
    
    var onDelete: (RecordedData)->Void
    
    let paddingValue: CGFloat = 10
    
    @Binding var dataOnExpanded: RecordedData?
    
    @Binding var dataOnPlaying: RecordedData?
    
    var body: some View {
        return VStack {
            HStack{
                Spacer()
                Button {
                    withAnimation {
                        isEditing.toggle()
                    }
                    
                } label: {
                    Text("Edit")
                        .frame(width: 40, height: 20, alignment: .center)
                }.softButtonStyle(RoundedRectangle(cornerRadius: 5),
                                  padding: 5,
                                  isPressed: isEditing)
            }.padding(EdgeInsets(top: 0,
                                 leading: 0,
                                 bottom: 0,
                                 trailing: 10))
            
            if recordedDatas.count > 0 {
                ForEach(recordedDatas) { data in
                    HStack {
                        if isEditing {
                            Button {
                                onDelete(data)
                                
                                if recordedDatas.count == 0 {
                                    isEditing.toggle()
                                }
                            } label: {
                                Image.init(systemName: "minus.circle.fill")
                            }
                            .softButtonStyle(Circle(),
                                             padding: paddingValue,
                                             textColor: .red)
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(data.fileName!)")
                                        .foregroundColor(Color.Neumorphic.secondary)
                                        .fontWeight(.bold)
                                    HStack {
                                        Text("Distance: \(data.movingDistance.string(fractionDigits: 2)) M").foregroundColor(Color.Neumorphic.secondary)
                                            .fontWeight(.light)
                                        Spacer()
                                        Text(getRecorderTimeFormat(UInt(data.recordDuration)))
                                            .foregroundColor(Color.Neumorphic.secondary)
                                            .fontWeight(.light)
                                    }
                                    
                                }
                                Spacer()
                            }
                            
                            if data == dataOnExpanded {
                                HStack(alignment: .center) {
                                    Spacer()
                                    Button {
                                        if data == dataOnPlaying {
                                            onPause()
                                        } else {
                                            onPlaying(data)
                                        }
                                    } label: {
                                        if data == dataOnPlaying {
                                            Image.init(systemName: "pause.fill")
                                        } else {
                                            Image.init(systemName: "play.fill")
                                        }
                                    }.softButtonStyle(RoundedRectangle(cornerRadius: 5),
                                                      padding: paddingValue)
                                    
                                    Spacer()
                                }
                            }
                        }.padding(paddingValue)
                            .background(Color.Neumorphic.main)
                            .cornerRadius(15)
                            .softOuterShadow(darkShadow: (data == dataOnPlaying) ? Color(hex: "#FF0000", alpha: 0.3) : Color.Neumorphic.darkShadow,
                                             lightShadow: (data == dataOnPlaying) ? Color(hex: "#FF0000", alpha: 0.2) : Color.Neumorphic.lightShadow,
                                             offset: 3)
                    }.onTapGesture {
                        withAnimation {
                            if dataOnExpanded == data {
                                onSelected(nil)
                            } else {
                                onSelected(data)
                            }
                        }
                    }
                }.padding(EdgeInsets(top: 5,
                                     leading: 15,
                                     bottom: 5,
                                     trailing: 15))
            } else {
                Text("No Storage Data")
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
        FileListView(onPlaying: {_ in
            
        }, onPause: {
            
        }, onSelected: { _ in
            
        }, onDelete: { _ in
            
        }, dataOnExpanded: .constant(nil),
                     dataOnPlaying: .constant(nil))
    }
}
