//
//  PrefWinC.m
//  Sao's PDF Kit
//
//  Created by 河野 さおり on 2016/06/11.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "PrefWinC.h"

#pragma mark - Behavior of PrefWin

@interface PrefWin : NSWindow
@end

@implementation PrefWin

//キャンセル・オペレーション時ウィンドウを閉じるように設定
- (void)cancelOperation:(id)sender{
    [self close];
}

//ツールバーを変更不可にする
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem{
    SEL action = [anItem action];
    if (action == @selector(toggleToolbarShown:)) {
        return NO;
    }
    return [super validateUserInterfaceItem:anItem];
}

@end

@interface PrefWinC ()
@property (weak) IBOutlet NSView *generalView;
@property (weak) IBOutlet NSView *fontsView;
@property (weak) IBOutlet NSView *content;
@property (weak) IBOutlet NSUserDefaultsController *defaultsCntr;
@end

enum ContentView {
    kCViewGeneral = 100,
    kCViewFonts = 101,
};
typedef NSInteger ContentView;

@implementation PrefWinC{
    IBOutlet NSTextField *txtWinX;
    IBOutlet NSTextField *txtWinY;
    IBOutlet NSTextField *txtWinW;
    IBOutlet NSTextField *txtWinH;
    IBOutlet NSPopUpButton *popWinPos;
    IBOutlet NSPopUpButton *popMag;
    IBOutlet NSTextField *txtMagV;
    IBOutlet NSStepper *stpMagV;
    IBOutlet NSPopUpButton *popDisplayMode;
    IBOutlet NSButton *chkDisplayAsBook;
    IBOutlet NSButton *chkNavi;
    IBOutlet NSButton *chkAnti;
    IBOutlet NSTextField *txtGreeking;
    IBOutlet NSStepper *stpGreeking;
}
@synthesize content;

+ (PrefWinC *)sharedPrefWinC{
    static PrefWinC *sharedController = nil;
    if (sharedController == nil) {
        sharedController = [[PrefWinC alloc]init];
    }
    return sharedController;
}

- (id)init{
    self = [super initWithWindowNibName:@"PrefWinC"];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib{
    NSDictionary *initVal = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"",@"WinX",@"",@"WinY",
                            @"",@"WinW",@"",@"WinH",
                            [NSNumber numberWithInt:0],@"WinPos",
                            [NSNumber numberWithInt:0],@"Magnification",
                            @"",@"MagnificationVal",
                            [NSNumber numberWithInt:1],@"DisplayMode",
                            [NSNumber numberWithBool:NO],@"DisplayAsBook",
                            [NSNumber numberWithBool:YES],@"Navigator",
                            [NSNumber numberWithBool:YES],@"AntiAliase",
                            [NSNumber numberWithFloat:3.0],@"Greeking",nil];
    [self.defaultsCntr setInitialValues:initVal];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSToolbar *toolbar = self.window.toolbar;
    NSArray *toolbarItems = toolbar.items;
    NSToolbarItem *leftMostItem = [toolbarItems objectAtIndex:0];
    [toolbar setSelectedItemIdentifier:leftMostItem.itemIdentifier];
    [self switchView:leftMostItem];
    [self.window center];
}

- (IBAction)switchView:(id)sender {
    NSToolbarItem *item = (NSToolbarItem *)sender;
    ContentView cView = item.tag;
    NSView *view = nil;
    switch (cView) {
        case kCViewGeneral:
            view = self.generalView;
            break;
        case kCViewFonts:
            view = self.fontsView;
            break;
        default:
            break;
    }
    
    NSArray *subViews = content.subviews;
    for (NSView *subView in subViews) {
        [subView removeFromSuperview];
    }
    [self.window setTitle:item.label];
    NSRect newFrame = [self.window frameRectForContentRect:view.frame];
    newFrame.origin.x = self.window.frame.origin.x;
    newFrame.origin.y = self.window.frame.origin.y + self.window.frame.size.height - newFrame.size.height;
    [self.window setFrame:newFrame display:YES animate:YES];
    [content addSubview:view];
}

- (IBAction)initialize:(id)sender {
    NSDictionary *initVal = self.defaultsCntr.initialValues;
    if ([self.window.title isEqualToString:@"General"]) {
        txtWinX.stringValue = [initVal objectForKey:@"WinX"];
        txtWinY.stringValue = [initVal objectForKey:@"WinY"];
        txtWinW.stringValue = [initVal objectForKey:@"WinW"];
        txtWinH.stringValue = [initVal objectForKey:@"WinH"];
        [popWinPos selectItemAtIndex:[[initVal objectForKey:@"WinPos"]intValue]];
        txtMagV.stringValue = [[initVal objectForKey:@"MagnificationVal"]stringValue];
        stpMagV.floatValue = 1.0;
        [popDisplayMode selectItemAtIndex:[[initVal objectForKey:@"DisplayMode"]intValue]];
        [chkDisplayAsBook setState:[[initVal objectForKey:@"DisplayAsBook"]intValue]];
        [chkNavi setState:[[initVal objectForKey:@"Navigator"]intValue]];
    } else {
        [chkAnti setState:[[initVal objectForKey:@"AntiAliase"]intValue]];
        txtGreeking.stringValue = [[initVal objectForKey:@"Greeking"]stringValue];
        stpGreeking.floatValue = 3.0;
    }
}

@end
