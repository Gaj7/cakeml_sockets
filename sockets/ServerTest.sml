val _ = print "Establishing socket...\n"
val sockfd = Socket.listen 5000 5
val _ = print ("Socket established with file descriptor: " ^
               (Socket.fdToString sockfd) ^ "\n")

val _ = print "Waiting for incoming connection...\n"
val clientfd = Socket.accept sockfd
val _ = print ("Connection established with file descriptor: " ^
               (Socket.fdToString clientfd) ^ "\n")

val _ = print "Reading message...\n"
val message = TextIO.inputAll clientfd
val _ = print ("Message: " ^ message ^ "\n")

val _ = print "Closing sockets...\n"
val _ = TextIO.close clientfd
val _ = TextIO.close sockfd

val _ = print "Done\n"
