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


module nlayer1(
    input           aclk,
    input           aresetn,

    //------weight in channel-------//
    input   [15:0]  w_tdata,
    input   [7:0]   w_tid,//MSB High Valid


    //----in port----//
    input          s_tvalid,
    output         s_tready,
    input  [15:0]  s_tdata,
    input          s_tlast,
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

reg    w_tvalid_cell;
reg  [15:0] w_tdata_cell;
always @(posedge aclk)
begin
  w_tdata_cell <= w_tdata;

  
  case (w_tid[7:5])
    3'h4: w_tvalid_cell <= 1'b1;
    default: w_tvalid_cell <= 1'b0;
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
//assign s_tready = ((CS == IDLE  || CS == CACU) && (buffer_full == 1'b1))?1'b1:1'b0;
assign s_tready = 1'b1;


// reg [2:0] back_pipe;
// always @(posedge aclk)
// begin
//   back_pipe[0] <= cacu_dealing;
//   back_pipe[1] <= back_pipe[0];
//   back_pipe[2] <= back_pipe[1];
// end
//wire [15:0] muladder_a[0:7];
wire [15:0] muladder_b0 [0:19];
wire [35:0] muladder_c0[0:19];
wire [35:0] muladder_p0 [0:19];
wire [35:0] sum ;

reg s_tvalid_pipe;


reg [35:0] buffera0 [0:6];
reg [35:0] bufferb0 [0:6];
reg [35:0] buffera1 [0:6];
reg [35:0] bufferb1 [0:6];
reg [35:0] buffera2 [0:6];
reg [35:0] bufferb2 [0:6];
reg [3:0] out_cnt;
wire load_temp;
reg loada,loadb;

reg load_pipe;
reg [35:0]muladder_p_pipe [0:1];

wire [23:0] din;

assign load_temp = (((input_dim-counter) == 4'h1) && (CS == CACU))? 1'b1:1'b0;
assign din = 24'h100000;

always @(posedge aclk)
begin

  s_tvalid_pipe <= s_tvalid;
  load_pipe <= load_temp;
  
end

assign muladder_c0[0] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[0]:36'h0;
assign muladder_c0[1] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[1]:36'h0;
assign muladder_c0[2] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[2]:36'h0;
assign muladder_c0[3] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[3]:36'h0;
assign muladder_c0[4] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[4]:36'h0;
assign muladder_c0[5] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[5]:36'h0;
assign muladder_c0[6] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[6]:36'h0;
assign muladder_c0[7] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[7]:36'h0;
assign muladder_c0[8] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[8]:36'h0;
assign muladder_c0[9] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[9]:36'h0;
assign muladder_c0[10] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[10]:36'h0;
assign muladder_c0[11] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[11]:36'h0;
assign muladder_c0[12] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[12]:36'h0;
assign muladder_c0[13] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[13]:36'h0;
assign muladder_c0[14] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[14]:36'h0;
assign muladder_c0[15] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[15]:36'h0;
assign muladder_c0[16] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[16]:36'h0;
assign muladder_c0[17] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[17]:36'h0;
assign muladder_c0[18] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[18]:36'h0;
assign muladder_c0[19] = ((counter > 4'h0) || ((counter == 4'h0) && (s_tvalid_pipe == 1'b1)))? muladder_p0[19]:36'h0;


//---------multiply adder instance------//


genvar i;
generate
  
  for (i = 0; i < 20; i = i+1) 
  begin:  layer1
my_multi_addere blocks00 (
  .clk(aclk),            // input wire CLK
  .a(s_tdata),                // input wire [15 : 0] A
  .b(muladder_b0[i]),                // input wire [15 : 0] B
  .c(muladder_c0[i]),                // input wire [35 : 0] C
  .p(muladder_p0[i])               // output wire [35 : 0] P
);

weight_cache weight_cache00 (
  .a(counter),      // input wire [4 : 0] a
  .d(w_tdata_cell),      // input wire [15 : 0] d
  .clk(aclk),  // input wire clk
  .we(w_tid_reg[i]&w_tvalid_cell),    // input wire we
  .spo(muladder_b0[i])  // output wire [15 : 0] spo
);
end
endgenerate




always @(posedge aclk)
begin

  loada <= load_pipe;
  loadb <= loada;
  if (loada == 1'b1) 
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
    

  end

end

always @(posedge aclk or negedge aresetn)
begin
  if (aresetn == 1'b0) 
    out_cnt <= 4'h0;
  else if(loadb == 1'b1)
    out_cnt <= 4'h7;
  else if((m_tvalid == 1'b1)) //&& (m_tready == 1'b1))
    out_cnt <= out_cnt-1;
  else
    out_cnt <= out_cnt;
end


reg [35:0] data0_temp,data1_temp,data2_temp;
always @(*)
begin
  case (out_cnt)
    4'h7: begin 
            data0_temp = buffera0[0];
            data1_temp = buffera1[0];
            data2_temp = buffera2[0];
          end
    4'h6: begin 
            data0_temp = buffera0[1];
            data1_temp = buffera1[1];
            data2_temp = buffera2[1];
          end
    4'h5: begin 
            data0_temp = buffera0[2];
            data1_temp = buffera1[2];
            data2_temp = buffera2[2];
          end
    4'h4: begin 
            data0_temp = buffera0[3];
            data1_temp = buffera1[3];
            data2_temp = buffera2[3];
          end
    4'h3: begin 
            data0_temp = buffera0[4];
            data1_temp = buffera1[4];
            data2_temp = buffera2[4];
          end
    4'h2: begin 
            data0_temp = buffera0[5];
            data1_temp = buffera1[5];
            data2_temp = buffera2[5];
          end
    4'h1: begin 
            data0_temp = buffera0[6];
            data1_temp = buffera1[6];
            data2_temp = buffera2[6];
          end
    default: begin 
            data0_temp = buffera0[0];
            data1_temp = buffera1[0];
            data2_temp = buffera2[0];
          end
  endcase
end


//--------out put hand shake------//&& (m_tready == 1'b1)
assign buffer_full = ( (({1'b0,out_cnt} < 1) ) || (out_cnt == 4'h0))? 1'b0:1'b1;

assign m_tvalid = (out_cnt == 4'h0)? 1'b0:1'b1;
assign m_tdata0 = (data0_temp[27])? 16'b0:data0_temp[27:12];
assign m_tdata1 = (data1_temp[27])? 16'b0:data1_temp[27:12];
assign m_tdata2 = (data2_temp[27])? 16'b0:data2_temp[27:12];
//assign m_tdata1 = data1_temp[23:8];
//assign m_tdata2 = data2_temp[23:8];
//assign muladder_a = s_tdata;
endmodule
