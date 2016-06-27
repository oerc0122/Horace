#ifndef H_COMBINE_SQW
#define H_COMBINE_SQW
#include "nsqw_pix_reader.h"
#include "sqw_pix_writer.h"

//#define STDIO

//
// $Revision::      $ ($Date::                                              $)" 
//

// parameters the mex routine uses and accepts in the array of input parameters
struct ProgParameters {
    size_t totNumBins;  // total number of bins in files to combine (has to be the same for all files)
    size_t nBin2read;  // current bin number to read (start from 0 for first bin of the array)
    size_t pixBufferSize; // the size of the buffer to return combined pixels
    int log_level;       // the number defines how talkative program is. usually it its > 1 all 
                         // all diagnostics information gets printed
    size_t num_log_ticks; // how many times per combine files to print log message about completion percentage
                          // Default constructor
    ProgParameters() :totNumBins(0), nBin2read(0),
        pixBufferSize(10000000), log_level(1), num_log_ticks(100)
    {};
};


enum readBinInfoOption {
    sumPixInfo,
    keepPixInfo
};


#endif
