#include "gsl-perl-helper.h"

void MemArray_DESTROY(MemArray* mem) {
    //SvREFCNT_dec(zt->p);
    DEBUG_MEMARRAY("Free1 ", mem);
    SvREFCNT_inc(SvRV(mem->perlobj));
    DEBUG_MEMARRAY("Free2 ", mem);
    SvREFCNT_dec(mem->perlobj);
    DEBUG_MEMARRAY("Free3 ", mem);
    Safefree(mem->data);
    Safefree(mem);
    //free(mem->data);
    //free(mem);
}

MemArray* MemArray_allocate(size_t sz, size_t nb) {
    MemArray *mem;
    Newx(mem, 1, MemArray);
    //mem=malloc(sizeof(MemArray));
    if (!mem) {
      return NULL;
    }
    mem->datasize=sz*nb;
    Newxc(mem->data, mem->datasize, char, void*);
    //mem->data=malloc(mem->datasize);
    if (!mem->data) {
      free(mem);
      return NULL;
    }
    mem->perlobj=perl_obj(mem, MemArray, Math::GSL::MemArray);
    DEBUG_MEMARRAY("PreAllocate ", mem);
    //mem->perlobj=sv_2mortal(mem->perlobj);
    sv_2mortal(SvRV(mem->perlobj));
    mem->mortal=1;
    DEBUG_MEMARRAY("Allocate ", mem);
    {
	    MemArray* mem2=c_obj(mem->perlobj,MemArray,Math::GSL::MemArray);
	    if (mem != mem2) {
		    fprintf(stderr,"Bad conversion: mem=%p\n", mem2);
		    abort();
	    }
	    SV* sv=mem->perlobj; MAGIC*magic;
	    if (SvGMAGICAL(sv) && (magic=mg_find(sv, PERL_MAGIC_ext))
		&& (magic->mg_ptr==mem)) {
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
