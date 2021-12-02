//
//  ViewController.swift
//  iOSBLEBackgroundNotification
//
//  Created by Minagawa Tatsuya on 2021/12/03.
//

import CoreBluetooth
import Foundation
import UIKit

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    /// 接続先ローカルネーム
    private let connectToLocalName:String = "M5Peripheral"
    /// 接続先Peripheral情報
    private var connectToPeripheral: CBPeripheral!
    /// Write Characteristic
    private var writeCharacteristic: CBCharacteristic?
    /// Notify Characteristic
    private var notifyCharacteristic: CBCharacteristic?
    /// CBCentralManagerインスタンス
    private var centralManager: CBCentralManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self,
                           queue: nil,
                           options: [CBCentralManagerOptionRestoreIdentifierKey : "myKey"]);
        // Do any additional setup after loading the view.
        centralManager?.delegate = self
    }

    private func scanForPeripherals() {
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }

    // CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            print("poweredOff")
        case .unknown:
            print("unknown")
        case .resetting:
            print("resetting")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
        case .poweredOn:
            print("poweredOn")
            scanForPeripherals()
        default:
            print("no match state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        
    }

    /// スキャン結果取得
    ///
    /// - Parameters:
    ///   - central: CBCentralManager
    ///   - peripheral: CBPeripheral
    ///   - advertisementData: アドバタイズしたデータを含む辞書型
    ///   - RSSI: 周辺機器の現在の受信信号強度インジケータ（RSSI）（デシベル単位）
    func centralManager(_: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("Device Name: \(String(describing: advertisementData[CBAdvertisementDataLocalNameKey])), RSSI: \(RSSI)")
        // 対象機器のみ保持する
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
           peripheralName.contains(connectToLocalName) {
           // 対象機器のみ保持する
           self.connectToPeripheral = peripheral
           // 機器に接続
           print("機器に接続：\(String(describing: peripheral.name))")
           self.centralManager?.connect(peripheral, options: nil)
       }
    }

    /// 接続成功時
    ///
    /// - Parameters:
    ///   - central: CBCentralManager
    ///   - peripheral: CBPeripheral
    func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("接続成功")
        self.connectToPeripheral = peripheral
        self.connectToPeripheral?.delegate = self
        // 指定のサービスを探索
        if let peripheral = self.connectToPeripheral {
           peripheral.discoverServices([CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")])
        }
        // スキャン停止処理
        self.centralManager?.stopScan()
    }

    /// 接続失敗時
    ///
    /// - Parameters:
    ///   - central: CBCentralManager
    ///   - peripheral: CBPeripheral
    ///   - error: Error
    func centralManager(_: CBCentralManager, didFailToConnect _: CBPeripheral, error: Error?) {
        print("接続失敗：\(String(describing: error))")
    }

    /// 接続切断時
    ///
    /// - Parameters:
    ///   - central: CBCentralManager
    ///   - peripheral: CBPeripheral
    ///   - error: Error
    func centralManager(_: CBCentralManager, didDisconnectPeripheral _: CBPeripheral, error: Error?) {
        print("接続切断：\(String(describing: error))")
    }
    
    /// サービス検索結果の取得
    /// CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else{
            print("error")
            return
        }
        print("\(services.count)個のサービスを発見。\(services)")
        
        if let services = peripheral.services {
            for service in services {
                print("service uuid = \(service.uuid.uuidString)")
                connectToPeripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    private func peripheralNotifyStart() {
        if let characteristic = notifyCharacteristic {
            connectToPeripheral.setNotifyValue(true, for: characteristic)
            print(characteristic.uuid)
        }
    }
        
    private func peripheralNotifyStop() {
        if let characteristic = notifyCharacteristic {
            connectToPeripheral.setNotifyValue(false, for: characteristic)
            print(characteristic.uuid)
        }
    }
    
    /// キャラクタリスティック検索結果の取得
    /// CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("error:\(error)")
        } else {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    print("characteristic = \(characteristic)")
                    switch characteristic.properties {
                    case .write:
                        print("[CBPeripheralDelegate] write")
                        writeCharacteristic = characteristic
                    case .notify:
                        print("[CBPeripheralDelegate] notify")
                        notifyCharacteristic = characteristic
                        peripheralNotifyStart()
                    default:
                        print("[CBPeripheralDelegate] unknown")
                    }
                }
            }
        }
    }
    
    /// notifyのデータ受け取り
    /// CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("error:\(error) uuid:\(characteristic.uuid)")
        } else {
            if let value = characteristic.value , let str = String(data: value, encoding: .utf8) {
                print("\(str)")
                localNotification(message: str)
            }
        }
    }
    
    func localNotification(message : String) {
        let content = UNMutableNotificationContent()
        content.title = "お知らせ"
        content.body = message
        content.sound = UNNotificationSound.default

        // 直ぐに通知を表示
        let request = UNNotificationRequest(identifier: "immediately", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
