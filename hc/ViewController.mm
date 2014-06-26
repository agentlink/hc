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

@interface ViewController () 
@property(strong, nonatomic) EAGLContext *context;
@property(strong, nonatomic) GLKBaseEffect *edgeEffect;
@property(strong, nonatomic) GLKBaseEffect *triangleEffect;

- (void)updateGLOnMove;

- (void)tearDownGL;

@end


static int actionPointCount;

@interface ActionPoint : NSObject

@property(nonatomic) int handleId;
@property(nonatomic) CGPoint start;
@property(nonatomic) CGPoint current;

- (instancetype)initWithStart:(CGPoint)aStart;

+ (instancetype)pointWithStart:(CGPoint)aStart;

@end

@implementation ActionPoint

+ (instancetype)pointWithStart:(CGPoint)aStart {
    return [[self alloc] initWithStart:aStart];
}

- (instancetype)initWithStart:(CGPoint)aStart {
    self = [super init];
    if (self) {
        _handleId = actionPointCount++;
        _start = aStart;
    }

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"ID = %d, ", _handleId];
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

    GLuint _edgeVertexArray;
    GLuint _edgeVertexBuffer;
    size_t _edgeCount;
    GLfloat *_edgeVertexData;
    size_t _edgeVertexDataSize;

    GLuint _triVertexArray;
    GLuint _triVertexBuffer;
    size_t _triCount;
    GLfloat *_triVertexData;
    size_t _triVertexDataSize;

    GLKTextureInfo *_textureInfo;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    size_t ptr = [self touchId:touch];
    CGPoint location = [touch locationInView:self.view];

    ActionPoint *ap = [ActionPoint pointWithStart:location];
    _touches2Points[@(ptr)] = ap;
    LOG_TOUCHES(@"NEW => %@", ap);
    CGFloat y = location.y;
    _shape->addHandle(ap.handleId, location.x, [self yToGL:y]);
    [self updateGLOnMove];
}

- (CGFloat)yToGL:(CGFloat)y {
    return _shape->height - y;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    size_t ptr = [self touchId:touch];
    ActionPoint *ap = _touches2Points[@(ptr)];

    CGPoint location = [touch locationInView:self.view];
    ap.current = location;
    LOG_TOUCHES(@"MOVED => %@", ap);
    [self updateHandle:ap location:location];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    size_t ptr = [self touchId:touch];
    ActionPoint *ap = _touches2Points[@(ptr)];

    CGPoint location = [touch locationInView:self.view];
    ap.current = location;
    LOG_TOUCHES(@"ENDED => %@", ap);

    [self updateHandle:ap location:location];

    [_touches2Points removeObjectForKey:@(ptr)];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    size_t ptr = [self touchId:touch];
    ActionPoint *ap = _touches2Points[@(ptr)];

    CGPoint location = [touch locationInView:self.view];
    ap.current = location;
    LOG_TOUCHES(@"CANCELLED => %@", ap);

    [self updateHandle:ap location:location];
    
    [_touches2Points removeObjectForKey:@(ptr)];
}

- (void)updateHandle:(ActionPoint *)ap location:(CGPoint)location {
    _shape->updateHandle(ap.handleId, location.x, [self yToGL:location.y]);
    [self updateGLOnMove];
}

- (size_t)touchId:(UITouch *)touch {
    size_t ptr = (size_t) (__bridge CFTypeRef) touch;
    return ptr;
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
    [self updateGLOnShape];
}


- (void)setupGL {
    [EAGLContext setCurrentContext:self.context];

    self.triangleEffect = [[GLKBaseEffect alloc] init];

//    self.edgeEffect = [[GLKBaseEffect alloc] init];
//    self.edgeEffect.light0.enabled = GL_TRUE;
//    self.edgeEffect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);

    self.edgeEffect = [[GLKBaseEffect alloc] init];
    self.edgeEffect.lightingType = GLKLightingTypePerPixel;

    // Turn on the first light
    self.edgeEffect.light0.enabled = GL_TRUE;
    self.edgeEffect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    self.edgeEffect.light0.position = GLKVector4Make(-5.f, -5.f, 10.f, 1.0f);
    self.edgeEffect.light0.specularColor = GLKVector4Make(1.0f, 0.0f, 0.0f, 1.0f);

    // Turn on the second light
    self.edgeEffect.light1.enabled = GL_TRUE;
    self.edgeEffect.light1.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    self.edgeEffect.light1.position = GLKVector4Make(15.f, 15.f, 10.f, 1.0f);
    self.edgeEffect.light1.specularColor = GLKVector4Make(1.0f, 0.0f, 0.0f, 1.0f);

    // Set material
    self.edgeEffect.material.diffuseColor = GLKVector4Make(0.f, 0.5f, 1.0f, 1.0f);
    self.edgeEffect.material.ambientColor = GLKVector4Make(0.0f, 0.5f, 0.0f, 1.0f);
    self.edgeEffect.material.specularColor = GLKVector4Make(1.0f, 0.0f, 0.0f, 1.0f);
    self.edgeEffect.material.shininess = 20.0f;
    self.edgeEffect.material.emissiveColor = GLKVector4Make(0.2f, 0.f, 0.2f, 1.0f);

    glEnable(GL_DEPTH_TEST);
    glGenVertexArraysOES(1, &_edgeVertexArray);
    glBindVertexArrayOES(_edgeVertexArray);
    glGenBuffers(1, &_edgeVertexBuffer);
    glBindVertexArrayOES(0);

    glGenVertexArraysOES(1, &_triVertexArray);
    glBindVertexArrayOES(_triVertexArray);
    glGenBuffers(1, &_triVertexBuffer);

    glBindVertexArrayOES(0);
}

- (void)updateGLOnShape {
    glActiveTexture(GL_TEXTURE0);
    CGImageRef cgImage = [_texture CGImage];
    NSError *theError = nil;
    _textureInfo = [GLKTextureLoader textureWithCGImage:cgImage options:nil error:&theError];

    GLKEffectPropertyTexture *tex = [[GLKEffectPropertyTexture alloc] init];
    tex.enabled = YES;
    tex.envMode = GLKTextureEnvModeDecal;
    tex.name = _textureInfo.name;

    self.triangleEffect.texture2d0.name = tex.name;

    [self updateGLOnMove];
}

- (void)updateGLOnMove {
    [self setupEdges];
    [self setupTriangles];
}

- (void)setupEdges {
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
        dataSize = (size_t) (_edgeCount * 2) * 3 * sizeof(GLfloat);

        if (_edgeVertexDataSize < dataSize) {
            _edgeVertexData = (GLfloat *) realloc(_edgeVertexData, dataSize);
            _edgeVertexDataSize = dataSize;
        }
        data = _edgeVertexData;

        for (size_t i = 0; i < _edgeCount; i++) {
            int e1 = tr.edgelist[2 * i];
            _edgeVertexData[i * 6] = (GLfloat) tr.pointlist[e1 * 2];
            _edgeVertexData[i * 6 + 1] = (GLfloat) (_shape->height - tr.pointlist[e1 * 2 + 1]);
            _edgeVertexData[i * 6 + 2] = 1.01;

            int e2 = tr.edgelist[2 * i + 1];
            _edgeVertexData[i * 6 + 3] = (GLfloat) tr.pointlist[e2 * 2];
            _edgeVertexData[i * 6 + 4] = (GLfloat) (_shape->height - tr.pointlist[e2 * 2 + 1]);
            _edgeVertexData[i * 6 + 5] = 1.01;
        }
    }

    glBindVertexArrayOES(_edgeVertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, _edgeVertexBuffer);

    glBufferData(GL_ARRAY_BUFFER, dataSize, data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));

    glBindVertexArrayOES(0);
}

- (void)setupTriangles {
    GLfloat *data;
    size_t dataSize;
    if (_shape == NULL) {
        data = gCubeVertexData;
        dataSize = sizeof(gCubeVertexData);
        _triCount = 1;
    }
    else {
        triangulateio tr = _shape->triangulation;

        _triCount = (size_t) tr.numberoftriangles;
        dataSize = (_triCount * 5) * 3 * sizeof(CGFloat);

        if (_triVertexDataSize < dataSize) {
            _triVertexData = (GLfloat *) realloc(_triVertexData, dataSize);
            _triVertexDataSize = dataSize;
        }
        data = _triVertexData;

        int height = _shape->height;
        int width = _shape->width;
        double *newPoints = _shape->pointsNew;
        
        for (size_t i = 0; i < _triCount; i++) {
            size_t base = i * 15;

            int t1 = tr.trianglelist[3 * i];
            _triVertexData[base + 0] = (GLfloat) newPoints[t1 * 2];
            _triVertexData[base + 1] = (GLfloat) (height - newPoints[t1 * 2 + 1]);
            _triVertexData[base + 2] = 1;
            _triVertexData[base + 3] = (GLfloat) tr.pointlist[t1 * 2] / width;
            _triVertexData[base + 4] = 1 - ((GLfloat) (height - tr.pointlist[t1 * 2 + 1])) / height;

            int t2 = tr.trianglelist[3 * i + 1];
            _triVertexData[base + 5] = (GLfloat) newPoints[t2 * 2];
            _triVertexData[base + 6] = (GLfloat) (height - newPoints[t2 * 2 + 1]);
            _triVertexData[base + 7] = 1;
            _triVertexData[base + 8] = (GLfloat) tr.pointlist[t2 * 2] / width;
            _triVertexData[base + 9] = 1 - ((GLfloat) (height - tr.pointlist[t2 * 2 + 1])) / height;

            int t3 = tr.trianglelist[3 * i + 2];
            _triVertexData[base + 10] = (GLfloat) newPoints[t3 * 2];
            _triVertexData[base + 11] = (GLfloat) (height - newPoints[t3 * 2 + 1]);
            _triVertexData[base + 12] = 1;
            _triVertexData[base + 13] = (GLfloat) tr.pointlist[t3 * 2] / width;
            _triVertexData[base + 14] = 1 - ((GLfloat) (height - tr.pointlist[t3 * 2 + 1])) / height;

        }
    }

    glBindVertexArrayOES(_triVertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, _triVertexBuffer);

    glBufferData(GL_ARRAY_BUFFER, dataSize, data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 5*sizeof(GLfloat), BUFFER_OFFSET(0));

    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 5*sizeof(GLfloat), BUFFER_OFFSET(3*sizeof(GLfloat)));


    glBindVertexArrayOES(0);
}

- (void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];

    glDeleteBuffers(1, &_edgeVertexBuffer);
    glDeleteVertexArraysOES(1, &_edgeVertexArray);

    glDeleteBuffers(1, &_triVertexBuffer);
    glDeleteVertexArraysOES(1, &_triVertexArray);

    self.edgeEffect = nil;
    self.triangleEffect = nil;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update {
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;

    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, width, 0, height, 0.1, 20);

    self.triangleEffect.transform.projectionMatrix = projectionMatrix;
    self.edgeEffect.transform.projectionMatrix = projectionMatrix;

    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.0f);

    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);

    self.triangleEffect.transform.modelviewMatrix = modelViewMatrix;
    self.edgeEffect.transform.modelviewMatrix = modelViewMatrix;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // triangles
    glBindVertexArrayOES(_triVertexArray);

    [self.triangleEffect prepareToDraw];

    glDrawArrays(GL_TRIANGLES, 0, 3 * _triCount);

    // edges
    glBindVertexArrayOES(_edgeVertexArray);

    glLineWidth(2);
    [self.edgeEffect prepareToDraw];

    glDrawArrays(GL_LINES, 0, 2 * _edgeCount);

}

#pragma mark -  OpenGL ES 2 shader compilation

@end
