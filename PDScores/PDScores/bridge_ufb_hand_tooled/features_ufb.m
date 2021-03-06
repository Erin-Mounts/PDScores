//% Receives raw features, normalization parameters and feature weights, and
//% computes user feedback value.
//% Inputs:
//%  ftvec - feature vector (1xN)
//%  wvec  - weight vector (Nx1)
//%  ilog  - list of features to apply logarithm (variance stabilization)
//%  ftmin - feature normalization vector minimum (1xN)
//%  ftmax - feature normalization vector maximum (1xN)
//%  fbmin - user feedback minimum
//%  fbmax - user feedback maximum
//% Outputs:
//%  fbnorm - normalized user feedback value
//%
//% (CC BY-SA 3.0) Max Little, 2014
// Objective-C port (CC BY-SA 3.0) Sage Bionetworks, 2015.

#import "bridge_ufb_hand_tooled.h"

//function fbnorm = features_ufb(ftvec,wvec,ilog,ftmin,ftmax,fbmin,fbmax)
double features_ufb(PDRealArray *ftvec, PDRealArray *wvec, PDIntArray *ilog, PDRealArray *ftmin, PDRealArray *ftmax, double fbmin, double fbmax)
{
    //
    //ftvecnorm = ftvec;
    PDRealArray *ftvecnorm = [ftvec copy];
    //ftvecnorm(:,ilog) = log10(ftvecnorm(:,ilog));
    PDIntArray *ftvecrows = [PDIntArray rowVectorFrom:1 to:ftvecnorm.rows];
    [ftvecnorm setElementsWithRowIndices:ftvecrows columnIndices:ilog fromArray:[[ftvecnorm subarrayWithRowIndices:ftvecrows columnIndices:ilog] log10]];
    //ftvecnorm = 2*((ftvecnorm-ftmin)./(ftmax-ftmin))-1;
    PDRealArray *ftdiff = [ftmax applyReal:^double(const double element, const double otherArrayElement) {
        return element - otherArrayElement;
    } withRealArray:ftmin];
    PDRealArray *ftvecdiff = [ftvecnorm applyReal:^double(const double element, const double otherArrayElement) {
        return element - otherArrayElement;
    } withRealArray:ftmin];
    ftvecnorm = [ftvecdiff applyReal:^double(const double element, const double otherArrayElement) {
        return 2.0 * (element / otherArrayElement) - 1.0;
    } withRealArray:ftdiff];

    //% Projection of features onto 1st PC to create simple user feedback
    //fb = ftvecnorm*wvec;
    PDRealArray *fb = [ftvecnorm matmult:wvec];

    //% Normalize and re-scale 0-100, clamp
    //fbnorm = max(min((fb-fbmin)/(fbmax-fbmin)*100,100),0);
    double fbnorm = MAX(MIN((fb.data[0] - fbmin) / (fbmax - fbmin) * 100.0, 100.0), 0.0);
    return fbnorm;
}
