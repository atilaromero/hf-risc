`ifndef MEMORY_SV
 `define MEMORY_SV

 `include "hfrv_interface.sv"

class memory_model;
   logic [31:0] data[integer];
   logic [31:0] base;
   integer      length;

   function new(string filename, logic [31:0] base, integer length);
      logic [31:0] inst_add, celing, write_data;
      int          code, i, r;
      int          instruction;

      this.base = base;
      this.length = length;

      if(filename != "") begin
         code = $fopen(filename,"r");
         if(code) begin

            inst_add = base;
            celing = base+length;

            while(!$feof(code) && inst_add < celing) begin
               r = $fscanf(code,"%h\n",instruction);
               write_data = read_write(inst_add, instruction, 'hF);
               inst_add = inst_add + 4;
            end
            $fclose(code);
         end // if (code)
      end // if (filename != "")

   endfunction // new

   function logic [31:0] read_write
     (logic [31:0] address,
      logic [31:0] w_data,
      logic [3:0]  we);

      logic [31:0] read_data;
      logic [31:0] offset;
      logic [31:0] mask;

      mask = {{8{we[3]}}, {8{we[2]}}, {8{we[1]}}, {8{we[0]}}};
      offset = address - base;
      offset = {offset[31:2], 2'b00};
      
      if (offset < length) begin
         offset = {2'b00, offset[31:2]};
         
         if (data.exists(offset))
           read_data = data[offset];
         else
           read_data = {32{1'b0}};
         
         if (we != 4'h0)
           data[offset] = (read_data & ~mask) | (w_data & mask);         
         
      end
      else
        read_data = {32{1'bz}};
      
      return read_data;
   endfunction // read_write
   
endclass // memory_model

class memory_driver;
   memory_model memory;
   mailbox gen2mem;
   mailbox mem2mon;
   virtual hfrv_interface.memory iface;
   event   dumpmem;

   function new(virtual hfrv_interface.memory iface,
                mailbox gen2mem,
                mailbox mem2mon,
                event   dumpmem);
      this.iface = iface;
      this.gen2mem = gen2mem;
      this.mem2mon = mem2mon;
      this.dumpmem = dumpmem;
   endfunction; // new

   task run();
      //automatic memory new_memory;
      gen2mem.get(memory);
      fork;
         memory_iface;
         memory_feeder;
         memory_dumper;
      join;
   endtask; // run

   task memory_iface();
      forever @(iface.mem) begin
         logic [31:0] data_read;
         
         data_read = memory.read_write(iface.mem.address,
                                       iface.mem.data_write,
                                       iface.mem.data_we);
         
         if (!(^data_read === 1'bX))
           iface.mem.data_read <= data_read;
      end

   endtask // memory_iface

   task memory_feeder();
      forever
        gen2mem.get(memory);
   endtask; // memory_feeder

   task memory_dumper();
      forever @(dumpmem)
        mem2mon.put(memory);
   endtask // memory_dumper

endclass // memory_driver

`endif
