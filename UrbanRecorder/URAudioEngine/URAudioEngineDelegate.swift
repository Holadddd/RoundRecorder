//
//  URAudioEngineDelegate.swift
//  UrbanRecorder
//
//  Created by ting hui wu on 2021/11/4.
//

import Foundation

protocol URAudioEngineDelegate: AnyObject {
    func didUpdateReceiversBufferMetaData(_ engine: URAudioEngine, metaData: URAudioBufferMetadata)
}
