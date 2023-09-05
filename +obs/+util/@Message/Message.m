classdef Message <handle
    
    properties
        ReplyTo=struct('Host','','Port',[]);
        SentTimestamp=[]; % time at which the message is sent, filled by the sending Messenger
        ReceivedTimestamp=[]; % time at which the message is received, filled by the listeniner
        ProgressiveNumber=[]; % ordinal number, set by the sending Messenger
        Command='';
        RequestReply=false;
        Content={};
        EvalInListener=false; % use true for the special case of retreiving properties of the receiving Messenger
    end
    
    methods
        
        function Msg=Message(command)
            % Creator with optional argument. The argument string may be a simple
            %  command or a structure which maps to all fields of the
            %  Message. The second case is useful for casting back
            %  json-flattened transmitted messages to Message objects
            if exist('command','var')
                if ischar(command)
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
                    Msg.Content='Error: can''t convert argument into command';
                    %report that the type of the argument is wrong?
                end
            end
        end
        
    end

end