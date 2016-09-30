
		//// pack operators

extern const char *		get_alphabet_a85(void) ;

extern const char *		pack_a85( unsigned long lval) ;
extern const char *		pack_a85e( unsigned long lval) ;  // pack without '.' shortcut

extern unsigned long	unpack_a85( const char * astr) ;
extern unsigned long	unpack_a85x( const char * astr, int * zlen ) ;	// unpack with fragment tracking

		//// buffer operators

extern void	encode_asc85(char * zdest, int asz, const unsigned char * asrc, int alen) ;
extern int	decode_asc85(unsigned char * zdest, int asz, const char * asrc) ;
extern int	decode_asc85x(unsigned char * zdest, int asz, const char * asrc, int * zuse) ;

