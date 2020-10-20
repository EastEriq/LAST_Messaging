function reply(Msng,content)
% helper method for replying to messages with either output from a command,
%  or errors for illegal commands, or acknowledgements to AreYouThere
    R=obs.util.Message;
    R.From=Msng.Name;
    R.SentTimestamp=now;
    R.RequestReply=false;
    R.Content=content;
    Msng.MessagesSent=Msng.MessagesSent+1;
    R.ProgressiveNumber=Msng.MessagesSent;

    % flatten it and dispatch it
    flat=jsonencode(R);
    if length(flat)>Msng.StreamResource.OutputBufferSize
        Msng.reportError(sprintf(['reply message too long (%d characters), truncating' ...
            ' (perhaps increase OutputBufferSize)'],length(flat)));
        % truncate the json string - this won't be interpreted by the
        % destination listener, which will say 'illegal command received'.
        % A more sophysticated solution could be to send a command like
        % 'error('received truncated datagram') which outputs a more specific message
        flat=flat(1:Msng.StreamResource.OutputBufferSize);
    end
    fwrite(Msng.StreamResource,flat);
