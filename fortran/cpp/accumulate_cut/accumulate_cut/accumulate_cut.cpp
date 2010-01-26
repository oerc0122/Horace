// accumulate_cut.cpp : Defines the exported functions for the DLL application.
//

#include "stdafx.h"
#include "accumulate_cut.h"
enum InputArguments {
	Pixel_data,
	Signal,
	Error,
	Npixels,
	CoordRotation_matrix,
	CoordShif_matrix,
	Scale_energy,
	Shift_energy,
	DataCut_range,
	Plot_axis,
	Program_settings,
	N_INPUT_Arguments
};
enum OutputArguments{ // unique ouptput arguments, 
	Actual_Pix_Range,
	Pixels_Ok,
	Pixels_Ind,
	Signal_modified,
	Error_Modified,
    Npixels_out,
	N_OUTPUT_Arguments
};
enum program_settings{
	Ignore_Nan,
	Ignore_Inf,
	Keep_pixels,
	N_Parallel_Processes,
	N_PROG_SETTINGS
};

const int PIXEL_DATA_WIDTH=9;
const int OUT_PIXEL_DATA_WIDTH=4;
/*
% Syntax:
[cut_range_pix, ok, ix, {s,e,npix -- modified on place} ] = accumulate_cut (s,e,npix,pixel_data,cut_range_pix,...
                                                                         cut_range, rot_ustep, trans_bott_left, ebin, trans_elo, pax,...
										                          		parameters)
% Accumulate signal into output arrays
%
%
% Input: (* denotes output argumnet with same name exists - exploits in-place working of Matlab R2007a)
% * s                Array of accumulated signal from all contributing pixels (dimensions match the plot axes)
% * e                Array of accumulated variance
% * npix             Array of number of contributing pixels
% * actual_pix_range Actual range of contributing pixels
%   cut_range     [2x4] array of the ranges of the data as defined by (i) output proj. axes ranges for
%                  integration axes (or plot axes with one bin), and (ii) step range (0 to no. bins)
%                  for plotaxes (with more than one bin)
%   rot_ustep       Matrix [3x3]     --|  that relate a vector expressed in the
%   trans_bott_left Translation [3x1]--|  frame of the pixel data to no. steps from lower data limit
%                                             r_step(i) = A(i,j)(r(j) - trans(j))
%   ebin            Energy bin width (plays role of rot_ustep for energy axis)
%   trans_elo       Bottom of energy scale (plays role of trans_bott_left for energy axis)
and parameters is the array of program parameters namely:
	parameters[0]->Ignore_Nan -- ignore pixels with NaN data
	parameters[1]->Ignore_Inf -- ignore pixels with Inf data
	parameters[2]->Keep_pixels -- Set to 1 if wish to retain the information about individual pixels; set to 0 if not
	parameters[3]->N_Parallel_Processes Number of threads to execute OMP code
if there are less parameters specified, then defaults are parameters[]={1,1,0,1}
%
% Output:
%   npix            Array of numbers of contributing pixels
%   actual_pix_range Actual range of contributing pixels
%   nPixel_retained Number of pixels that contribute to the cut
%   ok              If keep_pix==true: v(:,ok) are the pixels that are retained; otherwise =[]
%   ix              If keep_pix==true: column vector full bin index of each retained pixel; otherwise =[]
%
%
% Note:
        based on Matlab code of T.G.Perring   19 July 2007; C-version Alex Buts 02 July 2009
*/

void mexFunction(int nlhs, mxArray *plhs[ ],int nrhs, const mxArray *prhs[ ])
{ 

//* Check for proper number of arguments. */
{
  if(nrhs!=N_INPUT_Arguments&&nrhs!=N_INPUT_Arguments-1) {
    std::stringstream buf;
	buf<<"ERROR::Accomulate_cut needs "<<(short)N_INPUT_Arguments<<" or one less, but got "<<(short)nrhs<<" input arguments\n";
	mexErrMsgTxt(buf.str().c_str());
  }
  if(nlhs>N_OUTPUT_Arguments) {
    std::stringstream buf;
	buf<<"ERROR::Accomulate_cut may accept up to "<<(short)N_OUTPUT_Arguments<<" but requested to return"<<(short)nlhs<<" arguments\n";
    mexErrMsgTxt(buf.str().c_str());
  }

  for(int i=0;i<nrhs-1;i++){
	  if(prhs[i]==NULL){
		      std::stringstream buf;
			  buf<<"ERROR::Accomulate_cut=> argument N"<<i<<" undefined\n";
			  mexErrMsgTxt(buf.str().c_str());
	  }
  }
}
  
// inputs:
// associate and extract all inputs
//  pixel_data(9,:)              u1,u2,u3,u4,irun,idet,ien,s,e for each pixel,
//                               where ui are coords in projection axes of the pixel data in the file
  double const *pPixelData    = (double *)mxGetPr(prhs[Pixel_data]);
  mwSize  nPixDataRows        = mxGetM(prhs[Pixel_data]); 
  mwSize  nPixDataCols        = mxGetN(prhs[Pixel_data]);

// * s                           Array of accumulated signal from all contributing pixels (dimensions match the plot axes)
  double *pSignal             = (double *)mxGetPr(prhs[Signal]);
  int    nDimensions          = (int)mxGetNumberOfDimensions(prhs[Signal]);
  mwSize const*pmDims         =	mxGetDimensions(prhs[Signal]);
  long signalSize(1);
  for(int i=0;i<nDimensions;i++){	  signalSize*=pmDims[i];
  }
// * e                           Array of accumulated variance
  double *pError              = (double *)mxGetPr(prhs[Error]);
  double *pNpix               = (double *)mxGetPr(prhs[Npixels]);


  double const* rot_matrix    = (double *)mxGetPr(prhs[CoordRotation_matrix]);
  double const* shift_matrix  = (double *)mxGetPr(prhs[CoordShif_matrix]);
  double const  e_shift       = *mxGetPr(prhs[Shift_energy]);
  double const  ebin          = *mxGetPr(prhs[Scale_energy]);

  double const *data_limits    = (double *)mxGetPr(prhs[DataCut_range]);
// plot axis
  double const *pPAX           = mxGetPr(prhs[Plot_axis]);
  int    const nAxis           = mxGetN(prhs[Plot_axis]);

// program parameters; get from the data or use defaults
  mxArray *ppS(NULL);
  double  *pProg_settings;
  if(nrhs==N_INPUT_Arguments){
	pProg_settings       =(double *)mxGetPr(prhs[Program_settings]);
  }else{
    ppS = mxCreateDoubleMatrix(N_PROG_SETTINGS,1,mxREAL);
	pProg_settings    = (double *)mxGetPr(ppS);
	// supply defaults
	pProg_settings[Ignore_Nan]=1;	pProg_settings[Ignore_Inf]=1;	pProg_settings[Keep_pixels]=0;	pProg_settings[N_Parallel_Processes]=1;
  }


{// check the consistency of the input data
      if(nPixDataRows!=PIXEL_DATA_WIDTH){
    	  mexErrMsgTxt("Pixel data has to be a 9xN matrix where 9 is the number of pixels' data and N -- number of pixels");
      }
	  if(nDimensions<1 || nDimensions>4){
	       std::stringstream buf;
		   buf<<" Dimensions of the accumulated data can vary from 1 to 4 but currently it set to "<<nDimensions<<std::endl;
		   mexErrMsgTxt(buf.str().c_str());
	  }
	  if(nDimensions!=(int)mxGetNumberOfDimensions(prhs[Error])){
			mexErrMsgTxt(" Dimensions of the signal and error arrays has to be the same");
	  }
	  if(nDimensions!=(int)mxGetNumberOfDimensions(prhs[Npixels])){
			mexErrMsgTxt(" Dimensions of the n-pixel array has to be equal to the dimensions of the signal array");
	  }
	  mwSize const* pmErr =mxGetDimensions(prhs[Error]);
	  mwSize const* pmNpix=mxGetDimensions(prhs[Npixels]);
	  for(int i=0;i<nDimensions;i++){
		  if(pmDims[i]!=pmErr[i]||pmDims[i]!=pmNpix[i]){
		       std::stringstream buf;
			   buf<<" Shapes of signal, error and npix arrays has to coinside\n";
			   buf<<" but the direction and shapes are:"<<(short)i<<" "<<(short)pmDims[i]<<" "<<pmErr[i]<<" "<<pmNpix[i]<<std::endl;
		       mexErrMsgTxt(buf.str().c_str());
		  }
	  }

//*****
	  if(mxGetM(prhs[CoordRotation_matrix])!=3||mxGetN(prhs[CoordRotation_matrix])!=3){
	     mexErrMsgTxt(" Coordinates Rotation has to be a 3x3 matrix");
      }
      if(mxGetM(prhs[CoordShif_matrix])!=3||mxGetN(prhs[CoordShif_matrix])!=1){
	     mexErrMsgTxt(" Coordinates shift has to be a 1x3 matrix");
      }
      if(mxGetM(prhs[Scale_energy])!=1||mxGetN(prhs[Scale_energy])!=1){
	     mexErrMsgTxt(" Energy scale has to be a scalar");
      }
      if(mxGetM(prhs[Shift_energy])!=1||mxGetN(prhs[Shift_energy])!=1){
	       mexErrMsgTxt(" Energy shift has to be a scalar");
	  }
//*****
      if(mxGetM(prhs[DataCut_range])!=2||mxGetN(prhs[DataCut_range])!=OUT_PIXEL_DATA_WIDTH){
	        mexErrMsgTxt(" Data range has to be a 2x4 matrix");
      }
//
      if(mxGetM(prhs[Plot_axis])!=1||nAxis>4){
	  	 mexErrMsgTxt(" Plot axis has to be a vector of 0 to 4 numbers");
      }
      for(unsigned int i=0;i<mxGetN(prhs[Plot_axis]);i++){
	      if(pPAX[i]<1||pPAX[i]>4){
	       std::stringstream buf;
		   buf<<" Plot axis can vary from 1 to 4, while we get the number"<<(short)pPAX[i]<<" for the dimension"<<(short)i<<std::endl;
		   mexErrMsgTxt(buf.str().c_str());
		  }
	  }
	  if(nAxis!=nDimensions){
	       std::stringstream buf;
		   buf<<" number of output axis "<<nAxis<<" and number of data dimensions"<<nDimensions<<" are not equal";
		   mexErrMsgTxt(buf.str().c_str());
	  }
}//
//

// preprocess input arguments and identify the grid sizes
  mwSize grid_size[OUT_PIXEL_DATA_WIDTH];
	// integer axis indexes (taken from pPax)
  int iAxis[OUT_PIXEL_DATA_WIDTH]; // maximum value not to bother with alloc/delete

  for(int i=0;i<OUT_PIXEL_DATA_WIDTH;i++){	  grid_size[i]=0;
  }
  for(int i=0;i<nDimensions;i++){ iAxis[i]=iRound(pPAX[i]);
				                  grid_size[iAxis[i]-1]=iRound(pmDims[i]); // here iAxis[i]-1 to agree numbering of the arrays in Matlab with 
  }                                                 // c-arrays.
//****************************************************************************************************************
//* Create matrixes for the return arguments */
//****************************************************************************************************************
  mwSize dims[2]; // the dims will be used later too. 
  dims[0]=nPixDataCols;
  dims[1]=1;

  plhs[Pixels_Ok] =mxCreateLogicalArray(2,dims);
  mxLogical *ok = (mxLogical *)mxGetPr(plhs[Pixels_Ok]);
  if(!plhs[Pixels_Ok]){
	  mexErrMsgTxt(" Can not allocate memory for pixel validity array\n");
  }
  
  plhs[Actual_Pix_Range]= mxCreateDoubleMatrix(2,4, mxREAL);
  if(!plhs[Actual_Pix_Range]){
	  mexErrMsgTxt(" Can not allocate memory for actual pixel range matrix\n");
  }
  if(nlhs>Signal_modified){  // signals are returned in a new array
	  plhs[Signal_modified]= mxCreateNumericArray(nDimensions,pmDims, mxDOUBLE_CLASS,mxREAL);
	  if(!plhs[Signal_modified]){
   		  mexErrMsgTxt(" Can not allocate memory for modified signal, remove the signal array from output arrguments list to modify it in-place\n");
      }
	  double *pSignalNew=(double *)mxGetPr(plhs[Signal_modified]);
	  for(long i=0;i<signalSize;i++){
		  *(pSignalNew+i)=*(pSignal+i);
	  }
	  pSignal=pSignalNew; // and now we can do in-place modification of a new array
  }
  if(nlhs>Error_Modified){  // errors are returned in a new array
	  plhs[Error_Modified]= mxCreateNumericArray(nDimensions,pmDims, mxDOUBLE_CLASS, mxREAL);
	  if(!plhs[Error_Modified]){
   		  mexErrMsgTxt(" Can not allocate memory for modified error, remove the error array from output arrguments list to modify it in-place\n");
      }
	  double *pErrNew=(double *)mxGetPr(plhs[Error_Modified]);
	  for(long i=0;i<signalSize;i++){
		  *(pErrNew+i)=*(pError+i);
	  }
	  pError=pErrNew;
  }
  if(nlhs>Npixels_out){  // n-pixels are returned in a new array
	  plhs[Npixels_out]= mxCreateNumericArray(nDimensions,pmDims, mxDOUBLE_CLASS, mxREAL);
	  if(!plhs[Npixels_out]){
   		  mexErrMsgTxt(" Can not allocate memory for modified n-pixels, remove the n-pixels array from output arrguments list to modify it in-place\n");
      }
	  double *pNpNew=(double *)mxGetPr(plhs[Npixels_out]);
	  for(long i=0;i<signalSize;i++){
		  *(pNpNew+i)=*(pNpix+i);
	  }
	  pNpix=pNpNew;
  }
  double *pPixRange = (double *)mxGetPr(plhs[Actual_Pix_Range]);



  accumulate_cut(pSignal,pError,pNpix,
	             pPixelData,nPixDataCols,
	             ok, plhs[Pixels_Ind], pPixRange,
                 rot_matrix ,shift_matrix,ebin,e_shift, data_limits,
				 grid_size,iAxis,nAxis, pProg_settings);

  if(!iRound(pProg_settings[Keep_pixels])){ // if we do not keep pixels, let's free the array of the pixels in range
	    mxDestroyArray(plhs[Pixels_Ok]);
		dims[0]=0;
		dims[1]=0;
		plhs[Pixels_Ok]=mxCreateLogicalArray(2,dims);
  }

  if(ppS){
	  mxDestroyArray(ppS);
  }
}

void accumulate_cut(double *s, double *e, double *npix,
					double const* pixel_data,mwSize data_size,
                    mxLogical *ok,mxArray *&ix_final_pixIndex,double *actual_pix_range,
					double const* rot_ustep,double const* trans_bott_left,double ebin,double trans_elo, // transformation matrix
					double const* cut_range,
					mwSize grid_size[4],	int const *iAxis,int nAxis, 
					double const* pProg_settings)
{

double xt,yt,zt,Et,INF(0),NAN(0),
       pix_Xmin,pix_Ymin,pix_Zmin,pix_Emin,pix_Xmax,pix_Ymax,pix_Zmax,pix_Emax;
double ebin_inv(1/ebin);
bool  ignore_something,ignote_all;

//if we want to ignore nan and inf in the data
bool ignore_nan(false);
if(pProg_settings[Ignore_Nan]>FLT_EPSILON){	  ignore_nan=true;
 }
bool ignore_inf(false);
if(pProg_settings[Ignore_Inf]>FLT_EPSILON){   ignore_inf=true;
}
ignore_something=ignore_nan|ignore_inf;
ignote_all      =ignore_nan&ignore_inf;
if(ignore_nan){ 	NAN=mxGetNaN(); 
}
if(ignore_inf){  	INF=mxGetInf(); 
}



int num_OMP_Threads(1);
if(pProg_settings[N_Parallel_Processes]>1){
		num_OMP_Threads=(int)pProg_settings[N_Parallel_Processes];
}
bool keep_pixels(false);
if(pProg_settings[Keep_pixels]>FLT_EPSILON){   keep_pixels=true;
}

//int nRealThreads;
long i;
mwSize j0,i0;

bool   transform_energy;


//% Catch special (and common) case of energy being an integration axis to save calculations 
if(abs(ebin-1)<DBL_EPSILON && abs(trans_elo)<DBL_EPSILON){   	transform_energy=false;
}else{ 															transform_energy=true;
}

mwSize nPixel_retained(0);

mwSize  *ind     = (mwSize *)mxCalloc(4*data_size, sizeof(mwSize)); //working array of indexes of transformed pixels
if(!ind){  mexErrMsgTxt(" Can not allocate memory for array of indexes\n");
}

// min-max value initialization
actual_pix_range[0]=actual_pix_range[2]=actual_pix_range[4]=actual_pix_range[6]=std::numeric_limits<double>::max();
actual_pix_range[1]=actual_pix_range[3]=actual_pix_range[5]=actual_pix_range[7]=-actual_pix_range[0];
pix_Xmin=pix_Ymin=pix_Zmin=pix_Emin=std::numeric_limits<double>::max();
pix_Xmax=pix_Ymax=pix_Zmax=pix_Emax=-actual_pix_range[0];


omp_set_num_threads(num_OMP_Threads);

#pragma omp parallel default(none), private(i,i0,j0,xt,yt,zt,Et), \
	 shared(actual_pix_range,pixel_data,rot_ustep,trans_bott_left,cut_range,ok,ind, \
	 data_size,ignote_all,ignore_nan,ignore_inf,ignore_something,transform_energy, \
     NAN,INF,PIXEL_DATA_WIDTH,OUT_PIXEL_DATA_WIDTH ), \
	 firstprivate(pix_Xmin,pix_Ymin,pix_Zmin,pix_Emin, pix_Xmax,pix_Ymax,pix_Zmax,pix_Emax,\
				  trans_elo,ebin_inv), \
	 reduction(+:nPixel_retained)
{
//	#pragma omp master
//{
//    nRealThreads= omp_get_num_threads()
//	 mexPrintf(" n real threads %d :\n",nRealThread);}

#pragma omp for schedule(static,1)
	for(i=0;i<data_size;i++){
			i0=i*OUT_PIXEL_DATA_WIDTH;
            j0=i*PIXEL_DATA_WIDTH;

      // Check for the case when either data.s or data.e contain NaNs or Infs, but data.npix is not zero.
      // and handle according to options settings.
			ok[i]=true;
			if(ignore_something){
				if(ignote_all){
					if(pixel_data[j0+7]==INF||pixel_data[j0+7]==NAN||
					pixel_data[j0+8]==INF||pixel_data[j0+8]==NAN){
							ok[i]=false;
							continue;
					}
				}else if(ignore_nan){
					if(pixel_data[j0+7]==NAN||pixel_data[j0+8]==NAN){
						ok[i]=false;
						continue;
					}
				}else if(ignore_inf){
					if(pixel_data[j0+7]==INF||pixel_data[j0+8]==INF){
						ok[i]=false;
						continue;
					}
				}
			}

      // Transform the coordinates u1-u4 into the new projection axes, if necessary
	  //    indx=[(v(1:3,:)'-repmat(trans_bott_left',[size(v,2),1]))*rot_ustep',v(4,:)'];  % nx4 matrix 
			xt=pixel_data[j0  ]-trans_bott_left[0];
			yt=pixel_data[j0+1]-trans_bott_left[1];
			zt=pixel_data[j0+2]-trans_bott_left[2];

			if(transform_energy){
			//    indx(4)=[(v(4,:)'-trans_elo)*(1/ebin)];  % nx4 matrix
				Et=(pixel_data[j0+3]-trans_elo)*ebin_inv;
			}else{
//% Catch special (and common) case of energy being an integration axis to save calculations 
			//  indx(4)=[(v(4,:)'];  % nx4 matrix
				Et=pixel_data[j0+3];
			}

//  ok = indx(:,1)>=cut_range(1,1) & indx(:,1)<=cut_range(2,1) & indx(:,2)>=cut_range(1,2) & indx(:,2)<=urange_step(2,2) & ... 
//       indx(:,3)>=cut_range(1,3) & indx(:,3)<=cut_range(2,3) & indx(:,4)>=cut_range(1,4) & indx(:,4)<=cut_range(2,4);
			if(Et<cut_range[6]||Et>cut_range[7]){ ok[i]=false;		continue;
			}else{                                ok[i]=true;
			}

    		xt=xt*rot_ustep[0]+yt*rot_ustep[1]+zt*rot_ustep[2];
			if(xt<cut_range[0]||xt>cut_range[1]){ ok[i]=false;		continue;
			}else{									 
			}

			yt=xt*rot_ustep[3]+yt*rot_ustep[4]+zt*rot_ustep[5];
			if(yt<cut_range[2]||yt>cut_range[3]){ ok[i]=false;		continue;
			}

			zt=xt*rot_ustep[6]+yt*rot_ustep[7]+zt*rot_ustep[8];
			if(zt<cut_range[4]||zt>cut_range[5]){ ok[i]=false;		continue;
			}else{                                         			nPixel_retained++;
			}



//     indx=indx(ok,:);    % get good indices (including integration axes and plot axes with only one bin) 
			ind[i0  ]=(mwSize)floor(xt);
			ind[i0+1]=(mwSize)floor(yt);
			ind[i0+2]=(mwSize)floor(zt);
			ind[i0+3]=(mwSize)floor(Et);
	//	i0=nPixel_retained*OUT_PIXEL_DATA_WIDTH;    // transformed pixels;
//
//
//    actual_pix_range = [min(actual_pix_range(1,:),min(indx,[],1));max(actual_pix_range(2,:),max(indx,[],1))];  % true range of data 
			if(xt<pix_Xmin)pix_Xmin=xt;
			if(xt>pix_Xmax)pix_Xmax=xt;

			if(yt<pix_Ymin)pix_Ymin=yt;
			if(yt>pix_Ymax)pix_Ymax=yt;

			if(zt<pix_Zmin)pix_Zmin=zt;
			if(zt>pix_Zmax)pix_Zmax=zt;

			if(Et<pix_Emin)pix_Emin=Et;
			if(Et>pix_Emax)pix_Emax=Et;

	} // end for -- imlicit barrier;
#pragma omp critical
	{
		if(actual_pix_range[0]>pix_Xmin)actual_pix_range[0]=pix_Xmin;
		if(actual_pix_range[2]>pix_Ymin)actual_pix_range[2]=pix_Ymin;
		if(actual_pix_range[4]>pix_Zmin)actual_pix_range[4]=pix_Zmin;
		if(actual_pix_range[6]>pix_Emin)actual_pix_range[6]=pix_Emin;

		if(actual_pix_range[1]<pix_Xmax)actual_pix_range[1]=pix_Xmax;
		if(actual_pix_range[3]<pix_Ymax)actual_pix_range[3]=pix_Ymax;
		if(actual_pix_range[5]<pix_Zmax)actual_pix_range[5]=pix_Zmax;
		if(actual_pix_range[7]<pix_Emax)actual_pix_range[7]=pix_Emax;
	}
} // end parallel region

// 
if(nPixel_retained==0||!keep_pixels){
	 ix_final_pixIndex= mxCreateDoubleMatrix(0,0,mxREAL); // allocate empty matrix and 
	 data_size=0;                                     // set data size to skip the following loops
}else{
	 ix_final_pixIndex= mxCreateDoubleMatrix(nPixel_retained,1,mxREAL);
}
if(!ix_final_pixIndex){ // can not allocate memory for reduction; 
    mexErrMsgTxt(" Can not allocate memory for the transformed pixels indexes");
	return;
}
double *pFin_pix=(double *)mxGetPr(ix_final_pixIndex);

//0.25       2   79 indx = indx(:,pax); % Now keep only the plot axes with at least two bins 
// set up reduction axis ===>>>
long  nDimX(0),nDimY(0),nDimZ(0),nDimE(0); // reduction dimensions; if 0, the dimension is reduced;
long  nDimLength(1);
for(i=0;i<nAxis;i++){
	if      (iAxis[i]==1){	nDimX      =nDimLength;    nDimLength*=grid_size[0];
	}else if(iAxis[i]==2){	nDimY      =nDimLength;    nDimLength*=grid_size[1];
	}else if(iAxis[i]==3){	nDimZ      =nDimLength;    nDimLength*=grid_size[2];
	}else if(iAxis[i]==4){  nDimE      =nDimLength;    nDimLength*=grid_size[3];
	}
}
//<<<==== end of set-up reduction axesses

long ic(0),indl;
#pragma omp parallel default(none), private(i,i0,j0,indl), \
	       shared(ic,ok,pFin_pix,ind,e,s,npix,pixel_data,\
           data_size,OUT_PIXEL_DATA_WIDTH), \
           firstprivate(nDimX,nDimY,nDimZ,nDimE,keep_pixels)
{
#pragma omp for schedule(static,1)
for (i=0;i<data_size;i++){
       
		if(ok[i]){ // indx=indx(ok,:);    % get good indices (including integration axes and plot axes with only one bin)
			i0=i*OUT_PIXEL_DATA_WIDTH;
			j0=i*PIXEL_DATA_WIDTH;
//  0.62   2   83     s    = s    + accumarray(indx, v(8,ok), size(s)); 
//  0.61   2   84     e    = e    + accumarray(indx, v(9,ok), size(s)); 
//  0.39   2   85     npix = npix + accumarray(indx, ones(1,size(indx,1)), size(s)); 
			indl       = ind[i0]*nDimX+ind[i0+1]*nDimY+ind[i0+2]*nDimZ+ind[i0+3]*nDimE;
#pragma omp atomic
			s[indl]   +=pixel_data[j0+7];
#pragma omp atomic
			e[indl]   +=pixel_data[j0+8];
#pragma omp atomic
			npix[indl]++;
			if(keep_pixels){ 
#pragma omp critical
				{
				pFin_pix[ic]=indl+1; // +1 to be consistent with Matlab&Fortran indexing		
				ic++;
			    }
			}
		}
} // end for
} // end parallel;
	mxFree(ind);
}
