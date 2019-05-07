//
//  LYRunloop.m
//  RunloopDemo
//
//  Created by 余河川 on 2018/11/27.
//  Copyright © 2018 余河川. All rights reserved.
//

#import "LYRunloop.h"


static dispatch_queue_t ly_runloop_creation_queue() {
    static dispatch_queue_t ly_runloop_creation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ly_runloop_creation_queue = dispatch_queue_create("com.buttfly.ly.runloop", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return ly_runloop_creation_queue;
}



@interface LYRunloopAction : NSObject

/**
 <#Description#>
 */
@property (nonatomic, copy) NSString *name;

/**
 <#Description#>
 */
@property (nonatomic, copy) void(^action)(LYRunloopAction *action);

/**
 开始的次数，和精度一起决定延时启动时间，例如精度为 1，代表 精度为 1 秒，startIndex 为 10，那么计时器会在 10 * 1 秒后进行第一次调用，默认 0
 */
@property (nonatomic, assign) NSInteger startIndex;

/**
 间隔多少次调用 action，间隔时间为 精度 * interval，默认 1
 */
@property (nonatomic, assign) NSUInteger interval;

/**
 精度设置，默认 1 秒
 */
@property (nonatomic, assign) float accuracy;

/**
 <#Description#>
 */
@property (nonatomic, strong) dispatch_source_t timer;

/**
 重复的次数
 */
@property (nonatomic, assign) NSUInteger repeat;

/**
 <#Description#>
 */
@property (nonatomic, assign) NSUInteger count;

@end

@implementation LYRunloopAction

+ (instancetype)ly_actionWithName:(NSString *)name interval:(NSInteger)interval action:(void(^)(LYRunloopAction *runloopAction))action {
    return [self ly_actionWithName:name accuracy:1 startIndex:0 interval:interval repeat:NSUIntegerMax action:action];
}

+ (instancetype)ly_actionWithName:(NSString *)name accuracy:(float)accuracy startIndex:(NSInteger)startIndex interval:(NSInteger)interval repeat:(NSUInteger)repeat action:(void(^)(LYRunloopAction *runloopAction))action {
    
    LYRunloopAction *obj = [LYRunloopAction new];
    if (obj != nil) {
        if (repeat != NSUIntegerMax && ((repeat + startIndex + 1) * interval == 0)) {
            NSAssert(NO, @"repeat startIndex interval 过大");
            return nil;
        }
        obj.name = [name copy];
        obj.action = action;
        obj.startIndex = startIndex;
        obj.interval = interval;
        obj.accuracy = accuracy;
        obj.repeat = repeat;
    }
    return obj;
    
}

- (void)ly_startAction {
    
    if (_timer != nil) {
        [self ly_resumeAction];
        return;
    }
    dispatch_queue_t queue = ly_runloop_creation_queue();
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, _accuracy * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_timer, ^{
        NSUInteger count = self->_count;
        NSUInteger repeat = self->_repeat;
        NSUInteger interval = self->_interval;
        if (repeat != NSUIntegerMax && (count >= (repeat + self->_startIndex + 1) * interval)) {
            [self ly_stopAction];
            return ;
        }
        if (count < (self->_startIndex + 1) * interval) {
            self->_count += 1;
            return ;
        }
        if ((count % interval) != 0) {
            self->_count += 1;
            return;
        }
        if (self->_action != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_action(self);
                self->_count += 1;
            });
        }
    });
    dispatch_resume(_timer);
    
}

- (void)ly_suspendAction {
    dispatch_suspend(_timer);
}

- (void)ly_resumeAction {
    dispatch_resume(_timer);
}

- (void)ly_stopAction {
    dispatch_source_cancel(_timer);
    self.timer = nil;
}

- (void)dealloc {
    
    NSLog(@"%@, dealloc", self);
    
}

@end







@interface LYRunloop ()

/**
 <#Description#>
 */
@property (atomic, strong) NSMutableArray<LYRunloopAction *> *actions;

@property (nonatomic, strong) dispatch_semaphore_t semaphore_lock;


@end

@implementation LYRunloop

+ (void)ly_startRunloop {
    
    [LYRunloop _ly_shareRunloop];
    
}

+ (instancetype)_ly_shareRunloop {
    
    static dispatch_once_t onceToken;
    static LYRunloop *obj = nil;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init_ly];
    });
    return obj;
    
}

- (instancetype)init_ly {
    
    self = [super init];
    if (self != nil) {
        self.semaphore_lock = dispatch_semaphore_create(1);
        self.actions = [NSMutableArray array];
    }
    return self;
    
}

+ (BOOL)ly_addActionWithFlag:(NSString *)flag interval:(NSInteger)interval error:(NSError * _Nullable __autoreleasing * _Nullable)error action:(nonnull void (^)(NSString * _Nonnull, NSUInteger))action {
    
    return [self ly_addActionWithFlag:flag accuracy:1 startIndex:0 interval:interval repeat:NSUIntegerMax error:error action:action];
    
}

+ (BOOL)ly_addActionWithFlag:(NSString *)flag accuracy:(float)accuracy startIndex:(NSInteger)startIndex interval:(NSInteger)interval repeat:(NSUInteger)repeat error:(NSError *__autoreleasing  _Nullable * _Nullable)error action:(nonnull void (^)(NSString * _Nonnull, NSUInteger))action {
    
    interval = (NSInteger)interval;
    NSAssert([flag isKindOfClass:[NSString class]] && flag.length > 0 && interval != 0 && action != nil , @"参数错误");
    
    LYRunloop *loop = [LYRunloop _ly_shareRunloop];
    if (loop.actions.count >= 1024 * 8) {
        *error = [NSError errorWithDomain:@"LYRunloop" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"超过最大 LYRunloopAction 数量限制"}];
        return NO;
    }
    dispatch_semaphore_wait(loop.semaphore_lock, DISPATCH_TIME_FOREVER);
    LYRunloopAction *loopAction = [LYRunloopAction ly_actionWithName:flag accuracy:accuracy startIndex:startIndex interval:interval repeat:repeat action:^(LYRunloopAction *runloopAction) {
        if (action != nil) {
            action(runloopAction.name ,runloopAction.count / runloopAction.interval - runloopAction.startIndex - 1);
        }
    }];
    [loop.actions addObject:loopAction];
    [loopAction ly_startAction];
    dispatch_semaphore_signal(loop.semaphore_lock);
    return YES;
    
}

+ (void)ly_removeActionWithFlag:(NSString *)flag {
    
    LYRunloop *loop = [LYRunloop _ly_shareRunloop];
    dispatch_semaphore_wait(loop.semaphore_lock, DISPATCH_TIME_FOREVER);
    NSMutableArray<LYRunloopAction *> *removeActions = [NSMutableArray array];
    [loop.actions enumerateObjectsUsingBlock:^(LYRunloopAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString:flag]) {
            [removeActions addObject:obj];
            [obj ly_stopAction];
        }
    }];
    [loop.actions removeObjectsInArray:removeActions];
    dispatch_semaphore_signal(loop.semaphore_lock);
    
}

+ (BOOL)ly_actionIsRun:(NSString *)flag {
    
    LYRunloop *loop = [LYRunloop _ly_shareRunloop];
    __block BOOL result = NO;
    [loop.actions enumerateObjectsUsingBlock:^(LYRunloopAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString:flag]) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
    
}

@end
