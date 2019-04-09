//
//  LYRunloop.h
//  RunloopDemo
//
//  Created by 余河川 on 2018/11/27.
//  Copyright © 2018 余河川. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LYRunloop : NSObject


/**
 <#Description#>

 @param flag 唯一标记
 @param interval 间隔，间隔时间等于间隔乘以精度，默认精度为一秒
 @param error <#error description#>
 @param action 回调事件
 @return 是否成功添加
 */
+ (BOOL)ly_addActionWithFlag:(NSString *)flag interval:(NSInteger)interval error:(NSError * _Nullable __autoreleasing * _Nullable)error action:(void(^)(NSString *flag, NSUInteger index))action;


/**
 <#Description#>

 @param flag 唯一标记
 @param accuracy 精度，默认一秒
 @param startIndex 开始的次数，和精度一起决定延时启动时间，例如精度为 1，代表 精度为 1 秒，startIndex 为 10，那么计时器会在 10 * 1 秒后进行第一次调用，默认 0
 @param interval 间隔多少次调用 action，间隔时间为 精度 * interval，默认 1
 @param repeat 重复次数 默认 NSUIntegerMax
 @param error <#error description#>
 @param action 回调事件
 @return 是否成功添加
 */
+ (BOOL)ly_addActionWithFlag:(NSString *)flag accuracy:(float)accuracy startIndex:(NSInteger)startIndex interval:(NSInteger)interval repeat:(NSUInteger)repeat error:(NSError * _Nullable __autoreleasing * _Nullable)error action:(void(^)(NSString *flag, NSUInteger index))action;

+ (void)ly_removeActionWithFlag:(NSString *)flag;

/**
 <#Description#>
 
 @param flag 唯一标记
 */
+ (BOOL)ly_actionIsRun:(NSString *)flag;

@end

NS_ASSUME_NONNULL_END
