//
//  FileListView.swift
//  RoundRecorder
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
    
    var setReload: ()->Void
    
    @Binding var fileListCount: Int
    
    @State var isEditing: Bool = false {
        didSet {
            dataOnExpanded = nil
        }
    }
    
    @Binding var isShowingAlert: Bool
    
    var requestOnPlaying: (RecordedData?)->Void
    
    var stopSubscriptionAndPlaying: (RecordedData?)->Void
    
    var onPause: ()->Void
    
    var onSelected: (RecordedData?)->Void
    
    var onDelete: (RecordedData)->Void
    
    let paddingValue: CGFloat = 10
    
    let secondaryColor = Color.Neumorphic.secondary
    
    @Binding var dataOnExpanded: RecordedData?
    
    @Binding var dataOnPlaying: RecordedData?
    
    let alertMessage: String = I18n.string(.CancelChannelSubscriptions)
    
    var playingDurationScale: Double {
        guard let dataOnExpanded = dataOnExpanded else { return 0}
        let playingDuration = dataOnExpanded.playingDuration
        return playingDuration == 0 ? 0 : (playingDuration / Double(dataOnExpanded.recordDuration))
    }
    var body: some View {
        return ZStack {
            VStack{
                HStack(alignment: .center){
                    Spacer()
                    Button {
                        withAnimation {
                            isEditing.toggle()
                        }
                        
                    } label: {
                        Text(I18n.string(.Edit))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.Neumorphic.secondary)
                    }.softButtonStyle(RoundedRectangle(cornerRadius: 5),
                                      padding: 3,
                                      isPressed: isEditing)
                    
                }.padding(EdgeInsets(top: 10,
                                     leading: 0,
                                     bottom: 0,
                                     trailing: 10))
                Spacer()
            }
            VStack {
                if recordedDatas.count > 0 {
                    VStack{
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
                                            
                                            HStack{
                                                Text("\(data.fileName!)")
                                                    .foregroundColor(Color.Neumorphic.secondary)
                                                    .fontWeight(.bold)
                                                Spacer()
                                            }
                                            
                                            HStack {
                                                Text("\(I18n.string(.Distance)): \(data.movingDistance.string(fractionDigits: 2)) M").foregroundColor(Color.Neumorphic.secondary)
                                                    .fontWeight(.light)
                                                Spacer()
                                                if data != dataOnExpanded {
                                                    Text(getRecorderTimeFormat(UInt(data.recordDuration)))
                                                        .foregroundColor(Color.Neumorphic.secondary)
                                                        .fontWeight(.light)
                                                }
                                            }
                                            if data == dataOnExpanded {
                                                // TODO: Playing rate
                                                HStack(alignment: .center, spacing: 0) {
                                                    Spacer()
                                                    Rectangle().fill(.orange).frame(width: getProgressRateLineWidth() * playingDurationScale, height: 2, alignment: .center).cornerRadius(1)
                                                    Rectangle().fill(secondaryColor).frame(width: getProgressRateLineWidth() * (1 - playingDurationScale), height: 2, alignment: .center).cornerRadius(1)
                                                    Spacer()
                                                }
                                                
                                                HStack(alignment: .center) {
                                                    Text(getRecorderTimeFormat(UInt(dataOnExpanded?.playingDuration ?? 0)))
                                                        .foregroundColor(Color.Neumorphic.secondary)
                                                        .fontWeight(.light)
                                                    Spacer()
                                                    Text(getRecorderTimeFormat(UInt(data.recordDuration)))
                                                        .foregroundColor(Color.Neumorphic.secondary)
                                                        .fontWeight(.light)
                                                }
                                            }
                                        }
                                    }
                                    
                                    if data == dataOnExpanded {
                                        VStack{
                                            HStack(alignment: .center) {
                                                Spacer()
                                                Button {
                                                    if data == dataOnPlaying {
                                                        onPause()
                                                    } else {
                                                        requestOnPlaying(data)
                                                    }
                                                } label: {
                                                    if data == dataOnPlaying {
                                                        Image.init(systemName: "pause.fill")
                                                    } else {
                                                        Image.init(systemName: "play.fill")
                                                    }
                                                }.softButtonStyle(RoundedRectangle(cornerRadius: 5),
                                                                  padding: paddingValue)
                                                    .alert(alertMessage, isPresented: $isShowingAlert) {
                                                        Button(I18n.string(.No), role: .cancel) {
                                                            print("Keep channel subscription")
                                                        }
                                                        Button(I18n.string(.Yes), role: .destructive) {
                                                            stopSubscriptionAndPlaying(data)
                                                        }
                                                    }
                                                Spacer()
                                            }
                                        }
                                        
                                    }
                                    Divider()
                                }.padding(paddingValue)
                                    .background(Color.Neumorphic.main)
                                    .cornerRadius(15)
                            }.onTapGesture {
                                if !isEditing {
                                    withAnimation {
                                        if dataOnExpanded == data {
                                            onSelected(nil)
                                        } else {
                                            onSelected(data)
                                        }
                                    }
                                }
                            }
                        }.padding(EdgeInsets(top: 5,
                                             leading: 15,
                                             bottom: 5,
                                             trailing: 15))
                    }
                    .segmentCardView(title: I18n.string(.Filelist))
                    .padding(EdgeInsets(top: 15,
                                        leading: 15,
                                        bottom: 5,
                                        trailing: 15))
                    
                } else {
                    Text(I18n.string(.NoStorageData))
                        .foregroundColor(Color.Neumorphic.secondary)
                        .fontWeight(.bold)
                        .padding(EdgeInsets(top: 30, leading: 0, bottom: 0, trailing: 0))
                }
                Spacer()
            }.softOuterShadow()
            
        }.onReceive(recordedDatas.publisher.count()) { count in
            if count != fileListCount {
                fileListCount = count
                setReload()
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
    
    private func getProgressRateLineWidth()->CGFloat {
        let width = (UIScreen.main.bounds.width - 70) * 0.9
        
        return width
    }
}

struct FileListView_Previews: PreviewProvider {
    static var previews: some View {
        FileListView(setReload: {
            
        }, fileListCount: .constant(0), isShowingAlert: .constant(false), requestOnPlaying: {_ in
            
        }, stopSubscriptionAndPlaying: { _ in
            
        }, onPause: {
            
        }, onSelected: { _ in
            
        }, onDelete: { _ in
            
        }, dataOnExpanded: .constant(nil),
                     dataOnPlaying: .constant(nil))
    }
}
