target remote localhost:1234
# set arch i8086
# b *0x7c00
# b *0x8000
# b *0x7c55

display/x $eip
display/x $cs
display/x $esp
display/x $ss

define rk 
    x/20i $cs*16+$eip
end

define kk 
    x/20i $eip
end

define kkk  
    x/30i $arg0
end

set arch i386
symbol-file os.elf
