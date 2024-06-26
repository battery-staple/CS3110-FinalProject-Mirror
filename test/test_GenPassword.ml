open OUnit2
open FinalProject.GenPassword

(*throughout tests -- max 50 lenght password*)
let gen_20_passwords () =
  let list_of_passwords = ref [] in

  for _ = 0 to 19 do
    (* We want to generate 50 passwords with length choice and special or not
       choice for each *)
    let len = Random.int 50 in
    (* want int between 1 and 2^30 -1 *)
    let spec_choice = Random.int 2 + 1 in

    (* want int between 1 and 2*)
    let password =
      match (len, spec_choice) with
      | len, 1 -> generate_password_with_special len
      | len, 2 -> generate_password_without_special len
      | _ -> "Invalid arguments"
    in
    list_of_passwords := password :: !list_of_passwords
  done;
  !list_of_passwords

let tests =
  [
    ( "Test 20 passwords are all distinct, valid args" >:: fun _ ->
      let passwords_lst = gen_20_passwords () in
      let distinct = ref true in

      (* only changes if any password combo is the same*)
      for i = 0 to 18 do
        for j = i + 1 to 19 do
          (*check every possible distinct pair*)
          if List.nth passwords_lst i = List.nth passwords_lst j then
            distinct := false
        done
      done;
      assert_bool "At least 2 passwords are identical"
        !distinct (* only true if they are the same *) );
    ( "Test none of 5 non-spec passwords have non-alphanumerics" >:: fun _ ->
      let valid = ref true in
      for _ = 0 to 4 do
        let len = Random.int 50 in
        let password_new = generate_password_without_special len in
        if
          String.exists
            (fun c ->
              let code = Char.code (Char.lowercase_ascii c) in
              not (* not any one of these cases*)
                ((code >= 48 && code <= 57) || (code >= 97 && code <= 122)))
            password_new
        then valid := false
        (* only turns false if contains alphanumerics*)
      done;
      assert_bool "Contain non-alphanumerics" !valid );
    ( "Test correct length non-special characters" >:: fun _ ->
      let valid = ref true in
      let len = Random.int 50 in
      let password_new = generate_password_without_special len in
      if String.length password_new <> len then valid := false;
      (* if different passwords*)
      assert_bool "Wrong length for non-special" !valid );
    ( "Test correct length special characters" >:: fun _ ->
      let valid = ref true in
      let len = Random.int 50 in
      let password_new = generate_password_with_special len in
      if String.length password_new <> len then valid := false;
      (* if different passwords*)
      assert_bool "Wrong length for special" !valid );
    ( "Test none of 5 spec-spec passwords have non-permitted chars (not \
       alpha-numeric or #, $, &)"
    >:: fun _ ->
      let valid = ref true in
      for _ = 0 to 4 do
        let len = Random.int 50 in
        let password_new = generate_password_with_special len in
        if
          String.exists
            (fun c ->
              let code = Char.code (Char.lowercase_ascii c) in
              not (* not any one of these cases*)
                ((code >= 48 && code <= 57)
                || (code >= 97 && code <= 122)
                || code = 35
                || code = 36
                || code = 38))
            password_new
        then valid := false
        (* only turns false if contains alphanumerics*)
      done;
      assert_bool "Contain non-valid symbols" !valid );
  ]

let qcheck_tests =
  let open QCheck in
  [
    Test.make
      ~name:
        "Randomly generated passwords with only alphanumeric characters do not \
         consist of all the same character" ~count:200 (int_range 20 50)
      (fun len ->
        let pwd = generate_password_without_special len in
        String.exists (fun c -> c <> pwd.[0]) pwd);
    Test.make
      ~name:
        "Randomly generated passwords with alphanumeric and special characters \
         do not consist of all the same character" ~count:200 (int_range 20 50)
      (fun len ->
        let pwd = generate_password_with_special len in
        String.exists (fun c -> c <> pwd.[0]) pwd);
  ]

let gen_password_suite =
  "gen password suite"
  >::: tests @ QCheck_runner.to_ounit2_test_list qcheck_tests
