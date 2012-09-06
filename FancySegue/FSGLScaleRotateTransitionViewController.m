//
//  FSGLTransitionViewController.m
//  FancySegue
//
//  Created by Chris Miles on 12/07/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//
//  MIT Licensed (http://opensource.org/licenses/mit-license.php):
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "FSGLScaleRotateTransitionViewController.h"
#import <QuartzCore/QuartzCore.h>

#define DRAW_CUBE 0


#define BUFFER_OFFSET(i) ((char *)NULL + (i))

#ifdef DEBUG
#define ALog(...) [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__]
#define ASSERT_GL_OK() do {\
    GLenum glError = glGetError();\
    if (glError != GL_NO_ERROR) {\
	ALog(@"glError: %d", glError);\
    }} while (0)
#else
#define ASSERT_GL_OK() do { } while (0)
#endif

#if DRAW_CUBE
static GLfloat gCubeVertexData[288] =
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,	    texcoordX, texcoordY,
    0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,	0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,	1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,	0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,	0.0f, 1.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,	1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          1.0f, 0.0f, 0.0f,	1.0f, 1.0f,
    
    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,	0.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,	1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,	0.0f, 1.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,	0.0f, 1.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,	1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,	1.0f, 1.0f,
    
    -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,	0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,	1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,	0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,	0.0f, 1.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,	1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,	1.0f, 1.0f,
    
    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,	0.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,	1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,	0.0f, 1.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,	0.0f, 1.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,	1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,	1.0f, 1.0f,
    
    0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,	0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,	1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,	0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,	0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,	1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,	1.0f, 1.0f,
    
    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,	0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,	1.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,	0.0f, 1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,	0.0f, 1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,	1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f,	1.0f, 1.0f,
};
#endif


#define rWidth 320.0f
#define rHeight 480.0f

GLfloat gRect1Data[16] =
{
    // vx,     vy,     ts,   tu
    rWidth,   0.0f,  0.5f, 0.0f,
    rWidth, rHeight, 0.5f, 1.0f,
    0.0f,   0.0f,  0.0f, 0.0f,
    0.0f, rHeight, 0.0f, 1.0f,
};

GLfloat gRect2Data[16] =
{
    // vx,     vy,     ts,   tu
    rWidth,   0.0f,  1.0f, 0.0f,
    rWidth, rHeight, 1.0f, 1.0f,
    0.0f,   0.0f,  0.5f, 0.0f,
    0.0f, rHeight, 0.5f, 1.0f,
};


@interface FSGLScaleRotateTransitionViewController () {
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    
    BOOL _finished;
    float _rotation;
    float _transitionRotation;
    float _transitionScale;
    
    GLKMatrix4 _transitionViewModelViewMatrix;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    GLKBaseEffect *_texturedRectEffect;
    GLKTextureInfo *_textureInfo;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;
@end

@implementation FSGLScaleRotateTransitionViewController

@synthesize context = _context;
@synthesize effect = _effect;
@synthesize sourceView, destinationView;
@synthesize fancyStoryboardSegueDelegate;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.preferredFramesPerSecond = 60;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    [self setupGL];
    
    _rotation = M_PI_2;
    _transitionRotation = 0.0f;
    _transitionScale = 1.0f;
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

/*
- (UIImage *)imageFromView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, view.contentScaleFactor);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
*/

- (UIImage *)textureAtlasContainingSourceAndDestinationViews
{
    //CGFloat scaleFactor = [[UIScreen mainScreen] scale]; // Uncomment to support Retina (loading is a little slower)
    CGFloat scaleFactor = 1.0f;
    
    CGSize sourceSize = self.sourceView.bounds.size;
    CGRect textureBounds = CGRectMake(0.0f, 0.0f, sourceSize.width*2.0f, sourceSize.height);
    
    UIGraphicsBeginImageContextWithOptions(textureBounds.size, sourceView.opaque, scaleFactor);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [sourceView.layer renderInContext:context];
    
    CGContextTranslateCTM(context, roundf(textureBounds.size.width/2.0f), 0.0f);
    BOOL masks = destinationView.layer.masksToBounds;
    destinationView.layer.masksToBounds = YES; // prevent overdraw
    [destinationView.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    destinationView.layer.masksToBounds = masks; // restore
    
    return image;
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    UIImage *textureAtlas = [self textureAtlasContainingSourceAndDestinationViews];
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
    _textureInfo = [GLKTextureLoader textureWithCGImage:textureAtlas.CGImage options:options error:nil];

    CGFloat drawableWidth = CGRectGetWidth(self.view.bounds) * self.view.contentScaleFactor;
    CGFloat drawableHeight = CGRectGetHeight(self.view.bounds) * self.view.contentScaleFactor;
    gRect1Data[0] = gRect2Data[0] = drawableWidth;
    gRect1Data[4] = gRect2Data[4] = drawableWidth;
    gRect1Data[5] = gRect2Data[5] = drawableHeight;
    gRect1Data[13] = gRect2Data[13] = drawableHeight;
    
    _texturedRectEffect = [[GLKBaseEffect alloc] init];
    _texturedRectEffect.texture2d0.enabled = YES;
    _texturedRectEffect.texture2d0.name = _textureInfo.name;
    
    _texturedRectEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho(0.0f, drawableWidth, 0.0f, drawableHeight, -1.0f, 1.0f);
    _texturedRectEffect.transform.modelviewMatrix = GLKMatrix4Identity;
    
    _transitionViewModelViewMatrix = GLKMatrix4Identity;
    
    
#if DRAW_CUBE
    // Cube
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    self.effect.texture2d0.enabled = YES;
    self.effect.texture2d0.name = _textureInfo.name;
    
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(12));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(24));
    
    glBindVertexArrayOES(0);
#endif
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
#if DRAW_CUBE
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
#endif
}


#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    float drawableWidth = (float)[(GLKView *)self.view drawableWidth];
    float drawableHeight = (float)[(GLKView *)self.view drawableHeight];
    
    float modelScale = _transitionScale * _transitionScale; // Ease-in
    if (fmaxf(drawableWidth, drawableHeight) * modelScale < 1.0f) {
	_finished = YES;
    }
    
    _transitionViewModelViewMatrix = GLKMatrix4MakeTranslation(drawableWidth/2.0f, drawableHeight/2.0f, 0.0f);
    _transitionViewModelViewMatrix = GLKMatrix4Scale(_transitionViewModelViewMatrix, modelScale, modelScale, 1.0f);
    _transitionViewModelViewMatrix = GLKMatrix4Rotate(_transitionViewModelViewMatrix, _transitionRotation, 0.0f, 0.0f, 1.0f);
    _transitionViewModelViewMatrix = GLKMatrix4Translate(_transitionViewModelViewMatrix, -drawableWidth/2.0f, -drawableHeight/2.0f, 0.0f);
    
    _transitionRotation += self.timeSinceLastUpdate * 2.0f;
    _transitionScale *= 1.0f - self.timeSinceLastUpdate;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    // Compute the model view matrix for the object rendered with ES2
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    _rotation += self.timeSinceLastUpdate * 0.5f;

    
    
    
    float drawableWidth = (float)[(GLKView *)self.view drawableWidth];
    float drawableHeight = (float)[(GLKView *)self.view drawableHeight];
    gRect1Data[0] = gRect2Data[0] = drawableWidth;
    gRect1Data[4] = gRect2Data[4] = drawableWidth;
    gRect1Data[5] = gRect2Data[5] = drawableHeight;
    gRect1Data[13] = gRect2Data[13] = drawableHeight;

    _texturedRectEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho(0.0f, drawableWidth, 0.0f, drawableHeight, -1.0f, 1.0f);

    
    
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glDisable(GL_DEPTH_TEST);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArrayOES(0);
    
    
    _texturedRectEffect.transform.modelviewMatrix = GLKMatrix4Identity;
    [_texturedRectEffect prepareToDraw];
    [self drawTexturedRectData:gRect2Data];
    
    _texturedRectEffect.transform.modelviewMatrix = _transitionViewModelViewMatrix;
    [_texturedRectEffect prepareToDraw];
    [self drawTexturedRectData:gRect1Data];
    
    
#if DRAW_CUBE
    // Render cube with GLKit
    glEnable(GL_DEPTH_TEST);
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object with GLKit
    [self.effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
#endif
    
    
    if (_finished) {
	dispatch_async(dispatch_get_main_queue(), ^{
	    [fancyStoryboardSegueDelegate fancyStoryboardSegueTransitionFinished:self];
	});
    }
}

- (void)drawTexturedRectData:(CGFloat *)rectData
{
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 4*sizeof(GL_FLOAT), &rectData[0]);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 4*sizeof(GL_FLOAT), &rectData[2]);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
}

@end
