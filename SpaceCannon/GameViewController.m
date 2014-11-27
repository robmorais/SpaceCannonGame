//
//  GameViewController.m
//  SpaceCannon
//
//  Created by Roberto Silva on 24/11/14.
//  Copyright (c) 2014 HE:mobile. All rights reserved.
//

#import "GameViewController.h"
#import "MainScene.h"

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    SKView *spriteView = (SKView *) self.view;
    spriteView.showsDrawCount = YES;
    spriteView.showsNodeCount = YES;
    spriteView.showsFPS = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    SKView *spriteView = (SKView *) self.view;
    MainScene* hello = [MainScene sceneWithSize:spriteView.bounds.size];
    
    [spriteView presentScene: hello];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
