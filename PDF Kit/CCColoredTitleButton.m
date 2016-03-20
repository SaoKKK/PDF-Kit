//
//  CCColoredTitleButton.m
//  customButton
//
//  Created by 河野 さおり on 2016/03/20.
//  Copyright © 2016年 Saori Kohno. All rights reserved.
//

#import "CCColoredTitleButton.h"

@implementation CCColoredTitleButton{
    NSArray *colorLst;
}

- (void)awakeFromNib{
    colorLst = [NSArray arrayWithObjects:[NSColor whiteColor],nil];

    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedTitle]];
    NSRange range = NSMakeRange(0, [title length]);
    [title addAttribute:NSForegroundColorAttributeName value:[colorLst objectAtIndex:self.tag] range:range];
    [self setAttributedTitle:title];
}
@end