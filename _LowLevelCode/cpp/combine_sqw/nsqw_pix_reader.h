#ifndef H_NSQW_PIX_READER
#define H_NSQW_PIX_READER

#include "combine_sqw.h"
#include "sqw_reader.h"
#include "exchange_buffer.h"
//-----------------------------------------------------------------------------------------------------------------
/* Structure (class) supporting the read operations for range of input files and combining the information
from this files together in the file buffer*/
struct nsqw_pix_reader {
    ProgParameters &param;
    std::vector<sqw_reader> &fileReaders;
    exchange_buffer &Buff;

    nsqw_pix_reader(ProgParameters &prog_par, std::vector<sqw_reader> &tmpReaders, exchange_buffer &buf) :
        param(prog_par), fileReaders(tmpReaders), Buff(buf)
    { }
    // satisfy thread interface
    void operator()() {
        this->run_read_job();
    }

    //
    void run_read_job();
    void read_pix_info(size_t &n_buf_pixels, size_t &n_bins_processed, uint64_t *nBinBuffer = NULL);
};

#endif

