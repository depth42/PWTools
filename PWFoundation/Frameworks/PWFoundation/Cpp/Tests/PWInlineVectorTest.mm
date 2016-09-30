//
//  PWInlineVectorTest.mm
//  PWFoundation
//
//  Created by Kai Brüning on 2.8.11.
//
//

#import "PWInlineVectorTest.h"
#import "PWInlineVector.hpp"

using namespace PWFoundation;

@implementation PWInlineVectorTest

template <typename T, int N>
bool isInlineBufferUsed (const inline_vector<T, N>& v)
{
    const void* dataPtr = reinterpret_cast<const void*>(&v.front());
    const inline_vector<T, N>* vAddress = &v;
    return dataPtr >= vAddress && dataPtr < vAddress + 1;
}

- (void) testWithPrimitiveType
{
    inline_vector<int, 3> v;
    
    XCTAssertEqual (v.capacity(), (inline_vector<int, 3>::size_type) 3);

    v.push_back (1);
    v.push_back (2);
    v.push_back (3);
    XCTAssertEqual (v.capacity(), (inline_vector<int, 3>::size_type) 3);
    XCTAssertEqual (v[2], 3);
    
    XCTAssertTrue (isInlineBufferUsed (v));
    
    v.push_back (4);
    XCTAssertTrue  (v.capacity() > 3);
    XCTAssertFalse (isInlineBufferUsed (v));
    v.push_back (5);
    XCTAssertEqual (v[2], 3);
    XCTAssertEqual (v[4], 5);
}

struct NonPOD
{
    NonPOD (int i) : i_ (i) {}
    NonPOD (const NonPOD& x) : i_ (x.i_) {}
    NonPOD& operator= (const NonPOD& x) { i_ = x.i_; return *this; }
    virtual int i() { return i_; }
    int i_;
};
    
- (void) testWithNonPODType
{
    inline_vector<NonPOD, 3> v;
    
    XCTAssertEqual (v.capacity(), (inline_vector<int, 3>::size_type) 3);
    
    v.push_back (NonPOD (1));
    v.push_back (NonPOD (2));
    v.push_back (NonPOD (3));
    XCTAssertEqual (v.capacity(), (inline_vector<int, 3>::size_type) 3);
    
    XCTAssertTrue (isInlineBufferUsed (v));
    
    v.push_back (NonPOD (4));
    XCTAssertTrue (v.capacity() > 3);
    XCTAssertFalse (isInlineBufferUsed (v));
    v.push_back (NonPOD (5));
    XCTAssertEqual (v[4].i(), 5);
}

- (void) testConstructors
{
    // Construction from single element value.
    inline_vector<int, 3> v1 (3, 5);
    XCTAssertEqual (v1.capacity(), (inline_vector<int, 3>::size_type) 3);
    XCTAssertEqual (v1[2], 5);
    XCTAssertTrue   (isInlineBufferUsed (v1));

    // Construction using an iterator range.
    int a[3] = { 1, 2, 3 };
    inline_vector<int, 3> v2 (a, a + 3);
    XCTAssertEqual (v2.capacity(), (inline_vector<int, 3>::size_type) 3);
    XCTAssertEqual (v2[2], 3);
    XCTAssertTrue   (isInlineBufferUsed (v2));

    // Construction from another inline_vector.
    v2.push_back (4);
    inline_vector<int, 4> v3 (v2);
    XCTAssertEqual (v3.size(), (inline_vector<int, 4>::size_type)4);
    XCTAssertEqual (v3[3], 4);
    XCTAssertTrue   (isInlineBufferUsed (v3));

    // Construction from a std::vector.
    std::vector<int> sv (3, 5);
    inline_vector<int, 4> v4 (sv);
    XCTAssertEqual (v4.size(), (inline_vector<int, 4>::size_type)3);
    XCTAssertEqual (v4[2], 5);
    XCTAssertTrue   (isInlineBufferUsed (v4));
    v4.push_back (6);
    XCTAssertTrue   (isInlineBufferUsed (v4));

    // Assignment is allowed accross different inline buffer sizes.
    v2 = v3;
    XCTAssertEqual (v2.size(), (inline_vector<int, 3>::size_type)4);
    XCTAssertEqual (v2[3], 4);
    XCTAssertFalse  (isInlineBufferUsed (v2));
}

@end
