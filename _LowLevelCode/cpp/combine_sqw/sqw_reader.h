#ifndef H_SQW_READER
#define H_SQW_READER

#include "cells_in_memory.h"
#include "fileParameters.h"
//-----------------------------------------------------------------------------------------------------------------
class sqw_reader :public cells_in_memory
{
    /* Class provides bin and pixel information for a pixels of a single sqw file.

    Created to read bin and pixel information from a cell stored on hdd,
    but optimized for subsequent data access, so subsequent cells are
    cashed in a buffer and provided from the buffer if available

    %
    % $Revision: 1211 $($Date : 2015 - 12 - 07 21 : 20 : 34 + 0000 (Mon, 07 Dec 2015) $)
    %
    */
public:
    sqw_reader(size_t working_buf_size = 4096);
    sqw_reader(const fileParameters &fpar, bool changefileno, bool fileno_provided, size_t working_buf_size = 4096);
    ~sqw_reader();
    void init(const fileParameters &fpar, bool changefileno, bool fileno_provided, size_t working_buf_size = 4096, int use_multithreading = 0);
    /* return pixel information for the pixels stored in the bin */
    void get_pix_for_bin(size_t bin_number, float *const pix_info, size_t cur_buf_position,
        size_t &pix_start_num, size_t &num_bin_pix, bool position_is_defined = false);
private:
    void read_pixels(size_t bin_number, size_t pix_start_num);
    size_t check_binInfo_loaded_(size_t bin_number, bool extend_bin_buffer, size_t pix_start_num);

    void read_pix_io(size_t pix_start_num, std::vector<float> &pix_buffer, size_t num_pix_to_read);

    // parameters, which describe 
    fileParameters fileDescr;

    size_t npix_in_buf_start; //= 0;
    size_t buf_pix_end; //  number of last pixel in the buffer+1
    std::vector<float> pix_buffer; // buffer containing pixels (9*npix size)

                                   // number of pixels to read in pix buffer
    size_t PIX_BUF_SIZE;
    //Boolean indicating that the id, which specify pixel run number should be modified
    bool change_fileno;
    // Boolean, indicating if one needs to offset pixel's run number id by fileDescr.file_id
    // or set up its value into fileDescr.file_id;
    bool fileno;

    static const size_t PIX_SIZE = 9; // size of the pixel in pixel data units (float)
    static const size_t PIX_BLOCK_SIZE_BYTES = 36; //9 * 4; // size of the pixel block in bytes

                                                   // thread buffer and thread reading operations ;
    std::mutex pix_read_lock, pix_exchange_lock;
    bool use_multithreading_pix, pix_read, pix_read_job_completed;
    size_t n_first_buf_pix;
    std::vector<float> thread_pix_buffer;
    std::condition_variable pix_ready, read_pix_needed;
    std::thread read_pix_job_holder;

    void read_pixels_job();

#ifdef STDIO
    FILE *h_data_file_pix;
    long fpos;
#else
    std::ifstream h_data_file_pix;
#endif


};


#endif