//
//  MyWindowController.h
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/02/19.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "MyPDFView.h"

@interface MyWindowController : NSWindowController

@property (strong) MyPDFView *_pdfView;

@end
