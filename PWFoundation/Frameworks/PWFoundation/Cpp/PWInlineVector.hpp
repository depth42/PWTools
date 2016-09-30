//
//  PWInlineVector.hpp
//  PWFoundation
//
//  Created by Kai Brüning on 2.8.11.
//
//

// TODO: most likely the inline buffer is put on the stack twice due to the allocator instance which is passed to
// the vector constructor. A fixed might be a dummy allocator type which returns the real inline allocator from rebind.

#ifndef PWFoundation_inline_vector_hpp
#define PWFoundation_inline_vector_hpp

#include <vector>

namespace PWFoundation {
    
    // An allocator with inline storage for N elements. Being a stateful allocator, it may have problems with some
    // STL implementations, but any such problems should be detected by the tests immediately.
    template <typename T, int N> class inline_allocator: public std::allocator<T>
    {
    public:
        typedef typename std::allocator<T> base_type;
        
        inline_allocator() {}
        inline_allocator (const inline_allocator&) {}
        ~inline_allocator() {}
        
        template <class U> 
        inline_allocator (const inline_allocator<U, N>&) {}
        
        template <class U> 
        struct rebind { typedef inline_allocator<U, N> other; };
        
        typename base_type::pointer allocate (typename base_type::size_type n, typename std::allocator<void>::const_pointer hint = 0)
        {
            // Note: the double cast via void* is needed under ARC for retainable object types.
            return (n == N) ? reinterpret_cast<typename base_type::pointer>(reinterpret_cast<void*>(buffer_))
                            : this->base_type::allocate (n, hint);
        }
        
        void deallocate (typename base_type::pointer p, typename base_type::size_type n)
        {
            if (static_cast<void*>(p) != buffer_)
                this->base_type::deallocate (p, n);
        }

    private:
        unsigned char   buffer_[sizeof (T[N])];

        void operator= (const inline_allocator&);   // made inaccessible
    };
    
    // Allocations are not interchangable between different instances of inline_allocator due to the use of the inline
    // buffer -> different instances must compare unequal.
    template <typename T, int N>
    inline bool operator== (const inline_allocator<T, N>& a1, const inline_allocator<T, N>& a2) {
        return &a1 == &a2;
    }
    
    template <typename T, int N>
    inline bool operator!= (const inline_allocator<T, N>& a1, const inline_allocator<T, N>& a2)
    {
        return &a1 != &a2;
    }
    
    
    // inline_vector reserves space for N elements inline in its data and otherwise behaves as std::vector.
    // Instances start out with capacity() == N.
    // If its capacity grows beyond N, normal heap allocation is used for all elements.
    template <typename T, int N> class inline_vector: public std::vector<T, inline_allocator<T, N> >
    {
    public:
        typedef typename std::vector<T, inline_allocator<T, N> > base_type;

        explicit inline_vector()
            : base_type (inline_allocator<T, N>())
        {
            this->reserve (N);
        }
        
        explicit inline_vector (typename base_type::size_type n, const T& value = T())
            : base_type (inline_allocator<T, N>())
        {
            this->reserve (N);
            this->insert (this->end(), n, value);
        }

        template <typename InputIterator>
        inline_vector (InputIterator first, InputIterator last)
            : base_type (inline_allocator<T, N>())
        {
            this->reserve (N);
            this->insert (this->end(), first, last);
        }

        // Construction from another inline_vector of same type and any buffer size.
        template <int N2>
        inline_vector (const inline_vector<T, N2>& x)
            : base_type (inline_allocator<T, N>())
        {
            this->reserve (N);
            this->insert (this->end(), x.begin(), x.end());
        }

        // Can't hurt: allow construction from std::vector of same type.
        template <typename Allocator>
        inline_vector (const std::vector<T, Allocator>& x)
            : base_type (inline_allocator<T, N>())
        {
            this->reserve (N);
            this->insert (this->end(), x.begin(), x.end());
        }
        
        template <int N2>
        inline_vector<T, N>& operator= (const inline_vector<T, N2>& x)
        {
            this->assign (x.begin(), x.end());
            return *this;
        }

    private:
        // swap is made unaccessible: it is unclear whether it can be supported at all, and it does not make much
        // sense because its constant complexity guarantee would be broken for sure.
        void swap (inline_vector<T, N>&);
    };
    
    // TODO: comparision operators

}   // namespace PWFoundation


#endif
