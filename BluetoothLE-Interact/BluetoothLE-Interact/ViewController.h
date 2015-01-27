//
//  ViewController.h
//  BluetoothLE-Interact
//
//  Created by danny on 2014/1/21.
//  Copyright (c) 2014年 danny. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate> {
    
}


@property (nonatomic,strong) CBCentralManager *CM;

@property (nonatomic,weak) IBOutlet UITextField *textHeartRate;
@property (nonatomic,weak) IBOutlet UITextField *textHeartRateLocation;

- (IBAction)buttonScanAndConnect:(id)sender;
- (IBAction)buttonStop:(id)sender;



@end
