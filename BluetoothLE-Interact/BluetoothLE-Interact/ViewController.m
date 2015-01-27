//
//  ViewController.m
//  BluetoothLE-Interact
//
//  Created by danny on 2014/04/1.
//  Copyright (c) 2014年 danny. All rights reserved.
//

#import "ViewController.h"
#define HEART_RATE_MEASUREMENT_CHARACTERISTIC_UUID @"2A37"
#define HEART_RATE_BODY_LOCATION_CHARACTERISTIC_UUID @"2A38"

@interface ViewController () {
    CBPeripheral *connectPeripheral;
}
@end


@implementation ViewController

@synthesize CM;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    CM= [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)centralManagerDidUpdateState:(CBCentralManager*)cManager
{
    NSMutableString* nsmstring=[NSMutableString stringWithString:@"UpdateState:"];
    BOOL isWork=FALSE;
    switch (cManager.state) {
        case CBCentralManagerStateUnknown:
            [nsmstring appendString:@"Unknown\n"];
            break;
        case CBCentralManagerStateUnsupported:
            [nsmstring appendString:@"Unsupported\n"];
            break;
        case CBCentralManagerStateUnauthorized:
            [nsmstring appendString:@"Unauthorized\n"];
            break;
        case CBCentralManagerStateResetting:
            [nsmstring appendString:@"Resetting\n"];
            break;
        case CBCentralManagerStatePoweredOff:
            [nsmstring appendString:@"PoweredOff\n"];
            break;
        case CBCentralManagerStatePoweredOn:
            [nsmstring appendString:@"PoweredOn\n"];
            isWork=TRUE;
            break;
        default:
            [nsmstring appendString:@"none\n"];
            break;
    }
    NSLog(@"%@",nsmstring);
}



- (IBAction)buttonScanAndConnect:(id)sender {
    [CM stopScan];
    [CM scanForPeripheralsWithServices:nil options:nil];
    NSLog(@"Scan And Connect");
    
}

- (IBAction)buttonStop:(id)sender {
    
    [CM stopScan];
    NSLog(@"stopScan");
    
    if (connectPeripheral == NULL){
        NSLog(@"connectPeripheral == NULL");
        return;
    }
    
    if (connectPeripheral.state == CBPeripheralStateConnected) {
        [CM cancelPeripheralConnection:connectPeripheral];
        NSLog(@"disconnect-1");

    }
/*
    if ([connectPeripheral isConnected]) {
        [CM cancelPeripheralConnection:connectPeripheral];
        NSLog(@"disconnect-1");
    }
*/
}



- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {

    NSLog(@"peripheral\n%@\n",peripheral);
    NSLog(@"advertisementData\n%@\n",advertisementData);
    NSLog(@"RSSI\n%@\n",RSSI);
    
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    
    NSLog(@"localName:%@",localName);
    //if ([peripheral.name length] && [peripheral.name rangeOfString:@"DannySimpleBLE"].location != NSNotFound) {
    if ([localName length] && [localName rangeOfString:@"Polar"].location != NSNotFound) {
        //抓到週邊後就立即停子Scan
        [CM stopScan];
        NSLog(@"stopScan");
        connectPeripheral = peripheral;
        [CM connectPeripheral:peripheral options:nil];
        NSLog(@"connect to %@",peripheral.name);
    }
    
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@"%@",@"connected");
    NSLog(@"Connect To Peripheral with name: %@\nwith UUID:%@\n",peripheral.name,peripheral.identifier.UUIDString);
    
    peripheral.delegate=self;//連線成功後會回傳CBPeripheral，並邊要設定Delegate才能對後續的操作有所反應
    [peripheral discoverServices:nil];//一定要執行"discoverService"功能去尋找可用的Service
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"%@",@"disconnect-2");
}


//
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"didDiscoverServices:\n");
    if( peripheral.identifier == NULL  ) return; // zach ios6 added
    if (!error) {
        NSLog(@"====%@\n",peripheral.name);
        NSLog(@"=========== %ld of service for UUID %@ ===========\n",(long)peripheral.services.count,peripheral.identifier.UUIDString);
        
        for (CBService *p in peripheral.services){
            NSLog(@"Service found with UUID: %@\n", p.UUID);
            [peripheral discoverCharacteristics:nil forService:p];
        }
        
    }
    else {
        NSLog(@"Service discovery was unsuccessfull !\n");
    }
    
}
//
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
    CBService *s = [peripheral.services objectAtIndex:(peripheral.services.count - 1)];
    //NSLog(@"=========== Service UUID %s ===========\n",[NSUUID UUID] ini);
    if (!error) {
        NSLog(@"=========== %ld Characteristics of %@ service ",(long)service.characteristics.count,service.UUID);
        
        for(CBCharacteristic *c in service.characteristics){
            
            NSLog(@" %@ \n",c.UUID);
            //  CBService *s = [peripheral.services objectAtIndex:(peripheral.services.count - 1)];
            if(service.UUID == NULL || s.UUID == NULL) return; // zach ios6 added

            if ([c.UUID isEqual:[CBUUID UUIDWithString:HEART_RATE_MEASUREMENT_CHARACTERISTIC_UUID]]) {
                [peripheral setNotifyValue:YES forCharacteristic:c];//設定2A37為通知型，值有變化時會引發Delegate
                NSLog(@"找到 心跳測量屬性");
            }else if ([c.UUID isEqual:[CBUUID UUIDWithString:HEART_RATE_BODY_LOCATION_CHARACTERISTIC_UUID]]) {
                //讀取Heart Rate Measurement 位置
                [peripheral readValueForCharacteristic:c];
                NSLog(@"找到 心跳測量位置屬性 ");
            }
            
        }
        NSLog(@"=== Finished set notification ===\n");
        
        
    }
    else {
        NSLog(@"Characteristic discorvery unsuccessfull !\n");
        
    }

    
}
//更新通知Delegate，有進行setNotifyValue:forCharacteristic設定的UUID一旦有更新都會呼叫此protocol
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Updated value for heart rate measurement received
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:HEART_RATE_MEASUREMENT_CHARACTERISTIC_UUID]]) { // 1
        //如果更新符合HEART RATE MEASUREMENT UUID進行心跳值的轉換
        [self conveterBPMData:characteristic error:error];
        
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:HEART_RATE_BODY_LOCATION_CHARACTERISTIC_UUID]]) {  // 3
        [self conveterLocation:characteristic];
    }
}

- (void) conveterBPMData:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Get the Heart Rate Monitor BPM
    NSData *data = [characteristic value];      // 1
    const uint8_t *reportData = [data bytes];
    uint16_t bpm = 0;
    //判定第0個byte之第0個bit值為1的話要將取得的byte反轉 (LSB->MSB)
    if ((reportData[0] & 0x01) == 0) {          // 2
        // Retrieve the BPM value for the Heart Rate Monitor
        bpm = reportData[1];
    }
    else {
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));  // 3
    }
    // Display the heart rate value to the UI if no error occurred
    if( (characteristic.value)  || !error ) {   // 4
        NSLog(@"%@",[NSString stringWithFormat:@"%i bpm", bpm]);
        self.textHeartRate.text = [NSString stringWithFormat:@"%i", bpm];//更新UI資料
    }
    return;
}

- (void) conveterLocation:(CBCharacteristic *)characteristic
{
    NSData *sensorData = [characteristic value];//取得資料
    uint8_t *locationData = (uint8_t *)[sensorData bytes];//轉換成byte來取得特定的byte
    if (locationData ) {
        uint8_t sensorLocation = locationData[0];
        /*
         0 Other
         1 Chest 胸部
         2 Wrist
         3 Finger
         4 Hand
         5 Ear Lobe
         6 Foot
         7 ~ 255 Reserved for future use
         因Porla H7為胸部位置，所以針對取值後判斷是不是為1
         */
        NSLog(@"%@",[NSString stringWithFormat:@"位置: %@", sensorLocation == 1 ? @"胸部" : @"非位於胸部"]); // 3
        self.textHeartRateLocation.text = [NSString stringWithFormat:@"%@", sensorLocation == 1 ? @"胸部" : @"非位於胸部"];//更新UI資料
    }
    else {
        NSLog(@"%@",[NSString stringWithFormat:@"位置: 未知"]);
        self.textHeartRateLocation.text = [NSString stringWithFormat:@"未知"];//更新UI資料
    }
    return;
}
    
@end
