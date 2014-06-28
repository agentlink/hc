#import "PaintView.h"


@implementation PaintView {
    NSMutableArray *paths;
}


- (void)startPath:(CGPoint)point {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, point.x, point.y);
    [paths addObject:[NSValue valueWithPointer:path]];
}

- (void)continuePath:(CGPoint)point {
    CGMutablePathRef path = [self getPath:paths.lastObject];
    CGPathAddLineToPoint(path, NULL, point.x, point.y);
    [self setNeedsDisplay];
}

- (void)endPath:(CGPoint)point {
    CGMutablePathRef path = [self getPath:paths.lastObject];
    CGPathAddLineToPoint(path, NULL, point.x, point.y);
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    [self drawRect:rect context:ctx translation:CGPointZero fillColor:[UIColor clearColor] strokeColor:[[UIColor redColor] colorWithAlphaComponent:0.5]];
}

- (void)drawRect:(CGRect)rect context:(CGContextRef)ctx translation:(CGPoint)translation fillColor:(UIColor *)fillColor strokeColor:(UIColor *)strokeColor {
    CGContextSetFillColorWithColor(ctx, fillColor.CGColor);
    CGContextFillRect(ctx, rect);

    CGContextSetShouldAntialias(ctx, NO);
    CGContextSetAllowsAntialiasing(ctx, NO);
    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);

    CGContextTranslateCTM(ctx, translation.x, translation.y);
    CGContextSetLineWidth(ctx, _strokeWidth);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetStrokeColorWithColor(ctx, strokeColor.CGColor);

    for (NSValue *value in paths) {
        CGMutablePathRef path = [self getPath:value];
        CGContextAddPath(ctx, path);
        CGContextDrawPath(ctx, kCGPathStroke);
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];

    paths = [NSMutableArray new];
    _strokeWidth = 50;
}

- (void)clearPaths {
    for (NSValue *value in paths) {
        CGMutablePathRef path = [self getPath:value];
        CGPathRelease(path);
    }
    [paths removeAllObjects];
}

- (CGMutablePathRef)getPath:(NSValue *)value {
    CGMutablePathRef path = [value pointerValue];
    return path;
}

- (void)dealloc {
    [self clearPaths];
}

@end