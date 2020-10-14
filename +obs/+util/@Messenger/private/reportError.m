function reportError(I,msg)
% report on stdout and set LastError, with the same argument
    I.LastError=msg;
    I.report([msg,'\n'])
end
