//
//  TxtPanel.h
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/04/02.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "MyWinC.h"
#import "MyPDFView.h"
#import "NSAlert+SynchronousSheet.h"

@interface TxtPanel : NSWindowController<NSWindowDelegate>

- (void)clearTxt;

@end
