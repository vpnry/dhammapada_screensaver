//
//  DhammapadaScreenSaverView.m
//  DhammapadaScreenSaver
//
//  Created by dpc on 2025-10-20.
//
#import "DhammapadaScreenSaverView.h"
#import "VerseDatabase.h"

@implementation DhammapadaScreenSaverView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/60.0];
        
        // Load verse database from external file so it can be edited separately.
        verseDatabase = kDhammapadaVerseDatabase;

        // Select random verse
        currentVerseIndex = arc4random_uniform((uint32_t)[verseDatabase count]);
        
        // Initialize fade alpha
        fadeAlpha = 0.0;
        animationPhase = 0.0;
        
        // Initialize particles (lotus petals falling)
        particlePositions = [NSMutableArray array];
        for (int i = 0; i < 40; i++) {
            CGFloat x = (CGFloat)arc4random_uniform((uint32_t)frame.size.width);
            CGFloat y = (CGFloat)arc4random_uniform((uint32_t)frame.size.height);
            CGFloat speed = 0.15 + ((CGFloat)arc4random_uniform(60) / 100.0);
            CGFloat rotation = (CGFloat)arc4random_uniform(360);
            CGFloat rotationSpeed = -2.0 + ((CGFloat)arc4random_uniform(40) / 10.0);
            [particlePositions addObject:@{
                @"x": @(x),
                @"y": @(y),
                @"speed": @(speed),
                @"rotation": @(rotation),
                @"rotationSpeed": @(rotationSpeed)
            }];
        }
        
        // Change verse every 30 seconds (not in preview)
        if (!isPreview) {
            verseChangeTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                                target:self
                                                              selector:@selector(changeVerse)
                                                              userInfo:nil
                                                               repeats:YES];
        }
    }
    return self;
}

- (void)changeVerse
{
    fadeAlpha = 0.0;
    currentVerseIndex = arc4random_uniform((uint32_t)[verseDatabase count]);
}

- (void)dealloc
{
    [verseChangeTimer invalidate];
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    
    // Draw gradient background (saffron/gold Buddhist colors)
    NSGradient *gradient = [[NSGradient alloc] initWithColors:@[
        [NSColor colorWithRed:0.15 green:0.10 blue:0.20 alpha:1.0],
        [NSColor colorWithRed:0.25 green:0.15 blue:0.30 alpha:1.0],
        [NSColor colorWithRed:0.20 green:0.12 blue:0.25 alpha:1.0]
    ]];
    [gradient drawInRect:self.bounds angle:-45];
    
    // Draw lotus petals
    [self drawParticles];
    
    // Get current verse data
    NSDictionary *currentVerse = verseDatabase[currentVerseIndex];
    NSString *pali = currentVerse[@"pali"];
    NSString *entrans = currentVerse[@"entrans"];
    NSString *vitrans = currentVerse[@"vitrans"];
    NSString *verse = currentVerse[@"verse"];
    NSString *chapter = currentVerse[@"chapter"];
    
    // Calculate center positions
    CGFloat centerX = self.bounds.size.width / 2;
    CGFloat centerY = self.bounds.size.height / 2;
    CGFloat maxWidth = self.bounds.size.width * 0.8;
    
    // Scale fonts for preview mode
    CGFloat scale = self.isPreview ? 0.35 : 1.0;
    
    // Draw verse number and chapter at top
    NSFont *verseFont = [NSFont systemFontOfSize:18 * scale weight:NSFontWeightMedium];
    NSDictionary *verseAttributes = @{
        NSFontAttributeName: verseFont,
        NSForegroundColorAttributeName: [[NSColor colorWithRed:0.9 green:0.7 blue:0.4 alpha:1.0] colorWithAlphaComponent:fadeAlpha * 0.9]
    };
    NSString *verseInfo = [NSString stringWithFormat:@"TipitakaPali.org • Dhammapada %@ • %@", verse, chapter];
    NSAttributedString *verseString = [[NSAttributedString alloc] initWithString:verseInfo attributes:verseAttributes];
    NSSize verseSize = [verseString size];
    NSRect verseRect = NSMakeRect(centerX - verseSize.width / 2,
                                   self.bounds.size.height - 80 * scale,
                                   verseSize.width,
                                   verseSize.height);
    [verseString drawInRect:verseRect];
    
    // Draw Pali text (centered, multiple lines)
    NSFont *paliFont = [NSFont fontWithName:@"Georgia" size:24 * scale] ?: [NSFont systemFontOfSize:24 * scale weight:NSFontWeightLight];
    NSMutableParagraphStyle *paliStyle = [[NSMutableParagraphStyle alloc] init];
    [paliStyle setAlignment:NSTextAlignmentCenter];
    [paliStyle setLineSpacing:8 * scale];
    NSDictionary *paliAttributes = @{
        NSFontAttributeName: paliFont,
        NSForegroundColorAttributeName: [[NSColor colorWithRed:1.0 green:0.95 blue:0.8 alpha:1.0] colorWithAlphaComponent:fadeAlpha],
        NSParagraphStyleAttributeName: paliStyle
    };
    NSAttributedString *paliString = [[NSAttributedString alloc] initWithString:pali attributes:paliAttributes];
    NSSize paliSize = [paliString boundingRectWithSize:NSMakeSize(maxWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin].size;
    NSRect paliRect = NSMakeRect(centerX - maxWidth / 2,
                                  centerY + 120 * scale,
                                  maxWidth,
                                  paliSize.height);
    [paliString drawInRect:paliRect];
    
    // Draw English translation
    NSFont *enFont = [NSFont systemFontOfSize:18 * scale weight:NSFontWeightRegular];
    NSMutableParagraphStyle *enStyle = [[NSMutableParagraphStyle alloc] init];
    [enStyle setAlignment:NSTextAlignmentCenter];
    [enStyle setLineSpacing:6 * scale];
    [enStyle setLineBreakMode:NSLineBreakByWordWrapping];
    NSDictionary *enAttributes = @{
        NSFontAttributeName: enFont,
        NSForegroundColorAttributeName: [[NSColor colorWithRed:0.85 green:0.90 blue:1.0 alpha:1.0] colorWithAlphaComponent:fadeAlpha * 0.95],
        NSParagraphStyleAttributeName: enStyle
    };
    NSAttributedString *enString = [[NSAttributedString alloc] initWithString:entrans attributes:enAttributes];
    NSSize enSize = [enString boundingRectWithSize:NSMakeSize(maxWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading].size;
    enSize.width = ceil(enSize.width);
    enSize.height = ceil(enSize.height);
    NSRect enRect = NSMakeRect(centerX - maxWidth / 2,
                               centerY - 20 * scale,
                               maxWidth,
                               enSize.height);
    [enString drawInRect:enRect];
    
    // Draw Vietnamese translation (match English style)
    NSFont *viFont = [NSFont systemFontOfSize:18 * scale weight:NSFontWeightRegular];
    NSMutableParagraphStyle *viStyle = [[NSMutableParagraphStyle alloc] init];
    [viStyle setAlignment:NSTextAlignmentCenter];
    [viStyle setLineSpacing:6 * scale];
    [viStyle setLineBreakMode:NSLineBreakByWordWrapping];
    NSDictionary *viAttributes = @{
        NSFontAttributeName: viFont,
        NSForegroundColorAttributeName: [[NSColor colorWithRed:0.85 green:0.90 blue:1.0 alpha:1.0] colorWithAlphaComponent:fadeAlpha * 0.95],
        NSParagraphStyleAttributeName: viStyle
    };
    NSAttributedString *viString = [[NSAttributedString alloc] initWithString:vitrans attributes:viAttributes];
    NSSize viSize = [viString boundingRectWithSize:NSMakeSize(maxWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading].size;
    viSize.width = ceil(viSize.width);
    viSize.height = ceil(viSize.height);
    NSRect viRect = NSMakeRect(centerX - maxWidth / 2,
                               centerY - enSize.height - 80 * scale,
                               maxWidth,
                               viSize.height);
    [viString drawInRect:viRect];
}

- (void)drawParticles
{
    // Draw lotus petal-like particles with golden color
    for (NSDictionary *particle in particlePositions) {
        CGFloat x = [particle[@"x"] doubleValue];
        CGFloat y = [particle[@"y"] doubleValue];
        CGFloat rotation = [particle[@"rotation"] doubleValue];
        
        NSGraphicsContext *context = [NSGraphicsContext currentContext];
        [context saveGraphicsState];
        
        // Translate and rotate
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:x yBy:y];
        [transform rotateByDegrees:rotation];
        [transform concat];
        
        // Draw petal shape
        NSBezierPath *petal = [NSBezierPath bezierPath];
        [petal moveToPoint:NSMakePoint(0, -6)];
        [petal curveToPoint:NSMakePoint(3, 0)
              controlPoint1:NSMakePoint(2, -6)
              controlPoint2:NSMakePoint(3, -3)];
        [petal curveToPoint:NSMakePoint(0, 6)
              controlPoint1:NSMakePoint(3, 3)
              controlPoint2:NSMakePoint(2, 6)];
        [petal curveToPoint:NSMakePoint(-3, 0)
              controlPoint1:NSMakePoint(-2, 6)
              controlPoint2:NSMakePoint(-3, 3)];
        [petal curveToPoint:NSMakePoint(0, -6)
              controlPoint1:NSMakePoint(-3, -3)
              controlPoint2:NSMakePoint(-2, -6)];
        [petal closePath];
        
        [[NSColor colorWithRed:0.9 green:0.7 blue:0.4 alpha:0.2] setFill];
        [petal fill];
        
        [context restoreGraphicsState];
    }
}

- (void)animateOneFrame
{
    // Fade in animation
    if (fadeAlpha < 1.0) {
        fadeAlpha += 0.008;
    }
    
    // Animate lotus petals
    for (NSInteger i = 0; i < [particlePositions count]; i++) {
        NSMutableDictionary *particle = [particlePositions[i] mutableCopy];
        CGFloat x = [particle[@"x"] doubleValue];
        CGFloat y = [particle[@"y"] doubleValue];
        CGFloat speed = [particle[@"speed"] doubleValue];
        CGFloat rotation = [particle[@"rotation"] doubleValue];
        CGFloat rotationSpeed = [particle[@"rotationSpeed"] doubleValue];
        
        y -= speed;
        rotation += rotationSpeed;
        
        // Add slight horizontal drift
        x += sin(animationPhase + i) * 0.3;
        
        // Reset particle if it goes off screen
        if (y < -10) {
            y = self.bounds.size.height + 10;
            x = (CGFloat)arc4random_uniform((uint32_t)self.bounds.size.width);
        }
        
        // Keep x within bounds
        if (x < -10) x = self.bounds.size.width + 10;
        if (x > self.bounds.size.width + 10) x = -10;
        
        particle[@"x"] = @(x);
        particle[@"y"] = @(y);
        particle[@"rotation"] = @(rotation);
        particlePositions[i] = particle;
    }
    
    // Update animation phase
    animationPhase += 0.01;
    if (animationPhase > M_PI * 2) {
        animationPhase = 0;
    }
    
    [self setNeedsDisplay:YES];
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

@end
