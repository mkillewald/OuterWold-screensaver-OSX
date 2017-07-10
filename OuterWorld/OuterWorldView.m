//
//  OuterWorldView.m
//  OuterWorld
//
//  Created by k1ds3ns4t10n on 4/20/17.
//  Copyright © 2017 Gameaholix. All rights reserved.
//

#import "OuterWorldView.h"

@implementation OuterWorldView

static NSString * const kMyModuleName = @"com.gameaholix.OuterWorld";

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    
    // init some variables
    frameCounter = 0;
    index = 0; // re-usable general purpose index for use within frame logic
    counter = 20; // 20 second countdown timer
    drawSynchrotron = NO;
    drawRooms = NO;
    drawEjection = NO;
    
    // set up colors
    synchrotronColor = [NSColor colorWithCalibratedRed:52/255.0 green:128/255.0 blue:15/255.0 alpha:1.0];
    particleColor = [NSColor colorWithCalibratedRed:209/255.0 green:177/255.0 blue:20/255.0 alpha:1.0];
    textHighlightColor = [NSColor colorWithCalibratedRed:180/255.0 green:1.0 blue:48/255.0 alpha:1.0];
    textColor = [NSColor colorWithCalibratedRed:118/255.0 green:187/255.0 blue:17/255.0 alpha:1.0];
    textDarkColor = [NSColor colorWithCalibratedRed:93/255.0 green:163/255.0 blue:29/255.0 alpha:1.0];
    textDark2Color = [NSColor colorWithCalibratedRed:52/255.0 green:128/255.0 blue:15/255.0 alpha:1.0];
    displayBGColor = [NSColor colorWithCalibratedRed:11/255.0 green:83/255.0 blue:0.0 alpha:1.0];
    displayBGAlphaColor = [NSColor colorWithCalibratedRed:0.0 green:69/255.0 blue:0.0 alpha:0.5];
    displayTopColor = [NSColor colorWithCalibratedRed:30/255.0 green:87/255.0 blue:0.0 alpha:1.0];
    displayBottomColor = [NSColor colorWithCalibratedRed:82/255.0 green:155/255.0 blue:0.0 alpha:1.0];
    
    topFill = [[NSGradient alloc] initWithStartingColor:displayTopColor endingColor:displayBGColor];
    bottomFill = [[NSGradient alloc] initWithStartingColor:displayBottomColor endingColor:displayBGColor];
    sideFill = [[NSGradient alloc] initWithStartingColor:displayTopColor endingColor:displayBottomColor];
    overlay = [[NSGradient alloc] initWithStartingColor:NSColor.clearColor endingColor:displayBGColor];
    
    if (self) {
        [self setAnimationTimeInterval:1/30.0];
        
        self.layer = [CALayer layer];
        self.layer.backgroundColor = displayBGColor.CGColor;
        self.layer.needsDisplayOnBoundsChange = YES;
        self.layer.frame = NSRectToCGRect(self.bounds);
        self.layer.delegate = (id)self;
        self.wantsLayer = YES;
        [self.layer setNeedsDisplay]; //only going to draw our background layer once
    }
    
    // obtain bundle for this screensaver module
    NSBundle *bundle = [NSBundle bundleWithIdentifier:kMyModuleName];
    
    // register custom tff fonts
    NSArray *ttfPaths = [bundle pathsForResourcesOfType:@"ttf" inDirectory:@""];
    
    for (NSString *path in ttfPaths) {
        NSURL *fontUrl = [[NSURL alloc] initFileURLWithPath:path];
        CFErrorRef error;
        CTFontManagerRegisterFontsForURL((CFURLRef)fontUrl, kCTFontManagerScopeProcess, &error);
    }
    
//    // register custom otf fonts
//    NSArray *otfPaths = [bundle pathsForResourcesOfType:@"otf" inDirectory:@""];
//    
//    for (NSString *path in otfPaths) {
//        NSURL *fontUrl = [[NSURL alloc] initFileURLWithPath:path];
//        CFErrorRef error;
//        CTFontManagerRegisterFontsForURL((CFURLRef)fontUrl, kCTFontManagerScopeProcess, &error);
//    }

    // set up display scaling for drawing vectors
    nativeRect = NSMakeRect(0, 0, 1280, 720);
    
    NSSize nativeSize = nativeRect.size;
    NSSize boundsSize = self.bounds.size;
//    CGFloat nativeAspect = nativeSize.width / nativeSize.height;
//    CGFloat boundsAspect = boundsSize.width / boundsSize.height;
//    scale = nativeAspect > boundsAspect ? boundsSize.width / nativeSize.width : boundsSize.height / nativeSize.height;
    scale = boundsSize.height / nativeSize.height;
    
    transform = [[NSAffineTransform alloc] init];
    [transform translateXBy:0.5 * (boundsSize.width - scale * nativeSize.width)
                        yBy:0.5 * (boundsSize.height - scale * nativeSize.height)];
    [transform scaleBy:scale];
    
    //create a layer to draw in, we will update this layer as needed in the animateOneFrame method
    drawLayer = [CALayer layer];
    drawLayer.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    drawLayer.bounds = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    drawLayer.backgroundColor = NSColor.clearColor.CGColor;
    drawLayer.delegate = (id)self;
    [self.layer addSublayer:drawLayer];
    
    CGFloat offsetX = 0.5 * (boundsSize.width - scale * nativeSize.width);
    CGFloat offsetY = 0.5 * (boundsSize.height - scale * nativeSize.height);

    // set up text display rects
    mainDisplayRect.size.width = boundsSize.width * 0.80;
    mainDisplayRect.size.height = boundsSize.height * 0.80;
    
    mainDisplayRect.origin.x = (boundsSize.width - mainDisplayRect.size.width) / 2;
    mainDisplayRect.origin.y = (boundsSize.height - mainDisplayRect.size.height) / 2;
    
    rightDisplayRect.size.width = mainDisplayRect.size.width / 2.0;
    rightDisplayRect.size.height = mainDisplayRect.size.height;
    rightDisplayRect.origin.x = mainDisplayRect.origin.x + rightDisplayRect.size.width;
    rightDisplayRect.origin.y = mainDisplayRect.origin.y;
    
    // set up textStorage, layoutManager, textContainer, and textView instances
    mainTextStorage = [[NSTextStorage alloc] initWithString:@"" attributes:textNormalAttrs];
    NSLayoutManager *mainLayoutManager = [[NSLayoutManager alloc] init];
    [mainTextStorage addLayoutManager:mainLayoutManager];
    NSTextContainer *mainTextContainer = [[NSTextContainer alloc] initWithContainerSize:mainDisplayRect.size];
    [mainLayoutManager addTextContainer:mainTextContainer];
    mainTextView = [[NSTextView alloc] initWithFrame:mainDisplayRect textContainer:mainTextContainer];
    mainTextView.backgroundColor = NSColor.clearColor;
    mainTextView.drawsBackground = YES;
    mainTextView.editable = NO;
    mainTextView.selectable = NO;
    
    rightTextStorage = [[NSTextStorage alloc] initWithString:@"" attributes:textNormalAttrs];
    NSLayoutManager *rightLayoutManager = [[NSLayoutManager alloc] init];
    [rightTextStorage addLayoutManager:rightLayoutManager];
    NSTextContainer *rightTextContainer = [[NSTextContainer alloc] initWithContainerSize:rightDisplayRect.size];
    [rightLayoutManager addTextContainer:rightTextContainer];
    rightTextView = [[NSTextView alloc] initWithFrame:rightDisplayRect textContainer:rightTextContainer];
    rightTextView.backgroundColor = NSColor.clearColor;
    rightTextView.drawsBackground = YES;
    rightTextView.editable = NO;
    rightTextView.selectable = NO;
    
//    mainTextView.layer = [CALayer layer];
//    mainTextView.layer.needsDisplayOnBoundsChange = YES;
//    mainTextView.layer.frame = NSRectToCGRect(mainTextView.bounds);
//    mainTextView.layer.backgroundColor = NSColor.clearColor.CGColor;
//    mainTextView.layer.opacity = 0.5;
//    [mainTextView.layer setNeedsDisplay];
    
    [self addSubview:mainTextView];
    [self addSubview:rightTextView];
    
    // determine font size and create string attributes
    CGFloat mainFontSize = 28.0 * scale;
    NSFont *mainFont = [NSFont fontWithName:@"Monopoly" size:mainFontSize];
    //    NSFont *font = [NSFont fontWithName:@"Big Pixel Demo" size:fontSize];
    
    CGFloat roomFontSize = 24.0 * scale;
    NSFont *roomFont = [NSFont fontWithName:@"Visitor TT2 BRK" size:roomFontSize];
    
    textNormalAttrs = @{
                        NSFontAttributeName : mainFont,
                        NSForegroundColorAttributeName : textColor,
                        NSBackgroundColorAttributeName : NSColor.clearColor
                        };
    
    textBlankAttrs = @{
                       NSFontAttributeName : mainFont,
                       NSForegroundColorAttributeName : NSColor.clearColor,
                       NSBackgroundColorAttributeName : NSColor.clearColor
                       };
    
    textDarkAttrs = @{
                      NSFontAttributeName : mainFont,
                      NSForegroundColorAttributeName : textDarkColor,
                      NSBackgroundColorAttributeName : NSColor.clearColor
                      };
    
    textDark2Attrs = @{
                       NSFontAttributeName : mainFont,
                       NSForegroundColorAttributeName : textDark2Color,
                       NSBackgroundColorAttributeName : NSColor.clearColor
                       };
    
    textHighlightAttrs = @{
                           NSFontAttributeName : mainFont,
                           NSForegroundColorAttributeName : textHighlightColor,
                           NSBackgroundColorAttributeName : NSColor.clearColor
                           };
    textRoomAttrs = @{
                        NSFontAttributeName : roomFont,
                        NSForegroundColorAttributeName : textColor,
                        NSBackgroundColorAttributeName : NSColor.clearColor
                        };
    
    cursorAttrs = @{
                    NSFontAttributeName : mainFont,
                    NSForegroundColorAttributeName : textHighlightColor,
                    NSBackgroundColorAttributeName : NSColor.clearColor
                    };
    
    NSParagraphStyle *defaults = [NSParagraphStyle defaultParagraphStyle];
    
    NSMutableParagraphStyle *centered = [defaults mutableCopy];
    [centered setAlignment:NSTextAlignmentCenter];
    textCenteredAttrs = @{NSParagraphStyleAttributeName : centered};
    
    NSMutableParagraphStyle *right = [defaults mutableCopy];
    [right setAlignment:NSTextAlignmentRight];
    textRightAttrs = @{NSParagraphStyleAttributeName : right};
    
    // create the display "cube"
    backOfCube = NSMakeRect(0, 0, mainDisplayRect.size.width * 0.90, mainDisplayRect.size.height * 0.90);
    backOfCube.origin.x = mainDisplayRect.origin.x + (mainDisplayRect.size.width - backOfCube.size.width) /2 ;
    backOfCube.origin.y = mainDisplayRect.origin.y + (mainDisplayRect.size.height - backOfCube.size.height) / 2;
    
    frontPointA = self.bounds.origin;
    frontPointB = NSMakePoint(self.bounds.origin.x, self.bounds.origin.y + self.bounds.size.height);
    frontPointC = NSMakePoint(self.bounds.origin.x + self.bounds.size.width, self.bounds.origin.y + self.bounds.size.height);
    frontPointD = NSMakePoint(self.bounds.origin.x + self.bounds.size.width, self.bounds.origin.y);
    
    backPointA = backOfCube.origin;
    backPointB = NSMakePoint(backOfCube.origin.x, backOfCube.origin.y + backOfCube.size.height);
    backPointC = NSMakePoint(backOfCube.origin.x + backOfCube.size.width, backOfCube.origin.y + backOfCube.size.height);
    backPointD = NSMakePoint(backOfCube.origin.x + backOfCube.size.width, backOfCube.origin.y);
    
    topFace = [NSBezierPath bezierPath];
    [topFace moveToPoint:frontPointB];
    [topFace lineToPoint:frontPointC];
    [topFace lineToPoint:backPointC];
    [topFace lineToPoint:backPointB];
    [topFace lineToPoint:frontPointB];
    
    bottomFace = [NSBezierPath bezierPath];
    [bottomFace moveToPoint:frontPointA];
    [bottomFace lineToPoint:backPointA];
    [bottomFace lineToPoint:backPointD];
    [bottomFace lineToPoint:frontPointD];
    [bottomFace lineToPoint:frontPointA];
    
    leftFace = [NSBezierPath bezierPath];
    [leftFace moveToPoint:frontPointA];
    [leftFace lineToPoint:frontPointB];
    [leftFace lineToPoint:backPointB];
    [leftFace lineToPoint:backPointA];
    [leftFace lineToPoint:frontPointA];
    
    rightFace = [NSBezierPath bezierPath];
    [rightFace moveToPoint:frontPointD];
    [rightFace lineToPoint:frontPointC];
    [rightFace lineToPoint:backPointC];
    [rightFace lineToPoint:backPointD];
    [rightFace lineToPoint:frontPointD];
    
    // create the room "cubes"
    NSRect room3Back = NSMakeRect(backPointA.x, backPointA.y+(backPointB.y-backPointA.y)*.55, backOfCube.size.width*.40, backOfCube.size.height*.45);
    NSPoint room3BackPointC = NSMakePoint(room3Back.origin.x+room3Back.size.width, room3Back.origin.y+room3Back.size.height);
    NSPoint room3BackPointD = NSMakePoint(room3BackPointC.x, room3Back.origin.y);
    NSPoint room3FrontPointB = NSMakePoint((backPointB.x-frontPointB.x)*2/3, backPointB.y+(frontPointB.y-backPointB.y)*1/3);
    NSRect room3Front = NSMakeRect(room3FrontPointB.x, room3Back.origin.y, room3Back.size.width*1.1, room3FrontPointB.y - room3Back.origin.y);
    NSPoint room3FrontPointC = NSMakePoint(room3Front.origin.x+room3Front.size.width, room3Front.origin.y+room3Front.size.height);
    NSPoint room3FrontPointD = NSMakePoint(room3FrontPointC.x, room3Front.origin.y);
    
    room3LabelPoint = NSMakePoint(room3FrontPointB.x + 5*scale, room3FrontPointB.y - 17*scale);
    
    room3 = [NSBezierPath bezierPathWithRect:room3Front];
    [room3 moveToPoint:room3FrontPointC];
    [room3 lineToPoint:room3BackPointC];
    [room3 lineToPoint:room3BackPointD];
    [room3 lineToPoint:room3FrontPointD];
    
    NSRect room1Back = NSMakeRect(backPointA.x, backPointA.y, backOfCube.size.width*.40, backOfCube.size.height*.55);
    NSPoint room1BackPointC = NSMakePoint(room1Back.origin.x+room1Back.size.width, room1Back.origin.y+room1Back.size.height);
    NSPoint room1BackPointD = NSMakePoint(room1BackPointC.x, room1Back.origin.y);
    NSPoint room1FrontPointA = NSMakePoint((backPointA.x-frontPointA.x)*2/3, frontPointA.y+(backPointA.y-frontPointA.y)*2/3);
    NSRect room1Front = NSMakeRect(room1FrontPointA.x, room1FrontPointA.y, room1Back.size.width*1.1, room3Back.origin.y-room1FrontPointA.y);
    NSPoint room1FrontPointB = NSMakePoint(room1Front.origin.x, room1Front.origin.y+room1Front.size.height);
    NSPoint room1FrontPointC = NSMakePoint(room1Front.origin.x+room1Front.size.width, room1Front.origin.y+room1Front.size.height);
    NSPoint room1FrontPointD = NSMakePoint(room1FrontPointC.x, room1Front.origin.y);
    
    room1LabelPoint = NSMakePoint(room1FrontPointB.x + 5*scale, room1FrontPointB.y - 17*scale);
    
    room1 = [NSBezierPath bezierPathWithRect:room1Front];
    [room1 moveToPoint:room1FrontPointC];
    [room1 lineToPoint:room1BackPointC];
    [room1 lineToPoint:room1BackPointD];
    [room1 lineToPoint:room1FrontPointD];
    
    // create boxed X in corner of room "cubes"
    NSRect room3XRect = NSMakeRect(room3FrontPointC.x-15*scale, room3FrontPointC.y-15*scale, 10*scale, 10*scale);
    room3XBox = [NSBezierPath bezierPathWithRect:room3XRect];
    room3X = [NSBezierPath bezierPath];
    [room3X moveToPoint:NSMakePoint(room3XRect.origin.x, room3XRect.origin.y)];
    [room3X lineToPoint:NSMakePoint(room3XRect.origin.x+room3XRect.size.width, room3XRect.origin.y+room3XRect.size.height)];
    [room3X moveToPoint:NSMakePoint(room3XRect.origin.x, room3XRect.origin.y+room3XRect.size.height)];
    [room3X lineToPoint:NSMakePoint(room3XRect.origin.x+room3XRect.size.width, room3XRect.origin.y)];
    
    NSRect room1XRect = NSMakeRect(room1FrontPointC.x-15*scale, room1FrontPointC.y-15*scale, 10*scale, 10*scale);
    room1XBox = [NSBezierPath bezierPathWithRect:room1XRect];
    room1X = [NSBezierPath bezierPath];
    [room3X moveToPoint:NSMakePoint(room1XRect.origin.x, room1XRect.origin.y)];
    [room3X lineToPoint:NSMakePoint(room1XRect.origin.x+room1XRect.size.width, room1XRect.origin.y+room1XRect.size.height)];
    [room3X moveToPoint:NSMakePoint(room1XRect.origin.x, room1XRect.origin.y+room1XRect.size.height)];
    [room3X lineToPoint:NSMakePoint(room1XRect.origin.x+room1XRect.size.width, room1XRect.origin.y)];
    
    // create synchrotron
    NSPoint center = NSMakePoint(840, 410);
    CGFloat radius = 200;
    synchrotron = [NSBezierPath bezierPath];
    [synchrotron appendBezierPathWithArcWithCenter:center radius:radius startAngle:180 endAngle:315 clockwise:YES];
    
    // create Lab "B" on tangent to synchrotron arc
    // since we are dealing with a curve, this will return 3 points
    // we are only concerned with the end point and its adjacent control point
    NSPoint points[3];
    [synchrotron elementAtIndex:synchrotron.elementCount-1 associatedPoints:points];
    NSPoint controlPoint = points[1];
    NSPoint endPoint = points[2];
    NSPoint tangent = NSMakePoint(endPoint.x - controlPoint.x, endPoint.y - controlPoint.y);
    [synchrotron relativeLineToPoint:NSMakePoint(tangent.x*3, tangent.y*3)];
    labB = [NSBezierPath bezierPath];
    [labB moveToPoint:synchrotron.currentPoint];
    [labB relativeLineToPoint:NSMakePoint(tangent.x/2, tangent.y/2)];
    
    // create phase2 and target points used for particle animation with scale
    phase2 = endPoint;
    phase2.x = phase2.x*scale + offsetX;
    phase2.y = phase2.y*scale + offsetY;
    
    NSPoint target = [synchrotron currentPoint];
    NSPoint targetScaled = NSMakePoint(target.x*scale + offsetX, target.y*scale + offsetY);
    
    labBLabelPoint = NSMakePoint(targetScaled.x + 5*scale, targetScaled.y - 35*scale);
    
    // continue drawing the synchrotron arc
    [synchrotron appendBezierPathWithArcWithCenter:center radius:radius startAngle:315 endAngle:180 clockwise:YES];
    
    // create Lab "A" on tangent to synchrotron arc
    // same as above, this returns 3 points. we only want the end point and its adjacent control point
    [synchrotron elementAtIndex:synchrotron.elementCount-1 associatedPoints:points];
    controlPoint = points[1];
    endPoint = points[2];
    tangent = NSMakePoint(endPoint.x - controlPoint.x, endPoint.y - controlPoint.y);
    // inverse x and y because the tangent direction we want is in the opposite direction of the arc being drawn
    tangent.x *= -1;
    tangent.y *= -1;
    [synchrotron relativeLineToPoint:NSMakePoint(tangent.x*3, tangent.y*3)];
    labA = [NSBezierPath bezierPath];
    [labA moveToPoint:synchrotron.currentPoint];
    [labA relativeLineToPoint:NSMakePoint(tangent.x/2, tangent.y/2)];
    
    // create phase0 and phase1 points used for particle animation with scale
    NSPoint phase0 = [synchrotron currentPoint];
    phase0.x = phase0.x*scale + offsetX;
    phase0.y = phase0.y*scale + offsetY;
    
    NSPoint phase1 = endPoint;
    phase1.x = phase1.x*scale + offsetX;
    phase1.y = phase1.y*scale + offsetY;
    
    CGPoint phase1CGPoint = CGPointMake(phase1.x , phase1.y);
    
    // create particle ejection
    NSRect ejectionRect = NSMakeRect(target.x+90, target.y-20, 80, 80);
    ejectionView = [NSBezierPath bezierPathWithRect:ejectionRect];
    
    NSPoint ejectionMagnifyPoint = NSMakePoint(target.x-7, target.y-7);
    ejectionMagnifyPointScaled = NSMakePoint(targetScaled.x-(7*scale), targetScaled.y-(7*scale));
    
    ejectionMagnify = [NSBezierPath bezierPath];
    [ejectionMagnify moveToPoint:ejectionMagnifyPoint];
    [ejectionMagnify lineToPoint:NSMakePoint(ejectionRect.origin.x, ejectionRect.origin.y+ejectionRect.size.height)];
    [ejectionMagnify lineToPoint:ejectionRect.origin];
    [ejectionMagnify closePath];
    
    NSPoint ejectionCenter = NSMakePoint(ejectionRect.origin.x + ejectionRect.size.width/2, ejectionRect.origin.y + ejectionRect.size.height/2);
    particleCenterScaled = NSMakePoint(targetScaled.x+(90*scale) + ejectionRect.size.width*scale/2, targetScaled.y-(20*scale) + ejectionRect.size.height*scale/2);
    
    targetShield = [NSBezierPath bezierPath];
    targetShieldArc = [NSBezierPath bezierPath];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:35.0 startAngle:0.0 endAngle:8.0];
    [targetShield moveToPoint:ejectionCenter];
    [targetShield lineToPoint:[targetShieldArc currentPoint]];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:35.0 startAngle:0.0 endAngle:28.0];
    [targetShield moveToPoint:ejectionCenter];
    [targetShield lineToPoint:[targetShieldArc currentPoint]];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:35.0 startAngle:0.0 endAngle:80.0];
    [targetShield moveToPoint:ejectionCenter];
    [targetShield lineToPoint:[targetShieldArc currentPoint]];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:35.0 startAngle:0.0 endAngle:100.0];
    [targetShield moveToPoint:ejectionCenter];
    [targetShield lineToPoint:[targetShieldArc currentPoint]];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:35.0 startAngle:0.0 endAngle:152.0];
    [targetShield moveToPoint:ejectionCenter];
    [targetShield lineToPoint:[targetShieldArc currentPoint]];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:35.0 startAngle:0.0 endAngle:172.0];
    [targetShield moveToPoint:ejectionCenter];
    [targetShield lineToPoint:[targetShieldArc currentPoint]];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:35.0 startAngle:0.0 endAngle:224.0];
    [targetShield moveToPoint:ejectionCenter];
    [targetShield lineToPoint:[targetShieldArc currentPoint]];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:35.0 startAngle:0.0 endAngle:244.0];
    [targetShield moveToPoint:ejectionCenter];
    [targetShield lineToPoint:[targetShieldArc currentPoint]];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:35.0 startAngle:0.0 endAngle:296.0];
    [targetShield moveToPoint:ejectionCenter];
    [targetShield lineToPoint:[targetShieldArc currentPoint]];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:35.0 startAngle:0.0 endAngle:316.0];
    [targetShield moveToPoint:ejectionCenter];
    [targetShield lineToPoint:[targetShieldArc currentPoint]];
    
    targetShieldBack = [NSBezierPath bezierPath];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:22.0 startAngle:0.0 endAngle:54.0];
    NSRect smallSquare = NSMakeRect(0, 0, 6.0, 6.0);
    smallSquare.origin.x = [targetShieldArc currentPoint].x - smallSquare.size.width/2;
    smallSquare.origin.y = [targetShieldArc currentPoint].y - smallSquare.size.height/2;
    [targetShieldBack appendBezierPathWithRect:smallSquare];
    
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:22.0 startAngle:0.0 endAngle:126.0];
    smallSquare.origin.x = [targetShieldArc currentPoint].x - smallSquare.size.width/2;
    smallSquare.origin.y = [targetShieldArc currentPoint].y - smallSquare.size.height/2;
    [targetShieldBack appendBezierPathWithRect:smallSquare];
    
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:22.0 startAngle:0.0 endAngle:270.0];
    smallSquare.size.width = 9.0;
    smallSquare.size.height = smallSquare.size.width;
    smallSquare.origin.x = [targetShieldArc currentPoint].x - smallSquare.size.width/2;
    smallSquare.origin.y = [targetShieldArc currentPoint].y - smallSquare.size.height/2;
    [targetShieldBack appendBezierPathWithRect:smallSquare];
    
    targetShieldBack2 = [NSBezierPath bezierPath];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:24.0 startAngle:0.0 endAngle:178.0];
    [targetShieldBack2 moveToPoint:[targetShieldArc currentPoint]];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:20.0 startAngle:0.0 endAngle:218.0];
    [targetShieldBack2 lineToPoint:[targetShieldArc currentPoint]];
    
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:20.0 startAngle:0.0 endAngle:322.0];
    [targetShieldBack2 moveToPoint:[targetShieldArc currentPoint]];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:24.0 startAngle:0.0 endAngle:2.0];
    [targetShieldBack2 lineToPoint:[targetShieldArc currentPoint]];

    [targetShieldArc removeAllPoints];
    [targetShieldArc appendBezierPathWithArcWithCenter:ejectionCenter radius:3.5 startAngle:0.0 endAngle:360.0];
    
    
    // create particle layer with scale
    particle = [CALayer layer];
    particle.backgroundColor = particleColor.CGColor;
    particle.position = phase1;
    particle.bounds = CGRectMake(0, 0, 5*scale, 5*scale);
    particle.cornerRadius = 2.5*scale;
    particle.speed = 1.0;
    particle.hidden = YES;
    [self.layer addSublayer:particle];
    
    // create phase 0 animation (injection)
    particleAnimationPhase0 = [CABasicAnimation animationWithKeyPath:@"position"];
    particleAnimationPhase0.fromValue = [NSValue valueWithPoint:phase0];
    particleAnimationPhase0.toValue = [NSValue valueWithPoint:phase1];
    particleAnimationPhase0.duration = 0.50;
    
    // create phase 1 particle animation path with scale
    CGMutablePathRef particlePhase1Path = CGPathCreateMutable();
    CGPathAddArc(particlePhase1Path, NULL, phase1CGPoint.x+(radius*scale), phase1CGPoint.y, radius*scale, M_PI*.999999999999, M_PI, true);
    
    // create phase 1 animation (acceleration)
    particleAnimationPhase1 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    particleAnimationPhase1.path = particlePhase1Path;
    particleAnimationPhase1.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    particleAnimationPhase1.duration=3.4; // magic number FTW!
    particleAnimationPhase1.repeatCount = 6.625;
    
    // create phase 2 animation (ejection)
    particleAnimationPhase2 = [CABasicAnimation animationWithKeyPath:@"position"];
    particleAnimationPhase2.fromValue = [NSValue valueWithPoint:phase2];
    particleAnimationPhase2.toValue = [NSValue valueWithPoint:targetScaled];
    
    // set up array of status messages
    statusMessages = @[@" Shield 9A.5f Ok",
                        @" Flux % 5.0177 Ok",
                        @"CDI Vector ok",
                        @"   %%%ddd ok",
                        @" Race-Track ok"];
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];

}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO]];
    
    if (layer == self.layer) {
        [displayTopColor setStroke];
        [NSBezierPath setDefaultLineWidth:2.0*scale];
        [NSBezierPath strokeRect:backOfCube];
        [NSBezierPath strokeLineFromPoint:frontPointA toPoint:backPointA];
        [NSBezierPath strokeLineFromPoint:backPointB toPoint:frontPointB];
        [NSBezierPath strokeLineFromPoint:frontPointC toPoint:backPointC];
        [NSBezierPath strokeLineFromPoint:backPointD toPoint:frontPointD];
        
        [topFill drawInBezierPath:topFace angle:270.0];
        [bottomFill drawInBezierPath:bottomFace angle:90.0];
        
//        [sideFill drawInBezierPath:leftFace angle:270.0];
//        [sideFill drawInBezierPath:rightFace angle:270.0];
    
//        [overlay drawInBezierPath:leftFace angle:0.0];
//        [overlay drawInBezierPath:rightFace angle:180.0];
//        [overlay drawInBezierPath:topFace angle:270.0];
    } else if (layer == drawLayer) {
        if (drawRooms) {
            [textDark2Color setStroke];
            [room3 setLineWidth:1.5*scale];
            [room1 setLineWidth:1.5*scale];
            [room3 stroke];
            [room3XBox stroke];
            [room1 stroke];
            [room1XBox stroke];
            
            [textColor setStroke];
            [room3X stroke];
            [room1X stroke];
            
            NSString *room3Label = @"room 3";
            NSAttributedString *room3LabelAttr = [[NSAttributedString alloc] initWithString:room3Label attributes:textRoomAttrs];
            [room3LabelAttr drawAtPoint:room3LabelPoint];
            
            NSString *room1Label = @"room 1";
            NSAttributedString *room1LabelAttr = [[NSAttributedString alloc] initWithString:room1Label attributes:textRoomAttrs];
            [room1LabelAttr drawAtPoint:room1LabelPoint];
        }
        
        if (drawSynchrotron) {
            NSString *labBLabel = @"lab";
            NSAttributedString *labBLabelAttr = [[NSAttributedString alloc] initWithString:labBLabel attributes:textRoomAttrs];
            [labBLabelAttr drawAtPoint:labBLabelPoint];
            
            [transform set];
            
            [synchrotronColor set];
            [synchrotron setLineWidth:5.0];
            [synchrotron stroke];
            
            [textColor set];
            [labB setLineWidth:20.0];
            [labA setLineWidth:20.0];
            [labB stroke];
            [labA stroke];
            
            [displayBGColor setStroke];
            [synchrotron setLineWidth:1.0];
            [synchrotron stroke];
            
            if (drawEjection) {
                [displayBGAlphaColor set];
                [ejectionMagnify fill];
                
                [synchrotronColor set];
                [ejectionView setLineWidth:1.5];
                [ejectionView stroke];
                [targetShieldBack fill];
                [targetShieldBack2 setLineWidth:1.5];
                [targetShieldBack2 stroke];

                [textColor set];
                [targetShield setLineWidth:1.5];
                [targetShield stroke];
                
                [displayBGColor set];
                [targetShieldArc fill];
            }
        }
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawRect:(NSRect)rect
{
//    [super drawRect:rect];
    
}


// this method gets called 30 times per second based on our timer set up in the initWithFrame:isPreview:
- (void)animateOneFrame
{
    switch (frameCounter)
    {
            
            //        case 1:   // font color testing
            //        {
            //            NSAttributedString *string1 = [[NSAttributedString alloc] initWithString:@"Dark Text\n" attributes:textDarkAttrs];
            //            NSAttributedString *string2 = [[NSAttributedString alloc] initWithString:@"Normal Text\n" attributes:textNormalAttrs];
            //            NSAttributedString *string3 = [[NSAttributedString alloc] initWithString:@"Highlighted Text\n" attributes:textHighlightAttrs];
            //            NSAttributedString *string4 = [[NSAttributedString alloc] initWithString:@"Dark Text 2\n" attributes:textDark2Attrs];
            //            [mainTextStorage appendAttributedString:string1];
            //            [mainTextStorage appendAttributedString:string2];
            //            [mainTextStorage appendAttributedString:string3];
            //            [mainTextStorage appendAttributedString:string4];
            //            drawSynchrotron = YES;
            //            frameCounter = 0;
            //            break;
            //        }
        case 10:    // copyright message
        {
            // appending the existing NSTextStorage
            NSString *copyright = @"Copyright  © 1990 Peanut Computer, Inc.\nAll Rights reserved.\n\nCDOS Version 5.01";
            NSAttributedString *copyrightAttr = [[NSAttributedString alloc] initWithString:copyright attributes:textNormalAttrs];
            [mainTextStorage appendAttributedString:copyrightAttr];
            break;
        }
        case 40:    // display prompt
        {
            // the # character is drawn as a full block in the font we are using
            NSString *prompt = @"\n\n\n\n\n\n\n\n\n\n\n\n\n> #";
            NSAttributedString *promptAttr = [[NSAttributedString alloc] initWithString:prompt attributes:textNormalAttrs];
            [mainTextStorage appendAttributedString:promptAttr];
            
            // highlight cursor
            NSRange cursorPos = [[mainTextStorage string] rangeOfString:@"#"];
            [mainTextStorage addAttributes:cursorAttrs range:cursorPos];
            break;
        }
        case 70 ... 96: // RUN PROJECT 23
            if (frameCounter % 2 == 0) {
                [mainTextStorage replaceCharactersInRange:NSMakeRange([mainTextStorage length] - 1, 0)
                                               withString:[@"RUN PROJECT 23" substringWithRange:NSMakeRange(index, 1)]];
                index ++; // character index within "RUN PROJECT 23"
            }
            break;
        case 106:   // carriage return
            [mainTextStorage replaceCharactersInRange:NSMakeRange([mainTextStorage length] - 1, 0)
                                           withString:@"\n  "];
            index = 0; // reset index for next use
            break;
        case 136:   // clear screen
            [mainTextStorage deleteCharactersInRange:NSMakeRange(0, [mainTextStorage length])];
            drawRooms = YES;
            [drawLayer setNeedsDisplay];
            break;

            // add room3 and room1 constructs here
            
        case 146:   // display modification parameters
        {
            NSString *modification = @"\nMODIFICATION OF PARAMETERS RELATING TO\nPARTICLE ACCELERATOR (SYNCHROTRON) .\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
            NSAttributedString *modificationAttr = [[NSAttributedString alloc] initWithString:modification attributes:textNormalAttrs];
            [mainTextStorage appendAttributedString:modificationAttr];
            
            NSString *parameters = @" \n\n\n\nE: 23%#\ng: .005\n\nRK: 77.2L\n\nopt: g+\n\n Shield:\n1: OFF\n2: ON\n3: ON\n\nPΩ: 1";
            NSAttributedString *parametersAttr = [[NSAttributedString alloc] initWithString:parameters attributes:textNormalAttrs];
            [rightTextStorage appendAttributedString:parametersAttr];
            
            // highlight cursor
            NSRange cursorPos = [[rightTextStorage string] rangeOfString:@"#"];
            [rightTextStorage addAttributes:cursorAttrs range:cursorPos];
            
            break;
        }
        case 176:   // move cursor down
        case 196:   // move cursor down
        case 198:   // move cursor down
        case 237:   // move cursor down
        case 257:   // move cursor down
        case 259:   // move cursor down
        case 260:   // move cursor down
        {
            // init C style array of pre-defined cursor locations within rightTextStorage
            NSInteger nextPos[7] = {19, 30, 39, 56, 62, 68, 75};
            //            NSInteger nextPos[7] = {19, 30, 39, 56, 62, 68, 75};
            // find current cursor position and remove it
            NSRange cursorPos = [[rightTextStorage string] rangeOfString:@"#"];
            [rightTextStorage deleteCharactersInRange:cursorPos];
            // insert cursor at next pre-defined location
            [rightTextStorage replaceCharactersInRange:NSMakeRange(nextPos[index], 0) withString:@"#"];
            // highlight cursor
            cursorPos = [[rightTextStorage string] rangeOfString:@"#"];
            [rightTextStorage addAttributes:cursorAttrs range:cursorPos];
            index ++; // index of pre-defined cursor locations
            break;
        }
        case 215:   // delete "+"
            [rightTextStorage deleteCharactersInRange:NSMakeRange(38, 1)];
            break;
        case 217:   // insert "-"
            [rightTextStorage replaceCharactersInRange:NSMakeRange(38, 0) withString:@"-"];
            break;
        case 280:   // delete cursor at end
            [rightTextStorage deleteCharactersInRange:NSMakeRange(75,1)];
            index = 0; // reset index for next use
            break;
        case 281:   // display run experiment
        {
            NSString *runExperiment = @"RUN EXPERIMENT ?";
            NSAttributedString *runExperimentAttr = [[NSAttributedString alloc] initWithString:runExperiment attributes:textNormalAttrs];
            [mainTextStorage appendAttributedString:runExperimentAttr];
            
            NSRange position = [[mainTextStorage string] rangeOfString:@"RUN EXPERIMENT ?"];
            [mainTextStorage addAttributes:textCenteredAttrs range:position];
            break;
        }
        case 291:   // blank run experiment
        {
            NSRange position = [[mainTextStorage string] rangeOfString:@"RUN EXPERIMENT ?"];
            [mainTextStorage addAttributes:textBlankAttrs range:position];
            
            if (index == 2) {
                frameCounter = 311; // exit blank/unblank loop, frameCounter will be incremented after break
                index =0; // reset index for next use
            }
            break;
        }
        case 301:   // unblank run experiment
        {
            NSRange position = [[mainTextStorage string] rangeOfString:@"RUN EXPERIMENT ?"];
            [mainTextStorage setAttributes:textNormalAttrs range:position];
            [mainTextStorage addAttributes:textCenteredAttrs range:position];
            
            if (index == 1) {
                NSRange position = [[mainTextStorage string] rangeOfString:@"RUN EXPERIMENT ?"];
                [mainTextStorage replaceCharactersInRange:position withString:@"                                        RUN EXPERIMENT ?                                      Y"];
                [mainTextStorage addAttributes:textCenteredAttrs range:position];
            }
            break;
        }
        case 311:   // loop back to frame 291
            frameCounter = 290; // frameCounter will be incremented after break
            index++ ; // index used as blank/unblank loop counter
            
            break;
        case 321:   // clear screen
            [mainTextStorage deleteCharactersInRange:NSMakeRange(0, [mainTextStorage length])];
            [rightTextStorage deleteCharactersInRange:NSMakeRange(0, [rightTextStorage length])];
            drawSynchrotron = YES;
            [drawLayer setNeedsDisplay];
            break;
        case 322:   // phase 0: INJECTION
        {
            NSString *phase0 = @"- - -  T h e o r e t i c a l   s t u d y  - - -\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n- Phase 0:\nINJECTION of particles\ninto synchrotron";
            NSAttributedString *phase0Attr = [[NSAttributedString alloc] initWithString:phase0 attributes:textNormalAttrs];
            [mainTextStorage appendAttributedString:phase0Attr];
            
            NSRange position = [[mainTextStorage string] rangeOfString:@"- - -  T h e o r e t i c a l   s t u d y  - - -"];
            [mainTextStorage addAttributes:textCenteredAttrs range:position];
            
            particle.hidden = NO;
            [particle addAnimation:particleAnimationPhase0 forKey:@"position"];
            break;
        }
        case 337:   // phase 1: ACCELERATION
        {
            NSRange phaseRange = [[mainTextStorage string] rangeOfString:@"- Phase 0:\nINJECTION of particles\ninto synchrotron"];
            [mainTextStorage replaceCharactersInRange:phaseRange withString:@"\n- Phase 1:\nParticle ACCELERATION."];
            [particle addAnimation:particleAnimationPhase1 forKey:@"position"];
            break;
        }
            // particle acceleration
        case 341:   // +3 frames from previous
        case 344:   // +3
        case 347:   // +3
        case 350:   // +3
        case 356:   // +6
        case 362:   // +6
        case 368:   // +6
        case 374:   // +6
        case 386:   // +12
        case 398:   // +12
        case 410:   // +12
        case 422:   // +12
        case 434:   // +12
        case 446:   // +12
            particle.timeOffset = [particle convertTime:CACurrentMediaTime() fromLayer:self.layer];
            particle.beginTime = CACurrentMediaTime();
            particle.speed *= 1.1;
            break;
        case 540:
            drawEjection = YES;
            [drawLayer setNeedsDisplay];
            break;
        case 541:   // phase 2: EJECTION
        {
            NSRange phaseRange = [[mainTextStorage string] rangeOfString:@"\n- Phase 1:\nParticle ACCELERATION."];
            [mainTextStorage replaceCharactersInRange:phaseRange withString:@"- Phase 2:\nEJECTION of particles\non the shield."];
            break;
        }
        case 557:   // particle ejection
            particle.position = ejectionMagnifyPointScaled;
            [particle addAnimation:particleAnimationPhase2 forKey:@"position"];
            break;
        // particle explosion
        case 560:
            particle.opacity = 0.7;
            particle.bounds = CGRectMake(0, 0, 5*scale*1.5, 5*scale*1.5);
            particle.cornerRadius = 2.5*scale*1.5;
            break;
        case 562:
            particle.hidden = YES;
            particle.position = particleCenterScaled;
            particle.bounds = CGRectMake(0, 0, 5*scale*2, 5*scale*2);
            particle.cornerRadius = 2.5*scale*2;
            break;
        case 564:
            particle.hidden = NO;
            break;
        case 566:
            particle.bounds = CGRectMake(0, 0, 5*scale*3, 5*scale*3);
            particle.cornerRadius = 2.5*scale*3;
            break;
        case 568:
            particle.opacity = 0.6;
            particle.bounds = CGRectMake(0, 0, 5*scale*5, 5*scale*5);
            particle.cornerRadius = 2.5*scale*5;
            break;
        case 570:
            particle.opacity = 0.5;
            particle.bounds = CGRectMake(0, 0, 5*scale*9, 5*scale*9);
            particle.cornerRadius = 2.5*scale*9;
            break;
        case 572:
            particle.bounds = CGRectMake(0, 0, 5*scale*13, 5*scale*13);
            particle.cornerRadius = 2.5*scale*15;
            break;
        case 574:
            particle.hidden = YES;
            particle.opacity = 1.0;
            particle.bounds = CGRectMake(0, 0, 5*scale, 5*scale);
            particle.cornerRadius = 2.5*scale;
            break;
        case 601:   // ANALYSIS
        {
            NSRange phaseRange = [[mainTextStorage string] rangeOfString:@"- Phase 2:\nEJECTION of particles\non the shield."];
            
            NSString *analysis = @"A    N    A    L    Y    S    I    S";
            [mainTextStorage replaceCharactersInRange:phaseRange withString:analysis];
            NSRange position = [[mainTextStorage string] rangeOfString:analysis];
            [mainTextStorage addAttributes:textCenteredAttrs range:position];
            
            [particle removeAllAnimations];
            particle.timeOffset = [particle convertTime:CACurrentMediaTime() fromLayer:self.layer];
            particle.beginTime = CACurrentMediaTime();
            particle.speed = 1.0;
            break;
        }
        case 661:   // RESULTS
        {
            NSRange phaseRange = [[mainTextStorage string] rangeOfString:@"\n\nA    N    A    L    Y    S    I    S"];
            [mainTextStorage replaceCharactersInRange:phaseRange withString:@"- RESULT:\nProbability of creating:\n ANTIMATTER: 91.V %\n NEUTRINO 27:  0.04 %\n NEUTRINO 424: 18 %"];
            break;
        }
        case 689:
            drawEjection = NO;
            [drawLayer setNeedsDisplay];
            break;
        case 690:   // The experiment will begin in..
        {
            [mainTextStorage deleteCharactersInRange:NSMakeRange(0, [mainTextStorage length])];
            NSString *experiment = @"THE   EXPERIMENT   WILL   BEGIN   IN   20   SECONDS";
            NSString *experimentPost = [NSString stringWithFormat:@"\n\n\n\n\n\n\n\n%@\n\n\n\n\n\n\n\n\n                                   ", experiment];
            NSAttributedString *experimentAttr = [[NSAttributedString alloc] initWithString:experimentPost attributes:textNormalAttrs];
            [mainTextStorage appendAttributedString:experimentAttr];
            NSRange position = [[mainTextStorage string] rangeOfString:experiment];
            [mainTextStorage addAttributes:textCenteredAttrs range:position];
            break;
        }
        case 720 ... 1320:  // 20 second countdown
        {
            // countdown 1 second every 30 frames
            if (frameCounter < 1291 && frameCounter % 30 == 0) {
                NSString *seconds = [NSString stringWithFormat:@"%lu", (long)counter];
                NSRange secondsRange = [[mainTextStorage string] rangeOfString:seconds];
                counter --;
                [mainTextStorage replaceCharactersInRange:secondsRange withString:[NSString stringWithFormat:@"%lu", (long)counter]];
                
                if (counter == 0){
                    [mainTextStorage addAttributes:textHighlightAttrs range:secondsRange];
                }
            }
            
            // cycle status messages
            if (frameCounter == 1140) {
                currentStatus = statusMessages[index];
                NSAttributedString *currentStatusAttr = [[NSAttributedString alloc] initWithString:currentStatus attributes:textDark2Attrs];
                [mainTextStorage appendAttributedString:currentStatusAttr];
                index++; // statusMessage index
            } else if (frameCounter > 1140 && frameCounter % 4 == 0) {
                NSRange statusRange = [[mainTextStorage string] rangeOfString:currentStatus];
                currentStatus = statusMessages[index];
                [mainTextStorage replaceCharactersInRange:statusRange withString:currentStatus];
                
                if (index < 4) {
                    index ++; // statusMessage index
                } else {
                    index = 0; // statusMessage index
                }
            }
            
            // remove countdown, start experiment
            if (frameCounter == 1302) {
                NSRange countdownRange = [[mainTextStorage string] rangeOfString:@"THE   EXPERIMENT   WILL   BEGIN   IN   0   SECONDS"];
                [mainTextStorage deleteCharactersInRange:countdownRange];
                particle.hidden = NO;
                [particle addAnimation:particleAnimationPhase0 forKey:@"position"];
                
            }
            
            if (frameCounter == 1317) {
                // experiment phase 1
                [particle addAnimation:particleAnimationPhase1 forKey:@"position"];
            }
            
            break;
        }
            // experiment particle acceleration
        case 1321:   // +3 frames from previous
            // clear status messages
            [mainTextStorage deleteCharactersInRange:NSMakeRange(0, [mainTextStorage length])];
        case 1324:   // +3
        case 1327:   // +3
        case 1330:   // +3
        case 1336:   // +6
        case 1342:   // +6
        case 1348:   // +6
        case 1354:   // +6
        case 1366:   // +12
        case 1378:   // +12
        case 1390:   // +12
        case 1402:   // +12
        case 1414:   // +12
        case 1426:   // +12
            particle.timeOffset = [particle convertTime:CACurrentMediaTime() fromLayer:self.layer];
            particle.beginTime = CACurrentMediaTime();
            particle.speed *= 1.1;
            break;
        case 1535:   // experiment particle ejection
            [particle addAnimation:particleAnimationPhase2 forKey:@"position"];
            break;
        case 1536:
            particle.hidden = YES;
            break;
        case 1700:
            // reset and clear screen
            index = 0; // re-usable general purpose index for use within frame logic
            counter = 20; // 20 second countdown timer
            drawSynchrotron = NO;
            drawRooms = NO;
            drawEjection = NO;
            [drawLayer setNeedsDisplay];
            [particle removeAllAnimations];
            particle.timeOffset = [particle convertTime:CACurrentMediaTime() fromLayer:self.layer];
            particle.beginTime = CACurrentMediaTime();
            particle.speed = 1.0;
            break;
        case 1715:
            // reset frameCounter to restart loop
            frameCounter = 0;
            break;
        default:
            break;
    }
    
    frameCounter ++;

    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

- (BOOL)isOpaque {
    // this keeps Cocoa from unneccessarily redrawing our superview
    return YES;
}

@end
