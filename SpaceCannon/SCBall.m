//
//  SCBall.m
//  SpaceCannon
//
//  Created by Roberto Silva on 12/12/14.
//  Copyright (c) 2014 HE:mobile. All rights reserved.
//

#import "SCBall.h"

@implementation SCBall

- (void)updateTrail
{
    if (self.trail) {
        self.trail.position = self.position;
    }
}

- (void)removeFromParent
{
    if (self.trail) {
        self.trail.particleBirthRate = 0.0;
        
        SKAction *removeTrail = [SKAction sequence:@[[SKAction waitForDuration:self.trail.particleLifetime + self.trail.particleLifetimeRange], [SKAction removeFromParent]]];
        
        [self runAction:removeTrail];
    }
    
    
    [super removeFromParent];
}

@end
