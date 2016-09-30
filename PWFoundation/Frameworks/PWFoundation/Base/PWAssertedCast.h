//
//  PWAssertedCast.h
//  PWFoundation
//
//  Created by Berbie on 14.02.2013.
//
//

/*
 
 Simple lightweight type casting for cases like:
 
    NSView* myView = PWAssertedCast(NSView, viewArray[0]);
 
 */


#ifndef NDEBUG
    FOUNDATION_STATIC_INLINE id _PWAssertedCast(Class c, id object)
    {
        BOOL valid = (object == nil || [object isKindOfClass:c]); // transfer in tmp var to fix ipad2 32bit retain bug
        NSCAssert(valid, @"invalid object of class %@", NSStringFromClass(c));
        return object;
    }

    #define PWAssertedCast(c,o) _PWAssertedCast([c class], o)
#else
    #define PWAssertedCast(c,o) (id)(o)
#endif
