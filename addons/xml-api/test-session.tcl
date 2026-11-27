if {$argc != 1} {
  puts stderr "Usage: tclsh test-session.tcl <patched-session.tcl>"
  exit 1
}

rename load native_load
proc load {args} {}
proc rega_script {script} {
  if {[string first "abcdefghij" $script] >= 0} {
    return [list ignored valid]
  }
  return [list ignored ""]
}
proc assert {condition message} {
  if {![uplevel 1 [list expr $condition]]} {
    error $message
  }
}

set fd [file tempfile tokenfile]
close $fd
set result [catch {
  set fd [open [lindex $argv 0] r]
  set script [read $fd]
  close $fd
  set script [string map [list /etc/config/addons/xmlapi/token.list $tokenfile] $script]
  set env(REMOTE_ADDR) 127.0.0.1
  set env(QUERY_STRING) ""
  eval $script

  assert {[check_session ""] == 0} "Missing sid accepted from loopback"
  assert {[check_session invalid] == 0} "Invalid sid accepted"
  set token [register_token test]
  assert {[check_session $token] == 1} "Registered token rejected"
  assert {[check_session @abcdefghij@] == 1} "Valid WebUI session rejected"
  assert {[check_session @zzzzzzzzzz@] == 0} "Invalid WebUI session accepted"
  assert {[revoke_token $token] == 1} "Token not revoked"
  assert {[check_session $token] == 0} "Revoked token accepted"

  file delete $tokenfile
  file mkdir $tokenfile
  assert {[catch {register_token test}]} "Token storage failure was ignored"
} errorMessage]
file delete $tokenfile
if {$result} {
  puts stderr $errorMessage
  exit 1
}
puts "XML-API session tests passed"
