#ifndef _GSL_PERL_HELPER_
#define _GSL_PERL_HELPER_

#include "EXTERN.h"
#include <perl.h>
#include <XSUB.h>

#include <stdlib.h>

#define GSL_MAGIC_SIG 0xBEBE /* Uniq value */

static MAGIC* gsl_perl_mg_find (SV *sv, int type) {
        if (sv) {
                MAGIC *mg;
                for (mg = SvMAGIC (sv); mg; mg = mg->mg_moremagic) {
                        if (mg->mg_type == type && mg->mg_private == GSL_MAGIC_SIG)
                                return mg;
                }
        }
        return 0;
}

static SV * gsl_perl_bind_obj2perl(SV* sv, const char* perlclass, void* pointer) {
	SV * tie;
        HV * stash;
        MAGIC * mg;

        /* Create a tied reference. */
        tie = newRV_noinc (sv);
        stash = gv_stashpv (perlclass, GV_ADD);
        sv_bless (tie, stash);
        //sv_magic ((SV *) av, tie, PERL_MAGIC_tied, Nullch, 0);

        /* Associate the array with the original path via magic. */
        sv_magic (sv, 0, PERL_MAGIC_ext, (const char *) pointer, 0);

	//SvREADONLY_on(sv);

        mg = mg_find (sv, PERL_MAGIC_ext);

        /* Mark the mg as belonging to us. */
        mg->mg_private = GSL_MAGIC_SIG;

#if PERL_REVISION <= 5 && PERL_VERSION <= 6
        /* perl 5.6.x doesn't actually set mg_ptr when namlen == 0, so do it
         * now. */
        mg->mg_ptr = (char *) pointer;
#endif /* 5.6.x */

        return tie;
}

#define perl_obj(pointer,ctype,perlclass)				\
	({								\
		SV* ref=(SV*)newAV(); /*SV* obj=newSVrv(ref, #perlclass); \
				   sv_setiv(obj, (IV) (ctype*)pointer);	\
				   sv_setiv(obj, (IV) 42);*/		\
		SV* sv=gsl_perl_bind_obj2perl(ref, #perlclass, (void*)pointer); \
		sv;							\
	})

#define c_obj(_sv,ctype,perlclass)					\
	({								\
		MAGIC* mg;						\
		SV* sv=(_sv);						\
		( sv &&	SvROK (sv)					\
		  && sv_isobject(sv) && sv_derived_from(sv, #perlclass) \
		  && (mg = gsl_perl_mg_find (SvRV (sv), PERL_MAGIC_ext))) \
			? ((ctype*)mg->mg_ptr) : NULL;			\
	})

typedef struct CObject {
	SV* perlobj;
	SV* data_owner;
} CObject;

typedef struct MemArray {
	CObject plink;
	SV* perlobj;
	size_t datasize;
	void* data;
	int mortal;
} MemArray;

#define DEBUG_MEMARRAY(start, mem) \
	({	\
		SV* ref=(mem->perlobj && (SvROK(mem->perlobj))) ? SvRV(mem->perlobj) : 0; \
		fprintf(stderr, "*** " start				\
			"MemArray[%i] (data: %ld @ %p, perlobj %d @ %p [%i] " \
			"-> %d @ %p [%i]) @ %p\n",			\
			mem->mortal,					\
			mem->datasize, mem->data,			\
			mem->perlobj ? SvREFCNT(mem->perlobj) : 0,	\
			mem->perlobj,					\
			mem->perlobj ? SvTYPE(mem->perlobj) : 0,	\
			ref ? SvREFCNT(ref) : SvROK(mem->perlobj),	\
			ref ? ref : 0,					\
			ref ? SvTYPE(ref) : -1,				\
			mem);						\
	})

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
