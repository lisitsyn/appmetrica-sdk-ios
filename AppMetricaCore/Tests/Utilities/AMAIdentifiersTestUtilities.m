
#import <UIKit/UIKit.h>
#import "AMAIdentifiersTestUtilities.h"
#import "AMAStartupClientIdentifier.h"
#import <AdSupport/AdSupport.h>
#import <Kiwi/Kiwi.h>
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAStartupClientIdentifierFactory.h"
#import "AMAUUIDProvider.h"
#import "AMAAdProvider.h"

@implementation AMAIdentifiersTestUtilities

+ (void)stubIdfaWithEnabled:(BOOL)isEnabled value:(NSString *)UUID
{
    AMAAdProvider *idfaMock = [AMAAdProvider mock];
    [idfaMock stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(isEnabled)];
    NSUUID *idfa = [[NSUUID alloc] initWithUUIDString:UUID];
    [idfaMock stub:@selector(advertisingIdentifier) andReturn:idfa];
    [AMAAdProvider stub:@selector(sharedInstance) andReturn:idfaMock];
}

+ (void)stubUUID:(NSString *)UUID
{
    AMAUUIDProvider *UUIDProvider = [AMAUUIDProvider nullMock];
    [UUIDProvider stub:@selector(retrieveUUID) andReturn:UUID];
    [AMAUUIDProvider stub:@selector(sharedInstance) andReturn:UUIDProvider];
}

+ (void)stubIFV:(NSString *)UUID
{
    id deviceMock = [UIDevice nullMock];
    NSUUID *ifv = [[NSUUID alloc] initWithUUIDString:UUID];
    [deviceMock stub:@selector(identifierForVendor) andReturn:ifv];
    [UIDevice stub:@selector(currentDevice) andReturn:deviceMock];
}

+ (void)stubDeviceIDHash:(NSString *)deviceIDHash
{
    [[AMAMetricaConfiguration sharedInstance].persistent stub:@selector(deviceIDHash) andReturn:deviceIDHash];
}

+ (void)stubClientIdentifiersProvider:(NSString *)UUID
                             deviceID:(NSString *)deviceID
                                  ifv:(NSString *)ifv
                         deviceIDHash:(NSString *)deviceIDHash
{
    AMAStartupClientIdentifier *startupClientID = [AMAStartupClientIdentifierFactory mock];
    [startupClientID stub:@selector(UUID) andReturn:UUID];
    [startupClientID stub:@selector(deviceID) andReturn:deviceID];
    [startupClientID stub:@selector(IFV) andReturn:ifv];
    [startupClientID stub:@selector(deviceIDHash) andReturn:deviceIDHash];
    [AMAStartupClientIdentifier stub:@selector(alloc) andReturn:startupClientID];
}

@end
