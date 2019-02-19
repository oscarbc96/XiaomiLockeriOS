//
//  Payloads.swift
//  XiaomiLocker
//
//  Created by Oscar Blanco on 19/02/2019.
//  Copyright © 2019 Oscar Blanco. All rights reserved.
//

import Foundation

func randomString(length: Int) -> String {
    let numbers = "0123456789"
    return String((0...length-1).map{ _ in numbers.randomElement()! })
}

//  PAYLOADS
let LockArray:[UInt8] = Message()
    .setDirection(newDirection: .MASTER_TO_M365)
    .setReadOrWrite(readOrWrite: .WRITE)
    .setPosition(pos: 0x70)
    .setPayload(singleByteToSend: 0x0001)
    .build()

let UnlockArray:[UInt8] = Message()
    .setDirection(newDirection: .MASTER_TO_M365)
    .setReadOrWrite(readOrWrite: .WRITE)
    .setPosition(pos: 0x71)
    .setPayload(singleByteToSend: 0x0001)
    .build()

let ChangePassArray:[UInt8] = Message()
    .setDirection(newDirection: .MASTER_TO_M365)
    .setReadOrWrite(readOrWrite: .WRITE)
    .setPosition(pos: 0x79)
    .setPayload(multipleBytesToSend: randomString(length: 6).utf8.map{UInt8($0)})
    .build()

let TurnOffArray:[UInt8] = Message()
    .setDirection(newDirection: .MASTER_TO_M365)
    .setReadOrWrite(readOrWrite: .WRITE)
    .setPosition(pos: 0x79)
    .setPayload(singleByteToSend: 0x01)
    .build()

let TurnOnLed:[UInt8] = Message()
    .setDirection(newDirection: .MASTER_TO_M365)
    .setReadOrWrite(readOrWrite: .WRITE)
    .setPosition(pos: 0x7d)
    .setPayload(singleByteToSend: 0x02)
    .build()

let TurnOffLed:[UInt8] = Message()
    .setDirection(newDirection: .MASTER_TO_M365)
    .setReadOrWrite(readOrWrite: .WRITE)
    .setPosition(pos: 0x7d)
    .setPayload(singleByteToSend: 0x00)
    .build()

let payloads = [
    "Lock": Data(bytes: LockArray),
    "Unlock": Data(bytes: UnlockArray),
    "Change Password": Data(bytes: ChangePassArray),
    "Turn Off": Data(bytes: TurnOffArray),
    "Turn On Led": Data(bytes: TurnOnLed),
    "Turn Off Led": Data(bytes: TurnOffLed)
]
