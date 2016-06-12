type filter = primop
and primop =
  | Id
  | Get of Edn.t
  | Pipe of filter * filter
  | Split of filter * filter
  | Map of filter
  | CollectVector of filter list
  | CollectMap of (filter * filter) list
  | PassThrough of Edn.t

let rec make_primop_filter (op:Edn.t) args  =
  match (op, args) with
    (`Symbol (None, "id"), []) -> Id
  | (`Symbol (None, "get"), arg::[]) -> Get arg
  | (`Symbol (None, "->"), filter1::filter2::[]) -> Pipe (make_filter filter1, make_filter filter2)
  | (`Symbol (None, "&"), filter1::filter2::[]) -> Split (make_filter filter1, make_filter filter2)
  | (`Symbol (None, "map"), filter::[]) -> Map (make_filter filter)
  | _ -> print_string "Unkonwn primop"; assert false
and make_filter (filter:Edn.t) =
  match filter with
    `List (op::args) -> make_primop_filter op args
  | `Vector xs -> CollectVector (List.map make_filter xs)
  | `Assoc xs -> CollectMap (List.map (fun (k, v) -> (make_filter k, make_filter v)) xs)
  | filter_value -> PassThrough filter_value

let rec lookup_map key kvs =
  match kvs with
    (k,v)::tl -> if k = key then v else lookup_map key tl
   | [] -> `Null

let lookup_seq key xs =
  match key with
    `Int n -> List.nth xs n
  | _ -> `Null

let lookup_set key xs =
  if List.mem key xs
  then key
  else `Null

let lookup key (value:Edn.t) =
  match value with
    `Assoc kvs -> lookup_map key kvs
  | (`List xs | `Vector xs) -> lookup_seq key xs
  | `Set xs -> lookup_set key xs
  | _ -> `Null

let mapcat f list =
  List.concat (List.map f list)

let rec apply_filter filter (value:Edn.t) =
  match filter with
    Id -> [value]
  | Get key -> [lookup key value]
  | Pipe (filter1, filter2) -> let result = apply_filter filter1 value in
                               mapcat (apply_filter filter2) result
  | Split (filter1, filter2) -> let result1 = apply_filter filter1 value in
                                let result2 = apply_filter filter2 value in
                                List.concat [result1; result2]
  | Map filter -> apply_map filter value
  | CollectVector fs -> let result = List.concat (List.map (fun f -> apply_filter f value) fs) in
                        [`Vector result]
  | CollectMap fs -> let result = List.map (fun (kf, vf) -> (List.hd (apply_filter kf value), List.hd (apply_filter vf value))) fs in
                     [`Assoc result]
  | PassThrough pvalue -> [pvalue]
and apply_map filter (value:Edn.t) =
  match value with
    `List xs -> List.concat (List.map (apply_filter filter) xs)
  | `Vector xs -> List.concat (List.map (apply_filter filter) xs)
  | `Set xs -> List.concat (List.map (apply_filter filter) xs)
  | `Assoc kvs -> List.concat
                    (List.map
                       (fun (k, v) ->
                         apply_filter filter (`Vector [k;v]))
                       kvs)
  | rest -> apply_filter filter rest
