// DESCRIPTION: Verilator: Verilog Test module
//
// This file ONLY is placed under the Creative Commons Public Domain
// SPDX-FileCopyrightText: 2026 Nikolai Kumar
// SPDX-License-Identifier: CC0-1.0

// verilog_format: off
`define stop $stop
`define checkd(gotv,expv) do if ((gotv) !== (expv)) begin $write("%%Error: %s:%0d:  got=%0d exp=%0d\n", `__FILE__,`__LINE__, (gotv), (expv)); `stop; end while(0);
// verilog_format: on

class monitor;
  bit clk, enable, fired;
  task run();
    forever @(posedge clk iff enable) fired = 1;
  endtask
endclass

module t;
  monitor mon = new;
  always #5 mon.clk = ~mon.clk;

  // Sensitivity terms that differ only by iff must not be merged
  logic clk = 0;
  logic a = 0;
  logic b = 1;
  int n1 = 0;
  int n2 = 0;
  int n3 = 0;
  logic [7:0] r = 0;
  always #5 clk = ~clk;
  initial #50 a = 1;
  always @(posedge clk iff a or posedge clk iff b) n1 <= n1 + 1;
  always @(posedge clk iff a or negedge clk) n2 <= n2 + 1;
  always @(posedge clk iff a or posedge clk) n3 <= n3 + 1;
  always_ff @(posedge clk iff a) r[7:4] <= r[7:4] + 4'd1;
  always_ff @(posedge clk) r[3:0] <= r[3:0] + 4'd1;

  initial begin
    fork
      mon.run();
    join_none

    repeat (4) @(posedge mon.clk);
    `checkd(mon.fired, 0);

    mon.enable = 1;
    repeat (2) @(posedge mon.clk);
    `checkd(mon.fired, 1);

    #44;  // Time 99, before the clk toggle at 100
    `checkd(n1, 10);
    `checkd(n2, 14);
    `checkd(n3, 10);
    `checkd(r, 8'h5a);

    $write("*-* All Finished *-*\n");
    $finish;
  end
endmodule
