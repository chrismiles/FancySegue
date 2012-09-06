//
//  FSClothFlipTransitionViewController.m
//  FancySegue
//
//  Created by Chris Miles on 29/08/12.
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

#import "FSGLClothFlipTransitionViewController.h"
#import "CMTraerPhysics.h"
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

typedef struct _vertexStruct
{
    GLfloat position[3];
    GLfloat normals[3];
    GLfloat texCoords[2];
} VertexStruct;

#define kBytesPerVertex (sizeof(VertexStruct))


/* tileData contains vertices for rectangle of each tile.
 */
#define kTileVertexLength 6
static VertexStruct tileData[kTileVertexLength] =
{
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,	    texcoordX, texcoordY,
    {0.0f, 0.0f, 0.0f,      0.0f, 0.0f, 1.0f,	0.25f, 0.5f},
    {-0.5f, 0.0f, 0.0f,     0.0f, 0.0f, 1.0f,	0.0f, 0.5f},
    {0.0f, -0.5f, 0.0f,     0.0f, 0.0f, 1.0f,	0.25f, 0.0f},
    {0.0f, -0.5f, 0.0f,     0.0f, 0.0f, 1.0f,	0.25f, 0.0f},
    {-0.5f, 0.0f, 0.0f,     0.0f, 0.0f, 1.0f,	0.0f, 0.5f},
    {-0.5f, -0.5f, 0.0f,    0.0f, 0.0f, 1.0f,	0.0f, 0.0f},
};


static float SineEaseInOut(float p);


@interface FSGLClothFlipTransitionViewController () {
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    
    BOOL _finished;
    float _timing;
    float _transition;
    BOOL _finalisePositions;
    BOOL _finalisePositionsFinished;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    GLKBaseEffect *_texturedRectEffect;
    GLKTextureInfo *_textureInfo;
    
    VertexStruct *_vertexData;
    size_t _vertexDataLength;
    
    CMTPVector3D *_finalPositions;
    
    float _worldWidth;
    float _worldHeight;
    
    CGSize _tileSize;
    int _numTilesX;
    int _numTilesY;
    int _numParticlesX;
    int _numParticlesY;
    
    // Physics
    CMTPParticle *_attractor;
    NSMutableArray *_particles;
    CMTPParticleSystem *_s;
    float _gravityScale;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@end

@implementation FSGLClothFlipTransitionViewController

@synthesize fancyStoryboardSegueDelegate;

- (void)dealloc
{
    free(_finalPositions); _finalPositions = NULL;
    [self tearDownGL];
}

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupScene];
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


- (void)setupScene
{
    _tileSize.width = CGRectGetWidth(self.view.bounds) / 12.0f;
    _tileSize.height = CGRectGetHeight(self.view.bounds) / 12.0f;
    _numTilesX = (int)ceilf(CGRectGetWidth(self.view.bounds) / _tileSize.width);
    _numTilesY = (int)ceilf(CGRectGetHeight(self.view.bounds) / _tileSize.height);
    NSLog(@"Tile size: %@ # Tiles: %d (X=%d Y=%d)", NSStringFromCGSize(_tileSize), _numTilesX*_numTilesY, _numTilesX, _numTilesY);
    
    [self setupPhysics];
    [self setupGL];
}


#pragma mark - Physics

- (void)setupPhysics
{
    float springConstant = 1.1f;
    float springDamping = 0.6f;
    float particleMass = 0.7f;
    float worldDrag = 0.03f;
    _gravityScale = 0.1f;
    _worldWidth = 300.0f;
    
    /* AttractionGrid - creates a square grid */
    _particles = [[NSMutableArray alloc] init];
    CMTPVector3D gravityVector = CMTPVector3DMake(0.0f, _gravityScale, 0.0f);
    _s = [[CMTPParticleSystem alloc] initWithGravityVector:gravityVector drag:worldDrag];
    [_s setIntegrator:CMTPParticleSystemIntegratorRungeKutta];
    
    _worldHeight = _worldWidth * CGRectGetHeight(self.view.bounds) / CGRectGetWidth(self.view.bounds);
    
    _numParticlesX = _numTilesX + 1;
    _numParticlesY = _numTilesY + 1;
    
    // Size of each tile in Physics space
    float spx = _worldWidth / _numTilesX;
    float spy = _worldHeight / _numTilesY;

    _finalPositions = calloc(_numParticlesX*_numParticlesY, sizeof(CMTPVector3D));

    // create grid of particles
    for (int y=0; y < _numParticlesY; y++) {
        for (int x=0; x < _numParticlesX; x++) {
	    CMTPVector3D position = CMTPVector3DMake(x*spx, y*spy, 0);
            CMTPParticle *p = [_s makeParticleWithMass:particleMass position:position];
            [_particles addObject:p];
	    
	    // Final position
	    position.x = _worldWidth - position.x;
	    _finalPositions[y*_numParticlesX + x] = position;
        }
    }
    
    // create springs
    for (int y=0; y < _numParticlesY; y++) { //horizontal
        for (int x=0; x < _numParticlesX-1; x++) {
            CMTPParticle *particleA = [_particles objectAtIndex:(y*_numParticlesX+x)];
            CMTPParticle *particleB = [_particles objectAtIndex:(y*_numParticlesX+x+1)];
            [_s makeSpringBetweenParticleA:particleA particleB:particleB springConstant:springConstant damping:springDamping restLength:spx];
        }
    }
    for (int y=0; y < _numParticlesY-1; y++) { //vertical
        for (int x=0; x < _numParticlesX; x++) {
            CMTPParticle *particleA = [_particles objectAtIndex:(y*_numParticlesX+x)];
            CMTPParticle *particleB = [_particles objectAtIndex:((y+1)*_numParticlesX+x)];
            [_s makeSpringBetweenParticleA:particleA particleB:particleB springConstant:springConstant damping:springDamping restLength:spy];
        }
    }
    
    NSArray *fixedParticles = [_particles subarrayWithRange:NSMakeRange(0, _numParticlesX)];
    for (CMTPParticle *particle in fixedParticles) {
	[particle makeFixed];
    }

    NSLog(@"Created %d particles", [_particles count]);
}


#pragma mark - GL Setup

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
    
    CGSize tileNormalisedSize = CGSizeMake(_tileSize.width/CGRectGetWidth(self.view.bounds), _tileSize.height/CGRectGetHeight(self.view.bounds));
    NSLog(@"view bounds: %@ numTilesX: %d numTilesY: %d tileNormalisedSize: %@", NSStringFromCGRect(self.view.bounds), _numTilesX, _numTilesY, NSStringFromCGSize(tileNormalisedSize));
    
    _vertexDataLength = 2 * _numTilesX * _numTilesY * kTileVertexLength * kBytesPerVertex;
    _vertexData = calloc(2 * _numTilesX * _numTilesY, kTileVertexLength * kBytesPerVertex);
    
    int vertexIndex = 0;
        
    // Copy source vertex data as tiles: Front side
    for (int tileY=0; tileY < _numTilesY; tileY++) {
	float lowerVy = 1.0f - tileY * tileNormalisedSize.height - 0.5f;
	float upperVy = 1.0f - (tileY+1) * tileNormalisedSize.height - 0.5f;
	for (int tileX=0; tileX < _numTilesX; tileX++) {
	    float lhsVx = tileX * tileNormalisedSize.width - 0.5f;
	    float rhsVx = (tileX+1) * tileNormalisedSize.width - 0.5f;
	    
	    // vertex positions
	    tileData[0].position[0] = tileData[2].position[0] = tileData[3].position[0] = rhsVx;
	    tileData[1].position[0] = tileData[4].position[0] = tileData[5].position[0] = lhsVx;
	    tileData[0].position[1] = tileData[1].position[1] = tileData[4].position[1] = upperVy;
	    tileData[2].position[1] = tileData[3].position[1] = tileData[5].position[1] = lowerVy;

	    // tex coords
	    tileData[0].texCoords[0] = tileData[2].texCoords[0] = tileData[3].texCoords[0] = (tileX+1) * tileNormalisedSize.width / 2.0f;
	    tileData[1].texCoords[0] = tileData[4].texCoords[0] = tileData[5].texCoords[0] = tileX * tileNormalisedSize.width / 2.0f;
	    tileData[0].texCoords[1] = tileData[1].texCoords[1] = tileData[4].texCoords[1] = (tileY+1) * tileNormalisedSize.height;
	    tileData[2].texCoords[1] = tileData[3].texCoords[1] = tileData[5].texCoords[1] = tileY * tileNormalisedSize.height;
	    
	    memcpy(&_vertexData[vertexIndex], tileData, kBytesPerVertex*kTileVertexLength);
	    vertexIndex+=6;
	}
    }

    // Copy source vertex data as tiles: Back side
    for (int tileY=0; tileY < _numTilesY; tileY++) {
	float lowerVy = 1.0f - tileY * tileNormalisedSize.height - 0.5f;
	float upperVy = 1.0f - (tileY+1) * tileNormalisedSize.height - 0.5f;
	for (int tileX=0; tileX < _numTilesX; tileX++) {
	    float lhsVx = tileX * tileNormalisedSize.width - 0.5f;
	    float rhsVx = (tileX+1) * tileNormalisedSize.width - 0.5f;
	    
	    // position vertices
	    tileData[0].position[0] = tileData[1].position[0] = tileData[3].position[0] = rhsVx;
	    tileData[2].position[0] = tileData[4].position[0] = tileData[5].position[0] = lhsVx;
	    tileData[0].position[1] = tileData[2].position[1] = tileData[5].position[1] = upperVy;
	    tileData[1].position[1] = tileData[3].position[1] = tileData[4].position[1] = lowerVy;
	    
	    // tex coords
	    tileData[0].texCoords[0] = tileData[1].texCoords[0] = tileData[3].texCoords[0] = 1.0f - (tileX+1) * tileNormalisedSize.width / 2.0f;
	    tileData[2].texCoords[0] = tileData[4].texCoords[0] = tileData[5].texCoords[0] = 1.0f - tileX * tileNormalisedSize.width / 2.0f;
	    tileData[0].texCoords[1] = tileData[2].texCoords[1] = tileData[5].texCoords[1] = (tileY+1) * tileNormalisedSize.height;
	    tileData[1].texCoords[1] = tileData[3].texCoords[1] = tileData[4].texCoords[1] = tileY * tileNormalisedSize.height;
	    
	    memcpy(&_vertexData[vertexIndex], tileData, kBytesPerVertex*kTileVertexLength);
	    vertexIndex+=6;
	}
    }

    UIImage *textureAtlas = [self textureAtlasContainingSourceAndDestinationViews];
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:GLKTextureLoaderOriginBottomLeft];
    _textureInfo = [GLKTextureLoader textureWithCGImage:textureAtlas.CGImage options:options error:nil];
    
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.texture2d0.enabled = YES;
    self.effect.texture2d0.name = _textureInfo.name;
    
    ASSERT_GL_OK();
    
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glFrontFace(GL_CW);

    ASSERT_GL_OK();

    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, _vertexDataLength, _vertexData, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(12));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(24));
    
    ASSERT_GL_OK();
    
    glBindVertexArrayOES(0);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    _textureInfo = nil;
    
    free(_vertexData); _vertexData = NULL;
}


#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    _timing += self.timeSinceLastUpdate * 0.25f;
    if (_timing >= 1.0f) {
	_timing = 1.0f;
	_finished = YES;
    }
    
    _transition = SineEaseInOut(_timing);

    GLKMatrix4 animTransform = GLKMatrix4MakeTranslation(_transition * _worldWidth/2.0f, 0.0f, -sinf(_transition * M_PI) * 80.0f);
    animTransform = GLKMatrix4Rotate(animTransform, _transition*M_PI, 0.0f, 1.0f, 0.0f);
    animTransform = GLKMatrix4Translate(animTransform, -_transition * _worldWidth/2.0f, 0.0f, 0.0f);

    float spx = _worldWidth / _numTilesX;

    // Update fixed particle positions
    NSArray *fixedParticles = [_particles subarrayWithRange:NSMakeRange(0, _numTilesX+1)];
    [fixedParticles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
	GLKVector4 vPos = GLKVector4Make(idx*spx, 0.0f, 0.0f, 1.0f);
	vPos = GLKMatrix4MultiplyVector4(animTransform, vPos);
	
	CMTPParticle *particle = obj;
	particle.position = CMTPVector3DMake(vPos.x, vPos.y, vPos.z);
    }];
    

    if (_finalisePositions) {
	BOOL resetDone = YES;
	
	// animate particle positions back to original
	for (int y=0; y < _numParticlesY; y++) {
	    for (int x=0; x < _numParticlesX; x++) {
		NSUInteger index = y*_numParticlesY + x;
		CMTPParticle *p = [_particles objectAtIndex:index];
		CMTPVector3D position = p.position;
		CMTPVector3D finalPosition = _finalPositions[index];
		position.x += (finalPosition.x - position.x) * 0.1f;
		position.y += (finalPosition.y - position.y) * 0.1f;
		position.z += (finalPosition.z - position.z) * 0.1f;
		p.position = position;
		
		if (resetDone && (fabsf(finalPosition.x - position.x) > 0.1f || fabsf(finalPosition.y - position.y) > 0.1f || fabsf(finalPosition.z - position.z) > 0.1f)) {
		    resetDone = NO;
		}
	    }
	}
	if (resetDone) _finalisePositionsFinished = YES;
    }
    else {
	// simulate physics
	[_s tick:1.0f];
    }
    


    float posScaleX = 1.0f / _worldWidth;
    float posScaleY = 1.0f / _worldHeight;
    float posScaleZ = posScaleX;
    
    NSUInteger particlesPerRow = _numTilesX + 1;
    NSUInteger backOffset = _vertexDataLength / kBytesPerVertex / 2;
    NSUInteger vertexIndex = 0;

    for (NSUInteger i=0; i < _numTilesY; i++) {
	for (NSUInteger j=0; j < _numTilesX; j++) {
	    CMTPParticle *pBotLeft =  [_particles objectAtIndex:(i*particlesPerRow)+j];
	    CMTPParticle *pBotRight = [_particles objectAtIndex:(i*particlesPerRow)+j+1];
	    CMTPParticle *pTopLeft =  [_particles objectAtIndex:((i+1)*particlesPerRow)+j];
	    CMTPParticle *pTopRight = [_particles objectAtIndex:((i+1)*particlesPerRow)+j+1];

	    /*
	    NSLog(@"-- Tile %d", vertexIndex/6);
	    NSLog(@"pBotLeft:  %@", pBotLeft);
	    NSLog(@"pBotRight: %@", pBotRight);
	    NSLog(@"pTopLeft:  %@", pTopLeft);
	    NSLog(@"pTopRight: %@", pTopRight);
	     */

	    // Front facing triangles
	    _vertexData[vertexIndex+0].position[0] = pTopRight.position.x * posScaleX - 0.5f;
	    _vertexData[vertexIndex+0].position[1] = 1.0f - pTopRight.position.y * posScaleY - 0.5f;
	    _vertexData[vertexIndex+0].position[2] = pTopRight.position.z * posScaleZ;
	    
	    _vertexData[vertexIndex+1].position[0] = pTopLeft.position.x * posScaleX - 0.5f;
	    _vertexData[vertexIndex+1].position[1] = 1.0f - pTopLeft.position.y * posScaleY - 0.5f;
	    _vertexData[vertexIndex+1].position[2] = pTopLeft.position.z * posScaleZ;
	    
	    _vertexData[vertexIndex+2].position[0] = pBotRight.position.x * posScaleX - 0.5f;
	    _vertexData[vertexIndex+2].position[1] = 1.0f - pBotRight.position.y * posScaleY - 0.5f;
	    _vertexData[vertexIndex+2].position[2] = pBotRight.position.z * posScaleZ;
	    
	    _vertexData[vertexIndex+3].position[0] = pBotRight.position.x * posScaleX - 0.5f;
	    _vertexData[vertexIndex+3].position[1] = 1.0f - pBotRight.position.y * posScaleY - 0.5f;
	    _vertexData[vertexIndex+3].position[2] = pBotRight.position.z * posScaleZ;
	    
	    _vertexData[vertexIndex+4].position[0] = pTopLeft.position.x * posScaleX - 0.5f;
	    _vertexData[vertexIndex+4].position[1] = 1.0f - pTopLeft.position.y * posScaleY - 0.5f;
	    _vertexData[vertexIndex+4].position[2] = pTopLeft.position.z * posScaleZ;
	    
	    _vertexData[vertexIndex+5].position[0] = pBotLeft.position.x * posScaleX - 0.5f;
	    _vertexData[vertexIndex+5].position[1] = 1.0f - pBotLeft.position.y * posScaleY - 0.5f;
	    _vertexData[vertexIndex+5].position[2] = pBotLeft.position.z * posScaleZ;
	    
	    // Back facing triangles
	    _vertexData[backOffset+vertexIndex+0].position[0] = pTopRight.position.x * posScaleX - 0.5f;
	    _vertexData[backOffset+vertexIndex+0].position[1] = 1.0f - pTopRight.position.y * posScaleY - 0.5f;
	    _vertexData[backOffset+vertexIndex+0].position[2] = pTopRight.position.z * posScaleZ;
	    
	    _vertexData[backOffset+vertexIndex+1].position[0] = pBotRight.position.x * posScaleX - 0.5f;
	    _vertexData[backOffset+vertexIndex+1].position[1] = 1.0f - pBotRight.position.y * posScaleY - 0.5f;
	    _vertexData[backOffset+vertexIndex+1].position[2] = pBotRight.position.z * posScaleZ;
	    
	    _vertexData[backOffset+vertexIndex+2].position[0] = pTopLeft.position.x * posScaleX - 0.5f;
	    _vertexData[backOffset+vertexIndex+2].position[1] = 1.0f - pTopLeft.position.y * posScaleY - 0.5f;
	    _vertexData[backOffset+vertexIndex+2].position[2] = pTopLeft.position.z * posScaleZ;
	    
	    _vertexData[backOffset+vertexIndex+3].position[0] = pBotRight.position.x * posScaleX - 0.5f;
	    _vertexData[backOffset+vertexIndex+3].position[1] = 1.0f - pBotRight.position.y * posScaleY - 0.5f;
	    _vertexData[backOffset+vertexIndex+3].position[2] = pBotRight.position.z * posScaleZ;
	    
	    _vertexData[backOffset+vertexIndex+4].position[0] = pBotLeft.position.x * posScaleX - 0.5f;
	    _vertexData[backOffset+vertexIndex+4].position[1] = 1.0f - pBotLeft.position.y * posScaleY - 0.5f;
	    _vertexData[backOffset+vertexIndex+4].position[2] = pBotLeft.position.z * posScaleZ;
	    
	    _vertexData[backOffset+vertexIndex+5].position[0] = pTopLeft.position.x * posScaleX - 0.5f;
	    _vertexData[backOffset+vertexIndex+5].position[1] = 1.0f - pTopLeft.position.y * posScaleY - 0.5f;
	    _vertexData[backOffset+vertexIndex+5].position[2] = pTopLeft.position.z * posScaleZ;
	    
	    vertexIndex += 6;
	}
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    float fovy = GLKMathDegreesToRadians(65.0f);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(fovy, aspect, 0.1f, 100.0f);
    float zdist = 0.5f / tanf(fovy/2.0f);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
//    float physicsCorrectYScale = 0.99f;
//    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -zdist);
//    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, aspect, physicsCorrectYScale, 1.0f); // scale to match view aspect ratio & physics stretching
//    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0.0f, 0.005f, 0.0f);

    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -zdist);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, aspect, 1.0f, 1.0f); // scale to match view aspect ratio

    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    
    glClearColor(0.25f, 0.25f, 0.25f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    glBindVertexArrayOES(_vertexArray);
    glBufferData(GL_ARRAY_BUFFER, _vertexDataLength, _vertexData, GL_DYNAMIC_DRAW);
    
    // Render the object with GLKit
    [self.effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, _vertexDataLength/kBytesPerVertex);
    
    if (_finished) {
	
	// wait for cloth to come back to rest
	CMTPParticle *lastParticle1 = [_particles objectAtIndex:([_particles count] - _numParticlesX)];
	CMTPParticle *lastParticle2 = [_particles lastObject];
	if (lastParticle1.position.z > -0.1f && lastParticle2.position.z > -0.1f) {
	    _finalisePositions = YES;
	}
    }
    
    if (_finalisePositionsFinished) {
	dispatch_async(dispatch_get_main_queue(), ^{
	    [fancyStoryboardSegueDelegate fancyStoryboardSegueTransitionFinished:self];
	});
    }
}

@end


/* Easing function borrowed from AHEasing https://github.com/warrenm/AHEasing
 */
static float SineEaseInOut(float p)
{
    return 0.5 * (1 - cos(p * M_PI));
}
