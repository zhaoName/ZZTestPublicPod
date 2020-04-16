#import "NSString+Add.h"
#import <AdSupport/AdSupport.h>
#import <dlfcn.h>
#import <sys/stat.h>
#import <mach-o/dyld.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonCrypto.h>

#define iPhoneX (SCREEN_WIDTH == 375.f && SCREEN_HEIGHT == 812.f)
#define iPhoneXmax (SCREEN_WIDTH == 414.f && SCREEN_HEIGHT == 896.f)

@implementation NSString (Add)

// 351838AD-C3BD-49D7-8FB3-665FE3CB0A3C
+ (NSString *)getIDFA
{
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

+ (NSString *)getIDFV
{
    return [UIDevice currentDevice].identifierForVendor.UUIDString;
}

#pragma mark -- app信息
+ (NSString *)getBundleID
{
    return [NSBundle mainBundle].infoDictionary[@"CFBundleIdentifier"];
}

+ (NSString *)getAppName
{
    return [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
}

// 获取app版本号
+ (NSString *)getAppVersion
{
    return [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
}

// 获取app Build号
+ (NSString *)getAppBuild
{
    return [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];
}

#pragma mark --

// 屏幕亮度
+ (NSInteger)getScreenBrightness
{
    return [UIScreen mainScreen].brightness * 100;
}

// 磁盘总容量
+ (float)getTotalDiskCapacity
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    NSDictionary *systemAttributes = [[NSFileManager defaultManager] fileSystemAttributesAtPath:NSHomeDirectory()];
#pragma clang diagnostic pop
    NSString *diskTotalSize = [systemAttributes objectForKey:@"NSFileSystemSize"];
    return [diskTotalSize floatValue]/1000/1000;
}

// 磁盘未使用容量
+ (float)getFreeDiskCapacity
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    NSDictionary *systemAttributes = [[NSFileManager defaultManager] fileSystemAttributesAtPath:NSHomeDirectory()];
#pragma clang diagnostic pop
    NSString *diskFreeSize = [systemAttributes objectForKey:@"NSFileSystemFreeSize"];
    return [diskFreeSize floatValue]/1000/1000;
}

// 获取WiFi的SSID 也就是WiFi名称
+ (NSString *)getWifiSSID
{
    NSString *ssid = @"Not Found";
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray != nil)
    {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray,0));
        if (myDict != nil) {
            NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
            ssid = [dict valueForKey:@"SSID"];//Mac Name
        }
    }
    return ssid;
}

// 获取WiFi的BSSID 也就是Mac地址
+ (NSString *)getWifiBSSID
{
    NSString *macIp = @"Not Found";
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray != nil)
    {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray,0));
        if (myDict != nil) {
            NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
            macIp = [dict valueForKey:@"BSSID"];//Mac address
        }
    }
    return macIp;
}

// 是否安装SIM卡
+ (BOOL)cq_isInstallSIMCard
{
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    
    return carrier.isoCountryCode.length;
}

// getProxyStatus
+ (BOOL)cq_getProxyStatus
{
    NSDictionary *proxySettings = (__bridge NSDictionary *)(CFNetworkCopySystemProxySettings());
    NSURL *url = [NSURL URLWithString:@"http://www.google.com"];
    NSArray *proxies = (__bridge NSArray *)(CFNetworkCopyProxiesForURL((__bridge CFURLRef)(url),
                                                                       (__bridge CFDictionaryRef)(proxySettings)));
    NSDictionary *settings = proxies[0];
    if ([[settings objectForKey:(NSString *)kCFProxyTypeKey] isEqualToString:@"kCFProxyTypeNone"]) {
        return NO;
    }
    else {
        return YES;
    }
}
+ (BOOL)cq_isVPNOn
{
    BOOL flag = NO;
    NSDictionary * proxySettings = (__bridge NSDictionary *)CFNetworkCopySystemProxySettings();
    NSArray *keys = [proxySettings[@"__SCOPED__"] allKeys];
    for (NSString *key in keys) {
        if ([key rangeOfString:@"tap"].location != NSNotFound ||
            [key rangeOfString:@"tun"].location != NSNotFound ||
            [key rangeOfString:@"ipsec"].location != NSNotFound ||
            [key rangeOfString:@"ppp"].location != NSNotFound) {
            flag = YES;
            break;
        }
    }
    return flag;
}


@end
