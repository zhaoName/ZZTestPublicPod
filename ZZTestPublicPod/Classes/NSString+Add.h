#import <Foundation/Foundation.h>

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

#pragma mark --


@end
