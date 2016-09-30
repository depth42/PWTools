//
//  NSData-PWExtensions.m
//  PWFoundation
//
//  Created by Frank Illenberger on 10.11.05.
//
//

#import "NSData-PWExtensions.h"
#include <zlib.h>
#import <CommonCrypto/CommonDigest.h>
#import "modp_b64w.h"
#include <stdlib.h>
#include <string.h>
#include <errno.h>

@implementation NSData (PWExtensions)

- (NSData *) decodeCOBS
{
    if (self.length == 0) return self;
    
    const Byte *ptr = self.bytes;
    NSUInteger length = self.length;
    NSMutableData *decoded = [NSMutableData dataWithLength:length];
    Byte *dst = decoded.mutableBytes;
    Byte *basedst = dst;
    
    const unsigned char *end = ptr + length;
    while (ptr < end)
    {
        NSInteger i, code = *ptr++;
        for (i=1; i<code; i++) *dst++ = *ptr++;
        if (code < 0xFF) *dst++ = 0;
    }
    
    decoded.length = (dst - basedst);
    return [NSData dataWithData:decoded];
}

- (NSData *)inflatedData
{
    if (self.length == 0) return self;
    
    //NSUInteger full_length = [self length];
    NSUInteger half_length = self.length / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: half_length];
    BOOL done = NO;
    NSInteger status;
    
    z_stream strm;
    strm.next_in = (Bytef *)self.bytes;
    strm.avail_in = (uInt)self.length;
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    //NSUInteger progressPercent = 0;

    if (inflateInit (&strm) != Z_OK) 
        return nil;
    while (!done)
    {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= decompressed.length)
            [decompressed increaseLengthBy: half_length];
        strm.next_out = decompressed.mutableBytes + strm.total_out;
        strm.avail_out = (uInt)(decompressed.length - strm.total_out);
        
       /* 
        // If progress tracking is needed again, we should use a block
        if(target)
        {
            NSUInteger newProgressPercent = (((CGFloat)strm.total_in) * 100.0f) / ((CGFloat)full_length);
            if(newProgressPercent - progressPercent > 0)
            {
                progressPercent = newProgressPercent;
                [target performSelector:selector withObject:[NSNumber numberWithDouble:((CGFloat)newProgressPercent)/100.0f]];
            }
        }*/
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) 
            done = YES;
        else if (status != Z_OK) 
            break;
    }
    if (inflateEnd (&strm) != Z_OK) 
        return nil;
    
    // Set real length.
    if (done)
    {
        decompressed.length = strm.total_out;
        return decompressed;
    }
    else 
        return nil;
}

- (NSData *)deflatedData
{
    NSUInteger totalLength = self.length;
    if(totalLength == 0)
        return self;
    
    z_stream strm;
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in = (Bytef *)self.bytes;
    strm.avail_in = (uInt)self.length;
    
    if (deflateInit(&strm, Z_DEFAULT_COMPRESSION) != Z_OK) 
        return nil;
    
    //NSUInteger progressPercent = 0;
    
    NSMutableData *compressed = [NSMutableData dataWithLength:16384*4];  // 64K chuncks for expansion
    NSUInteger compressedLength = compressed.length;
    do 
    {
        if (strm.total_out >= compressedLength)
        {
            [compressed increaseLengthBy: 16384*4];
            compressedLength += 16384*4;
           /* 
            // If progress tracking is needed again, we should use a block
            if(target && totalLength>1024*1024*3)
            {
                NSUInteger newProgressPercent = (((CGFloat)strm.total_in) * 100.0f) / (CGFloat)totalLength;
                if(newProgressPercent - progressPercent > 0)
                {
                    progressPercent = newProgressPercent;
                    [target performSelector:selector withObject:[NSNumber numberWithDouble:((CGFloat)newProgressPercent)/100.0f]];
                }
            }*/
        }
        
        strm.next_out = compressed.mutableBytes + strm.total_out;
        strm.avail_out = (uInt)(compressedLength - strm.total_out);
        
        deflate(&strm, Z_FINISH);  
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
    
    compressed.length = strm.total_out;
    return compressed;
}

#pragma mark - Diff und Patch
#pragma mark

NSString* uniqueNameForFile(NSString *path)
{
    NSString* originalPathWithoutExtension = path.stringByDeletingPathExtension;
    NSString* extension = path.pathExtension;
    NSInteger suffixCount = 2;
    while([NSFileManager.defaultManager fileExistsAtPath:path])
    {
        path = [NSString localizedStringWithFormat:@"%@_%02ld", originalPathWithoutExtension, (long)suffixCount++];
        if(extension.length)
            path = [path stringByAppendingPathExtension:extension];
    }
    return path;
}

- (BOOL)writeToFile:(NSString*)path atomically:(BOOL)flag createDirectories:(BOOL)createDirectories
{
    if(createDirectories)
    {
        NSString* parentPath = path.stringByDeletingLastPathComponent;
        if(parentPath.length)
            [NSFileManager.defaultManager createDirectoryAtPath:parentPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [self writeToFile:path atomically:flag];
}

- (NSString*)encodeBase64;
{
    return [self encodeBase64WithNewlines:YES];
}

- (NSString*)encodeBase64WithNewlines:(BOOL)encodeWithNewlines
{
    // note that NSDataBase64EncodingEndLineWithLineFeed represents a linebreak of \n only
    return [self base64EncodedStringWithOptions:encodeWithNewlines ? (NSDataBase64Encoding64CharacterLineLength|NSDataBase64EncodingEndLineWithLineFeed) : 0];
}

- (NSString*)encodeBase64WithNewlines:(BOOL)encodeWithNewlines
                  withCarriageReturns:(BOOL)encodeWithCarriageReturns
{
    NSDataBase64EncodingOptions options = 0;
    if(encodeWithNewlines || encodeWithCarriageReturns)
        options |= NSDataBase64Encoding64CharacterLineLength;
    if(encodeWithNewlines)
        options |= NSDataBase64EncodingEndLineWithLineFeed;
    if(encodeWithCarriageReturns)
        options |= NSDataBase64EncodingEndLineWithCarriageReturn;
    return [self base64EncodedStringWithOptions:options];
}


- (NSString*)encodeBase64URL
{
    NSUInteger length = self.length;
    const char* data = self.bytes;
    
    NSUInteger encodeLength = modp_b64w_encode_len (length);
    
    char* encodeBuffer = malloc (encodeLength);
    modp_b64w_encode (encodeBuffer, data, length);

    // Remove padding.
    --encodeLength; // position before trailing zero
    if (encodeBuffer[encodeLength - 1] == '.') {
        --encodeLength;
        if (encodeBuffer[encodeLength - 1] == '.')
            --encodeLength;
    }
    NSAssert (encodeBuffer[encodeLength - 1] != '.', @"more than two padding characters?");
    
    NSString* result = [[NSString alloc] initWithBytes:encodeBuffer
                                                length:encodeLength
                                              encoding:NSASCIIStringEncoding];
    free (encodeBuffer);

    return result;
}

- (instancetype)initWithBase64URLRepresentation:(NSString*)string
{
    NSUInteger stringLength = string.length;
    if (stringLength == 0)
        return nil;
    
    NSUInteger encodedLength = (stringLength + 3) / 4 * 4;
    NSAssert (encodedLength >= stringLength, nil);
    if (encodedLength - stringLength > 2)
        return nil;

    char* encodedBuffer = malloc (encodedLength);
    if (![string getBytes:encodedBuffer
                maxLength:stringLength
               usedLength:NULL
                 encoding:NSASCIIStringEncoding
                  options:0
                    range:NSMakeRange (0, stringLength)
           remainingRange:NULL])
    {
        free (encodedBuffer);
        return nil;
    }
    // Add padding characters
    for (NSUInteger i = stringLength; i < encodedLength; ++i)
         encodedBuffer[i] = '.';

    NSUInteger decodeLength = modp_b64w_decode_len (encodedLength);
    char* decodeBuffer = malloc (decodeLength);

    NSUInteger actualDecodeLength = modp_b64w_decode (decodeBuffer, encodedBuffer, encodedLength);
    free (encodedBuffer);

    if (actualDecodeLength <= 0) {
        free (decodeBuffer);
        return nil;
    }
    
    NSAssert (actualDecodeLength <= decodeLength, nil);
    self = [self initWithBytes:decodeBuffer length:actualDecodeLength];

    free (decodeBuffer);

    return self;
}

+ (NSData*)dataWithHexadecimalRepresentation:(NSString*)string
{
    return [[NSData alloc]initWithHexadecimalRepresentation:string];
}

- (NSString*)hexadecimalRepresentation
{
    static const char *hexChars = "0123456789abcdef";
    NSUInteger slen = self.length;
    NSUInteger dlen = slen * 2;
    const unsigned char *src = (const unsigned char *)self.bytes;
    char *dst = (char*)NSZoneMalloc(NSDefaultMallocZone(), dlen);
    NSUInteger spos = 0;
    NSUInteger dpos = 0;
    while (spos < slen)
    {
        unsigned char c = src[spos++];
        dst[dpos++] = hexChars[(c >> 4) & 0x0f];
        dst[dpos++] = hexChars[c & 0x0f];
    }
    NSString *string = [[NSString alloc] initWithBytes:dst length:dlen encoding:NSASCIIStringEncoding];
    NSZoneFree(NSDefaultMallocZone(), dst);
    return string;
}

- (instancetype)initWithHexadecimalRepresentation:(NSString*)string
{
    NSData  *d;
    const char  *src;
    const char  *end;
    unsigned char   *dst;
    NSUInteger  pos = 0;
    unsigned char   byte = 0;
    BOOL        high = NO;
    
    d = [string dataUsingEncoding: NSASCIIStringEncoding
             allowLossyConversion: YES];
    src = (const char*)d.bytes;
    end = src + d.length;
    dst = NSZoneMalloc(NSDefaultMallocZone(), d.length/2 + 1);
    
    while (src < end)
    {
        char        c = *src++;
        unsigned char   v;
        
        if (isspace(c))
        {
            continue;
        }
        if (c >= '0' && c <= '9')
        {
            v = c - '0';
        }
        else if (c >= 'A' && c <= 'F')
        {
            v = c - 'A' + 10;
        }
        else if (c >= 'a' && c <= 'f')
        {
            v = c - 'a' + 10;
        }
        else
        {
            pos = 0;
            break;
        }
        if (high == NO)
        {
            byte = v << 4;
            high = YES;
        }
        else
        {
            byte |= v;
            high = NO;
            dst[pos++] = byte;
        }
    }
    if (pos > 0 && high == NO)
    {
        self = [self initWithBytes: dst length: pos];
    }
    else
    {
        self = nil;
    }
    NSZoneFree(NSDefaultMallocZone(), dst);
    if (self == nil)
    {
        [NSException raise:NSInvalidArgumentException format:@"%@: invalid hexadeciaml string data",
            NSStringFromSelector(_cmd)];
    }
    return self;
}

- (NSData*)sha1
{
    char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(self.bytes, (CC_LONG)self.length, (unsigned char*)digest);
	return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}

- (NSString*)sha1String
{
    return self.sha1.hexadecimalRepresentation;
}

- (NSData *)gunzippedDataForHTTP:(BOOL)forHTTP
{
    if(self.length == 0) 
        return self;
    
    NSUInteger full_length = self.length;
    NSUInteger half_length = self.length / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    NSInteger status;
    
    NSInteger gzHeaderLength = forHTTP ? 10 : 0;
    z_stream strm;
    strm.total_out  = 0;
    strm.avail_in   = (uInt)(self.length - gzHeaderLength);
    strm.next_in    = (Bytef *)self.bytes + gzHeaderLength;
    strm.zfree      = Z_NULL;
    strm.zalloc     = Z_NULL;
    
    if(inflateInit2(&strm, forHTTP ? -15 : 15+32) != Z_OK) 
        return nil;
    while(!done)
    {
        if (strm.total_out >= decompressed.length)
            [decompressed increaseLengthBy: half_length];
        strm.next_out   = decompressed.mutableBytes + strm.total_out;
        strm.avail_out  = (uInt)(decompressed.length - strm.total_out);
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END)
            done = YES;
        else if (status != Z_OK)
            break;
    }
    if(inflateEnd (&strm) != Z_OK) 
        return nil;
    
    if(done)
    {
        decompressed.length = strm.total_out;
        return [NSData dataWithData: decompressed];
    }
    else 
        return nil;
}

- (NSData*)gunzippedData
{
    return [self gunzippedDataForHTTP:NO];
}

- (NSData*)httpGunzippedData
{
    return [self gunzippedDataForHTTP:YES];
}

NS_INLINE void wblPutLong(uLong x, NSMutableData *data) 
{
    for(NSUInteger n = 0; n < 4; n++) 
    {
        unsigned char c = (int)(x & 0xff);
        [data appendBytes:&c length:1];
        x >>= 8;
    }
}

- (NSData *)gzippedDataWithCompressionLevel:(NSInteger)_level 
{
    NSUInteger    len       = self.length;
    void          *src      = (void *)self.bytes;
    char          outBuf[4096];
    z_stream      out;
    NSMutableData *data = [NSMutableData dataWithCapacity:(len / 10 < 128) ? len : len / 10];
    out.zalloc    = (alloc_func)NULL;
    out.zfree     = (free_func)NULL;
    out.opaque    = (voidpf)NULL;
    out.next_out  = (Byte*)&outBuf;
    out.avail_out = sizeof(outBuf);
    out.next_in   = Z_NULL;
    out.avail_in  = 0;
    NSInteger errorCode = Z_OK;
    uLong crc = crc32(0L, Z_NULL, 0);
    errorCode = deflateInit2(&out, _level, Z_DEFLATED, -MAX_WBITS, 9, 0); 
    if(errorCode != Z_OK) 
        return nil;
    char buf[10] = 
    {
        0x1f, 0x8b,     // magic
        Z_DEFLATED, 0,  // flags
        0, 0, 0, 0,     // time
        0, 0x03         // flags
    };
    [data appendBytes:&buf length:10];
    
    out.next_in  = src;
    out.avail_in = (uInt)len;
    while(out.avail_in > 0) 
    {
        if (out.avail_out == 0) 
        {
            out.next_out = (void *)&outBuf; // reset buffer position
            unsigned outBufSize = sizeof(outBuf);
            [data appendBytes:&outBuf length:outBufSize];
            out.avail_out = outBufSize;
        }
        errorCode = deflate(&out, Z_NO_FLUSH);
        if (errorCode != Z_OK) 
        {
            NSLog(@"gzip error: error deflating chunk");
            if (out.state) 
                deflateEnd(&out);
            return nil;
        }
    }
    
    crc = crc32(crc, src, (uInt)len);
    BOOL done = NO;
    out.next_in  = NULL;
    out.avail_in = 0;
    while(YES) 
    {
        len = sizeof(outBuf) - out.avail_out;
        if (len > 0) 
        {
            [data appendBytes:&outBuf length:len];
            out.next_out  = (void *)&outBuf;
            out.avail_out = sizeof(outBuf);
        }
        if (done)
            break;
        errorCode = deflate(&out, Z_FINISH);
        done = (out.avail_out != 0 || errorCode == Z_STREAM_END);
        if (errorCode != Z_OK && errorCode != Z_STREAM_END)
            break;
    }
    if(errorCode != Z_STREAM_END) 
    {
        NSLog(@"gzip error: flushing failed");
        if(out.state) 
            deflateEnd(&out);
        return nil;
    }
    wblPutLong(crc, data);
    wblPutLong(out.total_in, data);
    if(out.state) 
        deflateEnd(&out);
    return data;
}

- (NSData *)httpGzippedData
{
    return [self gzippedDataWithCompressionLevel:/*Z_DEFAULT_COMPRESSION*/Z_BEST_SPEED];
}

- (uint8_t)byteAtIndex:(NSUInteger)index
{
    uint8_t byte;
    [self getBytes:&byte range:NSMakeRange(index, 1)];
    return byte;
}

#pragma mark - File Descriptors for writing to a file

typedef struct {
    __unsafe_unretained NSData* data;
    void *bytes;
    size_t length;
    size_t position;
} FileContext;

static int readfn(void *_ctx, char *buf, int nbytes)
{
    FileContext *ctx = (FileContext *)_ctx;

    if (nbytes <= 0)
        return 0;

    size_t sizeToRead = MIN((size_t)nbytes, ctx->length - ctx->position);
    memcpy(buf, ctx->bytes + ctx->position, sizeToRead);
    ctx->position += sizeToRead;

    return (int)sizeToRead;
}

static int writefn(void *_ctx, const char *buf, int nbytes)
{
    FileContext *ctx = (FileContext *)_ctx;

    if (ctx->position + nbytes > ctx->length) {
        ctx->length = ctx->position + nbytes;
        ((NSMutableData*)ctx->data).length = ctx->length;
        ctx->bytes = ((NSMutableData*)ctx->data).mutableBytes;
    }

    memcpy(ctx->bytes + ctx->position, buf, nbytes);
    ctx->position += nbytes;
    return nbytes;
}

static fpos_t seekfn(void *_ctx, off_t offset, int whence)
{
    FileContext *ctx = (FileContext *)_ctx;

    off_t reference;
    if (whence == SEEK_SET)
        reference = 0;
    else if (whence == SEEK_CUR)
        reference = ctx->position;
    else if (whence == SEEK_END)
        reference = ctx->length;
    else
        return -1;

    if (reference + offset >= 0 && reference + offset <= (off_t)ctx->length) {
        ctx->position = (size_t)(reference + offset);
        return ctx->position;
    }
    return -1;
}

static int closefn(void *_ctx)
{
    FileContext *ctx = (FileContext *)_ctx;
    CFRelease((__bridge CFTypeRef)ctx->data);
    free(ctx);

    return 0;
}

- (FILE*)createStreamForReadingReturningError:(NSError**)outError
{
    FileContext* ctx = calloc(1, sizeof(FileContext));
    ctx->data = CFRetain((__bridge CFTypeRef)(self));
    ctx->bytes = (void*)self.bytes;
    ctx->length = self.length;

    FILE* f = funopen(ctx, readfn, NULL, seekfn, closefn);
    if (!f) {
        if (outError)
            *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        CFRelease((__bridge CFTypeRef)(self));
        free(ctx);
    }
    return f;
}

@end

@implementation NSMutableData (PWExtensions)

- (FILE*)createStreamForReadingAndWritingReturningError:(NSError**)outError
{
    FileContext* ctx = calloc(1, sizeof(FileContext));
    ctx->data = CFRetain((__bridge CFTypeRef)(self));
    ctx->bytes = (void*)self.mutableBytes;
    ctx->length = self.length;

    FILE* f = funopen(ctx, readfn, writefn, seekfn, closefn);
    if (!f) {
        if (outError)
            *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        CFRelease((__bridge CFTypeRef)(self));
        free(ctx);
    }
    return f;
}

@end
