//
//  MyPDFView.h
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/02/21.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <QuartzCore/QuartzCore.h>
#import "Document.h"
#import "HandleView.h"
#import "ZoomView.h"
#import "HandScrollView.h"
#import "MyWindowController.h"

@class HandleView;
@class HandScrollView;
@class ZoomView;

@interface MyPDFView : PDFView

@property (assign)NSRect _rect;
@property (strong)HandleView *handleView;
@property (strong)HandScrollView *handScrollView;
@property (strong)ZoomView *zoomView;

- (void)loadHundleView;
- (void)loadHandScrollView;
- (void)loadZoomView;
- (void)removeSubView;

@end
