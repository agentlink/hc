#import <Foundation/Foundation.h>

@class ShapeHandle;


typedef enum {
    ADD,
    MOVE,
    REMOVE
} AnimationEventType;

@interface AnimationEvent : NSObject
@property(nonatomic) NSTimeInterval time;
@property(nonatomic) AnimationEventType type;
@property(nonatomic) int handleId;
@property(nonatomic) CGPoint position;

- (instancetype)initWithTime:(NSTimeInterval)time type:(AnimationEventType)type handleId:(int)handleId position:(CGPoint)position;

+ (instancetype)eventWithTime:(NSTimeInterval)_time type:(AnimationEventType)_type handleId:(int)_handleId position:(CGPoint)_position;

@end