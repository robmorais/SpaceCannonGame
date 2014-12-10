//
//  SCMenu.m
//  SpaceCannon
//
//  Created by Roberto Silva on 10/12/14.
//  Copyright (c) 2014 HE:mobile. All rights reserved.
//

#import "SCMenu.h"

@implementation SCMenu
{
    SKLabelNode *_scoreLabel;
    SKLabelNode *_topScoreLabel;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        SKSpriteNode *title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        title.position = CGPointMake(0, 140);
        [self addChild:title];
        
        SKSpriteNode *scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
        scoreBoard.position = CGPointMake(0, 70);
        [self addChild:scoreBoard];
        
        SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        playButton.name = @"PlayButton";
        playButton.position = CGPointMake(0, 0);
        [self addChild:playButton];
        
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _scoreLabel.fontSize = 30.0;
        _scoreLabel.position = CGPointMake(-52.0, 50);
        [self addChild:_scoreLabel];
        
        _topScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _topScoreLabel.fontSize = 30.0;
        _topScoreLabel.position = CGPointMake(48, 50);
        [self addChild:_topScoreLabel];
        
        // Starting values
        self.score = 0;
        self.topScore = 0;
    }
    
    return self;
}

- (void)setScore:(int)score
{
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"%d",_score];
}

- (void)setTopScore:(int)topScore
{
    _topScore = topScore;
    _topScoreLabel.text = [NSString stringWithFormat:@"%d",_topScore];
}

@end
