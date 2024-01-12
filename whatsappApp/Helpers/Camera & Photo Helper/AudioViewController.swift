//
//  AudioViewController.swift
//  whatsappApp
//
//  Created by Abhishek Biswas on 12/01/24.
//

import Foundation
import IQAudioRecorderController


class AudioViewController {
    var delegate : IQAudioRecorderViewControllerDelegate
    
    init(_delegate: IQAudioRecorderViewControllerDelegate) {
        self.delegate = _delegate
    }
    
}
