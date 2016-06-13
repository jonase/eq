open Format

type edn = Edn.t

type query =
  | Id
  | Get of edn
  | Pipe of query * query
  | Split of query * query
  | Map of query
  | CollectVector of query list
  | CollectMap of (query * query) list
  | PassThrough of edn

let ensure_arg_count op args n =
  let arg_count = List.length args in
  if arg_count = n then
    args
  else
    failwith (sprintf "Expected %d args to %s, got %d."
                      n op arg_count)

let rec id_query args = Id

and get_query args = Get (List.hd args)

and pipe_query args = Pipe (make_query (List.hd args),
                            make_query (List.nth args 1))

and split_query args = Split (make_query (List.hd args),
                              make_query (List.nth args 1))

and map_query args = Map (make_query (List.hd args))

and make_primop_query op args  =
  match (op, args) with
  | ("id",  args) -> id_query    (ensure_arg_count "id"  args 0)
  | ("get", args) -> get_query   (ensure_arg_count "get" args 1)
  | ("->",  args) -> pipe_query  (ensure_arg_count "->"  args 2)
  | ("&",   args) -> split_query (ensure_arg_count "&"   args 2)
  | ("map", args) -> map_query   (ensure_arg_count "map" args 1)
  | _ -> failwith (sprintf "Unknown query op: %s" op);

and make_query (query:edn) =
  match query with
    `List ((`Symbol (None, op))::args) -> make_primop_query op args
  | `Vector xs -> CollectVector (List.map make_query xs)
  | `Assoc xs -> CollectMap (List.map (fun (k, v) -> (make_query k, make_query v)) xs)
  | query_value -> PassThrough query_value

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

let lookup key (value:edn) =
  match value with
    `Assoc kvs -> lookup_map key kvs
  | (`List xs | `Vector xs) -> lookup_seq key xs
  | `Set xs -> lookup_set key xs
  | _ -> `Null

let mapcat f list =
  List.concat (List.map f list)

let rec apply_query query (value:edn) =
  match query with
    Id -> [value]
  | Get key -> [lookup key value]
  | Pipe (query1, query2) -> let result = apply_query query1 value in
                               mapcat (apply_query query2) result
  | Split (query1, query2) -> let result1 = apply_query query1 value in
                                let result2 = apply_query query2 value in
                                List.concat [result1; result2]
  | Map query -> apply_map query value
  | CollectVector fs -> let result = List.concat (List.map (fun f -> apply_query f value) fs) in
                        [`Vector result]
  | CollectMap fs -> let result = List.map (fun (kf, vf) -> (List.hd (apply_query kf value), List.hd (apply_query vf value))) fs in
                     [`Assoc result]
  | PassThrough pvalue -> [pvalue]
and apply_map query (value:edn) =
  match value with
    `List xs -> List.concat (List.map (apply_query query) xs)
  | `Vector xs -> List.concat (List.map (apply_query query) xs)
  | `Set xs -> List.concat (List.map (apply_query query) xs)
  | `Assoc kvs -> List.concat
                    (List.map
                       (fun (k, v) ->
                         apply_query query (`Vector [k;v]))
                       kvs)
  | rest -> apply_query query rest
