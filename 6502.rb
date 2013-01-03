#!/usr/bin/ruby
 
class CPU6502
  attr_accessor :cpu_instance, :cpus, :imagesize, :debug
  
  def initialize
    debug = 0
    @ip = 0
    @imagesize = 0
    @pc = 0
#    @pc_off = 0x1000
    @pc_off = 0x1000

    @RAM_SIZE = 1024 * 64
    #RAM = Array.new(RAM_SIZE)

    @ram = Array.new(@RAM_SIZE) #was 65536
    @prog = Array.new(@RAM_SIZE) #was 65536

    #@ram = [ ] * 65536*10

    @register = { :A => 0, :X => 0, :Y => 0, :SP => 0xFF, :SR => 0 }    
    @flag = { :S => 0, :V => 0, :B => 0, :D => 0, :I => 0, :Z =>0, :C => 0 } 
    @cpu_instance = 1
    @cpus = @cpus.to_i+1
    @oper1 = 0
    @oper2 = 0

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

  def push(oper1 = @oper1)
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
  
  def set_break(flag)
    @flag[:B] = flag
  end

  def loadimage(filename)
    #@img = Array.new
  ##  @img = File.open(filen, "rb") { |io| io.read }
    #@img = File.open(filen, "rb")

    @img = File.read(filename)
    #RAM_SIZE = 1024 * 64
    #RAM = Array.new(RAM_SIZE)

    @imagesize = @img.bytesize

#    RAM[0x1000, @imagesize] = @prog.bytes.to_a

#    @prog = Array.new(0x1000+@img.size)
    #@prog = [] * (0x1000+@img.size)
    #puts (0x1000+@img.size)
    #@prog[0x1000, (0x1000+@img.size)] = @img
    #puts @prog.size
    #puts @img.size
    #puts "xx"
    #@prog = @prog.to_a + @img.to_a
    #puts @prog.size
 #   @prog = @img
    @prog[0x1000, @imagesize] = @img.bytes.to_a
  end
  
  def brk_implied
    puts "************** IN BREAK **************"
    @pc=+1
    # Push return address onto stack
#    push(@pc >> 8)
   push((@pc >> 8) & 0xff)

    push(@pc & 0xff)
    
    set_break(1)
    
    printf("[brk_implied] SR: %04X\n", @register[:SR])
    push(@register[:SR])
    set_interrupt(1)
    @pc = (@ram[0xFFFE].to_i + (@ram[0xFFFF].to_i<<8))
    printf("[brk_implied] PC = %04X", @pc)
    #@ram[@register[:SP]+0x100] = @register[:A]
    #@register[:SP]-=1 #Not sure about this
    
    Process.exit  
  end
  
  def set_interrupt(flag)
    @flag[:I] = flag
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
    @pc+=1

    if (@flag[:Z] == 0)
      if (oper1 > 0x7F)
        @pc = @pc - (~(oper1) & 0x00FF)
        # printf("next PC=%04X\n",@pc)
      else
        @pc = @pc + (oper1 & 0x00FF)
        display_pc
      end	
    else
      # printf("no match in BNE =-=-=-=-=-=-=-=\n");
      @pc=@pc+1
    end
    # puts("Reached BNE end")
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

  def readmem(pc)
    @prog[pc]
  end
  
  
  $instr = { 0xA2 => { :name => "LDX", :mode => :immediate, :operands => 2, :op => :ldx_immediate }, 
             0x8A => { :name => "TXA", :mode => :implied, :operands => 1, :op => :txa_implied },
             0x20 => { :name => "JSR", :mode => :absolute, :operands => 3, :op => :jsr_absolute },
             0xE8 => { :name => "INX", :mode => :absolute, :operands => 1, :op => :inx_absolute },
             0xE0 => { :name => "CPX", :mode => :immediate, :operands => 2, :op => :cpx_immediate },
             0xD0 => { :name => "BNE", :mode => :immediate, :operands => 2, :op => :bne_relative },
             0xA9 => { :name => "LDA", :mode => :immediate, :operands => 2, :op => :lda_immediate },
             0xAD => { :name => "LDA", :mode => :absolute, :operands => 3, :op => :lda_absolute },
             0x48 => { :name => "PHA", :mode => :implied, :operands => 1, :op => :pha_absolute },
             0x00 => { :name => "BRK", :mode => :implied, :operands => 1, :op => :brk_implied },

           }

  
  def runop(opcode, oper1, oper2, disasm = 0)
    if disasm == 1
      printf("operands: %04X\n", $instr[opcode][:operands])
    end
    case $instr[opcode][:operands]
    when 1
      if disasm == 1
        printf("%04X %s\n", @pc, $instr[opcode][:name])
        @pc+=$instr[opcode][:operands]
      end
    when 2
      @oper1 = readmem(@pc+1)
      if disasm == 1
        printf("%04X %s #%02X\n", @pc, $instr[opcode][:name], @oper1) 
        @pc+=$instr[opcode][:operands]
      end
    when 3
      @oper1 = readmem(@pc+2)
      @oper2 = readmem(@pc+1)
      if disasm == 1
        printf("%04X %s 0x%02X%02X\n", @pc, $instr[opcode][:name], @oper1, @oper2) 
        @pc+=$instr[opcode][:operands]
      end
    end
    
    if disasm == 0
      method($instr[opcode][:op]).call  
    end
  end
  
  def stop
    printf("Stopping CPU...\n")
    Process.exit
  end
  
  def decode
    @pc = @pc_off
    @operand = Array.new(2)
    printf("prog.size: %d\n", @imagesize+@pc_off)
    while (@pc < (@pc_off + @imagesize-1))
      opcode = readmem(@pc)
      @operand[0] = readmem(@pc+2)
      @operand[1] = readmem(@pc+1)
      printf("opcode: %02X  ", opcode)
      runop(opcode, @operand[0], @operand[1], 1)
    end
    debug=1
    display_pc
    debug=0
    @pc = @pc_off
    while (@pc < (@pc_off + @imagesize-1))
      opcode = readmem(@pc)
      @operand[0] = readmem(@pc+2)
      @operand[1] = readmem(@pc+1)
      runop(opcode, @operand[0], @operand[1], 0)
      display_pc
    end
    #debug = 1
    display_pc
    #debug = 0
  end
end

#unless ARGV.length == 1
#  puts "Dude, not the right number of arguments."
#  puts "Usage: ruby 6502.rb binaryfile.img\n"
#  exit
#end

input_file = ARGV[0]
input_file = '/Users/aaron/6502/temp.img'

a = CPU6502.new
puts "Loading file... #{input_file}\n"
a.loadimage(input_file)
printf("File size: %d\n", a.imagesize)
a.debug = 0
a.decode
#a.stop

#mem.each_byte do |ch|
#  putc ch
#end
