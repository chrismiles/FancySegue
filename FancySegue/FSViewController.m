//
//  FSViewController.m
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

#import "FSViewController.h"
#import "FSFancyStoryboardSegue.h"
#import "FSGLBoxTransitionViewController.h"
#import "FSGLScaleRotateTransitionViewController.h"
#import "FSGLTileFlyViewController.h"
#import "FSGLClothFlipTransitionViewController.h"

#define kScaleAndRotateTransitionTag 1
#define kBoxTransitionTag 2
#define kTileFlyTransitionTag 3
#define kClothFlipTransitionTag 4

//typedef enum {
//    TransitionTypeNone		    = 0,
//    TransitionTypeScaleAndRotate    = 1,
//    TransitionTypeBox		    = 2,
//    TransitionTypeTileFly	    = 3,
//    TransitionTypeClothFlip	    = 4,
//} TransitionType;

/* Return a random float between 0.0 and 1.0 */
static inline float randomClamp()
{
    return (float)(arc4random() % ((unsigned)RAND_MAX + 1)) / (float)((unsigned)RAND_MAX + 1);
}

/* Returns a random integer number between low and high inclusive */
static inline int randomInt(int low, int high)
{
    return (arc4random() % (high-low+1)) + low;
}


@interface FSViewController ()

@end

@implementation FSViewController

@synthesize bgImageName = _bgImageName;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.view.backgroundColor = [UIColor colorWithRed:randomClamp() green:randomClamp() blue:randomClamp() alpha:1.0f];
    
//    if (nil == self.bgImageName) self.bgImageName = [NSString stringWithFormat:@"miles_photo_%d.jpg", randomInt(1, 4)];
    
    if (self.bgImageName) {
	// Single large background image
	UIImageView *bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:self.bgImageName]];
	bgImageView.frame = self.view.bounds;
	bgImageView.contentMode = UIViewContentModeScaleAspectFill;
	bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view insertSubview:bgImageView atIndex:0];
    }
    else {
	// Grid of background images
	for (int i=0; i<4; i++) {
	    NSString *imageName = [NSString stringWithFormat:@"miles_photo_%d.jpg", i+1];
	    UIImageView *bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
	    CGRect frame = CGRectMake(0.0f, 0.0f, self.view.bounds.size.width/2.0f, self.view.bounds.size.height/2.0f);
	    if (i == 0) {
		bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	    }
	    else if (i == 1) {
		frame.origin = CGPointMake(self.view.bounds.size.width/2.0f, 0.0f);
		bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
	    }
	    else if (i == 2) {
		frame.origin = CGPointMake(0.0f, self.view.bounds.size.height/2.0f);
		bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
	    }
	    else if (i == 3) {
		frame.origin = CGPointMake(self.view.bounds.size.width/2.0f, self.view.bounds.size.height/2.0f);
		bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
	    }
	    bgImageView.frame = CGRectIntegral(frame);
	    bgImageView.contentMode = UIViewContentModeScaleAspectFill;
	    bgImageView.clipsToBounds = YES;
	    [self.view insertSubview:bgImageView atIndex:0];
	}
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
	return YES;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue isKindOfClass:[FSFancyStoryboardSegue class]]) {
	FSFancyStoryboardSegue *fancySegue = (FSFancyStoryboardSegue *)segue;
	UIViewController<FSFancyStoryboardSegueTransitionProtocol> *transitionViewController = nil;
	
	if ([(UIView *)sender tag] == kScaleAndRotateTransitionTag) {
	    transitionViewController = [[FSGLScaleRotateTransitionViewController alloc] initWithNibName:nil bundle:nil];
	}
	else if ([(UIView *)sender tag] == kBoxTransitionTag) {
	    transitionViewController = [[FSGLBoxTransitionViewController alloc] initWithNibName:nil bundle:nil];
	}
	else if ([(UIView *)sender tag] == kTileFlyTransitionTag) {
	    transitionViewController = [[FSGLTileFlyViewController alloc] initWithNibName:nil bundle:nil];
	}
	else if ([(UIView *)sender tag] == kClothFlipTransitionTag) {
	    transitionViewController = [[FSGLClothFlipTransitionViewController alloc] initWithNibName:nil bundle:nil];
	}
	
	fancySegue.transitionViewController = transitionViewController;
	
	if ([fancySegue.destinationViewController respondsToSelector:@selector(setBgImageName:)]) {
	    NSString *bgImageName = nil;
	    if (nil == self.bgImageName) {
//		while ([(bgImageName = [NSString stringWithFormat:@"miles_photo_%d.jpg", randomInt(1, 4)]) isEqualToString:self.bgImageName]) ;
		bgImageName = [NSString stringWithFormat:@"miles_photo_%d.jpg", randomInt(1, 4)];
	    }
	    
	    FSViewController *destinationViewController = (FSViewController *)fancySegue.destinationViewController;
	    destinationViewController.bgImageName = bgImageName;
//	    [fancySegue.destinationViewController performSelector:@selector(setBgImageName:) withObject:bgImageName];
	}
    }
}

@end
