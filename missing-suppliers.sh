#!/bin/bash

currentDateTs=$(date +%s)
today=$(date -j -f "%s" $currentDateTs "+%Y-%m-%d")
offset=86400*7
currentDateTs=$(($currentDateTs-$offset))
lastweek=$(date -j -f "%s" $currentDateTs "+%Y-%m-%d")


url="https://hub.celtra.com/api/analytics?metrics=sessions,creativeLoads,creativeViews00,sessionsWithInteraction,interactions&dimensions=campaignName,creativeId,creativeName,supplierName&filters.accountDate.gte="$lastweek"&filters.accountDate.lte="$today"&filters.accountId=e97de0f9&sort=-sessions&limit=200"

curl -s -u "078735bc:a6028e865466e9299cc639e944e5dbc78c0fb8cc" $url | lsc ./../bin/jqlsc "(.rows)" | lsc ./../bin/jqlsc "map ( -> it  <<< ri: it.sessionsWithInteraction / it.creativeViews00)" | lsc ./../bin/jqlsc "sort-by (.creativeViews00)" | lsc ./../bin/missing-suppliers-json | lsc ./../bin/json-to-csv