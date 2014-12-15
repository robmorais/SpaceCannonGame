//
//  SCBall.h
//  SpaceCannon
//
//  Created by Roberto Silva on 12/12/14.
//  Copyright (c) 2014 HE:mobile. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SCBall : SKSpriteNode

@property (nonatomic, strong) SKEmitterNode *trail;
@property (nonatomic) int bounces;

- (void)updateTrail;

@end
