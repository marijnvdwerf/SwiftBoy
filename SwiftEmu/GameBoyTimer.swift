//
//  GameBoyClock.swift
//  SwiftEmu
//
//  Created by Michal Majczak on 15.09.2015.
//  Copyright (c) 2015 Michal Majczak. All rights reserved.
//

import Foundation

class GameBoyTimer {
    
    // timer helper functions
    var mCounter: UInt
    var baseCounter: UInt
    var divCounter: UInt
    var timaCounter: UInt
    
    var memory: GameBoyRAM
    
    init(memory mem: GameBoyRAM) {
        memory = mem
        mCounter = 0
        baseCounter = 0
        divCounter = 0
        timaCounter = 0
        memory.write(address: memory.DIV, value: 0)
        memory.write(address: memory.TIMA, value: 0)
        memory.write(address: memory.TMA, value: 0)
        memory.write(address: memory.TAC, value: 0)
    }
    
    func reset() {
        baseCounter = 0
        divCounter = 0
        timaCounter = 0
        memory.write(address: memory.DIV, value: 0)
        memory.write(address: memory.TIMA, value: 0)
        memory.write(address: memory.TMA, value: 0)
        memory.write(address: memory.TAC, value: 0)
    }
    
    func updateTimer(cycles: UInt8) {
        mCounter = mCounter &+ UInt(cycles)
        baseCounter += UInt(cycles)
        
        let baseBy4 = baseCounter / 4
        if(baseBy4 > 0) {
            baseCounter -= baseBy4 * 4
            divCounter += baseBy4
            timaCounter += baseBy4
            
            if divCounter >= 16 { //DIV updates at 1/16*4
                var div = memory.read(address: memory.DIV)
                div = div &+ UInt8(divCounter/16)
                memory.write(address: memory.DIV, value: div)
                divCounter %= 16
            }
            
            let timerControl = memory.read(address: memory.TAC)
            if timerControl & 0x04 > 0 {
                var increment = UInt8(0)
                switch  timerControl & 0x03 {
                case 0x00 where timaCounter >= 64: // M/64*4
                    increment = UInt8(timaCounter / 64)
                    timaCounter %= 64
                case 0x01:  // M/4
                    increment = UInt8(timaCounter)
                    timaCounter = 0
                case 0x02 where timaCounter % 4 == 0: // M/4*4
                    increment = UInt8(timaCounter / 4)
                    timaCounter %= 4
                case 0x03 where timaCounter % 16 == 0:// M/16*4
                    increment = UInt8(timaCounter / 16)
                    timaCounter %= 16
                default:
                    return
                }
                
                
                var tima = memory.read(address: memory.TIMA)
                var didOverflow = tima > 0xFF - increment
                tima = tima &+ increment
                memory.write(address: memory.TIMA, value: tima)
                memory.write(address: memory.TMA, value: tima)
                //TODO handle timer overflow interrupt
            }
            
        }
    }
    
    func getMTimer() -> UInt { return mCounter }
}