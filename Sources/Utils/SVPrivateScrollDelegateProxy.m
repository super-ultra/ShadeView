#import "SVPrivateScrollDelegateProxy.h"

@implementation SVPrivateScrollDelegateProxy

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [self.mainDelegate respondsToSelector:aSelector] || [self.supplementaryDelegate respondsToSelector:aSelector];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature* signature = [self.mainDelegate methodSignatureForSelector:selector];
    if (!signature) {
       signature = [self.supplementaryDelegate methodSignatureForSelector:selector];
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    SEL aSelector = [anInvocation selector];

    if ([self.mainDelegate respondsToSelector:aSelector]) {
        [anInvocation invokeWithTarget:self.mainDelegate];
    }
    if ([self.supplementaryDelegate respondsToSelector:aSelector]) {
        [anInvocation invokeWithTarget:self.supplementaryDelegate];
    }
}

@end
