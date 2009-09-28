#ifndef H_GET_ASCII_FILE
#define H_GET_ASCII_FILE
// TODO: reference additional headers your program requires here
#include <iostream>
#include <fstream>
#include <sstream>
#include <string.h>
#include <sys/stat.h>
#include <stdio.h>
#include "mex.h" // llget_ascii_file uses only the definition of mwSize from mex.h
				// if the function has to be used independently on Matlab, it should just typedef mwSize
#include "matrix.h"

//
/*!  file types currently supported
*/
enum fileTypes{
	iPAR_type,
	iPHX_type,
	iSPE_type,
	iNumFileTypes
};
/*!
*   Description of the data header, common for all files
*/
struct FileTypeDescriptor{
	fileTypes Type;
	std::streampos data_start_position; //> the position in the file where the data structure starts
	mwSize 	  nData_records,       //> number of data records -- actually nDetectors
		      nData_blocks;        //> nEnergy bins for SPE file and 0 for other two types
};

// load file header and identify which file (PHX,PAR or SPE) it belongs to. It also identifies the position of the begining of the data
FileTypeDescriptor get_ASCII_header(std::string const &fileName, std::ifstream &data_stream);
// load PAR or PHX file
void load_plain(std::ifstream &stream,double *pData,FileTypeDescriptor const &FILE_TYPE);
// load SPE file
void load_spe(std::ifstream &stream,double *data_S,double *data_ERR,double * data_en, FileTypeDescriptor const &FILE_TYPE);
#endif

#ifndef _CRT_SECURE_NO_WARNINGS
#define _CRT_SECURE_NO_WARNINGS
#endif
