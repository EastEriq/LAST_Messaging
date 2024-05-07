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
    %  if on another host. This steals additional time, though.
    [~,r]=system(sprintf('ssh %s %s%s " "', S.SshOptions, user, S.Host));
    
    % use lsof. Don't filter out MATLAB, in order to ascertain that
    %  processes different from it are not holding the port; but filter out
    %  'mupkern'. Apparently matlab creates one separate process for it (is
    %  this new? Because of something new introduced in AstroPack? I think
    %  once it was not) probably in connection with Mupad. we don't need to
    %  list it separately; the process disappears together with its calling
    %  matlab
    if isa(S.Messenger,'obs.util.MessengerCommon')
        [s,a]=system(sprintf('ssh %s %s%s "lsof -c^mupkern -ti :%d"', ...
            S.SshOptions, user, S.Messenger.DestinationHost, S.Messenger.DestinationPort));
    else
        if isempty(S.Messenger)
            % if the Messenger has not yet been created, check using the
            %  values of the relevant properties known to the SpawnedMatlab
            %  object itself
            [s,a]=system(sprintf('ssh %s %s%s "lsof -c^mupkern -ti :%d"', ...
                S.SshOptions, user, S.Host, S.MessengerRemotePort));
        else
            S.reportError('.Messenger is not a messenger')
            a='';
        end
    end
    a=split(a,newline);
    Mpids=[];
    for i=1:numel(a)
        Mpids=[Mpids;sscanf(a{i},'%d')];
    end
    if s~=0 && s~=1 % return status can be 1 if lsof didn't find the port in use
        S.reportError('cannot execute commands on %s',S.Host)
    end
    
    if nargout>1 && (s==0 || s==1)
        if isa(S.Responder,'obs.util.MessengerCommon')
            [~,a]=system(sprintf('ssh %s %s%s "lsof -c^mupkern -ti :%d"', ...
                S.SshOptions, user, S.Responder.DestinationHost, S.Responder.DestinationPort));
        else
            if isempty(S.Responder)
                [~,a]=system(sprintf('ssh %s %s%s "lsof -c^mupkern -ti :%d"', ...
                    S.SshOptions, user, S.Host, S.ResponderRemotePort));
            else
                S.reportError('.Responder is not a messenger')
                a='';
            end
        end
        a=split(a,newline);
        Rpids=[];
        for i=1:numel(a)
            Rpids=[Rpids;sscanf(a{i},'%d')];
        end
    else
        Rpids=[];
    end

