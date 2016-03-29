hexchat.register("Text Replace", 0.1, "Sets up mappings to replace certain text in most events, such as for coloration or nicknaming.")

local conffilename = hexchat.get_info("configdir") .. "/" .. "addon_text_replace.conf"

repls = {}

local conf = io.open(conffilename,"r")
local pat
for line in conf:lines() do
  if not pat then
    pat = line
  else
    repls[pat] = line
    pat = nil
  end
end
conf:close()

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
          for pat,repl in pairs(repls) do
            arg = arg:gsub(pat,repl .. "" .. (suffixes[i] or ""))
          end
          args[i] = arg
        end
      end

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

addhook("Channel Action", { "17", "17", false, false })
addhook("Channel Action Hilight", { "04", "04", false, false })
addhook("Channel Message", { "25", "", false, false })
addhook("Channel Msg Hilight", { "04", "04", false, false })
addhook("Channel Notice", { "30", false, "21" })
addhook("Join", { "18", false, false })
addhook("Notice", { "30", "21" })
addhook("Notice Send", { "30", "21" })
addhook("Notify Away", { "18", "24" })
addhook("Notify Back", { "18" })
addhook("Notify Offline", { nil, false, false })
addhook("Notify Online", { nil, false, false })
addhook("Part", { "30", false, false })
addhook("Part with Reason", { "30", false, false, nil })
addhook("Private Action", { "18", nil, false })
addhook("Private Action to Dialog", { "18", nil, false })
addhook("Private Message", { "29", nil, false })
addhook("Private Message to Dialog", { "28", nil, false })
addhook("Quit", {"31", nil, false })
addhook("Topic", { false, "22" })
addhook("Topic Change", { nil, nil, false })
addhook("Topic Creation", { false, "22", false })
addhook("Your Action", { "17", "17", false })
addhook("Your Message", { "19", nil, false, false })

hexchat.hook_command("DUMPREPLS", function()
  for k,v in pairs(repls) do
    print(k, "->", v)
  end

  return hexchat.EAT_ALL
end, "Usage: DUMPREPLS, outputs all replacements set up for Text Replace to the current window.")

local function saverepls()
  local conf = io.open(conffilename, "w")
  for k,v in pairs(repls) do
    conf:write(k,"\n",v,"\n")
  end
  conf:close()
end

local repin

hexchat.hook_command("TEXTREPINPUT", function(words,wordeols)
  repin = wordeols[2]
  print("Input phrase set to \"" .. repin .. "\"")
  return hexchat.EAT_ALL
end, "Usage: TEXTREPINPUT <text>, sets the current input phrase for Text Replace. Use with SETTEXTREPOUT to add a new text replacement, or change an existing one.")

hexchat.hook_command("TEXTREPOUTPUT", function(words,wordeols)
  if not repin then
    print("Use TEXTREPINPUT first!")
    return hexchat.EAT_ALL
  end
  if not wordeols[2] and repls[repin] then
    print("Text Replacement 4removed: \"" .. repin .. "\" -> \"" .. repls[repin] .. "\"")
  end
  repls[repin] = wordeols[2]
  if wordeols[2] then
    print("Text Replacement created: \"" .. repin .. "\" -> \"" .. wordeols[2] .. "\"")
  end
  saverepls()
  return hexchat.EAT_ALL
end, "Usage: TEXTREPOUTPUT <text>, sets up a replacement so that whatever text was specified by TEXTREPINPUT will be replaced with the text provided to this command. Does not work without having called TEXTREPINPUT in the first place. Call with no arguments to delete a given replacement.")

