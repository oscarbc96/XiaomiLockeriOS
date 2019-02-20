import UIKit

func printPayload(payload: [UInt8]) {
    var str = "  Output: "
    for number in payload {
        str += String(format:"%02X", number)
    }
    print(str)
}
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
        
        checksum += multipleBytesToSend.count + 2
        payload.forEach({
            checksum += Int($0)
        })
        
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

let LockArray:[UInt8] = Message()
    .setDirection(newDirection: .MASTER_TO_M365)
    .setReadOrWrite(readOrWrite: .WRITE)
    .setPosition(pos: 0x71)
    .setPayload(singleByteToSend: 0x0001)
    .build()
print("--")
printPayload(payload: LockArray)

let UnlockArray:[UInt8] = Message()
    .setDirection(newDirection: .MASTER_TO_M365)
    .setReadOrWrite(readOrWrite: .WRITE)
    .setPosition(pos: 0x70)
    .setPayload(singleByteToSend: 0x0001)
    .build()
print("--")
printPayload(payload: UnlockArray)

let ChangePassArray:[UInt8] = Message()
    .setDirection(newDirection: .MASTER_TO_M365)
    .setReadOrWrite(readOrWrite: .WRITE)
    .setPosition(pos: 0x17)
    .setPayload(multipleBytesToSend: "932046".utf8.map{UInt8($0)})
    .build()
print("--")
printPayload(payload: ChangePassArray)

let TurnOffArray:[UInt8] = Message()
    .setDirection(newDirection: .MASTER_TO_M365)
    .setReadOrWrite(readOrWrite: .WRITE)
    .setPosition(pos: 0x79)
    .setPayload(singleByteToSend: 0x01)
    .build()
print("--")
printPayload(payload: TurnOffArray)

let TurnOnLed:[UInt8] = Message()
    .setDirection(newDirection: .MASTER_TO_M365)
    .setReadOrWrite(readOrWrite: .WRITE)
    .setPosition(pos: 0x7d)
    .setPayload(multipleBytesToSend: [0x02, 0x00])
    .build()
print("--")
print("Expected: 55aa0420037d020059ff")
printPayload(payload: TurnOnLed)

let TurnOffLed:[UInt8] = Message()
    .setDirection(newDirection: .MASTER_TO_M365)
    .setReadOrWrite(readOrWrite: .WRITE)
    .setPosition(pos: 0x7d)
    .setPayload(multipleBytesToSend: [0x00, 0x00])
    .build()
print("--")
print("Expected: 55aa0420037d00005bff")
printPayload(payload: TurnOffLed)
