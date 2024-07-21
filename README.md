# LAST_Messaging

Messaging framework for the LAST project, implementing:

+ ability of spawning programmatically new matlab sessions, controlled loosely by their caller (class `obs.util.SpawnedMatlab`) (**LINUX only**)
+ messenger infrastructure allowing different matlab session to send matlab commands and queries among one another (classes
  `obs.util.Messenger`, `obs.util.Listener`, `obs.util.Message`). The infrastructure is based on udp datagrams allowing an N:1
  communication between sessions.

**OLD** Reference ramblings in [this document](https://docs.google.com/document/d/1DjzCIXcocHF7WdJuvAIJ3wisPQ6r0wCh8txn9g9bzto) (also duplicated loosely [here](doc/Messenger_and_Message_classes.md))

+ I have assumed for the time being that the classes sit under `+obs/+util`
  and are thus to be prefixed with `obs.util`. If this is changed, remember to
  change accordingly all the references within the code.

## Dependencies

+ certainly depends from [LAST_Handle](https://github.com/EastEriq/LAST_Handle), I doubt that by chance it depends on other components of the LAST project too.

+ the matlab **Instrument Control Toolbox** is required
