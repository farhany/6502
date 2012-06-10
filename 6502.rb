#!/usr/bin/ruby
 
class CPU6502
  attr_accessor :cpu_instance, :cpus, :imagesize
  
  def initialize
    @ip = 0
    @imagesize = 0
    @pc = 0
    @pc_off = 0
    @ram = [ ] * 65536
    @register = { :A => 0, :X => 0, :Y => 0, :SP => 0xFF, :SR => 0 }    
    @cpu_instance = 1
    @cpus = @cpus.to_i+1
    @inst = Array.new
    @inst.push [ 0xA2, :immediate, 2, "LDX" ]
    @inst.push [ 0xA9, :immediate, 2, "LDA" ]
    @inst.push [ 0xA6, :zeropage, 2, "LDX" ]
    @inst.push [ 0xB6, :zeropagey, 2, "LDX" ]
    @inst.push [ 0xAE, :absolute, 2, "LDX" ]
    @inst.push [ 0xBE, :absolutey, 2, "LDX" ]
    @inst.push [ 0x8A, :implied, 1, "TXA" ]
    @inst.push [ 0x20, :absolute, 3, "JSR" ]
    @inst.push [ 0xE8, :absolute, 1, "INX" ]
    @inst.push [ 0xE0, :absolute, 2, "CPX" ]
    @inst.push [ 0xD0, :absolute, 2, "BNE" ]
    @inst.push [ 0x00, :absolute, 2, "BRK" ]
    @flag = { :S => 0, :V => 0, :B => 0, :D => 0, :I => 0, :Z =>0, :C => 0 } 
  end
  def [](r); @registers[r]; end
  def []=(r,v); @registers[r]=v;   end

  def display_status
    #printf("PC=%04x SP=%04x A=%02x X=%02x Y=%02x S=%02x C=%d Z=%d\n\n", @pc,@register[:SP],@register[:A],@register[:X],@register[:Y],@flag[:S],@flag[:C]?1:0,@flag[:Z])
  end

  def push(oper1)
    #display_status
    #printf("pushing: %02x\n",oper1)
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
    #printf("accpassed to set-zero: %d\n",accumulator)
    
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

  def runop(opcode, oper1, oper2)
#    display_status
    case opcode
      when 0xA2 #LDX
        @register[:X] = oper1
        @pc+=2
        set_sign(@register[:X])
        set_zero(@register[:X])
      when 0x8A #TXA
        @register[:A] = @register[:X]
        @pc+=1
      when 0x20 #JSR
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
#	printf("compl...\n")
      when 0xE8 #INX
        @register[:X] = (@register[:X]+1) & 0xff
        set_sign(@register[:X])
        set_zero(@register[:X])
        @pc+=1  
      when 0xE0 #CPX
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
      when 0xD0 #BNE
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
#            printf("next PC=%04X\n",@pc)
          end	
#          display_status
        else
#          printf("no match in BNE =-=-=-=-=-=-=-=\n");
        @pc=@pc+1

	end
#	puts("Reached BNE end")
#        printf("next PC=%04X\n",@pc)
      when 0xA9 #LDA
#	puts "I AM IN LDA!!!!!!!!!"
        set_sign(oper1)
        set_zero(oper1)
        @register[:A] = oper1
        @pc+=2
 #           printf("next PC=%04X\n",@pc)
      when 00 #BRK
        #puts "************** IN BREAK **************"
        @pc+1
        Process.exit
    end
    display_status
  end

  def readmem(pc)
    @prog[pc]
  end

  def decode
    @pc=0
    @operand=Array.new(2)
    while @pc <= (@pc_off + @prog.size)
      #puts "inside decode loop - #{@pc} #{@prog.size}"
      opcode=readmem(@pc)
      @inst.find do |opc,mode,bytes,desc| 
      if opc == opcode
        case bytes
          when 2 
            @operand[0] = readmem(@pc+1)
#            printf("%04X\t%s #%02X\t\t # %02X%02X -- (%d)\n", @pc,desc, @operand[0], opc, @operand[0], bytes)
            runop(opcode, @operand[0], @operand[1])
            #@pc+=2
          when 1
#            printf("%04X\t%s \t\t #%02X -- (%d)\n", @pc,desc, opc, bytes)
            runop(opcode, @operand[0], @operand[1])
            #@pc+=1
          when 3
            @operand[0] = readmem(@pc+2)
            @operand[1] = readmem(@pc+1)
#            printf("%04X\t%s $%02X%02X\t\t # %02X%02X%02X -- (%d)\n", @pc,desc, @operand[0], @operand[1], opc, @operand[0],@operand[1], bytes)
            runop(opcode, @operand[0], @operand[1])
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

a = CPU6502.new
#a.loadi("/home/aaron/temp.img")
a.loadi("temp.img")
a.decode

printf("File size: %d\n", a.imagesize)
#mem.each_byte do |ch|
#  putc ch
#end


