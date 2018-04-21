% Source : https://github.com/tellezhector/cryptography/blob/master/aes/aesinit.m
function S_box = S_box_gen()
	% irreducible polynomial for multiplication in a finite field 0x11b
	% bin2dec('100011011');
	S_box.mod_pol = 283;

	% first build logarithm lookup table and it's inverse
	aes_logt = zeros(1,256);
	aes_ilogt = zeros(1,256);
	gen = 1;
	for i = 0:255
	    aes_logt(gen + 1) = i;
	    gen = poly_mult(gen, 3, S_box.mod_pol);
	end
	aes_ilogt(aes_logt + 1) = (0:255);
	aes_ilogt(1) = 1; %car non traite par la transformation precedente
	% store log tables
	S_box.aes_logt = aes_logt;
	S_box.aes_ilogt = aes_ilogt;
	% build s-box and it's inverse
	s_box = zeros(1,256);
	loctable = [1 2 4 8 16 32 64 128 1 2 4 8 16 32 64 128];
	for i = 0:255
	    if (i == 0)
	        inv = 0;
	    else
	        inv = aes_ilogt(255 - aes_logt(i + 1) + 1);
	    end
	    temp = 0;
	    for bi = 0:7
	        temp2 = sign(bitand(inv, loctable(bi + 1)));
	        temp2 = temp2 + sign(bitand(inv, loctable(bi + 4 + 1)));
	        temp2 = temp2 + sign(bitand(inv, loctable(bi + 5 + 1)));
	        temp2 = temp2 + sign(bitand(inv, loctable(bi + 6 + 1)));
	        temp2 = temp2 + sign(bitand(inv, loctable(bi + 7 + 1)));
	        temp2 = temp2 + sign(bitand(99, loctable(bi + 1)));
	        if (rem(temp2,2))
	            temp = bitor(temp, loctable(bi + 1));
	        end
	    end
	    s_box(i + 1) = temp;
	end

	inv_s_box(s_box + 1) = (0:255);

	S_box.s_box = s_box;
	S_box.inv_s_box = inv_s_box;
end

function p = poly_mult(a, b, mod_pol)
	% Multiplication in a finite field
	% For loop multiplication - slower than log/ilog tables
	% but must be used for log/ilog tables generation
	
	p = 0;
	for counter = 1 : 8
	    if (rem(b, 2))
	        p = bitxor(p, a);
	        b = (b - 1)/2;
	    else
	        b = b/2;
	    end
	    a = 2*a;
	    if (a > 255)
	        a = bitxor(a, mod_pol);
	    end
	end
end
