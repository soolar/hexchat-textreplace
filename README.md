# HexChat Text Replace
A text replacement plugin for HexChat

Requires the [HexChat Lua Interface](https://github.com/mniip/hexchat-lua).

## Installation
Place lua.so from HexChat Lua Interface and textreplace.lua from this repository in `~/.config/hexchat/addons` on Linux, or `%APPDATA%\\HexChat\\addons` on Windows.

## Commands
### `/textrepinput <text>`
Sets the current input text to the provided text. This text can be any arbitrary amount of text, including multiple words. Whenever this text shows up in almost any message, it will be replaced with whatever output you then specify with `/textrepoutput`.

Exceptions to replacement are generally messages where exact text matters, such as ban addresses, and other general system messages.

### `/textrepoutput <text>`
Sets the replacement text for the current input. If used with no arguments provided, it will clear the current input from being replaced, if it is already in use.

### `/dumprepls`
Prints out a list of all current replacements.

## Example
Take the following conversation, before setting up any replacements with this script:

```
<Alice> Hi Bob, how is it going?
<Bob> Oh, fine Alice, how has your day been?
<Alice> Oh, fine, just doing a little test with this HexChat addon.
```

Now let's execute the following commands:

```
/textrepinput test
/textrepoutput success
/textrepinput Alice
/textrepoutput A
/textrepinput Bob
/textrepoutput B
```

Now, if the same conversation were to happen, it would look like this:

```
<A> Hi B, how is it going?
<B> Oh, fine A, how has your day been?
<A> Oh, fine, just doing a little success with this HexChat addon.
```

If we then typed `/dumprepls`, the output would look like this:

```
test -> success
Alice -> A
Bob -> B
```

Note that you can do more advanced things, such as providing nickname coloration by adding color codes to the output, but you can generally only modify how nicknames and message text display, not system things like the format of a join or part message (aside from the nickname and/or the part reason). Also, channel names are generally excluded.

## Notes
All inputs are case sensitive! However, you can leverage the full power of [patterns](http://www.lua.org/manual/5.2/manual.html#6.4.1) and the [gsub](http://www.lua.org/manual/5.2/manual.html#pdf-string.gsub) function, if you feel the need! Keep in mind that the order of execution of the replacements is not guaranteed to stay the same as you add new replacements, so you *CAN NOT* reliably count on order of execution to pull stunts with what order things are replaced in, sorry!

## Known Issues
1. Using this to provide alternate names for your friends (for example) will remove the ability to right click their name in chat for the popup window.
2. It WILL modify channel names in the body of messages, which can be confusing, and prevents double clicking the channel name to join it (or more specifically, makes it so you'll join the wrong channel, which could be awkward).
3. Is not smart enough to avoid modifying the body of a URL, yet.
4. Does not allow for coloration/nicknaming in the userlist of a channel, which I believe is utterly impossible with the Lua HexChat addition I am using, but I have not looked in to that thoroughly yet. However, even if it was possible, I'm not sure if that would be a good idea, because of issue #1.
