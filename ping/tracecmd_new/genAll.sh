#!/bin/bash

rscript genReport.r $1/inner_dev/
rscript genReport.r $1/max_dev/
rscript genReport.r $1/syscalls/
