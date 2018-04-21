function showThisFunctionVariables()
	[ST,I] = dbstack;
    fprintf('=> Entering function <%s> in the script: <%s> at line <%s> ...\n\n', ST(1).name, ST(1).file, ST(1).line)
end
