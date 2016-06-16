/* Generated file, do not edit */

#ifndef CXXTEST_RUNNING
#define CXXTEST_RUNNING
#endif

#define _CXXTEST_HAVE_STD
#define _CXXTEST_HAVE_EH
#include <cxxtest/TestListener.h>
#include <cxxtest/TestTracker.h>
#include <cxxtest/TestRunner.h>
#include <cxxtest/RealDescriptions.h>
#include <cxxtest/TestMain.h>

bool suite_TestCombineSQW_init = false;
#include "d:\users\abuts\SVN\ISIS\Hor#160\_LowLevelCode\cpp\combine_sqw\TestCombineSQW\TestCombineSQW.h"

static TestCombineSQW* suite_TestCombineSQW = 0;

static CxxTest::List Tests_TestCombineSQW = { 0, 0 };
CxxTest::DynamicSuiteDescription< TestCombineSQW > suiteDescription_TestCombineSQW( "d:/users/abuts/SVN/ISIS/Hor#160/_LowLevelCode/cpp/combine_sqw/TestCombineSQW/TestCombineSQW.h", 21, "TestCombineSQW", Tests_TestCombineSQW, suite_TestCombineSQW, 28, 31 );

static class TestDescription_suite_TestCombineSQW_test_read_nbins : public CxxTest::RealTestDescription {
public:
 TestDescription_suite_TestCombineSQW_test_read_nbins() : CxxTest::RealTestDescription( Tests_TestCombineSQW, suiteDescription_TestCombineSQW, 51, "test_read_nbins" ) {}
 void runTest() { if ( suite_TestCombineSQW ) suite_TestCombineSQW->test_read_nbins(); }
} testDescription_suite_TestCombineSQW_test_read_nbins;

static class TestDescription_suite_TestCombineSQW_test_get_npix_for_bins : public CxxTest::RealTestDescription {
public:
 TestDescription_suite_TestCombineSQW_test_get_npix_for_bins() : CxxTest::RealTestDescription( Tests_TestCombineSQW, suiteDescription_TestCombineSQW, 123, "test_get_npix_for_bins" ) {}
 void runTest() { if ( suite_TestCombineSQW ) suite_TestCombineSQW->test_get_npix_for_bins(); }
} testDescription_suite_TestCombineSQW_test_get_npix_for_bins;

