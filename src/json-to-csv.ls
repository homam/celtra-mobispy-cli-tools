#!/usr/local/bin/lsc -d
{map, filter, foldl, id, Obj, Str, any, all, difference, unique-by, concat-map, obj-to-pairs} = require \prelude-ls

is-array = (o) -> "[object Array]" == Object.prototype.toString.call o
is-string = (o) -> "[object String]" == Object.prototype.toString.call o
is-primary = (o) ->
  type = Object.prototype.toString.call o
  ['String', 'Number', 'Boolean'] |> map (-> "[object #it]") |> any (== type)


# (a -> String -> (o -> a')) -> [{func : (o -> a'), name : String}]
keys = (o, prefix = "", selector = id) -> 
  return [func: selector, name: prefix] if !o or Obj.empty o or is-primary o
  kvs = Obj.obj-to-pairs o
  kvs |> concat-map ([k, v]) -> 
    keys v, (if prefix == "" then "" else prefix + "-") +  k, selector >> -> it?[k]


# o -> primary-value or null
csv-cell = (s) ->
  return "" if s is null
  return "\"#s\"" if is-string s and (s.indexOf ' ') > -1
  s


# [x] -> String
unwinded-json-to-csv = (arr) ->
  all-keys = arr |> concat-map keys
  max-keys = all-keys |> unique-by (.name)
 
  values = [(max-keys |> map (.name))] ++ foldl ((acc, a) -> acc ++ [max-keys |> map (.func a)]), [], arr 
  values |> map (map csv-cell) >> (Str.join ',') |> Str.join "\n"


# String -> b -> o -> [unwind ... b <<< o] or b <<< o
unwind = (prefix, baggage, obj) -->

  prefixify = (p) ->
    (if prefix == "" then "" else prefix + "-") + p

  return concat-map (unwind prefix, {} <<< baggage), obj if is-array obj

  obj-keys = Obj.keys obj
  array-props = obj-keys |> filter (-> is-array obj[it] and not (all is-primary, obj[it]))
  non-array-props = obj-keys `difference` array-props
  non-array-object = non-array-props |> foldl ((o, p) -> o[prefixify p] = obj[p]; o), {}

  return {} <<< baggage <<< non-array-object if array-props.length == 0

  array-props |> concat-map (p) -> 
    obj[p] |> concat-map unwind (prefixify p), {} <<< baggage <<< non-array-object


json-to-csv = (obj) ->
  (unwind "", {}, obj) |> unwinded-json-to-csv


module.exports = json-to-csv

# solar-system = [
#   {pname: 'jupiter', mass: 5, satellites: [
#     {sname: 'ganymede', color: 'orange', craters: [
#       {size: 4, location: {x: 12, y: 33}, orbits: [{gamma:3, alpha: 4},{gamma: 5, alpha: -1}]}
#       {size: 12, location: {x: -37, y: -55}}
#       ]}
#     {sname: 'europa', color: 'white'}
#     {sname: 'io', color: 'red', volcanos: ['vol1', 'vol2']}
#     ]}
#   {pname: 'saturn', mass: 3, satellites: [
#     {sname: 'titan', color: 'yellow', atmosphere: [{gas: 'Hydrogen'},{gas: 'Helium'}]}
#     {sname: 'mimas', color: 'gray'}
#     ]}
# ]


# #process.stdout.write <| JSON.stringify (unwind "", {}, solar-system), null, 4
# process.stdout.write <| json-to-csv solar-system 
# process.stdout.write "\n"
