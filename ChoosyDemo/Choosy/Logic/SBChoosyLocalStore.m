
#import "SBChoosyLocalStore.h"
#import "SBChoosySerialization.h"

static NSString *LAST_DETECTED_APPS_KEY = @"DetectedApps";
static NSString *DEFAULT_APPS_KEY = @"DefaultApps";

@implementation SBChoosyLocalStore

#pragma mark - Public

#pragma mark Default App Selection

+ (NSString *)defaultAppForAppType:(NSString *)appType
{
    NSDictionary *defaultApps = [(NSMutableDictionary *)[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_APPS_KEY] copy];
    
    return defaultApps[appType];
}

+ (void)setDefaultApp:(NSString *)appKey forAppType:(NSString *)appType
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *defaultApps = [(NSDictionary *)[defaults objectForKey:DEFAULT_APPS_KEY] mutableCopy];
    
    if (!defaultApps) defaultApps = [NSMutableDictionary new];
    
    if (appKey) {
        defaultApps[appType] = appKey;
    } else {
        if ([defaultApps.allKeys containsObject:appType]) [defaultApps removeObjectForKey:appType];
    }
    
	[defaults setObject:defaultApps forKey:DEFAULT_APPS_KEY];
	[defaults synchronize];
}

#pragma mark Last Detected Apps

+ (NSArray *)lastDetectedAppsForAppType:(NSString *)appTypeKey
{
	NSDictionary *detectedApps = (NSDictionary *)[[NSUserDefaults standardUserDefaults] objectForKey:LAST_DETECTED_APPS_KEY];
    
    if (detectedApps) {
        return detectedApps[appTypeKey];
    }
    
    return nil;
}

+ (void)setLastDetectedApps:(NSArray *)appKeys forAppType:(NSString *)appTypeKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *detectedApps = (NSDictionary *)[defaults objectForKey:LAST_DETECTED_APPS_KEY];
    
    NSMutableDictionary *newDetectedApps = detectedApps ? [detectedApps mutableCopy] : [NSMutableDictionary new];
    newDetectedApps[appTypeKey] = appKeys;
    
	[defaults setObject:[newDetectedApps copy] forKey:LAST_DETECTED_APPS_KEY];
	[defaults synchronize];
}

#pragma mark App Type Caching

+ (NSArray *)cachedAppTypes
{
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self pathForCacheDirectory] error:nil];
    NSPredicate *jsonExtFilter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.json'"];
    NSArray *jsonFilePaths = [directoryContents filteredArrayUsingPredicate:jsonExtFilter];
    
    NSMutableArray *appTypes = [NSMutableArray new];
    for (NSString *jsonFilePath in jsonFilePaths) {
        [appTypes addObjectsFromArray:[self cachedAppTypesAtPath:jsonFilePath]];
    }
    
    return [appTypes count] > 0 ? appTypes : nil;
}

+ (SBChoosyAppType *)cachedAppType:(NSString *)appTypeKey;
{
    NSString *filePath = [self filePathForAppTypeKey:appTypeKey];
    NSArray *appTypes = [self cachedAppTypesAtPath:filePath];
    
    return [SBChoosyAppType filterAppTypesArray:appTypes byKey:appTypeKey];
}

+ (void)cacheAppTypes:(NSArray *)appTypes
{
    if (!appTypes) return;
    
    // TODO: make sure this runs on a background thread
    
    // convert app types to JSON
    for (SBChoosyAppType *appType in appTypes) {
        NSData *appTypeData = [SBChoosySerialization serializeAppTypesToNSData:@[appType]];
        NSString *filePath = [self filePathForAppTypeKey:appType.key];
        
//        NSError *error;
        [appTypeData writeToFile:filePath atomically:YES];
    }
}

+ (SBChoosyAppType *)getBuiltInAppType:(NSString *)appTypeKey
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"systemAppTypes" ofType:@".json"];
    
    NSArray *appTypes = [SBChoosyLocalStore cachedAppTypesAtPath:filePath];
    
    return [SBChoosyAppType filterAppTypesArray:appTypes byKey:appTypeKey];
}

#pragma mark - Private
#pragma mark App Type Caching

+ (NSArray *)cachedAppTypesAtPath:(NSString *)filePath
{
    if (!filePath || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) return nil;
    
    NSData *jsonAppTypeData = [[NSFileManager defaultManager] contentsAtPath:filePath];
    
    NSArray *appTypes = [SBChoosySerialization deserializeAppTypesFromNSData:jsonAppTypeData];
    
    return appTypes;
}

+ (NSString *)filePathForAppTypeKey:(NSString *)appTypeKey
{
    return [[self pathForCacheDirectory] stringByAppendingPathComponent:[appTypeKey stringByAppendingString:@".json"]];
}

+ (NSString *)pathForCacheDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Choosy"];
    BOOL isDir = NO;
    NSError *error;
    if (! [[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    return cachePath;
}

@end
