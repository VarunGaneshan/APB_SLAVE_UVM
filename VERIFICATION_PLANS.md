# APB SLAVE VERIFICATION PLANS

## Table of Contents
1. [Test Plan](#test-plan)
2. [Coverage Plan](#coverage-plan)
3. [Assertion Plan](#assertion-plan)
4. [Implementation Summary](#implementation-summary)

---

## 1. TEST PLAN

### 1.1 Objective
Verify the functionality of the APB Slave module with:
- **Address Width**: 8-bit (256 locations)
- **Data Width**: 32-bit
- **Memory Depth**: 256 locations
- **Features**: Read/Write with byte strobes, error detection

### 1.2 Test Scenarios

#### **1.2.1 Basic Functional Tests**

##### Reset Test
- **Objective**: Verify proper reset behavior
- **Implementation**: `apb_base_test` initial reset sequence
- **Checks**:
  - All memory locations initialized to 0
  - PRDATA outputs 0 after reset
  - Proper behavior during and after reset assertion

##### Single Write Tests
- **Sequence**: `apb_write_sequence`
- **Coverage**:
  - Write to different memory locations (full address range)
  - Write with full PSTRB (all bytes enabled)
  - Write to boundary addresses (0x00, 0xFF)
  - Various data patterns (all 0s, all 1s, walking 1s/0s, random)

##### Single Read Tests
- **Sequence**: `apb_read_sequence`
- **Coverage**:
  - Read from different memory locations
  - Read from boundary addresses
  - Read from uninitialized locations (expect 0)

##### Back-to-Back Operations
- **Sequence**: `apb_write_read_sequence`
- **Coverage**:
  - Write followed by immediate read (same address)
  - Consecutive writes to different addresses
  - Consecutive reads from different addresses

#### **1.2.2 APB Protocol Compliance Tests**

##### PSEL and PENABLE Timing
- **Driver Implementation**: Two-phase protocol in `apb_driver.sv`
- **Assertions**: Protocol sequence checks
- **Verification**:
  - Transfer occurs only when PSEL=1 and PENABLE=1
  - SETUP phase (PSEL=1, PENABLE=0)
  - ACCESS phase (PSEL=1, PENABLE=1)

##### PREADY Signal Tests
- **Expected**: PREADY=1 for single-cycle access
- **Assertion**: `assert_pready_high`
- **Coverage**: Always monitored

##### PWRITE Control Tests
- **Sequences**: All write and read sequences
- **Coverage**:
  - Write operation (PWRITE=1)
  - Read operation (PWRITE=0)
  - Alternating read/write sequences

#### **1.2.3 Byte Strobe (PSTRB) Tests**

##### PSTRB Variations
- **Sequence**: `apb_byte_strobe_sequence`
- **Coverage**: 14 valid PSTRB combinations
  - All bytes: 4'b1111
  - Single byte: 4'b0001, 4'b0010, 4'b0100, 4'b1000
  - Two bytes: 4'b0011, 4'b1100, 4'b0101, 4'b1010
  - Three bytes: 4'b0111, 4'b1110, 4'b1011, 4'b1101
  - Zero bytes: 4'b0000 (no write should occur)

##### Byte Write Granularity
- **Scoreboard Check**: Verify only strobed bytes are written
- **Test**: Write with partial PSTRB, read back, verify unchanged bytes

#### **1.2.4 Error Handling Tests**

##### Address Boundary Tests
- **Sequence**: `apb_error_sequence`
- **Valid Range**: 0 to 255
- **Invalid Range**: 256 and above
- **Expected**:
  - Write to out-of-range: PSLVERR=1
  - Read from out-of-range: PSLVERR=1, PRDATA=0xFFFFFFFF

##### Error Signal Tests
- **Assertions**:
  - `assert_error_invalid_addr`: Error for invalid addresses
  - `assert_no_error_valid`: No error for valid addresses
  - `assert_no_error_idle`: No error during idle

#### **1.2.5 Stress Tests**

##### Burst Operations
- **Sequences**: 
  - `apb_burst_write_sequence`: Sequential writes
  - `apb_burst_read_sequence`: Sequential reads
- **Coverage**: 16-64 consecutive operations

##### Random Operations
- **Sequence**: `apb_random_sequence`
- **Coverage**: 100-200 mixed random transactions
- **Includes**: Random idle cycles, mixed read/write, random addresses

##### Comprehensive Test
- **Test**: `apb_comprehensive_test`
- **Execution**: All sequences in sequence
- **Duration**: 500+ transactions

### 1.3 Test Execution Matrix

| Test Name | Sequence(s) | Transactions | Coverage Focus |
|-----------|-------------|--------------|----------------|
| apb_write_test | apb_write_sequence | 20 | Basic writes |
| apb_read_test | apb_read_sequence | 20 | Basic reads |
| apb_write_read_test | apb_write_read_sequence | 30 | Write-read verification |
| apb_byte_strobe_test | apb_byte_strobe_sequence | 13 | All PSTRB combinations |
| apb_error_test | apb_error_sequence | 20 | Error handling |
| apb_random_test | apb_random_sequence | 100 | Random stress |
| apb_burst_test | burst_write + burst_read | 64 | Burst operations |
| apb_comprehensive_test | All sequences | 500+ | Full coverage |

---

## 2. COVERAGE PLAN

### 2.1 Functional Coverage Groups

#### **Protocol Coverage** (`apb_protocol_cg`)
```systemverilog
- PWRITE: write (1), read (0)
- PSEL: selected (1), not_selected (0)
- PREADY: ready (1), not_ready (0)
- PSLVERR: no_error (0), error (1)
```
**Target**: 100%

#### **Address Coverage** (`address_cg`)
```systemverilog
- Address ranges:
  - Low: 0-63
  - Mid-low: 64-127
  - Mid-high: 128-191
  - High: 192-255
  - Out-of-range: 256+
- Boundaries: 0, 255
- Validity: valid, invalid
```
**Target**: >95%

#### **Data Coverage** (`data_cg`)
```systemverilog
Write data patterns:
- All zeros: 0x00000000
- All ones: 0xFFFFFFFF
- Alternating: 0xAAAAAAAA, 0x55555555
- Ranges: low, mid, high

Read data patterns:
- All zeros, all ones, alternating, other
```
**Target**: >90%

#### **Byte Strobe Coverage** (`pstrb_cg`)
```systemverilog
All 14 valid combinations:
- 4'b1111 (all bytes)
- 4'b0001, 4'b0010, 4'b0100, 4'b1000 (single)
- 4'b0011, 4'b1100, 4'b0101, 4'b1010 (double)
- 4'b0111, 4'b1110, 4'b1011, 4'b1101 (triple)
- 4'b0000 (none - should not write)
```
**Target**: 100%

#### **Transfer Type Coverage** (`transfer_cg`)
```systemverilog
Cross coverage:
- write_selected: PWRITE=1, PSEL=1
- read_selected: PWRITE=0, PSEL=1
- idle: PSEL=0
```
**Target**: 100%

#### **Write Operation Coverage** (`write_cg`)
```systemverilog
- Address ranges during writes
- PSTRB × Address cross coverage
```
**Target**: >95%

#### **Read Operation Coverage** (`read_cg`)
```systemverilog
- Address ranges during reads
- PRDATA × PSLVERR cross coverage
```
**Target**: >95%

#### **Error Coverage** (`error_cg`)
```systemverilog
- Error on invalid address
- No error on valid address
- Error pattern (0xFFFFFFFF)
```
**Target**: 100%

#### **Boundary Coverage** (`boundary_cg`)
```systemverilog
- First address: 0
- Last valid: 255
- First invalid: 256
- Max value: 0xFF
- Data extremes: 0x00000000, 0xFFFFFFFF
```
**Target**: 100%

### 2.2 Code Coverage

#### **Line Coverage**
- **Target**: 100%
- **Focus**: All executable lines in DUT

#### **Branch Coverage**
- **Target**: 100%
- **Focus**: All if/else and case branches

#### **Condition Coverage**
- **Target**: 100%
- **Focus**: All boolean conditions

#### **Toggle Coverage**
- **Target**: >95%
- **Focus**: All I/O signals toggle 0→1 and 1→0

### 2.3 Coverage Reporting

Coverage is automatically collected by `apb_subscriber` and reported at end of simulation:

```
============================================
      FUNCTIONAL COVERAGE REPORT           
============================================
Protocol Coverage:    XX.XX%
Address Coverage:     XX.XX%
Data Coverage:        XX.XX%
Byte Strobe Coverage: XX.XX%
Transfer Coverage:    XX.XX%
Write Op Coverage:    XX.XX%
Read Op Coverage:     XX.XX%
Error Coverage:       XX.XX%
Boundary Coverage:    XX.XX%
--------------------------------------------
OVERALL COVERAGE:     XX.XX%
============================================
```

---

## 3. ASSERTION PLAN

### 3.1 Protocol Assertions

#### **APB Transfer Sequence**
```systemverilog
assert_penable_psel:
  PENABLE high requires PSEL high
  
assert_psel_penable_seq:
  Rising PSEL followed by PENABLE in next cycle
  
assert_no_continuous_access:
  No back-to-back ACCESS phases without SETUP
```

#### **Signal Stability**
```systemverilog
assert_addr_stable:
  PADDR stable from SETUP to ACCESS phase
  
assert_pwrite_stable:
  PWRITE stable during transfer
  
assert_pwdata_stable:
  PWDATA stable during write transfer
  
assert_pstrb_stable:
  PSTRB stable during write transfer
```

### 3.2 Functional Assertions

#### **PREADY Behavior**
```systemverilog
assert_pready_high:
  PREADY always 1 (single-cycle slave)
```

#### **Error Conditions**
```systemverilog
assert_error_invalid_addr:
  PSLVERR=1 when (PADDR >= 256) during transfer
  
assert_no_error_valid:
  PSLVERR=0 when (PADDR < 256) during transfer
  
assert_no_error_idle:
  PSLVERR=0 when no transfer
  
assert_read_error_pattern:
  PRDATA=0xFFFFFFFF for out-of-range reads
```

#### **Data Validity**
```systemverilog
assert_read_data_valid:
  PRDATA not X during valid read with PREADY
  
assert_pstrb_valid:
  PSTRB not X during write
  
assert_pwdata_valid:
  PWDATA not X during write
```

### 3.3 Reset Assertions

```systemverilog
assert_reset_prdata:
  PRDATA = 0 after reset deassertion
```

### 3.4 Coverage Assertions

```systemverilog
cover_write_transaction:
  Valid write transactions
  
cover_read_transaction:
  Valid read transactions
  
cover_error_transaction:
  Error conditions
  
cover_full_strobe:
  Full byte strobe writes
  
cover_partial_strobe:
  Partial byte strobe writes
```

### 3.5 Assertion Binding

All assertions are bound to the interface via `apb_bind.sv`:
```systemverilog
bind apb_if apb_assertions apb_if_assert_inst (...)
```

### 3.6 Assertion Reporting

- **Errors**: Reported immediately via $error
- **Warnings**: For protocol violations
- **Coverage**: Tracked throughout simulation
- **Summary**: Available in simulation log

---

## 4. IMPLEMENTATION SUMMARY

### 4.1 Files Updated

| File | Status | Changes |
|------|--------|---------|
| project_configs.sv | ✅ Updated | ADDR_WIDTH=8, DATA_WIDTH=32, added MEM_DEPTH, STRB_WIDTH |
| apb_if.sv | ✅ Updated | New APB slave signals with proper clocking blocks |
| apb_sequence_item.sv | ✅ Updated | APB slave transaction fields with constraints |
| apb_driver.sv | ✅ Updated | Two-phase APB protocol implementation |
| apb_active_monitor.sv | ✅ Updated | Monitor APB input signals during ACCESS phase |
| apb_passive_monitor.sv | ✅ Updated | Monitor APB output signals |
| apb_scoreboard.sv | ✅ Updated | Reference model with byte strobe support |
| apb_sequence.sv | ✅ Updated | 9 comprehensive test sequences |
| apb_subscriber.sv | ✅ Updated | 9 coverage groups with detailed bins |
| apb_assertions.sv | ✅ Updated | 30+ protocol and functional assertions |
| apb_bind.sv | ✅ Updated | Updated signal connections |
| apb_environment.sv | ✅ Updated | Fixed subscriber connection |
| apb_test.sv | ✅ Updated | 8 comprehensive test cases |
| apb_passive_agent.sv | ✅ Updated | Fixed monitor instantiation |
| top.sv | ✅ Updated | New DUT instantiation with APB slave |
| README.md | ✅ Updated | Comprehensive documentation |

### 4.2 Key Features Implemented

#### **Driver**
- ✅ SETUP phase (PSEL=1, PENABLE=0)
- ✅ ACCESS phase (PSEL=1, PENABLE=1)
- ✅ Proper signal timing
- ✅ IDLE state management

#### **Monitors**
- ✅ Transaction capture during valid transfers
- ✅ Separate input and output monitoring
- ✅ Proper synchronization

#### **Scoreboard**
- ✅ Reference memory model (256 × 32-bit)
- ✅ Byte-level write granularity
- ✅ Data integrity checking
- ✅ Error condition verification
- ✅ Detailed pass/fail reporting

#### **Coverage**
- ✅ 9 comprehensive coverage groups
- ✅ Protocol, address, data, PSTRB coverage
- ✅ Cross coverage
- ✅ Boundary and error coverage
- ✅ Automatic reporting

#### **Assertions**
- ✅ 20+ functional assertions
- ✅ 10+ coverage properties
- ✅ Protocol compliance checks
- ✅ Error detection verification

#### **Test Sequences**
- ✅ Basic read/write
- ✅ Write-read verification
- ✅ Byte strobe variations
- ✅ Error scenarios
- ✅ Burst operations
- ✅ Random stress testing

### 4.3 Verification Quality Metrics

| Metric | Target | Implementation |
|--------|--------|----------------|
| Functional Coverage | >98% | 9 coverage groups with detailed bins |
| Code Coverage | >99% | Full DUT instrumentation |
| Assertion Coverage | >95% | 30+ assertions covering all scenarios |
| Test Scenarios | All | 8 comprehensive tests |
| Protocol Compliance | 100% | Full APB protocol implementation |

### 4.4 Running Instructions

1. **Compile**: `vlog -sv +incdir+Src Src/top.sv`
2. **Run**: `vsim -c top +UVM_TESTNAME=apb_comprehensive_test -do "run -all"`
3. **Coverage**: Use simulator coverage tools
4. **Reports**: Check simulation logs for scoreboard and coverage reports

### 4.5 Success Criteria

✅ All tests pass (PASSED count = Total transactions)  
✅ Zero assertion failures  
✅ Functional coverage >98%  
✅ Code coverage >99%  
✅ All protocol checks pass  
✅ Error scenarios properly handled  

---

## Conclusion

This verification environment provides comprehensive coverage of the APB Slave functionality with:
- **Complete protocol implementation** following APB specification
- **Reference model** for data integrity checking
- **Extensive coverage** across all features
- **Robust assertions** for protocol compliance
- **Multiple test scenarios** from basic to stress testing

The environment is ready for regression testing and can be easily extended for additional features or requirements.
