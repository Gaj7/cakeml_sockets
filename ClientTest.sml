val _ = print "Connecting to server...\n"
val serverfd = Socket.connect "127.0.0.1" 5000
val _ = print ("Connection established\n")

val _ = print "Sending message...\n"
val _ = TextIO.output serverfd "Hello Socket World\n"

val _ = print "Closing socket...\n"
val _ = TextIO.close serverfd

val _ = print "Done\n"
