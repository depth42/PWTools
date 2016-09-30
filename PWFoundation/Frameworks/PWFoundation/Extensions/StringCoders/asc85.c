
	const static char ascii85[]= "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+-;<=>?@^_`{|}~" ;
	const static unsigned char  dascii85[128]= {
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0, 62, 0, 63, 64, 65, 66, 0, 67, 68, 69, 70, 0, 71, 0, 0,
		0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 72, 73, 74, 75, 76,
		77, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
		25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 0, 0, 0, 78, 79,
		80, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
		51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 81, 82, 83, 84, 0 } ;

const char *	get_alphabet_a85(void) { return ascii85 ; }

const char *    pack_a85( unsigned long lval)
{
	static char result[6] ;
	char * pfill ;
	int istep ;

	if ( ! lval ) return "." ;

	pfill= result +5 ;
	*( pfill --)= '\0' ;

	for ( istep= 5 ; ( istep -- ) ; ) {
		*( pfill --)= ascii85[ lval % 85] ;
		lval /= 85 ;
	}

	return result ;
}

const char *    pack_a85e( unsigned long lval)	// pack without '.' shortcut
{
	static char result[6] ;
	char * pfill ;
	int istep ;

	pfill= result +5 ;
	*( pfill --)= '\0' ;

	for ( istep= 5 ; ( istep -- ) ; ) {
		*( pfill --)= ascii85[ lval % 85] ;
		lval /= 85 ;
	}

	return result ;
}

unsigned long   unpack_a85( const char * astr)
{
	long lval ;
	int istep, itrim ;

	if ( '.' == * astr ) return 0 ;

	for (istep= 5, lval= 0; ( * astr && istep ) ; istep -- )
		{ lval *= 85, lval += dascii85[ 0x7f & * ( astr ++)] ; }
	if ( istep ) {
			// trim out for short messages
		for ( itrim= 0 ; ( istep -- ) ; itrim += 8 ) { lval *= 85 ;  lval += 84 ; }
		lval >>= itrim ;
	}

	return lval ;
}

unsigned long   unpack_a85x( const char * astr, int * alen )	// pack with fragment tracking
{
	long lval ;
	int istep, itrim ;

	for (istep= 5, lval= 0; ( * astr && istep ) ; istep -- )
		{ lval *= 85, lval += dascii85[ 0x7f & * ( astr ++)] ; }
	if ( alen ) { * alen= ( 5 - istep ) ; }
	if ( istep ) {
			// trim out for short messages
		for ( itrim= 0 ; ( istep -- ) ; itrim += 8 ) { lval *= 85 ;  lval += 84 ; }
	}

	return lval ;
}

		////

void	encode_asc85(char * zbuf, int asz, const unsigned char * asrc, int alen)
{
	char c, * zfill ;
	const char * p ;
	unsigned long lval ;
	int istep ;

	if ( ! zbuf || ! asrc || ! asz ) return ;	// bad pointer, or no room for even a null terminator
	asz -- ;  // pre-reserve space for null

	for (zfill= zbuf ; (( alen & ~3 ) && ( asz >= 5 )) ; alen -= 4 )
	{
		lval= * (asrc ++) ;  lval <<= 8 ; lval |= * (asrc ++) ;  lval <<= 8 ;
		lval |= * (asrc ++) ;  lval <<= 8 ; lval |= * (asrc ++) ;

		;
		for ( p= pack_a85( lval); ( c= *( p ++) ) ; -- asz ) { *( zfill ++)= c ; }
	}

	if ( alen && ! ( alen & ~3 ) && ( asz >= ( alen +1 )))	// there's a fragment left, and still space
	{
			// pack 1,2 or 3 bytes
		lval= * (asrc ++) * (1L << 24) ;
		switch ( alen )
		{
			case 3:
				lval |= *( asrc ++) << 16 ;
				lval |= *( asrc ++) << 8 ;
				break ;
			case 2:
				lval |= *( asrc ++) << 16 ;
				break ;
		}

		for ( istep= alen +1, alen= 0, p= pack_a85e( lval) ; ( istep -- && ( *(zfill ++)= *(p ++) )) ; -- asz ) { }
	}

	if ( alen ) {  // src data left over
		if ( ! asz && ( zfill > zbuf ) ) { -- zfill ; }	// back up one to fit the error marker
		*( zfill ++)= '/' ;
	}

	* zfill= '\0' ;
}

int		decode_asc85(unsigned char * zdest, int asz, const char * asrc)
{
	int istep, ival ;
	unsigned long lval ;
	unsigned char * zfill= zdest ;

	if ( ! zdest || ! asz || ! asrc ) return -1 ;

	while ( asz && * asrc )
	{
		if ( '.' == * asrc ) {
			asrc ++ ;
			for ( istep= 4 ; ( istep -- && asz ) ; -- asz ) { *(zfill ++)= 0 ; }
			continue ;
		}

		lval= unpack_a85x( asrc, &ival ) ;
		asrc += ival ;
		if ( ival < 2 ) return -1 ;
		for ( istep= 32, ival -- ; ( istep && ival && asz ) ; -- ival, -- asz ) { istep -= 8 ;  *(zfill ++)= 0xff & ( lval >> istep ) ; }
	}

	return ( zfill - zdest ) ;
}

int		decode_asc85x(unsigned char * zdest, int asz, const char * asrc, int * zuse)
{
	int istep, ival ;
	unsigned long lval ;
	const char * ptr= asrc ;
	unsigned char * zfill= zdest ;

	if ( ! zdest || ! asz || ! asrc ) return -1 ;
	while (( asz > 4 ) && * ptr )
	{
		if ( '.' == * ptr ) {
			ptr ++ ;
			for ( istep= 4 ; ( istep -- && asz ) ; -- asz ) { *(zfill ++)= 0 ; }
			continue ;
		}

		lval= unpack_a85x( ptr, &ival ) ;
		if ( ival < 5 ) break ;
		*(zfill ++)= 0xff & ( lval >> 24 ) ;
		*(zfill ++)= 0xff & ( lval >> 16 ) ;
		*(zfill ++)= 0xff & ( lval >> 8 ) ;
		*(zfill ++)= 0xff & lval ;
		ptr += ival ;
		asz -= 4 ;
	}

	if ( zuse ) { * zuse= ( ptr - asrc ) ; }
	return ( zfill - zdest ) ;
}

