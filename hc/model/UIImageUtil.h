#import <Foundation/Foundation.h>


@interface UIImageUtil : NSObject
+ (UIImage *)removeBackground:(UIImage *)image borders:(UIImage *)borders;

+ (NSMutableArray *)loadImagePaths;

+ (NSString *)applicationDocumentsDirectory;
@end