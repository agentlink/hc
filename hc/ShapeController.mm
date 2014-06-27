#import "ShapeController.h"
#import "AnimationController.h"
#import "ImageUtil.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface ShapeController ()
@property(strong, nonatomic) EAGLContext *context;
@property(strong, nonatomic) GLKBaseEffect *edgeEffect;
@property(strong, nonatomic) GLKBaseEffect *triangleEffect;

- (void)tearDownGL;

@end


@implementation ShapeController {
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

    GLuint _handleVertexArray;
    GLuint _handleVertexBuffer;
    size_t _handleCount;
    GLfloat *_handleVertexData;
    size_t _handleVertexDataSize;

    GLKTextureInfo *_textureInfo;
    Shape *_shape;
    UIImage *_texture;
}

- (void)viewDidLoad {
    [super viewDidLoad];

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

- (void)setShapeImage:(UIImage *)image {
    Shape *oldShape = _shape;
    _shape = image == nil ? NULL : [ImageUtil loadImage:image];
    _texture = image;
    [self updateGLOnNewShape];
    if (oldShape != NULL) {
        delete oldShape;
    }
}


- (void)setupGL {
    [EAGLContext setCurrentContext:self.context];

    self.triangleEffect = [[GLKBaseEffect alloc] init];

    self.edgeEffect = [[GLKBaseEffect alloc] init];
    self.edgeEffect.light0.enabled = GL_TRUE;
    self.edgeEffect.light0.diffuseColor = GLKVector4Make(1.0f, 0, 0, 1.0f);

    glEnable(GL_DEPTH_TEST);
    glGenVertexArraysOES(1, &_edgeVertexArray);
    glBindVertexArrayOES(_edgeVertexArray);
    glGenBuffers(1, &_edgeVertexBuffer);
    glBindVertexArrayOES(0);

    glGenVertexArraysOES(1, &_triVertexArray);
    glBindVertexArrayOES(_triVertexArray);
    glGenBuffers(1, &_triVertexBuffer);

    glGenVertexArraysOES(1, &_handleVertexArray);
    glBindVertexArrayOES(_handleVertexArray);
    glGenBuffers(1, &_handleVertexBuffer);

    glBindVertexArrayOES(0);
}

- (void)updateGLOnNewShape {
    glActiveTexture(GL_TEXTURE0);
    CGImageRef cgImage = [_texture CGImage];
    NSError *theError = nil;
    _textureInfo = [GLKTextureLoader textureWithCGImage:cgImage options:nil error:&theError];

    GLKEffectPropertyTexture *tex = [[GLKEffectPropertyTexture alloc] init];
    tex.enabled = YES;
    tex.envMode = GLKTextureEnvModeDecal;
    tex.name = _textureInfo.name;

    self.triangleEffect.texture2d0.name = tex.name;

    [self updateOnShapeTransform];
}

- (void)updateOnShapeTransform {
    [self setupTriangles];
    [self setupEdges];
    [self setupHandles];
}

- (void)setupEdges {
    if (_shape == NULL) {
        return;
    }

    triangulateio tr = _shape->triangulation;

    _edgeCount = (size_t) tr.numberofedges;
    size_t dataSize = (size_t) (_edgeCount * 2) * 3 * sizeof(GLfloat);

    double *newPoints = _shape->pointsNew;
    if (_edgeVertexDataSize < dataSize) {
        _edgeVertexData = (GLfloat *) realloc(_edgeVertexData, dataSize);
        _edgeVertexDataSize = dataSize;
    }
    GLfloat *data = _edgeVertexData;

    for (size_t i = 0; i < _edgeCount; i++) {
        int e1 = tr.edgelist[2 * i];
        _edgeVertexData[i * 6] = (GLfloat) newPoints[e1 * 2];
        _edgeVertexData[i * 6 + 1] = (GLfloat) (newPoints[e1 * 2 + 1]);
        _edgeVertexData[i * 6 + 2] = 1.01;

        int e2 = tr.edgelist[2 * i + 1];
        _edgeVertexData[i * 6 + 3] = (GLfloat) newPoints[e2 * 2];
        _edgeVertexData[i * 6 + 4] = (GLfloat) (newPoints[e2 * 2 + 1]);
        _edgeVertexData[i * 6 + 5] = 1.01;
    }

    glBindVertexArrayOES(_edgeVertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, _edgeVertexBuffer);

    glBufferData(GL_ARRAY_BUFFER, dataSize, data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));

    glBindVertexArrayOES(0);
}

- (void)setupTriangles {
    if (_shape == NULL) {
        return;
    }

    triangulateio tr = _shape->triangulation;

    _triCount = (size_t) tr.numberoftriangles;
    size_t dataSize = (_triCount * 5) * 3 * sizeof(GLfloat);

    if (_triVertexDataSize < dataSize) {
        _triVertexData = (GLfloat *) realloc(_triVertexData, dataSize);
        _triVertexDataSize = dataSize;
    }
    GLfloat *data = _triVertexData;

    int height = _shape->height;
    int width = _shape->width;
    double *newPoints = _shape->pointsNew;

    for (size_t i = 0; i < _triCount; i++) {
        size_t base = i * 15;

        int t1 = tr.trianglelist[3 * i];
        _triVertexData[base + 0] = (GLfloat) newPoints[t1 * 2];
        _triVertexData[base + 1] = (GLfloat) (newPoints[t1 * 2 + 1]);
        GLfloat z = 1 + ((GLfloat)tr.pointlist[t1 * 2]/width + (GLfloat)tr.pointlist[t1 * 2 + 1]/height)/10;
        _triVertexData[base + 2] = z;
        _triVertexData[base + 3] = (GLfloat) tr.pointlist[t1 * 2] / width;
        _triVertexData[base + 4] = 1 - ((GLfloat) (height - tr.pointlist[t1 * 2 + 1])) / height;

        int t2 = tr.trianglelist[3 * i + 1];
        _triVertexData[base + 5] = (GLfloat) newPoints[t2 * 2];
        _triVertexData[base + 6] = (GLfloat) (newPoints[t2 * 2 + 1]);
        _triVertexData[base + 7] = z;
        _triVertexData[base + 8] = (GLfloat) tr.pointlist[t2 * 2] / width;
        _triVertexData[base + 9] = 1 - ((GLfloat) (height - tr.pointlist[t2 * 2 + 1])) / height;

        int t3 = tr.trianglelist[3 * i + 2];
        _triVertexData[base + 10] = (GLfloat) newPoints[t3 * 2];
        _triVertexData[base + 11] = (GLfloat) (newPoints[t3 * 2 + 1]);
        _triVertexData[base + 12] = z;
        _triVertexData[base + 13] = (GLfloat) tr.pointlist[t3 * 2] / width;
        _triVertexData[base + 14] = 1 - ((GLfloat) (height - tr.pointlist[t3 * 2 + 1])) / height;

    }

    glBindVertexArrayOES(_triVertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, _triVertexBuffer);

    glBufferData(GL_ARRAY_BUFFER, dataSize, data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), BUFFER_OFFSET(0));

    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), BUFFER_OFFSET(3 * sizeof(GLfloat)));


    glBindVertexArrayOES(0);
}

- (void)setupHandles {
    if (_shape == NULL) {
        return;
    }

    map<int, point2d<double>> handles = _shape->handles;
    _handleCount = handles.size();
    size_t dataSize = (_handleCount * 6) * 3 * sizeof(GLfloat);

    if (_handleVertexDataSize < dataSize) {
        _handleVertexData = (GLfloat *) realloc(_handleVertexData, dataSize);
        _handleVertexDataSize = dataSize;
    }

    GLfloat *data = _handleVertexData;

    size_t i = 0;
    for (auto kv : handles) {
        point2d<double> point = kv.second;
        size_t base = i * 18;

        GLfloat x = (GLfloat) point.x;
        GLfloat y = (GLfloat) point.y;

        _handleVertexData[base + 0] = x;
        _handleVertexData[base + 1] = y;
        _handleVertexData[base + 2] = 1.2;

        _handleVertexData[base + 3] = 0;
        _handleVertexData[base + 4] = 0;
        _handleVertexData[base + 5] = 1;

        _handleVertexData[base + 6] = x + 10;
        _handleVertexData[base + 7] = y + 10;
        _handleVertexData[base + 8] = 1.2;

        _handleVertexData[base + 9] = 0;
        _handleVertexData[base + 10] = 0;
        _handleVertexData[base + 11] = 1;

        _handleVertexData[base + 12] = x + 10;
        _handleVertexData[base + 13] = y;
        _handleVertexData[base + 14] = 1.2;

        _handleVertexData[base + 15] = 0;
        _handleVertexData[base + 16] = 0;
        _handleVertexData[base + 17] = 1;
        i++;
    }

    glBindVertexArrayOES(_handleVertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, _handleVertexBuffer);

    glBufferData(GL_ARRAY_BUFFER, dataSize, data, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), BUFFER_OFFSET(0));

    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), BUFFER_OFFSET(3 * sizeof(GLfloat)));

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
    [_animationDataSource updateAnimation:self];

    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;

    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, width, 0, height, 0.1, 20);

    self.triangleEffect.transform.projectionMatrix = projectionMatrix;
    self.edgeEffect.transform.projectionMatrix = projectionMatrix;

    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.0f);

    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, self.view.frame.size.height, -1.5f);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 1, -1, 1);
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

    glDrawArrays(GL_LINES, 0, 2 * _edgeCount);

    // handles
    glBindVertexArrayOES(_handleVertexArray);

    [self.edgeEffect prepareToDraw];

    glDrawArrays(GL_TRIANGLES, 0, 3 * _handleCount);

}

- (void)releaseHandles:(vector<int>)releasedHandles update:(BOOL)update {
    _shape->releaseHandles(releasedHandles);
    if (update) {
        [self updateOnShapeTransform];
    }
}

- (void)addHandle:(int)handleId atLocation:(CGPoint)location update:(BOOL)update {
    _shape->addHandle(handleId, location.x, location.y);
    if (update) {
        [self updateOnShapeTransform];
    }
}

- (void)handlesMoved:(map<int, point2d<double>>)changed update:(BOOL)update {
    _shape->updateHandles(changed);
    if (update) {
        [self updateOnShapeTransform];
    }
}

- (BOOL)hasShape {
    return _shape != NULL;
}

@end
