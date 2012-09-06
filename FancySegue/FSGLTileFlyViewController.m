//
//  FSGLTileFlyViewController.m
//  FancySegue
//
//  Created by Chris Miles on 18/07/12.
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

#import "FSGLTileFlyViewController.h"
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

static inline int randomInt(int low, int high);


/* destVertexData contains vertices for rectangle where the
 * destination view will be rendered (behind the tiles).
 */
#define kDestVertexDataLength 48
static GLfloat destVertexData[kDestVertexDataLength] =
{
    // Destination
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,	    texcoordX, texcoordY,
    0.5f, 0.5f, -0.001f,      0.0f, 0.0f, 1.0f,	1.0f, 1.0f,
    -0.5f, 0.5f, -0.001f,     0.0f, 0.0f, 1.0f,	0.5f, 1.0f,
    0.5f, -0.5f, -0.001f,     0.0f, 0.0f, 1.0f,	1.0f, 0.0f,
    0.5f, -0.5f, -0.001f,     0.0f, 0.0f, 1.0f,	1.0f, 0.0f,
    -0.5f, 0.5f, -0.001f,     0.0f, 0.0f, 1.0f,	0.5f, 1.0f,
    -0.5f, -0.5f, -0.001f,    0.0f, 0.0f, 1.0f,	0.5f, 0.0f,
};

/* tileData contains vertices for rectangle of each tile.
 */
#define kTileDataLength 48
static GLfloat tileData[kTileDataLength] =
{
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,	    texcoordX, texcoordY,
    0.0f, 0.0f, 0.0f,      0.0f, 0.0f, 1.0f,	0.25f, 0.5f,
    -0.5f, 0.0f, 0.0f,     0.0f, 0.0f, 1.0f,	0.0f, 0.5f,
    0.0f, -0.5f, 0.0f,     0.0f, 0.0f, 1.0f,	0.25f, 0.0f,
    0.0f, -0.5f, 0.0f,     0.0f, 0.0f, 1.0f,	0.25f, 0.0f,
    -0.5f, 0.0f, 0.0f,     0.0f, 0.0f, 1.0f,	0.0f, 0.5f,
    -0.5f, -0.5f, 0.0f,    0.0f, 0.0f, 1.0f,	0.0f, 0.0f,
};


@interface FSGLTileFlyViewController () {
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    
    BOOL _finished;
    float _timing;
    float _transition;
    
    GLKMatrix4 _transitionViewModelViewMatrix;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    GLKBaseEffect *_texturedRectEffect;
    GLKTextureInfo *_textureInfo;
    
    GLfloat *_vertexData;
    size_t _vertexDataLength;
    
    int _numTilesX;
    int _numTilesY;
    int *_tileOrder;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation FSGLTileFlyViewController

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
    CGRect textureBounds = CGRectMake(0.0f, 0.0f, sourceSize.width * 2.0f, sourceSize.height);
    
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
    
    float tileSize = 32.0f;
    _numTilesX = (int)ceilf(CGRectGetWidth(self.view.bounds) / tileSize);
    _numTilesY = (int)ceilf(CGRectGetHeight(self.view.bounds) / tileSize);
    
    CGSize tileNormalisedSize = CGSizeMake(tileSize/CGRectGetWidth(self.view.bounds), tileSize/CGRectGetHeight(self.view.bounds));
    NSLog(@"view bounds: %@ numTilesX: %d numTilesY: %d tileNormalisedSize: %@", NSStringFromCGRect(self.view.bounds), _numTilesX, _numTilesY, NSStringFromCGSize(tileNormalisedSize));
    
    _vertexDataLength = kDestVertexDataLength + kTileDataLength * _numTilesX * _numTilesY;
    _vertexData = calloc(_vertexDataLength, sizeof(GLfloat));
    memcpy(_vertexData, destVertexData, kDestVertexDataLength*sizeof(GLfloat)); // static destination vertex data
    //memcpy(&_vertexData[48], &sourceVertexData[48], (_vertexDataLength-48)*sizeof(GLfloat));
    
    int dataIndex = kDestVertexDataLength;
    
    // Copy source vertex data as tiles
    for (int tileY=0; tileY < _numTilesY; tileY++) {
	float lowerVx = tileY * tileNormalisedSize.height - 0.5f;
	float upperVy = (tileY+1) * tileNormalisedSize.height - 0.5f;
	for (int tileX=0; tileX < _numTilesX; tileX++) {
	    float lhsVx = tileX * tileNormalisedSize.width - 0.5f;
	    float rhsVx = (tileX+1) * tileNormalisedSize.width - 0.5f;
	    
	    // position vertices
	    tileData[8*0] = tileData[8*2] = tileData[8*3] = rhsVx;
	    tileData[8*1] = tileData[8*4] = tileData[8*5] = lhsVx;
	    tileData[8*0+1] = tileData[8*1+1] = tileData[8*4+1] = upperVy;
	    tileData[8*2+1] = tileData[8*3+1] = tileData[8*5+1] = lowerVx;
	    
	    // tex coords
	    tileData[8*0+6] = tileData[8*2+6] = tileData[8*3+6] = (tileX+1) * tileNormalisedSize.width / 2.0f;
	    tileData[8*1+6] = tileData[8*4+6] = tileData[8*5+6] = tileX * tileNormalisedSize.width / 2.0f;
	    tileData[8*0+7] = tileData[8*1+7] = tileData[8*4+7] = (tileY+1) * tileNormalisedSize.height;
	    tileData[8*2+7] = tileData[8*3+7] = tileData[8*5+7] = tileY * tileNormalisedSize.height;
	    
	    memcpy(&_vertexData[dataIndex], tileData, kTileDataLength*sizeof(GLfloat));
	    dataIndex += kDestVertexDataLength;
	}
    }
    
    int numTiles =_numTilesX * _numTilesY;
    _tileOrder = calloc(numTiles, sizeof(int));
    for (int i=0; i<numTiles; i++) {
	_tileOrder[i] = i;
    }
    // Randomise order of tiles; super simplistic randomisation
    for (int i=0; i<numTiles; i++) {
	int j = randomInt(0, numTiles-1);
	int swap = _tileOrder[j];
	_tileOrder[j] = _tileOrder[i];
	_tileOrder[i] = swap;
    }
    
    
    UIImage *textureAtlas = [self textureAtlasContainingSourceAndDestinationViews];
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
    _textureInfo = [GLKTextureLoader textureWithCGImage:textureAtlas.CGImage options:options error:nil];
    
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.texture2d0.enabled = YES;
    self.effect.texture2d0.name = _textureInfo.name;
    
    ASSERT_GL_OK();
    
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, _vertexDataLength*sizeof(GLfloat), _vertexData, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(12));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(24));
    
    ASSERT_GL_OK();
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
    free(_vertexData); _vertexData = NULL;
    free(_tileOrder); _tileOrder = NULL;
}


#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    _timing += self.timeSinceLastUpdate * 0.4f;
    if (_timing >= 1.0f) {
	_timing = 1.0f;
	_finished = YES;
    }
    
    _transition = _timing * _timing; // ease-in timing
    
    // Move tiles towards eye
    
    int numTiles = _numTilesX * _numTilesY;
    for (int t=0; t<numTiles; t++) {
	int tileNum = _tileOrder[t];
	float flySpeed = 2.0f + 10.0f * t / numTiles;
	
	for (int i=0; i<6; i++) {
	    int dataIndex = kDestVertexDataLength + kTileDataLength * tileNum + 8*i+2;
	    _vertexData[dataIndex] = _transition * flySpeed;
	}
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    float fovy = GLKMathDegreesToRadians(25.0f);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(fovy, aspect, 0.1f, 100.0f);
    float zdist = 0.5f / tanf(fovy/2.0f);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -zdist);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, aspect, 1.0f, 1.0f); // scale to match view aspect ratio
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    glBufferData(GL_ARRAY_BUFFER, _vertexDataLength*sizeof(GLfloat), _vertexData, GL_DYNAMIC_DRAW);

    // Render the object with GLKit
    [self.effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, _vertexDataLength/8);
    
    if (_finished) {
	dispatch_async(dispatch_get_main_queue(), ^{
	    [fancyStoryboardSegueDelegate fancyStoryboardSegueTransitionFinished:self];
	});
    }
}

@end



/* Returns a random integer number between low and high inclusive */
static inline int randomInt(int low, int high)
{
    return (arc4random() % (high-low+1)) + low;
}
