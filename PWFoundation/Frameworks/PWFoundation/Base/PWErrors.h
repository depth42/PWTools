//
//  PWErrors.h
//  PWFoundation
//
//  Created by Frank Illenberger on 07.04.09.
//
//

enum : NSInteger {
    PWCrossStoreRelationshipRecordCouldNotFindTargetDocumentError   = 1,
    PWCrossStoreRelationshipRecordDoubleUUIDError                   = 2,
    PWCrossStoreRelationshipRecordDoubleTargetError                 = 3,
    PWCrossStoreRelationshipAccessDeniedError                       = 4,
    PWCrossStoreRelationshipCouldNotResolveURLError                 = 5,
    PWCrossStoreRelationshipTargetStoreDoesNotExistError            = 6,
    PWCrossStoreRelationshipURLURIMismatchError                     = 7,
    PWInvalidUniqueURIError                                         = 8,
    PWUniqueIDLookupError                                           = 9,
    PWInvalidUniqueIDError                                          = 10,
    
    // To be used when a needed object is no longer useable during asynchronous processing.
    PWObjectHasBeenDisposedError                                    = 11,

    PWUnknownPersistentStoreIdentifierError                         = 12,
    PWUnknownEntityError                                            = 13,
    PWCantDeterminePersistentStoreVersionError                      = 14,

    PWValueTypeConversionError                                      = 20,
    PWYAMLParseError                                                = 30,
    PWAttributedStringParsingError                                  = 31,
    PWXMLCodingParsingError                                         = 32,
    PWPListCodingParsingError                                       = 33,
    PWFileWrapperIncorrectURLError                                  = 40,
    PWURLSchemeError                                                = 41,   // URL has not the expected scheme
    PWURLSecurityScopedAccessFailedError                            = 42,
    
    PWSQLiteError                                                   = 50,

    // Stand in error if an error object is needed and none was provided by a failing API.
    // Used by +[NSError ensureError:].
    PWGenericError                                                  = 60,
    
    PWDispatchIOChannelError                                        = 100,
    PWMediaDescriptionDigestValidationError                         = 200,
    PWMediaDescriptionUnsupportedSymbolicLinkError                  = 201,

    PWInvalidZipFileFormatError                                     = 300,
    PWInvalidZipFailedError                                         = 301,

    PWSMTPClientError                                               = 400,
    PWSMTPClientTimeoutError                                        = 401,

    PWHTTPClientError                                               = 500,
    PWHTTPClientTimeoutError                                        = 501,
    PWHTTPConnectionAlreadyInUseError                               = 502,
    PWHTTPInvalidChunkSizeError                                     = 503,
    PWHTTPInvalidChunkLengthError                                   = 504,

    PWFTPClientError                                                = 600,
    PWFTPClientTimeoutError                                         = 601,
    PWFTPConnectionAlreadyInUseError                                = 602,
    PWFTPConnectionUserCredentialsMissingError                      = 603,
    PWFTPDirectoryListingParseError                                 = 604,
    PWFTPConnectionUploadError                                      = 605,
    PWFTPConnectionDeleteError                                      = 606,
    PWFTPConnectionAuthenticationFailedError                        = 607,

    PWWebDAVClientError                                             = 700,

    PWDispatchIOSSLChannelError                                     = 800,
    PWInvalidSSLCertificateError                                    = 801,

    PWSocketErrror                                                  = 900,

    PWTarSourceNotFoundError                                        = 1000,
    PWTarBadBlockError                                              = 1001,
    
    PWKeychainOpenError                                             = 1100,
    PWKeychainCreateError                                           = 1101,
    PWKeychainDeleteItemError                                       = 1102,
    PWKeychainSetPasswordError                                      = 1103,
    PWKeychainGetPasswordError                                      = 1104,
    PWKeychainCreateAccessError                                     = 1105,
    PWKeychainCreateTrustedApplicationError                         = 1106,
    PWKeychainUnlockError                                           = 1107,
    PWKeychainImportError                                           = 1108,
    PWKeychainQueryError                                            = 1109,
    PWKeychainCreateIdentityError                                   = 1110,
    PWKeychainExportError                                           = 1111,
    
    PWOLEStorageError                                               = 1200,

    PWCertificateCreateError                                        = 1300,

    PWSystemCommandTaskError                                        = 1400,
};


extern NSString* const PWErrorDomain;
extern NSString* const PWUnderlyingErrorsKey;
extern NSString* const PWDispatchIOChannelErrorUnderlyingCodeKey;   // key containing the errno code of the underlying channel error as NSNumber. See errno.h.
