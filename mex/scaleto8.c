/*--------------------------------------------------------------------
 *	Copyright (c) 2004-2019 by J. Luis
 *
 * 	This program is part of Mirone and is free software; you can redistribute
 * 	it and/or modify it under the terms of the GNU Lesser General Public
 * 	License as published by the Free Software Foundation; either
 * 	version 2.1 of the License, or any later version.
 * 
 * 	This program is distributed in the hope that it will be useful,
 * 	but WITHOUT ANY WARRANTY; without even the implied warranty of
 * 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * 	Lesser General Public License for more details.
 *
 *	Contact info: w3.ualg.pt/~jluis/mirone
 *--------------------------------------------------------------------*/

/*
 * Output a uint8 or uint16 matrix scaled to the [0-255] or [0-65535] range. The input matrix can have
 * any of the following types: double, single, Int32, Int16 and UInt16 
 *
 * Alternatively give two outputs to recover only z_min & z_max
 *
 * Note: In fact the scaling is done in [0-254] (or [0-65534]) and add 1 to the result. In this way the
 * the first color entry is reserved for the background color (NaNs). Apparently IVS uses the same
 * technique when scaling to uint16.
 *
 * Revision 1.0	18-Sep-2004 Joaquim Luis
 * Changes 	26-Oct-2004 - Added a test for uint8 with NaNs
 *		17-Apr-2006 - Added a noDataValue for ints
 *		28-Feb-2007 - Removed the mxIsNaN tests since they were superfluous
 *			      Added scaling to a [min max] vector either as a 3 or 4th arg
 *		06-Mar-2007 - Shit, the mxIsNaN tests were necessary. Also add test on nodata
 *		17-Dec-2007 - No change in the code but WARNING: [min max] option changes input grid
 *		05-Jan-2008 - Fix bug (z_4 instead of z_8) when Z was double and [new_min new_max] option
 *			      Do explicitly castings when using mxGetData()
 *		07-Jul-2008 - Let int8 (char) arrays be processed as well
 *		30-Oct-2008 - -8 | -16 scale to int without adding 1. Work with 3D arrays
 *		19-JAN-2009 - Test if NaN before scaling. This is worth doing.
 *		23-FEB-2009 - Do not scale int8 arrays if they have no negative values.
 *
 */

#ifndef MIN
#define MIN(x, y) (((x) < (y)) ? (x) : (y))	/* min and max value macros */
#endif
#ifndef MAX
#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#endif

/* For floats ONLY */
#define ISNAN_F(x) (((*(int32_T *)&(x) & 0x7f800000L) == 0x7f800000L) && \
                    ((*(int32_T *)&(x) & 0x007fffffL) != 0x00000000L))

#include "mex.h"
#include "float.h"
#include <time.h>

#if HAVE_OPENMP
#include <omp.h>
	#ifdef _MSC_VER
		#define OMP_PARF __pragma(omp parallel for private(i))
	#else
		#define OMP_PARF _Pragma("omp parallel for private(i)")
	#endif
	#if defined(_OPENMP) && (_OPENMP > 201200)
		#ifdef _MSC_VER
			#define OMP_PARF_MINMAX __pragma(omp parallel for reduction(min : min_val) reduction(max : max_val))
		#else
			#define OMP_PARF_MINMAX _Pragma("omp parallel for reduction(min : min_val) reduction(max : max_val)")
		#endif
	#else
		#define OMP_PARF_MINMAX 
	#endif
#else
	#define OMP_PARF
	#define OMP_PARF_MINMAX 
#endif

//int mxUnshareArray(mxArray *);

void scale_16(unsigned short int *ui_2, unsigned char *out8, unsigned short int *out16, int got_nodata,
              int got_limits, int scale_range, int scale8, int scale16, size_t np, int add_off, float nodata,
              float min_val, float max_val, float new_range, double *z_min, double *z_max);

/* --------------------------------------------------------------------------- */
/* the gateway function */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
	double  range8 = 1, *z_min, *z_max, *z_8, min8 = DBL_MAX, max8 = -DBL_MAX;
	double	*pNodata, *which_scale, *pLimits;
	float	range = 1, min_val = FLT_MAX, max_val = -FLT_MAX, *z_4, new_range, nodata;
	int     nx, ny, i, is_double = 0, is_single = 0, is_int32 = 0, is_int16 = 0, inodata = 0;
	int     is_uint16 = 0, is_int8 = 0, is_uint8 = 0, scale_range = 1, *i_4, scale8 = 1, scale16 = 0, nBands = 1;
	int     n_row, n_col, got_nodata = 0, got_limits = 0, add_off = 1, imin = INT_MAX, imax = INT_MIN;
	char	*i_1;
	short int *i_2;
	unsigned short int *ui_2 = NULL, *out16 = NULL;
	unsigned char *ui_1, *out8 = NULL;
	const int *dim_array;
	size_t np;
	clock_t tic;
 
  	/*  check for proper number of arguments */
	if((nrhs < 1 || nrhs > 3) || (nlhs < 1 || nlhs > 2)) {
		mexPrintf ("usage: img8  = scaleto8(Z);\n");
		mexPrintf (" 	   img8  = scaleto8(Z,8,noDataValue);\n");
		mexPrintf (" 	   img16 = scaleto8(Z,16);\n");
		mexPrintf (" 	   img16 = scaleto8(Z,16,noDataValue);\n");
		mexPrintf (" 	   img16 = scaleto8(Z,8|16,[new_min new_max]);\n");
		mexPrintf (" 	   img16 = scaleto8(Z,8|16,noDataValue,[new_min new_max]);\n");
		mexPrintf (" 	   [z_min,z_max] = scaleto8(Z);\n");
		return;
	}

#ifdef MIR_TIMEIT
	tic = clock();
#endif

	/* Find out in which data type was given the input array */
	if (mxIsDouble(prhs[0])) {
		z_8 = mxGetPr(prhs[0]);
		is_double = 1;
	}
	else if (mxIsSingle(prhs[0])) {
		z_4 = (float *)mxGetData(prhs[0]);
		is_single = 1;
	}
	else if (mxIsInt32(prhs[0])) {
		i_4 = (int *)mxGetData(prhs[0]);
		is_int32 = 1;
	}
	else if (mxIsInt16(prhs[0])) {
		i_2 = (short int *)mxGetData(prhs[0]);
		is_int16 = 1;
	}
	else if (mxIsUint16(prhs[0])) {
		ui_2 = (unsigned short int *)mxGetData(prhs[0]);
		is_uint16 = 1;
	}
	else if (mxIsInt8(prhs[0])) {
		i_1 = (char *)mxGetData(prhs[0]);
		is_int8 = 1;
	}
	else if (mxIsUint8(prhs[0])) {
		ui_1 = (unsigned char *)mxGetData(prhs[0]);
		is_uint8 = 1;
	}
	else {
		mexPrintf("SCALETO8 ERROR: Unknown input data type.\n");
		mexErrMsgTxt("Valid types are:double, single, Int32, Int16, UInt16, UInt8 and Int8.\n");
	}

	/*  get the dimensions of the matrix input */
	ny = mxGetM(prhs[0]);
	nx = mxGetN(prhs[0]);
	if ((size_t)nx * ny == 1) mexErrMsgTxt("SCALETO8 ERROR: First input must be a matrix.");

	/* Check if 3D */
	if (mxGetNumberOfDimensions(prhs[0]) > 2) {
		dim_array = mxGetDimensions(prhs[0]);
		nx = dim_array[1];
		nBands = dim_array[2];
	}
	np = (size_t)nx * ny;
 
	if (nrhs == 1) {
		new_range = 254;		/* scale to uint8 */
		scale8 = 1;		scale16 = 0;
	}
	else {
		n_col = mxGetN (prhs[1]);
		if (n_col > 1)
			mexErrMsgTxt("SCALETO8 ERROR: Second argument must be a scalar == 8 or 16.");

		which_scale = mxGetPr(prhs[1]);
		if (*which_scale == 8) {
			new_range = 254;		/* scale to uint8 */
			add_off = 1;
		}
		else if (*which_scale == -8) {		/* scale to uint8 but do not add 1 */
			new_range = 255;
			add_off = 0;
		}
		else if (*which_scale == 16) { 
			new_range = 65534;		/* scale to uint16 */
			scale16 = 1;	scale8 = 0;
			add_off = 1;
		}
		else if (*which_scale == -16) {		 /* scale to uint16 but do not add 1 */
			new_range = 65535;
			scale16 = 1;	scale8 = 0;
			add_off = 0;
		}
		else
			mexErrMsgTxt("SCALETO8 ERROR: Second argument must be a scalar == 8 or 16.");

		if (nrhs >= 3) {
			n_row = mxGetM (prhs[2]);
			n_col = mxGetN (prhs[2]);
			if (n_row * n_col == 1) {
				pNodata = (double *)mxGetData(prhs[2]);
				nodata = (float)pNodata[0];
				got_nodata = 1;
			}
			else if (n_row == 1 && n_col == 2) {	/* Third arg is a [Lmin Lmax] vector */
				pLimits = (double *)mxGetData(prhs[2]);
				min8 = pLimits[0];		max8 = pLimits[1];
				if (!is_double) {min_val = (float)min8;		max_val = (float)max8;}
				got_limits = 1;
				//mxUnshareArray(prhs[0]);	/* Only matters if prhs[0] is a copy */
			}
			else
				mexErrMsgTxt("SCALETO8 ERROR: Third argument must be a scalar or a 1x2 vector.");

			if (nrhs == 4) {
				pLimits = (double *)mxGetData(prhs[3]);
				min8 = pLimits[0];		max8 = pLimits[1];
				if (!is_double) {min_val = (float)min8;		max_val = (float)max8;}
				got_limits = 1;
				//mxUnshareArray(prhs[0]);	/* Only matters if prhs[0] is a copy */
			}
			else if (nrhs > 4)
				mexErrMsgTxt("SCALETO8 ERROR: Hei stop! no more than four input args.");
		}
	}

	if (nlhs == 2) {
		if (got_limits) mexErrMsgTxt("SCALETO8 ERROR: No, No! no minmax inside grid bounds.");
		scale_range = 0;	/* Output min_val/max_val */
	}


	/*  set the output pointer to the output matrix */
	if (scale_range) {	/* If scale the output into new_range */
		/*  create a C pointer to a copy of the output matrix */
		if (scale8) {
			plhs[0] = mxCreateNumericArray(mxGetNumberOfDimensions(prhs[0]),
		  	                               mxGetDimensions(prhs[0]), mxUINT8_CLASS, mxREAL);
			out8 = (unsigned char *)mxGetData(plhs[0]);
		}
		else {
			plhs[0] = mxCreateNumericArray(mxGetNumberOfDimensions(prhs[0]),
		  	                               mxGetDimensions(prhs[0]), mxUINT16_CLASS, mxREAL);
			out16 = (unsigned short int *)mxGetData(plhs[0]);
		}
	}
	else {
		plhs[0] = mxCreateDoubleMatrix (1,1,mxREAL);
		plhs[1] = mxCreateDoubleMatrix (1,1,mxREAL);
		/*  create a C pointer to a copy of the output matrix */
		z_min = mxGetPr(plhs[0]);
		z_max = mxGetPr(plhs[1]);
	}

	if (is_double) {
		if (!got_limits) {
			for (i = 0; i < nx*ny; i++) {	/* Find min_val and max_val value */
				if (mxIsNaN(z_8[i])) continue;
				min8 = MIN(min8,z_8[i]);
				max8 = MAX(max8,z_8[i]);
			}
		}
		if (scale_range) {	/* Scale data into the new_range ([0 255] or [0 65535]) */ 
			if (max8 != min8)
				range8 = new_range / (max8 - min8);

			if (scale8) {	/* Scale to uint8 */
OMP_PARF
				for (i = 0; i < nx*ny; i++) { 	/* if z == NaN, out will be = 0 */
					if (mxIsNaN(z_8[i])) continue;
					if (got_limits) {
						if      (z_8[i] < min8) out8[i] = (char)add_off;
						else if (z_8[i] > max8) out8[i] = (char)((((float)max8 - min8) * range8) + add_off);
						else    out8[i] = (char)((((float)z_8[i] - min8) * range8) + add_off);
					}
					else
						out8[i] = (char)((((float)z_8[i] - min8) * range8) + add_off);
				}
			} 
			else if (scale16) {	/* Scale to uint16 */
OMP_PARF
				for (i = 0; i < nx*ny; i++) {
					if (mxIsNaN(z_8[i])) continue;
					if (got_limits) {
						if      (z_8[i] < min8) out16[i] = (unsigned short int)add_off;
						else if (z_8[i] > max8) out16[i] = (unsigned short int)((((float)max8 - min8) * range8) + add_off);
						else    out16[i] = (unsigned short int)((((float)z_8[i] - min8) * range8) + add_off);
					}
					else
						out16[i] = (unsigned short int)((((float)z_8[i] - min8) * range8) + add_off);
				}
			} 
		}
		else { 			/* min_val/max_val required */
			*z_min = min8;	*z_max = max8;
		}
	}
	else if (is_single) {
		if (!got_limits) {
OMP_PARF_MINMAX
			for (i = 0; i < nx*ny; i++) {
				if (ISNAN_F(z_4[i])) continue;
				if (z_4[i] < min_val) min_val = z_4[i];
				if (z_4[i] > max_val) max_val = z_4[i];
			}
		}
		if (scale_range) {	/* Scale data into the new_range ([0 255] or [0 65535]) */ 
			if (max_val != min_val)
				range = new_range / (max_val - min_val);

			if (scale8) {	/* Scale to uint8 */
OMP_PARF
				for (i = 0; i < nx*ny; i++) {	/* if z == NaN, out will be = 0 */
					if (ISNAN_F(z_4[i])) continue;
					if (got_limits) {
						if      (z_4[i] < min_val) out8[i] = (char)add_off;
						else if (z_4[i] > max_val) out8[i] = (char)((((float)max_val - min_val) * range) + add_off);
						else    out8[i] = (char)((((float)z_4[i] - min_val) * range) + add_off);
					}
					else
						out8[i] = (char)((((float)z_4[i] - min_val) * range) + add_off);
				}
			} 
			else if (scale16) {	/* Scale to uint16 */
OMP_PARF
				for (i = 0; i < nx*ny; i++) {
					if (ISNAN_F(z_4[i])) continue;
					if (got_limits) {
						if      (z_4[i] < min_val) out16[i] = (unsigned short int)add_off;
						else if (z_4[i] > max_val) out16[i] = (unsigned short int)((((float)max_val - min_val) * range) + add_off);
						else    out16[i] = (unsigned short int)((((float)z_4[i] - min_val) * range) + add_off);
					}
					else
						out16[i] = (unsigned short int)((((float)z_4[i] - min_val) * range) + add_off);
				} 
			} 
		}
		else { 			/* min_val/max_val required */
			*z_min = min_val;	*z_max = max_val;
		}
	}
	else if (is_int32) {
		if (!got_limits) {
			if (!got_nodata) {
				for (i = 0; i < nx*ny; i++) {
					if (i_4[i] < min_val) min_val = i_4[i];
					if (i_4[i] > max_val) max_val = i_4[i];
				}
			}
			else {
				for (i = 0; i < nx*ny; i++) {
					if ((float)i_4[i] == nodata) continue;
					if (i_4[i] < min_val) min_val = i_4[i];
					if (i_4[i] > max_val) max_val = i_4[i];
				}
			}
		}
		else {			/* Replace outside limits values by min_val | max_val */
			int min_i4, max_i4;
			min_i4 = (int)min_val;	max_i4 = (int)max_val;
			for (i = 0; i < nx*ny; i++) {
				if (got_nodata && (float)i_4[i] == nodata) continue;
				if (i_4[i] < min_i4) i_4[i] = min_i4;
				if (i_4[i] > max_i4) i_4[i] = max_i4;
			}
		}
		if (scale_range) {	/* Scale data into the new_range ([0 255] or [0 65535]) */ 
			if (max_val != min_val)
				range = new_range / (max_val - min_val);

			if (scale8) {	/* Scale to uint8 */
				for (i = 0; i < nx*ny; i++) {
					if (got_nodata && (float)i_4[i] == nodata) continue;
					out8[i] = (char)(((float)i_4[i] - min_val) * range) + add_off;
				}
			}
			else if (scale16) {	/* Scale to uint16 */
				for (i = 0; i < nx*ny; i++) {
					if (got_nodata && (float)i_4[i] == nodata) continue;
					out16[i] = (unsigned short int)(((float)i_4[i] - min_val) * range) + add_off;
				}
			}
		}
		else { 			/* min_val/max_val required */
			*z_min = min_val;	*z_max = max_val;
		}
	}
	else if (is_int16) {
		if (!got_limits) {
			if (!got_nodata) {
OMP_PARF_MINMAX
				for (i = 0; i < nx*ny; i++) {
					if (i_2[i] < min_val) min_val = i_2[i];
					if (i_2[i] > max_val) max_val = i_2[i];
				}
			}
			else {
OMP_PARF_MINMAX
				for (i = 0; i < nx*ny; i++) {
					if ((float)i_2[i] == nodata) continue;
					if (i_2[i] < min_val) min_val = i_2[i];
					if (i_2[i] > max_val) max_val = i_2[i];
				}
			}
		}
		else {			/* Replace outside limits values by min_val | max_val */
			short int min_i2, max_i2;
			min_i2 = (short int)min_val;	max_i2 = (short int)max_val;
OMP_PARF_MINMAX
			for (i = 0; i < nx*ny; i++) {
				if (got_nodata && (float)i_2[i] == nodata) continue;
				if (i_2[i] < min_i2) i_2[i] = min_i2;
				if (i_2[i] > max_i2) i_2[i] = max_i2;
			}
		}
		if (scale_range) {	/* Scale data into the new_range ([0 255] or [0 65535]) */ 
			if (max_val != min_val)
				range = new_range / (max_val - min_val);

			if (scale8) {	/* Scale to uint8 */
				for (i = 0; i < nx*ny; i++) {
					if (got_nodata && (float)i_2[i] == nodata) continue;
					out8[i] = (char)(((float)i_2[i] - min_val) * range) + add_off;
				}
			}
			else if (scale16) {	/* Scale to uint16 */
				for (i = 0; i < nx*ny; i++) {
					if (got_nodata && (float)i_2[i] == nodata) continue;
					out16[i] = (unsigned short int)(((float)i_2[i] - min_val) * range) + add_off;
				}
			}
		}
		else { 			/* min_val/max_val required */
			*z_min = min_val;	*z_max = max_val;
		}
	}
	else if (is_uint16) {
		for (i = 0; i < nBands; i++) {
			if (scale8)
				scale_16(&ui_2[np*i], &out8[np*i], out16, got_nodata, got_limits, scale_range, scale8, scale16, np,
				         add_off, nodata, min_val, max_val, new_range, z_min, z_max);
			else if (scale16)
				scale_16(&ui_2[np*i], out8, &out16[np*i], got_nodata, got_limits, scale_range, scale8, scale16, np,
				         add_off, nodata, min_val, max_val, new_range, z_min, z_max);
			/* The else case would compute global min_val max_val (with some more coding). Idiot thing to do */
		}

	}
	else if (is_int8) {	/* This whole case is a bit stupid */
		if (got_limits)
			mexErrMsgTxt("SCALETO8 ERROR: Asking for limits on a INT8 array is not availabe (does it make sense?).");

		if (!got_nodata) {
			for (i = 0; i < nx*ny; i++) {
				min_val = MIN(min_val,i_1[i]);
				max_val = MAX(max_val,i_1[i]);
			}
		}
		else {
			for (i = 0; i < nx*ny; i++) {
				if ((float)i_1[i] == nodata) continue;
				min_val = MIN(min_val,i_1[i]);
				max_val = MAX(max_val,i_1[i]);
			}
		}

		if (scale_range) {	/* Scale data into the new_range ([0 255] or [0 65535]) */ 
			if (max_val != min_val)
				range = new_range / (max_val - min_val);

			if (min_val >= 0 && scale8) {	/* There is nothing to scale here */ 
				for (i = 0; i < nx*ny; i++)
					out8[i] = (char)i_1[i];
			}
			else if (scale8) {	/* Scale to uint8 */
				for (i = 0; i < nx*ny; i++) {
					if (got_nodata && (float)i_1[i] == nodata) continue;
					out8[i] = (char)(((float)i_1[i] - min_val) * range) + add_off;
				}
			}
			else if (scale16) {	/* Scale to uint16 - IDIOT thing to do but ... */
				for (i = 0; i < nx*ny; i++) {
					if (got_nodata && (float)i_1[i] == nodata) continue;
					out16[i] = (unsigned short int)(((float)i_1[i] - min_val) * range) + add_off;
				}
			}
		}
		else { 			/* min_val/max_val required */
			*z_min = min_val;	*z_max = max_val;
		}
	}
	else if (is_uint8) {	/* This case is used to mimic the effect of CLim */
		unsigned char min_i1 = 255, max_i1 = 0;
		//min_i1 = (unsigned char)min_val;	max_i1 = (unsigned char)max_val;

		if (!got_limits) {
OMP_PARF_MINMAX
			for (i = 0; i < nx*ny; i++) {
				if (ui_2[i] < min_i1) ui_2[i] = min_i1;
				if (ui_2[i] > max_i1) ui_2[i] = max_i1;
			}
			min_val = min_i1;		max_val = max_i1;
		}
		else {
			if (!scale_range) {
OMP_PARF_MINMAX	
				for (i = 0; i < nx*ny; i++) {
					if (ui_1[i] < min_val) min_val = ui_1[i];
					if (ui_1[i] > max_val) max_val = ui_1[i];
				}
			}
		}
		if (scale_range) {	/* Scale data into the new_range ([0 255]) */ 
			if (max_val != min_val)
				range = new_range / (max_val - min_val);

			if (scale8) {
OMP_PARF
				for (i = 0; i < nx*ny; i++) {
					if      (ui_1[i] >= max_val) out8[i] = 255;		/* Need IFs because C wraps, not trims */
					else if (ui_1[i] <= min_val) out8[i] = 0;
					else    out8[i] = (char)(((float)ui_1[i] - min_val) * range + add_off);
				}
			}
		}
		else { 			/* min_val/max_val required */
			*z_min = min_val;	*z_max = max_val;
		}
	}

#ifdef MIR_TIMEIT
	mexPrintf("SCALETO8: CPU ticks = %.3f\tCPS = %d\n", (double)(clock() - tic), CLOCKS_PER_SEC);
#endif

}

/* ----------------------------------------------------------------------------------------------------------- */
void scale_16(unsigned short int *ui_2, unsigned char *out8, unsigned short int *out16, int got_nodata,
              int got_limits, int scale_range, int scale8, int scale16, size_t np, int add_off, float nodata,
              float min_val, float max_val, float new_range, double *z_min, double *z_max) {
	/* Make it a separate function so that it can be called for each band */
	long long i;
	int     inodata = 0, imin = INT_MAX, imax = INT_MIN;
	float	range = 1;

	if (!got_nodata) {
		if (!got_limits) {		/* Otherwise we don't need to find min_val/max_val */
OMP_PARF_MINMAX
			for (i = 0; i < np; i++) {
				if (ui_2[i]) {			/* Assume 0 is nodata, so jump it */
					if (ui_2[i] < imin) imin = ui_2[i];
					if (ui_2[i] > imax) imax = ui_2[i];
				}
			}
			got_nodata = 1;	nodata = 0;
		}
		else {
			imin = (int)min_val;	imax = (int)max_val;
		}
	}
	else {
		if (!got_limits) {		/* Otherwise we don't need to find min_val/max_val */
			inodata = (int)nodata;
OMP_PARF_MINMAX
			for (i = 0; i < np; i++) {
				if (ui_2[i] != inodata) {
					if (ui_2[i] < imin) imin = ui_2[i];
					if (ui_2[i] > imax) imax = ui_2[i];
				}
			}
		}
		else {
			imin = (int)min_val;	imax = (int)max_val;
		}
	}

	if (scale_range) {	/* Scale data into the new_range ([0 255] or [0 65535]) */ 
		unsigned short int min_ui2, max_ui2;
		min_ui2 = (unsigned short int)imin;		max_ui2 = (unsigned short int)imax;
		if (imax != imin)
			range = new_range / (imax - imin);

		inodata = (int)nodata;
		if (scale8) {	/* Scale to uint8 */
OMP_PARF
			for (i = 0; i < np; i++) {
				if (got_nodata && ui_2[i] == inodata) continue;
				if (got_limits) {
					if      (ui_2[i] < min_ui2) out8[i] = (char)add_off;
					else if (ui_2[i] > max_ui2) out8[i] = (char)((((float)max_ui2 - min_ui2) * range) + add_off);
					else    out8[i] = (char)((((float)ui_2[i] - min_ui2) * range) + add_off);
				}
				else
					out8[i] = (char)((((float)ui_2[i] - min_ui2) * range) + add_off);
			}
		}
		else if (scale16) {	/* Scale to uint16 */
OMP_PARF
			for (i = 0; i < np; i++) {
				if (got_nodata && ui_2[i] == inodata) continue;
				if (got_limits) {
					if      (ui_2[i] < min_ui2) out16[i] = (unsigned short int)add_off;
					else if (ui_2[i] > max_ui2) out16[i] = (unsigned short int)((((float)max_ui2 - min_ui2) * range) + add_off);
					else    out16[i] = (unsigned short int)((((float)ui_2[i] - min_ui2) * range) + add_off);
				}
				else
					out16[i] = (unsigned short int)((((float)ui_2[i] - min_ui2) * range) + add_off);
			}
		}
	}
	else { 			/* min_val/max_val required */
		*z_min = imin;	*z_max = imax;
	}
}