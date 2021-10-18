function shortflat=jsonTruncate(Msng,M)
% flatten a message converting it to json string, and
% truncate it to fit the output buffer of the messenger,
%  so that it can be transmitted as a single datagram without error
    flat=jsonencode(M,'ConvertInfAndNaN',false);
    if length(flat)>Msng.StreamResource.OutputBufferSize
        Msng.reportError(['reply message too long (%d characters), truncating' ...
            ' (perhaps increase OutputBufferSize)'],length(flat));
        % shorten the json string, by nulling .Command and assigning a
        %  short string to .Content - not an universal solution (e.g.
        %  doesn't shorten unreasonably long names) but reasonable for the
        %  time being
        M.Command='';
        M.Content=jsonencode('truncated...');
        shortflat=jsonencode(M);
    else
        shortflat=flat;
    end
