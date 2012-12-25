#!/usr/bin/ruby
 
class CPU6502
  attr_accessor :cpu_instance, :cpus, :imagesize, :debug
  
  def initialize
    debug = 0
    @ip = 0
    @imagesize = 0
    @pc = 0
    @pc_off = 0
    @ram = [ ] * 65536
    @register = { :A => 0, :X => 0, :Y => 0, :SP => 0xFF, :SR => 0 }    
    @cpu_instance = 1
    @cpus = @cpus.to_i+1
    @oper1 = 0
    @oper2 = 0
    
    @inst = Array.new
    @inst.push [ 0xA2, :immediate, 2, "LDX", :ldx_i ]
    @inst.push [ 0xA9, :immediate, 2, "LDA", :lda_i ]
    @inst.push [ 0xAD, :absolute, 3, "LDA", :lda_a ]
    @inst.push [ 0xA6, :zeropage, 2, "LDX", :ldx_zp ]
    @inst.push [ 0xB6, :zeropagey, 2, "LDX", :ldx_zpy ]
    @inst.push [ 0xAE, :absolute, 2, "LDX", :ldx_a ]
    @inst.push [ 0xBE, :absolutey, 2, "LDX", :ldx_ay ]
    @inst.push [ 0x8A, :implied, 1, "TXA", :txa_i ]
    @inst.push [ 0x20, :absolute, 3, "JSR", :jsr_a ]
    @inst.push [ 0xE8, :absolute, 1, "INX", :inx_a ]
    @inst.push [ 0xE0, :absolute, 2, "CPX", :cpx_a ]
    @inst.push [ 0xD0, :absolute, 2, "BNE", :bne_a ]
    @inst.push [ 0x00, :absolute, 2, "BRK", :brk_a ]
    @inst.push [ 0x48, :implied, 1, "PHA", :pha_i ] 
    @inst.push [ 0x08, :implied, 1, "PLA", :pha_i ] 
    @inst.push [ 0x00, :implied, 1, "PLP", :plp_i ] 

    @flag = { :S => 0, :V => 0, :B => 0, :D => 0, :I => 0, :Z =>0, :C => 0 } 
  end
  def [](r); @registers[r]; end
  def []=(r,v); @registers[r]=v;   end

  def display_status
    if debug == 1
       printf("\nPC=%04x SP=%04x A=%02x X=%02x Y=%02x S=%02x C=%d Z=%d\n\n", @pc,@register[:SP],@register[:A],@register[:X],@register[:Y],@flag[:S],@flag[:C]?1:0,@flag[:Z])
    end
  end

  def display_pc
    if debug == 1
      printf("\nPC=%04X\n",@pc)
    end
  end

#(memory[0x0100 + S--]= (BYTE))
  def pha_implied
    display_status
    if debug == 1 
      printf("PHA=%02x\n",@register[:A])
    end
    #@ram[@register[:SP]+0x100] = @register[:A]
    #@register[:SP]-=1 #Not sure about this
    push(@register[:A])
    @pc+=1
  end

  def push(oper1=@oper1)
    display_status
    if debug == 1
      printf("PUSH=%02x\n",oper1)
    end
    @ram[@register[:SP]+0x100] = oper1
    @register[:SP]-=1
  end

  def pull
    @register[:SP]+=1
    @ram[@register[:SP]+0x100]
  end

  def set_sign(accumulator)
    @flag[:S] = accumulator & 0x80 #bit 7 of A
  end

  def set_zero(accumulator)    
#    @flag[:Z] = (accumulator==0) ? false:true
    if accumulator == 0 
      @flag[:Z] = 0
    else
      @flag[:Z] = 1
    end
  end

  def set_carry(accumulator)
    @flag[:C] = accumulator
  end

  def loadi(filen)
    @prog = File.open(filen, "rb") { |io| io.read }
    @imagesize = @prog.size
  end

  def dumpops
    #@inst.each do |op| { puts "#{op}" } 

    #printf("op: %X, name: %s\n", @inst[i][0], @inst[i][3]) }
  end

  def disassembleop(opcode, oper1, oper2)
    #case opcode
#    method().call
  end

#   @inst.push [ 0xA2, :immediate, 2, "LDX", :ldx_i ]
#   @inst.push [ 0xA9, :immediate, 2, "LDA", :lda_i ]
#   @inst.push [ 0xAD, :absolute, 3, "LDA", :lda_a ]
#   @inst.push [ 0xA6, :zeropage, 2, "LDX", :ldx_zp ]
#   @inst.push [ 0xB6, :zeropagey, 2, "LDX", :ldx_zpy ]
#   @inst.push [ 0xAE, :absolute, 2, "LDX", :ldx_a ]
#   @inst.push [ 0xBE, :absolutey, 2, "LDX", :ldx_ay ]
#   @inst.push [ 0x8A, :implied, 1, "TXA", :txa_i ]
#   @inst.push [ 0x20, :absolute, 3, "JSR", :jsr_a ]
#   @inst.push [ 0xE8, :absolute, 1, "INX", :inx_a ]
#   @inst.push [ 0xE0, :absolute, 2, "CPX", :cpx_a ]
#   @inst.push [ 0xD0, :absolute, 2, "BNE", :bne_a ]
#   @inst.push [ 0x00, :absolute, 2, "BRK", :brk_a ]
#   @inst.push [ 0x48, :implied, 1, "PHA", :pha_i ] 
#   @inst.push [ 0x08, :implied, 1, "PLA", :pha_i ] 
#   @inst.push [ 0x00, :implied, 1, "PLP", :plp_i ] 
  
  $instr = { 0xA2 => { :name => "LDX" , :mode => :immediate, :operands => 2, :op => :ldx_immediate }, 
             0x8A => { :name => "TXA" , :mode => :implied, :operands => 1, :op => :txa_implied },
             0x20 => { :name => "JSR" , :mode => :absolute, :operands => 3, :op => :jsr_absolute },
             0xE8 => { :name => "INX" , :mode => :absolute, :operands => 1, :op => :inx_absolute },
             0xE0 => { :name => "CPX" , :mode => :immediate, :operands => 2, :op => :cpx_immediate },
             0xD0 => { :name => "BNE" , :mode => :immediate, :operands => 2, :op => :bne_relative },
             0xA9 => { :name => "LDA" , :mode => :immediate, :operands => 2, :op => :lda_immediate },
             0xAD => { :name => "LDA" , :mode => :absolute, :operands => 3, :op => :lda_absolute },
             0x48 => { :name => "PHA" , :mode => :implied, :operands => 1, :op => :pha_absolute },
             0x00 => { :name => "BRK" , :mode => :implied, :operands => 1, :op => :brk_implied },

           }
  
  def brk_implied
    #puts "************** IN BREAK **************"
    @pc+1
    Process.exit  
  end
  
  def ldx_immediate(oper1 = @oper1)
    @register[:X] = oper1
    @pc+=2
    set_sign(@register[:X])
    set_zero(@register[:X])    
  end
  
  def txa_implied
    @register[:A] = @register[:X]
    @pc+=1
  end
    
  def jsr_absolute(oper1 = @oper1, oper2 = @oper2)
    @pc = @pc + 3 - 1 #was +3
    push((@pc >> 8) & 0xff)
    push(@pc & 0xff)
    
    tmp_addr = (oper1 << 8) | oper2
    if tmp_addr == 0xFFEE
      printf("%c", @register[:A]) 
      @pc = tmp_addr
    else
      @pc = tmp_addr
    end
    display_status
    @pc = pull
    @pc |= (pull << 8)
    @pc=@pc+1  
  end

  def inx_absolute
    @register[:X] = (@register[:X]+1) & 0xff
    set_sign(@register[:X])
    set_zero(@register[:X])
    @pc+=1  
  end

  def cpx_immediate(oper1 = @oper1)
    tmp = @register[:X] - oper1
    set_carry(@register[:X] >= oper1) #was < 0x100
    set_sign(tmp)
    #        printf("X=%02X oper1: %02X Z=%d\n", @register[:X], oper1, tmp)
    #	set_zero(tmp & 0xFF)
    if (tmp == 0)
      set_zero(1)
    else
      set_zero(0)
    end
    #        printf("Z=%d\n", @flag[:Z])
    #        set_zero(!tmpx) #was &ff
    @pc+=2
  end

  def bne_relative(oper1 = @oper1)
    display_status
    #	puts "===in BNE==="
    #        puts @flag[:Z]
    @pc+=1

    if (@flag[:Z] == 0)
      if (oper1 > 0x7F)
        @pc = @pc - (~(oper1) & 0x00FF)
    #            printf("next PC=%04X\n",@pc)
      else
        @pc = @pc + (oper1 & 0x00FF)
        display_pc
      end	
    else
    #          printf("no match in BNE =-=-=-=-=-=-=-=\n");
      @pc=@pc+1
    end
    #	puts("Reached BNE end")
    display_pc
  end  
  
  def lda_immediate(oper1 = @oper1)
    set_sign(oper1)
    set_zero(oper1)
    @register[:A] = oper1
    @pc+=2
  end
  
  def lda_absolute(oper1 = @oper1)
    set_sign(oper1)
    set_zero(oper1)
    @register[:A] = oper1
    @pc+=2
  end
  
  def runop(opcode, oper1, oper2)
    @oper1 = oper1
    @oper2 = oper2 
    method($instr[opcode][:op]).call  
  end
  
  def runop_(opcode, oper1, oper2)
    display_status
    case opcode
      when 0xA2 #LDX
        ldx_immediate(oper1)
      when 0x8A #TXA
        txa_implied
      when 0x20 #JSR
        jsr_absolute(oper1, oper2)
      when 0xE8 #INX
        inx_absolute
      when 0xE0 #CPX
        cpx_immediate(oper1)
      when 0xD0 #BNE
        bne_relative(oper1)
      when 0xA9 #LDA
        lda_immediate(oper1)
      when 0xAD #LDA Absolute with Operand
        lda_absolute(oper1)
      when 0x48
        pha_implied(oper1)
      when 00 #BRK
        brk_implied
    end
    display_status
  end

  def readmem(pc)
    @prog[pc]
  end
  
  def stop
    printf("Stopping CPU...\n");
    Process.exit
  end
  
  def decode
    @pc=0
    @operand=Array.new(2)
    while @pc <= (@pc_off + @prog.size)
      #puts "inside decode loop - #{@pc} #{@prog.size}"
      opcode=readmem(@pc)
      @inst.find do |opc,mode,bytes,desc,method| 
      if opc == opcode
        case bytes
          when 2 
            @operand[0] = readmem(@pc+1)
            if debug == 1
              printf("%04X\t%s #%02X\t\t # %02X%02X -- (%d)\n", @pc,desc, @operand[0], opc, @operand[0], bytes)
            end
            if debug == 0
              runop(opcode, @operand[0], @operand[1])
	           else
	            disassembleop(opcode, @operand[0], @operand[1])
            end
            #@pc+=2
          when 1
            printf("%04X\t%s \t\t #%02X -- (%d)\n", @pc,desc, opc, bytes) unless debug == 0
            if debug == 0 
              runop(opcode, @operand[0], @operand[1])
            else
              disassembleop(opcode, @operand[0], @operand[1])
            end
            #@pc+=1
          when 3
            @operand[0] = readmem(@pc+2)
            @operand[1] = readmem(@pc+1)
            if debug == 1
               printf("%04X\t%s $%02X%02X\t\t # %02X%02X%02X -- (%d)\n", @pc,desc, @operand[0], @operand[1], opc, @operand[0],@operand[1], bytes)
            end
            # Run only if debug is off
            if debug == 0
               runop(opcode, @operand[0], @operand[1])
            else 
               disassembleop(opcode, @operand[0], @operand[1])
            end
            #@pc+=3
        end
#        @pc+=bytes
        #puts "..."
      end
    end
    end 
  end
end

#mem = File.open("/home/aaron/temp.img", "rb") { |io| io.read }


#unless ARGV.length == 1
#  puts "Dude, not the right number of arguments."
#  puts "Usage: ruby 6502.rb binaryfile.img\n"
#  exit
#end

#input_file = ARGV[0]
input_file = '/Users/aaron/6502/temp.img'

a = CPU6502.new

#a.dumpops
#exit
puts "Loading file... #{input_file}\n"
a.loadi(input_file)
printf("File size: %d\n", a.imagesize)
a.debug = 0
a.decode
a.stop

#mem.each_byte do |ch|
#  putc ch
#end


