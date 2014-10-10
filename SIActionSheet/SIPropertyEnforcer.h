//
//  PropertyEnforcer.h
//
//  Created by Kevin Cao on 14-6-26.
//  Copyright (c) 2014年 Sumi Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SIPropertyEnforcer : NSObject

+ (void)enforceProperty:(NSString*)keyPath ofObject:(id)target toValue:(id)value;

@end
