//
//  AppDelegate.h
//  PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyWinC.h"
#import "BMPanel.h"
#import "TxtPanel.h"

@class BMPanel;
@class TxtPanel;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) BMPanel *_bmPanelC;
@property (strong) TxtPanel *_txtPanel;
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

//pass win
@property (weak) IBOutlet NSWindow *passWin;
@property (weak) IBOutlet NSTextField *pwMsgTxt;
@property (weak) IBOutlet NSTextField *pwInfoTxt;
@property (weak) IBOutlet NSSecureTextField *pwTxtPass;
@property (readwrite) NSWindow *parentWin;

@property (assign) BOOL isImgInPboard;
@property (assign) BOOL isWinExist;
@property (assign) BOOL isDocWinMain;
@property (assign) BOOL isSelection;
@property (assign) BOOL isOLExists;
@property (assign) BOOL isOLSelected;
@property (assign) BOOL isOLSelectedSingle;
@property (assign) BOOL isTwoPages;
@property (assign) BOOL isTextPanelKey;
@property (assign) BOOL isLocked;
@property (assign) BOOL isCopyLocked;
@property (assign) BOOL isPrintLocked;
@property (assign) BOOL isDocLocked;
@property (assign) BOOL beResponse;
@property (readwrite,nonatomic)NSMutableDictionary *olInfo;
@property (assign) BOOL bRowClicked;

- (void)setMnPageDisplayState:(NSInteger)tag;
- (void)showStatusWin:(NSRect)rect messageText:(NSString*)message infoText:(NSString*)info;
- (void)restorePDFLst;
- (IBAction)showBookmarkPanel:(id)sender;

@end

