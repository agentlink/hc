@interface ShapeHandle : NSObject

@property(nonatomic) int handleId;
@property(nonatomic) CGPoint start;
@property(nonatomic) CGPoint current;

@property(nonatomic, strong) NSDate *lastTouchedAt;

- (instancetype)initWithStart:(CGPoint)aStart;

+ (instancetype)pointWithStart:(CGPoint)aStart;

@end
