%module "Math::GSL::MemArray"
%include "typemaps.i"
%include "gsl_typemaps.i"

%rename(DESTROY) MemArray_DESTROY;
%rename(allocate) MemArray_allocate;

void MemArray_DESTROY(MemArray* mem);
MemArray* MemArray_allocate(size_t sz, size_t nb);

%inline %{

typedef struct {
   int a;
   int b;
} essai;

MemArray* pass(MemArray* mem) { return mem; }

%}

%include "../pod/MemArray.pod"


%typemap(in) input_array_p {
    memarray_t *array;
    AV *tempav;
    I32 len;
    int i;
    size_t datasize;
    SV **tv;
    if (!SvROK($input))
        croak("Math::GSL : $$1_name is not a reference!");
    if (SvTYPE(SvRV($input)) != SVt_PVAV)
        croak("Math::GSL : $$1_name is not an array ref!");

    tempav = (AV*)SvRV($input);
    len = av_len(tempav);
    datasize = (len+1)*sizeof(double);
    array = (memarray_t*) malloc(datasize+sizeof(memarray_t));
    array->datasize=datasize;
    array->data=&array[1];
    $1 = ($1_type)array;
    for (i = 0; i <= len; i++) {
        tv = av_fetch(tempav, i, 0);
        (($1_type)(array->data))[i] = (double) SvNV(*tv);
    }
    SV* sv;
    sv = newSVuv((long)array);
    fprintf(stderr, "Allocate size %ld at %p, perl obj at %p\n",
        array->datasize, array, sv);
    sv = newSVrv(sv, "Math::GSL::MemArray");
    fprintf(stderr, "Blessed Allocate size %ld at %p, perl obj at %p\n",
        array->datasize, array, sv);
    array->perlobj=sv;
    //sv = sv_2mortal(sv);
    fprintf(stderr, "Blessed Mortal Allocate size %ld at %p, perl obj at %p\n",
        array->datasize, array, sv);
}

%typemap(in) array_p {
    memarray_t *array = 0;
    int i;
    SV *sv;
    sv=$input;
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Math::GSL::MemArray")) {
        croak("Math::GSL::MemArray : $$1_name is not a Math::GSL::MemArray!");
    }

    sv=SvRV(sv);
    array=(memarray_t*)SvUV(sv);
    
    $1=($1_type)array;
}

%typemap(out) array_p {
    memarray_t *array=(memarray_t *)$1;
    SV* sv=array->perlobj;
    fprintf(stderr, "return for size %ld at %p, perl obj at %p\n",
            array->datasize, array, sv);
    sv = SvREFCNT_inc(sv);
    fprintf(stderr, "return real for size %ld at %p, perl obj at %p\n",
            array->datasize, array, sv);
    $result = sv;
    argvi++;
}


