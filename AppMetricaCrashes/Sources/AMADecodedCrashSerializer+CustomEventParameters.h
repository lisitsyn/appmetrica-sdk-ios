
#import "AMADecodedCrashSerializer.h"
#import "AMACrashEventType.h"

NS_ASSUME_NONNULL_BEGIN

@class AMADecodedCrash;
@class AMACustomEventParameters;

@interface AMADecodedCrashSerializer (CustomEventParameters)

/// Creates an `AMACustomEventParameters` object from the given decoded crash data for a specific event type.
///
/// - Parameters:
///   - decodedCrash: The `AMADecodedCrash` object to be converted into event parameters.
///   - eventType: The type of event for which the event parameters are being created.
///   - error: A pointer to an `NSError` object for error reporting.
///
/// - Returns: An `AMACustomEventParameters` object if successful or if only non-critical errors occur; `nil` if a critical error occurs.
- (nullable AMACustomEventParameters *)eventParametersFromDecodedData:(AMADecodedCrash *)decodedCrash
                                                         forEventType:(AMACrashEventType)eventType
                                                                error:(NSError **)error;

/// Creates an `AMACustomEventParameters` object from the given decoded crash data.
///
/// - Parameters:
///   - decodedCrash: The `AMADecodedCrash` object to be converted into event parameters.
///   - error: A pointer to an `NSError` object for error reporting.
///
/// - Returns: An `AMACustomEventParameters` object if successful or if only non-critical errors occur; `nil` if a critical error occurs.
- (nullable AMACustomEventParameters *)eventParametersFromDecodedData:(AMADecodedCrash *)decodedCrash
                                                                error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
