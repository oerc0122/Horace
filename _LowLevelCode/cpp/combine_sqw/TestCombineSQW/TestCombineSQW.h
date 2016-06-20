#pragma once
#include <cxxtest/TestSuite.h>
#include "../combine_sqw.h"
#include "nsqw_pix_reader.h"
#include "sqw_pix_writer.h"
#include "pix_mem_map.h"
class pix_map_tester :public pix_mem_map
{
public:
    void read_bins(size_t num_bin, std::vector<pix_mem_map::bin_info> &buffer,
        size_t &bin_end, size_t &buf_end) {
        pix_mem_map::_read_bins(num_bin, buffer, bin_end, buf_end);
    }


};




class TestCombineSQW : public CxxTest::TestSuite {
    std::vector<uint64_t> sample_npix;
    std::vector<uint64_t> sample_pix_pos;
    std::string test_file_name;
    size_t num_bin_in_file,bin_pos_in_file;
public:
    // This pair of boilerplate methods prevent the suite being created statically
    // This means the constructor isn't called when running other tests
    static TestCombineSQW *createSuite() {
        return new TestCombineSQW();
    }
    static void destroySuite(TestCombineSQW*suite) { delete suite; }

    TestCombineSQW() {
        test_file_name = "d:/Data/svn/Horace/_test/test_symmetrisation/w3d_sqw.sqw";
        num_bin_in_file = 472392;
        bin_pos_in_file = 5194471;
        sample_npix.resize(num_bin_in_file);
        sample_pix_pos.resize(num_bin_in_file,0);
        std::ifstream   data_file_bin;
        data_file_bin.open(test_file_name, std::ios::in | std::ios::binary);
        if (!data_file_bin.is_open()) {
            throw "Can not open test data file";
        }
        char *buf = reinterpret_cast<char *>(&sample_npix[0]);
        data_file_bin.seekg(bin_pos_in_file);
        data_file_bin.read(buf, num_bin_in_file*8);
        for (size_t i = 1; i < sample_npix.size(); i++) {
            sample_pix_pos[i] = sample_pix_pos[i-1]+ sample_npix[i-1];
        }

        data_file_bin.close();
    }
    void test_read_nbins() {
        pix_map_tester pix_map;

        pix_map.init(this->test_file_name, bin_pos_in_file, num_bin_in_file, 128, false);
        std::vector<pix_mem_map::bin_info> buffer(256);

        size_t bin_end, buf_end;
        pix_map.read_bins(0, buffer, bin_end, buf_end);

        TS_ASSERT_EQUALS(256, bin_end);
        TS_ASSERT_EQUALS(256, buf_end);
        TS_ASSERT_EQUALS(sample_npix[125], buffer[125].num_bin_pixels);
        TS_ASSERT_EQUALS(sample_npix[115], buffer[115].num_bin_pixels);
        TS_ASSERT_EQUALS(sample_npix[114], buffer[114].num_bin_pixels);
        TS_ASSERT_EQUALS(sample_npix[0], buffer[0].num_bin_pixels);
        TS_ASSERT_EQUALS(sample_npix[1], buffer[1].num_bin_pixels);
        TS_ASSERT_EQUALS(sample_npix[5], buffer[5].num_bin_pixels);
        TS_ASSERT_EQUALS(sample_npix[129], buffer[129].num_bin_pixels);

        for (size_t i = 1; i < buffer.size(); i++) {
            TS_ASSERT_EQUALS(buffer[i].pix_pos, buffer[i - 1].pix_pos + buffer[i - 1].num_bin_pixels);
        }

        //--------------------------------------------------------------------------------------------
        pix_map.init(this->test_file_name, bin_pos_in_file, num_bin_in_file, 0, false);
        std::vector<pix_mem_map::bin_info> buffer1(1);

        pix_map.read_bins(0, buffer1, bin_end, buf_end);
        TS_ASSERT_EQUALS(1, bin_end);
        TS_ASSERT_EQUALS(1, buf_end);
        TS_ASSERT_EQUALS(sample_npix[0], buffer[0].num_bin_pixels);

        pix_map.read_bins(125, buffer1, bin_end, buf_end);
        TS_ASSERT_EQUALS(sample_npix[125], buffer1[0].num_bin_pixels);
        TS_ASSERT_EQUALS(126, bin_end);
        TS_ASSERT_EQUALS(1, buf_end);


        pix_map.read_bins(115, buffer1, bin_end, buf_end);
        TS_ASSERT_EQUALS(sample_npix[115], buffer1[0].num_bin_pixels);
        TS_ASSERT_EQUALS(116, bin_end);
        TS_ASSERT_EQUALS(1, buf_end);

        pix_map.read_bins(5, buffer1, bin_end, buf_end);
        TS_ASSERT_EQUALS(sample_npix[5], buffer1[0].num_bin_pixels);

        //--------------------------------------------------------------------------------------------

        pix_map.init(this->test_file_name, bin_pos_in_file, num_bin_in_file, 0, false);
        std::vector<pix_mem_map::bin_info> buffer2(128);

        pix_map.read_bins(0, buffer2, bin_end, buf_end);

        TS_ASSERT_EQUALS(128, bin_end);
        TS_ASSERT_EQUALS(128, buf_end);
        TS_ASSERT_EQUALS(sample_npix[125], buffer2[125].num_bin_pixels);
        TS_ASSERT_EQUALS(sample_npix[115], buffer2[115].num_bin_pixels);
        TS_ASSERT_EQUALS(sample_npix[114], buffer2[114].num_bin_pixels);
        TS_ASSERT_EQUALS(sample_npix[0], buffer2[0].num_bin_pixels);
        TS_ASSERT_EQUALS(sample_npix[1], buffer2[1].num_bin_pixels);
        TS_ASSERT_EQUALS(sample_npix[5], buffer2[5].num_bin_pixels);

        for (size_t i = 1; i < buffer2.size(); i++) {
            TS_ASSERT_EQUALS(buffer2[i].pix_pos, buffer[i - 1].pix_pos + buffer[i - 1].num_bin_pixels);
        }

        pix_map.read_bins(num_bin_in_file-2, buffer2, bin_end, buf_end);
        TS_ASSERT_EQUALS(num_bin_in_file, bin_end);
        TS_ASSERT_EQUALS(2, buf_end);



    }
    void  test_get_npix_for_bins() {
        pix_mem_map pix_map;

        pix_map.init(this->test_file_name, bin_pos_in_file, num_bin_in_file, 0, false);

        // number of pixels in file is unknown
        TS_ASSERT_EQUALS(std::numeric_limits<uint64_t>::max(), pix_map.num_pix_in_file());

        size_t pix_start, npix;
        pix_map.get_npix_for_bin(0, pix_start, npix);
        TS_ASSERT_EQUALS(0, pix_start);
        TS_ASSERT_EQUALS(sample_npix[0], npix);

        pix_map.get_npix_for_bin(114, pix_start, npix);
        TS_ASSERT_EQUALS(sample_npix[114], npix);
        TS_ASSERT_EQUALS(sample_pix_pos[114], pix_start);

        pix_map.get_npix_for_bin(511, pix_start, npix);
        TS_ASSERT_EQUALS(sample_npix[511], npix);
        TS_ASSERT_EQUALS(sample_pix_pos[511], pix_start);


        pix_map.get_npix_for_bin(600, pix_start, npix);
        TS_ASSERT_EQUALS(sample_npix[600], npix);
        TS_ASSERT_EQUALS(sample_pix_pos[600], pix_start);

        pix_map.get_npix_for_bin(2400, pix_start, npix);
        TS_ASSERT_EQUALS(sample_npix[2400], npix);
        TS_ASSERT_EQUALS(sample_pix_pos[2400], pix_start);

        // number of pixels in file is unknown
        TS_ASSERT_EQUALS(std::numeric_limits<uint64_t>::max(), pix_map.num_pix_in_file());


        pix_map.get_npix_for_bin(2, pix_start, npix);

        TS_ASSERT_EQUALS(sample_npix[2], npix);
        TS_ASSERT_EQUALS(sample_pix_pos[2], pix_start);


        pix_map.get_npix_for_bin(num_bin_in_file-2, pix_start, npix);
        TS_ASSERT_EQUALS(sample_npix[num_bin_in_file - 2], 0);
        TS_ASSERT_EQUALS(sample_pix_pos[num_bin_in_file - 2], pix_start);

        // number of pixels in file is known 
        TS_ASSERT(std::numeric_limits<uint64_t>::max() != pix_map.num_pix_in_file());

        TS_ASSERT_EQUALS(pix_map.num_pix_in_file(), sample_pix_pos[num_bin_in_file - 1] + sample_npix[num_bin_in_file - 1])

    }
    void test_fully_expand_pix_map_from_start() {
        pix_mem_map pix_map;

        pix_map.init(this->test_file_name, bin_pos_in_file, num_bin_in_file, 512, false);

        bool end_pix_reached;
        size_t num_pix = pix_map.expand_pix_map(4,512, end_pix_reached);
        TS_ASSERT(!end_pix_reached);
        TS_ASSERT_EQUALS(512, num_pix);

        // Read whole map in memory requesting map for much bigger number of npixels then the real npix number in the file.
        num_pix = pix_map.expand_pix_map(0,2* 1164180, end_pix_reached);
        // the file contains 
        TS_ASSERT_EQUALS(sample_pix_pos[num_bin_in_file-1]+ sample_npix[num_bin_in_file - 1], num_pix);
        TS_ASSERT(end_pix_reached);

        for (size_t i = 0; i < num_bin_in_file; i++) {
            size_t pix_start,npix;
            pix_map.get_npix_for_bin(i, pix_start, npix);
            TS_ASSERT_EQUALS(pix_start, sample_pix_pos[i]);
            TS_ASSERT_EQUALS(npix, sample_npix[i]);

        }
        TS_ASSERT_EQUALS(pix_map.num_pix_in_file(), num_pix);

    }
    void test_expand_pix_map() {
        pix_mem_map pix_map;

        pix_map.init(this->test_file_name, bin_pos_in_file, num_bin_in_file, 512, false);

        bool end_pix_reached;
        size_t num_pix1 = pix_map.expand_pix_map(511, 512, end_pix_reached);
        TS_ASSERT(!end_pix_reached);
        TS_ASSERT_EQUALS(510, num_pix1);

        size_t pix_pos,npix;
        pix_map.get_npix_for_bin(511,pix_pos,npix);
        TS_ASSERT_EQUALS(sample_pix_pos[511],pix_pos);
        TS_ASSERT_EQUALS(sample_npix[511], npix);

        // Read whole map in memory requesting map for much bigger number of npixels then the real npix number in the file.
        size_t num_pix = pix_map.expand_pix_map(512, 2 * 1164180, end_pix_reached);
        // the file contains 
        TS_ASSERT_EQUALS(sample_pix_pos[num_bin_in_file - 1] + sample_npix[num_bin_in_file - 1]- pix_pos- npix, num_pix);
        TS_ASSERT(end_pix_reached);

        for (size_t i = 512; i < num_bin_in_file; i++) {
            size_t pix_start, npix;
            pix_map.get_npix_for_bin(i, pix_start, npix);
            TS_ASSERT_EQUALS(pix_start, sample_pix_pos[i]);
            TS_ASSERT_EQUALS(npix, sample_npix[i]);

        }
        TS_ASSERT_EQUALS(pix_map.num_pix_in_file(), num_pix+ pix_pos+ npix);

        num_pix = pix_map.expand_pix_map(512, 512, end_pix_reached);
        TS_ASSERT(end_pix_reached);
        TS_ASSERT_EQUALS(512, num_pix);


        num_pix = pix_map.expand_pix_map(4, 512, end_pix_reached);
        TS_ASSERT(!end_pix_reached);
        TS_ASSERT_EQUALS(512, num_pix);

        pix_map.get_npix_for_bin(512+4, pix_pos, npix);
        TS_ASSERT_EQUALS(sample_pix_pos[512+4], pix_pos);
        TS_ASSERT_EQUALS(sample_npix[512+4], npix);


    }



    /*

        void xest_sqw_reader_propagate_pix() {
            sqw_reader reader(128);
            fileParameters file_par;
            file_par.fileName = "d:/Data/svn/Horace/_test/test_symmetrisation/w3d_sqw.sqw";
            file_par.file_id = 0;
            file_par.nbin_start_pos = 5194471;
            file_par.pix_start_pos = 8973651;
            file_par.total_NfileBins = num_bin_in_file;
            bool initialized(false);
            try {
                reader.init(file_par, false, false, 128);
                initialized = true;
            }
            catch (...) {}

            TS_ASSERT(initialized);

            size_t pix_start_num, num_bin_pix,start_bin(0);
            std::vector<float> pix_buffer(9*1000);
            float *pPix_info = &pix_buffer[0];

            reader.get_pix_for_bin(0,pPix_info, start_bin,pix_start_num,num_bin_pix,false);
            TS_ASSERT_EQUALS(pix_start_num,0);
            TS_ASSERT_EQUALS(num_bin_pix, 3);
            // pix buffer have not changed at all
            reader.get_pix_for_bin(127, pPix_info, start_bin, pix_start_num, num_bin_pix, false);
            TS_ASSERT_EQUALS(pix_start_num, 338);
            TS_ASSERT_EQUALS(num_bin_pix, 0);

            reader.get_pix_for_bin(126, pPix_info, start_bin, pix_start_num, num_bin_pix, false);
            TS_ASSERT_EQUALS(pix_start_num, 334);
            TS_ASSERT_EQUALS(num_bin_pix, 4);

            reader.get_npix_for_bin(256,pix_start_num,num_bin_pix);
            TS_ASSERT_EQUALS(pix_start_num,678);
            TS_ASSERT_EQUALS(num_bin_pix, 0);
        }

        void xest_sqw_reader_propagate_pix_multi() {
            sqw_reader reader(128);
            fileParameters file_par;
            file_par.fileName = "d:/Data/svn/Horace/_test/test_symmetrisation/w3d_sqw.sqw";
            file_par.file_id = 0;
            file_par.nbin_start_pos = 5194471;
            file_par.pix_start_pos = 8973651;
            file_par.total_NfileBins = num_bin_in_file;
            bool initialized(false);
            try {
                reader.init(file_par, false, false, 128,1);
                initialized = true;
            }
            catch (...) {}

            TS_ASSERT(initialized);

            size_t pix_start_num, num_bin_pix, start_bin(0);
            std::vector<float> pix_buffer(9 * 1000);
            float *pPix_info = &pix_buffer[0];

            reader.get_pix_for_bin(0, pPix_info, start_bin, pix_start_num, num_bin_pix, false);
            TS_ASSERT_EQUALS(pix_start_num, 0);
            TS_ASSERT_EQUALS(num_bin_pix, 3);
            // pix buffer have not changed at all
            reader.get_pix_for_bin(127, pPix_info, start_bin, pix_start_num, num_bin_pix, false);
            TS_ASSERT_EQUALS(pix_start_num, 338);
            TS_ASSERT_EQUALS(num_bin_pix, 0);

            reader.get_pix_for_bin(126, pPix_info, start_bin, pix_start_num, num_bin_pix, false);
            TS_ASSERT_EQUALS(pix_start_num, 334);
            TS_ASSERT_EQUALS(num_bin_pix, 4);

            reader.get_npix_for_bin(256, pix_start_num, num_bin_pix);
            TS_ASSERT_EQUALS(pix_start_num, 678);
            TS_ASSERT_EQUALS(num_bin_pix, 0);

        }

        void xest_reader_propagate_pix_multi() {
            std::vector<sqw_reader> reader_noThread(1);

            fileParameters file_par;
            file_par.fileName = "d:/Data/svn/Horace/_test/test_symmetrisation/w3d_sqw.sqw";
            file_par.file_id = 0;
            file_par.nbin_start_pos = 5194471;
            file_par.pix_start_pos = 8973651;
            file_par.total_NfileBins = num_bin_in_file;
            bool initialized(false);
            try {
                //(fileParam[i], change_fileno, fileno_provided, read_buf_size, read_files_multitreaded);
                reader_noThread[0].init(file_par, false, false, 64, 0);
                initialized = true;
            }
            catch (...) {
            }

            TS_ASSERT(initialized);

            ProgParameters ProgSettings;
            ProgSettings.log_level = 2;
            ProgSettings.nBin2read = 0;
            ProgSettings.num_log_ticks = 100;
            ProgSettings.pixBufferSize = 1164180;
            ProgSettings.totNumBins = num_bin_in_file;

            exchange_buffer Buffer(ProgSettings.pixBufferSize, file_par.total_NfileBins, ProgSettings.num_log_ticks);
            nsqw_pix_reader Reader(ProgSettings, reader_noThread, Buffer);

            std::vector<uint64_t> nbin_Buffer_noThreads(ProgSettings.totNumBins,-1);
            uint64_t *nbinBuf = &nbin_Buffer_noThreads[0];

            size_t n_buf_pixels, n_bins_processed(0);
            Reader.read_pix_info(n_buf_pixels, n_bins_processed, nbinBuf);

            TS_ASSERT_EQUALS(n_buf_pixels, ProgSettings.pixBufferSize);
            TS_ASSERT_EQUALS(n_bins_processed+1, ProgSettings.totNumBins);

            size_t nReadPixels, n_bin_max;
            const float * buf = reinterpret_cast<const float *>(Buffer.get_write_buffer(nReadPixels, n_bin_max));
            Buffer.unlock_write_buffer();
            TS_ASSERT_EQUALS(nReadPixels, ProgSettings.pixBufferSize);
            //---------------------------------------------------------------------
            std::vector<sqw_reader> reader_threads(1);
            initialized=false;
            try {
                //(fileParam[i], change_fileno, fileno_provided, read_buf_size, read_files_multitreaded);
                reader_threads[0].init(file_par, false, false, 64, 3);
                initialized = true;
            }
            catch (...) {
            }
            TS_ASSERT(initialized);

            nsqw_pix_reader ReaderThr(ProgSettings, reader_threads, Buffer);

            std::vector<uint64_t> nbin_Buffer_Threads(ProgSettings.totNumBins, -1);
            uint64_t *nbinBufThr  = &nbin_Buffer_Threads[0];

            n_bins_processed = 0;
            ReaderThr.read_pix_info(n_buf_pixels, n_bins_processed, nbinBufThr);

            TS_ASSERT_EQUALS(n_buf_pixels, ProgSettings.pixBufferSize);
            TS_ASSERT_EQUALS(n_bins_processed + 1, ProgSettings.totNumBins);

            const float * buf1 = reinterpret_cast<const float *>(Buffer.get_write_buffer(nReadPixels, n_bin_max));
            Buffer.unlock_write_buffer();
            TS_ASSERT_EQUALS(nReadPixels, ProgSettings.pixBufferSize);

            for (size_t i = 0; i < n_bins_processed + 1; i+=10) {
                TSM_ASSERT_EQUALS("bin N"+std::to_string(i),nbin_Buffer_Threads[i], nbin_Buffer_noThreads[i]);
            }
            for (size_t i = 0; i < n_buf_pixels; i+=100) {
                size_t n_pix = i/9;
                TSM_ASSERT_EQUALS("pix N" + std::to_string(n_pix), buf[i], buf1[i]);
            }

        }
        */
};
