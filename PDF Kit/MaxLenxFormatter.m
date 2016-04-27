//
//  MaxLenxFormatter.m
//  LimitMaxLengthFormatter
//
//  Created by 河野 さおり on 2016/04/25.
//  Copyright © 2016年 河野 さおり. All rights reserved.
//

#import "MaxLenxFormatter.h"

@implementation MaxLenxFormatter
@synthesize maxLength;

+ (void)setMaxLength:(int)maxLength{
    maxLength = maxLength;
}

+ (id)formatterWithMaxLength:(int)maxLength{
    id formatter = [[MaxLenxFormatter alloc]init];
    [formatter setMaxLength:maxLength];
    return formatter;
}

- (NSString*)stringForObjectValue:(id)obj{
    return (NSString*)obj;
}

- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj
             forString:(NSString *)string
      errorDescription:(out NSString *__autoreleasing  _Nullable *)error{
    *obj = string;
    return YES;
}

- (BOOL)isPartialStringValid:(NSString *__autoreleasing  _Nonnull *)partialStringPtr
       proposedSelectedRange:(NSRangePointer)proposedSelRangePtr
              originalString:(NSString *)origString
       originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString *__autoreleasing  _Nullable *)error{
    if ([*partialStringPtr length] > maxLength) {
        return NO;
    }
    return YES;
}

@end
