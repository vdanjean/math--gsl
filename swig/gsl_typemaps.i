%ignore GSL_MAJOR_VERSION;
%ignore GSL_MINOR_VERSION;
%include "system.i"
%ignore GSL_NEGZERO;
%ignore GSL_POSZERO;
%include "gsl/gsl_nan.h"
#if defined(GSL_MINOR_VERSION) &&  GSL_MINOR_VERSION >= 12
    %include "gsl/gsl_inline.h"
#endif

%{
    #include "gsl/gsl_nan.h"
    #include "../helper/gsl-perl-helper.h"
%}

%typemap(out) MemArray* {
    if ($1 == NULL)
      croak("Invalid results: out of memory?");
    SvREFCNT_inc($1->perlobj);
    DEBUG_MEMARRAY("Return ", $1);
    $result = $1->perlobj;
    argvi++;
}

%typemap(in) MemArray* {
    $1=c_obj($input,MemArray,Math::GSL::MemArray);
    if (!$1) {
      croak("Math::GSL : $$1_name is not a MemArray!");
    }
    DEBUG_MEMARRAY("Input ",$1);
}

%define MEMARRAY_TMAP_IN(ctype, perlctype, perlSvXV, const_kw)
  MemArray *MemArray$argnum = NULL;
  {
    MemArray * mem;
    if (!SvROK($input))
        croak("Math::GSL : $$1_name is not a reference!");
    do {
      if (SvTYPE(SvRV($input)) == SVt_PVAV) {
          AV * tempav = (AV*)SvRV($input);
          I32 len = av_len(tempav);
          int i;
          SV ** tv;
          mem = MemArray_allocate(sizeof(ctype), len);
          if (!mem)
             croak("Math::GSL : Out of memory");
          for (i = 0; i <= len; i++) {
             tv = av_fetch(tempav, i, 0);
             (($1_ltype)(mem->data))[i] = (ctype)(perlctype) perlSvXV(*tv);
          }
          break;
      } else {
          if (sv_isobject($input)
              && sv_derived_from($input, "Math::GSL::MemArray")) {
              mem = c_obj($input,MemArray,Math::GSL::MemArray);
          }
      }
      croak("Math::GSL : $$1_name is not something I can work with!");
    } while(0);
    $1 = mem->data;
    MemArray$argnum = mem;
    DEBUG_MEMARRAY("Using(in/"#const_kw " " #ctype ") ", mem);
  }
%enddef

%define MEMARRAY(ctype, perlctype, perlSvXV)
%typemap(in) const ctype* %{
  MEMARRAY_TMAP_IN(ctype, perlctype, perlSvXV, const)
%}
%typemap(in) ctype* %{
  MEMARRAY_TMAP_IN(ctype, perlctype, perlSvXV, )
%}
%typemap(argout) ctype* {
    MemArray *mem = MemArray$argnum;
    if (argvi >= items) {            
        EXTEND(sp,1);              /* Extend the stack by 1 object */
    }
    $result = SvREFCNT_inc(mem->perlobj);
    argvi++;
    DEBUG_MEMARRAY("Using(argout/" #ctype ") ", mem);
}
%typemap(argout) const ctype* %{
%}
%typemap(freearg) ctype* %{
%}
%typemap(freearg) const ctype* %{
%}
%typemap(out) ctype* {
    %#warning ctype not handled as 'out' type    
}
%apply ctype* { ctype[] };
%apply const ctype* { const ctype[] };
%enddef

MEMARRAY(long double, double, SvNV)
MEMARRAY(double, double, SvNV)
MEMARRAY(float, double, SvNV)

MEMARRAY(unsigned long, UV, SvUV)
MEMARRAY(long, IV, SvIV)
MEMARRAY(unsigned int, UV, SvUV)
MEMARRAY(int, IV, SvIV)
MEMARRAY(unsigned short, UV, SvUV)
MEMARRAY(short, IV, SvIV)
MEMARRAY(unsigned char, UV, SvUV)
MEMARRAY(char, IV, SvIV)

/********************************
 * For printf formats
 */
%typemap(in) const char* format {
    $1=SvPV_nolen($input);
}
%typemap(argout) const char* format %{ %}
%typemap(freearg) const char* format %{ %}

%apply const char* format {
    const char* range_format,
    const char* bin_format,
    const char* name,
    char* filename
};

/*****************************
 * handle some parameters as input or output
 */
/*
%apply int *OUTPUT { size_t *imin, size_t *imax, size_t *neval };
%apply double * OUTPUT {
    double * min_out, double * max_out,
    double *abserr, double *result
};
*/

/*****************************
 * Callback managment
 */
%typemap(in) gsl_monte_function * (struct gsl_monte_function_perl w_gsl_monte_function) {
    SV * f = 0;
    SV * dim = 0;
    SV * params = 0;
    size_t C_dim;

    if (SvROK($input) && (SvTYPE(SvRV($input)) == SVt_PVAV)) {
        AV* array=(AV*)SvRV($input);
        SV ** p_f = 0;
        if (av_len(array)<0) {
            croak("Math::GSL : $$1_name is an empty array!");
        }
        if (av_len(array)>2) {
            croak("Math::GSL : $$1_name is an array with more than 3 elements!");
        }
        p_f = av_fetch(array, 0, 0);
        f = *p_f;
        if (av_len(array)>0) {
            SV ** p_dim = 0;
            p_dim = av_fetch(array, 1, 0);
            dim = *p_dim;
        }
        if (av_len(array)>1) {
            SV ** p_params = 0;
            p_params = av_fetch(array, 1, 0);
            params = *p_params;
        }
    } else {
        f = $input;
    }

    if (!f || !(SvPOK(f) || (SvROK(f) && (SvTYPE(SvRV(f)) == SVt_PVCV)))) {
        croak("Math::GSL : $$1_name is not a reference to code!");
    }

    f = newSVsv(f);

    if (! dim) {
        dim=&PL_sv_undef;
        C_dim=0;
    } else {
        if (!SvIOK(dim)) {
            croak("Math::GSL : $$1_name is not an integer for dim!");
        }
        C_dim=SvIV(dim);
    }
    dim = newSVsv(dim);

    if (! params) {
        params=&PL_sv_undef;
    }
    params = newSVsv(params);
            
    w_gsl_monte_function.f = f;
    w_gsl_monte_function.dim = dim;
    w_gsl_monte_function.params = params;
    w_gsl_monte_function.C_gsl_monte_function.f = &call_gsl_monte_function;
    w_gsl_monte_function.C_gsl_monte_function.dim = C_dim;
    w_gsl_monte_function.C_gsl_monte_function.params   = &w_gsl_monte_function;
    $1         = &w_gsl_monte_function.C_gsl_monte_function;
};

%typemap(in) gsl_function * (struct gsl_function_perl w_gsl_function) {
    SV * function = 0;
    SV * params = 0;

    if (SvROK($input) && (SvTYPE(SvRV($input)) == SVt_PVAV)) {
        AV* array=(AV*)SvRV($input);
        SV ** p_function = 0;
        if (av_len(array)<0) {
            croak("Math::GSL : $$1_name is an empty array!");
        }
        if (av_len(array)>1) {
            croak("Math::GSL : $$1_name is an array with more than 2 elements!");
        }
        p_function = av_fetch(array, 0, 0);
        function = *p_function;
        if (av_len(array)>0) {
            SV ** p_params = 0;
            p_params = av_fetch(array, 1, 0);
            params = *p_params;
        }
    } else {
        function = $input;
    }

    if (!function || !(SvPOK(function) || (SvROK(function) && (SvTYPE(SvRV(function)) == SVt_PVCV)))) {
        croak("Math::GSL : $$1_name is not a reference to code!");
    }

    function = newSVsv(function);

    if (! params) {
        params=&PL_sv_undef;
    }
    params = newSVsv(params);
            
    w_gsl_function.params = params;
    w_gsl_function.function = function;
    w_gsl_function.C_gsl_function.params   = &w_gsl_function;
    w_gsl_function.C_gsl_function.function = &call_gsl_function;
    $1         = &w_gsl_function.C_gsl_function;
};

%typemap(freearg) gsl_monte_function * {
    struct gsl_monte_function_perl *p=(struct gsl_monte_function_perl *) $1->params;
    SvREFCNT_dec(p->f);
    SvREFCNT_dec(p->dim);
    SvREFCNT_dec(p->params);
};

%typemap(freearg) gsl_function * {
    struct gsl_function_perl *p=(struct gsl_function_perl *) $1->params;
    SvREFCNT_dec(p->function);
    SvREFCNT_dec(p->params);
};

/* TODO: same thing should be done for these kinds of callbacks */
%typemap(in) gsl_function_fdf * {
    fprintf(stderr, 'FDF_FUNC');
    return GSL_NAN;
}
