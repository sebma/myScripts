%#!/usr/bin/env methlabs

1;
main
function r = byteXOR(a,b)
	r = bitxor( bitand(a,2^8-1), bitand(b,2^8-1) );
end

function showThisFunctionVariables()
	[ST,I] = dbstack;
    fprintf('=> Entering function <%s> in the script: <%s> at line <%s> ...\n\n', ST(1).name, ST(1).file, ST(1).line)
	whos
end

function main()
    fprintf("=> r = %d\n\n", byteXOR(5,7) );
	showThisFunctionVariables
end
