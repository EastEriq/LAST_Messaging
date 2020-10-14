classdef Message <handle
    
    properties
        From='';
        ReplyTo='';
        Destination='';
        Timestamp=[];
        ProgressiveNumber=-1;
        Command='';
        RequestReply=false;
        Content={};
    end
    
    methods
        function Msg=Message(command,content)
            % creator with optional arguments Command and Content
            if exist('command','var')
                Msg.Command=command;
            end
            if exist('content','var')
                Msg.Content=content;
            end
        end
    end

end