//
//  MaxLenxFormatter.h
//  LimitMaxLengthFormatter
//
//  Created by 河野 さおり on 2016/04/25.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MaxLenxFormatter : NSFormatter
@property (assign)int maxLength;
+ (void)setMaxLength:(int)maxLength;
+ (id)formatterWithMaxLength:(int)maxLength;
@end
