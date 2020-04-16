#import <Foundation/Foundation.h>
#import "Enum.h"
#import <AFNetworking.h>

@interface NSString (Add)

/**
 * 获取广告标识符
 */
+ (NSString *)getIDFA;
+ (NSString *)getIDFV;

#pragma mark -- app信息

/**
 * 获取app的BundleID
 */
+ (NSString *)getBundleID;
/**
 * 获取app的名字
 */
+ (NSString *)getAppName;
/**
 * 获取app版本号
 */
+ (NSString *)getAppVersion;
/**
 * 获取app Build号
 */
+ (NSString *)getAppBuild;

#pragma mark --
/**
 * 获取设备屏幕亮度 e.g. 0 .. 1.0
 */
+ (NSInteger)getScreenBrightness;

/**
 * 获取磁盘的总容量 MB
 */
+ (float)getTotalDiskCapacity;
/**
 * 获取未使用的磁盘的容量 MB
 */
+ (float)getFreeDiskCapacity;

/**
 * 监测是否开启代理
 */
+ (BOOL)cq_getProxyStatus;

/**
 * 监测是否开启VPN
 */
+ (BOOL)cq_isVPNOn;

#pragma mark -- 网络
/**
 * 获取网络状态
 *
 * @warning 使用时一定要保证statusbar没有隐藏
 */
+ (CQNetworkStatus)getNetworkStatus;

/**
 * 获取Wifi的信号强度
 */
+ (NSInteger)getWifiSignalStrength;

/**
 * 获取WiFi的SSID 也就是WiFi名称
 */
+ (NSString *)getWifiSSID;

/**
 * 获取WiFi的BSSID 也就是Mac地址
 */
+ (NSString *)getWifiBSSID;

/**
 * 是否安装SIM卡
 */
+ (BOOL)cq_isInstallSIMCard;

/**
 * 获取SIM卡的运营商 e.g. 移动 电信 联通
 */
+ (SIMCarrierName)getSIMCarrierName;

#pragma mark --

/**
 * 判断iPhone设备是否越狱
 */
+ (BOOL)cq_isJailBreak;

#pragma mark --
/**
 * 用bundleID判断是否安转此app
 *
 * @param bundleID 唯一标记
 */
+ (BOOL)cq_isInstalledWithBundleID:(NSString *)bundleID;

/**
 * 用bundleID打开设备上安装的app
 *
 * @param bundleID 唯一标记
 */
+ (BOOL)cq_openAppWithBundleID:(NSString *)bundleID;

/**
 * 是否重复安装
 *
 * @param bundleID 唯一标记
 */
+ (BOOL)cq_isReDownloadWithBundleID:(NSString *)bundleID;

+ (NSString *)cq_getPurchaserDSIDWithBundleId:(NSString *)bundleId;

+ (NSString*)cq_getToken:(NSDate *)currnetDate;

#pragma mark -- 解密

- (NSString *)cq_getEncryptString;

@end
