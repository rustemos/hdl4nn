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


module layern(
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
    output  [15:0]  m_tdata0,
    output  [15:0]  m_tdata1,
    output  [15:0]  m_tdata2,

    input   [3:0] input_dim
    );


//------weight distribute----//
reg  [20:0]  w_tid_reg;

reg  [2:0]  w_tvalid_cell;
reg  [15:0] w_tdata_cell [0:2];
always @(posedge aclk)
begin
  w_tdata_cell[0] <= w_tdata;
  w_tdata_cell[1] <= w_tdata;
  w_tdata_cell[2] <= w_tdata;
  
  case (w_tid[7:5])
    3'h4: w_tvalid_cell <= 3'b001;
    3'h5: w_tvalid_cell <= 3'b010;
    3'h6: w_tvalid_cell <= 3'b100;
    default: w_tvalid_cell <= 3'b000;
  endcase


  case (w_tid[4:0])
    5'h0: w_tid_reg <= 20'h1;
    5'h1: w_tid_reg <= 20'h2;
    5'h2: w_tid_reg <= 20'h4;
    5'h3: w_tid_reg <= 20'h8;

    5'h4: w_tid_reg <= 20'h10;
    5'h5: w_tid_reg <= 20'h20;
    5'h6: w_tid_reg <= 20'h40;
    5'h7: w_tid_reg <= 20'h80;
    
    5'h8: w_tid_reg <= 20'h100;
    5'h9: w_tid_reg <= 20'h200;
    5'ha: w_tid_reg <= 20'h400;
    5'hb: w_tid_reg <= 20'h800;

    5'hc: w_tid_reg <= 20'h1000;
    5'hd: w_tid_reg <= 20'h2000;
    5'he: w_tid_reg <= 20'h4000;
    5'hf: w_tid_reg <= 20'h8000;
    
    5'h10: w_tid_reg <= 20'h10000;
    5'h11: w_tid_reg <= 20'h20000;
    5'h12: w_tid_reg <= 20'h40000;
    5'h13: w_tid_reg <= 20'h80000;
    default: w_tid_reg <= 20'h0;
  endcase
end
wire [2:0] w_tlast_cell;
assign w_tlast_cell[0] = w_tvalid_cell[0]&(~w_tid[7]);
assign w_tlast_cell[1] = w_tvalid_cell[1]&(~w_tid[7]);
assign w_tlast_cell[2] = w_tvalid_cell[2]&(~w_tid[7]);




localparam  IDLE = 3'b001,
            CACU = 3'b010,
            SETW = 3'b100;
//------------state machine ctrl------------//
reg [2:0] CS,NS;
reg [3:0] counter;
wire temp_tvalid;
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
        if (!w_tvalid_cell == 3'b000) NS = SETW;
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
          if(w_tvalid_cell == 3'b000) counter <= counter;
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
wire [15:0] muladder_b0 [0:20];
wire [35:0] muladder_c0[0:20];
wire [35:0] muladder_p0 [0:20];
wire [15:0] muladder_b1 [0:20];
wire [35:0] muladder_c1[0:20];
wire [35:0] muladder_p1 [0:20];
wire [15:0] muladder_b2 [0:20];
wire [35:0] muladder_c2[0:20];
wire [35:0] muladder_p2 [0:20];
wire [35:0] sum0 ;
wire [35:0] sum1 ;
wire [35:0] sum2 ;

reg s_tvalid_pipe;
wire load_temp;
reg [2:0]load_pipe;
reg [35:0]muladder_p_pipe [0:2];

wire [23:0] din;
assign din = 24'h100000;

assign load_temp = (((input_dim-counter) == 4'h1) && (CS == CACU))? 1'b1:1'b0;



always @(posedge aclk)
begin
  s_tvalid_pipe <= s_tvalid;
  load_pipe[0] <= load_temp;
  load_pipe[1] <= load_pipe[0];
  
 
  
  
  
end

assign muladder_c0[0] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[0]:36'h0;
assign muladder_c0[1] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[1]:36'h0;
assign muladder_c0[2] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[2]:36'h0;
assign muladder_c0[3] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[3]:36'h0;
assign muladder_c0[4] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[4]:36'h0;
assign muladder_c0[5] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[5]:36'h0;
assign muladder_c0[6] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[6]:36'h0;
assign muladder_c0[7] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[7]:36'h0;
assign muladder_c0[8] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[8]:36'h0;
assign muladder_c0[9] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[9]:36'h0;
assign muladder_c0[10] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[10]:36'h0;
assign muladder_c0[11] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[11]:36'h0;
assign muladder_c0[12] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[12]:36'h0;
assign muladder_c0[13] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[13]:36'h0;
assign muladder_c0[14] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[14]:36'h0;
assign muladder_c0[15] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[15]:36'h0;
assign muladder_c0[16] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[16]:36'h0;
assign muladder_c0[17] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[17]:36'h0;
assign muladder_c0[18] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[18]:36'h0;
assign muladder_c0[19] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[19]:36'h0;
//1111

assign muladder_c1[0] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[0]:36'h0;
assign muladder_c1[1] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[1]:36'h0;
assign muladder_c1[2] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[2]:36'h0;
assign muladder_c1[3] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[3]:36'h0;
assign muladder_c1[4] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[4]:36'h0;
assign muladder_c1[5] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[5]:36'h0;
assign muladder_c1[6] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[6]:36'h0;
assign muladder_c1[7] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[7]:36'h0;
assign muladder_c1[8] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[8]:36'h0;
assign muladder_c1[9] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[9]:36'h0;
assign muladder_c1[10] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[10]:36'h0;
assign muladder_c1[11] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[11]:36'h0;
assign muladder_c1[12] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[12]:36'h0;
assign muladder_c1[13] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[13]:36'h0;
assign muladder_c1[14] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[14]:36'h0;
assign muladder_c1[15] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[15]:36'h0;
assign muladder_c1[16] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[16]:36'h0;
assign muladder_c1[17] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[17]:36'h0;
assign muladder_c1[18] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[18]:36'h0;
assign muladder_c1[19] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p1[19]:36'h0;
//2222

assign muladder_c2[0] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[0]:36'h0;
assign muladder_c2[1] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[1]:36'h0;
assign muladder_c2[2] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[2]:36'h0;
assign muladder_c2[3] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[3]:36'h0;
assign muladder_c2[4] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[4]:36'h0;
assign muladder_c2[5] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[5]:36'h0;
assign muladder_c2[6] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[6]:36'h0;
assign muladder_c2[7] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[7]:36'h0;
assign muladder_c2[8] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[8]:36'h0;
assign muladder_c2[9] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[9]:36'h0;
assign muladder_c2[10] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[10]:36'h0;
assign muladder_c2[11] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[11]:36'h0;
assign muladder_c2[12] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[12]:36'h0;
assign muladder_c2[13] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[13]:36'h0;
assign muladder_c2[14] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[14]:36'h0;
assign muladder_c2[15] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[15]:36'h0;
assign muladder_c2[16] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[16]:36'h0;
assign muladder_c2[17] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[17]:36'h0;
assign muladder_c2[18] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[18]:36'h0;
assign muladder_c2[19] = ((counter > 4'h1) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p2[19]:36'h0;
//---------multiply adder instance------//


genvar i;
generate
  
  for (i = 0; i < 20; i = i+1) 
  begin:  layern
my_multi_addere blocks10 (
  .clk(aclk),            // input wire CLK
  .a(s_tdata0),                // input wire [15 : 0] A
  .b(muladder_b0[i]),                // input wire [15 : 0] B
  .c(muladder_c0[i]),                // input wire [35 : 0] C
  .p(muladder_p0[i])               // output wire [35 : 0] P
);

weight_cache weight_cache10 (
  .a(counter),      // input wire [4 : 0] a
  .d(w_tdata_cell[0]),      // input wire [15 : 0] d
  .clk(aclk),  // input wire clk
  .we(w_tid_reg[i]&w_tvalid_cell[0]),    // input wire we
  .spo(muladder_b0[i])  // output wire [15 : 0] spo
);

my_multi_addere blocks11 (
  .clk(aclk),            // input wire CLK
  .a(s_tdata1),                // input wire [15 : 0] A
  .b(muladder_b1[i]),                // input wire [15 : 0] B
  .c(muladder_c1[i]),                // input wire [35 : 0] C
  .p(muladder_p1[i])               // output wire [35 : 0] P
);

weight_cache weight_cache11 (
  .a(counter),      // input wire [4 : 0] a
  .d(w_tdata_cell[1]),      // input wire [15 : 0] d
  .clk(aclk),  // input wire clk
  .we(w_tid_reg[i]&w_tvalid_cell[1]),    // input wire we
  .spo(muladder_b1[i])  // output wire [15 : 0] spo
);

my_multi_addere blocks12 (
  .clk(aclk),            // input wire CLK
  .a(s_tdata2),                // input wire [15 : 0] A
  .b(muladder_b2[i]),                // input wire [15 : 0] B
  .c(muladder_c2[i]),                // input wire [35 : 0] C
  .p(muladder_p2[i])               // output wire [35 : 0] P
);

weight_cache weight_cache12 (
  .a(counter),      // input wire [4 : 0] a
  .d(w_tdata_cell[2]),      // input wire [15 : 0] d
  .clk(aclk),  // input wire clk
  .we(w_tid_reg[i]&w_tvalid_cell[2]),    // input wire we
  .spo(muladder_b2[i])  // output wire [15 : 0] spo
);
end
endgenerate



reg [35:0] buffera0 [0:6],bufferb0[0:6],bufferc0[0:6];

reg [35:0] buffera1 [0:6],bufferb1[0:6],bufferc1[0:6];

reg [35:0] buffera2 [0:6],bufferb2[0:6],bufferc2[0:6];

reg [3:0] out_cnt,in_cnt;
reg loada,loadb,loadc,loadd;

always @ (posedge aclk)
begin
loada <= load_pipe;
loadb<=loada;
loadc<=loadb;

if (load_pipe[1] == 1'b1)
begin
buffera0[0] <= muladder_p0[0];
buffera0[1] <= muladder_p0[1];
buffera0[2] <= muladder_p0[2];
buffera0[3] <= muladder_p0[3];
buffera0[4] <= muladder_p0[4];
buffera0[5] <= muladder_p0[5];
buffera0[6] <= muladder_p0[6];

buffera1[0] <= muladder_p0[7];
buffera1[1] <= muladder_p0[8];
buffera1[2] <= muladder_p0[9];
buffera1[3] <= muladder_p0[10];
buffera1[4] <= muladder_p0[11];
buffera1[5] <= muladder_p0[12];
buffera1[6] <= muladder_p0[13];

buffera2[0] <= muladder_p0[14];
buffera2[1] <= muladder_p0[15];
buffera2[2] <= muladder_p0[16];
buffera2[3] <= muladder_p0[17];
buffera2[4] <= muladder_p0[18];
buffera2[5] <= muladder_p0[19];
buffera2[6] <= din;

bufferb0[0] <= muladder_p1[0];
bufferb0[1] <= muladder_p1[1];
bufferb0[2] <= muladder_p1[2];
bufferb0[3] <= muladder_p1[3];
bufferb0[4] <= muladder_p1[4];
bufferb0[5] <= muladder_p1[5];
bufferb0[6] <= muladder_p1[6];

bufferb1[0] <= muladder_p1[7];
bufferb1[1] <= muladder_p1[8];
bufferb1[2] <= muladder_p1[9];
bufferb1[3] <= muladder_p1[10];
bufferb1[4] <= muladder_p1[11];
bufferb1[5] <= muladder_p1[12];
bufferb1[6] <= muladder_p1[13];

bufferb2[0] <= muladder_p1[14];
bufferb2[1] <= muladder_p1[15];
bufferb2[2] <= muladder_p1[16];
bufferb2[3] <= muladder_p1[17];
bufferb2[4] <= muladder_p1[18];
bufferb2[5] <= muladder_p1[19];
bufferb2[6] <= 1'h0;

bufferc0[0] <= muladder_p2[0];
bufferc0[1] <= muladder_p2[1];
bufferc0[2] <= muladder_p2[2];
bufferc0[3] <= muladder_p2[3];
bufferc0[4] <= muladder_p2[4];
bufferc0[5] <= muladder_p2[5];
bufferc0[6] <= muladder_p2[6];

bufferc1[0] <= muladder_p2[7];
bufferc1[1] <= muladder_p2[8];
bufferc1[2] <= muladder_p2[9];
bufferc1[3] <= muladder_p2[10];
bufferc1[4] <= muladder_p2[11];
bufferc1[5] <= muladder_p2[12];
bufferc1[6] <= muladder_p2[13];

bufferc2[0] <= muladder_p2[14];
bufferc2[1] <= muladder_p2[15];
bufferc2[2] <= muladder_p2[16];
bufferc2[3] <= muladder_p2[17];
bufferc2[4] <= muladder_p2[18];
bufferc2[5] <= muladder_p2[19];
bufferc2[6] <= 1'h0;
end
else
begin
buffera0[0] <= buffera0[0];
buffera0[1] <= buffera0[1];
buffera0[2] <= buffera0[2];
buffera0[3] <= buffera0[3];
buffera0[4] <= buffera0[4];
buffera0[5] <= buffera0[5];
buffera0[6] <= buffera0[6];

buffera1[0] <= buffera1[0];
buffera1[1] <= buffera1[1];
buffera1[2] <= buffera1[2];
buffera1[3] <= buffera1[3];
buffera1[4] <= buffera1[4];
buffera1[5] <= buffera1[5];
buffera1[6] <= buffera1[6];

buffera2[0] <= buffera2[0];
buffera2[1] <= buffera2[1];
buffera2[2] <= buffera2[2];
buffera2[3] <= buffera2[3];
buffera2[4] <= buffera2[4];
buffera2[5] <= buffera2[5];
buffera2[6] <= buffera2[6];

bufferb0[0] <= bufferb0[0];
bufferb0[1] <= bufferb0[1];
bufferb0[2] <= bufferb0[2];
bufferb0[3] <= bufferb0[3];
bufferb0[4] <= bufferb0[4];
bufferb0[5] <= bufferb0[5];
bufferb0[6] <= bufferb0[6];

bufferb1[0] <= bufferb1[0];
bufferb1[1] <= bufferb1[1];
bufferb1[2] <= bufferb1[2];
bufferb1[3] <= bufferb1[3];
bufferb1[4] <= bufferb1[4];
bufferb1[5] <= bufferb1[5];
bufferb1[6] <= bufferb1[6];


bufferb2[0] <= bufferb2[0];
bufferb2[1] <= bufferb2[1];
bufferb2[2] <= bufferb2[2];
bufferb2[3] <= bufferb2[3];
bufferb2[4] <= bufferb2[4];
bufferb2[5] <= bufferb2[5];
bufferb2[6] <= bufferb2[6];

bufferc0[0] <= bufferc0[0];
bufferc0[1] <= bufferc0[1];
bufferc0[2] <= bufferc0[2];
bufferc0[3] <= bufferc0[3];
bufferc0[4] <= bufferc0[4];
bufferc0[5] <= bufferc0[5];
bufferc0[6] <= bufferc0[6];

bufferc1[0] <= bufferc1[0];
bufferc1[1] <= bufferc1[1];
bufferc1[2] <= bufferc1[2];
bufferc1[3] <= bufferc1[3];
bufferc1[4] <= bufferc1[4];
bufferc1[5] <= bufferc1[5];
bufferc1[6] <= bufferc1[6];

bufferc2[0] <= bufferc2[0];
bufferc2[1] <= bufferc2[1];
bufferc2[2] <= bufferc2[2];
bufferc2[3] <= bufferc2[3];
bufferc2[4] <= bufferc2[4];
bufferc2[5] <= bufferc2[5];
bufferc2[6] <= bufferc2[6];


end

end

always @ (posedge aclk or negedge aresetn)
begin
if (aresetn == 1'b0)
in_cnt <= 4'h0;
else if (loada == 1'b1)
in_cnt <= 4'h7;
else if(temp_tvalid == 1'b1)
in_cnt <= in_cnt - 1;
else
in_cnt <= in_cnt;
end



reg [35:0] data00_temp,data01_temp,data02_temp,data10_temp,data11_temp,data12_temp,data20_temp,data21_temp,data22_temp;

always @(*)
begin
  case (in_cnt)
    4'h7: begin 
            data00_temp = buffera0[0];
            data01_temp = bufferb0[0];
            data02_temp = bufferc0[0];
            
            data10_temp = buffera1[0];
            data11_temp = bufferb1[0];
            data12_temp = bufferc1[0];
            
            data20_temp = buffera2[0];
            data21_temp = bufferb2[0];
            data22_temp = bufferc2[0];
          end
    4'h6: begin 
            data00_temp = buffera0[1];
            data01_temp = bufferb0[1];
            data02_temp = bufferc0[1];
            
            data10_temp = buffera1[1];
            data11_temp = bufferb1[1];
            data12_temp = bufferc1[1];
            
            data20_temp = buffera2[1];
            data21_temp = bufferb2[1];
            data22_temp = bufferc2[1];
          end
    4'h5: begin 
            data00_temp = buffera0[2];
            data01_temp = bufferb0[2];
            data02_temp = bufferc0[2];
            
            data10_temp = buffera1[2];
            data11_temp = bufferb1[2];
            data12_temp = bufferc1[2];
            
            data20_temp = buffera2[2];
            data21_temp = bufferb2[2];
            data22_temp = bufferc2[2];
          end
    4'h4: begin 
            data00_temp = buffera0[3];
            data01_temp = bufferb0[3];
            data02_temp = bufferc0[3];
            
            data10_temp = buffera1[3];
            data11_temp = bufferb1[3];
            data12_temp = bufferc1[3];
            
            data20_temp = buffera2[3];
            data21_temp = bufferb2[3];
            data22_temp = bufferc2[3];
          end
    4'h3: begin 
            data00_temp = buffera0[4];
            data01_temp = bufferb0[4];
            data02_temp = bufferc0[4];
            
            data10_temp = buffera1[4];
            data11_temp = bufferb1[4];
            data12_temp = bufferc1[4];
            
            data20_temp = buffera2[4];
            data21_temp = bufferb2[4];
            data22_temp = bufferc2[4];
          end
    4'h2: begin 
            data00_temp = buffera0[5];
            data01_temp = bufferb0[5];
            data02_temp = bufferc0[5];
            
            data10_temp = buffera1[5];
            data11_temp = bufferb1[5];
            data12_temp = bufferc1[5];
            
            data20_temp = buffera2[5];
            data21_temp = bufferb2[5];
            data22_temp = bufferc2[5];
          end
    4'h1: begin 
            data00_temp = buffera0[6];
            data01_temp = bufferb0[6];
            data02_temp = bufferc0[6];
            
            data10_temp = buffera1[6];
            data11_temp = bufferb1[6];
            data12_temp = bufferc1[6];
            
            data20_temp = buffera2[6];
            data21_temp = bufferb2[6];
            data22_temp = bufferc2[6];
          end
    default: begin 
            data00_temp = buffera0[0];
            data01_temp = bufferb0[0];
            data02_temp = bufferc0[0];
            
            data10_temp = buffera1[0];
            data11_temp = bufferb1[0];
            data12_temp = bufferc1[0];
            
            data20_temp = buffera2[0];
            data21_temp = bufferb2[0];
            data22_temp = bufferc2[0];
          end
  endcase
end


always @ (posedge aclk)
begin
  muladder_p_pipe[0] <= data02_temp;
  muladder_p_pipe[1] <= data12_temp;
  muladder_p_pipe[2] <= data22_temp;
end


wire [35:0] temp0_sum,temp1_sum,temp2_sum;
genvar j;
generate

 for (j = 0; j < 1; j = j+1) 
  begin:  layernadd
  
  adder_36 temp0_adder (
  .A(data00_temp),      // input wire [35 : 0] A
  .B(data01_temp),      // input wire [35 : 0] B
  .CLK(aclk),  // input wire CLK
  .CE(1'b1),    // input wire CE
  .S(temp0_sum)      // output wire [35 : 0] S
);

adder_36 final0_adder (
  .A(muladder_p_pipe[0]),      // input wire [35 : 0] A
  .B(temp0_sum),      // input wire [35 : 0] B
  .CLK(aclk),  // input wire CLK
  .CE(1'b1),    // input wire CE
  .S(sum0)      // output wire [35 : 0] S
);

  adder_36 temp1_adder (
  .A(data10_temp),      // input wire [35 : 0] A
  .B(data11_temp),      // input wire [35 : 0] B
  .CLK(aclk),  // input wire CLK
  .CE(1'b1),    // input wire CE
  .S(temp1_sum)      // output wire [35 : 0] S
);

adder_36 final1_adder (
  .A(muladder_p_pipe[1]),      // input wire [35 : 0] A
  .B(temp1_sum),      // input wire [35 : 0] B
  .CLK(aclk),  // input wire CLK
  .CE(1'b1),    // input wire CE
  .S(sum1)      // output wire [35 : 0] S
);

  adder_36 temp2_adder (
  .A(data20_temp),      // input wire [35 : 0] A
  .B(data21_temp),      // input wire [35 : 0] B
  .CLK(aclk),  // input wire CLK
  .CE(1'b1),    // input wire CE
  .S(temp2_sum)      // output wire [35 : 0] S
);

adder_36 final2_adder (
  .A(muladder_p_pipe[2]),      // input wire [35 : 0] A
  .B(temp2_sum),      // input wire [35 : 0] B
  .CLK(aclk),  // input wire CLK
  .CE(1'b1),    // input wire CE
  .S(sum2)      // output wire [35 : 0] S
);

end
endgenerate

always @(posedge aclk or negedge aresetn)
begin
  if (aresetn == 1'b0) 
    out_cnt <= 4'h0;
  else if(loadc == 1'b1)
    out_cnt <= 4'h7;
  else if((m_tvalid == 1'b1) && (buffer_full == 1'b1))
    out_cnt <= out_cnt-1;
  else
    out_cnt <= out_cnt;
end


//--------out put hand shake------//
//assign m_tready = ( (({1'b0,out_cnt} < input_dim) && (m_tready == 1'b1)) || (out_cnt == 4'h0))? 1'b0:1'b1;
assign buffer_full = ( (({1'b0,out_cnt} < 1) ) || (out_cnt == 4'h0))? 1'b0:1'b1;
assign m_tvalid = (out_cnt == 4'h0)? 1'b0:1'b1;
assign temp_tvalid = (in_cnt == 4'h0)? 1'b0:1'b1;
//assign m_tdata0 = data0_temp[23:8];
//assign m_tdata1 = data1_temp[23:8];
//assign m_tdata2 = data2_temp[23:8];
assign m_tdata0 = (sum0[27])? 16'b0:sum0[27:12];
assign m_tdata1 = (sum1[27])? 16'b0:sum1[27:12];
assign m_tdata2 = (sum2[27])? 16'b0:sum2[27:12];
//assign muladder_a = s_tdata;
endmodule
