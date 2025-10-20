//
//  DhammapadaScreenSaverView.h
//  DhammapadaScreenSaver
//
//  Created by dpc on 2025-10-20.
//

#import <ScreenSaver/ScreenSaver.h>

@interface DhammapadaScreenSaverView : ScreenSaverView {
    NSInteger currentVerseIndex;
    CGFloat fadeAlpha;
    NSMutableArray *particlePositions;
    CGFloat animationPhase;
    NSArray *verseDatabase;
    NSTimer *verseChangeTimer;
}

@end
