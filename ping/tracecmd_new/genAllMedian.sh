#!/bin/bash

rscript genReportMedian.r $1/inner_dev/
rscript genReportMedian.r $1/max_dev/
rscript genReportMedian.r $1/syscalls/
