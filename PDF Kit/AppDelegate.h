//
//  AppDelegate.h
//  PDF Kit
//
//  Created by 河野 さおり on 2016/02/15.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readwrite,retain,nonatomic)NSMutableArray* PDFLst;
@property (readwrite,retain,nonatomic)NSMutableArray* errLst;
@property (weak) IBOutlet NSWindow *statusWin;

- (void)showStatusWin:(NSRect)rect messageText:(NSString*)message infoText:(NSString*)info;
- (void)restorePDFLst;
@end

