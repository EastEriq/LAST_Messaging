function shortflat=jsonTruncate(Msng,M)
% flatten a message converting it to json string, and
% truncate it to fit the output buffer of the messenger,
%  so that it can be transmitted as a single datagram without error
    flat=jsonencode(M);
    if length(flat)>Msng.StreamResource.OutputBufferSize
        Msng.reportError(sprintf(['reply message too long (%d characters), truncating' ...
            ' (perhaps increase OutputBufferSize)'],length(flat)));
        % truncate the json string - this won't be interpreted by the
        % destination listener, which will say 'illegal command received'.
        % A more sophysticated solution could be to replace offending long
        %  fields with shorter labels, such as .Command with a command like
        % 'error('received truncated datagram') which outputs a more specific message
        % at the destination side
        shortflat=flat(1:Msng.StreamResource.OutputBufferSize);
    else
        shortflat=flat;
    end
