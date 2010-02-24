#include <mex.h>

#include <image.hpp>
#include <mx_wrapper.hpp>
#include <compute_nms.hpp>
#include <steerable_filtering.hpp>

template <int M>
static void dispatch(const image<2, double> & ima,
		     double sigma,
		     int nlhs,
		     mxArray *plhs[])
{
  unser_filtering<2, M> f(ima.size());

  f.compute(ima, sigma);

  ////////////////////////////
  // Allocate output arrays //
  ////////////////////////////

  if (nlhs > 0) image2mxArray(f.res(), plhs[0]);
  if (nlhs > 1) image2mxArray(f.theta(), plhs[1]);

  if (nlhs > 2)
    {
      /////////////////////////////////////
      // Compute non-maximal suppression //
      /////////////////////////////////////

      image<2, double> nms(ima.size());
  
      compute_nms(f.res(), f.theta(), nms);

      image2mxArray(nms, plhs[2]);
    }

  if (nlhs > 3)
    {
      int nfilters = unser_filtering<2, M>::nfilters;

      mwSize s[3];

      s[0] = ima.height();
      s[1] = ima.width();
      s[2] = nfilters;

      plhs[3] = mxCreateNumericArray(3, s, mxDOUBLE_CLASS, mxREAL);

      double * ptr = mxGetPr(plhs[3]);

      for (int i = 0; i < nfilters; ++i)
	{
	  f.fconvh(i).raw_data(ptr);
	  ptr += (s[0] * s[1]);
	}
    }
}

void mexFunction(int nlhs, mxArray *plhs[],
		 int nrhs, const mxArray *prhs[])
{
  /////////////////////////////////////////////////
  // Check number of input and output parameters //
  /////////////////////////////////////////////////

  if (nrhs < 3)
    mexErrMsgTxt("Three input arguments required.");

  if (nlhs > 4)
    mexErrMsgTxt("Too many output arguments");

  ////////////////////////////
  // Check input parameters //
  ////////////////////////////

  if (mxGetNumberOfDimensions(prhs[0]) != 2)
    mexErrMsgTxt("Invalid dimension for I argument.");

  if (!mxIsDouble(prhs[0]))
    mexErrMsgTxt("I is not a double-precision matrix.");

  if (mxGetNumberOfElements(prhs[1]) != 1)
    mexErrMsgTxt("Invalid dimension for M argument.");

  if (mxGetNumberOfElements(prhs[2]) != 1)
    mexErrMsgTxt("Invalid dimension for sigma argument.");

  //////////////////////////
  // Get input parameters //
  //////////////////////////

  int size[2];
  sizeWrapper<2>::convert(mxGetDimensions(prhs[0]), size);
  double* ptr = mxGetPr(prhs[0]);
  image<2, double> ima(size);
  ima.fill(ptr);

  int m = (int) *mxGetPr(prhs[1]);

  ptr = mxGetPr(prhs[2]);

  if (*ptr <= 0)
    mexErrMsgTxt("sigma must be strictly positive.");

  double sigma = *ptr;
  
  ///////////////////////
  // Compute filtering //
  ///////////////////////

  switch (m)
    {
    case 1: dispatch<1>(ima, sigma, nlhs, plhs); break;
    case 2: dispatch<2>(ima, sigma, nlhs, plhs); break;
    case 3: dispatch<3>(ima, sigma, nlhs, plhs); break;
    case 4: dispatch<4>(ima, sigma, nlhs, plhs); break;
    default: mexErrMsgTxt("Invalid order (M must be 1, 2, 3, or 4.");
    }
}
