
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




--build_features
build_features = function( clean_text, key_words )
  eval_features = {}
  
  for i = 1,table.getn(key_words) do
  
    key_word = key_words[i]
  
    if string.find( clean_text, key_word) ~= nil then
      eval_features[i] = 1
    else
      eval_features[i] = 0 
    end
  
  end

  return( eval_features )
end 




-- print key words
print_features = function( values, key_words ) 
 

  for i = 1,table.getn(key_words) do
  
    key_word = key_words[i]
    value = values[i] 

    print( i..":\t "..value.."  "..key_word)
  
  
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
--    print("class:  "..class.." score:  "..score[class]) 

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


