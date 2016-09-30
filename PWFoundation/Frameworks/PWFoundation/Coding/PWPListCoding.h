#import <Foundation/Foundation.h>
#import <PWFoundation/PWValueType.h>
// Protocol used for serializing value objects to Plist and back

NS_ASSUME_NONNULL_BEGIN

@protocol PWPListCoding

// Note: parsing errors should use PWPListCodingParsingError.
- (instancetype) initWithPList:(id)pList context:(nullable id<PWValueTypeContext>)context error:(NSError**)outError;

- (id) pListRepresentationWithOptions:(nullable NSDictionary*)options context:(nullable id<PWValueTypeContext>)context;

@end

NS_ASSUME_NONNULL_END
