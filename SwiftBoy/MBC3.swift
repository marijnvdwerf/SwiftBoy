//
//  MBC3.swift
//  SwiftBoy
//
//  Created by Michal Majczak on 24.02.2016.
//  Copyright © 2016 Michal Majczak. All rights reserved.
//

import Foundation

class MBC3 : IMemoryBankController {
    var rom: [UInt8]
    var ram: [UInt8]
    let type: UInt8
    let romSize: UInt8
    let ramSize: UInt8
    let romByteCount: Int
    let ramByteCount: Int
    
    var currentRomBank: UInt8
    var currentRamBank: UInt8
    
    var ramEnabled: Bool
    var rtcEnabled: Bool
    
    init(rom: [UInt8]) {
        type = rom[0x0147]
        romSize = rom[0x0148]
        ramSize = rom[0x0149]
        romByteCount = getROMTotalSize(romSize) //Int(0x8000) << Int(romSize)
        ramByteCount = getRAMTotalSize(ramSize) //ramSize == 0 ? 0 : Int(0x2000) << Int(ramSize-1)
        self.rom = [UInt8](count: romByteCount, repeatedValue: UInt8(0))
        self.rom[0..<rom.count] = rom[0..<rom.count]
        self.ram = [UInt8](count: ramByteCount, repeatedValue: UInt8(0))
        
        currentRomBank = 1
        currentRamBank = 0
        ramEnabled = false
        rtcEnabled = false
    }
    
    func read(address address: UInt16) -> UInt8 {
        switch Int(address) {
        case 0x0000...0x3FFF:
            return rom[Int(address)]
        case 0x4000...0x7FFF: // access rom bank
            return rom[Int(address) + 0x4000*(Int(currentRomBank) - 1)]
        case 0xA000...0xBFFF: // access ram bank
            if ramSize != 0 {
                if currentRamBank < 0x08 {
                    return ram[Int(address - 0xA000 + 0x2000*UInt16(currentRamBank))]
                } else {
                    LogE("RTC not implemented yet!!!")
                    //TODO RTC
                }
            }
        default:
            LogE("Invalid read in MBC3!")
            exit(-1)
        }
        return 0
    }
    
    func write(address address: UInt16, value: UInt8) {
        switch Int(address) {
        case 0x0000...0x1FFF: // if value = 0x0A enable RAM else disable RAM
            ramEnabled = (value & 0x0F == 0x0A)
        case 0x2000...0x3FFF: // value in range 0x01...0x1F selects lower 7-bits of ROM bank, 0x00 is translated to 0x01
            if value == 0x00 {
                currentRomBank = 1
            } else {
                currentRomBank = value & 0x7F
            }
        case 0x4000...0x5FFF: // value in range 0x00...0x08 selects RAM bank, 0x09 - 0x0C selects RTC
            currentRamBank = value & 0x0C
        case 0x6000...0x7FFF: // RTC latching
            LogE("RTC not implemented yet!!!")
            //TODO RTC latching
        case 0xA000...0xBFFF:
            if ramSize != 0 {
                ram[Int(address - 0xA000 + 0x2000*UInt16(currentRamBank))] = value
            }
        default:
            LogE("Invalid write in MBC3!")
            exit(-1)
        }
    }
    
    func getDMAData(address address: UInt16, size: UInt16) -> [UInt8] {
        var ret = [UInt8](count: Int(size), repeatedValue: UInt8(0))
        ret[0..<Int(size)] = ram[ Int(address - 0xA000)..<Int(address - 0xA000 + size)]
        return ret
    }
    
    func reset() {
        self.ram = [UInt8](count: ramByteCount, repeatedValue: UInt8(0))
        currentRomBank = 1
        currentRamBank = 0
        ramEnabled = false
    }
}