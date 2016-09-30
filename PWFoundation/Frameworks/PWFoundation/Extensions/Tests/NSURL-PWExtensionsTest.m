//
//  NSURL-PWExtensionsTest.m
//  PWFoundation
//
//  Created by Jens Eickmeyer on 02.11.12.
//
//

#import "NSURL-PWExtensionsTest.h"

#import "NSURL-PWExtensions.h"

@implementation NSURL_PWExtensionsTest

- (void)testPathWithoutStrippingTrailingSlash
{
    XCTAssertEqualObjects([[NSURL URLWithString:@"http://www.projectwizards.net/index.html"] pathWithoutStrippingTrailingSlash], @"/index.html");
    XCTAssertEqualObjects([[NSURL URLWithString:@"http://www.projectwizards.net/en"] pathWithoutStrippingTrailingSlash], @"/en");
    XCTAssertEqualObjects([[NSURL URLWithString:@"http://www.projectwizards.net/en/"] pathWithoutStrippingTrailingSlash], @"/en/");
    XCTAssertEqualObjects([[NSURL URLWithString:@"http://www.projectwizards.net/en/index.html"] pathWithoutStrippingTrailingSlash], @"/en/index.html");
}

- (void)testPunycode
{
    XCTAssertEqualObjects([NSURL IDNEncodedHostname:@"näse.de"], @"xn--nse-qla.de");
    XCTAssertEqualObjects([NSURL IDNEncodedHostname:@"nase.de"], @"nase.de");
}

- (void)testRelativeURLToURL
{
    NSURL* baseURL = [NSURL URLWithString:@"http://localhost/some/path"];
    NSURL* URL;
    NSURL* relativeURL;
    
    // Different hosts
    URL = [NSURL URLWithString:@"http://www.projectwizards.net/some/path/to/a/file.txt"];
    relativeURL = [URL relativeURLToURL:baseURL];
    XCTAssertEqual(relativeURL, baseURL);
    
    // Different schemes
    URL = [NSURL URLWithString:@"file://localhost/some/path/to/a/file.txt"];
    relativeURL = [URL relativeURLToURL:baseURL];
    XCTAssertEqual(relativeURL, baseURL);
    
    // Different ports
    URL = [NSURL URLWithString:@"http://localhost:8080/some/path/to/a/file.txt"];
    relativeURL = [URL relativeURLToURL:baseURL];
    XCTAssertEqual(relativeURL, baseURL);
    
    // Implicit host "localhost"
    URL = [NSURL URLWithString:@"http:///some/path/to/a/file.txt"];
    relativeURL = [baseURL relativeURLToURL:URL];
    XCTAssertEqualObjects(relativeURL.relativePath, @"to/a/file.txt");
}

@end
