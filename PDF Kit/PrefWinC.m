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
@end

enum ContentView {
    kCViewGeneral = 100,
    kCViewFonts = 101,
};
typedef NSInteger ContentView;

@implementation PrefWinC
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
    [self.window.contentView addSubview:self.generalView];
}

@end
