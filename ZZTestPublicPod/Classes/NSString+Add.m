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
#import <RNDecryptor.h>
#import <CommonCrypto/CommonCrypto.h>
#import "QYEncryptStringData.h"

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


#pragma mark -- 网络

+ (CQNetworkStatus)getNetworkStatus
{
    __block CQNetworkStatus returnValue = CQNetworkStatusUnknow;
    
    if (![[NSThread currentThread] isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            returnValue = [self getNetworkStatus];
        });
        return returnValue;
    }
    id _statusBar = nil;
    if (@available(iOS 13.0, *)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        UIStatusBarManager *statusBarManager = [UIApplication sharedApplication].keyWindow.windowScene.statusBarManager;
        if ([statusBarManager respondsToSelector:@selector(createLocalStatusBar)]) {
            UIView *_localStatusBar = [statusBarManager performSelector:@selector(createLocalStatusBar)];
            if ([_localStatusBar respondsToSelector:@selector(statusBar)]) {
                _statusBar = [_localStatusBar performSelector:@selector(statusBar)];
            }
        }
#pragma clang diagnostic pop
        if (_statusBar) {
            // _UIStatusBarDataCellularEntry
            id currentData = [[_statusBar valueForKeyPath:@"_statusBar"] valueForKeyPath:@"currentData"];
            id _wifiEntry = [currentData valueForKeyPath:@"wifiEntry"];
            id _cellularEntry = [currentData valueForKeyPath:@"cellularEntry"];
            
            if (_wifiEntry && [[_wifiEntry valueForKeyPath:@"isEnabled"] boolValue]) {
                // If wifiEntry is enabled, is WiFi.
                returnValue = CQNetworkStatusWifi;
            }
            else if (_cellularEntry && [[_cellularEntry valueForKeyPath:@"isEnabled"] boolValue]) {
                NSNumber *type = [_cellularEntry valueForKeyPath:@"type"];
                if (type) {
                    switch (type.integerValue) {
                        case 5:
                            returnValue = CQNetworkStatus4G;
                            break;
                        case 4:
                            returnValue = CQNetworkStatus3G;
                        default:
                            returnValue = CQNetworkStatusUnknow;
                            break;
                    }
                }
            }
        }
    } else {
        UIApplication *app = [UIApplication sharedApplication];
        _statusBar = [app valueForKeyPath:@"_statusBar"];
        
        if ([_statusBar isKindOfClass:NSClassFromString(@"UIStatusBar_Modern")]) {
            // For iPhoneX
            NSArray *children = [[[_statusBar valueForKeyPath:@"_statusBar"] valueForKeyPath:@"foregroundView"] subviews];
            for (UIView *view in children) {
                for (id child in view.subviews) {
                    if ([child isKindOfClass:NSClassFromString(@"_UIStatusBarWifiSignalView")]) {
                        returnValue = CQNetworkStatusWifi;
                        break;
                    }
                    if ([child isKindOfClass:NSClassFromString(@"_UIStatusBarStringView")]) {
                        NSString *originalText = [child valueForKey:@"_originalText"];
                        if ([originalText containsString:@"G"]) {
                            if ([originalText isEqualToString:@"2G"]) {
                                returnValue = CQNetworkStatus2G;
                            } else if ([originalText isEqualToString:@"3G"]) {
                                returnValue = CQNetworkStatus3G;
                            } else if ([originalText isEqualToString:@"4G"]) {
                                returnValue = CQNetworkStatus4G;
                            } else {
                                returnValue = CQNetworkStatus4G;
                            }
                            break;
                        }
                    }
                }
            }
        } else {
            // For others iPhone
            NSArray *children = [[_statusBar valueForKeyPath:@"foregroundView"] subviews];
            int type = -1;
            for (id child in children) {
                if ([child isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
                    type = [[child valueForKeyPath:@"dataNetworkType"] intValue];
                }
            }
            switch (type) {
                case 0:
                    returnValue = CQNetworkStatusUnknow;
                    break;
                case 1:
                    returnValue = CQNetworkStatus2G;
                    break;
                case 2:
                    returnValue = CQNetworkStatus3G;
                    break;
                case 3:
                    returnValue = CQNetworkStatus4G;
                    break;
                case 5:
                    returnValue = CQNetworkStatusWifi;
                    break;
                default:
                    break;
            }
        }
    }
    
    return returnValue;
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

// 获取SIM卡运营商
+ (SIMCarrierName)getSIMCarrierName
{
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    NSString *carrierName = networkInfo.subscriberCellularProvider.carrierName;
    if ([carrierName isEqualToString:@"中国移动"]) {
        return SIMCarrierNameChinaMobile;
    }
    else if([carrierName isEqualToString:@"中国联通"]) {
        return SIMCarrierNameChinaUnicon;
    }
    else if([carrierName isEqualToString:@"中国电信"]) {
        return SIMCarrierNameChinaTelecom;
    }
    else {
        return SIMCarrierNameUnknow;
    }
}

/// 获取Wifi的信号强度
+ (NSInteger)getWifiSignalStrength
{
    if ([self getNetworkStatus] == CQNetworkStatusWifi) return -1;
    
    id statusBar = nil;
    int signalStrength = -1;
    if (@available(iOS 13, *)) {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wundeclared-selector"
        UIStatusBarManager *statusBarManager = [UIApplication sharedApplication].keyWindow.windowScene.statusBarManager;
        if ([statusBarManager respondsToSelector:@selector(createLocalStatusBar)]) {
            UIView *_localStatusBar = [statusBarManager performSelector:@selector(createLocalStatusBar)];
            if ([_localStatusBar respondsToSelector:@selector(statusBar)]) {
                statusBar = [_localStatusBar performSelector:@selector(statusBar)];
            }
        }
    #pragma clang diagnostic pop
        if (statusBar) {
            // _UIStatusBarDataCellularEntry
            id currentData = [[statusBar valueForKeyPath:@"_statusBar"] valueForKeyPath:@"currentData"];
            id _cellularEntry = [currentData valueForKeyPath:@"cellularEntry"];
            if (_cellularEntry && [[_cellularEntry valueForKeyPath:@"isEnabled"] boolValue]) {
                NSNumber *type = [_cellularEntry valueForKeyPath:@"type"];
                NSString *_str = [_cellularEntry valueForKeyPath:@"_string"];
                if (![_str isEqualToString:@"无SIM卡"]) {
                    signalStrength = type.intValue;
                }
            }
        }
    }
    else {
        UIApplication *appli = [UIApplication sharedApplication];
        statusBar = [appli valueForKey:@"statusBar"];
        
        if (iPhoneX || iPhoneXmax)
        {
            id statusBarView = [statusBar valueForKeyPath:@"statusBar"];
            UIView *foregroundView = [statusBarView valueForKeyPath:@"foregroundView"];
            NSArray *subviews = [[foregroundView subviews][2] subviews];
            
            for (id subview in subviews)
            {
                if ([subview isKindOfClass:NSClassFromString(@"_UIStatusBarWifiSignalView")]) {
                    signalStrength = [[subview valueForKey:@"_numberOfActiveBars"] intValue];
                }
            }
        }
        else {
            NSArray *subviews = [[statusBar valueForKey:@"foregroundView"] subviews];
            //-1代表wifi未连接
            for (id view in subviews)
            {
                if ([view isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]])
                {
                    signalStrength = [[view valueForKey:@"_wifiStrengthBars"] intValue];
                    break;
                }
            }
        }
    }
    return signalStrength;
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
#pragma mark -- 是否越狱

// 是否越狱
+ (BOOL)cq_isJailBreak
{
    NSArray *bundles = @[qy_OCString(_3784108089), qy_OCString(_301580735), qy_OCString(_3857008747), qy_OCString(_1386216873), qy_OCString(_358709726)];
    for (NSString *bundle in bundles)
    {
        if ([self cq_isInstalledWithBundleID:bundle]) return YES;
    }
    // 1.判定常用的越狱文件
    NSArray *files = @[qy_OCString(_1454923920), qy_OCString(_1407766725), qy_OCString(_3650059283), qy_OCString(_1513848991), qy_OCString(_466115639)];
    for (NSString *file in files)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:file]) return YES;
    }
    
    // 2.判断cydia的URL Scheme
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:qy_OCString(_1365527521)]]) return YES;
    
    // 3.读取系统所有应用的名称 这个是利用不越狱的机器没有这个权限来判定的
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/User/Applications/"])
    {
        NSArray *appList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/User/Applications/" error:nil];
        CQLog(@"appList:%@", appList);
        return YES;
    }
    
    // 4.使用stat方法来判定cydia是否存在
    if (checkInject()) return YES;
    
    // 5. 读取环境变量
    if (printEnv()) return YES;
    
    // 6.
    if ([self cq_jailBrokenWithWriteToFile]) return YES;
    return NO;
}

int checkInject(void) {
    NSString* dylib = [[NSString alloc] initWithUTF8String:libsystem_kernel_dylib_path_name()];
    if ([dylib rangeOfString:@"iPhoneSimulator"].location != NSNotFound || [dylib rangeOfString:@"Xcode"].location != NSNotFound) {
        // in simulator
        return 1;
    }
    if ([dylib isEqualToString:qy_OCString(_3928929132)]) {
        // attacker not inject the 'libsystem_kernel.dylib'
        return 0;
    } else {
        // do whatever as the attacker want on this os/device ...
        return 1;
    }
}

const char* libsystem_kernel_dylib_path_name() {
    int ret ;
    Dl_info dylib_info;
    int (*func_stat)(const char *, struct stat *) = stat;
    if ((ret = dladdr(func_stat, &dylib_info))) {
        return dylib_info.dli_fname;
    }
    return "";
}

void checkDylibs(void) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0 ; i < count; ++i) {
        NSString *name = [[NSString alloc]initWithUTF8String:_dyld_get_image_name(i)];
        CQLog(@"name:%@", name);
    }
}

char* printEnv(void) {
    char *env = getenv(qy_CString(_4253303225));
    // CQLog(@"%s", env);
    
    return env;
}

+ (BOOL)cq_jailBrokenWithWriteToFile
{
    NSError *error;
    NSString *stringToBeWritten = @"This is a test.";
    [stringToBeWritten writeToFile:qy_OCString(_449666947) atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if(error==nil){
        //Device is jailbroken
        return YES;
    } else {
        //Device is not jailbroken
        [[NSFileManager defaultManager] removeItemAtPath:qy_OCString(_449666947)  error:nil];
        return NO;
    }
}

#pragma mark --

+ (BOOL)cq_isInstalledWithBundleID:(NSString *)bundleID
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:@"extension.data"];
    NSArray *arr = [NSArray arrayWithContentsOfFile:path];
    
    if (arr.count == 0) return NO;
    
    NSBundle *container = [NSBundle bundleWithPath:[arr[0] cq_getEncryptString]];
    if ([container load]) {
        Class appContainer = NSClassFromString([arr[1] cq_getEncryptString]);
        SEL containerSEL = NSSelectorFromString([arr[2] cq_getEncryptString]);
        id test = [appContainer performSelector:containerSEL withObject:bundleID withObject:nil];
        if (test) {
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
}

// 用bundleID打开设备上安装的app
+ (BOOL)cq_openAppWithBundleID:(NSString *)bundleID
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:@"extension.data"];
    NSArray *arr = [NSArray arrayWithContentsOfFile:path];
    
    if (bundleID.length == 0 || arr.count == 0) return NO;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    Class ls_c = objc_getClass([[arr[3] cq_getEncryptString] cStringUsingEncoding:NSUTF8StringEncoding]);
    SEL dwss = NSSelectorFromString([arr[4] cq_getEncryptString]);
    NSObject* workspace = [ls_c performSelector:dwss];
    
    SEL oawbi = NSSelectorFromString([arr[5] cq_getEncryptString]);
    BOOL isOpen = (BOOL)[workspace performSelector:oawbi withObject:bundleID];
    CQLog(@"isOpen:%d", isOpen);
    return isOpen;
#pragma clang diagnostic pop
}

// 是否重复安装
+ (BOOL)cq_isReDownloadWithBundleID:(NSString *)bundleID
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:@"extension.data"];
    NSArray *arr = [NSArray arrayWithContentsOfFile:path];
    
    if (bundleID.length == 0 || arr.count == 0) return YES;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    NSString *ls = [arr[6] cq_getEncryptString];
    Class ls_c = objc_getClass([ls cStringUsingEncoding:NSUTF8StringEncoding]);
    
    SEL apfi = NSSelectorFromString([arr[7] cq_getEncryptString]);
    NSObject* lsap=  [ls_c performSelector:apfi withObject:bundleID];
    
    SEL iprd = NSSelectorFromString([arr[8] cq_getEncryptString]);
    bool isReDown = [lsap performSelector:iprd];
#pragma clang diagnostic pop
    //RELog(@"bundleid = %@\nstoreCohort = %@\nisReDown = %d", bundleID, storeCohort, isReDown);
    return isReDown;
}

/**
 deviceIdentifierVendorName : 北海泽豪网络科技有限公司
 purchaserDSID : 10895839079
 itemId(App ID) : 1282905232
 itemName : 翻翻配资
 termID : 5S9B229JVE
 */
+ (NSString *)cq_getPurchaserDSIDWithBundleId:(NSString *)bundleId
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:@"extension.data"];
    NSArray *arr = [NSArray arrayWithContentsOfFile:path];
    
    if (bundleId.length == 0 || arr.count == 0) return @"0";
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *ls = [arr[6] cq_getEncryptString];
    Class ls_c = objc_getClass([ls cStringUsingEncoding:NSUTF8StringEncoding]);
    
    SEL apfi = NSSelectorFromString([arr[7] cq_getEncryptString]);
    NSObject* lsap=  [ls_c performSelector:apfi withObject:bundleId];
    
    SEL scm = NSSelectorFromString([arr[9] cq_getEncryptString]);
    NSString* dsid = [NSString stringWithFormat:@"%@", [lsap performSelector:scm]];
#pragma clang diagnostic pop
    return dsid;
}

#pragma mark --
+ (NSString *)cq_getToken:(NSDate *)currnetDate
{
    //从1970算起的毫秒转化为String类型
    NSTimeInterval interval = [currnetDate timeIntervalSince1970]*1000;
    NSString *TimeStamp = [NSString stringWithFormat:@"%.0f", interval];
    
    long long time = [TimeStamp longLongValue];
    // 定义 block参数为long 返回值String
    NSString *(^myBlock)(long long);
    myBlock=^(long long time){
        
        NSString* t=[NSString stringWithFormat:@"chuangqi%lld",(time>>((time%5)+3))+time%99999];
        
        return [[t dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    };
    return myBlock(time);
}

#pragma mark -- 解密

- (NSString *)cq_getEncryptString
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self options:0];
    RNCryptorSettings RNCryptorCustomSettings = {
        .algorithm = kCCAlgorithmAES128,
        .blockSize = kCCBlockSizeAES128,
        .IVSize = kCCBlockSizeAES128,
        .options = kCCOptionPKCS7Padding,
        .HMACAlgorithm = kCCHmacAlgSHA256,
        .HMACLength = CC_SHA256_DIGEST_LENGTH,
        
        .keySettings = {
            .keySize = kCCKeySizeAES256,
            .saltSize = 8,
            .PBKDFAlgorithm = kCCPBKDF2,
            .PRF = kCCPRFHmacAlgSHA1,
            .rounds = 10,
            .hasV2Password = 0
        },
        .HMACKeySettings = {
            .keySize = kCCKeySizeAES256,
            .saltSize = 8,
            .PBKDFAlgorithm = kCCPBKDF2,
            .PRF = kCCPRFHmacAlgSHA1,
            .rounds = 10,
            .hasV2Password = 0
        }
    };
    data = [RNDecryptor decryptData:data withSettings:RNCryptorCustomSettings password:qy_OCString(_1804480085) error:nil];
    NSString *decryptStr = [data base64EncodedStringWithOptions:0];
    data = [[NSData alloc] initWithBase64EncodedString:decryptStr options:0];
    decryptStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    data = [[NSData alloc] initWithBase64EncodedString:decryptStr options:0];
    decryptStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return decryptStr;
}

@end
