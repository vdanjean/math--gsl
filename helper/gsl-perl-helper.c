#include "gsl-perl-helper.h"

void MemArray_DESTROY(MemArray* mem) {
    DEBUG_MEMARRAY("Free1 ", mem);
    DEBUG_MEMARRAY("Free2 ", mem);
    Safefree(mem->data);
    DEBUG_MEMARRAY("Free3 ", mem);
    Safefree(mem);
    //free(mem->data);
    //free(mem);
}

MemArray* MemArray_allocate(size_t sz, size_t nb) {
    MemArray *mem;
    SV *ref;
    Newx(mem, 1, MemArray);
    //mem=malloc(sizeof(MemArray));
    if (!mem) {
      return NULL;
    }
    mem->datasize=sz*nb;
    mem->nb_elem=nb;
    fprintf(stderr, "Allocate %i bytes\n", mem->datasize);
    Newxc(mem->data, mem->datasize, char, void*);
    //mem->data=malloc(mem->datasize);
    if (!mem->data) {
      free(mem);
      return NULL;
    }
    ref=perl_obj(mem, MemArray, Math::GSL::MemArray);
    mem->perlobj=SvRV(ref);
    DEBUG_MEMARRAY("PreAllocate ", mem);
    sv_2mortal(ref);
    DEBUG_MEMARRAY("Allocate ", mem);
    {
	    MemArray* mem2=c_obj(ref,MemArray,Math::GSL::MemArray);
	    if (mem != mem2) {
		    fprintf(stderr,"Bad conversion: mem=%p\n", mem2);
		    abort();
	    }
	    SV* sv=ref; MAGIC*magic;
	    if (SvGMAGICAL(sv) && (magic=mg_find(sv, PERL_MAGIC_ext))
		&& (magic->mg_ptr==(void*)mem)) {
		    fprintf(stderr,"\n\nSucess convert\n\n");		    
	    } else {
		    fprintf(stderr,"ERROR: %d, %d\n", SvTYPE(sv), SVt_PVMG);
	    }
    }
    return mem;
}


/* These functions (C callbacks) calls the perl callbacks.
   Info for perl callback can be found using the 'void*params' parameter
*/
double call_gsl_function(double x , void *params){
    struct gsl_function_perl *F=(struct gsl_function_perl*)params;
    unsigned int count;
    double y;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVnv((double)x)));
    XPUSHs(F->params);
    PUTBACK;

    count = call_sv(F->function, G_SCALAR);
    SPAGAIN;

    if (count != 1)
            croak("Expected to call subroutine in scalar context!");

    y = POPn;

    PUTBACK;
    FREETMPS;
    LEAVE;
     
    return y;
}
double call_gsl_monte_function(double *x_array , size_t dim, void *params){
    struct gsl_monte_function_perl *F=(struct gsl_monte_function_perl*)params;
    unsigned int count;
    unsigned int i;
    AV* perl_array;
    double y;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    perl_array=newAV();
    sv_2mortal((SV*)perl_array);
    XPUSHs(sv_2mortal(newRV((SV *)perl_array)));
    for(i=0; i<dim; i++) {
            /* no mortal : it is referenced by the array */
            av_push(perl_array, newSVnv(x_array[i]));
    }
    XPUSHs(sv_2mortal(newSViv(dim)));
    XPUSHs(F->params);
    PUTBACK;

    count = call_sv(F->f, G_SCALAR);
    SPAGAIN;

    if (count != 1)
            croak("Expected to call subroutine in scalar context!");

    y = POPn;

    PUTBACK;
    FREETMPS;
    LEAVE;
     
    return y;
}
