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

end