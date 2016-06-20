#ifndef H_CELLS_MEM_MAP
#define H_CELLS_MEM_MAP
//
#include <vector>
#include <string>
#include <list>
#include <iostream>
#include <fstream>

#include <thread>
#include <mutex>

#include <algorithm>
// Matlab includes
#include <mex.h>

//-----------------------------------------------------------------------------------------------------------------
/* Class describes block of bins, loaded in memory and used to find location of correspondent block of pixels on HDD
*  practically providing pixels memory map
*
*  Its assumed that bins and pixels are the arrays of Horace data format 
*/
class pix_mem_map{
public:
    // the structure describes the part of bins, loaded in memory.
    struct bin_info {
        uint64_t num_bin_pixels; // number of pixels in given bins
        uint64_t pix_pos;        // position of the pixels wrt to the first bin loaded in memory
        bin_info() :
            num_bin_pixels(0), pix_pos(0) {}
        bin_info(size_t num_pix,size_t pix_pos_e) :
            num_bin_pixels(num_pix), pix_pos(pix_pos_e)
        {}
    };

    pix_mem_map();

    void init(const std::string &full_file_name, size_t bin_start_pos, size_t n_tot_bins, size_t BufferSize, bool use_multithreading);
    /* get number of pixels, stored in the bin and the position of these pixels within pixel array */
    void   get_npix_for_bin(size_t bin_number, size_t &pix_start_num, size_t &num_bin_pix);

    size_t expand_pix_map(size_t bin_number,size_t num_pix_to_fit, bool &end_of_pix_reached);
    size_t num_pix_described(size_t bin_number)const;
    //size_t num_pix_to_fit(size_t bin_number, size_t buf_size)const;
    ~pix_mem_map();
    /* Return number of pixels, stored in file and defined by this memory map*/
    uint64_t num_pix_in_file()const {
        if (num_pix_isknown) {
            return this->_numPixInFile;
        }else{
            return std::numeric_limits<uint64_t>::max();
        }
    }
protected:
    // the name of the file to process
    std::string full_file_name;

    std::mutex io_lock;
    // handle pointing to open file

    // EXPOSED FOR TESTING
    void _read_bins(size_t num_bin,std::vector<bin_info> &buffer,
        size_t &bin_end, size_t &buf_end);

    void _update_data_cash(size_t bin_number);
    void _update_data_cash_(size_t bin_number, std::vector<bin_info> &nbin_buffer,
        size_t &num_first_buf_bin, size_t &num_last_buf_bin, size_t &prebuf_pix_num);
    size_t _flatten_memory_map(const std::list<std::vector<bin_info> > &bin_buf_holder, size_t map_size, size_t first_bin_number);
private:
    bool use_streambuf_direct;
    size_t num_first_buf_bin,num_last_buf_bin; // number of first and last bin stored in memory

    size_t prebuf_pix_num;                // total number of pixels, stored before the pixels corresponding to the first bin buffer
    std::vector<bin_info> nbin_buffer;   // buffer containing bin info

    //----------------------------------------------------------------------------
    size_t  _nTotalBins;
    size_t  _binFileStartPos;

    bool num_pix_isknown;
    uint64_t  _numPixInFile;


    // thread buffer and thread reading operations ;
    bool nbins_read, read_completed;
    size_t n_first_rbuf_bin, rbuf_nbin_end, rbuf_end;

    std::condition_variable bins_ready, read_bins_needed;
    std::thread read_bins_job_holder;


    //void calc_buf_range(size_t num_bin, size_t buf_size, size_t &tot_num_bins_to_read);

    bool use_multithreading;
    std::mutex bin_read_lock, exchange_lock;
    //void read_bins_job();


    static const long BIN_SIZE_BYTES = 8;
    size_t BIN_BUF_SIZE; // physical size of the bins buffer
    //
    std::ifstream h_data_file_bin;
    std::vector<uint64_t>   nbin_read_buffer;

};

#endif