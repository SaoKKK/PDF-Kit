//
//  AppDelegate.h
//  PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BMPanelController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) BMPanelController *_bmPanelC;
@property (weak) IBOutlet NSMenuItem *mnItemView;
@property (weak) IBOutlet NSMenuItem *mnItemGo;
@property (weak) IBOutlet NSMenu *mnView;
@property (weak) IBOutlet NSMenu *mnGo;
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
@property (assign) BOOL isDocWinMain;
@property (assign) BOOL isOLExists;
@property (assign) BOOL isOLSelected;
@property (readwrite,nonatomic)NSMutableDictionary *olInfo;

- (void)setMnPageDisplayState:(NSInteger)tag;
- (void)documentMenuSetEnabled:(BOOL)enabled;
- (void)mergeMenuSetEnabled;
- (void)findMenuSetEnabled:(BOOL)enabled;
- (void)showStatusWin:(NSRect)rect messageText:(NSString*)message infoText:(NSString*)info;
- (void)restorePDFLst;
- (IBAction)showBookmarkPanel:(id)sender;

@end

