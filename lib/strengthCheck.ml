let common_passwords_opt = ref None

module type CommonPasswordsPath = sig
  val common_passwords_path : string
end

module Make (CPP : CommonPasswordsPath) = struct
  let init_async_return () =
    let pwds_promise =
      Lwt_preemptive.detach Trie.of_file CPP.common_passwords_path
    in
    common_passwords_opt := Some pwds_promise;
    pwds_promise

  let init_async () = init_async_return () |> ignore

  let is_initialized () =
    match !common_passwords_opt with
    | Some promise -> begin
        match Lwt.state promise with
        | Return _ -> true
        | _ -> false
      end
    | None -> false

  let is_weak password_str =
    let%lwt common_passwords =
      match !common_passwords_opt with
      | Some pass_promise -> pass_promise
      | None -> init_async_return ()
    in
    Lwt.return
      (try Trie.mem password_str common_passwords
       with Failure mess ->
         if mess = "Invalid character" then false else raise (Failure mess))
end
