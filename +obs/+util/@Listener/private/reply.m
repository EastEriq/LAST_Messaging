function reply(Msng,content)
% helper method for replying to messages with either output from a command,
%  or errors for illegal commands, or acknowledgements to AreYouThere
    R=obs.util.Message;
    localhostname=char(java.net.InetAddress.getLocalHost.getHostName);
    R.From=sprintf('%s:%d',localhostname,Msng.LocalPort);
    R.SentTimestamp=now;
    R.RequestReply=false;
    R.Content=content;
    Msng.MessagesSent=Msng.MessagesSent+1;
    R.ProgressiveNumber=Msng.MessagesSent;

    % flatten it and dispatch it
    flat=jsonTruncate(Msng,R);
    fwrite(Msng.StreamResource,flat);
