#import <Foundation/Foundation.h>


@interface UIImageUtil : NSObject
+ (UIImage *)removeBackground:(UIImage *)image borders:(UIImage *)borders;

+ (NSString *)applicationDocumentsDirectory;

+ (NSString *)formatDate:(NSDate *)start;
@end