#import "Record.h"


@implementation Record {
    NSMutableArray *events;
}

- (id)init {
    self = [super init];
    if (self) {
        events = [NSMutableArray new];
    }

    return self;
}

@end
