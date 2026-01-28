interface fifo_if(input logic wr_clk, rd_clk);
  logic wr_en, rd_en, wr_rst_n, rd_rst_n;
  logic [7:0] din, dout;
  logic full, empty;

  property p_no_write_when_full;
    @(posedge wr_clk) disable iff (!wr_rst_n)
      full |-> !wr_en;
  endproperty
  assert property (p_no_write_when_full);

  property p_no_read_when_empty;
    @(posedge rd_clk) disable iff (!rd_rst_n)
      empty |-> !rd_en;
  endproperty
  assert property (p_no_read_when_empty);
endinterface


class transaction;
  rand bit [7:0] din;
  rand bit wr_en, rd_en;
  bit [7:0] dout;
  bit full, empty;

  constraint burst_c {
    wr_en dist {1 := 70, 0 := 30};
    rd_en dist {1 := 70, 0 := 30};
  }
endclass


class generator;
  mailbox gen2drv;
  int count;
  event done;

  function new(mailbox gen2drv);
    this.gen2drv = gen2drv;
  endfunction

  task run();
    repeat (count) begin
      transaction tr = new();
      assert(tr.randomize());
      gen2drv.put(tr);
    end
    -> done;
  endtask
endclass


class driver;
  virtual fifo_if vif;
  mailbox gen2drv;

  function new(virtual fifo_if vif, mailbox gen2drv);
    this.vif = vif;
    this.gen2drv = gen2drv;
  endfunction

  task run();
    forever begin
      transaction tr;
      gen2drv.get(tr);

      @(posedge vif.wr_clk);
      vif.wr_en <= tr.wr_en;
      vif.din   <= tr.din;

      @(posedge vif.rd_clk);
      vif.rd_en <= tr.rd_en;
    end
  endtask
endclass


class monitor;
  virtual fifo_if vif;
  mailbox mon2sb;

  covergroup fifo_cg @(posedge vif.wr_clk);
    option.per_instance = 1;
    cp_full  : coverpoint vif.full  { bins hit = {1}; }
    cp_empty : coverpoint vif.empty { bins hit = {1}; }
    cp_wr    : coverpoint vif.wr_en;
    cp_rd    : coverpoint vif.rd_en;
    cross_full_wr  : cross cp_full, cp_wr;
    cross_empty_rd : cross cp_empty, cp_rd;
    cross_rw       : cross cp_wr, cp_rd;
  endgroup

  function new(virtual fifo_if vif, mailbox mon2sb);
    this.vif = vif;
    this.mon2sb = mon2sb;
    fifo_cg = new();
  endfunction

  task run();
    forever begin
      transaction tr = new();

      @(posedge vif.wr_clk);
      tr.wr_en = vif.wr_en;
      tr.din   = vif.din;
      tr.full  = vif.full;

      @(posedge vif.rd_clk);
      tr.rd_en = vif.rd_en;
      tr.dout  = vif.dout;
      tr.empty = vif.empty;

      mon2sb.put(tr);
      fifo_cg.sample();
    end
  endtask
endclass


class scoreboard;
  mailbox mon2sb;
  bit [7:0] q[$];

  function new(mailbox mon2sb);
    this.mon2sb = mon2sb;
  endfunction

  task run();
    forever begin
      transaction tr;
      mon2sb.get(tr);

      if (tr.wr_en && !tr.full)
        q.push_back(tr.din);

      if (tr.rd_en && !tr.empty && q.size() > 0) begin
        bit [7:0] exp = q.pop_front();
        if (tr.dout !== exp)
          $error("DATA MISMATCH exp=%h got=%h", exp, tr.dout);
      end
    end
  endtask
endclass


module tb_top;
  bit wr_clk = 0, rd_clk = 0;
  always #5 wr_clk = ~wr_clk;
  always #7 rd_clk = ~rd_clk;

  fifo_if bif(wr_clk, rd_clk);

  async_fifo dut (
    .wr_clk(wr_clk), .wr_rst_n(bif.wr_rst_n), .wr_en(bif.wr_en),
    .rd_clk(rd_clk), .rd_rst_n(bif.rd_rst_n), .rd_en(bif.rd_en),
    .din(bif.din), .dout(bif.dout),
    .full(bif.full), .empty(bif.empty)
  );

  mailbox g2d = new(), m2s = new();
  generator  gen;
  driver     drv;
  monitor    mon;
  scoreboard sb;

  initial begin
    gen = new(g2d);
    drv = new(bif, g2d);
    mon = new(bif, m2s);
    sb  = new(m2s);

    bif.wr_rst_n = 0;
    bif.rd_rst_n = 0;
    bif.wr_en = 0;
    bif.rd_en = 0;
    #20;
    bif.wr_rst_n = 1;
    bif.rd_rst_n = 1;

    gen.count = 50;

    fork
      gen.run();
      drv.run();
      mon.run();
      sb.run();
    join_none

    wait(gen.done.triggered);
    #100;
    $display("Functional Coverage = %0.2f %%", mon.fifo_cg.get_coverage());
    $finish;
  end
endmodule
