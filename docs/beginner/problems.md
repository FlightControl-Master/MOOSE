---
parent: Beginner
nav_order: 05
---

# Problems
{: .no_toc }

1. Table of contents
{:toc}

## Something went wrong

If the mission shows not the expected behavior do the following steps:

1. Double check if you added the changed mission script to the mission again!
1. Check if the triggers are configured as requested in the last sections:
  - To load MOOSE: `4 MISSION START`, nothing on `CONDITIONS`, `DO SCRIPT FILE` to load `Moose_.lua`.
  - To load mission script(s): `1 ONCE`, in `CONDITIONS` add `TIME MORE` = 1, `DO SCRIPT FILE` to load `yourscript.lua`.
1. Double check if you have the right version of MOOSE (some classes need the develop branch).
1. Try the newest version of MOOSE.

## Read the logs

The DCS log is a super important and useful log for the entire of DCS World.
All scripting and other errors are recorded here. It is the one stop shop for
things that occurred in your mission. It will tell you if there was a mistake.

1. Open the file `dcs.log` in the `Logs` subfolder in your DCS [Saved Games folder].

1. Search for the following line: `*** MOOSE INCLUDE END ***`
  - If it is included in the log, Moose was loaded.
  - If the line is not in the log check the triggers again!

1. Search for lines with `SCRIPTING` and `WARNING` or `ERROR` and read them.
  - This might help to find your error.

    {: .note }
    > You will find a lot of warning and error lines in the log which are not
    > related to `SCRIPTING`. They are related to stuff from Eagle Dynamics or
    > Third Parties and you have to ignore them. EA does the same. ;o)

## Next step

If you don't find the error and/or don't understand the messages in the log file
you can [ask for help].

[Saved Games folder]: tipps-and-tricks.md#find-the-saved-games-folder
[ask for help]: ask-for-help.md
