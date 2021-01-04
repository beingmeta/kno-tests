(check-modules '{defmacro defstruct dopool engine ezrecords fifo
		 io/filestream gpath json/export logctl logger net/mimetable
		 kno/packetfns text/parsetime io/readfile
		 text/stringfmts varconfig})
(check-modules '{kno/condense})

(check-modules '{bench kno/sessions kno/profiling kno/primdecls kno/mttools kno/threads})

(check-modules '{knodb
		 knodb/adjuncts knodb/branches knodb/countrefs
		 knodb/filenames 
		 knodb/flexindex knodb/flexpool
		 knodb/hashindexes knodb/indexes knodb/kindexes
		 knodb/kb knodb/registry knodb/typeindex
		 ;; Kind of legacy
		 knodb/slotindex knodb/splitpool
		 sqldb/oids})

(check-modules '{bugjar bugjar/html bugjar/servlet})

(check-modules '{xhtml/auth xhtml/buglog xhtml/clickit 
		 xhtml/datetime xhtml/download xhtml/entities
		 xhtml/exceptions xhtml/include
		 xhtml/pagedate xhtml/tableout})



