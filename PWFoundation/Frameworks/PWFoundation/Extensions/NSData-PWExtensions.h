//
//  NSData-PWExtensions.h
//  PWFoundation
//
//  Created by Frank Illenberger on 10.11.05.
//
//

@interface NSData (PWExtensions)

@property (nonatomic, readonly) NSData*    sha1;
@property (nonatomic, readonly) NSString*  sha1String;
@property (nonatomic, readonly) NSData*    httpGzippedData;
@property (nonatomic, readonly) NSData*    gunzippedData;
@property (nonatomic, readonly) NSData*    httpGunzippedData;

@property (nonatomic, readonly, copy) NSData *inflatedData;
@property (nonatomic, readonly, copy) NSData *deflatedData;

- (BOOL)writeToFile:(NSString*)path atomically:(BOOL)flag createDirectories:(BOOL)createDirectories;

@property (nonatomic, readonly, copy) NSString *encodeBase64;
- (NSString*)encodeBase64WithNewlines:(BOOL)encodeWithNewlines;
- (NSString*)encodeBase64WithNewlines:(BOOL)encodeWithNewlines
                  withCarriageReturns:(BOOL)encodeWithCarriageReturns;

@property (nonatomic, readonly, copy) NSString *encodeBase64URL;   // like -_U6RE1vEiacYABQ5MAAZw - always without trailing ..

// Returns nil if string does not contain valid encoding. This includes the case string == nil or empty.
- (instancetype)initWithBase64URLRepresentation:(NSString*)string;

@property (nonatomic, readonly, copy) NSString *hexadecimalRepresentation;
+ (NSData*)dataWithHexadecimalRepresentation:(NSString*)string;
- (instancetype)initWithHexadecimalRepresentation:(NSString*)string;

- (uint8_t)byteAtIndex:(NSUInteger)index;

- (FILE*)createStreamForReadingReturningError:(NSError**)outError NS_RETURNS_INNER_POINTER;
@end

#pragma mark 

@interface NSMutableData (PWExtensions)

- (FILE*)createStreamForReadingAndWritingReturningError:(NSError**)outError NS_RETURNS_INNER_POINTER;

@end
