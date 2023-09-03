function reply(Msng,content,evalInListener)
% helper method for replying to messages with either output from a command,
%  or errors for illegal commands, or acknowledgements to AreYouThere
    if ~exist('evalInListener','var')
        evalInListener=false;
    end

    R=obs.util.Message;
    R.From.Host=Msng.localHostName;
    R.From.Port=Msng.LocalPort;
    R.SentTimestamp=now;
    R.RequestReply=false;
    R.Content=content;
    R.EvalInListener=evalInListener;
    Msng.MessagesSent=Msng.MessagesSent+1;
    R.ProgressiveNumber=Msng.MessagesSent;

    % flatten it and dispatch it
    flat=jsonTruncate(Msng,R);
    fwrite(Msng.StreamResource,flat);
