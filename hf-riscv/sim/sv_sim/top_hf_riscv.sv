
`timescale 1ns/1ns

module top_hf_riscv;

	bit clock_in, boot_enable_n, ram_enable_n, ram_dly;
	bit [31:0] data_read_boot, data_read_ram; 
	bit [3:0] data_w_n_ram;

	interface_cpu_busmux cpu_busmux (clock_in);
	interface_busmux_mem busmux_mem (clock_in);

	always #20 clock_in = ~clock_in;
	
	always@(posedge clock_in)
	begin
		if (cpu_busmux.reset == 1) begin
			ram_dly <= 0;
		end else begin
			ram_dly <= ~ram_enable_n;
		end
	end

	always@(busmux_mem.address or cpu_busmux.stall_cpu or cpu_busmux.reset or boot_enable_n)
	begin
		if ((busmux_mem.address[31:28] == 0 && cpu_busmux.stall_cpu == 0) || cpu_busmux.reset == 1)
			boot_enable_n = 0;
		else	
			boot_enable_n = 1;
	end

	always@(busmux_mem.address or cpu_busmux.stall_cpu or cpu_busmux.reset or ram_enable_n)
	begin
		if ((busmux_mem.address[31:28] == 4 && cpu_busmux.stall_cpu == 0) || cpu_busmux.reset == 1)
			ram_enable_n = 0;
		else
			ram_enable_n = 1;
	end

	always@(busmux_mem.address or ram_dly or busmux_mem.data_read or data_read_boot or data_read_ram)
	begin
		if (busmux_mem.address[31:28] == 0 && ram_dly == 0)
			busmux_mem.data_read = data_read_boot;
		else
			busmux_mem.data_read = data_read_ram;
	end

	assign data_w_n_ram = ~busmux_mem.data_we;

	// HF-RISC core
	datapath core(	
         .clock (cpu_busmux.clock_in),
			.reset (cpu_busmux.reset),
			.stall (cpu_busmux.stall_cpu),
			.irq_vector (cpu_busmux.irq_vector_cpu),
			.irq (cpu_busmux.irq_cpu),
			.irq_ack (cpu_busmux.irq_ack_cpu),
			.exception (cpu_busmux.exception_cpu),
			.address (cpu_busmux.address_cpu),
			.data_in (cpu_busmux.data_in_cpu),
			.data_out (cpu_busmux.data_out_cpu),
			.data_w (cpu_busmux.data_w_cpu),
			.data_access (cpu_busmux.data_access_cpu)
	);

   // Peripherals / busmux logic
   busmux #(
		.log_file("out.txt"),
		.uart_support("no")
	)
	peripherals_busmux(
		.clock (cpu_busmux.clock_in),
		.reset (cpu_busmux.reset),
		.stall (cpu_busmux.stall),
		.stall_cpu (cpu_busmux.stall_cpu),
		.irq_vector_cpu (cpu_busmux.irq_vector_cpu),
		.irq_cpu (cpu_busmux.irq_cpu),
		.irq_ack_cpu (cpu_busmux.irq_ack_cpu),
		.exception_cpu (cpu_busmux.exception_cpu),
		.address_cpu (cpu_busmux.address_cpu),
		.data_in_cpu (cpu_busmux.data_in_cpu),
		.data_out_cpu (cpu_busmux.data_out_cpu),
		.data_w_cpu (cpu_busmux.data_w_cpu),
		.data_access_cpu (cpu_busmux.data_access_cpu),
		
      	.addr_mem (busmux_mem.address),
		.data_read_mem (busmux_mem.data_read),
		.data_write_mem (busmux_mem.data_write),
		.data_we_mem (busmux_mem.data_we),
		.extio_in (8'h00),
		.extio_out (),
		.uart_read (1'b1),
		.uart_write () 
	);

   // Boot ROM
   boot_ram #(	
      .memory_file ("boot.txt"),
	  .data_width (8),
	  .address_width (12),
	  .bank (0)
   )
   boot0lb(
		.clk (clock_in),
		.addr (busmux_mem.address[11:2]),
		.cs_n (boot_enable_n),
		.we_n	(1'b1),
		.data_i (8'h00),
		.data_o (data_read_boot[7:0])
	);
   
   boot_ram #(	
      .memory_file ("boot.txt"),
	  .data_width (8),
	  .address_width (12),
	  .bank (1)
   )
   boot0ub(
		.clk (clock_in),
		.addr (busmux_mem.address[11:2]),
		.cs_n (boot_enable_n),
		.we_n	(1'b1),
		.data_i (8'h00),
		.data_o (data_read_boot[15:8])
	);
		
   boot_ram #(	
      .memory_file ("boot.txt"),
	  .data_width (8),
	  .address_width (12),
	  .bank (2)
   )
   boot1lb(
		.clk (clock_in),
		.addr (busmux_mem.address[11:2]),
		.cs_n (boot_enable_n),
		.we_n	(1'b1),
		.data_i (8'h00),
		.data_o (data_read_boot[23:16])
	);
		
      
   boot_ram #(	
      .memory_file ("boot.txt"),
		.data_width (8),
		.address_width (12),
		.bank (3)
   )
   boot1ub(
		.clk (clock_in),
		.addr (busmux_mem.address[11:2]),
		.cs_n (boot_enable_n),
		.we_n	(1'b1),
		.data_i (8'h00),
		.data_o (data_read_boot[31:24])
	);

    // RAM
	bram #(	
	   .memory_file ("code.txt"),
	   .data_width (8),
	   .address_width (16),
	   .bank (0)
	)
	memory0lb(
	   .clk 	(clock_in),
	   .addr (busmux_mem.address[15:2]),
	   .cs_n (ram_enable_n),
	   .we_n	(data_w_n_ram[0]),
	   .data_i (busmux_mem.data_write[7:0]),
	   .data_o	(data_read_ram[7:0])
	);

	bram #(	
	   .memory_file ("code.txt"),
	   .data_width (8),
	   .address_width (16),
	   .bank (1)
	)
	memory0ub(
	   .clk 	(clock_in),
	   .addr (busmux_mem.address[15:2]),
	   .cs_n (ram_enable_n),
	   .we_n	(data_w_n_ram[1]),
	   .data_i (busmux_mem.data_write[15:8]),
	   .data_o	(data_read_ram[15:8])
	);

	bram #(	
	   .memory_file ("code.txt"),
	   .data_width (8),
	   .address_width (16),
	   .bank (2)
	)
	memory1lb(
	   .clk 	(clock_in),
	   .addr (busmux_mem.address[15:2]),
	   .cs_n (ram_enable_n),
	   .we_n	(data_w_n_ram[2]),
	   .data_i (busmux_mem.data_write[23:16]),
	   .data_o	(data_read_ram[23:16])
	);

	bram #(	
	   .memory_file ("code.txt"),
	   .data_width (8),
	   .address_width (16),
	   .bank (3)
	)
	memory1ub(
	   .clk 	(clock_in),
	   .addr (busmux_mem.address[15:2]),
	   .cs_n (ram_enable_n),
	   .we_n	(data_w_n_ram[3]),
	   .data_i (busmux_mem.data_write[31:24]),
	   .data_o	(data_read_ram[31:24])
	);	

	// Test process
	test_hf_riscv test (cpu_busmux, busmux_mem);

endmodule : top_hf_riscv
