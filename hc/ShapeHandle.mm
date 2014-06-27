#include "ShapeHandle.h"

static int actionPointCount;

@implementation ShapeHandle

+ (instancetype)pointWithStart:(CGPoint)aStart {
    return [[self alloc] initWithStart:aStart];
}

- (instancetype)initWithStart:(CGPoint)aStart {
    self = [super init];
    if (self) {
        _handleId = actionPointCount++;
        _start = aStart;
        _current = aStart;
        _lastTouchedAt = [NSDate date];
    }

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"ID = %d, ", _handleId];
    [description appendFormat:@"start = %@, ", NSStringFromCGPoint(_start)];
    [description appendFormat:@"current = %@", NSStringFromCGPoint(_current)];
    [description appendFormat:@"lastTouched = %@", _lastTouchedAt];
    [description appendString:@">"];
    return description;
}

@end
