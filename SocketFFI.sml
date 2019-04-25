(* Safe(ish) wrapper to FFI socket functions *)
structure Socket = struct
    (* Generic socket exception *)
    exception SocketFail

    local
        (* Shared/reused buffers *)
        val fdbuf = Word8Array.array 9 (Word8.fromInt 0)
        val cbuf = Word8Array.array 2 (Word8.fromInt 0)
        (* The null char (used here to delimit args) *)
        val null = String.str (Char.chr 0)
    in
        (* Takes a port number and maximum queue length, and returns the fd of a new
           actively listening socket *)
        fun listen port qLen =
            let
                val _ = Marshalling.n2w2 qLen cbuf 0
                val c = (Word8Array.substring cbuf 0 2) ^ (Int.toString port)
                val _ = #(listen) c fdbuf
            in
                if Word8Array.sub fdbuf 0 = Word8.fromInt 1
                    then raise SocketFail
                    else Word8Array.substring fdbuf 1 8
            end

        (* Takes the fd of an actively listening socket, returns the fd of a connection *)
        (* Blocks until there is an incoming connection *)
        fun accept sockfd =
            let
                val _ = #(accept) sockfd fdbuf
            in
                if Word8Array.sub fdbuf 0 = Word8.fromInt 1
                    then raise SocketFail
                    else Word8Array.substring fdbuf 1 8
            end

        (* Takes the host as a string, in the format of a domain name or IPv4 address,
           and port, and integer corresponding to a port number. Returns a fd. *)
        fun connect host port =
            let
                val c = host ^ null ^ (Int.toString port) ^ null
                val _ = #(connect) c fdbuf
            in
                if Word8Array.sub fdbuf 0 = Word8.fromInt 1
                    then raise SocketFail
                    else Word8Array.substring fdbuf 1 8
            end
    end

    (* The following code is adaptped from the TextIO implementation in the
       basis library. It is stripped of the instream/outstream constructors.
       The input functions are changed to not make redundant read calls that
       end up blocking when used on sockets.

       Specifically, the code is adapted from the following commit:
https://github.com/CakeML/cakeml/commit/b2076e74977d96b0734bd1ab2ae59ef1f91c3004
       The following licensing information applies to the rest of the code in
       this file: *)
(*
CakeML Copyright Notice, License, and Disclaimer.

Copyright 2013, 2014, 2015, 2016, 2017, 2018 by
Anthony Fox, Google LLC, Ramana Kumar, Magnus Myreen,
Michael Norrish, Scott Owens, Yong Kiam Tan, and
other contributors listed at https://cakeml.org

All rights reserved.

CakeML is free software. Redistribution and use in source and binary forms,
with or without modification, are permitted provided that the following
conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * The names of the copyright holders and contributors may not be
      used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

    exception InvalidFD

    local
        val iobuff = Word8Array.array 2052 (Word8.fromInt 0)
    in
        (* Write functions *)
        local
            fun writei fd n i =
                let val a = Marshalling.n2w2 n iobuff 0
                    val a = Marshalling.n2w2 i iobuff 2
                    val a = #(write) fd iobuff in
                    if Word8Array.sub iobuff 0 = Word8.fromInt 1
                    then raise InvalidFD
                    else
                      let val nw = Marshalling.w22n iobuff 1 in
                        if nw = 0 then writei fd n i
                        else nw
                      end
                end
            fun write fd n i =
              if n = 0 then () else
                let val nw = writei fd n i in
                    if nw < n then write fd (n-nw) (i+nw) else () end
        in
            fun output fd s =
                if s = "" then () else
                let val z = String.size s
                    val n = if z <= 2048 then z else 2048
                    val fl = Word8Array.copyVec s 0 n iobuff 4
                    val a = write fd n 0 in
                        output fd (String.substring s n (z-n))
                end
        end

        (* Read functions *)
        local
            fun read fd n =
                let val a = Marshalling.n2w2 n iobuff 0 in
                    (#(read) fd iobuff;
                    if Word8.toInt (Word8Array.sub iobuff 0) <> 1
                        then Marshalling.w22n iobuff 1
                        else raise InvalidFD)
                end

            fun input fd buff off len =
                let fun input0 off len count =
                    let val nwant = min len 2048
                        val nread = read fd nwant
                    in
                        if nread = 0 then count else
                        (Word8Array.copy iobuff 4 nread buff off;
                            if nread < nwant then count+nread else
                            input0 (off + nread) (len - nread) (count + nread))
                    end
                in input0 off len 0 end

            fun extend_array arr =
                let
                    val len = Word8Array.length arr
                    val arr' = Word8Array.array (2*len) (Word8.fromInt 0)
                in (Word8Array.copy arr 0 len arr' 0; arr') end
        in
            fun inputAll fd =
                let
                    fun inputAll_aux arr i =
                        let val len = Word8Array.length arr in
                            if i < len then
                                let
                                    val nwant = len - i
                                    val nread = input fd arr i nwant
                                in
                                    if nread < nwant then Word8Array.substring arr 0 (i+nread)
                                    else inputAll_aux arr (i + nread)
                                end
                            else inputAll_aux (extend_array arr) i
                        end
                in inputAll_aux (Word8Array.array 127 (Word8.fromInt 0)) 0 end
        end

        (* Close function *)
        fun close fd =
            let val a = #(close) fd iobuff in
            if Word8Array.sub iobuff 0 = Word8.fromInt 0
            then () else raise InvalidFD
        end
    end
end
