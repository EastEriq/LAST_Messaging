function report(N,msg)
% report on stdout if verbose is true
    if N.verbose
        fprintf(msg)
    end
end
