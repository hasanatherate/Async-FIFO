module async_fifo #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 4
)(
  input  logic wr_clk, wr_rst_n, wr_en,
  input  logic rd_clk, rd_rst_n, rd_en,
  input  logic [DATA_WIDTH-1:0] din,
  output logic [DATA_WIDTH-1:0] dout,
  output logic full, empty
);

  localparam DEPTH = 1 << ADDR_WIDTH;
  logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];

  logic [ADDR_WIDTH:0] wptr_bin, rptr_bin;
  logic [ADDR_WIDTH:0] wptr_gray, rptr_gray;
  logic [ADDR_WIDTH:0] wq1_rptr, wq2_rptr;
  logic [ADDR_WIDTH:0] rq1_wptr, rq2_wptr;

  // WRITE DOMAIN
  always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n)
      wptr_bin <= 0;
    else if (wr_en && !full) begin
      mem[wptr_bin[ADDR_WIDTH-1:0]] <= din;
      wptr_bin <= wptr_bin + 1;
    end
  end

  assign wptr_gray = wptr_bin ^ (wptr_bin >> 1);

  // READ DOMAIN
  always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n)
      rptr_bin <= 0;
    else if (rd_en && !empty) begin
      dout <= mem[rptr_bin[ADDR_WIDTH-1:0]];
      rptr_bin <= rptr_bin + 1;
    end
  end

  assign rptr_gray = rptr_bin ^ (rptr_bin >> 1);

  // CDC SYNC
  always_ff @(posedge wr_clk or negedge wr_rst_n)
    if (!wr_rst_n) {wq2_rptr, wq1_rptr} <= 0;
    else           {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr_gray};

  always_ff @(posedge rd_clk or negedge rd_rst_n)
    if (!rd_rst_n) {rq2_wptr, rq1_wptr} <= 0;
    else           {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr_gray};

  assign empty = (rptr_gray == rq2_wptr);
  assign full  = (wptr_gray ==
                 {~wq2_rptr[ADDR_WIDTH:ADDR_WIDTH-1],
                   wq2_rptr[ADDR_WIDTH-2:0]});

endmodule
