
#import <Foundation/Foundation.h>

/*
 Used to define a specific action in Choosy
 */
@interface SBChoosyActionContext : NSObject

// required
@property (nonatomic) NSString *appTypeKey;

// optional
@property (nonatomic) NSString *actionKey;
@property (nonatomic) NSDictionary *parameters;
@property (nonatomic) NSString *appPickerText; // overrides the default text in App Picker UI

+ (instancetype)contextWithAppType:(NSString *)appTypeKey;
+ (instancetype)contextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey;
+ (instancetype)contextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey parameters:(NSDictionary *)parameters;
+ (instancetype)contextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey parameters:(NSDictionary *)parameters appPickerText:(NSString *)appPickerText;

@end
