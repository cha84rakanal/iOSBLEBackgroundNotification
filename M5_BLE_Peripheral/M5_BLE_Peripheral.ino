/*
    Based on Neil Kolban example for IDF:
   https://github.com/nkolban/esp32-snippets/blob/master/cpp_utils/tests/BLE%20Tests/SampleServer.cpp
    Ported to Arduino ESP32 by Evandro Copercini
    updates by chegewara
*/

#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <stdint.h>
#include <stdio.h>

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/

#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

static BLECharacteristic* pBleNotifyCharacteristic = NULL;
bool deviceConnected = false;

// Bluetooth LE Change Connect State
class MyServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) { deviceConnected = true; };

    void onDisconnect(BLEServer* pServer) { deviceConnected = false; }
};

void setup() {
    Serial.begin(115200);
    Serial.println("Starting BLE work!");

    BLEDevice::init("M5Peripheral");
    BLEServer* pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());
    BLEService* pService = pServer->createService(SERVICE_UUID);
    // BLE Characteristicの生成
    pBleNotifyCharacteristic = pService->createCharacteristic(
        // Characteristic UUIDを指定
        CHARACTERISTIC_UUID,
        // このCharacteristicのプロパティを設定
        BLECharacteristic::PROPERTY_NOTIFY);
    // BLE Characteristicにディスクリプタを設定
    pBleNotifyCharacteristic->addDescriptor(new BLE2902());

    pService->start();
    // BLEAdvertising *pAdvertising = pServer->getAdvertising();  // this still
    // is working for backward compatibility
    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(
        0x06);  // functions that help with iPhone connections issue
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();
    Serial.println(
        "Characteristic defined! Now you can read it in your phone!");
}

int i = 0;

void loop() {
    if (deviceConnected) {
        // put your main code here, to run repeatedly:
        uint8_t buf[16];
        String s = "Hello !" + String(i) + "\n";
        s.getBytes(buf, 16);
        pBleNotifyCharacteristic->setValue(buf, 16);
        pBleNotifyCharacteristic->notify();
        i++;
    }

    // 100ミリ秒停止します
    delay(100);
}
