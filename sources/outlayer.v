`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/26 09:48:17
// Design Name: 
// Module Name: out_layer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module outlayer(
    input           aclk,
    input           aresetn,

    //------weight in channel-------//
    input   [15:0]  w_tdata,
    input   [7:0]   w_tid,//MSB High Valid


    //----in port----//
    input          s_tvalid,
    output         s_tready,
    input  [15:0]  s_tdata0,
    input  [15:0]  s_tdata1,
    input  [15:0]  s_tdata2,

    //---out port---//
    output        m_tvalid,
    input         m_tready,
    output  [15:0]  m_tdata,

    input   [3:0] input_dim
    );


//------weight distribute----//
reg  [2:0]  w_tid_reg;

reg  w_tvalid_cell;
reg  [15:0] w_tdata_cell;
always @(posedge aclk)
begin
  w_tdata_cell <= w_tdata;
  
  case (w_tid[7:5])
    3'h4: w_tvalid_cell <= 1'b1;
    default: w_tvalid_cell <= 1'b0;
  endcase


  case (w_tid[4:0])
    5'h0: w_tid_reg <= 3'h1;
    5'h1: w_tid_reg <= 3'h2;
    5'h2: w_tid_reg <= 3'h4;

    default: w_tid_reg <= 3'h0;
  endcase
end
wire w_tlast_cell;
assign w_tlast_cell = w_tvalid_cell&(~w_tid[7]);




localparam  IDLE = 3'b001,
            CACU = 3'b010,
            SETW = 3'b100;
//------------state machine ctrl------------//
reg [2:0] CS,NS;
reg [3:0] counter;
wire setw_done,cacu_dealing;
wire buffer_full;
always @(posedge aclk or negedge aresetn)
  begin
    if (aresetn == 1'b0) CS <= IDLE;
    else CS <= NS;
  end

  always @(*)
  begin
    if (aresetn == 1'b0)
    NS = IDLE;
    else
    begin
    case (CS)
      IDLE:
      begin
        if (w_tvalid_cell == 1'b1) NS = SETW;
        else if((s_tvalid == 1'b1) && (buffer_full == 1'b0)) NS = CACU;
        else NS = IDLE;
      end

      CACU:
      begin
        if (cacu_dealing == 1'b1) NS = CACU;
        else NS = IDLE;
      end 

      SETW:
      begin
        if (setw_done  == 1'b1) NS = IDLE;
        else NS = SETW;
      end

      // WAIT:
      // begin
      //   if(buffer_full == 1'b1) NS = WAIT;
      //   else NS = IDLE;
      // end

      default: NS = IDLE;
    endcase
    end
  end

  always @(posedge aclk or negedge aresetn)
  begin
    if (aresetn == 1'b0)
    begin
      counter <= 4'h0;
    end
    else
    begin
      case (NS)
        IDLE: counter <= 4'h0;

        CACU: counter <= counter+1;

        // WAIT: counter <= counter;

        SETW: 
        begin
          if(w_tvalid_cell == 1'b0) counter <= counter;
          else counter <= counter+1;
        end
        default: counter <= 4'h0;
      endcase
    end 
  end

assign setw_done = ((CS == SETW) && (w_tvalid_cell && w_tlast_cell))? 1'b1:1'b0;
assign cacu_dealing = (counter >= (input_dim-4'b1))? 1'b0:1'b1;
//assign s_tready = ((CS == IDLE  || CS == CACU) && (m_tready == 1'b1))?1'b1:1'b0;
assign s_tready = 1'b1;
// reg [2:0] back_pipe;
// always @(posedge aclk)
// begin
//   back_pipe[0] <= cacu_dealing;
//   back_pipe[1] <= back_pipe[0];
//   back_pipe[2] <= back_pipe[1];
// end
//wire [15:0] muladder_a[0:7];
wire [15:0] muladder_b0 [0:2];
wire [35:0] muladder_c0[0:2];
wire [35:0] muladder_p0 [0:2];
wire [35:0] sum ;

reg s_tvalid_pipe;
wire load_temp;
reg [2:0]load_pipe;
reg [35:0]muladder_p_pipe;

assign load_temp = (((input_dim-counter) == 4'h1) && (CS == CACU))? 1'b1:1'b0;



always @(posedge aclk)
begin
  s_tvalid_pipe <= s_tvalid;
  load_pipe[0] <= load_temp;
  load_pipe[1] <= load_pipe[0];
  muladder_p_pipe <= muladder_p0[2];

  
  
  
  
end

assign muladder_c0[0] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[0]:36'h0;
assign muladder_c0[1] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[1]:36'h0;
assign muladder_c0[2] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[2]:36'h0;


genvar i;
generate
  
  for (i = 0; i < 1; i = i+1) 
  begin:  layer4
my_multi_addere blocks40 (
  .clk(aclk),            // input wire CLK
  .a(s_tdata0),                // input wire [15 : 0] A
  .b(muladder_b0[0]),                // input wire [15 : 0] B
  .c(muladder_c0[0]),                // input wire [35 : 0] C
  .p(muladder_p0[0])               // output wire [35 : 0] P
);

weight_cache weight_cache40 (
  .a(counter),      // input wire [4 : 0] a
  .d(w_tdata_cell),      // input wire [15 : 0] d
  .clk(aclk),  // input wire clk
  .we(w_tid_reg[0]&w_tvalid_cell),    // input wire we
  .spo(muladder_b0[0])  // output wire [15 : 0] spo
);

my_multi_addere blocks41 (
  .clk(aclk),            // input wire CLK
  .a(s_tdata1),                // input wire [15 : 0] A
  .b(muladder_b0[1]),                // input wire [15 : 0] B
  .c(muladder_c0[1]),                // input wire [35 : 0] C
  .p(muladder_p0[1])               // output wire [35 : 0] P
);

weight_cache weight_cache41 (
  .a(counter),      // input wire [4 : 0] a
  .d(w_tdata_cell),      // input wire [15 : 0] d
  .clk(aclk),  // input wire clk
  .we(w_tid_reg[1]&w_tvalid_cell),    // input wire we
  .spo(muladder_b0[1])  // output wire [15 : 0] spo
);

my_multi_addere blocks42 (
  .clk(aclk),            // input wire CLK
  .a(s_tdata2),                // input wire [15 : 0] A
  .b(muladder_b0[2]),                // input wire [15 : 0] B
  .c(muladder_c0[2]),                // input wire [35 : 0] C
  .p(muladder_p0[2])               // output wire [35 : 0] P
);

weight_cache weight_cache42 (
  .a(counter),      // input wire [4 : 0] a
  .d(w_tdata_cell),      // input wire [15 : 0] d
  .clk(aclk),  // input wire clk
  .we(w_tid_reg[2]&w_tvalid_cell),    // input wire we
  .spo(muladder_b0[2])  // output wire [15 : 0] spo
);
end
endgenerate


wire [35:0] temp_sum;
genvar j;
generate

 for (j = 0; j < 1; j = j+1) 
  begin:  layernadd
  
  adder_36 temp_adder (
  .A(muladder_p0[0]),      // input wire [35 : 0] A
  .B(muladder_p0[1]),      // input wire [35 : 0] B
  .CLK(aclk),  // input wire CLK
  .CE(1'b1),    // input wire CE
  .S(temp_sum)      // output wire [35 : 0] S
);

adder_36 final_adder (
  .A(muladder_p_pipe),      // input wire [35 : 0] A
  .B(temp_sum),      // input wire [35 : 0] B
  .CLK(aclk),  // input wire CLK
  .CE(1'b1),    // input wire CE
  .S(sum)      // output wire [35 : 0] S
);

end
endgenerate

reg [35:0] buffer ;
reg [3:0] out_cnt;
reg loada,loadb,loadc,loadd;

always @(posedge aclk)
begin

  loada <= load_pipe[0];
  loadb <= loada;
  if (loada == 1'b1) 
  begin
    buffer <= sum;
  end
  else
  begin
    buffer <= buffer;
    

  end

end

always @(posedge aclk or negedge aresetn)
begin
  if (aresetn == 1'b0) 
    out_cnt <= 4'h0;
  else if(loadb == 1'b1)
    out_cnt <= 4'h1;
  else if((m_tvalid == 1'b1) && (buffer_full == 1'b1))
    out_cnt <= out_cnt-1;
  else
    out_cnt <= out_cnt;
end

reg [35:0] data_temp;
always @(*)
begin
  case (out_cnt)
    1'h1: begin 
            data_temp = buffer;
            end
    default: begin 
            data_temp = 36'b0;
          end
  endcase
end


//assign m_tready = ( (({1'b0,out_cnt} < input_dim) && (m_tready == 1'b1)) || (out_cnt == 4'h0))? 1'b0:1'b1;
assign buffer_full = ( (({1'b0,out_cnt} < 1) ) || (out_cnt == 4'h0))? 1'b0:1'b1;
assign m_tvalid = (out_cnt == 4'h0)? 1'b0:1'b1;

assign m_tdata =(m_tvalid ==1'b1)?sum[28:13]:16'b0;

endmodule
