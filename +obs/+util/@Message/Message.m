classdef Message <handle
    
    properties
        From='';
        ReplyTo='';
        Destination='';
        SentTimestamp=[];
        ReceivedTimestamp=[];
        ProgressiveNumber=-1;
        Command='';
        RequestReply=false;
        Content={};
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
                    %report that the type of the argument is wrong?
                end
            end
        end
        
    end

end