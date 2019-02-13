import XCTest

import templarTests

var tests = [XCTestCaseEntry]()
tests += templarTests.allTests()
XCTMain(tests)