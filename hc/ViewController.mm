#import "ViewController.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

GLfloat gCubeVertexData[18] =
        {
                // Data layout for each line below is:
                // positionX, positionY, positionZ,     normalX, normalY, normalZ,

                137.866302f, 0.919785f, 1,
                125.569344f, 207.957230f, 1,

//                0.f, 100.0f, 1.0f,
//                100.0f, 100.0f, 1.0f,
//                30.f, 0.f, 1.0f,
//                0.f, 0.f, 1.0f,
//                100.0f, 100.0f, 1.0f,
//                100.0f, 0.f, 1.0f,
        };

@interface ViewController () {
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}
@property(strong, nonatomic) EAGLContext *context;
@property(strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;

- (void)tearDownGL;

@end


static int actionPointCount;

@interface ActionPoint : NSObject

@property(nonatomic) CGPoint start;
@property(nonatomic) CGPoint current;

- (instancetype)initWithStart:(CGPoint)aStart;

+ (instancetype)pointWithStart:(CGPoint)aStart;

@end

@implementation ActionPoint {
    int _id;
}

+ (instancetype)pointWithStart:(CGPoint)aStart {
    return [[self alloc] initWithStart:aStart];
}

- (instancetype)initWithStart:(CGPoint)aStart {
    self = [super init];
    if (self) {
        _id = actionPointCount++;
        _start = aStart;
    }

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"ID = %d, ", _id];
    [description appendFormat:@"start = %@, ", NSStringFromCGPoint(_start)];
    [description appendFormat:@"current = %@", NSStringFromCGPoint(_current)];
    [description appendString:@">"];
    return description;
}

@end

#define LOG_TOUCHES(fmt, ...)
//#define LOG_TOUCHES(fmt, ...) NSLog(fmt, ##__VA_ARGS__)

@implementation ViewController {
    NSMutableDictionary *_touches2Points;
    size_t _edgeCount;
    GLfloat *_edgeVertexData;
    size_t _edgeVertexDataSize;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    int ptr = (int) (__bridge CFTypeRef) touch;
    CGPoint location = [touch locationInView:self.view];

    ActionPoint *ap = [ActionPoint pointWithStart:location];
    _touches2Points[@(ptr)] = ap;
    LOG_TOUCHES(@"NEW => %@", ap);
}

- (void)prepareGL {
    [EAGLContext setCurrentContext:self.context];

    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);

    glEnable(GL_DEPTH_TEST);
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);

    glGenBuffers(1, &_vertexBuffer);
    glBindVertexArrayOES(0);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    int ptr = (int) (__bridge CFTypeRef) touch;
    ActionPoint *ap = _touches2Points[@(ptr)];

    CGPoint location = [touch locationInView:self.view];
    ap.current = location;
    LOG_TOUCHES(@"MOVED => %@", ap);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    int ptr = (int) (__bridge CFTypeRef) touch;
    ActionPoint *ap = _touches2Points[@(ptr)];

    CGPoint location = [touch locationInView:self.view];
    ap.current = location;
    LOG_TOUCHES(@"ENDED => %@", ap);

    [_touches2Points removeObjectForKey:@(ptr)];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    int ptr = (int) (__bridge CFTypeRef) touch;
    ActionPoint *ap = _touches2Points[@(ptr)];

    CGPoint location = [touch locationInView:self.view];
    ap.current = location;
    LOG_TOUCHES(@"CANCELLED => %@", ap);

    [_touches2Points removeObjectForKey:@(ptr)];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    _touches2Points = [NSMutableDictionary new];

    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }

    GLKView *view = (GLKView *) self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    CAEAGLLayer *eaglLayer = (CAEAGLLayer *) self.view.layer;
    eaglLayer.opaque = NO;
    view.backgroundColor = [UIColor clearColor];

    [self prepareGL];

    [self setupGL];
}

- (void)dealloc {
    [self tearDownGL];

    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;

        [self tearDownGL];

        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (void)setShape:(Shape *)shape {
    _shape = shape;
    [self setupGL];
}


- (void)setupGL {
    GLfloat *data;
    size_t dataSize;
    if (_shape == NULL) {
    data = gCubeVertexData;
    dataSize = sizeof(gCubeVertexData);
    _edgeCount = 1;
    }
    else {
        triangulateio tr = _shape->triangulation;

        _edgeCount = (size_t) tr.numberofedges;
        dataSize = (size_t) (_edgeCount * 2) * 3 * sizeof(CGFloat);

        if (_edgeVertexDataSize < dataSize) {
            _edgeVertexData = (CGFloat*)realloc(_edgeVertexData, dataSize);
            _edgeVertexDataSize = dataSize;
        }
        data = _edgeVertexData;

        for (size_t i = 0; i < _edgeCount; i++) {
            int e1 = tr.edgelist[2*i];
            _edgeVertexData[i*6] = (GLfloat) tr.pointlist[e1*2];
            _edgeVertexData[i*6 + 1] = (GLfloat)(_shape->height - tr.pointlist[e1*2 + 1]);
            _edgeVertexData[i*6 + 2] = 1;

            int e2 = tr.edgelist[2*i+1];
            _edgeVertexData[i*6 + 3] = (GLfloat) tr.pointlist[e2*2];
            _edgeVertexData[i*6 + 4] = (GLfloat) (_shape->height - tr.pointlist[e2*2 + 1]);
            _edgeVertexData[i*6 + 5] = 1;
        }
    }

    glBindVertexArrayOES(_vertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);

    glBufferData(GL_ARRAY_BUFFER, dataSize, data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));

    glBindVertexArrayOES(0);
}

- (void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];

    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);

    self.effect = nil;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update {
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;

    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, width, 0, height, 0.1, 20);

    self.effect.transform.projectionMatrix = projectionMatrix;

    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.0f);

    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);

    self.effect.transform.modelviewMatrix = modelViewMatrix;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glBindVertexArrayOES(_vertexArray);

    // Render the object with GLKit
    [self.effect prepareToDraw];

    glDrawArrays(GL_LINES, 0, 2 * _edgeCount);
}

#pragma mark -  OpenGL ES 2 shader compilation

@end
