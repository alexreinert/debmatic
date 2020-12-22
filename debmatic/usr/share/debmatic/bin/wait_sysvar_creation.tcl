#!/bin/tclsh

load tclrpc.so
load tclrega.so

set script "
boolean are_sv_created = false;
string sv_id;

foreach (sv_id, dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedIDs()) {
  if ((sv_id == 40) || (sv_id == 41) || (sv_id == ID_PRESENT)) {
    are_sv_created = true;
  }
}
"

puts -nonewline "Waiting for ReGa startup "

for {set i 0} {$i < 30} {incr i} {
  puts -nonewline "."
  flush stdout

  exec sleep 5

  if { [catch {
    array set result [rega_script $script]
    set ise_are_sv_created $result(are_sv_created)
  } err ] } {
    set ise_are_sv_created false
  }

  if {$ise_are_sv_created} {
    puts " Done"
    break
  }
}

