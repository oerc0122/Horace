#include "combine_sqw.h"
#include <algorithm>
#include <numeric>
#include <iomanip>
#include <chrono>

enum InputArguments {
  inFileParams,
  outFileParams,
  programSettings,
  N_INPUT_Arguments
};
enum OutputArguments { // unique output arguments,
  pix_data,
  npix_in_bins,
  pix_info,
  N_OUTPUT_Arguments
};


//--------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------
//
void pix_reader::run_read_job() {
  int log_level = param.log_level;


  size_t start_bin = param.nBin2read;
  size_t n_pixels_processed(0);

  //
  size_t n_bins_total = param.totNumBins;
  //
  //
  while (start_bin < n_bins_total && !Buff.is_interrupted()) {
    size_t n_buf_pixels(0);
    this->read_pix_info(n_buf_pixels, start_bin);

    //pixWriter.write_pixels(Buff);
    //new start bin is by one shifted wrt the last bin read
    start_bin++;
    //
    n_pixels_processed += n_buf_pixels;
  }
  Buff.set_write_allowed();
}
//
void pix_reader::read_pix_info(size_t &n_buf_pixels, size_t &n_bins_processed, uint64_t *nBinBuffer) {

  n_buf_pixels = 0;
  size_t first_bin = n_bins_processed;


  size_t n_files = this->fileReaders.size();
  const size_t nBinsTotal(this->param.totNumBins);
  size_t n_tot_bins(0);
  size_t npix, pix_start_num;
  //
  bool common_position(false);
  if (n_files == 1) {
    common_position = true;
  }

  float * pPixBuffer = Buff.get_read_buffer();
  size_t pix_buffer_size = Buff.pix_buf_size();
  size_t ii(0);

  for (size_t n_bin = first_bin; n_bin < nBinsTotal; n_bin++) {
    size_t cell_pix = 0;

    for (size_t i = 0; i < n_files; i++) {
      fileReaders[i].get_npix_for_bin(n_bin, pix_start_num, npix);
      cell_pix += npix;
    }

    n_bins_processed = n_bin;
    if (nBinBuffer) {
      nBinBuffer[n_bin] = cell_pix;
    }

    if (cell_pix == 0)continue;

    if (cell_pix + n_buf_pixels > pix_buffer_size) {
      if (n_bins_processed == 0) {
        if (n_buf_pixels == 0) {
          pPixBuffer = Buff.get_read_buffer(cell_pix);
          pix_buffer_size = Buff.pix_buf_size();
        }
        else {
          Buff.set_interrupted("==>output pixels buffer is to small to accommodate single bin. Increase the size of output pixels buffer");
          break;
        }
      }
      else {
        n_bins_processed--;
        break;
      }
    }


    for (size_t i = 0; i < n_files; i++) {
      fileReaders[i].get_pix_for_bin(n_bin, pPixBuffer, n_buf_pixels,
        pix_start_num, npix, common_position);
      n_buf_pixels += npix;
    }
  }
  // unlocks read buffer too
  Buff.set_and_lock_write_buffer(n_buf_pixels, n_bins_processed + 1);
}
//--------------------------------------------------------------------------------------------------------------------
//--------- MAIN COMBINE JOB -----------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------
/* combine range of input sqw files into single output sqw file */
void combine_sqw(ProgParameters &param, std::vector<sqw_reader> &fileReaders, const fileParameters &outPar) {

  exchange_buffer Buff(param.pixBufferSize, param.totNumBins, param.num_log_ticks);

  pix_reader Reader(param, fileReaders, Buff);

  sqw_pix_writer pixWriter(Buff);
  pixWriter.init(outPar, param.totNumBins);

  int log_level = param.log_level;

  std::thread reader([&Reader]() {
    Reader.run_read_job();
  });
  std::thread writer([&pixWriter]() {
    pixWriter.run_write_pix_job();
  });

  bool interrupted(false);
  //int count(0);
  std::mutex log_mutex;
  std::unique_lock<std::mutex> l(log_mutex);  
  int c_sensitivity(2000); // msc
  //mexPrintf("%s\n", "MEX::COMBINE_SQW: starting logging loop ");  
  //mexEvalString("pause(.002);");        
  while (!Buff.is_write_job_completed()) {
    //mexPrintf("%s%d\n", "MEX::COMBINE_SQW: log_loop: ",count);
    //mexEvalString("pause(.002);");            
    //count++;
    
    Buff.logging_ready.wait_for(l, std::chrono::milliseconds(c_sensitivity), [&Buff]() {return Buff.do_logging; });
    //mexPrintf("%s","before BUF Do logging in\n");          
    //mexEvalString("pause(.002);");    
    if (Buff.do_logging) {
      if (interrupted) {
        mexPrintf("%s", ".\n");
        mexEvalString("pause(.002);");
      }
      Buff.print_log_meassage(log_level);
    }
    //mexPrintf("%s","after BUF Do logging in\n");          
    //mexEvalString("pause(.002);");    
    
    if (utIsInterruptPending()) {
      if (!interrupted) {
        mexPrintf("%s", "MEX::COMBINE_SQW: Interrupting by CTRL-C ..");
        mexEvalString("pause(.002);");
        Buff.set_interrupted("==> C-code interrupted by CTRL-C");
        c_sensitivity = 1000;
      }
      interrupted = true;
    }
    //mexPrintf("%s","after check interrupt\n");
    //mexEvalString("pause(.002);");
    
    if (interrupted) {
      mexPrintf("%s", ".");
      mexEvalString("pause(.002);");
    }
  }
  reader.join();
  writer.join();


  if (interrupted) {
    mexPrintf("%s", ".\n");
    mexEvalString("pause(.002);");
  }
  else {
    Buff.print_final_log_mess(log_level);
  }


  if (Buff.is_interrupted()) {
    mexErrMsgIdAndTxt("MEX_COMBINE_SQW:interrupted", Buff.error_message.c_str());
  }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

  const char REVISION[] = "$Revision::      $ ($Date::                                              $)";
  if (nrhs == 0 && nlhs == 1) {
    plhs[0] = mxCreateString(REVISION);
    return;
  }
  //--------------------------------------------------------
  //-------   PROCESS PARAMETERS   -------------------------
  //--------------------------------------------------------

  bool debug_file_reader(false);
  size_t n_prog_params(4);
  // if pixel's run numbers id should be renamed and in which manned
  bool change_fileno(false), fileno_provided(true);
  size_t read_buf_size(4096);
  //* Check for proper number of arguments. */
  {
    if (nrhs != N_INPUT_Arguments) {
      std::stringstream buf;
      buf << "ERROR::combine_sqw needs " << (short)N_INPUT_Arguments << " but got " << (short)nrhs
        << " input arguments and " << (short)nlhs << " output argument(s)\n";
      mexErrMsgTxt(buf.str().c_str());
    }
    if (nlhs == N_OUTPUT_Arguments) {
      debug_file_reader = true;
    }
    n_prog_params = mxGetN(prhs[programSettings]);
    if (!(n_prog_params == 4 || n_prog_params == 8 || n_prog_params == 9)) {
      std::string err = "ERROR::combine_sqw => array of program parameter settings (input N 3) should have  4 or 8 or 9 elements but got: " +
        std::to_string(n_prog_params);
      mexErrMsgTxt(err.c_str());
    }

  }
  /********************************************************************************/
  /* retrieve input parameters */
  // Pointer to list of file parameters to process. The parameters may change as
  // module takes more from Matlab code
  auto pParamList = prhs[inFileParams];
  mxClassID  category = mxGetClassID(pParamList);
  if (category != mxCELL_CLASS)mexErrMsgTxt("Input file parameters have to be packed in cellarray");

  size_t n_files = mxGetNumberOfElements(pParamList);
  size_t n_realFiles = 0;
  std::vector<fileParameters> fileParam(n_files);
  for (size_t i = 0; i < n_files; i++) {
    const mxArray *pCellElement;
    pCellElement = mxGetCell(pParamList, i);
    if (pCellElement == NULL) { // empty cell
      continue;
    }
    if (mxSTRUCT_CLASS != mxGetClassID(pCellElement)) {
      std::stringstream buf;
      buf << "ERROR::combine_sqw => all cells in the input parameter list have to be structures but element N" << i << " is not\n";
      mexErrMsgTxt(buf.str().c_str());
    }
    fileParam[n_realFiles] = fileParameters(pCellElement);
    n_realFiles++;
  }

  // Retrieve programs parameters
  ProgParameters ProgSettings;
  int read_files_multitreaded(0);

  auto pProg_settings = (double *)mxGetPr(prhs[programSettings]);

  for (size_t i = 0; i < n_prog_params; i++) {
    switch (i) {
    case(0) :
      ProgSettings.totNumBins = size_t(pProg_settings[i]);
      break;
    case(1) :
      // -1 --> convert to C-arrays from Matlab array counting
      ProgSettings.nBin2read = size_t(pProg_settings[i]) - 1;
      break;
    case(2) :
      ProgSettings.pixBufferSize = size_t(pProg_settings[i]);
      break;
    case(3) :
      ProgSettings.log_level = int(pProg_settings[i]);
      break;
    case(4) :
      change_fileno = (pProg_settings[i] > 0) ? true : false;
      break;
    case(5) :
      fileno_provided = (pProg_settings[i] > 0) ? true : false;;
      break;
    case(6) :
      ProgSettings.num_log_ticks = size_t(pProg_settings[i]);
      break;
    case(7) :
      read_buf_size = size_t(pProg_settings[i]);
      break;
    case(8) :
      read_files_multitreaded = int(pProg_settings[i]);
      break;

    }
  }
  // set up the number of bins, which is currently equal for all input files
  for (size_t i = 0; i < n_files; i++) {
    fileParam[i].total_NfileBins = ProgSettings.totNumBins;
  }


  // Pointer to output file parameters;
  auto pOutFileParams = prhs[outFileParams];
  if (mxSTRUCT_CLASS != mxGetClassID(pOutFileParams)) {
    std::stringstream buf;
    buf << "ERROR::combine_sqw => the output file parameters have to be a structure but it is not";
    mexErrMsgTxt(buf.str().c_str());
  }
  auto OutFilePar = fileParameters(pOutFileParams);
  // set up the number of bins, which is currently equal for input and output files
  OutFilePar.total_NfileBins = ProgSettings.totNumBins;

  //--------------------------------------------------------
  //-------   RUN PROGRAM      -----------------------------
  //--------------------------------------------------------
  std::vector<sqw_reader> fileReader(n_files);
  for (size_t i = 0; i < n_files; i++) {
    fileReader[i].init(fileParam[i], change_fileno, fileno_provided, read_buf_size, read_files_multitreaded);
  }
  size_t n_buf_pixels(0), n_bins_processed(0);
  if (debug_file_reader) {

    auto nbin_Buffer = mxCreateNumericMatrix(ProgSettings.totNumBins, 1, mxUINT64_CLASS, mxREAL);
    uint64_t *nbinBuf = (uint64_t *)mxGetPr(nbin_Buffer);

    exchange_buffer Buffer(ProgSettings.pixBufferSize, ProgSettings.totNumBins, ProgSettings.num_log_ticks);
    pix_reader Reader(ProgSettings, fileReader, Buffer);


    n_bins_processed = ProgSettings.nBin2read;
    Reader.read_pix_info(n_buf_pixels, n_bins_processed, nbinBuf);

    size_t nReadPixels, n_bin_max;
    const float * buf = reinterpret_cast<const float *>(Buffer.get_write_buffer(nReadPixels, n_bin_max));
    n_bins_processed = n_bin_max - 1;
    auto PixBuffer = mxCreateNumericMatrix(9, nReadPixels, mxSINGLE_CLASS, mxREAL);
    if (!PixBuffer) {
      mexErrMsgTxt("Can not allocate output pixels buffer");
    }
    float *pPixBuffer = (float *)mxGetPr(PixBuffer);
    for (size_t i = 0; i < nReadPixels * 9; i++) {
      pPixBuffer[i] = buf[i];
    }
    Buffer.unlock_write_buffer();

    auto OutParam = mxCreateNumericMatrix(2, 1, mxUINT64_CLASS, mxREAL);
    uint64_t *outData = (uint64_t *)mxGetPr(OutParam);
    outData[0] = n_buf_pixels;
    outData[1] = n_bins_processed + 1;

    plhs[pix_data] = PixBuffer;
    plhs[npix_in_bins] = nbin_Buffer;
    plhs[pix_info] = OutParam;
  }


  else {
    combine_sqw(ProgSettings, fileReader, OutFilePar);
  }
}

