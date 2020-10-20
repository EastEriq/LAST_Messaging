function report(N,msg)
% report on stdout if Verbose is true
    if N.Verbose
        fprintf(msg)
    end
end
