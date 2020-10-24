
--[[
Copyright (c) 2020, Jonathan Lisic
BSD Clause 2

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]




-- read the xgboost booster from a text dump
function read_booster ( ml_file) 

  -- identify file to read in
  ml_handle = io.open(ml_file, "r")

  if ml_handle == nil then
    return(nil)
  end

  -- initialize booster
  booster_iter = 0
  booster = {}

  io.input(ml_handle)
  
  --for i = 1,30 do
  while true do
    -- read the current line
    cur_line = io.read()
    
    -- check if there is anything to read
    if cur_line == nil then 
      break
    end
  
    
    -- check if this is a new tree
    -- if it is a new tree we iterate
    if string.find( cur_line, "booster") ~= nil then 
  
      cur_node = {}
      booster_iter = booster_iter +1
      booster[booster_iter] = cur_node 
   
  
    -- take care of the leaf
    elseif string.find( cur_line, "leaf")  then
  
      -- get the node
      node=string.match(cur_line,"%d+:")
      node=string.gsub(node, ":", "")
      node=tonumber(node) +1
      
      -- if needed increase number of nodes
      if( table.getn(cur_node) < node ) then
        for j = (table.getn(cur_node)+1),node do
          cur_node[j] = {} 
        end
      end
  
      -- get the leaf value 
      leaf=string.match(cur_line,"[-]*%d+[.]%d+[%d.eE+-]*")
      if( leaf == nil ) then
        leaf=string.match(cur_line,"[-]*%d+")
      end
      cur_node[node].leaf = tonumber(leaf)
  
  
    --take care of splits
    else
  
      -- get the node
      node=string.match(cur_line,"%d+:")
      node=string.gsub(node, ":", "")
      node=tonumber(node) +1
  
      -- if needed increase number of nodes
      if( table.getn(cur_node) < node ) then
        for j = (table.getn(cur_node)+1),node do
          cur_node[j] = {} 
        end
      end
  
      
      -- get the feature (starts at 0)
      feature=string.match(cur_line,"f%d+")
      feature=string.gsub(feature,"f","")
      cur_node[node].feature=tonumber(feature) +1
      
      -- get the lt value
      lt_value=string.match(cur_line,"<[-]*%d+[.]*%d+[%d.eE+-]*")
      lt_value=string.gsub(lt_value,"<","")
      cur_node[node].lt_value=tonumber(lt_value)
     
      -- get the yes node 
      yes_node=string.match(cur_line,"yes=%d+")
      yes_node=string.gsub(yes_node,"yes=","")
      cur_node[node].yes_node=tonumber(yes_node) +1
  
      -- get the no node
      no_node=string.match(cur_line,"no=%d+")
      no_node=string.gsub(no_node,"no=","")
      cur_node[node].no_node=tonumber(no_node) +1
  
      -- get the missing node
      missing_node=string.match(cur_line,"missing=%d+")
      missing_node=string.gsub(missing_node,"missing=","")
      cur_node[node].missing_node=tonumber(missing_node) +1
  
    
    end
    
    
  
  end

  io.close(ml_handle)
  return(booster)

end
  

-- print the booster
function print_booster( booster) 
  for i = 1,table.getn(booster) do
    print("######## Booster Tree " .. i .. "########")
    for j = 1, table.getn(booster[i]) do
  
       if booster[i][j].lt_value ~= nil then
         print( "node:  ".. j .." ".. booster[i][j].feature.." "..booster[i][j].lt_value.." "..booster[i][j].yes_node.." "..booster[i][j].no_node.." "..booster[i][j].missing_node )
       elseif booster[i][j].leaf ~= nil then
         print( "node:  ".. j .. " " ..booster[i][j].leaf )
       else
         print( "node:  ".. j  )
       end
  
    end
  end
end





-- read csv for key words
function read_key_words ( key_file) 

  -- init return
  cur_phrases = {}

  -- identify file to read in
  key_handle = io.open(key_file, "r")


  io.input(key_handle)
  
  -- read the current line
  cur_line = io.read()
    
  -- check if there is anything to read
  if cur_line == nil then 
   return(nil) 
  end

  -- read in the first row of the file
  i = ""
  k = 1
  while( i ~= nil ) do
    
    i,j = string.find(cur_line,',')

    cur_phrase = string.sub(cur_line, 0,i)
    cur_phrase=string.gsub(cur_phrase, ",", "")
    cur_phrase=string.gsub(cur_phrase, "\"", "")
  
    cur_phrases[k] = cur_phrase

    if( i ~= nil) then
     cur_line = string.sub(cur_line,i+1)
    end

    k = k + 1

  end

  io.close(key_handle)

  return( cur_phrases )

end


function write_words(filename, phrases) 
  -- identify file to read in
  key_handle = io.open(filename, 'w')
  for i =1,table.getn(phrases) do
    key_handle:write(phrases[i]..'\n')
  end
  key_handle:close() 
end

function read_words(filename) 
  -- init return
  cur_phrases = {}

  -- identify file to read in
  key_handle = io.open(filename, "r")
  
  -- check if the file exists 
  if key_handle == nil then
    return cur_phrases
  end

  io.input(key_handle)
  
  -- read the current line
  cur_line = key_handle:read()
  i = 1 
  -- check if there is anything to read
  while cur_line ~= nil do
    cur_phrases[i] = cur_line
    cur_line = key_handle:read()
    i = i + 1
  end

  key_handle:close()

  return( cur_phrases )
end

--[[
                                                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                                          
# feature name                                                                                                                                                                                                                                                                            
add_features_names <- c('__gil','__currency','__jobs','__roles','__merc','__omen_big_drops','__omen_drops', 
i
'__mythic_merc'
"(tinnin|tyger|sarameya)"

'__abyssea_merc'
"(colorless|chloris|ulhuadshi|dragua|glavoid|itzpapalot|orthus|briareus|sobek|apademak|carabosse|cirein-croin|isgebind|fistule|bukhis|alfard|azdaja)"
'__htbm_merc'
"(daybreak|sacro|malignance|lilith|odin|gere|freke|palug|hjarrandi|zantetsuken|geirrothr)"
'__bazaar_loc'
"[(][a-z]-[1-9][)]"
'__bazaar_item'
"(blured|raetic|voodoo)"
'__dyna_item'
"(voidhead|voidleg|voidhand|voidfeet|beastman|kindred)"
'__vagary_boss'
"(vagary|perfidien|plouton|putraxia)" 
'__power_level'
"(^| )pl[ ]" 
"__aman_orbs"
"(mars|venus)[ ]orb" 
     
]]--

--[[

gil 
"(alexandrite|plouton|beitsu|riftborn|montiont|jadeshell|byne|bayld|heavy[ ]metal|hmp|hpb|riftcinder)"
jobs 
"(war|mnk|whm|rdm|blm|thf|pld|drk|bst|brd|rng|smn|sam|nin|drg|blu|cor|pup|dnc|sch|geo|run|warrior|monk|mage|theif|paladin|knight|beastmaster|bard|ranger|summoner|samurai|ninja|dragoon|corsair|puppet|dancer|scholar|geomancer|rune)"
roles 
"(support|healer|tank|dd|melee|job)"
merc 
"merc",test_train$msg, ignore.case = TRUE) )
omen_big_drops 
"(regal|dagon|udug|shamash|ashera|nisroch)"
omen_drops 
"(utu|ammurapi|niqmaddu|shulmanu|dingir|yamarang|lugalbanda|ilabrat|enmerkar|iskur|sherida)"
mythic_merc 
"(tinnin|tyger|sarameya)"
abyssea_merc 
"(colorless|chloris|ulhuadshi|dragua|glavoid|itzpapalot|orthus|briareus|sobek|apademak|carabosse|cirein-croin|isgebind|fistule|bukhis|alfard|azdaja)"
htbm_merc 
"(daybreak|sacro|malignance|lilith|odin|gere|freke|palug|hjarrandi|zantetsuken|geirrothr)"
bazaar_loc 
"[(][a-z]-[1-9][)]",test_train$msg, ignore.case = TRUE) )
bazaar_item 
"(blured|blurred|raetic|voodoo|jinxed|vexed)"
dyna_item 
"(voidhead|voidleg|voidhand|voidfeet|voidtorso|voidbody|beastman|kindred)"
job_points 
 as.numeric(grepl(
"(job points|jobpoints|merit points|meritpoint|experiencepoints|experience points|^exp[ ]|[ ]exp[ ])"
,test_train$msg, ignore.case 
 TRUE) )
power_level 
"(^| )pl[ ]" ,test_train$msg, ignore.case = TRUE) )
vagary_boss 
"(vagary|perfidien|plouton|putraxia)"
aman_orbs 
"(mars|venus)[ ]orb" ,test_train$msg, ignore.case = TRUE) )
dynamis 
"(dynamis|[d]|(d))"
content 
"(omen|kei|kyou|kin|gin|fu|[ ]ou|^ou|ambuscade|[ ]sr|^sr)"
buy 
"(buy[ ]|buy$|sell[?]|wtb|reward|price)"
sell 
"(sell[ ]|sell$|buy[?]|wts)"
social 
"(linkshell|schedule|event|social|^ls[ ]|[ ]ls[ ]|concierge)"



--]]

--build_features
build_features = function( clean_text, key_words )
  eval_features = {}
  
  for i = 1,table.getn(key_words) do
  
    key_word = key_words[i]
          
    eval_features[i] = 0 

    if key_word == '__gil' then
      if windower.regex.match(clean_text, "[0-9]+(k|m|gil)") ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == '__currency' then
      if windower.regex.match(clean_text,"(alexandrite|plouton|beitsu|riftborn|montiont|jadeshell|byne|bayld|heavy[ ]metal|hmp|hpb|riftcinder)") ~= nil then
        eval_features[i] = 1 
      end
    elseif key_word == '__jobs' then
      if windower.regex.match(clean_text, "(war|mnk|whm|rdm|blm|thf|pld|drk|bst|brd|rng|smn|sam|nin|drg|blu|cor|pup|dnc|sch|geo|run|warrior|monk|mage|theif|paladin|knight|beastmaster|bard|ranger|summoner|samurai|ninja|dragoon|corsair|puppet|dancer|scholar|geomancer|rune)") ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == '__roles' then
      if windower.regex.match(clean_text, 
        "(support|healer|tank|dd|melee|job)"
        ) ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == '__merc' then
      if windower.regex.match(clean_text, "merc") ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == '__omen_big_drops' then
      if windower.regex.match(clean_text, "(regal|dagon|udug|shamash|ashera|nisroch)") ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == '__omen_drops' then
      if windower.regex.match(clean_text, 
        "(utu|ammurapi|niqmaddu|shulmanu|dingir|yamarang|lugalbanda|ilabrat|enmerkar|iskur|sherida)") ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == "__mythic_merc" then
      if windower.regex.match(clean_text, "(tinnin|tyger|sarameya)") ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == '__abyssea_merc' then
      if windower.regex.match(clean_text, "(colorless|chloris|ulhuadshi|dragua|glavoid|itzpapalot|orthus|briareus|sobek|apademak|carabosse|cirein-croin|isgebind|fistule|bukhis|alfard|azdaja)" ) ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == '__htbm_merc' then
      if windower.regex.match(clean_text, "(daybreak|sacro|malignance|lilith|odin|gere|freke|palug|hjarrandi|zantetsuken|geirrothr)") ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == '__bazaar_loc' then
      if windower.regex.match(clean_text, "[(][a-z]-[1-9][)]") ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == '__bazaar_item' then
      if windower.regex.match(clean_text, "(blured|blurred|raetic|voodoo|jinxed|vexed)") ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == '__dyna_item' then
      if windower.regex.match(clean_text, "(voidhead|voidleg|voidhand|voidfeet|voidtorso|voidbody|beastman|kindred)") ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == '__job_points' then
      if windower.regex.match(clean_text, "(job points|jobpoints|merit points|meritpoint|experiencepoints|experience points|^exp[ ]|[ ]exp[ ])") ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == '__power_level' then
      if windower.regex.match(clean_text, "(^| )pl[ ]" ) ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == '__vagary_boss' then
      if windower.regex.match(clean_text, "(vagary|perfidien|plouton|putraxia)" ) ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == "__aman_orbs" then
      if windower.regex.match(clean_text, "(mars|venus)[ ]orb" ) ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == "__dynamis" then
      if windower.regex.match(clean_text, "(dynamis|[d]|(d))" ) ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == "__content" then
      if windower.regex.match(clean_text, "(omen|kei|kyou|kin|gin|fu|[ ]ou|^ou|ambuscade|[ ]sr|^sr)" ) ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == "__buy" then
      if windower.regex.match(clean_text, "(buy[ ]|buy$|sell[?]|wtb|reward|price)" ) ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == "__sell" then
      if windower.regex.match(clean_text, "(sell[ ]|sell$|buy[?]|wts)" ) ~= nil then 
        eval_features[i] = 1 
      end
    elseif key_word == "__social" then
      if windower.regex.match(clean_text, "(linkshell|schedule|event|social|^ls[ ]|[ ]ls[ ]|concierge)" ) ~= nil then 
        eval_features[i] = 1 
      end
    elseif string.find( clean_text, key_word) ~= nil then
      eval_features[i] = 1
    end
  
  end

  return( eval_features )
end 




-- print key words
print_features = function( values, key_words ) 
 

for i = 1,table.getn(key_words) do
  
    key_word = key_words[i]
    value = values[i] 

    if value ~= 0  then
      print( i..":\t "..value.."  "..key_word)
    end
  
  
  end

end




--evaluate tree
eval_tree = function( cur_node, booster, eval)



   if booster[cur_node].lt_value ~= nil then
     
     --print( (cur_node -1)..":  "..eval[booster[cur_node].feature].." < "..booster[cur_node].lt_value ) 
   
     if( eval[ booster[cur_node].feature ] < booster[cur_node].lt_value ) then
       cur_node = booster[cur_node].yes_node
     elseif( eval[ booster[cur_node].feature ] == 0 ) then
       cur_node = booster[cur_node].missing_node
     else
       cur_node = booster[cur_node].no_node
     end
     
   else
     --print("fin:  "..booster[cur_node].leaf)
     return( booster[cur_node].leaf)
   end

   return( eval_tree(cur_node, booster, eval) )

end




--parse tree
eval_phrase = function( value, booster,classes )  
  xgboost_class = 0 
  score={}
  for i = 1,classes do
    score[i] = 0.5
  end

  for i = 1,table.getn(booster) do
    xgboost_class = xgboost_class + 1
    
    -- scor
    if xgboost_class > classes then 
      xgboost_class = 1
--      print("######## Booster Tree " .. i .. " of " .. classes .. " ########")
    end
    score[xgboost_class] = score[xgboost_class] + eval_tree( 1, booster[i], value) 

  end

  sum_all = 0
  for i = 1,classes do
    sum_all = sum_all + math.exp(score[i])
    --sum_all = sum_all + score[i]
  end
  for i = 1,classes do
    score[i] = math.exp(score[i])/sum_all
    --score[i] = score[i]/sum_all
  end

  return(score)
end










