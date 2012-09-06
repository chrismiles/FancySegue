//
//  FSGLBoxTransitionViewController.m
//  FancySegue
//
//  Created by Chris Miles on 15/07/12.
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

#import "FSGLBoxTransitionViewController.h"
#import <QuartzCore/QuartzCore.h>


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


#define BoxBack -0.1f
#define BoxFront 0.1f

static GLfloat gBoxVertexData[288] =
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,	    texcoordX, texcoordY,
    0.5f, -0.5f, BoxBack,        1.0f, 0.0f, 0.0f,	0.25f, 1.0f, // face 4
    0.5f, 0.5f, BoxBack,         1.0f, 0.0f, 0.0f,	0.25f, 1.0f,
    0.5f, -0.5f, BoxFront,       1.0f, 0.0f, 0.0f,	0.25f, 1.0f,
    0.5f, -0.5f, BoxFront,       1.0f, 0.0f, 0.0f,	0.25f, 1.0f,
    0.5f, 0.5f, BoxBack,         1.0f, 0.0f, 0.0f,	0.25f, 1.0f,
    0.5f, 0.5f, BoxFront,        1.0f, 0.0f, 0.0f,	0.25f, 1.0f,
    
    0.5f, 0.5f, BoxBack,       0.0f, 1.0f, 0.0f,	0.0f, 0.0f, // face top
    -0.5f, 0.5f, BoxBack,      0.0f, 1.0f, 0.0f,	1.0f, 0.0f,
    0.5f, 0.5f, BoxFront,      0.0f, 1.0f, 0.0f,	0.0f, 1.0f,
    0.5f, 0.5f, BoxBack,       0.0f, 1.0f, 0.0f,	0.0f, 1.0f,
    -0.5f, 0.5f, BoxBack,      0.0f, 1.0f, 0.0f,	1.0f, 0.0f,
    -0.5f, 0.5f, BoxBack,      0.0f, 1.0f, 0.0f,	1.0f, 1.0f,
    
    -0.5f, 0.5f, BoxBack,        -1.0f, 0.0f, 0.0f,	0.25f, 1.0f, // face 2
    -0.5f, -0.5f, BoxBack,       -1.0f, 0.0f, 0.0f,	0.25f, 1.0f,
    -0.5f, 0.5f, BoxFront,       -1.0f, 0.0f, 0.0f,	0.25f, 1.0f,
    -0.5f, 0.5f, BoxFront,       -1.0f, 0.0f, 0.0f,	0.25f, 1.0f,
    -0.5f, -0.5f, BoxBack,       -1.0f, 0.0f, 0.0f,	0.25f, 1.0f,
    -0.5f, -0.5f, BoxFront,      -1.0f, 0.0f, 0.0f,	0.25f, 1.0f,
    
    -0.5f, -0.5f, BoxBack,     0.0f, -1.0f, 0.0f,	0.0f, 0.0f, // face bottom
    0.5f, -0.5f, BoxBack,      0.0f, -1.0f, 0.0f,	1.0f, 0.0f,
    -0.5f, -0.5f, BoxFront,    0.0f, -1.0f, 0.0f,	0.0f, 1.0f,
    -0.5f, -0.5f, BoxFront,    0.0f, -1.0f, 0.0f,	0.0f, 1.0f,
    0.5f, -0.5f, BoxBack,      0.0f, -1.0f, 0.0f,	1.0f, 0.0f,
    0.5f, -0.5f, BoxFront,     0.0f, -1.0f, 0.0f,	1.0f, 1.0f,
    
    0.5f, 0.5f, BoxFront,      0.0f, 0.0f, 1.0f,	0.5f, 1.0f, // face 1 (front)
    -0.5f, 0.5f, BoxFront,     0.0f, 0.0f, 1.0f,	0.0f, 1.0f,
    0.5f, -0.5f, BoxFront,     0.0f, 0.0f, 1.0f,	0.5f, 0.0f,
    0.5f, -0.5f, BoxFront,     0.0f, 0.0f, 1.0f,	0.5f, 0.0f,
    -0.5f, 0.5f, BoxFront,     0.0f, 0.0f, 1.0f,	0.0f, 1.0f,
    -0.5f, -0.5f, BoxFront,    0.0f, 0.0f, 1.0f,	0.0f, 0.0f,
    
    0.5f, -0.5f, BoxBack,        0.0f, 0.0f, -1.0f,	0.5f, 0.0f, // face 3 (back)
    -0.5f, -0.5f, BoxBack,       0.0f, 0.0f, -1.0f,	1.0f, 0.0f,
    0.5f, 0.5f, BoxBack,         0.0f, 0.0f, -1.0f,	0.5f, 1.0f,
    0.5f, 0.5f, BoxBack,         0.0f, 0.0f, -1.0f,	0.5f, 1.0f,
    -0.5f, -0.5f, BoxBack,       0.0f, 0.0f, -1.0f,	1.0f, 0.0f,
    -0.5f, 0.5f, BoxBack,        0.0f, 0.0f, -1.0f,	1.0f, 1.0f,
};


static float QuadraticEaseInOut(float p);


@interface FSGLBoxTransitionViewController () {
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    
    BOOL _finished;
    float _timing;
    float _transition;
    
    GLKMatrix4 _transitionViewModelViewMatrix;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    GLKTextureInfo *_textureInfo;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;
@end

@implementation FSGLBoxTransitionViewController

@synthesize context = _context;
@synthesize destinationView = _destinationView;
@synthesize effect = _effect;
@synthesize fancyStoryboardSegueDelegate;
@synthesize sourceView = _sourceView;


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

- (UIImage *)textureAtlasContainingSourceAndDestinationViews
{
    //CGFloat scaleFactor = [[UIScreen mainScreen] scale]; // Uncomment to support Retina (loading is a little slower)
    CGFloat scaleFactor = 1.0f;
    
    CGSize sourceSize = self.sourceView.bounds.size;
    CGRect textureBounds = CGRectMake(0.0f, 0.0f, sourceSize.width*2.0f, sourceSize.height);
    
    UIGraphicsBeginImageContextWithOptions(textureBounds.size, _sourceView.opaque, scaleFactor);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [_sourceView.layer renderInContext:context];
    
    CGContextTranslateCTM(context, roundf(textureBounds.size.width/2.0f), 0.0f);
    BOOL masks = _destinationView.layer.masksToBounds;
    _destinationView.layer.masksToBounds = YES; // prevent overdraw
    [_destinationView.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _destinationView.layer.masksToBounds = masks; // restore
    
    return image;
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    UIImage *textureAtlas = [self textureAtlasContainingSourceAndDestinationViews];
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
    _textureInfo = [GLKTextureLoader textureWithCGImage:textureAtlas.CGImage options:options error:nil];

    
    // Cube
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.ambientColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    self.effect.light0.position = GLKVector4Make(0.0f, 0.0f, 1.0f, 0.0f);
    self.effect.texture2d0.enabled = YES;
    self.effect.texture2d0.name = _textureInfo.name;
    
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gBoxVertexData), gBoxVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(12));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(24));
    
    glBindVertexArrayOES(0);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
}


#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    _timing += self.timeSinceLastUpdate * 0.5f;
    if (_timing >= 1.0f) {
	_timing = 1.0f;
	_finished = YES;
    }
    
    _transition = QuadraticEaseInOut(_timing);
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    float fovy = GLKMathDegreesToRadians(45.0f);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(fovy, aspect, 0.1f, 100.0f);
    float zdist = 0.5f / tanf(fovy/2.0f);

    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -zdist - 0.1f);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, aspect, 1.0f, 1.0f); // scale to match view aspect ratio
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0.0f, 0.0f, -sinf(_transition * M_PI)*1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _transition * M_PI, 0.0f, 1.0f, 0.0f);
    //modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _transition * M_PI, 0.0f, 0.0f, 1.0f);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;

    
    glClearColor(0.45f, 0.45f, 0.45f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    // Render cube with GLKit
    glEnable(GL_DEPTH_TEST);
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object with GLKit
    [self.effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    if (_finished) {
	dispatch_async(dispatch_get_main_queue(), ^{
	    [fancyStoryboardSegueDelegate fancyStoryboardSegueTransitionFinished:self];
	});
    }
}

@end


/* Easing function borrowed from AHEasing https://github.com/warrenm/AHEasing
 */
static float QuadraticEaseInOut(float p)
{
    if(p < 0.5)
    {
	return 2 * p * p;
    }
    else
    {
	return (-2 * p * p) + (4 * p) - 1;
    }
}
