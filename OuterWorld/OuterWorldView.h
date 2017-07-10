//
//  OuterWorldView.h
//  OuterWorld
//
//  Created by k1ds3ns4t10n on 4/20/17.
//  Copyright © 2017 Gameaholix. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>
#import <Quartzcore/Quartzcore.h>

@interface OuterWorldView : ScreenSaverView
{
    BOOL drawSynchrotron;
    BOOL drawRooms;
    BOOL drawEjection;
    
    NSColor *synchrotronColor;
    NSColor *particleColor;
    NSColor *textHighlightColor;
    NSColor *textColor;
    NSColor *textDarkColor;
    NSColor *textDark2Color;
    NSColor *displayBGColor;
    NSColor *displayBGAlphaColor;
    NSColor *displayTopColor;
    NSColor *displayBottomColor;
    
    NSGradient *topFill;
    NSGradient *sideFill;
    NSGradient *bottomFill;
    NSGradient *overlay;
    
    NSUInteger frameCounter;
    NSUInteger counter;
    NSUInteger index;
    
    NSRect nativeRect;
    NSRect mainDisplayRect;
    NSRect rightDisplayRect;
    NSRect backOfCube;
    
    CGFloat scale;
    
    CALayer *drawLayer;
    
    NSDictionary *textNormalAttrs;
    NSDictionary *textBlankAttrs;
    NSDictionary *textDarkAttrs;
    NSDictionary *textDark2Attrs;
    NSDictionary *textHighlightAttrs;
    NSDictionary *textRoomAttrs;
    NSDictionary *textCenteredAttrs;
    NSDictionary *textRightAttrs;
    NSDictionary *cursorAttrs;
    
    NSTextStorage *mainTextStorage;
    NSTextStorage *rightTextStorage;
    
    NSTextView *mainTextView;
    NSTextView *rightTextView;
    
    NSAffineTransform *transform;
    
    NSPoint frontPointA;
    NSPoint frontPointB;
    NSPoint frontPointC;
    NSPoint frontPointD;
    
    NSPoint backPointA;
    NSPoint backPointB;
    NSPoint backPointC;
    NSPoint backPointD;
    
    NSBezierPath *topFace;
    NSBezierPath *bottomFace;
    NSBezierPath *leftFace;
    NSBezierPath *rightFace;
    
    NSPoint room3LabelPoint;
    NSPoint room1LabelPoint;
    NSBezierPath *room3;
    NSBezierPath *room1;
    NSBezierPath *room3XBox;
    NSBezierPath *room3X;
    NSBezierPath *room1XBox;
    NSBezierPath *room1X;

    NSBezierPath *synchrotron;
    NSBezierPath *labA;
    NSBezierPath *labB;
    NSBezierPath *ejectionView;
    NSBezierPath *ejectionMagnify;
    NSPoint ejectionMagnifyPointScaled;
    NSPoint particleCenterScaled;
    NSBezierPath *targetShield;
    NSBezierPath *targetShieldArc;
    NSBezierPath *targetShieldBack;
    NSBezierPath *targetShieldBack2;
    
    NSPoint labBLabelPoint;
    NSPoint phase2;

    CALayer *particle;
    CABasicAnimation *particleAnimationPhase0;
    CAKeyframeAnimation *particleAnimationPhase1;
    CABasicAnimation *particleAnimationPhase2;
    
    NSArray *statusMessages;
    NSString *currentStatus;
}

@end
