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
    fwrite(Msng.StreamResource,jsonencode(R));
