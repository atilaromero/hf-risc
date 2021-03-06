`ifndef __TESTBENCH_SV
`define __TESTBENCH_SV
`include "random_instruction.sv"
`include "random_program.sv"


`define NUMPROGRS 20

module testbench;

  random_program p;
  string program_code;
  string filename;
  string dirname;
  int f;

  initial begin

    for (int i = 0; i < `NUMPROGRS; i++) begin

      //create a new randomized program
      p = new (100); 
      program_code = p.toString();
      
      //display on screen
      $display("-------------------------------");
      $display(program_code);

      //save to file (note that these files are compiled elsewhere)
      $sformat(filename, "apps/app%05d/app%05d.S", i, i);
      $sformat(dirname,  "apps/app%05d", i);

      $system({"mkdir ", dirname});

      f = $fopen(filename);
      $fwrite(f, "%s", program_code);
      $fclose(f);



    end




  end

endmodule

`endif //__TESTBENCH_SV
