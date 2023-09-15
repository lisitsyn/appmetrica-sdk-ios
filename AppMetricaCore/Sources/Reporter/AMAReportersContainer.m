
#import "AMACore.h"
#import "AMAReportersContainer.h"
#import "AMAReporter.h"

@interface AMAReportersContainer ()

@property (nonatomic, strong) NSMutableDictionary *reporters;

@end

@implementation AMAReportersContainer

- (id)init
{
    self = [super init];
    if (self) {
        _reporters = [NSMutableDictionary new];
    }
    return self;
}

- (AMAReporter *)reporterForApiKey:(NSString *)apiKey
{
    if (apiKey == nil) {
        return nil;
    }
    
    @synchronized(self) {
        AMAReporter *reporter = self.reporters[apiKey];
        return reporter;
    }
}

- (void)setReporter:(AMAReporter *)reporter forApiKey:(NSString *)apiKey
{
    if (reporter == nil || apiKey == nil) {
        return;
    }

    @synchronized(self) {
        self.reporters[apiKey] = reporter;
    }
}

- (void)start
{
    [self makeReportersPerformSelector:@selector(start)];
}

- (void)shutdown
{
    [self makeReportersPerformSelector:@selector(shutdown)];
}

- (void)startNewSession
{
    [self makeReportersPerformSelector:@selector(startNewSession)];
}

#pragma mark - Private

- (void)makeReportersPerformSelector:(SEL)selector
{
    @synchronized(self) {
        [self.reporters.allValues makeObjectsPerformSelector:selector];
    }
}

@end