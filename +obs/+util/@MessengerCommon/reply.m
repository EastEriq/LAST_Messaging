function reply(Msng,content,nid)
% helper method for replying to messages with either output from a command,
%  or errors for illegal commands, or acknowledgements to AreYouThere
    R=obs.util.Message;
    R.SentTimestamp=now;
    R.RequestReply=false;
    R.Content=content;
    Msng.MessagesSent=Msng.MessagesSent+1;
    % if provided, fill the number of the original request, to help sorting
    %  out at reception, if the receiver has such a mechanism
    if exist('nid','var')
        R.ProgressiveNumber=nid;
    else
        R.ProgressiveNumber=Msng.MessagesSent;
    end

    % flatten it and dispatch it
    flat=jsonTruncate(Msng,R);
    try
        % I've seen this failing on startup of a blind slave, which is
        %  already interrogated by a monitor - maybe because the
        %  Streamresource is not yet set?
        % ???? access once to avoid that Msng.DestinationHost becomes
        %  '{obs.util.Listener}' if running in a headless slave ???
        Msng.StreamResource.RemoteHost=R.ReplyTo.Host;
        fwrite(Msng.StreamResource,flat);
    catch
        Msng.reportError('cannot write to .StreamResource [%s,%d]',...
            Msng.StreamResource.RemoteHost,Msng.StreamResource.RemotePort)
    end