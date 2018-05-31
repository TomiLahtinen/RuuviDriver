//
//  Oscillator.swift
//  RuuviDriver
//
//  Created by Tomi Lahtinen on 30/05/2018.
//  Copyright © 2018 Tomi Lahtinen. All rights reserved.
//

import Foundation
import AudioKit

class Oscillator {
    
    let oscillator: AKOscillator
    let mixer: AKMixer
    
    init() {
        oscillator = AKOscillator()
        mixer = AKMixer(oscillator)
        AudioKit.output = mixer
        
        try? AudioKit.start()
        oscillator.amplitude = 1.0
        oscillator.frequency = 2000
        oscillator.start()
    }
    
    func set(amplitude to: Double) {
        oscillator.amplitude = abs(to)
    }
    
    func set(frequency to: Double) {
        oscillator.frequency = abs(to) * 10000
    }
}
