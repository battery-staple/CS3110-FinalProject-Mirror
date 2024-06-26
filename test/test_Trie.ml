open OUnit2
open QCheck
open FinalProject.Trie

let trie_string = string

let empty_trie =
  let open Gen in
  QCheck.make (return FinalProject.Trie.make >|= fun f -> f ())

let lowercase = List.map String.lowercase_ascii

let randomized_tests =
  [
    Test.make ~name:"insert x; mem x = true for all x" ~count:500
      (tup2 trie_string empty_trie) (fun (x, trie) ->
        assume (x <> "");
        insert x trie;
        mem x trie);
    Test.make ~name:"insert x; insert y; mem x = true for all x, y" ~count:500
      (tup3 trie_string trie_string empty_trie) (fun (x, y, trie) ->
        assume (x <> "" && y <> "");
        insert x trie;
        insert y trie;
        mem x trie);
    Test.make ~name:"insert x; insert y; mem y = true for all x, y" ~count:500
      (tup3 trie_string trie_string empty_trie) (fun (x, y, trie) ->
        assume (x <> "" && y <> "");
        insert x trie;
        insert y trie;
        mem y trie);
    Test.make ~name:"insert x; insert xy; mem x = true for all x, y" ~count:500
      (tup3 trie_string trie_string empty_trie) (fun (x, y, trie) ->
        assume (x <> "" && y <> "");
        insert x trie;
        insert (x ^ y) trie;
        mem x trie);
    Test.make ~name:"insert x; insert xy; mem xy = true for all x, y" ~count:500
      (tup3 trie_string trie_string empty_trie) (fun (x, y, trie) ->
        assume (x <> "" && y <> "");
        insert x trie;
        insert (x ^ y) trie;
        mem (x ^ y) trie);
    Test.make ~name:"insert x; insert y; to_list = [x; y] for all x, y, x<>y"
      ~count:500 (tup3 trie_string trie_string empty_trie) (fun (x, y, trie) ->
        assume (x <> "" && y <> "" && x <> y);
        insert x trie;
        insert y trie;
        let ( = ) = TestUtil.equals_ignoring_duplicates in
        lowercase (to_list trie) = lowercase [ x; y ]);
    Test.make ~name:"of_list [x; y] |> to_list = [x; y] for all x, y, x<>y"
      ~count:500 (tup2 trie_string trie_string) (fun (x, y) ->
        assume (x <> "" && y <> "" && x <> y);
        let trie = of_list [ x; y ] in
        let ( = ) = TestUtil.equals_ignoring_duplicates in
        lowercase (to_list trie) = lowercase [ x; y ]);
    Test.make ~name:"insert x; mem (lower x) = true for all x, y, x<>y"
      ~count:500 (tup2 empty_trie trie_string) (fun (trie, x) ->
        assume (x <> "");
        let lower_x = String.lowercase_ascii x in
        trie |> insert x;
        trie |> mem lower_x);
    Test.make ~name:"insert x; mem (upper x) = true for all x, y, x<>y"
      ~count:500 (tup2 empty_trie trie_string) (fun (trie, x) ->
        assume (x <> "");
        let upper_x = String.uppercase_ascii x in
        trie |> insert x;
        trie |> mem upper_x);
    Test.make ~name:"make () |> mem x = false for all x" ~count:500
      (tup2 empty_trie trie_string) (fun (trie, x) -> not (mem x trie));
    Test.make ~name:"insert x; mem y = false for all x, y, lower x <> lower y"
      ~count:500 (tup3 empty_trie trie_string trie_string) (fun (trie, x, y) ->
        assume
          (x <> ""
          && y <> ""
          && String.lowercase_ascii x <> String.lowercase_ascii y);
        trie |> insert x;
        not (mem y trie));
  ]

let deterministic_tests =
  [
    ( "strange characters distinguishable" >:: fun _ ->
      let strange_characters =
        [ "¢"; "Â"; "£"; "â"; "§"; "¶"; "ª"; "º"; "´"; "®"; "¨" ]
      in
      strange_characters
      |> List.iter (fun strange ->
             let trie = make () in
             insert strange trie;
             assert (mem strange trie);
             strange_characters
             |> List.iter (fun strange' ->
                    assert (strange' = strange || not (mem strange' trie)))) );
  ]

let trie_test_suite =
  "trie test suite"
  >::: deterministic_tests @ QCheck_runner.to_ounit2_test_list randomized_tests
