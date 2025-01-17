
#import <Security/Security.h>
#import "AMAAppIdentifierProvider.h"
#import "AMASecItemOperationResult.h"

@implementation AMAAppIdentifierProvider

#pragma mark - Public -
+ (NSString *)appIdentifierPrefix
{
    NSDictionary *query = [self query];
    AMASecItemOperationResult *operationResult = [self resultForCopyQuery:[self query]];
    if (operationResult.status == errSecItemNotFound) {
        operationResult = [self resultForAddQuery:query];
    }
    if (operationResult.status != errSecSuccess) {
        return nil;
    }
    return [self accessGroupWithAttributes:operationResult.attributes];
}

#pragma mark - Private -

+ (NSDictionary *)query
{
    return @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
             (__bridge id)kSecAttrAccount: @"AMAAppIdentifierPrefix",
             (__bridge id)kSecAttrService: @"AMADeviceDescription",
             (__bridge id)kSecReturnAttributes: (__bridge id)kCFBooleanTrue,
             (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock};
}

+ (AMASecItemOperationResult *)resultForCopyQuery:(NSDictionary *)query
{
    return [self resultForQuery:query block:^OSStatus(CFDictionaryRef query, CFTypeRef *result) {
        return SecItemCopyMatching(query, result);
    }];
}

+ (AMASecItemOperationResult *)resultForAddQuery:(NSDictionary *)query
{
    return [self resultForQuery:query block:^OSStatus(CFDictionaryRef query, CFTypeRef *result) {
        return SecItemAdd(query, result);
    }];
}

+ (AMASecItemOperationResult *)resultForQuery:(NSDictionary *)query
                                        block:(OSStatus (^)(CFDictionaryRef query, CFTypeRef *result))block
{
    CFDictionaryRef result = nil;
    OSStatus status = block((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    AMASecItemOperationResult *operationResult =
        [[AMASecItemOperationResult alloc] initWithStatus:status attributes:(__bridge id)result];
    if (result != nil) {
        CFRelease(result);
    }
    return operationResult;
}

+ (NSString *)accessGroupWithAttributes:(NSDictionary *)attributes
{
    NSString *accessGroup = [attributes objectForKey:(__bridge id)kSecAttrAccessGroup];
    NSArray *components = [accessGroup componentsSeparatedByString:@"."];
    NSString *appIdentifierPrefix = nil;
    if ([components count] > 0) {
        appIdentifierPrefix = [NSString stringWithFormat:@"%@.", components[0]];
    }
    return appIdentifierPrefix;
}

@end
