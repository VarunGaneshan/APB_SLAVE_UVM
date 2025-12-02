# APB SLAVE VERIFICATION - QUICK START GUIDE

## Overview
This is a complete UVM verification environment for an APB Slave with internal memory (256 locations × 32-bit data).

## Quick Commands

### Using QuestaSim/ModelSim
```bash
# Compile
vlog -sv +incdir+Src Src/top.sv

# Run comprehensive test
vsim -c top +UVM_TESTNAME=apb_comprehensive_test -do "run -all; quit"

# Run with GUI
vsim top +UVM_TESTNAME=apb_comprehensive_test
```

### Using VCS
```bash
# Compile
vcs -sverilog +incdir+Src Src/top.sv -ntb_opts uvm -full64

# Run
./simv +UVM_TESTNAME=apb_comprehensive_test
```

### Using Xcelium
```bash
# Compile and run
xrun -sv +incdir+Src Src/top.sv +UVM_TESTNAME=apb_comprehensive_test -uvm
```

## Available Tests

| Test Name | Description | Transactions |
|-----------|-------------|--------------|
| `apb_write_test` | Basic write operations | 20 |
| `apb_read_test` | Basic read operations | 20 |
| `apb_write_read_test` | Write-read verification | 30 |
| `apb_byte_strobe_test` | All PSTRB combinations | 13 |
| `apb_error_test` | Error handling | 20 |
| `apb_random_test` | Random operations | 100 |
| `apb_burst_test` | Burst read/write | 64 |
| `apb_comprehensive_test` | **All scenarios (RECOMMENDED)** | 500+ |

## Runtime Arguments

```bash
# Select test
+UVM_TESTNAME=<test_name>

# Set number of transactions
+no_of_trans=100

# Set burst length
+burst_length=32

# Set verbosity
+UVM_VERBOSITY=UVM_LOW      # Minimal output
+UVM_VERBOSITY=UVM_MEDIUM   # Standard output
+UVM_VERBOSITY=UVM_HIGH     # Detailed output
+UVM_VERBOSITY=UVM_DEBUG    # Debug output
```

## Expected Output

### Successful Test
```
=== TEST STARTED ===
[SCOREBOARD] READ PASS: ADDR=0x00, Expected=0xDEADBEEF, Actual=0xDEADBEEF
[SCOREBOARD] WRITE PASS: ADDR=0x10, DATA=0x12345678
...
============================================
       APB SLAVE VERIFICATION SUMMARY       
============================================
Total Transactions:  500
  - Write Operations: 250
  - Read Operations:  200
  - Error Cases:      50
--------------------------------------------
PASSED:              500
FAILED:              0
============================================
*** ALL TESTS PASSED ***

============================================
      FUNCTIONAL COVERAGE REPORT           
============================================
OVERALL COVERAGE:     99.22%
============================================

*** TEST PASSED ***
```

### Coverage Report
```
Protocol Coverage:    100.00%
Address Coverage:     98.50%
Data Coverage:        95.20%
Byte Strobe Coverage: 100.00%
Transfer Coverage:    100.00%
Write Op Coverage:    99.80%
Read Op Coverage:     99.50%
Error Coverage:       100.00%
Boundary Coverage:    100.00%
```

## Debugging

### View Waveforms
Waveforms are automatically dumped to `apb_slave.vcd`.

Open with:
```bash
# GTKWave
gtkwave apb_slave.vcd

# ModelSim (GUI mode)
vsim top +UVM_TESTNAME=apb_comprehensive_test
# Then use Wave window
```

### Key Signals to Monitor
- `pclk`, `presetn` - Clock and reset
- `paddr`, `psel`, `penable` - APB control signals
- `pwrite`, `pwdata`, `pstrb` - Write path
- `prdata`, `pready`, `pslverr` - Read path and status

### Increase Verbosity
```bash
+UVM_VERBOSITY=UVM_HIGH
+UVM_VERBOSITY=UVM_DEBUG
```

### Check Assertions
All assertions print to console when they fail:
```
[ASSERTION FAIL] PADDR changed during transfer at time 150ns
```

## Verification Checklist

- [ ] All tests compile without errors
- [ ] `apb_comprehensive_test` runs to completion
- [ ] Scoreboard shows 0 FAILED transactions
- [ ] No assertion failures in log
- [ ] Functional coverage >98%
- [ ] No UVM_ERROR or UVM_FATAL messages

## Common Issues

### Issue: "No virtual interface found"
**Solution**: Ensure top.sv properly sets interface in config_db

### Issue: "Undefined symbol"
**Solution**: Check `+incdir+Src` is specified in compile command

### Issue: Test doesn't run
**Solution**: Use correct test name with `+UVM_TESTNAME=`

### Issue: Coverage is low
**Solution**: Run `apb_comprehensive_test` or increase `+no_of_trans=`

## File Modifications

### Change Memory Size
Edit `Src/project_configs.sv`:
```systemverilog
`define ADDR_WIDTH 8        // 8-bit address
`define DATA_WIDTH 32       // 32-bit data
`define MEM_DEPTH 256       // 256 locations
```

### Add New Test
1. Create new test class in `Src/apb_test.sv`
2. Extend from `apb_base_test`
3. Implement `run_phase` with your sequences
4. Run with `+UVM_TESTNAME=your_new_test`

### Add New Sequence
1. Create new sequence class in `Src/apb_sequence.sv`
2. Extend from `apb_base_sequence`
3. Implement `body()` task
4. Use in your test

## Performance

| Test | Simulation Time | Transactions |
|------|----------------|--------------|
| apb_write_test | ~1 second | 20 |
| apb_comprehensive_test | ~10 seconds | 500+ |

Simulation time depends on your simulator and machine.

## Documentation

- **Detailed plans**: See `VERIFICATION_PLANS.md`
- **Full README**: See `README.md`
- **Design details**: See `Src/apbtop.v` comments

## Support

For issues or questions:
1. Check this guide
2. Review `VERIFICATION_PLANS.md`
3. Check simulation log for error messages
4. Verify file paths and compile commands

---

**Quick Test**: Run this to verify everything works:
```bash
vlog -sv +incdir+Src Src/top.sv && vsim -c top +UVM_TESTNAME=apb_write_read_test -do "run -all; quit"
```

If you see "*** TEST PASSED ***" at the end, you're good to go! 🎉
