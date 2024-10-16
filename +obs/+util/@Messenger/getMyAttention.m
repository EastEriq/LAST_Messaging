function resp=getMyAttention(Msng)
% tell to the messenger receiving on the other end, to change its
%  DestinationHost and DestinationPort so to answer here.
% This is useful for taking over, when we know that there is a messenger
%  receiving at the other end, but it was bound to another messenger
%  elsewhere
% We evaluate in the remote datagramParser, but the settings of the
%  StreamResource are globally visible
    send(Msng,['Msng.DestinationHost=''' Msng.LocalHost ''';'],-1,true);
    send(Msng,['Msng.DestinationPort=' num2str(Msng.LocalPort) ';'],-1,true);
    resp=Msng.areYouThere;
