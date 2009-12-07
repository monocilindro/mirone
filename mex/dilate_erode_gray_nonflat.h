/*
 * Copyright 1993-2007 The MathWorks, Inc.
 * $Revision: 1.4.4.2 $  $Date: 2007/06/04 21:09:20 $
 *
 * This file contains a function body for implementing nonflat grayscale
 * erosion and dilation.  It can be used to instantiate various
 * functions for erosion and dilation on different numeric types
 * by #defining TYPE, COMPARE_OP, INIT_VAL, DO_ROUND, MIN_VAL, and MAX_VAL.  
 * Note that implementing dilation properly with this function body requires 
 * passing in a neighborhood walker constructed from a reflected neighborhood.
 */

(TYPE *In, TYPE *Out, mwSize num_elements, NeighborhoodWalker_T walker, double *height) {
    double val;
    double init_val = INIT_VAL;
    double new_val;

    for (mwSize p = 0; p < num_elements; p++) {
        mwSize q;
        mwSize neighbor_idx;

        val = init_val;
        nhSetWalkerLocation(walker, p);
        while (nhGetNextInboundsNeighbor(walker, &q, &neighbor_idx)) {
            new_val = (double) In[q] COMBINE_OP height[neighbor_idx];
            if (new_val COMPARE_OP val)
                val = new_val;
        }

#ifdef DO_ROUND
        val = (val < MIN_VAL) ? MIN_VAL : val;
        val = (val > MAX_VAL) ? MAX_VAL : val;
        val = (TYPE) floor(val + 0.5);
#endif /* DO_ROUND */

        Out[p] = (TYPE) val;
    }
}

#undef TYPE
#undef INIT_VAL
#undef DO_ROUND
#undef MIN_VAL
#undef MAX_VAL
#undef COMBINE_OP
#undef COMPARE_OP
