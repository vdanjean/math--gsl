#ifndef _GSL_PERL_HELPER_
#define _GSL_PERL_HELPER_

#include "EXTERN.h"
#include <perl.h>
#include <XSUB.h>

#include <stdlib.h>

#define perl_obj(pointer,ctype,perlclass) ({                 \
   SV* ref=newSViv(0); SV* obj=newSVrv(ref, #perlclass);     \
   sv_setiv(obj, (IV) (ctype*)pointer); SvREADONLY_on(obj);  \
   ref;                                                      \
})

#define c_obj(sv,ctype,perlclass) (                      \
   (sv_isobject(sv) && sv_derived_from(sv, #perlclass))  \
      ? ((ctype*)SvIV(SvRV(sv)))                         \
      : NULL                                             \
   )

typedef struct CObject {
	SV* perlobj;
	SV* data_owner;
} CObject;

typedef struct MemArray {
	CObject plink;
	SV* perlobj;
	size_t datasize;
	void* data;
} MemArray;

#define DEBUG_MEMARRAY(start, mem) \
   fprintf(stderr, start "MemArray (data: %ld @ %p, perlobj %d @ %p) @ %p\n", \
   mem->datasize, mem->data, mem->perlobj ? SvREFCNT(mem->perlobj) : 0, mem->perlobj, mem)

void MemArray_DESTROY(MemArray* mem);

MemArray* MemArray_allocate(size_t sz, size_t nb);



#include "gsl/gsl_math.h"
#include "gsl/gsl_monte.h"
/* structure to hold required information while the gsl function call
   for each callback
 */
struct gsl_function_perl {
    gsl_function C_gsl_function;
    SV * function;
    SV * params;
};
struct gsl_monte_function_perl {
    gsl_monte_function C_gsl_monte_function;
    SV * f;
    SV * dim;
    SV * params;
};

double call_gsl_function(double x , void *params);
double call_gsl_monte_function(double *x_array , size_t dim, void *params);

#endif
