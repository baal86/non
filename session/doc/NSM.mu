
! title		Non Session Management API
! author	Jonathan Moore Liles #(email,male@tuxfamily.org)
! date		August 1, 2010

-- Table Of Contents

: Non Session Management API version 0.7

  The Non Session Management API is an API for session management used
  by the various parts of the Non music production suite. It comprises
  a simple OSC based protocol which can easily be implemented by other
  applications. NSM provides robust session management, including
  interactive features.

  The Non project contains an implementation of the NSM server API
  called `nsmd` which can be controlled by the `non-session-manager`
  GUI, but the same server API can easily be implemented by other
  session managers (such as LADISH).
  
  The only dependency for clients `liblo` (the OSC library), which
  several Linux audio applications already link to or plan to link to
  in the future.

  The aim of this project is to thoroughly define the behavior
  required of clients. This is an area where other attempts at session
  management (LASH and JACK-Session) have failed. Often the difficulty
  with these previous system been, not in implementing support for
  them, but in attempting to interpret the confusing and ambiguous API
  documentation. For this reason, all LASH support has been removed
  from Non.

  You *WILL* see a lot of unambiguous language in this document. These
  rules are meant to be followed and are non-negotiable. If an
  application does not conform to this specification it should be
  considered broken. Consistency across applications under session
  management is very important for a good user experience.

:: Client Behavior Under Session Management

  Most graphical applications make available to the user a common set
  of file operations, typically presented under a File or Project
  menu.

  These are: New, Open, Save, Save As, Close and Quit or Exit.

  The following sub-sections describe how these options should behave when
  the application is part of an NSM session. These rules only apply
  when session management is active (that is, after the `announce`
  handshake described in the #(ref,NSM OSC Protocol) section). 
  
  In order to provide a consistent and predictable user experience, it
  is important for applications to adhere to these guidelines.

::: New

  This option may empty\/reset the current file or project (possibly
  after user confirmation). *UNDER NO CIRCUMSTANCES* should it allow
  the user to create a new project\/file in another location.

::: Open

  This option should be disabled. 

  The application may, however, elect to implement an option called
  'Import into Session', creates a copy of a file\/project which is
  then saved in the session path provided by NSM.

::: Save

  This option should behave as normal, saving the current
  file\/project as established by the NSM `open` message.

  *UNDER NO CIRCUMSTANCES* should this option present the user with a
  choice of where to save the file!

::: Save As

  This option should be disabled.

  The application may, however, elect to implement an option called
  'Export from Session', which creates a copy of the current
  file\/project which is then saved in a user-specified location
  outside of the session path provided by NSM.

::: Close (as distinguished from Quit or Exit)
  
  This option should be disabled, unless its meaning is to disconnect
  the application from session management.

::: Quit or Exit

  This option may behave as normal (even possibly asking the user to
  confirm exiting).

:: NSM OSC Protocol

  All message parameters are *REQUIRED*. All messages *MUST* be sent
  from the same socket as the `announce` message, using the
  `lo\_send\_from` method of liblo (the server uses the return
  addresses to distinguish between clients).

::: Establishing a Connection

:::: Announce

  When started clients *MUST* check the environment for the value of
  `NSM\_URL`. If present, the client *MUST* send the following message
  to the provided address as soon as it is ready to respond to the
  `\/nsm\/client\/open` event:

> /nsm/server/announce s:application_name s:capabilities i:api_version_major i:api_version_minor i:pid

  If `NSM\_URL` is undefined, invalid, or unreachable, then the client
  should proceed assuming that session management is unavailable.

  `api\_version\_major` and `api\_version\_minor` must be the two parts of
  the version number of the NSM API as defined by this document.

  Note that if the application intends to register JACK clients,
  `application\_name` *MUST* be the same as the name that would
  normally by passed to `jack\_client\_open`. For example, Non-Mixer
  sends "Non-Mixer" as its `application\_name`. Applications *MUST
  NOT* register their JACK clients until receiving an `open` message;
  the `open` message will provide a unique client name prefix suitable
  for passing to JACK. This is probably the most complex requirement
  of the NSM API, but it isn't difficult to implement.

  `capabilities` *MUST* be a string containing a colon separated list
  of the special capabilities the client
  possesses. e.g. ":dirty:switch:progress:"

// Available Client Capabilities
[[ Name, Description
[[ switch, client is capable of responding to multiple `open` messages without restarting
[[ dirty, client knows when it has unsaved changes
[[ progress, client can send progress updates during time-consuming operations
[[ status, client can send textual status updates 

:::: Response

  The server will respond to the client's `announce` with the following message:

> /reply "/nsm/server/announce" s:message s:name_of_session_manager s:capabilities

  `message` is a welcome message.

  The value of `name\_of\_session\_manager` will depend on the
  implementation of the NSM server. It might say "Non Session Manager",
  or it might say "LADISH".

  `capabilities` will be a string containing a colon separated list of
  special server capabilities.

  Presently, the server `capabilities` are:

// Available Server Capabilities
[[ Name, Description
[[ server_control, client-to-server control

  A client should not consider itself to be under session management
  until it receives this response (the Non programs activate their
  "SM" blinkers at this time.)

  If there is an error, a reply of the following form will be sent to
  the client:

> /error "/nsm/server/announce" i:error_code s:error_message

  The following table defines possible values of `error\_code`:

// Response codes
[[ Code, Meaning
[[ ERR_GENERAL, General Error
[[ ERR_INCOMPATIBLE_API, Incompatible API version
[[ ERR_BLACKLISTED, Client has been blacklisted.

::: Server to Client Control Messages

  Compliant clients *MUST* accept the client control messages
  described in this section. All client control messages *REQUIRE* a
  response. Responses *MUST* be delivered back to the sender (NSM)
  from the same socket used by the client in its `announce` message
  (by using `lo\_send\_from`) *AFTER* the action has been completed or
  if an error is encountered. The required response is described in
  the subsection for each message.

  If there is an error and the action cannot be completed, then
  `error\_code` *MUST* be set to a valid error code (see #(fig,Error Code Definitions))
  and `message` to a string describing the problem (suitable
  for display to the user).

  The reply can take one of the following two forms, where `path` *MUST* be
  the path of the message being replied to (e.g. "/nsm\/client\/save"):

> /reply s:path s:message

> /error s:path i:error_code s:message

:::: Quit

  There is no message for this. Clients will receive the Unix SIGTERM
  signal and *MUST* close cleanly *IMMEDIATELY*, without displaying
  any kind of dialog to the user and regardless of whether or not
  unsaved changes would be lost (when a session is closed the
  application will receive this signal soon after having responded to
  a `save` message).

:::: Open 

> /nsm/client/open s:path_to_instance_specific_project s:client_id

  The client *MUST* open an existing project, or create new one if one
  doesn't already exist, at `path\_to\_instance_specific\_project`

  If the path provided doesn't exist, then the client *MUST*
  immediately create and open a new file\/project at the specified
  path (whether that means creating a single file or a project
  directory).

  No file or directory will be created at the specified path by the
  server. It is up to the client to create what it needs.

  The client may append to the path, creating a subdirectory,
  e.g. '/song.foo' or simply append the client's native file extension
  (e.g. '.non' or '.XML'). The same transformation *MUST* be applied
  to the name when opening an existing project, as NSM will only
  provide the instance specific part of the path.

  For clients which *HAVE NOT* specified the 'switch' capability, the
  `open` message will only be delivered once, immediately after the
  'announce' response.

  For client which *HAVE* specified the `:switch:` capability, the
  client *MUST* immediately switch to the specified project or create
  a new one if it doesn't exist.

  Clients which are incapable of switching projects or are prone to
  crashing upon switching *MUST NOT* include `:switch:` in their
  capability string.

  If the user the is allowed to run two or more instances of the
  application simultaneously (that is to say, there is no technical
  limitation preventing them from doing so, even if it doesn't make
  sense to the author), then such an application *MUST* prepend the
  provided `client\_id` string to any names it registers with common
  subsystems (e.g. JACK client names). This ensures that the multiple
  instances of the same application can be restored in any order
  without scrambling the JACK connections or causing other
  conflicts. The provided `client\_id` will be a concatenation of the
  value of `application\_name` sent by the client in its `announce`
  message and a unique identifier. Therefore, applications which
  create single JACK clients can use the value of `client\_id` directly
  as their JACK client name. Applications which register multiple JACK
  clients (e.g. Non-Mixer) *MUST* prepend `client_id` value to the
  client names they register with JACK and the application determined
  part *MUST* be unique for that (JACK) client.

  For example, a suitable JACK client name would be:

> $CLIENT_ID/track-1

  A response is *REQUIRED* *AFTER* the load\/new operation has been
  completed.  Ongoing progress may be indicated by sending messages to
  `\/nsm\/client\/progress`.

::::: Response

  The client *MUST* respond to the 'open' message with:

> /reply "/nsm/client/open" s:message

  Or

> /error "/nsm/client/open" i:error_code s:message

// Response Codes
[[ Code, Meaning
[[ ERR, General Error
[[ ERR_BAD_PROJECT, An existing project file was found to be corrupt
[[ ERR_CREATE_FAILED, A new project could not be created
[[ ERR_UNSAVED_CHANGES, Unsaved changes would be lost
[[ ERR_NOT_NOW, Operation cannot be completed at this time

:::: Save

> /nsm/client/save

  The client *MUST* immediately save the current application specific
  project data to the project path previously established in the
  'open' message. *UNDER NO CIRCUMSTANCES* should a dialog be
  displayed to the user (giving a choice of where to save, etc.)

::::: Response

  The client *MUST* respond to the 'save' message with:

> /reply "/nsm/client/save" s:message

  Or

> /error "/nsm/client/save" i:error_code s:message

// Response Codes
[[ Code, Meaning
[[ ERR, General Error
[[ ERR_SAVE_FAILED, Project could not be saved
[[ ERR_NOT_NOW, Operation cannot be completed at this time

::: Server to Client Informational Messages

:::: Session is Loaded
 
  Accepting this message is optional. The intent is to signal to
  clients which may have some interdependency (say, peer to peer OSC
  connections) that the session is fully loaded and all their peers
  are available.

> /nsm/client/session_is_loaded

  This message does not require a response.

::: Client to Server Informational Messages

  These are optional messages which a client can send to the NSM
  server to inform it about the client's status. The client should not
  expect any reply to these messages. If a client intends to send a
  message described in this section, then it *MUST* add the
  appropriate value to its `capabilities` string when composing the
  `announce` message.

:::: Progress

> /nsm/client/progress f:progress

  For potentially time-consuming operations, such as `save` and
  `open`, progress updates may be indicated throughout the duration by
  sending a floating point value between 0.0 and 1.0, 1.0 indicating
  completion, to the NSM server.

  The server will not send a response to these messages, but will
  relay the information to the user.

  Note that, even when using the `progress` feature, the final
  response to the `save` or `open` message is still *REQUIRED*.

  Clients which intend to send `progress` messages should include
  `:progress:` in their `announce` capability string.

:::: Dirtiness

> /nsm/client/is_dirty

> /nsm/client/is_clean

  Some clients may be able to inform the server when they have unsaved
  changes pending. Such clients may optionally send `is\_dirty` and `is\_clean`
  messages. 

  Clients which have this capability should include `:dirty:` in their
  `announce` capability string.

:::: Status Messages

> /nsm/client/message i:priority s:message

  Clients may send miscellaneous status updates to the server for
  possible display to the user. This may simply be chatter that is normally
  written to the console. `priority` should be a number from 0 to 3, 3
  being the most important.

  Clients which have this capability should include `:message:` in their
  `announce` capability string.

::: Error Code Definitions

// Error Code Definitions
[[ Symbolic Name, Integer Value
[[ ERR_GENERAL, -1
[[ ERR_INCOMPATIBLE_API, -2
[[ ERR_BLACKLISTED,      -3
[[ ERR_LAUNCH_FAILED,    -4
[[ ERR_NO_SUCH_FILE,     -5
[[ ERR_NO_SESSION_OPEN, -6
[[ ERR_UNSAVED_CHANGES,  -7
[[ ERR_NOT_NOW, -8
[[ ERR_BAD_PROJECT, -9
[[ ERR_CREATE_FAILED, -10

::: Client to Server Control

  If the server publishes the `server\_control` capability, then
  clients can also initiate action by the server. For example, a
  client might implement a 'Save All' option which sends a
  `\/nsm\/server\/save` message to the server, rather than requiring
  the user to switch to the session management interface to effect the
  save.

::: Server Control API

  The session manager not only manages clients via OSC, but it is itself
  controlled via OSC messages. The server responds to the following
  messages.

  All of the following messages will be responded to back to the sender's address 
  with one of the two following messages:

> /reply s:path s:message

> /error s:path i:error_code s:message
 
  The first parameter of the reply is the path to the message being
  replied to. The `\/error` reply includes an integer error code
  (non-zero indicates error). `message` will be a description of the
  error.

  The possible errors are:

// Responses
[[ Code, Meaning
[[ ERR_GENERAL, General Error
[[ ERR_LAUNCH_FAILED, Launch failed
[[ ERR_NO_SUCH_FILE, No such file
[[ ERR_NO_SESSION, No session is open
[[ ERR_UNSAVED_CHANGES, Unsaved changes would be lost

= /nsm/server/add s:path_to_executable
  Adds a client to the current session.

= /nsm/server/save
  Saves the current session.

= /nsm/server/load s:project_name
  Saves the current session and loads a new session.

= /nsm/server/new s:project_name
  Saves the current session and creates a new session.

= /nsm/server/close
  Saves and closes the current session.

= /nsm/server/abort
  Closes the current session *WITHOUT SAVING*  

= /nsm/server/quit
  Saves and closes the current session and terminates the server.

= /nsm/server/duplicate s:new_project 
  Saves and closes the current session, creates a complete copy of
  it as `new_project` and opens it. The existing project should ideally be
  a lightweight template, as copying any audio data could be very time
  consuming.

= /nsm/server/list 
  Lists available projects. One `\/reply` message will be sent for each existing project.



# = /nsm/server/client/list
#   Lists clients in the current session, their client IDs and statuses
# = /nsm/server/ve

:::: Client to Client Communication

  If the server includes `:broadcast:` in its capability string, then
  clients may send broadcast messages to each other through the NSM
  server.
  
  Clients may send messages to the server at the path
  `\/broadcast`.

  The format of this message is as follows:

> /nsm/server/broadcast s:path [other parameters...]

  The message will then be relayed to all clients in the session at
  the path given in the `path` parameter and with the other parameters
  shifted forward by one.

  For example the message:

>  /nsm/server/broadcast /tempomap/update "0,120,4/4:12351234,240,4/4"

  Would broadcast the following message to all clients in the session
  (except for the sender), some of which might respond to the message
  by updating their own tempo maps.

>  /tempomap/update "0,120,4/4:12351234,240,4/4"

  Clients may use this feature to establish peer to peer OSC
  communication with symbolic names without having to remember the OSC
  URLs of peers.