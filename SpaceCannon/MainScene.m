//
//  MainScene.m
//  SpaceCannon
//
//  Created by Roberto Silva on 24/11/14.
//  Copyright (c) 2014 HE:mobile. All rights reserved.
//

#import "MainScene.h"

static const CGFloat SHOOT_SPEED = 1000.0;
static const CGFloat kSCHaloLowAngle = 200.0 * M_PI/180.0;
static const CGFloat kSCHaloHighAngle = 340.0 * M_PI/180.0;
static const CGFloat kSCHaloSpeed = 100.0;

// Colision Bitmaks
static const uint32_t kSCHaloCategory = 0x1 << 0;
static const uint32_t kSCBallCategory = 0x1 << 1;
static const uint32_t kSCEdgeCategory = 0x1 << 2;

@interface MainScene()
@property (nonatomic) int ammo;
@end

@implementation MainScene
{
    SKNode *_mainLayer;
    SKSpriteNode *_cannon;
    SKSpriteNode *_ammoDisplay;
    BOOL _shoot;
}

static inline CGVector radiansToVector(CGFloat radians)
{
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    
    return vector;
}

static inline CGFloat randomInRange(CGFloat low, CGFloat high) {
    CGFloat randomValue = arc4random_uniform(UINT32_MAX)/(CGFloat)UINT32_MAX;
    return low + (high -low) * randomValue ;
}

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        // Turn off gravity
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
        self.physicsWorld.contactDelegate = self;
        // Add BG
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
        background.position = CGPointZero;
        background.anchorPoint = CGPointZero;
        background.blendMode = SKBlendModeReplace;
        [self addChild:background];
        
        // Add Edges
        SKNode *leftEdge = [SKNode node];
        leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height)];
        leftEdge.position = CGPointZero;
        leftEdge.physicsBody.categoryBitMask = kSCEdgeCategory;
        [self addChild:leftEdge];
        
        SKNode *rightEdge = [SKNode node];
        rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height)];
        rightEdge.position = CGPointMake(self.size.width, 0);
        rightEdge.physicsBody.categoryBitMask = kSCEdgeCategory;
        [self addChild:rightEdge];
        
        // Add Main Layer
        _mainLayer = [SKNode new];
        [self addChild:_mainLayer];
        
        // Add Cannon
        _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
        _cannon.position = CGPointMake(self.size.width * 0.5, 0.0);
        [_mainLayer addChild:_cannon];
        
        SKAction *rotateCannonAction = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                                            [SKAction rotateByAngle:-M_PI duration:2]]];
                                        
        [_cannon runAction:[SKAction repeatActionForever:rotateCannonAction]];
        
        SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange:1],
                                                   [SKAction performSelector:@selector(spawnHalo) onTarget:self]]];
        
        [self runAction:[SKAction repeatActionForever:spawnHalo]];
        
        // Setup Ammo
        _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
        _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
        _ammoDisplay.position = _cannon.position;
        self.ammo = 5;
        
        [_mainLayer addChild:_ammoDisplay];
        
        SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:1.0],
                                                       [SKAction runBlock:^{
                                                            self.ammo++;
                                                        }]]];
        [self runAction:[SKAction repeatActionForever:incrementAmmo]];
        
        
    }
    return self;
}

- (void)setAmmo:(int)ammo
{
    if (ammo >= 0 && ammo <=5) {
        _ammo = ammo;
        _ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d",_ammo]];
    }
}

- (void)shoot
{
    if (self.ammo > 0) {
        self.ammo--;
        SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"Ball"];
        ball.name = @"ball";
        
        CGVector rotationVector = radiansToVector(_cannon.zRotation);
        ball.position = CGPointMake(_cannon.position.x + (_cannon.size.width * 0.5 * rotationVector.dx),
                                    _cannon.position.y + (_cannon.size.height * 0.5 * rotationVector.dy));
        
        [_mainLayer addChild:ball];
        
        ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];
        ball.physicsBody.categoryBitMask = kSCBallCategory;
        ball.physicsBody.collisionBitMask = kSCEdgeCategory;
        ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * SHOOT_SPEED, rotationVector.dy * SHOOT_SPEED);
        ball.physicsBody.restitution = 1.0;
        ball.physicsBody.linearDamping = 0.0;
        ball.physicsBody.friction = 0.0;
    }
}

- (void)spawnHalo
{
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, self.size.width - (halo.size.width * 0.5)), self.size.height + (halo.size.height * 0.5));
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:16.0];
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    
    CGVector direction = radiansToVector(randomInRange(kSCHaloLowAngle, kSCHaloHighAngle));
    halo.physicsBody.velocity = CGVectorMake(direction.dx * kSCHaloSpeed, direction.dy * kSCHaloSpeed);
    halo.physicsBody.categoryBitMask = kSCHaloCategory;
    halo.physicsBody.collisionBitMask = kSCEdgeCategory;
    halo.physicsBody.contactTestBitMask = kSCBallCategory;
    
    [_mainLayer addChild:halo];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count > 0) {
         _shoot = YES;
    }
}

- (void)addExplosion:(CGPoint)position
{
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:@"HaloExplosion" ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    
    explosion.position = position;
    
    [_mainLayer addChild:explosion];
    
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                     [SKAction removeFromParent]]];
    
    [explosion runAction:removeExplosion];
    
}

#pragma mark SKPhysicsContactDelegate

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    
    if ((firstBody.categoryBitMask == kSCHaloCategory && secondBody.categoryBitMask == kSCBallCategory)) {
        [self addExplosion:firstBody.node.position];
        
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
}

#pragma Life Cycle

- (void)didSimulatePhysics
{
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        if (!CGRectContainsPoint(self.frame, node.position)) {
            [node removeFromParent];
        }
    }];
    
    if (_shoot) {
        _shoot = NO;
        [self shoot];
    }
}

- (void)update:(NSTimeInterval)currentTime
{
    
}

@end
