#import "BeaconBroadcast.h"

@interface BeaconBroadcast()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;

@end

@implementation BeaconBroadcast

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(startSharedAdvertisingBeaconWithString:(NSString *)uuid identifier:(NSString *)identifier)
{
    [[BeaconBroadcast sharedInstance] startAdvertisingBeaconWithString: uuid identifier: identifier];
}

RCT_EXPORT_METHOD(stopSharedAdvertisingBeacon)
{
    [[BeaconBroadcast sharedInstance] stopAdvertisingBeacon];
}

#pragma mark - Common

+ (id)sharedInstance
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;

    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;

    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });

    // returns the same object each time
    return _sharedObject;
}

- (void)startAdvertisingBeaconWithString:(NSString *)uuid identifier:(NSString *)identifier
{
  NSLog(@"Turning on advertising...");

  [self createBeaconRegionWithString:uuid identifier:identifier];

  if (!self.peripheralManager)
      self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];

  [self turnOnAdvertising];
}

- (void)stopAdvertisingBeacon
{
  [self.peripheralManager stopAdvertising];

  NSLog(@"Turned off advertising.");
}

- (void)createBeaconRegionWithString:(NSString *)uuid identifier:(NSString *)identifier
{
    if (self.beaconRegion)
        return;

    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:uuid];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:identifier];
    self.beaconRegion.notifyEntryStateOnDisplay = YES;
}

- (void)createLocationManager
{
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
}

#pragma mark - Beacon advertising

- (void)turnOnAdvertising
{
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral manager is off.");
        return;
    }

    time_t t;
    srand((unsigned) time(&t));
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:self.beaconRegion.proximityUUID
                                                                     major:rand()
                                                                     minor:rand()
                                                                identifier:self.beaconRegion.identifier];
    NSDictionary *beaconPeripheralData = [region peripheralDataWithMeasuredPower:nil];
    [self.peripheralManager startAdvertising:beaconPeripheralData];

    NSLog(@"Turning on advertising for region: %@.", region);
}

#pragma mark - Beacon advertising delegate methods
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheralManager error:(NSError *)error
{
    if (error) {
        NSLog(@"Couldn't turn on advertising: %@", error);
        return;
    }

    if (peripheralManager.isAdvertising) {
        NSLog(@"Turned on advertising.");
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager
{
    if (peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral manager is off.");
        return;
    }

    NSLog(@"Peripheral manager is on.");
    [self turnOnAdvertising];
}


@end
