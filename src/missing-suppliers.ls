#!/usr/local/bin/lsc -d

{map, unique, foldl, Obj, obj-to-pairs, group-by, difference} = require \prelude-ls
# data = require \./data/missing-suppliers.json


make-report = (data) -> 

	suppliers = data |> map (.supplierName) |> unique

	suppliers = data |> foldl do 
		(acc, a) -> 
			acc[a.supplierName].sessions += a.sessions
			acc[a.supplierName].sessionsWithInteraction += a.sessionsWithInteraction
			acc
		suppliers |> foldl do 
			(acc, a) -> acc[a] = {sessions: 0, sessionsWithInteraction: 0}; acc
			{}


	suppliers = suppliers |> Obj.map (-> it <<< interactionRate: it.sessionsWithInteraction / it.sessions)

	bad-suppliers  = suppliers |> Obj.filter (.interactionRate < 0.01)
	good-suppliers = suppliers |> Obj.filter (.interactionRate >= 0.01)
	good-suppliers-names = Obj.keys good-suppliers



	data |> group-by (.creativeName) 
	|> Obj.map map (-> supplierName: it.supplierName, sessions: it.sessions, interactionRate: it.sessionsWithInteraction / it.sessions)
	|> Obj.map (arr) ->
		arr ++ ((good-suppliers-names `difference` map (.supplierName), arr) |> map -> supplierName: it, sessions: 0, interactionRate: 0)
	|> obj-to-pairs
	|> map ([creativeName, suppliers]) -> creativeName: creativeName, suppliers: suppliers


module.exports = make-report
