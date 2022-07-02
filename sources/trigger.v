`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/26 20:35:50
// Design Name: 
// Module Name: mlp_stcf
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


module mlp_stcf(
    input           aclk,
    input           aresetn,

    //------weight in channel-------//
    input   [31:0]  w_tdata,
    //input   [7:0]   w_tid,//MSB High Valid

    //------input activation------//

    input           s_tvalid,
    output          s_tready,
    input   [15:0]  s_tdata,
    input           s_tlast,

    //-----reg set---------//
    input [15:0] set_in,
    input set_en,
    output [15:0] set_out,

    //---out port---//
    output        m_tvalid,
    input         m_tready,
    output  [15:0]  m_tdata

    );

//-------reg set-------//
reg [15:0] set;
always @(posedge aclk or negedge aresetn)
begin
  if (aresetn == 1'b0)
    set <= 16'h0;
  else if(set_en)
    set <= set_in;
  else
    set <= set;
end
assign set_out = set;


//--------weight set--------//
reg [7:0]   lw_tid [0:3];
reg [15:0]  lw_tdata [0:3];

always @(posedge aclk)
begin
  lw_tid[0] <= {w_tdata[24]&set[1],w_tdata[22:16]};
  lw_tid[1] <= {w_tdata[25]&set[1],w_tdata[22:16]};
  lw_tid[2] <= {w_tdata[26]&set[1],w_tdata[22:16]};
  lw_tid[3] <= {w_tdata[27]&set[1],w_tdata[22:16]};
  
  lw_tdata[0] <= w_tdata[15:0];
  lw_tdata[1] <= w_tdata[15:0];
  lw_tdata[2] <= w_tdata[15:0];
  lw_tdata[3] <= w_tdata[15:0];
  
end

wire valid_12,ready_12;
wire valid_23,ready_23;
wire valid_3o;
wire ready_3o;
wire [15:0] data_12 [0:2];
wire [15:0] data_23 [0:2];
wire [15:0] data_3o [0:2];

nlayer1 layer1(

  //------activation in channel-------//
    .aclk(aclk),
    .aresetn(aresetn),
    .s_tvalid(s_tvalid),
    .s_tready(s_tready),
    .s_tdata(s_tdata),
    .s_tlast(s_tlast),
    //------weight in channel-------//
    .w_tdata(lw_tdata[0]),
    .w_tid(lw_tid[0]),//MSB High Valid

    .m_tvalid(valid_12),
    .m_tready(ready_12),
    .m_tdata0(data_12[0]),
    .m_tdata1(data_12[1]),
    .m_tdata2(data_12[2]),
    .input_dim(4'h4)
    );


layern layer2(
    .aclk(aclk),
    .aresetn(aresetn),

    //------weight in channel-------//
    .w_tdata(lw_tdata[1]),
    .w_tid(lw_tid[1]),//MSB High Valid


    //----in port----//
    .s_tvalid(valid_12),
    .s_tready(ready_12),
    .s_tdata0(data_12[0]),
    .s_tdata1(data_12[1]),
    .s_tdata2(data_12[2]),

    //---out port---//
    .m_tvalid(valid_23),
    .m_tready(ready_23),
    .m_tdata0(data_23[0]),
    .m_tdata1(data_23[1]),
    .m_tdata2(data_23[2]),
    .input_dim(4'h7)    
    );

layern layer3(
    .aclk(aclk),
    .aresetn(aresetn),

    //------weight in channel-------//
    .w_tdata(lw_tdata[2]),
    .w_tid(lw_tid[2]),//MSB High Valid


    //----in port----//
    .s_tvalid(valid_23),
    .s_tready(ready_23),
    .s_tdata0(data_23[0]),
    .s_tdata1(data_23[1]),
    .s_tdata2(data_23[2]),

    //---out port---//
    .m_tvalid(valid_3o),
    .m_tready(ready_3o),
    .m_tdata0(data_3o[0]),
    .m_tdata1(data_3o[1]),
    .m_tdata2(data_3o[2]),
    .input_dim(4'h7)    
    );

outlayer  outlayer(
    .aclk(aclk),
    .aresetn(aresetn),

    //------weight in channel-------//
    .w_tdata(lw_tdata[3]),
    .w_tid(lw_tid[3]),//MSB High Valid


    //----in port----//
    .s_tvalid(valid_3o),
    .s_tready(ready_3o),
    .s_tdata0(data_3o[0]),
    .s_tdata1(data_3o[1]),
    .s_tdata2(data_3o[2]),

    //---out port---//
    .m_tvalid(m_tvalid),
    .m_tready(m_tready),
    .m_tdata(m_tdata),
    //.m_tlast(intf.m_tlast),

    //------parameters-------------//
    
    .input_dim(4'h7)
    );
endmodule
