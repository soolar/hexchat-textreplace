hexchat.register("Text Replace", 0.1, "Sets up mappings to replace certain text in most events, such as for coloration or nicknaming.")

local conffilename = hexchat.get_info("configdir") .. "/" .. "addon_text_replace.conf"

-- incredibly oversimplified URL pattern, I'll make it more complex
-- if that turns out to be a problem.
local urlpattern = "%S*%a%S*%.%a%S*[^%s)]"
-- see https://tools.ietf.org/html/rfc2812#section-1.3
local chanpattern = "#" .. string.rep("[^ \x07,]", 49, "?")

local repls = {}
local prfxs = {}

local delimiters = { [repls] = "\x01", [prfxs] = "\x04" }

-- load from the config file
do
  local conf = io.open(conffilename,"r")
  local conftext = conf:read("*a")
  conf:close()
  local storepattern = {"","([^","\n]+)","([^","\n]+)","\n"}
  for t,delimiter in pairs(delimiters) do
    for a,b in conftext:gmatch(table.concat(storepattern,delimiter)) do
      t[a] = b
    end
  end
end

-- creates a hook callback to be used for the given event
-- suffixes will append to numerically matching replacements
-- also, if a suffix is false, that argument will not be parsed
-- which... makes the name kind of confusing, but oh well.
local function makehook(event, suffixes)
  -- the hook can be toggled, so that it can generate an event of its
  -- own type without catching it itself and creating an infinite loop
  local enabled = true
  suffixes = suffixes or {}

  local function hook(args)
    if enabled then
      -- some debug printing
      --for k,v in pairs(args) do print(k,v) end

      for i,arg in pairs(args) do
        if suffixes[i] ~= false then
          local protected = {}
          local protcount = 0
          local function protect(text)
            -- debug print
            -- print("PROT\t" .. text)
            protcount = protcount + 1
            protected[tostring(protcount)] = text
            return "\x00" .. protcount .. "\x00"
          end
          -- strip out and preserve URLs and channel names
          arg = arg:gsub(urlpattern, protect)
          arg = arg:gsub(chanpattern, protect)
          -- now replace any pattern matches
          for pat,repl in pairs(repls) do
            arg = arg:gsub(pat,repl)
          end
          -- now evaluate for any prefixes
          for pat,pre in pairs(prfxs) do
            arg = arg:gsub(pat,pre .. "%0\x0f" .. (suffixes[i] or ""))
          end
          -- restore URLs and channel names
          arg = arg:gsub("\x00(%d+)\x00", protected)
          args[i] = arg
        end
      end

      -- re-emit the event with the modified arguments,
      -- with this hook temporarily disabled, so that it won't
      -- go in to a terrible infinite loop
      enabled = false
      hexchat.emit_print(event, table.unpack(args))
      enabled = true
      return hexchat.EAT_ALL
    end
    return hexchat.EAT_NONE
  end

  return hook
end

local function addhook(event, suffixes)
  hexchat.hook_print(event, makehook(event, suffixes), hexchat.PRI_HIGHEST)
end

addhook("Channel Action", { "\x0317", "\x0317", false, false })
addhook("Channel Action Hilight", { "\x02\x0304", "\x0304", false, false })
addhook("Channel Message", { "\x0325", "", false, false })
addhook("Channel Msg Hilight", { "\x0304", "\x0304", false, false })
addhook("Channel Notice", { "\x0330", false, "\x0321" })
addhook("Join", { "\x0318", false, false })
addhook("Notice", { "\x0330", "\x0321" })
addhook("Notice Send", { "\x0330", "\x0321" })
addhook("Notify Away", { "\x0318", "\x0324" })
addhook("Notify Back", { "\x0318" })
addhook("Notify Offline", { nil, false, false })
addhook("Notify Online", { nil, false, false })
addhook("Part", { "\x0330", false, false })
addhook("Part with Reason", { "\x0330", false, false, nil })
addhook("Private Action", { "\x0318", nil, false })
addhook("Private Action to Dialog", { "\x0318", nil, false })
addhook("Private Message", { "\x0329", nil, false })
addhook("Private Message to Dialog", { "\x0328", nil, false })
addhook("Quit", {"\x0331", nil, false })
addhook("Topic", { false, "\x0322" })
addhook("Topic Change", { nil, nil, false })
addhook("Topic Creation", { false, "\x0322", false })
addhook("Your Action", { "\x0317", "\x0317", false })
addhook("Your Message", { "\x0319", nil, false, false })

hexchat.hook_command("TEXTREPLACEDUMP", function()
  print("repls\t---------------------")
  for k,v in pairs(repls) do
    print(k, "->", v)
  end
  print("prfxs\t---------------------")
  for k,v in pairs(prfxs) do
    k = k:gsub("%[(%a)%a%]","%1")
    print(k, "->", v .. k .. "\x0f")
  end

  return hexchat.EAT_ALL
end, "Usage: TEXTREPLACEDUMP, outputs all replacements set up for Text Replace to the current window.")

local function save()
  local conf = io.open(conffilename, "w")
  for t,delimiter in pairs(delimiters) do
    for k,v in pairs(t) do
      conf:write(delimiter,k,delimiter,v,delimiter,"\n")
    end
  end
  conf:close()
end

local repin

local textrepusage = "Usage: TEXTREP <input> <output>, sets input to be replaced by output whenever it shows up. Input in this case can only be one word, but output can be as many as you want. See TEXTREPINPUT and TEXTREPOUTPUT if you need a multiple word input."
hexchat.hook_command("TEXTREP", function(words,wordeols)
  if #words < 3 then
    print(textrepusage)
    return hexchat.EAT_ALL
  end
  print("Text Replacement created: \"" .. words[2] .. "\x0f\" -> \"" .. wordeols[3] .. "\x0f\"")
  repls[words[2]] = wordeols[3]
  save()
  return hexchat.EAT_ALL
end, textrepusage)

hexchat.hook_command("TEXTREPINPUT", function(words,wordeols)
  repin = wordeols[2]
  print("Input phrase set to \"" .. repin .. "\x0f\"")
  return hexchat.EAT_ALL
end, "Usage: TEXTREPINPUT <text>, sets the current input phrase for Text Replace. Use with SETTEXTREPOUT to add a new text replacement, or change an existing one.")

hexchat.hook_command("TEXTREPOUTPUT", function(words,wordeols)
  if not repin then
    print("Use TEXTREPINPUT first!")
    return hexchat.EAT_ALL
  end
  if not wordeols[2] and repls[repin] then
    print("Text Replacement \x034removed\x03: \"" .. repin .. "\x0f\" -> \"" .. repls[repin] .. "\"")
  end
  repls[repin] = wordeols[2]
  if wordeols[2] then
    print("Text Replacement created: \"" .. repin .. "\x0f\" -> \"" .. wordeols[2] .. "\x0f\"")
  end
  save()
  return hexchat.EAT_ALL
end, "Usage: TEXTREPOUTPUT <text>, sets up a replacement so that whatever text was specified by TEXTREPINPUT will be replaced with the text provided to this command. Does not work without having called TEXTREPINPUT in the first place. Call with no arguments to delete a given replacement.")

hexchat.hook_command("PREFIX", function(words,wordeols)
  local pat = words[2]
  local pre = wordeols[3]
  if not pre then
    print("Please provide at least two arguments!")
    return hexchat.EAT_ALL
  end
  pat = pat:gsub("%a",function(letter)
    return "[" .. string.lower(letter) .. string.upper(letter) .. "]"
  end)
  prfxs[pat] = pre
  save()
end, "Usage: PREFIX <text> <prefix>, whenever text (one word maximum) is found in a message, it will have prefix placed immediately before it. Unlike TEXTREP, this is case insensitive!")


