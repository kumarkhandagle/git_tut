// ============================================================================
//  Testbench  : tb_TC_010.v
//  Test Case  : TC_010
//  Title      : TS1 – COM byte (symbol 0)
//  DUT        : osGen.v
//  Spec Ref   : PCIe Base Spec Rev 3.0, Table 4-3
//  Priority   : P1
//
//  What this test checks
//  ─────────────────────
//  When a TS1 ordered set is requested, the very first byte that the
//  osGen drives onto the PIPE interface must be K28.5 = 0xBC replicated
//  identically across all 16 lanes.  At the same time, TxDataK must be
//  16'hFFFF because COM is a K-symbol in 8b/10b encoding.
//
//  Stimulus
//  ─────────
//    OSGen_Type    = 3'b000   (TS1)
//    OSGen_Start   = 1        for exactly 1 pclk cycle
//    OSGen_LaneNum = 8'hF7    (PAD)
//    OSGen_LinkNum = 8'hF7    (PAD)
//    OSGen_Rate    = 2'b00    (Gen1)
//    All other inputs = 0
//
//  Expected result at symbol 0
//  ────────────────────────────
//    TxData      = 128'h{BCBC...BC}   (K28.5 × 16 lanes)
//    TxDataK     = 16'hFFFF
//    TxDataValid = 16'hFFFF
//    OSGen_Busy  = 1
//    OSGen_Done  = 0
//
//  Cycle-accurate timing (IMPORTANT – read before modifying the TB)
//  ─────────────────────────────────────────────────────────────────
//  Both always blocks inside osGen are SEQUENTIAL (clocked).
//  The output driver reads 'symbol' and 'active' which are the
//  registered (Q) outputs of the latch block.
//
//  Cycle │rst_n│Start│active(Q)│symbol(Q)│ TxData(Q)      │Busy(Q)
//  ──────┼─────┼─────┼─────────┼─────────┼────────────────┼───────
//   0-4  │  0  │  0  │    0    │    0    │   0            │  0    } reset
//    5   │  1  │  0  │    0    │    0    │   0            │  0    } released
//    6   │  1  │  0  │    0    │    0    │   0            │  0    } settle
//    7   │  1  │  0  │    0    │    0    │   0            │  0    } settle
//    8   │  1  │  1  │  0→1   │   0→0  │  BC×16 ← SYM0  │ 0→1  } START
//    9   │  1  │  0  │    1    │   0→1  │  F7×16   SYM1   │  1   }
//   10   │  1  │  0  │    1    │   1→2  │  F7×16   SYM2   │  1   }
//  ...                                                             } TS1
//   23   │  1  │  0  │    1    │  14→15 │  4A×16   SYM15  │  1   }
//   24   │  1  │  0  │  1→0   │  15→0  │   0       Done  │ 1→0  } DONE
//
//  On cycle 8 (Start=1), 'active' is still 0 (old Q) so the output
//  driver enters the Start branch, reads symbol=0 (old Q) and drives
//  BC×16.  Both 'active' and 'TxData(BC)' update at the SAME edge.
//  Therefore TxData == BC×16 is readable one #1 after the posedge
//  that captured Start=1.  This is exactly where STEP 4 samples it.
//
// ============================================================================
`timescale 1ns/1ps

module tb_TC_010;

// ============================================================================
//  PARAMETERS
// ============================================================================
    parameter CLK_HALF = 2;    // 250 MHz → 4 ns period → 2 ns half

    // Expected values at symbol 0  (spec Table 4-3)
    parameter [127:0] EXP_TXDATA  = {16{8'hBC}};  // K28.5 × 16 lanes
    parameter [15:0]  EXP_TXDATAK = 16'hFFFF;      // COM is K-symbol
    parameter [15:0]  EXP_VALID   = 16'hFFFF;      // all lanes active

// ============================================================================
//  DUT PORT SIGNALS
// ============================================================================

    // Inputs to DUT – driven by testbench (reg)
    reg        pclk;
    reg        rst_n;
    reg        OSGen_Start;
    reg [2:0]  OSGen_Type;
    reg [7:0]  OSGen_LaneNum;
    reg [7:0]  OSGen_LinkNum;
    reg [1:0]  OSGen_Rate;
    reg        OSGen_Loopback;
    reg        OSGen_DisScram;
    reg [5:0]  OSGen_EqPreset;

    // Outputs from DUT – observed by testbench (wire)
    wire        OSGen_Busy;
    wire        OSGen_Done;
    wire [127:0] TxData;
    wire [15:0]  TxDataK;
    wire [15:0]  TxDataValid;

// ============================================================================
//  DUT INSTANTIATION
// ============================================================================
    osGen u_dut (
        .pclk           (pclk),
        .rst_n          (rst_n),
        .OSGen_Start    (OSGen_Start),
        .OSGen_Type     (OSGen_Type),
        .OSGen_LaneNum  (OSGen_LaneNum),
        .OSGen_LinkNum  (OSGen_LinkNum),
        .OSGen_Rate     (OSGen_Rate),
        .OSGen_Loopback (OSGen_Loopback),
        .OSGen_DisScram (OSGen_DisScram),
        .OSGen_EqPreset (OSGen_EqPreset),
        .OSGen_Busy     (OSGen_Busy),
        .OSGen_Done     (OSGen_Done),
        .TxData         (TxData),
        .TxDataK        (TxDataK),
        .TxDataValid    (TxDataValid)
    );

// ============================================================================
//  CLOCK GENERATION  –  250 MHz
// ============================================================================
    initial pclk = 1'b0;
    always  #(CLK_HALF) pclk = ~pclk;

// ============================================================================
//  WAVEFORM DUMP  –  open tc_010.vcd in GTKWave to view signals
// ============================================================================
    initial begin
        $dumpfile("tc_010.vcd");
        $dumpvars(0, tb_TC_010);
    end

// ============================================================================
//  PASS / FAIL COUNTERS
// ============================================================================
    integer pass_cnt;
    integer fail_cnt;

// ============================================================================
//  CHECK TASK
//  Compares observed vs expected.
//  Uses 4-state === so X or Z on observed always reports FAIL.
// ============================================================================
    task automatic chk;
        input [127:0] obs;      // value seen on DUT output
        input [127:0] exp;      // value expected from spec
        input [0:239] label;    // name of the signal being checked
        begin
            if (obs === exp) begin
                $display("    PASS | %-30s | got=0x%0h", label, obs);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("    FAIL | %-30s | got=0x%0h  exp=0x%0h",
                          label, obs, exp);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

// ============================================================================
//  MAIN STIMULUS
// ============================================================================
    initial begin : TC_010_MAIN

        // ── initialise all signals ───────────────────────────────────────────
        pass_cnt      = 0;
        fail_cnt      = 0;
        rst_n         = 1'b0;
        OSGen_Start   = 1'b0;
        OSGen_Type    = 3'b000;
        OSGen_LaneNum = 8'hF7;
        OSGen_LinkNum = 8'hF7;
        OSGen_Rate    = 2'b00;
        OSGen_Loopback= 1'b0;
        OSGen_DisScram= 1'b0;
        OSGen_EqPreset= 6'h00;

        $display("");
        $display("---------------------------------------------------------------");
        $display("  TC_010 : TS1 – COM byte (symbol 0)");
        $display("  DUT    : osGen.v");
        $display("  Spec   : PCIe Base Spec Rev 3.0 – Table 4-3");
        $display("---------------------------------------------------------------");

        // ── STEP 1: Reset ────────────────────────────────────────────────────
        // Hold rst_n=0 for 5 cycles so DUT flops clear to zero.
        $display("  [STEP 1] Assert reset (rst_n=0 for 5 cycles)");
        repeat(5) @(posedge pclk);
        #1;                         // #1 positions the change just after edge
        rst_n = 1'b1;
        $display("           rst_n released at %0t ns", $time);

        // ── STEP 2: Confirm idle after reset ─────────────────────────────────
        // Let the DUT settle for 2 cycles then verify everything is 0.
        $display("  [STEP 2] Check DUT is idle after reset");
        repeat(2) @(posedge pclk);
        #1;

        $display("  --- Pre-stimulus idle checks ---");
        chk({127'd0, OSGen_Busy},  128'd0, "Busy = 0 (idle)        ");
        chk({127'd0, OSGen_Done},  128'd0, "Done = 0 (idle)        ");
        chk(TxData,                128'd0, "TxData = 0 (idle)      ");
        chk({112'd0, TxDataK},     128'd0, "TxDataK = 0 (idle)     ");
        chk({112'd0, TxDataValid}, 128'd0, "TxDataValid = 0 (idle) ");

        // ── STEP 3: Apply stimulus ───────────────────────────────────────────
        // Set inputs matching TC_010 specification BEFORE the clock edge.
        // Assert OSGen_Start for exactly 1 cycle.
        $display("  [STEP 3] Stimulus: OSGen_Start=1, Type=000, Lane=F7, Link=F7, Rate=00");

        OSGen_Type    = 3'b000;   // TS1
        OSGen_LaneNum = 8'hF7;    // PAD  (per TC_010)
        OSGen_LinkNum = 8'hF7;    // PAD  (per TC_010)
        OSGen_Rate    = 2'b00;    // Gen1 (per TC_010)
        OSGen_Start   = 1'b1;     // start pulse

        // ── STEP 4: Capture symbol 0 output ──────────────────────────────────
        // At the NEXT posedge:
        //   – Latch block sees Start=1, active=0  → sets active=1, symbol=0
        //   – Output block sees Start=1, active=0  → enters Start branch,
        //     reads symbol=0 → drives TxData = BC×16
        // Both updates commit at this SAME posedge.
        // We sample after the #1 propagation guard.
        @(posedge pclk);
        #1;

        // De-assert Start immediately (1-cycle pulse)
        OSGen_Start = 1'b0;

        $display("  [STEP 4] Check symbol 0 output (sampled after Start posedge)");
        $display("  --- Symbol 0 checks ---");

        // CHECK A: TxData must be K28.5 = 0xBC on all 16 lanes
        chk(TxData,
            EXP_TXDATA,
            "TxData = 0xBC × 16    ");

        // CHECK B: TxDataK must be 16'hFFFF (COM is K-symbol on every lane)
        chk({112'd0, TxDataK},
            {112'd0, EXP_TXDATAK},
            "TxDataK = 16'hFFFF    ");

        // CHECK C: TxDataValid must be 16'hFFFF (all 16 lanes active)
        chk({112'd0, TxDataValid},
            {112'd0, EXP_VALID},
            "TxDataValid = 16'hFFFF");

        // CHECK D: OSGen_Busy must be 1 (transmitter is active)
        chk({127'd0, OSGen_Busy},
            128'd1,
            "OSGen_Busy = 1        ");

        // CHECK E: OSGen_Done must be 0 (Done only fires at symbol 15)
        chk({127'd0, OSGen_Done},
            128'd0,
            "OSGen_Done = 0        ");

        // CHECK F: Per-lane granular check
        // Slice TxData[127:0] into 16 × 8-bit pieces and verify each lane
        // independently.  Lane N occupies bits [N*8+7 : N*8].
        $display("  --- Per-lane byte checks (lanes 0..15) ---");
        begin : PER_LANE
            integer ln;
            reg [7:0] b;
            reg       lane_ok;
            lane_ok = 1'b1;
            for (ln = 0; ln < 16; ln = ln + 1) begin
                b = TxData[ln*8 +: 8];         // extract 8-bit lane slice
                if (b !== 8'hBC) begin
                    $display("    FAIL | Lane %2d = 0x%0h  (expected 0xBC)", ln, b);
                    lane_ok  = 1'b0;
                    fail_cnt = fail_cnt + 1;
                end
            end
            if (lane_ok) begin
                $display("    PASS | All 16 lanes carry 0xBC correctly");
                pass_cnt = pass_cnt + 1;
            end
        end

        // ── STEP 5: Let the full TS1 run to Done ─────────────────────────────
        // This is not part of TC_010's pass criteria, but running to Done
        // ensures the DUT is not stuck and gives a complete waveform.
        $display("  [STEP 5] Wait for OSGen_Done (TS1 = 16 symbols)");
        begin : WAIT_DONE
            integer timeout;
            timeout = 0;
            // Done fires at symbol 15, i.e. 15 more cycles after symbol 0
            while (!OSGen_Done && timeout < 40) begin
                @(posedge pclk); #1;
                timeout = timeout + 1;
            end
            if (OSGen_Done)
                $display("           OSGen_Done received at %0t ns – OK", $time);
            else begin
                $display("    FAIL | OSGen_Done never fired (timeout at %0t ns)", $time);
                fail_cnt = fail_cnt + 1;
            end
        end

        // Verify DUT returns to idle after Done
        @(posedge pclk); #1;
        $display("  --- Post-Done idle checks ---");
        chk({127'd0, OSGen_Busy}, 128'd0, "Busy = 0 after Done    ");
        chk({127'd0, OSGen_Done}, 128'd0, "Done = 0 after Done    ");

        // ── STEP 6: Final summary ─────────────────────────────────────────────
        $display("");
        $display("════════════════════════════════════════════════════════════");
        $display("  TC_010 RESULT  |  Pass: %0d  |  Fail: %0d",
                  pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display("  *** TC_010 : PASS ***");
        else
            $display("  *** TC_010 : FAIL ***  (%0d checks failed – see above)",
                      fail_cnt);
        $display("════════════════════════════════════════════════════════════");
        $display("");

        #20;
        $finish;
    end

// ============================================================================
//  WATCHDOG  –  kill sim if it runs longer than 500 ns
// ============================================================================
    initial begin
        #500;
        $display("WATCHDOG: 500 ns exceeded – force quit");
        $finish;
    end

// ============================================================================
//  LIVE SYMBOL TRACE
//  Prints one line per symbol while the DUT is transmitting.
//  Lets you read the full TS1 sequence from the console.
// ============================================================================
    always @(posedge pclk) begin
        if (OSGen_Busy || OSGen_Done)
            $display("  [%4t ns] sym=%0d  data[7:0]=8'h%0h  DataK[0]=%0b  Busy=%0b  Done=%0b",
                     $time,
                     u_dut.symbol,     // peek at internal symbol counter
                     TxData[7:0],      // lane-0 byte (same for all lanes)
                     TxDataK[0],
                     OSGen_Busy,
                     OSGen_Done);
    end

endmodule

// ============================================================================
//  HOW TO COMPILE AND RUN
// ============================================================================
//
//  Icarus Verilog (free / open-source):
//    iverilog -o tc010.out tb_TC_010.v osGen.v
//    vvp tc010.out
//    gtkwave tc_010.vcd        ← add signals to view waveforms
//
//  VCS (Synopsys):
//    vcs tb_TC_010.v osGen.v -o simv
//    ./simv
//
//  Questa / ModelSim:
//    vlog tb_TC_010.v osGen.v
//    vsim -c work.tb_TC_010 -do "run -all; quit"
//
// ============================================================================
//  EXPECTED CONSOLE OUTPUT  (when DUT is correct)
// ============================================================================
//
//  ════════════════════════════════════════════════════════════
//    TC_010 : TS1 – COM byte (symbol 0)
//    DUT    : osGen.v
//    Spec   : PCIe Base Spec Rev 3.0 – Table 4-3
//  ════════════════════════════════════════════════════════════
//    [STEP 1] Assert reset (rst_n=0 for 5 cycles)
//             rst_n released at 20 ns
//    [STEP 2] Check DUT is idle after reset
//    --- Pre-stimulus idle checks ---
//      PASS | Busy = 0 (idle)         | got=0x0
//      PASS | Done = 0 (idle)         | got=0x0
//      PASS | TxData = 0 (idle)       | got=0x0
//      PASS | TxDataK = 0 (idle)      | got=0x0
//      PASS | TxDataValid = 0 (idle)  | got=0x0
//    [STEP 3] Stimulus: OSGen_Start=1, Type=000, Lane=F7, Link=F7, Rate=00
//    [STEP 4] Check symbol 0 output (sampled after Start posedge)
//    --- Symbol 0 checks ---
//      PASS | TxData = 0xBC × 16     | got=0xbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbc
//      PASS | TxDataK = 16'hFFFF     | got=0xffff
//      PASS | TxDataValid = 16'hFFFF | got=0xffff
//      PASS | OSGen_Busy = 1         | got=0x1
//      PASS | OSGen_Done = 0         | got=0x0
//    --- Per-lane byte checks (lanes 0..15) ---
//      PASS | All 16 lanes carry 0xBC correctly
//    [STEP 5] Wait for OSGen_Done (TS1 = 16 symbols)
//             OSGen_Done received at 96 ns – OK
//    --- Post-Done idle checks ---
//      PASS | Busy = 0 after Done    | got=0x0
//      PASS | Done = 0 after Done    | got=0x0
//
//  ════════════════════════════════════════════════════════════
//    TC_010 RESULT  |  Pass: 13  |  Fail: 0
//    *** TC_010 : PASS ***
//  ════════════════════════════════════════════════════════════
//
// ============================================================================