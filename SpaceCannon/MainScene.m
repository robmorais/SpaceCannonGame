//
//  MainScene.m
//  SpaceCannon
//
//  Created by Roberto Silva on 24/11/14.
//  Copyright (c) 2014 HE:mobile. All rights reserved.
//

#import "MainScene.h"
#import "SCMenu.h"
#import "SCBall.h"

static const CGFloat SHOOT_SPEED = 1000.0;
static const CGFloat kSCHaloLowAngle = 200.0 * M_PI/180.0;
static const CGFloat kSCHaloHighAngle = 340.0 * M_PI/180.0;
static const CGFloat kSCHaloSpeed = 100.0;

static NSString *const kSCKeyTopScore = @"TopScoreKey";

// Colision Bitmaks
static const uint32_t kSCHaloCategory   = 0x1 << 0;
static const uint32_t kSCBallCategory   = 0x1 << 1;
static const uint32_t kSCEdgeCategory   = 0x1 << 2;
static const uint32_t kSCShieldCategory = 0x1 << 3;
static const uint32_t kSCLifeBarCategory = 0x1 << 4;

@interface MainScene()
@property (nonatomic) int ammo;
@property (nonatomic) int score;
@property (nonatomic) int multiplier;
@end

@implementation MainScene
{
    SKNode *_mainLayer;
    SCMenu *_menu;
    SKSpriteNode *_cannon;
    SKSpriteNode *_ammoDisplay;
    SKLabelNode *_scoreLabel;
    SKLabelNode *_multiplierLabel;
    BOOL _shoot;
    SKAction *_bounceSound;
    SKAction *_deepExplosionSound;
    SKAction *_explosionSound;
    SKAction *_laserSound;
    SKAction *_zapSound;
    BOOL _gameOver;
    NSUserDefaults *_userDefaults;
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

#pragma mark - Setup and Life Cycle

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
        leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100)];
        leftEdge.position = CGPointZero;
        leftEdge.physicsBody.categoryBitMask = kSCEdgeCategory;
        [self addChild:leftEdge];
        
        SKNode *rightEdge = [SKNode node];
        rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100)];
        rightEdge.position = CGPointMake(self.size.width, 0);
        rightEdge.physicsBody.categoryBitMask = kSCEdgeCategory;
        [self addChild:rightEdge];
        
        // Add Main Layer
        _mainLayer = [SKNode new];
        [self addChild:_mainLayer];
        
        // Add Cannon
        _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
        _cannon.position = CGPointMake(self.size.width * 0.5, 0.0);
        [self addChild:_cannon];
        
        SKAction *rotateCannonAction = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                                            [SKAction rotateByAngle:-M_PI duration:2]]];
                                        
        [_cannon runAction:[SKAction repeatActionForever:rotateCannonAction]];
        
        SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange:1],
                                                   [SKAction performSelector:@selector(spawnHalo) onTarget:self]]];
        
        [self runAction:[SKAction repeatActionForever:spawnHalo] withKey:@"SpawnHalo"];
        
        // Setup Ammo
        _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
        _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
        _ammoDisplay.position = _cannon.position;
        
        [self addChild:_ammoDisplay];
        
        SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:1.0],
                                                       [SKAction runBlock:^{
                                                            self.ammo++;
                                                        }]]];
        [self runAction:[SKAction repeatActionForever:incrementAmmo]];
        
        // Score Label
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _scoreLabel.position = CGPointMake(15, 10);
        _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        _scoreLabel.fontSize = 15.0;
        
        [self addChild:_scoreLabel];
        
        // Multiplier Label
        _multiplierLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _multiplierLabel.position = CGPointMake(15, 30);
        _multiplierLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        _multiplierLabel.fontSize = 15.0;
        
        [self addChild:_multiplierLabel];
        
        // Setup sounds
        [self setupSounds];
        
        // Setup Menu
        _menu = [SCMenu new];
        _menu.position = CGPointMake(self.size.width * 0.5, self.size.height - 220);
        
        [self addChild:_menu];
        
        // Init variables
        _gameOver = YES;
        self.ammo = 5;
        self.score = 0;
        self.multiplier = 1;
        _scoreLabel.hidden = YES;
        _multiplierLabel.hidden = YES;
        
        // User Defaults
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _menu.topScore = [_userDefaults integerForKey:kSCKeyTopScore];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count > 0 && !_gameOver) {
        _shoot = YES;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        if (_gameOver) {
            SKNode *node = [_menu nodeAtPoint:[touch locationInNode:_menu]];
            if ([node.name isEqualToString:@"PlayButton"]) {
                [self newGame];
            }
        }
    }
}

- (void)setupSounds
{
    _explosionSound = [SKAction playSoundFileNamed:@"Explosion.caf" waitForCompletion:NO];
    _deepExplosionSound = [SKAction playSoundFileNamed:@"DeepExplosion.caf" waitForCompletion:NO];
    _zapSound = [SKAction playSoundFileNamed:@"Zap.caf" waitForCompletion:NO];
    _bounceSound = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
    _laserSound = [SKAction playSoundFileNamed:@"Laser.caf" waitForCompletion:NO];
}

#pragma mark - Game Actions

- (void)newGame
{
    [_mainLayer removeAllChildren];
    
    // Setup shield
    for (int i=0; i < 6; i++) {
        SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shield.name = @"shield";
        shield.position = CGPointMake(35 + (50*i), 90);
        shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shield.physicsBody.categoryBitMask = kSCShieldCategory;
        shield.physicsBody.collisionBitMask = 0;
        
        [_mainLayer addChild:shield];
    }
    
    // Setup Life Bar
    SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
    lifeBar.position = CGPointMake(lifeBar.size.width * 0.5, 70);
    lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width * 0.5, 0) toPoint:CGPointMake(lifeBar.size.width * 0.5, 0)];
    lifeBar.physicsBody.categoryBitMask = kSCLifeBarCategory;
    
    [_mainLayer addChild:lifeBar];
    
    // Initial values
    self.ammo = 5;
    self.score = 0;
    self.multiplier = 1;
    _scoreLabel.hidden = NO;
    _multiplierLabel.hidden = NO;
    _menu.hidden = YES;
    _gameOver = NO;
    [self actionForKey:@"SpawnHalo"].speed = 1.0;
}

- (void)gameOver
{
    //[self addExplosion:firstBody.node.position name:@"HaloExplosion"];
    
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position name:@"HaloExplosion"];
        [node removeFromParent];
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    _menu.score = self.score;
    
    if (_menu.score > _menu.topScore) {
        _menu.topScore = self.score;
        [_userDefaults setInteger:self.score forKey:kSCKeyTopScore];
        [_userDefaults synchronize];
    }
    
    _menu.hidden = NO;
    _scoreLabel.hidden = YES;
    _multiplierLabel.hidden = YES;
    _gameOver = YES;
}

- (void)shoot
{
    if (self.ammo > 0) {
        self.ammo--;
        SCBall *ball = [SCBall spriteNodeWithImageNamed:@"Ball"];
        ball.name = @"ball";
        
        CGVector rotationVector = radiansToVector(_cannon.zRotation);
        ball.position = CGPointMake(_cannon.position.x + (_cannon.size.width * 0.5 * rotationVector.dx),
                                    _cannon.position.y + (_cannon.size.height * 0.5 * rotationVector.dy));
        
        [_mainLayer addChild:ball];
        
        ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];
        ball.physicsBody.categoryBitMask = kSCBallCategory;
        ball.physicsBody.collisionBitMask = kSCEdgeCategory;
        ball.physicsBody.contactTestBitMask = kSCEdgeCategory;
        ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * SHOOT_SPEED, rotationVector.dy * SHOOT_SPEED);
        ball.physicsBody.restitution = 1.0;
        ball.physicsBody.linearDamping = 0.0;
        ball.physicsBody.friction = 0.0;
        
        [self runAction:_laserSound];
        
        // Create trail
        NSString *trailEmitterPath = [[NSBundle mainBundle] pathForResource:@"BallTrail" ofType:@"sks"];
        SKEmitterNode *ballTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:trailEmitterPath];
        ballTrail.targetNode = _mainLayer;
        [_mainLayer addChild:ballTrail];
        ball.trail = ballTrail;
        
    }
}

- (void)spawnHalo
{
    // Increase speed
    SKAction *spawnAction = [self actionForKey:@"SpawnHalo"];
    
    if (spawnAction.speed < 1.5) {
        spawnAction.speed += 0.01;
    }
    
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.name = @"halo";
    halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, self.size.width - (halo.size.width * 0.5)), self.size.height + (halo.size.height * 0.5));
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:16.0];
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    
    CGVector direction = radiansToVector(randomInRange(kSCHaloLowAngle, kSCHaloHighAngle));
    halo.physicsBody.velocity = CGVectorMake(direction.dx * kSCHaloSpeed, direction.dy * kSCHaloSpeed);
    halo.physicsBody.categoryBitMask = kSCHaloCategory;
    halo.physicsBody.collisionBitMask = kSCEdgeCategory;
    halo.physicsBody.contactTestBitMask = kSCBallCategory | kSCShieldCategory | kSCLifeBarCategory | kSCEdgeCategory;
    
    // Random multiplier
    
    if (!_gameOver && arc4random_uniform(6) == 0) {
        halo.texture = [SKTexture textureWithImageNamed:@"HaloX"];
        halo.userData = [NSMutableDictionary dictionaryWithDictionary:@{@"Multiplier":@YES}];
    } else if (!_gameOver && arc4random_uniform(8) == 0) {
        halo.texture = [SKTexture textureWithImageNamed:@"HaloBomb"];
        halo.userData = [NSMutableDictionary dictionaryWithDictionary:@{@"Bomb":@YES}];
    }
    
    [_mainLayer addChild:halo];
    
}

- (void)addExplosion:(CGPoint)position name:(NSString *)name
{
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    
    explosion.position = position;
    
    [_mainLayer addChild:explosion];
    
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                     [SKAction removeFromParent]]];
    
    [explosion runAction:removeExplosion];
    
}

- (void)destroyAllHalos
{
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position name:@"HaloExplosion"];
        [self runAction:_explosionSound];
        [node removeFromParent];
        self.score += self.multiplier;
    }];
}

- (void)destroyAllShields
{
    [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position name:@"HaloExplosion"];
        [self runAction:_explosionSound];
        [node removeFromParent];
        self.score += self.multiplier;
    }];
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
        // Ball hits a Halo
        [self addExplosion:firstBody.node.position name:@"HaloExplosion"];
        [self runAction:_explosionSound];
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        
        self.score += self.multiplier;
        
        if ([[firstBody.node.userData valueForKey:@"Multiplier"] boolValue]) {
            self.multiplier++;
        }
        
        if ([[firstBody.node.userData valueForKey:@"Bomb"] boolValue]) {
            [self destroyAllHalos];
        }
        
        // Disable ball so it only hits once
        secondBody.categoryBitMask = 0;
    }
    
    if ((firstBody.categoryBitMask == kSCHaloCategory && secondBody.categoryBitMask == kSCShieldCategory)) {
        // Halo hits shield
        [self addExplosion:firstBody.node.position name:@"HaloExplosion"];
        [self runAction:_explosionSound];
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        
        if ([[firstBody.node.userData valueForKey:@"Bomb"] boolValue]) {
            [self destroyAllShields];
        }
        
        // Disable halo so it only hits once
        firstBody.categoryBitMask = 0;
    }
    
    if ((firstBody.categoryBitMask == kSCHaloCategory && secondBody.categoryBitMask == kSCLifeBarCategory)) {
        // Game Over
        [self addExplosion:secondBody.node.position name:@"LifeBarExplosion"];
        [secondBody.node removeFromParent];
        [self runAction:_deepExplosionSound];
        [self gameOver];
    }
    
    if ((firstBody.categoryBitMask == kSCHaloCategory && secondBody.categoryBitMask == kSCEdgeCategory)) {
        // Halo bounces
        if (!_gameOver) {
            [self runAction:_zapSound];
        }
    }
    
    if ((firstBody.categoryBitMask == kSCBallCategory && secondBody.categoryBitMask == kSCEdgeCategory)) {
        // balls bounces on the edges
        if ([firstBody.node isKindOfClass:[SCBall class]]) {
            ((SCBall *)firstBody.node).bounces++;
            if (((SCBall *)firstBody.node).bounces > 3) {
                [firstBody.node removeFromParent];
                self.multiplier = 1;
            }
        }
        
        [self addExplosion:contact.contactPoint name:@"BounceExplosion"];
        [self runAction:_bounceSound];
    }

}

#pragma mark Setters

- (void)setAmmo:(int)ammo
{
    if (ammo >= 0 && ammo <=5) {
        _ammo = ammo;
        _ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d",_ammo]];
    }
}

- (void)setScore:(int)score
{
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d",score];
}

- (void)setMultiplier:(int)multiplier
{
    _multiplier = multiplier;
    _multiplierLabel.text = [NSString stringWithFormat:@"Multiplier: x%d",multiplier];
}

#pragma mark Life Cycle

- (void)didSimulatePhysics
{
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        if ([node respondsToSelector:@selector(updateTrail)]) {
            [node performSelector:@selector(updateTrail) withObject:nil];
        }
        if (!CGRectContainsPoint(self.frame, node.position)) {
            [node removeFromParent];
            self.multiplier = 1;
        }
        
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.y + node.frame.size.height < 0) {
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
