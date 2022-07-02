`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/27 16:58:22
// Design Name: 
// Module Name: sim_network
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
interface mlp_if (input aclk);
  logic [15:0] s_tdata;
  logic [31:0] w_tdata;
  logic [15:0] set_in;
  logic [15:0] m_tdata;
  logic [15:0] set_out;

  logic s_tvalid;
  logic s_tready;
  logic set_en;
  logic s_tlast;

  logic m_tvalid;
  logic m_tready;
  logic m_tlast;
  
  
  clocking drv_ck @(posedge aclk);
    default input #0.5ns output #0.5ns;
    output s_tdata, w_tdata, set_en,  s_tvalid,m_tready,set_in, s_tlast;
    input s_tready,m_tvalid,m_tdata,set_out;
  endclocking
  // clocking DUT @(posedge clk);
  //   default input #1ns output #1ns;
  //   input data_A, data_B, data_C;
  //   //output data_P;
  // endclocking
endinterface

module sim_mlp (mlp_if intf);
        
task print_result();
  shortint resut_nn;
    wait(intf.drv_ck.m_tvalid == 1'b1)
      begin
        resut_nn = intf.m_tdata;
        $display("%d \n", resut_nn);
      end
 endtask    
        
task automatic set_idle();
    @(posedge intf.aclk);
    intf.drv_ck.s_tdata <= 16'h0;
    intf.drv_ck.s_tvalid <= 1'b0;
    intf.drv_ck.set_in <= 16'h0;
    intf.drv_ck.set_en <= 1'b0;

    intf.drv_ck.w_tdata <=  32'h0;
  endtask //automatic

task automatic set_reg(input int reg_value);
    @(posedge intf.aclk);
    intf.drv_ck.set_in <= reg_value[15:0];
    intf.drv_ck.set_en <= 1'b1;
  endtask //automatic

  task automatic sent_weight(input int weight_id,input int weight_value);
    @(posedge intf.aclk);
    intf.drv_ck.w_tdata <= {weight_id[15:0],weight_value[15:0]};

  endtask //automatic

  task automatic sent_pack(input int act,input int last);
    @(posedge intf.aclk);
    intf.drv_ck.s_tdata <= act[15:0];
    intf.drv_ck.s_tvalid <= 1'b1;

    intf.drv_ck.s_tlast <=  last[0];
  endtask //automatic

endmodule

module tb_network;

bit aclk;
logic aresetn;

mlp_if intf(.*);
sim_mlp sim_mlp(intf);
int n,j,k,m;
  integer weight_in4,weight_in3,weight_in2,weight_in1,activation_in;
  integer fid_in4,fid_in3,fid_in2,fid_in1,fid_in,num_out;

initial begin 
    fid_in4 = $fopen("D:/xilinx/Vivado/design_flow/muon_trigger2/fc4weightbias.txt","r");
    fid_in3 = $fopen("D:/xilinx/Vivado/design_flow/muon_trigger2/fc3weightbias.txt","r");
    fid_in2 = $fopen("D:/xilinx/Vivado/design_flow/muon_trigger2/fc2weightbias.txt","r");
    fid_in1 = $fopen("D:/xilinx/Vivado/design_flow/muon_trigger2/fc1weightbias.txt","r");
    fid_in = $fopen("D:/xilinx/Vivado/design_flow/muon_trigger2/activation.txt","r");
    num_out = $fopen("D:/xilinx/Vivado/design_flow/muon_trigger2/txt_out.txt","w");
  forever begin
    #1.5625 aclk = !aclk;
  end
end

initial begin 
  #15.6 aresetn <= 0;
  repeat(5) @(posedge aclk);
  sim_mlp.set_idle;
  repeat(10) @(posedge aclk);
  aresetn <= 1;

  sim_mlp.set_idle;
  repeat(5) @(posedge aclk);
  sim_mlp.set_reg(2);
  sim_mlp.set_idle;
  repeat(2) @(posedge aclk);


  for (j = 0; j<1; j=j+1) 
  begin
    for (k = 0; k<20; k=k+1) 
    begin
      for (n = 0; n<4; n=n+1) 
      begin
        $fscanf(fid_in1,"%d",weight_in1);
          m =weight_in1;
        sim_mlp.sent_weight(256+j*32+k,m);
      end
      sim_mlp.set_idle;
    end  
  end

  for (j = 0; j<3; j=j+1) 
  begin
    for (k = 0; k<20; k=k+1) 
    begin
      for (n = 0; n<7; n=n+1) 
      begin
        $fscanf(fid_in2,"%d",weight_in2);
          m =weight_in2;
        sim_mlp.sent_weight((256<<1)+j*32+k,m);
      end
      sim_mlp.set_idle;
    end  
  end


  for (j = 0; j<3; j=j+1) 
  begin
    for (k = 0; k<20; k=k+1) 
    begin
      for (n = 0; n<7; n=n+1) 
      begin
        $fscanf(fid_in3,"%d",weight_in3);
          m =weight_in3;
        sim_mlp.sent_weight((256<<2)+j*32+k,m);
      end
      sim_mlp.set_idle;
    end  
  end

  for (j = 0; j<1; j=j+1) 
  begin
    for (k = 0; k<3; k=k+1) 
    begin
      for (n = 0; n<7; n=n+1) 
      begin
        $fscanf(fid_in4,"%d",weight_in4);
          m =weight_in4;
        sim_mlp.sent_weight((256<<3)+j*32+k,m);
      end
      sim_mlp.set_idle;
    end  
  end


  //-----sent input-----//
  repeat(20) @(posedge aclk);
  sim_mlp.set_reg(1);
  sim_mlp.set_idle;
  intf.m_tready = 1'b1;
  repeat(50) @(posedge aclk);


for (j = 0; j<199223; j=j+1)
      begin 
  repeat(20) @(posedge aclk);
  wait ( intf.s_tready == 1'b1);
  for ( n = 1; n<4; n=n+1) 
  begin
  $fscanf(fid_in,"%d",activation_in);
            m =activation_in;
   sim_mlp.sent_pack(m, 0);
  end
  sim_mlp.sent_pack(256, 1);
  sim_mlp.set_idle;
  fork
            shortint resut_nn;
                wait(intf.drv_ck.m_tvalid == 1'b1)
                    begin
                        resut_nn = intf.m_tdata;
                        $fwrite(num_out,"%d \n", resut_nn);
                    end
           sim_mlp.print_result;
        join
  end
  end



mlp_stcf  mlp_stcf(
    .aclk(aclk),
    .aresetn(aresetn),

    //------weight in channel-------//
    .w_tdata(intf.w_tdata),
    //.w_tid(intf.w_tid),


    //----in port----//
    .s_tvalid(intf.s_tvalid),
    .s_tready(intf.s_tready),
    .s_tdata(intf.s_tdata),
    .s_tlast(intf.s_tlast),

    //------ module set------//
    .set_in(intf.set_in),
    .set_en(intf.set_en),
    .set_out(intf.set_out),


    //---out port---//
    .m_tvalid(intf.m_tvalid),
    .m_tready(intf.m_tready),
    .m_tdata(intf.m_tdata)
    //.m_tlast(intf.m_tlast),

    );
endmodule
