
`timescale 1ns/1ns

interface interface_cpu_busmux (input bit clock_in);

  //variable declarations
  logic reset, stall, stall_cpu, irq_cpu, irq_ack_cpu, exception_cpu, data_access_cpu;
  logic[31:0] irq_vector_cpu, address_cpu, data_in_cpu, data_out_cpu;
  logic[3:0] data_w_cpu;

endinterface
