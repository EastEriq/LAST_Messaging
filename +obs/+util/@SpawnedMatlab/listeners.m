function [Mpids,Rpids]=listeners(S)
% Find PIDs of processes connected to the destination ports of the
%  .Messenger and .Responder. Useful for detecting nonresponsive slaves,
%  multiple listeners, etc.
  
    if isempty(S.RemoteUser)
        user='';
    else
        user=[S.RemoteUser '@'];
    end
    % idea to clear stdout from https://www.mathworks.com/support/bugreports/1400063
    %  strange that this system call intercepts whatever is on left on stdout, even
    %  if on another host.
    [~,r]=system('');
    
    if isa(S.Messenger,'obs.util.MessengerCommon')
        [s,a]=system(sprintf('ssh %s %s%s "lsof -ti :%d"', ...
            S.SshOptions, user, S.Messenger.DestinationHost, S.Messenger.DestinationPort));
    else
        if isempty(S.Messenger)
            % if the Messenger has not yet been created, check using the
            %  values of the relevant properties known to the SpawnedMatlab
            %  object itself
            [s,a]=system(sprintf('ssh %s %s%s "lsof -ti :%d"', ...
                S.SshOptions, user, S.Host, S.MessengerRemotePort));
        else
            S.reportError('.Messenger is not a messenger')
            a='';
        end
    end
    Mpids=sscanf(a,'%d');
    if s~=0 && s~=1 % return status can be 1 if lsof didn't find the port in use
        S.reportError('cannot execute commands on %s',S.Host)
    end
    
    if nargout>1 && (s==0 || s==1)
        if isa(S.Responder,'obs.util.MessengerCommon')
            [~,a]=system(sprintf('ssh %s %s%s "lsof -ti :%d"', ...
                S.SshOptions, user, S.Responder.DestinationHost, S.Responder.DestinationPort));
        else
            if isempty(S.Responder)
                [~,a]=system(sprintf('ssh %s %s%s "lsof -ti :%d"', ...
                    S.SshOptions, user, S.Host, S.ResponderRemotePort));
            else
                S.reportError('.Responder is not a messenger')
                a='';
            end
        end
        Rpids=sscanf(a,'%d');
    else
        Rpids=[];
    end
