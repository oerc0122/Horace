#ifndef H_CELLS_MEM_MAP
#define H_CELLS_MEM_MAP
//
#include <vector>
#include <string>
#include <iostream>
#include <fstream>

#include <thread>
#include <mutex>

#include <algorithm>
// Matlab includes
#include <mex.h>

//-----------------------------------------------------------------------------------------------------------------
/* Class describes block of bins, loaded in memory and describe location of correspondent block of pixels on HDD*/
class cells_in_memory {
public:
    cells_in_memory(size_t buf_size) :
        use_multithreading(false),
        max_num_of_pixels(std::numeric_limits<size_t>::max()),
        nTotalBins(0), binFileStartPos(0),
        num_first_buf_bin(0), buf_nbin_end(0), pix_before_buffer(0),
        BIN_BUF_SIZE(buf_size), BUF_SIZE_STEP(buf_size), buf_end(1),
        nbins_read(false), read_completed(false),
        n_first_rbuf_bin(0) {
    }
    void init(const std::string &full_file_name, size_t bin_start_pos, size_t n_tot_bins, size_t BufferSize, bool use_multithreading);

    size_t num_pix_described(size_t bin_number)const;
    size_t num_pix_to_fit(size_t bin_number, size_t buf_size)const;
    /* get number of pixels, stored in the bin and the position of these pixels within pixel array */
    void   get_npix_for_bin(size_t bin_number, size_t &pix_start_num, size_t &num_bin_pix);
    void expand_pixels_selection(size_t bin_number);
    ~cells_in_memory();
protected:
    // the name of the file to process
    std::string full_file_name;
    size_t max_num_of_pixels;

    std::mutex io_lock;
    // handle pointing to open file

private:
    size_t  nTotalBins;
    size_t  binFileStartPos;

    size_t  num_first_buf_bin; // number of first bin in the buffer
    size_t  buf_nbin_end; //  number of the last bin in the buffer+1
    size_t  pix_before_buffer; /* number of pixels, located before the first pixel, described by the buffer
                               e.g. position of the first pixel located in the first bin of the buffer */
    std::vector<uint64_t> nbin_buffer;       // buffer containing bin info
    std::vector<uint64_t> pix_pos_in_buffer; // buffer containing pixels positions for bins, located in the buffer
    size_t BIN_BUF_SIZE; // physical size of the bins buffer
    size_t BUF_SIZE_STEP; // unit step for BIN_BUF_SIZE, which should not exceed 2*BUF_SIZE_STEP;
    size_t buf_end; /* points to the place after the last bin actually read into the buffer.
                    Differs from BIN_BUF_SIZE, as BIN_BUF_SIZE is physical buffer size which may not have all or any bins read into
                    e.g at the end, where all available bins were read */

                    // thread buffer and thread reading operations ;
    bool use_multithreading;
    std::mutex bin_read_lock, exchange_lock;
    bool nbins_read, read_completed;
    size_t n_first_rbuf_bin, rbuf_nbin_end, rbuf_end;
    std::vector<uint64_t>   nbin_read_buffer;
    std::condition_variable bins_ready, read_bins_needed;
    std::thread read_bins_job_holder;

    void read_bins(size_t num_bin, size_t buf_start, size_t buf_size,
        std::vector<uint64_t> &buffer, size_t &bin_end, size_t &buf_end);
    void  record_read_bins(size_t num_bin, size_t buf_nbin_end, size_t buf_end, const std::vector<uint64_t> &buffer);

    void read_all_bin_info(size_t bin_number);
    void read_bins_job();
    void calc_buf_range(size_t num_bin, size_t buf_start, size_t buf_size, size_t &tot_num_bins_to_read, size_t & bin_end, size_t & buf_end);

    static const long BIN_SIZE_BYTES = 8;
#ifdef STDIO
    FILE *h_data_file_bin;
    long fpos;
#else
    std::ifstream h_data_file_bin;
#endif
};

#endif