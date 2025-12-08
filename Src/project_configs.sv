`define ADDR_WIDTH 8
`define DATA_WIDTH 32
`define MEM_DEPTH 256
`define STRB_WIDTH 4
/*
vlog -sv +acc +cover +fcover top.sv
vsim -novopt -suppress 12110 top -assertdebug -coverage +UVM_TESTNAME=apb_regression_test
*/