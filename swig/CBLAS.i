%module "Math::GSL::CBLAS"
%include "typemaps.i"
%include "gsl_typemaps.i"

%{
    #include "gsl/gsl_cblas.h"
%}

%include "gsl/gsl_cblas.h"
%include "../pod/CBLAS.pod"
