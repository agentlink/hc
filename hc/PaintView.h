#import <Foundation/Foundation.h>


@interface PaintView : UIView
@property(nonatomic) int strokeWidth;

- (void)startPath:(CGPoint)point;

- (void)continuePath:(CGPoint)point;

- (void)endPath:(CGPoint)point;

- (void)clearPaths;

- (void)drawRect:(CGRect)rect context:(CGContextRef)context translation:(CGPoint)translation fillColor:(UIColor *)fillColor strokeColor:(UIColor *)strokeColor;
@end