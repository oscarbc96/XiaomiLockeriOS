//
//  Message.swift
//  XiaomiLocker
//
//  Created by Oscar Blanco on 13/02/2019.
//  Copyright © 2019 Oscar Blanco. All rights reserved.
//

import Foundation

enum MessageCommands: UInt8 {
    case MASTER_TO_M365 = 0x20
    case MASTER_TO_BATTERY = 0x22
    case READ = 0x01
    case WRITE = 0x03
}

class Message {
    private var message = [UInt8]()
    
    private var direction: UInt8 = 0
    private var rw: UInt8 = 0
    private var position: UInt8 = 0
    private var payload = [UInt8]()
    private var checksum: Int = 0
    
    
    func setDirection(newDirection: MessageCommands) -> Message {
        direction = newDirection.rawValue
        checksum += Int(direction)
        return self
    }
    
    func setReadOrWrite(readOrWrite: MessageCommands) -> Message { // read or write
        rw = readOrWrite.rawValue
        checksum += Int(rw)
        return self
    }
    
    func setPosition(pos: UInt8) -> Message {
        position = pos
        checksum += Int(position)
        return self
    }
    
    func setPayload(singleByteToSend: UInt8) -> Message {
        payload.append(singleByteToSend)
        checksum += 3
        checksum += Int(singleByteToSend)
        return self
    }
    
    func setPayload(multipleBytesToSend: [UInt8]) -> Message {
        payload.append(contentsOf: multipleBytesToSend)
        checksum += payload.count + 2
        payload.forEach {
            checksum += Int($0)
        }
        return self
    }
    
    private func setupHeaders() {
        message.append(0x55)
        message.append(0xAA)
    }
    
    private func setupBody() {
        message.append(UInt8(payload.count + 2))
        message.append(direction)
        message.append(rw)
        message.append(position)
        
        for byte in payload {
            message.append(byte)
        }
    }
    
    private func calculateChecksum() {
        checksum = checksum ^ 0xffff
        message.append(UInt8(checksum & 0xff))
        message.append(UInt8(checksum >> 8))
    }
    
    private func buildMessage() -> [UInt8] {
        return message
    }
    
    func build() -> [UInt8] {
        setupHeaders()
        setupBody()
        calculateChecksum()
        return buildMessage()
    }
}
