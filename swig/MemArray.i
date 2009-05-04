%module "Math::GSL::MemArray"
%include "typemaps.i"
%include "gsl_typemaps.i"

%rename(DESTROY) MemArray_DESTROY;
%rename(allocate) MemArray_allocate;

void MemArray_DESTROY(MemArray* mem);
MemArray* MemArray_allocate(size_t sz, size_t nb);

%ignore perl_array_out;

%typemap(out) perl_array_out {
    MemArray *mem=(MemArray *)$1;
    AV *tempav;
    I32 len;
    int i;

    tempav = newAV();
    len = mem->nb_elem;
    fprintf(stderr,"OUT @ %p : ", mem->data);
    for (i = 0; i < len; i++) {
      double val=((double*)(mem->data))[i];
      fprintf(stderr, "%lf ", val);
      av_push(tempav, newSVnv((double)val));
    }
    fprintf(stderr, "\n");
    $result=newRV_noinc((SV*)tempav);
    argvi++;
}

%inline %{

typedef MemArray* perl_array_out;

MemArray* pass(MemArray* mem) { return mem; }

perl_array_out to_array(MemArray* mem) { return mem; }

%}

%include "../pod/MemArray.pod"


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


