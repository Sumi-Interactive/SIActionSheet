//
//  PropertyEnforcer.m
//
//  See:
//  http://stackoverflow.com/questions/23233690/how-do-i-prevent-uipopovercontroller-passthroughviews-from-being-reset-after-ori
//
//  Created by Kevin Cao on 14-6-26.
//  Copyright (c) 2014年 Sumi Interactive. All rights reserved.
//

#import "SIPropertyEnforcer.h"
#import <objc/runtime.h>

@interface SIPropertyEnforcer ()

@property (retain) NSString *keyPath;
@property (retain) id value;
@property (assign) id target;

@end

@implementation SIPropertyEnforcer

- (void)dealloc
{
    [_target removeObserver:self forKeyPath:_keyPath context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if((([_target valueForKey:_keyPath] == nil) && (_value == nil)) || [[_target valueForKey:_keyPath] isEqual:_value]) {
        return;
    } else {
        [_target setValue:_value forKeyPath:_keyPath];
    }
}

+ (void)enforceProperty:(NSString*)keyPath ofObject:(id)target toValue:(id)value
{
    SIPropertyEnforcer *enforcer = [[SIPropertyEnforcer alloc] init];
    enforcer.value = value;
    enforcer.keyPath = keyPath;
    enforcer.target = target;
    
    [target addObserver:enforcer forKeyPath:keyPath options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:NULL];
    
    objc_setAssociatedObject(target,
                             _cmd, // using this technique we can only attach one PropertyEnforcer per target
                             enforcer,
                             OBJC_ASSOCIATION_RETAIN);
}

@end
