#ifndef H_FILE_PARAMETERS
#define H_FILE_PARAMETERS

#include <string>
#include <map>
#include <stdio.h>
#include <sstream>
// Matlab's includes
#include <mex.h>
#include <matrix.h>

/* Class describes a file to combine */
class fileParameters {
public:
    std::string fileName;
    size_t nbin_start_pos; // the initial file position where nbin array is located in the file
    uint64_t pix_start_pos;   // the initial file position where the pixel array is located in file
    int    file_id;       // the number which used to identify pixels, obtained from this particular file
    size_t total_NfileBins; // the number of bins in this file (has to be the same for all files)
    fileParameters(const mxArray *pFileParam);
    fileParameters() :fileName(""), nbin_start_pos(0), pix_start_pos(0),
        file_id(0), total_NfileBins(0) {}
private:
    static const std::map<std::string, int> fileParamNames;
};



#endif