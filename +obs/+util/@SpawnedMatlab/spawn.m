function spawn(S,host,messengerlocalport,messengerremoteport,...
                        responderlocalport,responderremoteport)
    % spawns one instance of matlab, creating two messengers in it,
    %  and two listeners in the base workspace of the issueing matlab
    %  session, and then connects to it.
    % The process belongs to the current user if host='localhost',
    %  and to RemoteUser for any other hostname (including the same
    %  machine by IP or by resolved name)
    % For consistency, matlab is always launched in $HOME, so that
    %  a startup.m file can be assumed to be always found there
    % NOTE: for RemoteTerminal = 'xterm' | 'gnome-terminal' | 'desktop'
    %       the prompt is available for user interaction in the
    %       (visible) matlab shell window. For 'none', we put
    %       matlab in an infinite while loop, otherwise it
    %       quits after having executed the messenger setup command
    %      It is yet to be ascertained that this does not have side
    %       consequences.

    if ~isempty(S.PID)
        S.report('PID exists, probably the slave has been already created. Checking status.\n')
        if ~strcmp(S.Status,'dead')
            S.reportError('  A remote MATLAB session with that PID still exists.')
            S.report('  Try .connect to attempt reconnecting\n')
            return
        else
            S.report('The remote process disappeared. Proceeding with .spawn.\n')
        end
    end

    if exist('host','var')
        S.Host=host;
    end
    if isempty(S.Host)
        S.Host='localhost';
    end

    if exist('messengerlocalport','var')
        S.MessengerLocalPort=messengerlocalport;
    end

    if exist('messengerremoteport','var')
        S.MessengerRemotePort=messengerremoteport;
    end
    if isempty(S.MessengerRemotePort)
        S.MessengerRemotePort=8002;
    end

    if exist('responderlocalport','var')
        S.ResponderLocalPort=responderlocalport;
    end

    if exist('responderremoteport','var')
        S.ResponderRemotePort=responderremoteport;
    end
    if isempty(S.ResponderRemotePort)
        S.ResponderRemotePort=9002;
    end

    [Mpids,Rpids]=S.listeners;
    if ~isempty(Mpids) || ~isempty(Rpids)
        p=unique([Mpids(:),Rpids(:)]);
        S.reportError('destination ports already used by processes %s',...
            num2str(p))
        S.reportError('probably you want to .connect instead, or to kill these processes first')
        return
    end

    if S.Logging
        % copy stdout and stderr in two separate files
        % from https://stackoverflow.com/questions/692000/how-do-i-write-stderr-to-a-file-while-using-tee-with-a-pipe/692407#692407
        % Tested ok with bash, but beware that it could behave
        %  differently in other shells
        tstart=datestr(now,'yyyymmddHHMMSS');
        loggingpipe = sprintf(['> >(tee -a %s_stdout.log) 2> ',...
                               '>(tee -a %s_stderr.log >&2)'],...
                               fullfile(S.LoggingDir,sprintf('matlab_%s_%s',S.Id,tstart)), ...
                               fullfile(S.LoggingDir,sprintf('matlab_%s_%s',S.Id,tstart)) );
    else
        loggingpipe = '';
    end

    localhostname=S.LocalHost;

    if strcmpi(S.RemoteMessengerFlavor,'listener')
        messengercommand = ...
            sprintf(['MasterMessenger=obs.util.Listener(''%s'',[%d],%d);'...
            'MasterMessenger.start;'],localhostname,...
            S.MessengerLocalPort,S.MessengerRemotePort);
    else
        messengercommand = ...
            sprintf(['MasterMessenger=obs.util.Messenger(''%s'',[%d],%d);'...
            'MasterMessenger.connect;'],localhostname,...
            S.MessengerLocalPort,S.MessengerRemotePort);
    end

    if (isempty(S.RemoteTerminal) || strcmp(S.RemoteTerminal,'none')) ...
        && ~strcmpi(S.RemoteMessengerFlavor,'listener')
        % if there is no window, put matlab in an infinite loop,
        %  otherwise it just quits after messengercommand is
        %  executed. This is not needed however if the remote messenger is
        %  a Listener, and it is started already in an infinite loop.
        % Matlab can always be closed by sending 'exit' as
        %  messenger command.
        messengercommand=[messengercommand,' while true; pause(0.02); end'];
    end

    % use xterm or gnome-terminal depending on which is
    %  installed sanely
    switch S.RemoteTerminal
        case 'xterm'
            xtitle=sprintf('-T "matlab_%s"',S.Id);
            % for X colors see e.g. https://en.wikipedia.org/wiki/X11_color_names
            spawncommand=['xterm ' xtitle ,...
                ' -sb -bg aliceblue -fg black -cr blue', ...
                ' -e '];
            matlabcommand = 'matlab -nosplash -nodesktop -r ';
        case 'gnome-terminal'
            spawncommand='gnome-terminal -- bash -c ';
            if ~strcmp(S.Host,'localhost')
                % dbus-launch needed for remore hosts, from
                % https://unix.stackexchange.com/questions/407831/how-can-i-launch-gnome-terminal-remotely-on-my-headless-server-fails-to-launch
                % but is still very slow. why?
                spawncommand=['export $(dbus-launch);' spawncommand];
            end
            matlabcommand = 'matlab -nosplash -nodesktop -r ';
        case 'desktop'
            % only local spawns should be allowed to come up
            %  in full java glory
            % stdout will go to the window and not to the pipe
            %  anyway, the eventual logfile will remain empty
            spawncommand = '';
            matlabcommand = 'matlab -nosplash -desktop -r ';
        otherwise
            % 'none', or '', or anything else: silent, but will exit
            %  as soon as the command passed finishes its execution.
            % Easiest workaround, command an infinite loop, as done above
            spawncommand = '';
            matlabcommand = 'matlab -nosplash -nodesktop -r ';
    end

    % we could check at this point: if there is already a corresponding Spawn
    %  messenger, and if it talks to a session (areYouThere), don't proceed.

    % TODO: the proper startup.m should be global
    if strcmp(S.Host,'localhost')
       switch S.RemoteTerminal
           case {'xterm','gnome-terminal'}
               shellcommand= ['"' matlabcommand '\"' ...
                                 messengercommand '\"' loggingpipe '"'];
           case 'desktop'
               % additional matlab commands if we want to rise the java frame:
               %  close the editor window, change title, ...
               desktopcommand = ['closeNoPrompt(matlab.desktop.editor.getAll); ', ...
                    'jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance; ', ...
                    sprintf('jDesktop.getMainFrame.setTitle(''spawn %d->%d''); ',...
                    S.MessengerRemotePort,S.MessengerLocalPort), 'clear jDesktop;'];
               shellcommand= [matlabcommand '"' desktopcommand ...
                              messengercommand '"' loggingpipe];
           otherwise
               shellcommand= [matlabcommand '"' ...
                              messengercommand '"' loggingpipe];                       
       end
       % not yet ok for 'desktop' and 'silent'
       success= (system(['cd ~; ' spawncommand shellcommand '&'])==0);
    else
        % Needs also that some mechanism of auto login is enabled.
        % cfr: http://rebol.com/docs/ssh-auto-login.html
        %      https://serverfault.com/questions/241588/how-to-automate-ssh-login-with-password
        if isempty(S.RemoteUser)
            user='';
        else
            user=[S.RemoteUser '@'];
        end

        % we use ssh -X. This allows opening locally the remote
        %  matlab windows, though it may be slow (expecially
        %  graphics in software OpenGL)

       sshcommand=['ssh -o PasswordAuthentication=no -fCX ' user S.Host];
        % we try to capture the result code, to trap potential
        %  problems -- e.g. unreachable host, wrong user

        % escape all characters which have to be escaped to
        %  transmit the command over ssh
        if any(strcmp(S.RemoteTerminal,{'xterm','gnome-terminal'}))
%                     messengercommand = strrep(messengercommand,'''','\''');
%                     messengercommand = strrep(messengercommand,'(','\(');
%                     messengercommand = strrep(messengercommand,')','\)');
%                     messengercommand = strrep(messengercommand,';','\\;');
            spawncommand = strrep(spawncommand,'"','\"');
            [~,result] = system([sshcommand ' "' spawncommand ...
                          '\"' matlabcommand ...
                          '\\\"' messengercommand '\\\"' ...
                          loggingpipe '\"";' ...
                          ' echo $?']);
        else
             [~,result] = system([sshcommand ' "' spawncommand ...
                          matlabcommand ...
                          '\"' messengercommand '\"' ...
                          loggingpipe '";' ...
                          ' echo $?']);
        end
        % parse result here. There are extra \n, and there could
        %  be "Warning: locale not supported by Xlib",
        %  "usage:  ...", etc. We look for the last line, with
        %  a number on it
        lines=split(result,newline);
        try
            if isempty(lines{end})
                success= sscanf(lines{end-1},'%d')==0;
            else
                success= sscanf(lines{end},'%d')==0;
            end
        catch
            success=false;
        end
    end
    if success
        S.LastError='';
    else
        S.reportError('spawning new session failed')
        return
    end

    % create a listener messenger, and using it create the remote responder
    if S.connect
        
    end

end
