//
//  RLPainterViewController.m
//  CGFun
//
//  Created by raokai on 13-6-22.
//  Copyright (c) 2013年 rockylession. All rights reserved.
//

#import "RLPainterViewController.h"
#import "QuartzCore/QuartzCore.h"

@interface RLPainterViewController (){
    CGFloat _canvasOriginX;
    CGFloat _canvanOriginY;
    CGFloat _canvasWidth;
    CGFloat _canvasHeight;
    
    NSUInteger sampleCount;
    
    UIImageView *_displayView;
    
    CGMutablePathRef _currentRootPath;
}

@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) BOOL isDashed;
@property (nonatomic, assign) BOOL shouldFill;
// whether use clip area
@property (nonatomic, assign) BOOL shouldClip;
@property (nonatomic, retain) UIColor *strokeColor;
@property (nonatomic, retain) UIColor *fillColor;

// pattern draw callback
void coloredDrawPattern (void *info, CGContextRef context);
void stencilDrawPattern (void *info, CGContextRef context);

- (void)drawLines;
- (void)drawCurves;
- (void)drawOvals;
- (void)drawTriangles;
- (void)drawRectangles;
- (void)drawfpstar;

- (void)setupColoredFillPatternInContext:(CGContextRef)context;
- (void)setupStencilDrawPatternInContext:(CGContextRef)context;

- (void)setClippingAera:(CGContextRef)context;
- (CGMutablePathRef)setupRootPathWithContext:(CGContextRef)context;
- (CGContextRef)prepareImageContextToDraw;
- (UIImage *)endContextAndRetriveImage:(CGContextRef)context;

// save current graphic to a bitmap file.
- (void)saveCurrentBitmap;

@end

@implementation RLPainterViewController

@synthesize lineWidth = _lineWidth, isDashed = _isDashed, shouldFill = _shouldFill, strokeColor = _strokeColor, fillColor = _fillColor;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _lineWidth = 2.0f;
        _isDashed = NO;
        _shouldFill = YES;
        _shouldClip = YES;
        _strokeColor = [[UIColor orangeColor] retain];
        _fillColor = [[UIColor purpleColor] retain];
        
        sampleCount = 5;
        
        _canvasOriginX = 20.0f;
        _canvanOriginY = 100.0f;
        _canvasWidth = 280.0f;
        _canvasHeight = 340.0f;
    }
    return self;
}

- (void)dealloc {
    [_strokeColor release];
    [_fillColor release];
    [_displayView release];
    if (_currentRootPath != nil) {
        CGPathRelease(_currentRootPath);
        _currentRootPath = nil;
    }
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.view.backgroundColor = [UIColor blackColor];
	// Do any additional setup after loading the view.
    UIButton *drawLineButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [drawLineButton setTitle:@"线" forState:UIControlStateNormal];
    [drawLineButton addTarget:self action:@selector(drawLines) forControlEvents:UIControlEventTouchUpInside];
    [drawLineButton sizeToFit];
    [self.view addSubview:drawLineButton];
    
    UIButton *curveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [curveButton setTitle:@"曲线" forState:UIControlStateNormal];
    [curveButton addTarget:self action:@selector(drawCurves) forControlEvents:UIControlEventTouchUpInside];
    [curveButton sizeToFit];
    [self.view addSubview:curveButton];

    UIButton *ovalButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [ovalButton setTitle:@"椭圆" forState:UIControlStateNormal];
    [ovalButton addTarget:self action:@selector(drawOvals) forControlEvents:UIControlEventTouchUpInside];
    [ovalButton sizeToFit];
    [self.view addSubview:ovalButton];
    
    UIButton *rectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [rectButton setTitle:@"矩形" forState:UIControlStateNormal];
    [rectButton addTarget:self action:@selector(drawRectangles) forControlEvents:UIControlEventTouchUpInside];
    [rectButton sizeToFit];
    [self.view addSubview:rectButton];

    UIButton *fsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [fsButton setTitle:@"五角星" forState:UIControlStateNormal];
    [fsButton addTarget:self action:@selector(drawfpstar) forControlEvents:UIControlEventTouchUpInside];
    [fsButton sizeToFit];
    [self.view addSubview:fsButton];
    
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [saveButton setTitle:@"储存图片" forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(saveCurrentBitmap) forControlEvents:UIControlEventTouchUpInside];
    [saveButton sizeToFit];
    [self.view addSubview:saveButton];
    
    
    drawLineButton.frame = CGRectMake(20.0, 10.0,
                                      drawLineButton.frame.size.width, drawLineButton.frame.size.height);
    curveButton.frame = CGRectMake(CGRectGetMaxX(drawLineButton.frame), 10.0,
                                      curveButton.frame.size.width, curveButton.frame.size.height);
    ovalButton.frame = CGRectMake(CGRectGetMaxX(curveButton.frame), 10.0,
                                   ovalButton.frame.size.width, ovalButton.frame.size.height);
    rectButton.frame = CGRectMake(CGRectGetMaxX(ovalButton.frame), 10.0,
                                  rectButton.frame.size.width, rectButton.frame.size.height);
    fsButton.frame = CGRectMake(CGRectGetMaxX(rectButton.frame), 10.0,
                                  fsButton.frame.size.width, fsButton.frame.size.height);
    
    
    saveButton.frame = CGRectMake(20.0, CGRectGetMaxY(drawLineButton.frame) + 5.0,
                                      saveButton.frame.size.width, saveButton.frame.size.height);
    _displayView = [[UIImageView alloc] initWithFrame:CGRectMake(_canvasOriginX, _canvanOriginY, _canvasWidth, _canvasHeight)];
    _displayView.layer.borderWidth = 3.0;
    _displayView.layer.cornerRadius = 5.0;
    
    
    [self.view addSubview:_displayView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setClippingAera:(CGContextRef)context {
    CGFloat radius = _canvasHeight / 4;
    CGFloat centerX = _canvasWidth / 2;
    CGFloat centerY = _canvasHeight / 2;
    CGContextBeginPath(context);
    CGContextAddArc(context, centerX, centerY, radius, 0, M_PI * 2, 0);
    CGContextClosePath(context);
    CGContextClip(context);
}

// drawing pattern routines
void coloredDrawPattern (void *info, CGContextRef context) {
    
    // pattern width, height. just remember in heart.
//    CGFloat patternWidth = 8.0f;
//    CGFloat patternHeight = 8.0f;
    
    CGFloat unit = 3.0f;
    
    CGRect lefttop = CGRectMake(0.0, 0.0, unit, unit);
    CGRect righttop = CGRectMake(unit, 0.0, unit, unit);
    CGRect leftbottom = CGRectMake(0.0, unit, unit, unit);
    CGRect rightbottom = CGRectMake(unit, 0.0, unit, unit);
    
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
    CGContextFillRect(context, lefttop);
    CGContextSetRGBFillColor(context, 0.0, 1.0, 0.0, 1.0);
    CGContextFillRect(context, righttop);
    CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1.0);
    CGContextFillRect(context, leftbottom);
    CGContextSetRGBFillColor(context, 0.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, rightbottom);
}

// drawing pattern
void stencilDrawPattern (void *info, CGContextRef context) {

    // pattern width = height = 16 pixels
    CGFloat PSIZE = 16.0f;
    int k;
    double r, theta;
    
    r = PSIZE / 2;
    theta = 2 * M_PI * (2.0 / 5.0); // 144 degrees
    
    CGContextTranslateCTM (context, PSIZE/2, PSIZE/2);
    
    CGContextMoveToPoint(context, 0, r);
    for (k = 1; k < 5; k++) {
        CGContextAddLineToPoint (context,
                                 r * sin(k * theta),
                                 r * cos(k * theta));
    }
    CGContextClosePath(context);
    CGContextFillPath(context);    
}

- (void)setupStencilDrawPatternInContext:(CGContextRef)context {
    
    // define color space and color
    CGColorSpaceRef baseColorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorSpaceRef patternColorSpace = CGColorSpaceCreatePattern(baseColorSpace);
    CGFloat color[] = {0.5, 0.5, 0.5, 1.0};
    
    // stencil (no color) pattern creation
    CGPatternCallbacks callbacks = {0, &stencilDrawPattern, nil};
    CGPatternRef stencilPattern = CGPatternCreate(nil, CGRectMake(0.0, 0.0, 16.0, 16.0), CGAffineTransformIdentity, 16.0, 16.0, kCGPatternTilingConstantSpacingMinimalDistortion, NO, &callbacks);
    
    CGContextSetFillColorSpace(context, patternColorSpace);    
    CGContextSetFillPattern(context, stencilPattern, color);
    
    // release
    CGColorSpaceRelease(patternColorSpace);
    CGColorSpaceRelease(baseColorSpace);
    CGPatternRelease(stencilPattern);
}

- (void)setupColoredFillPatternInContext:(CGContextRef)context {
    CGPatternRef pattern;
    CGColorSpaceRef patternColorSpace;
    CGFloat alpha = 1;
    CGFloat patternWidth = 8.0f;
    CGFloat patternHeight = 8.0f;
    // the third param is used for release raw data when pattern is releasing
    static const CGPatternCallbacks callbacks = {0, &coloredDrawPattern, NULL};
    
    // set color space
    patternColorSpace = CGColorSpaceCreatePattern(nil);
    CGContextSetFillColorSpace(context, patternColorSpace);
    CGColorSpaceRelease(patternColorSpace);
    
    // set pattern
    pattern = CGPatternCreate(NULL, CGRectMake(0.0, 0.0, patternWidth, patternHeight), CGAffineTransformIdentity, patternWidth, patternHeight, kCGPatternTilingConstantSpacingMinimalDistortion, YES, &callbacks);
    CGContextSetFillPattern(context, pattern, &alpha);    // colored pattern, only supply a alpha component
    CGPatternRelease(pattern);
}

- (CGMutablePathRef)setupRootPathWithContext:(CGContextRef)context {
    if (_currentRootPath != nil) {
        CGPathRelease(_currentRootPath);
    }
    _currentRootPath = CGPathCreateMutable();
    return _currentRootPath;
}

- (CGContextRef)prepareImageContextToDraw {
    UIGraphicsBeginImageContext(_displayView.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, _lineWidth);
    if (!_isDashed) {
        CGContextSetLineDash(context, 0, nil, 0);
    }else {
        const CGFloat pattern[] = {1.0, 1.0};
        CGContextSetLineDash(context, 0, pattern, 2);
    }
    
    // setup color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextSetStrokeColorSpace(context, colorSpace);
//    CGContextSetFillColorSpace(context, colorSpace);
    CGColorSpaceRelease(colorSpace);
    
//    [self setupColoredFillPatternInContext:context];
    [self setupStencilDrawPatternInContext:context];
    
    // set color
//    CGContextSetFillColor(context, CGColorGetComponents(_fillColor.CGColor));
    CGContextSetStrokeColor(context, CGColorGetComponents(_strokeColor.CGColor));
    
    // clipping
    if (_shouldClip) {
        [self setClippingAera:context];
    }else {
        // do nothing
    }
    return context;
}

- (UIImage *)endContextAndRetriveImage:(CGContextRef)context {

    if (_shouldFill) {
        CGContextDrawPath(context, kCGPathEOFillStroke);
    }else {
        CGContextDrawPath(context, kCGPathStroke);
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)drawLines {
    CGContextRef context = [self prepareImageContextToDraw];
    [self setupRootPathWithContext:context];
    
    for (int i = 0; i < sampleCount ; i++) {
        CGFloat x1 = (i + 1) * _canvasWidth / (sampleCount + 1);
        CGFloat y1 = 5.0f;
        CGFloat x2 = x1;
        CGFloat y2 = _canvasHeight - 10.0f;
        CGPathMoveToPoint(_currentRootPath, nil, x1, y1);
        CGPathAddLineToPoint(_currentRootPath, nil, x2, y2);
    }
    
    CGContextAddPath(context, _currentRootPath);
    UIImage *image = [self endContextAndRetriveImage:context];
    _displayView.image = image;
}

- (void)drawCurves {
    CGContextRef context = [self prepareImageContextToDraw];    
    [self setupRootPathWithContext:context];
    
    for (int i = 0; i < sampleCount; i++) {
        CGFloat x = (i+1) * _canvasWidth / (sampleCount + 1);
        CGFloat y = (i+1) * _canvasHeight / (sampleCount + 1);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddArc(path, nil, x, y, 15.0f, 2 * M_PI / sampleCount * i, 2 * M_PI / sampleCount * (i+1), 0);
        CGPathAddPath(_currentRootPath, nil, path);
    }
    CGContextAddPath(context, _currentRootPath);
    UIImage *image = [self endContextAndRetriveImage:context];
    _displayView.image = image;
}

- (void)drawOvals{
    CGContextRef context = [self prepareImageContextToDraw];
    [self setupRootPathWithContext:context];
    for (int i = 0; i < sampleCount; i++) {
        CGFloat x = (i+1) * _canvasWidth / (sampleCount + 1);
        CGFloat y = (i+1) * _canvasHeight / (sampleCount + 1);
        CGFloat width = _canvasWidth / sampleCount;
        CGFloat height = _canvasHeight / sampleCount;
        CGPathAddEllipseInRect(_currentRootPath, nil, CGRectMake(x - width / 2, y - height / 2, width, height));
    }
    CGContextAddPath(context, _currentRootPath);
    CGContextClosePath(context);
    UIImage *image = [self endContextAndRetriveImage:context];
    _displayView.image = image;
}

- (void)drawTriangles {}

- (void)drawRectangles {
    CGContextRef context = [self prepareImageContextToDraw];
    [self setupRootPathWithContext:context];
    for (int i = 0; i < sampleCount; i++) {
        CGFloat x = (i+1) * _canvasWidth / (sampleCount + 1);
        CGFloat y = (i+1) * _canvasHeight / (sampleCount + 1);
        CGFloat width = _canvasWidth / sampleCount;
        CGFloat height = _canvasHeight / sampleCount;
        CGPathAddRect(_currentRootPath, nil, CGRectMake(x - width / 2, y - height / 2, width, height));
    }
    CGContextAddPath(context, _currentRootPath);
    UIImage *image = [self endContextAndRetriveImage:context];
    _displayView.image = image;
}

- (void)drawfpstar {
    CGFloat radius = _canvasHeight / 3;
    CGFloat centerX = _canvasWidth / 2;
    CGFloat centerY = _canvasHeight / 2;
    
    CGFloat endPointx[5];
    CGFloat endPointy[5];
    
    CGFloat radian = M_PI / 180.0 * 162.0;
    for (int i = 0; i < 5; i++) {
        endPointx[i] = centerX + radius * cosf(radian);
        endPointy[i] = centerY + radius * sinf(radian);
        radian = radian + 2 * M_PI / 5;
    }
    
    CGContextRef context = [self prepareImageContextToDraw];
    [self setupRootPathWithContext:context];
    CGPathMoveToPoint(_currentRootPath, nil, endPointx[0], endPointy[0]);
    int index = 0;
    for (int i = 0; i < 5; i++) {
        index = index + 2;
        if (index >= 5) {
            index = index - 5;
        }
        CGPathAddLineToPoint(_currentRootPath, nil, endPointx[index], endPointy[index]);
    }
    CGPathCloseSubpath(_currentRootPath);
    CGContextAddPath(context, _currentRootPath);
    UIImage *image = [self endContextAndRetriveImage:context];
    _displayView.image = image;
}

// save current graphic to a bitmap file.
- (void)saveCurrentBitmap {
    if (_currentRootPath != nil) {
        CGContextRef bitmapContext = [self prepareImageContextToDraw];
        CGContextAddPath(bitmapContext, _currentRootPath);
        UIImage *image = [self endContextAndRetriveImage:bitmapContext];
        NSData *pngData = UIImagePNGRepresentation(image);
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = [searchPaths objectAtIndex:0];
        NSFileManager *defaultFileManager = [NSFileManager defaultManager];
        NSString *resourceDir = @"resource";
        NSString *resourcePath = [documentDirectory stringByAppendingPathComponent:resourceDir];
        NSError *error;
        if (![defaultFileManager fileExistsAtPath:resourcePath]) {
            BOOL success = [defaultFileManager createDirectoryAtPath:resourcePath withIntermediateDirectories:YES attributes:nil error:&error];
            if (!success) {
                NSLog(@"error occurs %@", [error localizedDescription]);
            }
        }
        
        NSArray *contents = [defaultFileManager contentsOfDirectoryAtPath:resourcePath error:&error];
        int count = [contents count];
        NSString *fileName = [NSString stringWithFormat:@"bitmap-%d.png", count];
        [pngData writeToFile:[resourcePath stringByAppendingPathComponent:fileName] atomically:YES];
    }
    
}

@end
