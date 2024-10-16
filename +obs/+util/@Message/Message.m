classdef Message < handle
    
    properties
        ReplyTo=struct('Host','','Port',[]);
        SentTimestamp=[]; % time at which the message is sent, filled by the sending Messenger
        ReceivedTimestamp=[]; % time at which the message is received, filled by the listeniner
        ProgressiveNumber=[]; % ordinal number, set by the sending Messenger
        Command=''; % matlab command to be executed on reception of the message
        RequestReplyWithin=-1; % seconds from SentTimestamp within which to send back a result
        Content={}; % result of the command, or other free textual payload
        EvalInListener=false; % use true for the special case of retreiving properties of the receiving Messenger
    end
    
    methods
        
        function Msg=Message(command)
            % Creator with optional argument. The argument string may be a simple
            %  command or a structure which maps to all fields of the
            %  Message. The second case is useful for casting back
            %  json-flattened transmitted messages to Message objects
            % Msg.ReplyTo.Host=obs.util.localHostIP;
            % beware - .localHostIP reads stdout, and could be confused
            %  by adiacent system() command
            if exist('command','var')
                if ischar(command) || isstring(command)
                    try
                        m=jsondecode(command);
                        ff=fieldnames(m);
                        for i=1:length(ff)
                            Msg.(ff{i})=m.(ff{i});
                        end
                    catch
                        Msg.Command=command;
                    end
                else
                    Msg.Content=sprintf('can''t convert argument of type "%s" into message',...
                        class(command));
                    %report that the type of the argument is wrong?
                end
            end
        end
        
    end

end