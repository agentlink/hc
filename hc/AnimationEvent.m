#import "AnimationEvent.h"


@implementation AnimationEvent {

}
- (instancetype)initWithTime:(NSTimeInterval)time type:(AnimationEventType)type handleId:(int)handleId position:(CGPoint)position {
    self = [super init];
    if (self) {
        self.time = time;
        self.type = type;
        self.handleId = handleId;
        self.position = position;
    }

    return self;
}

+ (instancetype)eventWithTime:(NSTimeInterval)_time type:(AnimationEventType)_type handleId:(int)_handleId position:(CGPoint)_position {
    return [[self alloc] initWithTime:_time type:_type handleId:_handleId position:_position];
}

@end