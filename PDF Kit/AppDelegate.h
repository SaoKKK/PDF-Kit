//
//  AppDelegate.h
//  PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSMenuItem *mnGoToPrevPg;
@property (weak) IBOutlet NSMenuItem *mnGoToNextPg;
@property (weak) IBOutlet NSMenuItem *mnGoToFirstPg;
@property (weak) IBOutlet NSMenuItem *mnGoToLastPg;
@property (weak) IBOutlet NSMenuItem *mnGoBack;
@property (weak) IBOutlet NSMenuItem *mnGoForward;
@property (weak) IBOutlet NSMenuItem *mnZoomIn;
@property (weak) IBOutlet NSMenuItem *mnZoomOut;
@property (weak) IBOutlet NSMenuItem *mnFullScreen;
@property (readwrite,retain,nonatomic)NSMutableArray* PDFLst;
@property (readwrite,retain,nonatomic)NSMutableArray* errLst;
@property (weak) IBOutlet NSWindow *statusWin;

- (void)setMnPageDisplayState:(NSInteger)tag;
- (void)documentMenuSetEnabled:(BOOL)enabled;
- (void)showStatusWin:(NSRect)rect messageText:(NSString*)message infoText:(NSString*)info;
- (void)restorePDFLst;
@end

