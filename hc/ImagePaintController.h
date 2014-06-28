#import <Foundation/Foundation.h>
#import "PaintView.h"

@interface ImagePaintController : UIViewController
@property(nonatomic, strong) IBOutlet UIImageView *imageView;
@property(nonatomic, strong) IBOutlet PaintView *paintView;
@property(nonatomic, strong) UIImage *originalImage;

- (void)clearBorders;

- (UIImage *)maskWithFillColor:(UIColor *)fillColor strokeColor:(UIColor *)strokeColor;

@end
