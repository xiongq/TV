//
//  NSObject+kvoRuntime.m
//  TV
//  runtime 交换移除通知方法 处理移除通知造成crash
//  Created by xiong on 2016/12/15.
//  Copyright © 2016年 xiong. All rights reserved.
//

#import "NSObject+kvoRuntime.h"
#import <objc/runtime.h>

@implementation NSObject (kvoRuntime)
+(void)load{
    [self switchMethod];

}
-(void)removeXQ:(NSObject *)observer forKeyPath:(NSString *)keyPath{
    @try {
        [self removeXQ:observer forKeyPath:keyPath];
    } @catch (NSException *exception) {
        
    }

}
+(void)switchMethod{

    SEL removeSel   = @selector(removeObserver:forKeyPath:);
    SEL xqRemoveSel = @selector(removeXQ:forKeyPath:);
    
    Method systemRemoveMethod = class_getClassMethod([self class], removeSel);
    Method xqRemoveMethod = class_getClassMethod([self class], xqRemoveSel);
    
    method_exchangeImplementations(systemRemoveMethod, xqRemoveMethod);

}
@end
