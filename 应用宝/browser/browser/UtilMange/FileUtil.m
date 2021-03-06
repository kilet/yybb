//
//  FileUtil.m
//  browser
//
//  Created by 王 毅 on 12-11-8.
//
//

#import "FileUtil.h"
#import "AppStatusManage.h"
#import "GTMBASE64.h"
#import "Reachability.h"
#import "SettingPlistConfig.h"
#import "IPAdress.h"
#import "SettingPlistConfig.h"
#import "encry.h"
#import "NSString+Hashing.h"
#import "BppDownloadToLocal.h"
#import "TMCache.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import <sys/utsname.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AdSupport/AdSupport.h>
#import <AdSupport/ASIdentifierManager.h>
#import "UIApplication+MS.h"
#import "TFHpple.h"
#import "TFHppleElement.h"
#import "CJSONDeserializer.h"
#import "RegExCategories.h"

#import "JSONKit.h"
#import "DESUtils.h"
#include <dlfcn.h>


#define SELECT_FLAG @"searchKind.plist"
#define DOWNLOADHEAD @"marketinterfacedownloadstate&appid="


@interface FileUtil()
@end

@implementation FileUtil

+ (FileUtil *)instance
{
    static FileUtil *instance=nil;
    if (instance == nil) {
        instance = [[FileUtil alloc] init];
    }
    return instance;
}

-(id)init{
    self = [super init];
    if(self){
        
        
        
    }
    return  self;
}

-(void)dealloc{

}

-(BOOL)isExistFile:(NSString *)path{
    return [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil];
}

-(NSString *)getDocumentsPath{
    
    //app可能安装到2个位置
    //  1. /private/var/mobile/Containers/Bundle/Application/FA79D7BC-3CA8-47A5-828E-254960EE0704/xxx.app
    //  2. /Applications/xxx.app
    NSString * pos = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] lastPathComponent];
    if( [pos isEqualToString:@"Applications"] ){
        
        NSString * mobileRootDocuments = @"/var/mobile/Documents";
        [[NSFileManager defaultManager] createDirectoryAtPath:mobileRootDocuments
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        
        NSString *documents = [mobileRootDocuments stringByAppendingPathComponent: [[NSBundle mainBundle] bundleIdentifier]];
        [[NSFileManager defaultManager] createDirectoryAtPath:documents
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        return documents;
    }
    
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}
-(NSString *)getLibraryPath{
    
    NSString * pos = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] lastPathComponent];
    if( [pos isEqualToString:@"Applications"] ){
        
        NSString * mobileRootDocuments = @"/var/mobile/Library";
        [[NSFileManager defaultManager] createDirectoryAtPath:mobileRootDocuments
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        
        NSString *documents = [mobileRootDocuments stringByAppendingPathComponent: [[NSBundle mainBundle] bundleIdentifier]];
        [[NSFileManager defaultManager] createDirectoryAtPath:documents
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        return documents;
    }
    
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

- (NSString*)base64Str:(NSString*)plainText
{
    NSData *data = [plainText dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSString* encoded = [[NSString alloc] initWithData:[GTMBASE64 encodeData:data] encoding:NSUTF8StringEncoding];
    return encoded;
}

- (NSString*)unbase64Str:(NSString*)plainText{
    NSString* decoded = [[NSString alloc] initWithData:[GTMBASE64 decodeString:plainText] encoding:NSUTF8StringEncoding];
    return decoded;
}

-(NSString*)GetCurrntNet
{
    NSString * result = nil;
    if (![[Reachability reachabilityForInternetConnection]isReachable] && ![[Reachability reachabilityForInternetConnection]isReachableViaWiFi] && ![[Reachability reachabilityForInternetConnection]isReachableViaWWAN])
    {
        result = nil;
    }
    if ([[Reachability reachabilityForInternetConnection]isReachableViaWWAN])
    {
        result=@"3g";
    }
    if ([[Reachability reachabilityForInternetConnection]isReachableViaWiFi]) {
        result=@"wifi";
    }
    
    return result;
    
}

#pragma mark MAC

// Return the local MAC addy

// Courtesy of FreeBSD hackers email list

// Accidentally munged during previous update. Fixed thanks to mlamb.


- (NSString *) macaddress{
    
    NSString * systemVersion = [[UIDevice currentDevice] systemVersion];
    
    if ([systemVersion hasPrefix:@"7"] ) {
        return @"";
    }else{
        return [self getMacaddress];
    }
    
}


- (NSString *) getMacaddress
{
    int                    mib[6];
    size_t                len;
    char                *buf;
    unsigned char        *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl    *sdl;
    

    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error/n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1/n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!/n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        return NULL;
    }
    

    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    
    // NSString *outstring = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    
    NSString *outstring = [NSString stringWithFormat:@"%02x-%02x-%02x-%02x-%02x-%02x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    
    free(buf);
    
    return [outstring uppercaseString];
}

- (NSString *)getDeviceFileUdid{
    
    
    NSError * error = nil;
    
    NSString *devUdid = nil;
    
    do {
        
    NSString *path = [NSString stringWithContentsOfFile:@"/var/mobile/Media/iTunes_Control/iTunes/kyinfo.dat"
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    devUdid = [dic objectForKey:@"devid"];
    
    
    NSString * LibraryPath = [self getLibraryPath];
    NSString *_path = [NSString stringWithFormat:@"%@/devid.plist",LibraryPath];
    NSMutableDictionary *libraryDic = [NSMutableDictionary dictionaryWithContentsOfFile:_path];
    NSMutableDictionary *_libraryDic = [libraryDic objectForKey:@"DEVID"];
    NSString *devString = nil;
    devString = [_libraryDic objectForKey:@"DEVID"];
    
    
    BOOL isDirExist = [self isExistFile:path];
    BOOL _isDirExist = [self isExistFile:_path];
    
    if (isDirExist == YES) {
        
        if (devUdid != nil && ![devUdid isEqualToString:@""]) {
            return devUdid;
        }else{
            if (_isDirExist == YES) {
                
                if (devString != nil && ![devString isEqualToString:@""]) {
                    return devString;
                }else{
                        break;
                        //return @"NotFound";
                }
                
            }else{
                    
                    break;
                    //return @"NotFound";
            }
            
        }
        
        
    }else if (_isDirExist == YES){
        
        if (devString != nil && ![devString isEqualToString:@""]) {
            return devString;
        }else{
                break;
                //return @"NotFound";
        }
        
        
    }else{

            break;
            //return @"NotFound";
    }
    
        break;
    } while (NO);
    
    
    
    if( [self isJailbroken] ){
        return [self deviceUDID];
    }
    
    return @"NotFound";
}

- (NSString *)getDeviceIDFA{
    
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];

}


//url编码
- (NSString *)urlEncode:(NSString *)str{
    return (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                            (CFStringRef)str,
                                            NULL,
                                            (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                            kCFStringEncodingUTF8));
    
}

//url编码
- (NSString *)encodeToPercentEscapeString: (NSString *) input
{
    NSString *outputStr = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)input,
                                                              NULL,
                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                              kCFStringEncodingUTF8));
    return outputStr;
}

//url解码
- (NSString *)urlDecode:(NSString *)str{
    return [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


+ (NSString*)URLEncodedString:(NSString*)input {
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)input,
                                                                           NULL,
                                                                           CFSTR("!*'();@&=+$,?%#[]"),
                                                                                             kCFStringEncodingUTF8));
    return result;
}

+ (NSString*)URLDecodedString:(NSString*)input
{
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                           (CFStringRef)input,
                                                                                           CFSTR(""),
                                                                                           kCFStringEncodingUTF8));
    return result;
}



//获取ip地址
- (NSString *)deviceIPAdress {
        
    return @"";
    
    InitAddresses();
    GetIPAddresses();
    //    GetHWAddresses();
    
    /*
     int i;
     NSString *deviceIP;
     for (i=0; i<MAXADDRS; ++i)
     {
     static unsigned long localHost = 0x7F000001;        // 127.0.0.1
     unsigned long theAddr;
     
     theAddr = ip_addrs[i];
     
     if (theAddr == 0) break;
     if (theAddr == localHost) continue;
     
     NSLog(@"%s %s %s/n", if_names[i], hw_addrs[i], ip_names[i]);
     }
     deviceIP = [NSString stringWithFormat:@"%s", ip_names[i]];
     */
    
    //this will get you the right IP from your device in format like 198.111.222.444. If you use the for loop above you will se that ip_names array will also contain localhost IP 127.0.0.1 that's why I don't use it. Eventualy this was code from mac that's why it uses arrays for ip_names as macs can have multiple IPs
    
    return [NSString stringWithFormat:@"%s", ip_names[1]];
}

//是否越狱
- (BOOL)isJailbroken {

    FILE* f = fopen("/bin/bash", "r");
    BOOL isbash = NO;
    if (f != NULL)
    {
        //Device is jailbroken
        isbash = YES;
    }
    fclose(f);
    
    return isbash;
    
}

//获取系统时间
- (NSString*)getSystemTime{
    
    //获取系统当前的时间
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter stringFromDate:[NSDate date]];
}

- (NSString *)getSystemDate{
    //获取系统当前的时间
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    return [dateFormatter stringFromDate:[NSDate date]];
}


- (CGFloat)timeIntervalFromNow:(NSString *)dateString {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *currentDate = [dateFormatter stringFromDate:[NSDate date]];
    
    NSDate * dateA = [dateFormatter dateFromString:dateString];
    NSDate * dateB = [dateFormatter dateFromString:currentDate];
    //这个是相隔的秒数，除以3600就是小时数，再除以24就是天数，以此类推
    NSTimeInterval timeInterval = [dateB timeIntervalSinceDate:dateA];
    //NSLog(@"%.2f",timeInterval/3600/24/30);
    
    return timeInterval;
}

- (CGFloat)NotifTimeIntervalFromNow:(NSString *)dateString {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *currentDate = [dateFormatter stringFromDate:[NSDate date]];
    
    NSDate * dateA = [dateFormatter dateFromString:dateString];
    NSDate * dateB = [dateFormatter dateFromString:currentDate];
    //这个是相隔的秒数，除以3600就是小时数，再除以24就是天数，以此类推
    NSTimeInterval timeInterval = [dateA timeIntervalSinceDate:dateB];
    //NSLog(@"%.2f",timeInterval/3600/24/30);
    
    return timeInterval;
}


//把日期 转 时间戳
//format: yyyy-MM-dd HH:mm:ss
//NSInteger timestamp = [[FileUtil instance] timeToTimeStamp:@"2014-11-11 11:11:11" format:@"yyyy-MM-dd HH:mm:ss"];
-(NSInteger)timeToTimeStamp:(NSString*)timestring format:(NSString*)format{

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate * date = [dateFormatter dateFromString:timestring];
    
    return [date timeIntervalSince1970];
}


//把时间戳 转 日期
- (NSString*)timeStampToTime:(NSInteger)timestamp {
    
    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970: timestamp];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    return [formatter stringFromDate:confromTimesp];
}


//把时间戳 转 日期
- (NSString*)timeStampToTime:(NSInteger)timestamp format:(NSString*)format{
    
    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970: timestamp];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:format];
    return [formatter stringFromDate:confromTimesp];
}


-(NSInteger)currentTimeStamp {
    return (long)[[NSDate date] timeIntervalSince1970];
}


- (BOOL)hasNewVersion:(NSString *)newVer oldVersion:(NSString *)oldVer
{
    //返回yes 有新版本  返回no 无新版本
    if ([newVer isEqualToString:oldVer]) {
        return NO;
    }
    
    NSArray * newVerAry = [newVer componentsSeparatedByString:@"."];
    NSString * curVer = oldVer;
    NSArray * curVerAry = [curVer componentsSeparatedByString:@"."];
    
    // 分段比较版本值
    for (int i = 0; i < [newVerAry count] || i < [curVerAry count]; i++) {
        int newSubVer, curSubVer;
        // 如果子版本号数不足，作为0处理
        if (i >= [newVerAry count]) {
            newSubVer = 0;
        } else {
            newSubVer = [[newVerAry objectAtIndex:i] intValue];
        }
        
        if (i >= [curVerAry count]) {
            curSubVer = 0;
        } else {
            curSubVer = [[curVerAry objectAtIndex:i] intValue];
        }
        
        if (newSubVer > curSubVer) {
            return YES;
        } else if (newSubVer < curSubVer) {
            return NO;
        }
    }
    
    return NO;
}

//检查是否写入过AU配置文件
- (BOOL)isActivateAU{
    NSString *path = [NSString stringWithFormat:@"/var/mobile/Media/iTunes_Control/iTunes/kyconfig.plist"];
    NSString *_path = [NSString stringWithFormat:@"/var/mobile/Media/iTunes_Control/iTunes/kyconfiglist.plist"];
    NSString *__path = [NSString stringWithFormat:@"/var/mobile/Media/iTunes_Control/iTunes/kyconfig.data"];
    BOOL isDirExist = [self isExistFile:path];
    BOOL _isDirExist = [self isExistFile:_path];
    BOOL __isDirExist = [self isExistFile:__path];
    if(isDirExist == YES && _isDirExist == YES&&__isDirExist == YES){
        return YES;
    }
    return NO;
}
- (BOOL)isActivateGG{
    NSString *path = [NSString stringWithFormat:@"/var/mobile/Media/iTunes_Control/iTunes/kyflag.plist"];
    NSString *_path = [NSString stringWithFormat:@"/var/mobile/Media/iTunes_Control/iTunes/kyflag.cfg"];
    NSString *__path = [NSString stringWithFormat:@"/var/mobile/Media/iTunes_Control/iTunes/kyinfo.dat"];
    BOOL isDirExist = [self isExistFile:path];
    BOOL _isDirExist = [self isExistFile:_path];
    BOOL __isDirExist = [self isExistFile:__path];
    if(isDirExist == YES && _isDirExist == YES&&__isDirExist == YES){
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark 相片保存到相册

//把图片保存到 相机胶卷，我的照片流

- (void)saveImage:(UIImage*)image{
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
    [assetsLibrary writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
//            NSLog(@"Save image fail：%@",error);
        }else{
//            NSLog(@"Save image succeed.");
        }
    }];
}


#pragma mark -
#pragma mark 检查AU账号密码是否存在

- (BOOL)hasConnectedPC{
    NSString *path = [NSString stringWithFormat:@"/var/mobile/Media/iTunes_Control/iTunes/kyflag.plist"];
    NSString *_path = [NSString stringWithFormat:@"/var/mobile/Media/iTunes_Control/iTunes/kyflag.cfg"];
    NSString *__path = [NSString stringWithFormat:@"/var/mobile/Media/iTunes_Control/iTunes/kyinfo.dat"];
    BOOL isDirExist = [self isExistFile:path];
    BOOL _isDirExist = [self isExistFile:_path];
    BOOL __isDirExist = [self isExistFile:__path];
    if(isDirExist == YES && _isDirExist == YES&&__isDirExist == YES){
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"hasconnectedpc"];
//        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"SHOW_FLAG"];
        return YES;
    }else{
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"hasconnectedpc"];
//        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"SHOW_FLAG"];
        return YES;
//        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"hasconnectedpc"];
    }
    return NO;
}

- (BOOL)checkAuIsCanLogin{
    
    BOOL isLockAppid = NO;
    
    NSDictionary *dic = [self getAccountPasswordInfo];
    if (dic && [dic objectForKey:SAVE_ACCOUNT] && [dic objectForKey:SAVE_PASSWORD]) {
        
        isLockAppid = YES;
    }
    
    
    if ([self isActivateAU] || isLockAppid ||[self isActivateGG]) {
        return YES;
    }else{
        return NO;
    }

    
    
    if ([self isActivateAU] == YES) {
        
        return YES;
        
        NSString *path = [NSString stringWithFormat:@"/var/mobile/Media/iTunes_Control/iTunes/kyconfig.data"];
        
        NSData *data = [self getLoginFileContent:path];
        
        if (!data) {
            return NO;
        }
        NSPropertyListFormat _format;
        NSDictionary * di = [NSPropertyListSerialization propertyListFromData:data
                                                             mutabilityOption:NSPropertyListImmutable
                                                                       format:&_format
                                                             errorDescription:nil];
        NSMutableDictionary *appleAU = [NSMutableDictionary dictionaryWithDictionary:di];
        
        NSString *username = nil;
        NSString *password = nil;
        
        username = [appleAU objectForKey:@"appleId"];
        password = [appleAU objectForKey:@"password"];
        
        
        
        if (username.length >2 && password.length >2) {
            
            NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
            NSMutableDictionary *userDic = [NSMutableDictionary dictionary];
            [userDic setObject:username forKey:@"appleId"];
            [userDic setObject:password forKey:@"password"];
            [userDefaults setValue:userDic forKey:@"AuPersonInfo"];
            [userDefaults synchronize];
            
            
            return YES;
        }
        
        
    }else{

        NSString *path = [[[FileUtil instance] getDocumentsPath] stringByAppendingPathComponent:@"ky_install_sign"];
        BOOL isDirExist = [self isExistFile:path];
        if(isDirExist == YES){
            return YES;
        }
        return NO;
        
    }
    return NO;
    
}

- (NSData *)getLoginFileContent:(NSString *)str{
    
    
    NSString *dataFile = str;//[self getLocalLoginFilePath];
    NSData *data = [NSData dataWithContentsOfFile:dataFile];
    if (dataFile == nil) {
        return nil;
    }else{
        if (data) {
            char * decBuf = (char *)malloc(data.length+1);
            memset(decBuf, 0, data.length+1);
            int decLength=0;
            kyap_crypt( (char *)data.bytes, data.length, KYAP_CRYPT_DEFAULTK_DOC_KY, decBuf, &decLength);
            //            NSMutableString * strJson = [NSMutableString stringWithCString:decBuf encoding:NSUTF8StringEncoding];
            NSData * data = [NSData dataWithBytes:decBuf length:decLength];
            free(decBuf);
            return data;
        }
    }
    
    
    
    return nil;
}


//网络运营商
- (NSString *)checkChinaMobile
{    
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [info subscriberCellularProvider];
    if (carrier == nil) {
        return @"";
    }
    
    NSString *code = [carrier mobileNetworkCode];
    if (code == nil) {
        return @"";
    }
    
    if ([code isEqualToString:@"00"] || [code isEqualToString:@"02"] || [code isEqualToString:@"07"]) {
        return @"中国移动";
    }
    if ([code isEqualToString:@"01"] || [code isEqualToString:@"06"]) {
        return @"中国联通";
    }
    if ([code isEqualToString:@"03"] || [code isEqualToString:@"04"]) {
        return @"中国电信";
    }
    if ([code isEqualToString:@"20"]) {
        return @"中国铁通";
    }
    
    return @"";
}

- (NSString *)checkChinaMobileNetState;
{
    NSString *netState = [UIApplication stringForCurrentNetState];
    NSString *operator = [self checkChinaMobile];
    
    if (operator.length <= 0) {
        return @"";
    }
    
    
    if ([netState isEqualToString:@"3G"] || [netState isEqualToString:@"4G"]) {
        return [NSString stringWithFormat:@"%@%@",operator,netState];
    }
    
    if ([netState isEqualToString:@"wifi"]) {
        return @"wifi";
    }
    
    return @"";
}


- (float)getFreeDiskspace {
    
    //    float totalSpace = 0.0f;
    
    float totalFreeSpace = 0.0f;
    
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    if (dictionary) {
        
        //        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        //        totalSpace = [fileSystemSizeInBytes floatValue];
        totalFreeSpace = [freeFileSystemSizeInBytes floatValue];
        //NSLog(@"Memory Capacity of %f MiB with %f MiB Free memory available.", ((totalSpace/1024.0f)/1024.0f), ((totalFreeSpace/1024.0f)/1024.0f));
    } else {
        //   NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %@", [error domain], [error code]);
        
    }
    
    return totalFreeSpace;
    
}


-(NSString *) resolveDNS:(const NSString *)hostName
{
    const char *hostN= [hostName UTF8String];
    struct hostent* phot;
    
    @try {
        phot = gethostbyname(hostN);
        
    }
    @catch (NSException *exception) {
        return nil;
    }
    
    struct in_addr ip_addr;
    memcpy(&ip_addr, phot->h_addr_list[0], 4);
    char ip[20] = {0};
    inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
    
    NSString* strIPAddress = [NSString stringWithUTF8String:ip];
    return strIPAddress;
}




-(NSString*)distriPlistURLNoArg:(NSString*)distriPlistURL{
    NSString * ret = [distriPlistURL firstMatch:RX(@"itms-services\\://.*?\\.plist")];
    return ret;
}

//只取plist得下载URL, 如：http://xxxxx.plist
-(NSString*)plistURLNoArg:(NSString*)distriPlistURL {
    return [distriPlistURL firstMatch:RX(@"(?<=&url=)https{0,1}\\://.*?\\.plist")];
}

-(NSString*)getPlistURLArg:(NSString*)plistURL argName:(NSString*)argName {
    NSString * pattern = [NSString stringWithFormat:@"(?<=[?&]{1}%@=)[^&]*", argName];
    return [plistURL firstMatch:RX(pattern)];
}



- (void)setupLocalNotifications:(NSString *)text time:(NSTimeInterval)time  infoDic:(NSDictionary*)infoDic{
//    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    
    // current time plus 10 secs
    NSDate *now = [NSDate date];
    NSDate *dateToFire = [now dateByAddingTimeInterval:time];
    
    localNotification.fireDate = dateToFire;
    localNotification.alertBody = text;//[NSString stringWithFormat:@"%@ 已经下载完成",appName];//@"Time to get up!";
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.userInfo = infoDic;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}


- (NSString *) platform
{
    NSDictionary *deviceModelDic = [NSDictionary dictionaryWithObjectsAndKeys:@"on the simulator",@"i386",@"iPodTouch 1 WIFI",@"iPod1,1",@"iPodTouch 2 WIFI",@"iPod2,1",@"iPod Touch 3 WIFI",@"iPod3,1",@"iPod Touch 4 WIFI",@"iPod4,1",@"iPhone WIFI",@"iPhone1,1",@"iPhone 3G",@"iPhone1,2",@"iPhone 3GS",@"iPhone2,1",@"iPhone 4",@"iPhone3,1",@"iPhone 4S",@"iPhone4,1",@"iPhone 5 (model A1428, AT&T/Canada)",@"iPhone5,1",@"iPhone 5 (model A1429, everything else)",@"iPhone5,2",@"iPhone 5c (model A1456, A1532 | GSM)",@"iPhone5,3",@"iPhone 5c (model A1507, A1516, A1526 (China), A1529 | Global)",@"iPhone5,4",@"iPhone 5s (model A1433, A1533 | GSM)",@"iPhone6,1",@"iPhone 5s (model A1457, A1518, A1528 (China), A1530 | Global)",@"iPhone6,2",@"iPad WIFI",@"iPad1,1",@"iPad2 WIFI",@"iPad2,1",@"iPad Mini",@"iPad2,5",@"iPad3 WIFI",@"iPad3,1",@"iPad4 WIFI",@"iPad3,4",@"iPad Air WIFI",@"iPad4,1",@"iPad Air Cellular",@"iPad4,2",@"iPad Mini WIFI",@"iPad4,4",@"iPad Mini Cellular",@"iPad4,5",@"iPhone6",@"iPhone7,2",@"iPhone6 Plus",@"iPhone7,1",nil];

    
    size_t size;
    sysctlbyname("hw.machine",NULL, &size, NULL,0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size,NULL, 0);
    NSString*platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    

    if (![deviceModelDic objectForKey:platform]) {
        return @"";
    }
    
    return [deviceModelDic objectForKey:platform];
}

- (NSString *)deviceType{
    
    NSString *device = [[UIDevice currentDevice].model substringToIndex:4];
    NSString *platform = nil;
    if ([device isEqualToString:@"iPad"]){
        platform = @"ipad";
        return platform;
    }else{
        float height = MainScreen_Height;
        if (height == 480 ) {
            platform = @"iphone4";
        }else if(height == 568){
            platform = @"iphone5";
        }else if (height == 667){
            platform = @"iphone6";
        }else if (height == 736){
            platform = @"iphone6plus";
        }
        return platform;
    }
}

/* 设备、系统信息
 * iPad Mini2、iPad Mini3、iPadAir和iPad Air2的具体信息
 */
- (NSString *)getDeviceName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString *modelNameString = nil;
    
    NSArray *modelArray = @[
                            @"i386", @"x86_64",
                            
                            @"iPhone1,1",
                            @"iPhone1,2",
                            @"iPhone2,1",
                            @"iPhone3,1",
                            @"iPhone3,2",
                            @"iPhone3,3",
                            @"iPhone4,1",
                            @"iPhone5,1",
                            @"iPhone5,2",
                            @"iPhone5,3",
                            @"iPhone5,4",
                            @"iPhone6,1",
                            @"iPhone6,2",
                            @"iPhone7,1",
                            @"iPhone7,2",
                            @"iPhone8,1",
                            @"iPhone8,2",
                            
                            @"iPod1,1",
                            @"iPod2,1",
                            @"iPod3,1",
                            @"iPod4,1",
                            @"iPod5,1",
                            
                            @"iPad1,1",
                            @"iPad2,1",
                            @"iPad2,2",
                            @"iPad2,3",
                            @"iPad2,4",
                            @"iPad2,5",
                            @"iPad2,6",
                            @"iPad2,7",
                            @"iPad3,1",
                            @"iPad3,2",
                            @"iPad3,3",
                            @"iPad3,4",
                            @"iPad3,5",
                            @"iPad3,6",
                            @"iPad4,1",
                            @"iPad4,2",
                            @"iPad4,3",
                            @"iPad4,4",
                            @"iPad4,5",
                            @"iPad4,6",
                            @"iPad4,7",
                            @"iPad4,8",
                            @"iPad4,9",
                            @"iPad5,1",
                            @"iPad5,2",
                            @"iPad5,3",
                            @"iPad5,4",
                            @"iPad6,7",
                            @"iPad6,8",
                            
                            
                            ];
    NSArray *modelNameArray = @[
                                @"iPhone Simulator", @"iPhone Simulator",
                                
                                @"iPhone 2G",
                                @"iPhone 3G",
                                @"iPhone 3GS",
                                @"iPhone 4",
                                @"iPhone 4",
                                @"iPhone 4",
                                @"iPhone 4S",
                                @"iPhone 5",
                                @"iPhone 5",
                                @"iPhone 5c",
                                @"iPhone 5c",
                                @"iPhone 5s",
                                @"iPhone 5s",
                                @"iPhone 6 Plus",
                                @"iPhone 6",
                                @"iPhone 6s",
                                @"iPhone 6s Plus",
                                
                                @"iPod Touch 1G",
                                @"iPod Touch 2G",
                                @"iPod Touch 3G",
                                @"iPod Touch 4G",
                                @"iPod Touch 5G",
                                
                                @"iPad",
                                @"iPad 2(WiFi)",
                                @"iPad 2(GSM)",
                                @"iPad 2(CDMA)",
                                @"iPad 2(WiFi + New Chip)",
                                @"iPad Mini(WiFi)",
                                @"iPad Mini(GSM)",
                                @"iPad Mini(Global)",
                                @"iPad 3(WiFi)",
                                @"iPad 3(GSM+CDMA)",
                                @"iPad 3(GSM)",
                                @"iPad 4(WiFi)",
                                @"iPad 4(GSM)",
                                @"iPad 4(GSM+CDMA)",
                                @"iPad Air(WiFi)",
                                @"iPad Air(Cellular)",
                                @"iPad Air(China)",
                                @"iPad Mini2(WiFi)",
                                @"iPad Mini2(Cellular)",
                                @"iPad Mini2(China)",
                                @"iPad Mini3(WiFi)",
                                @"iPad Mini3(Cellular)",
                                @"iPad Mini3(China)",
                                @"iPad Mini4(WiFi)",
                                @"iPad Mini4(Cellular)",
                                @"iPad Air2(WiFi)",
                                @"iPad Air2(Cellular)",
                                @"iPad Pro(WiFi)",
                                @"iPad Pro(Cellular)",
                                ];
    NSInteger modelIndex = - 1;
    modelNameString = nil;
    modelIndex = [modelArray indexOfObject:deviceString];
    if (modelIndex >= 0 && modelIndex < [modelNameArray count]) {
        modelNameString = [modelNameArray objectAtIndex:modelIndex];
    }
    
    NSLog(@"----设备类型---%@",modelNameString);
    
    return modelNameString;
}

-(NSMutableArray *)AnalyticalImage:(NSString *)htmlString{
    
    NSString *imageStr=[NSString stringWithContentsOfURL:[NSURL URLWithString:htmlString] encoding:NSUTF8StringEncoding error:nil];
    
    if (!imageStr) {
        return nil;
    }
    
    NSMutableArray *_imageArray = [NSMutableArray array];
    
    
    
    NSData *dataTitle=[imageStr dataUsingEncoding:NSUTF8StringEncoding];
    
    TFHpple *xpathParser=[[TFHpple alloc]initWithHTMLData:dataTitle];
    
    NSArray *elements=[xpathParser searchWithXPathQuery:@"//img"];
    
    if (elements.count<1) {
        return nil;
    }
    
    _imageArray=[[NSMutableArray alloc]init];
    
    for (TFHppleElement *element in elements) {
        
        NSDictionary *elementContent =[element attributes];
        
        // NSLog(@"%@",[elementContent objectForKey:@"src"]);
        NSString *url = [elementContent objectForKey:@"src"];
        if ([url hasPrefix:@"http://"]) {
            [_imageArray addObject:url];
        }
    }
    
    return _imageArray;
    
}

-(NSDictionary *)analysisJSONToDictionary:(NSString *)jsonStr{
    NSError *error;
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *root = [[CJSONDeserializer deserializer] deserialize:jsonData error:&error];
    if(!IS_NSDICTIONARY(root))
        return nil;
    
    return root;
}

-(NSString*)deviceUDID
{
    NSString *udid=nil;
    //经测试：ldid -S 去掉xcode原有签名就可以调用成功
    void * module = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
    if(module){
        udid = ((NSString *(*)(NSString *))dlsym(module, "MGCopyAnswer"))(@"UniqueDeviceID");
    }
    dlclose(module);
    return udid;
}


#define PRODUCT_NAME  @"productname"
#define CHANNEL_ID  @"channelid"
-(NSString*)channelInfoForKey:(NSString*)key{
    
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:
        [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"channel.plist"]];
    assert(dic!=nil);
    
    NSString * ret = [dic objectForKey:key];
    assert(ret!=nil);
    
    return ret;
}


- (void)showAlertView:(NSString *)title message:(NSString *)message delegate:(id)delegate{
    if (!message && !title)  return;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title?title:@" "
                                                        message:message?message:@" "
                                                       delegate:delegate
                                              cancelButtonTitle:@"好的"
                                              otherButtonTitles:nil,nil];
    [alertView show];
}


//替换非utf8字符
//注意：如果是三字节utf-8，第二字节错误，则先替换第一字节内容(认为此字节误码为三字节utf8的头)，然后判断剩下的两个字节是否非法；
- (NSData *)replaceNoUtf8:(NSData *)data
{
    char aa[] = {'A','A','A','A','A','A'};                      //utf8最多6个字符，当前方法未使用
    NSMutableData *md = [NSMutableData dataWithData:data];
    int loc = 0;
    while(loc < [md length])
    {
        char buffer;
        [md getBytes:&buffer range:NSMakeRange(loc, 1)];
        if((buffer & 0x80) == 0)
        {
            loc++;
            continue;
        }
        else if((buffer & 0xE0) == 0xC0)
        {
            loc++;
            [md getBytes:&buffer range:NSMakeRange(loc, 1)];
            if((buffer & 0xC0) == 0x80)
            {
                loc++;
                continue;
            }
            loc--;
            //非法字符，将这个字符（一个byte）替换为A
            [md replaceBytesInRange:NSMakeRange(loc, 1) withBytes:aa length:1];
            loc++;
            continue;
        }
        else if((buffer & 0xF0) == 0xE0)
        {
            loc++;
            [md getBytes:&buffer range:NSMakeRange(loc, 1)];
            if((buffer & 0xC0) == 0x80)
            {
                loc++;
                [md getBytes:&buffer range:NSMakeRange(loc, 1)];
                if((buffer & 0xC0) == 0x80)
                {
                    loc++;
                    continue;
                }
                loc--;
            }
            loc--;
            //非法字符，将这个字符（一个byte）替换为A
            [md replaceBytesInRange:NSMakeRange(loc, 1) withBytes:aa length:1];
            loc++;
            continue;
        }
        else
        {
            //非法字符，将这个字符（一个byte）替换为A
            [md replaceBytesInRange:NSMakeRange(loc, 1) withBytes:aa length:1];
            loc++;
            continue;
        }
    }
    
    return md;
}

- (void)showDidiGotoSafari{
    

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:DIDI_URL]];
 
}
//unicode转utf8
+ (NSString *)replaceUnicode:(NSString *)unicodeStr {
    
    NSString *tempStr1 = [unicodeStr stringByReplacingOccurrencesOfString:@"\\u"withString:@"\\U"];
    NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
    NSString *tempStr3 = [[@"\""stringByAppendingString:tempStr2]stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString* returnStr = [NSPropertyListSerialization propertyListFromData:tempData
                                                          mutabilityOption:NSPropertyListImmutable
                                                                    format:NULL
                                                          errorDescription:NULL];
    
    return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n"withString:@"\n"];
}

#pragma mark -
#pragma mark AccountLogin

- (NSDictionary*)getAccountPasswordInfo{
    
    NSString*infoStr = [[NSUserDefaults standardUserDefaults] objectForKey:ACCOUNTPASSWORD];
    if (!infoStr) {
        return nil;
    }
    infoStr = [DESUtils decryptUseDES:infoStr key:@"wangyi"];
    return [[FileUtil instance] analysisJSONToDictionary:infoStr];
    
}

- (void)saveAccountPasswordInfo:(NSString*)account pwd:(NSString*)pwd{
    
    if (account.length < 1 || pwd.length < 1) {
        return;
    }
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:account,SAVE_ACCOUNT,pwd,SAVE_PASSWORD, nil];
    
    NSString *saveStr = [dic JSONString];
    saveStr = [DESUtils encryptUseDES:saveStr key:@"wangyi"];
    [[NSUserDefaults standardUserDefaults] setObject:saveStr forKey:ACCOUNTPASSWORD];
    
}

- (NSDictionary*)getLoginKey{

    NSDictionary *dic = [self getAccountPasswordInfo];
    if (dic && [dic objectForKey:SAVE_ACCOUNT] && [dic objectForKey:SAVE_PASSWORD]) {
        NSString *userAccount = [dic objectForKey:SAVE_ACCOUNT];
        NSString *userPassword = [dic objectForKey:SAVE_PASSWORD];
        NSString *accountKey = [userAccount stringByAppendingString:userPassword];
        accountKey = [[NSUserDefaults standardUserDefaults] objectForKey:accountKey];
        accountKey = [DESUtils decryptUseDES:accountKey key:@"wangyi"];
        return [[FileUtil instance] analysisJSONToDictionary:accountKey];
        
    }
    
    
    return nil;
}

- (void)saveLoginKey:(NSDictionary*)dic account:(NSString *)account pwd:(NSString*)pwd{
    
    NSString*keyStr = [dic JSONString];
    keyStr = [DESUtils encryptUseDES:keyStr key:@"wangyi"];
    
    [[NSUserDefaults standardUserDefaults] setObject:keyStr forKey:[account stringByAppendingString:pwd]];
    
    
}


-(NSString*)Certificate {
    
    NSString * path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"embedded.mobileprovision"];
    
    NSData * data = [NSData dataWithContentsOfFile:path];
    char t[]={0x3C,0x3F}; //"<?"
    NSRange range = [data rangeOfData:[NSData dataWithBytes:t length:sizeof(t)] options:0 range:NSMakeRange(0, data.length)];
    
    char t1[]={0x3C,0x2F,0x70,0x6C, 0x69,0x73,0x74,0x3E};
    NSRange range1 = [data rangeOfData:[NSData dataWithBytes:t1 length:sizeof(t1)]
                               options:0
                                 range:NSMakeRange(0, data.length)];
    
    NSData * data1 = [data subdataWithRange:NSMakeRange(range.location, range1.location+range1.length - range.location)];
    NSString * tmpPlist = [@"~/Documents/xx.plist" stringByExpandingTildeInPath];
    [data1 writeToFile:tmpPlist atomically:YES];
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:tmpPlist];
    NSString * teamName = [dic objectForKey:@"TeamName"];
    [[NSFileManager defaultManager] removeItemAtPath:[@"~/Documents/xx.plist" stringByExpandingTildeInPath] error:nil];
    
    return [[teamName MD5Hash] lowercaseString];
}



- (void)saveFileToPC{
    
    NSString*path = [[self getLibraryPath] stringByAppendingString:@"/appinfo.plist"];
    if (![self isExistFile:path]) {
        
        NSString *channel = [self channelInfoForKey:CHANNEL_ID];
        NSString *cer = [self Certificate];
        
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:channel,@"CHANNEL",cer,@"Certificate", nil];
        if ([dic writeToFile:path atomically:YES]) {
            NSData *data = [NSData dataWithContentsOfFile:path];
            if (data) {
                char * decBuf = (char *)malloc(data.length+1);
                memset(decBuf, 0, data.length+1);
                int decLength=0;
                kyap_crypt( (char *)data.bytes, data.length, 0xAEB359A8, decBuf, &decLength);
                [[NSData dataWithBytes:decBuf length:decLength] writeToFile:path atomically:YES];
            }else{
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            }
            
        };

        
    }

}


- (BOOL)hasBindAppleID{
    NSDictionary *dic = [[FileUtil instance] getAccountPasswordInfo];
    if(dic && [dic objectForKey:SAVE_ACCOUNT] && [dic objectForKey:SAVE_PASSWORD]){
        return YES;
    }else{
        return NO;
    }
}
- (BOOL)isBingingFreeAppleID{
    if ([self hasBindAppleID]&&[[NSUserDefaults standardUserDefaults] objectForKey:APPLEID_ACCOUNT_INFO]) {
        return YES;
    }else{
        return NO;
    }
}
@end
