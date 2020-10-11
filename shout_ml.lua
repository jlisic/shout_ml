--[[
Copyright (c) 2020, Jonathan Lisic
BSD Clause 2

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]


_addon.name = 'shout_ml'
_addon.version = '0.6'
_addon.author = 'Epigram (Asura)'
_addon.command = 'sml'


require('luau')
require('xgboost_score')
texts = require('texts')
packets = require('packets')
config = require('config')
bit = require('bit')

---------------------------------- load defaults ----------------------------
defaults = {}
defaults.display = {}
defaults.display.pos = {}
defaults.display.pos.x = 100 
defaults.display.pos.y = 100 
defaults.display.bg = {}
defaults.display.bg.red = 0
defaults.display.bg.green = 0
defaults.display.bg.blue = 0
defaults.display.bg.alpha = 255 
defaults.display.text = {}
defaults.display.text.font = 'Consolas'
defaults.display.text.red = 255
defaults.display.text.green = 255
defaults.display.text.blue = 255
defaults.display.text.alpha = 255
defaults.display.text.size = 12

-- initial thresholds
defaults.xgboost = {}
defaults.xgboost.class_threshold = {1.0,0.5,0.5,0.5,1.0,1.0,1.0,1.0}

-- initial allow list

settings = config.load(defaults)
settings:save() -- make sure we save initial 


-- create initial conditions
xgboost_classes = 8
xgboost_booster = {}
xgboost_key_words = {}
xgboost_debug = false

xgboost_class_names = {'Content','RMT','Merc','JP Merc','Chat','Selling (non-Merc)','Buying (non-Merc)','Unknown'}
xgboost_players = {}

-- get player names
player = windower.ffxi.get_player()
player_name      = player['name']


xgboost_allow_list = read_words( windower.addon_path.."data/ffxi_allow_list_"..player_name..".txt")

-- create out box
--[[
shout_box = texts.new(settings.display, settings)

shout_box:register_event('reload', function(text, settings)

    local properties = L{}
    properties:append('Player    Message             ')
    for i=1,table.getn(xgboost_players) do
      properties:append('${xgboost_players[i]|-|%08s}')
    end

    text:clear()
    text:append(properties:concat('\n'))
    shout_box:show()
end)
]]--



-- on load
windower.register_event('load',function()

  -- load ffxi booster
  xgboost_booster = read_booster( windower.addon_path.."ffxi_spam_model.txt")
       
  if xgboost_booster == nil then
    windower.send_command('input /echo "cannot load file"')
  else
    -- read in ffxi booster
    xgboost_key_words = read_key_words( windower.addon_path.."example.csv"  )
  end  

end)




-- on shout
windower.register_event('incoming chunk', function(id,data)
  if id == 0x017 then

    -- get the basic chat
    local chat = packets.parse('incoming', data)

    -- clean up chat for scoring
    local clean_text = windower.convert_auto_trans(chat['Message']):lower()
     
    -- check if it is a yell (maye I should add more cats later
    if (chat['Mode'] == 26) or (chat['Mode'] == 1) then


      shouter = chat['Sender Name']

      -- if we can't score we are done
      if booster == nil then
        return nil 
      end

      -- check if there is an allow list option
      for i=1,table.getn(xgboost_allow_list) do
        if windower.regex.match( clean_text, xgboost_allow_list[i]:lower() ) ~= nil then
          return 
        end
      end


      -- calculate 
      xgboost_value = build_features( clean_text, xgboost_key_words )
      class_score = eval_phrase( xgboost_value, xgboost_booster,xgboost_classes) 
      max_score = 0
      max_class = 1

      for i = 1,xgboost_classes do

        if( class_score[i] > max_score ) then
          max_score = class_score[i]
          max_class = i
        end

      end

      if xgboost_debug then
        windower.add_to_chat(55,'Shout Type:  '..xgboost_class_names[max_class]..', Probability = '.. max_score.. ' threshold = '..settings.xgboost.class_threshold[max_class])
      end

      -- block if above a threshold
      if max_score > settings.xgboost.class_threshold[max_class] then
        return true 
      end

    end
  end
end)




--  self commands
windower.register_event('addon command', function(command, ...)
  command = command and command:lower() 
  local args = L{...}

  -- help
  if command == 'help' or command == 'h' then
        windower.add_to_chat(55,'All yells are classified into one of eight')
        windower.add_to_chat(55,'categories using machine learning.')
        windower.add_to_chat(55,' ')
        windower.add_to_chat(55,'Categories:')
        windower.add_to_chat(55,'(1) Content,  (2) RMT,                 (3) Merc,              (4) JP Merc')
        windower.add_to_chat(55,'(5) Chat,     (6) Selling (non-Merc),  (7) Buying (non-Merc), (8) Unknown')
        windower.add_to_chat(55,' ')
        windower.add_to_chat(55,'Set Threshold:')
        windower.add_to_chat(55,'  t (class 1-8) (threshold 0.0 - 1.0 [default 0.9])')
        windower.add_to_chat(55,'A higher threshold the less of a chance of seeing this type of yell')
        windower.add_to_chat(55,'Set to 0 to deny all, and 1 to allow all of a yell type.')
        windower.add_to_chat(55,' ')
        windower.add_to_chat(55,'Add Allow-List Phrase:')
        windower.add_to_chat(55,'  a "phrase"')
        windower.add_to_chat(55,'Adds a new phrase to the allow-list to skip classification.')
        windower.add_to_chat(55,' ')
        windower.add_to_chat(55,'Remove Allow-List Phrase:')
        windower.add_to_chat(55,'  r (phrase index)')
        windower.add_to_chat(55,'Remove phrase from allow list.')
        windower.add_to_chat(55,' ')
        windower.add_to_chat(55,'Show Status: status or s')
        windower.add_to_chat(55,' ')
        windower.add_to_chat(55,'Set Debug Mode: debug or d')
        return
  end
  
  if command == 'status' or command == 's' then
        windower.add_to_chat(55,'Categories:')
        windower.add_to_chat(55,'(1) Content '..settings.xgboost.class_threshold[1])
        windower.add_to_chat(55,'(2) RMT '..settings.xgboost.class_threshold[2])
        windower.add_to_chat(55,'(3) Merc '..settings.xgboost.class_threshold[3])
        windower.add_to_chat(55,'(4) JP Merc '..settings.xgboost.class_threshold[4])
        windower.add_to_chat(55,'(5) Chat '..settings.xgboost.class_threshold[5])
        windower.add_to_chat(55,'(6) Selling (non-Merc) '..settings.xgboost.class_threshold[6])
        windower.add_to_chat(55,'(7) Buying (non-Merc) '..settings.xgboost.class_threshold[7])
        windower.add_to_chat(55,'(8) Unknown '..settings.xgboost.class_threshold[8])
        windower.add_to_chat(55,'Allow-List:')
        for i = 1,table.getn(xgboost_allow_list) do
          windower.add_to_chat(55,"("..i..") "..xgboost_allow_list[i])
        end
        return
  end

  -- threshold
  if command == 'threshold' or command == 't' then
    if args[1] then

      new_threshold = tonumber( args[2] )
      threshold_class = tonumber( args[1] )

      if (new_threshold == nil) or (threshold_class == nil)  then
        windower.add_to_chat(55,'Not a valid threshold or class'..args[1]..' '..args[2])
        return
      end

      threshold_class = math.floor(threshold_class)
      
      if (threshold_class < 1) or (threshold_class > 8)  then
        windower.add_to_chat(55,'Not a valid class'..threshold_class)
        return
      end

      settings.xgboost.class_threshold[threshold_class] = new_threshold
      windower.add_to_chat(55,'New Threshold for class '..xgboost_class_names[threshold_class].. ' = '..new_threshold) 

      settings:save() -- save settings 
      return

    end
  end
  
  -- allow list
  if command == 'allow' or command == 'a' then
    if args[1] then

      new_allow = tostring(args[1])
      table.insert(xgboost_allow_list, new_allow )
      write_words( windower.addon_path.."data/ffxi_allow_list_"..player_name..".txt", xgboost_allow_list)
      windower.add_to_chat(55,'Adding allow list item: '..new_allow) 
    end
    return
  end
  
  -- allow list
  if command == 'remove' or command == 'r' then
    if args[1] then
      xgboost_index = tonumber(args[1])
      if xgboost_index ~= nil then
        if (xgboost_index > 0) and (xgboost_index <= table.getn(xgboost_allow_list) ) then
          windower.add_to_chat(55,'Removed allow list item: '..xgboost_allow_list[xgboost_index]) 
          table.remove(xgboost_allow_list, xgboost_index )
          -- add it to settings
          write_words( windower.addon_path.."data/ffxi_allow_list_"..player_name..".txt", xgboost_allow_list)
        else
          windower.add_to_chat(55,'Is not a valid index '.. xgboost_index) 
        end
      end
    end
    return
  end

  -- debug mode
  if command == 'debug' or command == 'd' then
    if xgboost_debug then
      xgboost_debug = false
        windower.add_to_chat(55,'Debug OFF')
    else 
      xgboost_debug = true
      windower.add_to_chat(55,'Debug ON')
    end
    return
  end


end)




