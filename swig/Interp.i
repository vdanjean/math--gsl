%module "Math::GSL::Interp"

%include "typemaps.i"
%include "gsl_typemaps.i"

%{
    #include "gsl/gsl_types.h"
    #include "gsl/gsl_interp.h"
%}

%include "gsl/gsl_types.h"
%include "gsl/gsl_interp.h"

%include "../pod/Interp.pod"
