//
//  HandScrollView.m
//  Document-based2
//
//  Created by 河野 さおり on 2016/03/23.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "HandScrollView.h"

@implementation HandScrollView

- (void)mouseDown:(NSEvent *)theEvent{
    NSLog(@"down");
}

- (void)mouseDragged:(NSEvent *)theEvent{
    NSLog(@"drag");
}

- (void)mouseUp:(NSEvent *)theEvent{
    NSLog(@"up");
}

@end
