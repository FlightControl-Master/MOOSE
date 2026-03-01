---
-- @field Messages
CTLD.Messages = {
    EN = {
        -- ============================================================
        -- Crate / Cargo Loading
        -- ============================================================
        CRATE_LOADED_GROUNDCREW         = "Crate %s loaded by ground crew!",
        CRATE_UNLOADED_GROUNDCREW       = "Crate %s unloaded by ground crew!",
        CRATE_LOADED_ID                 = "Crate ID %d for %s loaded!",
        LOADED_FULL                     = "Loaded %d %s.",
        LOADED_SETS_LEFTOVER            = "Loaded %d %s(s), with %d leftover crate(s).",
        LOADED_SETS                     = "Loaded %d %s(s).",
        LOADED_PARTIAL                  = "Loaded only %d/%d crate(s) of %s.",
        LOADED_PARTIAL_LIMIT            = "Loaded only %d/%d crate(s) of %s. Cargo limit is now reached!",
        LOADED_BATCH                    = "Loaded %d %s.",
        LOADED_BATCH_PARTIAL            = "Some sets could not be fully loaded.",
        -- ============================================================
        -- Dropping / Unloading
        -- ============================================================
        DROPPED_FULL                    = "Dropped %d %s.",
        DROPPED_SETS_LEFTOVER           = "Dropped %d %s(s), with %d leftover crate(s).",
        DROPPED_SETS                    = "Dropped %d %s(s).",
        DROPPED_PARTIAL                 = "Dropped %d/%d crate(s) of %s.",
        DROPPED_INTO_ACTION             = "Dropped %s into action!",
        DROPPED_BEACON                  = "Dropped %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        CRATES_POSITIONED               = "%d crates for %s have been positioned near you!",
        CRATES_DROPPED                  = "%d crates for %s have been dropped!",
        -- ============================================================
        -- Troops
        -- ============================================================
        BOARDED                         = "%s boarded!",
        BOARDING                        = "%s boarding!",
        TROOPS_RETURNED                 = "Troops have returned to base!",
        -- ============================================================
        -- Deployment
        -- ============================================================
        DEPLOYED_NEAR_YOU               = "%s have been deployed near you!",
        UNITS_REMOVED                   = "%s have been removed",
        -- ============================================================
        -- Build / Repair
        -- ============================================================
        BUILD_STARTED                   = "Build started, ready in %d seconds!",
        REPAIR_STARTED                  = "Repair started using %s taking %d secs",
        NO_UNIT_TO_REPAIR               = "No unit close enough to repair!",
        CANT_REPAIR_WITH                = "Can't repair this unit with %s",
        CRATES_MOVE_BEFORE_BUILD        = "*** Crates need to be moved before building!",
        -- ============================================================
        -- Errors - Chopper / Weight / Capacity
        -- ============================================================
        CHOPPER_CANNOT_CARRY            = "Sorry this chopper cannot carry crates!",
        TOO_HEAVY                       = "Sorry, that's too heavy to load!",
        FULLY_LOADED                    = "Sorry, we are fully loaded!",
        CRAMMED                         = "Sorry, we're crammed already!",
        NO_CAPACITY_NOW                 = "No capacity to load more now!",
        NO_MORE_CAPACITY                = "No more capacity to load crates!",
        CANNOT_LOAD_NONE_OR_FULL        = "Cannot load crates: either none found or no capacity left.",
        -- ============================================================
        -- Errors - Position
        -- ============================================================
        NEED_TO_LAND_OR_HOVER_LOAD      = "You need to land or hover in position to load!",
        HOVER_OVER_CRATES               = "Hover over the crates to pick them up!",
        LAND_OR_HOVER_OVER_CRATES       = "Land or hover over the crates to pick them up!",
        MUST_LAND_OR_HOVER_CRATES       = "You must land or hover to load crates!",
        NEED_TO_LAND_BUILD              = "You need to land / stop to build something, Pilot!",
        NOT_CLOSE_ENOUGH_LOGISTICS      = "You are not close enough to a logistics zone!",
        NOT_CLOSE_ENOUGH_DROP           = "You are not close enough to a drop zone!",
        NOT_CLOSE_ENOUGH_ZONE_NM        = "Negative, need to be closer than %dnm to a zone!",
        CANNOT_BUILD_LOADING_AREA       = "You cannot build in a loading area, Pilot!",
        -- ============================================================
        -- Errors - Doors
        -- ============================================================
        OPEN_DOORS_LOAD_CARGO           = "You need to open the door(s) to load cargo!",
        OPEN_DOORS_LOAD_TROOPS          = "You need to open the door(s) to load troops!",
        OPEN_DOORS_EXTRACT_TROOPS       = "You need to open the door(s) to extract troops!",
        OPEN_DOORS_UNLOAD_TROOPS        = "You need to open the door(s) to unload troops!",
        OPEN_DOORS_DROP_CARGO           = "You need to open the door(s) to drop cargo!",
        -- ============================================================
        -- Errors - Stock / Availability
        -- ============================================================
        ALL_GONE                        = "Sorry, all %s are gone!",
        RAN_OUT_OF                      = "Sorry, we ran out of %s",
        CARGO_NOT_AVAILABLE_ZONE        = "The requested cargo is not available in this zone!",
        ENOUGH_CRATES_NEARBY            = "There are enough crates nearby already! Take care of those first!",
        NO_CRATES_WITHIN                = "No (loadable) crates within %d meters!",
        NO_CRATES_WITHIN_PLAIN          = "No crates within %d meters!",
        NO_CRATES_IN_RANGE              = "No crates found in range!",
        NO_NAMED_CRATES_IN_RANGE        = "No \"%s\" crates found in range!",
        NO_LOADABLE_CRATES              = "Sorry, no loadable crates nearby or max cargo weight reached!",
        NO_UNITS_TO_EXTRACT             = "No units close enough to extract!",
        NO_UNIT_CONFIG                  = "No unit configuration found for %s",
        CANT_ONBOARD                    = "Can't onboard %s",
        TOO_MANY_UNITS_NEARBY           = "You already have %d units nearby!",
        NO_CRATE_GROUPS                 = "No crate groups found for this unit!",
        NO_CRATE_SET                    = "No crate set found or index invalid!",
        NO_CRATE_IN_SET                 = "No crate found in that set!",
        NO_TROOP_CHUNK                  = "No troop cargo chunk found for ID %d!",
        TROOP_CHUNK_EMPTY               = "Troop chunk is empty for ID %d!",
        -- ============================================================
        -- Nothing loaded / in stock
        -- ============================================================
        NOTHING_LOADED                  = "Nothing loaded!\nTroop limit: %d | Crate limit %d | Weight limit %d kgs",
        NOTHING_LOADED_AIRDROP          = "Nothing loaded or not within airdrop parameters!",
        NOTHING_LOADED_HOVER            = "Nothing loaded or not hovering within parameters!",
        NOTHING_IN_STOCK                = "Nothing in stock!",
        NOTHING_TO_PACK                 = "Nothing to pack at this distance pilot!",
        NOTHING_TO_REMOVE               = "Nothing to remove at this distance pilot!",
        -- ============================================================
        -- Zone / Info
        -- ============================================================
        ROGER_ZONE                      = "Roger, %s zone %s!",
        -- ============================================================
        -- Report: Hover / Flight Parameters
        -- ============================================================
        HOVER_PARAMS_METRIC             = "Hover parameters (autoload/drop):\n - Min height %dm \n - Max height %dm \n - Max speed 2mps \n - In parameter: %s",
        HOVER_PARAMS_IMPERIAL           = "Hover parameters (autoload/drop):\n - Min height %dft \n - Max height %dft \n - Max speed 6ftps \n - In parameter: %s",
        FLIGHT_PARAMS_IMPERIAL          = "Flight parameters (airdrop):\n - Min height %dft \n - Max height %dft \n - In parameter: %s",
        FLIGHT_PARAMS_METRIC            = "Flight parameters (airdrop):\n - Min height %dm \n - Max height %dm \n - In parameter: %s",
        -- ============================================================
        -- Report Titles  (REPORT:New())
        -- ============================================================
        REPORT_CRATES_FOUND             = "Crates Found Nearby:",
        REPORT_REMOVING_CRATES          = "Removing Crates Found Nearby:",
        REPORT_TRANSPORT_CHECKOUT       = "Transport Checkout Sheet",
        REPORT_INVENTORY                = "Inventory Sheet",
        REPORT_BUILD_CHECKLIST          = "Checklist Buildable Crates",
        REPORT_REPAIR_CHECKLIST         = "Checklist Repairs",
        REPORT_BEACONS                  = "Active Zone Beacons",
        -- ============================================================
        -- Report Section Headers  (report:Add())
        -- ============================================================
        REPORT_SECTION_TROOPS           = "        -- TROOPS --",
        REPORT_SECTION_CRATES           = "       -- CRATES --",
        REPORT_SECTION_CRATES_GC        = "       -- CRATES loaded via Ground Crew --",
        REPORT_SECTION_NONE             = "        N O N E",
        REPORT_SECTION_NONE_ALT         = "     --- None found! ---",
        REPORT_SECTION_NONE_REPAIR      = "     --- None Found ---",
        REPORT_GC_LOADABLE_HINT         = "Probably ground crew loadable (F8)",
        REPORT_TOTAL_MASS               = "Total Mass: %s kg. Loadable: %s kg.",
        REPORT_TROOPS_CRATES_COUNT      = "Troops: %d(%d), Crates: %d(%d)",
        REPORT_TROOPS_CRATETYPES_COUNT  = "Troops: %d, Cratetypes: %d",
        -- ============================================================
        -- Report Row Templates  (per-item lines in reports)
        -- ============================================================
        REPORT_ROW_TROOP                = "Troop: %s size %d",
        REPORT_ROW_CRATE                = "Crate: %s %d/%d",
        REPORT_ROW_CRATE_SIZE1          = "Crate: %s size 1",
        REPORT_ROW_GC_CRATE             = "GC loaded Crate: %s size 1",
        REPORT_ROW_DROPPED_CRATE        = "Dropped crate for %s, %dkg",
        REPORT_ROW_CRATE_KG             = "Crate for %s, %dkg",
        REPORT_ROW_CRATE_REMOVED        = "Crate for %s, %dkg removed",
        REPORT_ROW_UNIT_STOCK           = "Unit: %s | Soldiers: %d | Stock: %s",
        REPORT_ROW_TYPE_CRATE_STOCK     = "Type: %s | Crates per Set: %d | Stock: %s",
        REPORT_ROW_TYPE_STOCK           = "Type: %s | Stock: %s",
        REPORT_ROW_BUILD_CHECK          = "Type: %s | Required %d | Found %d | Can Build %s",
        REPORT_ROW_REPAIR_CHECK         = "Type: %s | Required %d | Found %d | Can Repair %s",
        REPORT_ROW_BEACON               = " %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        -- ============================================================
        -- Weight / Crate limit tokens
        -- ============================================================
        WEIGHT_LIMIT                    = "Weight limit reached",
        CRATE_LIMIT                     = "Crate limit reached",
        -- ============================================================
        -- Menu labels - Top level
        -- ============================================================
        MENU_CTLD                       = "CTLD",
        MENU_MANAGE_TROOPS              = "Manage Troops",
        MENU_MANAGE_CRATES              = "Manage Crates",
        MENU_MANAGE_UNITS               = "Manage Units",
        -- ============================================================
        -- Menu labels - Troops
        -- ============================================================
        MENU_LOAD_TROOPS                = "Load troops",
        MENU_DROP_TROOPS                = "Drop Troops",
        MENU_DROP_ALL_TROOPS            = "Drop ALL troops",
        MENU_EXTRACT_TROOPS             = "Extract troops",
        MENU_DROP_N_TROOPS              = "Drop (%d) %s",
        -- ============================================================
        -- Menu labels - Crates: Get
        -- ============================================================
        MENU_GET_CRATES                 = "Get Crates",
        MENU_GET                        = "Get",
        MENU_GET_AND_LOAD               = "Get and Load",
        MENU_GET_ANYWAY                 = "Get anyway",
        MENU_PARTIALLY_LOAD             = "Partially load",
        MENU_OUT_OF_STOCK               = "Out of stock",
        MENU_TROOP_LIMIT                = "Troop limit reached",
        -- ============================================================
        -- Menu labels - Crates: Load
        -- ============================================================
        MENU_LOAD_CRATES                = "Load Crates",
        MENU_LOAD_ALL                   = "Load ALL",
        MENU_SHOW_LOADABLE_CRATES       = "Show loadable crates",
        MENU_NO_CRATES_FOUND_RESCAN     = "No crates found! Rescan?",
        MENU_USE_C130_LOAD              = "Use C-130 Load system",
        MENU_LOAD_SINGLE                = "Load",
        -- ============================================================
        -- Menu labels - Crates: Drop
        -- ============================================================
        MENU_DROP_CRATES                = "Drop Crates",
        MENU_DROP_ALL_CRATES            = "Drop ALL crates",
        MENU_DROP                       = "Drop",
        MENU_DROP_AND_BUILD             = "Drop and build",
        MENU_DROP_N_SETS                = "Drop %d Set%s",
        MENU_NO_CRATES_TO_DROP          = "No crates to drop!",
        -- ============================================================
        -- Menu labels - Crates: Build / Repair / Pack / Remove
        -- ============================================================
        MENU_BUILD_CRATES               = "Build crates",
        MENU_REPAIR                     = "Repair",
        MENU_PACK_CRATES                = "Pack crates",
        MENU_PACK                       = "Pack",
        MENU_PACK_AND_LOAD              = "Pack and Load",
        MENU_PACK_AND_REMOVE            = "Pack and Remove",
        MENU_REMOVE_CRATES              = "Remove crates",
        MENU_REMOVE_CRATES_NEARBY       = "Remove crates nearby",
        MENU_LIST_CRATES_NEARBY         = "List crates nearby",
        MENU_CRATES_NEEDED              = "%d crate%s %s (%dkg)",
        -- ============================================================
        -- Menu labels - Units (C-130)
        -- ============================================================
        MENU_GET_UNITS                  = "Get Units",
        MENU_REMOVE_UNITS_NEARBY        = "Remove units nearby",
        -- ============================================================
        -- Menu labels - Info / Cargo
        -- ============================================================
        MENU_LIST_BOARDED_CARGO         = "List boarded cargo",
        MENU_INVENTORY                  = "Inventory",
        MENU_LIST_ZONE_BEACONS          = "List active zone beacons",
        -- ============================================================
        -- Menu labels - Smokes / Flares / Beacons
        -- ============================================================
        MENU_SMOKES_FLARES_BEACONS      = "Smokes, Flares, Beacons",
        MENU_SMOKE_ZONES_NEARBY         = "Smoke zones nearby",
        MENU_DROP_SMOKE_NOW             = "Drop smoke now",
        MENU_RED_SMOKE                  = "Red smoke",
        MENU_BLUE_SMOKE                 = "Blue smoke",
        MENU_GREEN_SMOKE                = "Green smoke",
        MENU_ORANGE_SMOKE               = "Orange smoke",
        MENU_WHITE_SMOKE                = "White smoke",
        MENU_FLARE_ZONES_NEARBY         = "Flare zones nearby",
        MENU_FIRE_FLARE_NOW             = "Fire flare now",
        MENU_DROP_BEACON_NOW            = "Drop beacon now",
        -- ============================================================
        -- Menu labels - Parameters
        -- ============================================================
        MENU_SHOW_FLIGHT_PARAMS         = "Show flight parameters",
        MENU_SHOW_HOVER_PARAMS          = "Show hover parameters",
        STOCK_NONE                      = "none",
        STOCK_UNLIMITED                 = "unlimited",
        BUILD_YES                       = "YES",
        BUILD_NO                        = "NO",
    },
  DE = {
        -- ============================================================
        -- Kiste / Fracht laden
        -- ============================================================
        CRATE_LOADED_GROUNDCREW         = "Kiste %s vom Bodenpersonal geladen!",
        CRATE_UNLOADED_GROUNDCREW       = "Kiste %s vom Bodenpersonal entladen!",
        CRATE_LOADED_ID                 = "Kiste ID %d für %s geladen!",
        LOADED_FULL                     = "%d %s geladen.",
        LOADED_SETS_LEFTOVER            = "%d %s geladen, %d Kiste(n) übrig.",
        LOADED_SETS                     = "%d %s geladen.",
        LOADED_PARTIAL                  = "Nur %d/%d Kiste(n) von %s geladen.",
        LOADED_PARTIAL_LIMIT            = "Nur %d/%d Kiste(n) von %s geladen. Frachtlimit erreicht!",
        LOADED_BATCH                    = "%d %s geladen.",
        LOADED_BATCH_PARTIAL            = "Einige Sets konnten nicht vollständig geladen werden.",
        -- ============================================================
        -- Abwerfen / Entladen
        -- ============================================================
        DROPPED_FULL                    = "%d %s abgeworfen.",
        DROPPED_SETS_LEFTOVER           = "%d %s abgeworfen, %d Kiste(n) übrig.",
        DROPPED_SETS                    = "%d %s abgeworfen.",
        DROPPED_PARTIAL                 = "%d/%d Kiste(n) von %s abgeworfen.",
        DROPPED_INTO_ACTION             = "%s im Einsatz abgesetzt!",
        DROPPED_BEACON                  = "%s abgesetzt | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        CRATES_POSITIONED               = "%d Kisten für %s in Ihrer Nähe positioniert!",
        CRATES_DROPPED                  = "%d Kisten für %s abgeworfen!",
        -- ============================================================
        -- Truppen
        -- ============================================================
        BOARDED                         = "%s eingestiegen!",
        BOARDING                        = "%s steigt ein!",
        TROOPS_RETURNED                 = "Truppen zur Basis zurückgekehrt!",
        -- ============================================================
        -- Einsatz
        -- ============================================================
        DEPLOYED_NEAR_YOU               = "%s in Ihrer Nähe eingesetzt!",
        UNITS_REMOVED                   = "%s entfernt",
        -- ============================================================
        -- Bauen / Reparieren
        -- ============================================================
        BUILD_STARTED                   = "Bau gestartet, fertig in %d Sekunden!",
        REPAIR_STARTED                  = "Reparatur mit %s gestartet, dauert %d Sek.",
        NO_UNIT_TO_REPAIR               = "Keine Einheit in Reichweite zum Reparieren!",
        CANT_REPAIR_WITH                = "Diese Einheit kann nicht mit %s repariert werden",
        CRATES_MOVE_BEFORE_BUILD        = "*** Kisten müssen vor dem Bau verschoben werden!",
        -- ============================================================
        -- Fehler - Hubschrauber / Gewicht / Kapazität
        -- ============================================================
        CHOPPER_CANNOT_CARRY            = "Dieser Hubschrauber kann keine Kisten transportieren!",
        TOO_HEAVY                       = "Entschuldigung, das ist zu schwer zum Laden!",
        FULLY_LOADED                    = "Entschuldigung, wir sind voll beladen!",
        CRAMMED                         = "Entschuldigung, wir sind bereits voll besetzt!",
        NO_CAPACITY_NOW                 = "Aktuell keine Ladekapazität mehr vorhanden!",
        NO_MORE_CAPACITY                = "Keine Kapazität mehr für weitere Kisten!",
        CANNOT_LOAD_NONE_OR_FULL        = "Laden nicht möglich: keine Kisten gefunden oder Kapazität erschöpft.",
        -- ============================================================
        -- Fehler - Position
        -- ============================================================
        NEED_TO_LAND_OR_HOVER_LOAD      = "Bitte landen oder schweben Sie zum Laden!",
        HOVER_OVER_CRATES               = "Schweben Sie über die Kisten, um sie aufzunehmen!",
        LAND_OR_HOVER_OVER_CRATES       = "Landen oder schweben Sie über die Kisten, um sie aufzunehmen!",
        MUST_LAND_OR_HOVER_CRATES       = "Sie müssen landen oder schweben, um Kisten zu laden!",
        NEED_TO_LAND_BUILD              = "Sie müssen landen / anhalten, um etwas zu bauen, Pilot!",
        NOT_CLOSE_ENOUGH_LOGISTICS      = "Sie sind nicht nah genug an einer Logistikzone!",
        NOT_CLOSE_ENOUGH_DROP           = "Sie sind nicht nah genug an einer Abwurfzone!",
        NOT_CLOSE_ENOUGH_ZONE_NM        = "Negativ, Sie müssen näher als %d Seemeilen an einer Zone sein!",
        CANNOT_BUILD_LOADING_AREA       = "In einem Ladebereich kann nicht gebaut werden, Pilot!",
        -- ============================================================
        -- Fehler - Türen
        -- ============================================================
        OPEN_DOORS_LOAD_CARGO           = "Bitte öffnen Sie die Tür(en) zum Laden von Fracht!",
        OPEN_DOORS_LOAD_TROOPS          = "Bitte öffnen Sie die Tür(en) zum Einladen von Truppen!",
        OPEN_DOORS_EXTRACT_TROOPS       = "Bitte öffnen Sie die Tür(en) zum Aussteigen der Truppen!",
        OPEN_DOORS_UNLOAD_TROOPS        = "Bitte öffnen Sie die Tür(en) zum Entladen der Truppen!",
        OPEN_DOORS_DROP_CARGO           = "Bitte öffnen Sie die Tür(en) zum Abwerfen der Fracht!",
        -- ============================================================
        -- Fehler - Bestand / Verfügbarkeit
        -- ============================================================
        ALL_GONE                        = "Entschuldigung, alle %s sind vergriffen!",
        RAN_OUT_OF                      = "Entschuldigung, %s ist nicht mehr vorrätig",
        CARGO_NOT_AVAILABLE_ZONE        = "Die angeforderte Fracht ist in dieser Zone nicht verfügbar!",
        ENOUGH_CRATES_NEARBY            = "Es sind bereits genügend Kisten in der Nähe! Bitte zuerst um diese kümmern!",
        NO_CRATES_WITHIN                = "Keine (ladbaren) Kisten in %d Metern Umkreis!",
        NO_CRATES_WITHIN_PLAIN          = "Keine Kisten in %d Metern Umkreis!",
        NO_CRATES_IN_RANGE              = "Keine Kisten in Reichweite gefunden!",
        NO_NAMED_CRATES_IN_RANGE        = "Keine \"%s\"-Kisten in Reichweite gefunden!",
        NO_LOADABLE_CRATES              = "Entschuldigung, keine ladbaren Kisten in der Nähe oder maximales Frachtgewicht erreicht!",
        NO_UNITS_TO_EXTRACT             = "Keine Einheiten nah genug zum Aussteigen!",
        NO_UNIT_CONFIG                  = "Keine Einheitenkonfiguration für %s gefunden",
        CANT_ONBOARD                    = "%s kann nicht eingeladen werden",
        TOO_MANY_UNITS_NEARBY           = "Sie haben bereits %d Einheiten in der Nähe!",
        NO_CRATE_GROUPS                 = "Keine Kistengruppen für diese Einheit gefunden!",
        NO_CRATE_SET                    = "Kein Kistenset gefunden oder Index ungültig!",
        NO_CRATE_IN_SET                 = "Keine Kiste in diesem Set gefunden!",
        NO_TROOP_CHUNK                  = "Kein Truppenfracht-Block für ID %d gefunden!",
        TROOP_CHUNK_EMPTY               = "Truppenfracht-Block für ID %d ist leer!",
        -- ============================================================
        -- Nichts geladen / kein Bestand
        -- ============================================================
        NOTHING_LOADED                  = "Nichts geladen!\nTruppenlimit: %d | Kistenlimit: %d | Gewichtslimit: %d kg",
        NOTHING_LOADED_AIRDROP          = "Nichts geladen oder nicht innerhalb der Abwurfparameter!",
        NOTHING_LOADED_HOVER            = "Nichts geladen oder Schwebeparameter nicht erfüllt!",
        NOTHING_IN_STOCK                = "Nichts vorrätig!",
        NOTHING_TO_PACK                 = "Nichts in dieser Entfernung zum Verpacken, Pilot!",
        NOTHING_TO_REMOVE               = "Nichts in dieser Entfernung zum Entfernen, Pilot!",
        -- ============================================================
        -- Zone / Info
        -- ============================================================
        ROGER_ZONE                      = "Verstanden, %s Zone %s!",
        -- ============================================================
        -- Report: Schwebe- / Flugparameter
        -- ============================================================
        HOVER_PARAMS_METRIC             = "Schwebeparameter (Autoladen/Abwurf):\n - Min. Höhe %dm \n - Max. Höhe %dm \n - Max. Geschwindigkeit 2m/s \n - Im Parameter: %s",
        HOVER_PARAMS_IMPERIAL           = "Schwebeparameter (Autoladen/Abwurf):\n - Min. Höhe %dft \n - Max. Höhe %dft \n - Max. Geschwindigkeit 6ft/s \n - Im Parameter: %s",
        FLIGHT_PARAMS_IMPERIAL          = "Flugparameter (Luftabwurf):\n - Min. Höhe %dft \n - Max. Höhe %dft \n - Im Parameter: %s",
        FLIGHT_PARAMS_METRIC            = "Flugparameter (Luftabwurf):\n - Min. Höhe %dm \n - Max. Höhe %dm \n - Im Parameter: %s",
        -- ============================================================
        -- Report-Titel
        -- ============================================================
        REPORT_CRATES_FOUND             = "Kisten in der Nähe:",
        REPORT_REMOVING_CRATES          = "Entferne Kisten in der Nähe:",
        REPORT_TRANSPORT_CHECKOUT       = "Transport-Checkliste",
        REPORT_INVENTORY                = "Inventarliste",
        REPORT_BUILD_CHECKLIST          = "Checkliste baubare Kisten",
        REPORT_REPAIR_CHECKLIST         = "Checkliste Reparaturen",
        REPORT_BEACONS                  = "Aktive Zonenfeuer",
        -- ============================================================
        -- Report-Sektionskopfzeilen
        -- ============================================================
        REPORT_SECTION_TROOPS           = "        -- TRUPPEN --",
        REPORT_SECTION_CRATES           = "       -- KISTEN --",
        REPORT_SECTION_CRATES_GC        = "       -- KISTEN via Bodenpersonal geladen --",
        REPORT_SECTION_NONE             = "        K E I N E",
        REPORT_SECTION_NONE_ALT         = "     --- Keine gefunden! ---",
        REPORT_SECTION_NONE_REPAIR      = "     --- Keine gefunden ---",
        REPORT_GC_LOADABLE_HINT         = "Wahrscheinlich durch Bodenpersonal ladbar (F8)",
        REPORT_TOTAL_MASS               = "Gesamtgewicht: %s kg. Ladbar: %s kg.",
        REPORT_TROOPS_CRATES_COUNT      = "Truppen: %d(%d), Kisten: %d(%d)",
        REPORT_TROOPS_CRATETYPES_COUNT  = "Truppen: %d, Kistentypen: %d",
        -- ============================================================
        -- Report-Zeilenvorlagen
        -- ============================================================
        REPORT_ROW_TROOP                = "Truppe: %s Größe %d",
        REPORT_ROW_CRATE                = "Kiste: %s %d/%d",
        REPORT_ROW_CRATE_SIZE1          = "Kiste: %s Größe 1",
        REPORT_ROW_GC_CRATE             = "Bodenpersonal-Kiste: %s Größe 1",
        REPORT_ROW_DROPPED_CRATE        = "Abgeworfene Kiste für %s, %dkg",
        REPORT_ROW_CRATE_KG             = "Kiste für %s, %dkg",
        REPORT_ROW_CRATE_REMOVED        = "Kiste für %s, %dkg entfernt",
        REPORT_ROW_UNIT_STOCK           = "Einheit: %s | Soldaten: %d | Bestand: %s",
        REPORT_ROW_TYPE_CRATE_STOCK     = "Typ: %s | Kisten pro Set: %d | Bestand: %s",
        REPORT_ROW_TYPE_STOCK           = "Typ: %s | Bestand: %s",
        REPORT_ROW_BUILD_CHECK          = "Typ: %s | Benötigt: %d | Gefunden: %d | Baubar: %s",
        REPORT_ROW_REPAIR_CHECK         = "Typ: %s | Benötigt: %d | Gefunden: %d | Reparierbar: %s",
        REPORT_ROW_BEACON               = " %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        -- ============================================================
        -- Gewichts- / Kistenlimit-Token
        -- ============================================================
        WEIGHT_LIMIT                    = "Gewichtslimit erreicht",
        CRATE_LIMIT                     = "Kistenlimit erreicht",
        -- ============================================================
        -- Menübezeichnungen - Obere Ebene
        -- ============================================================
        MENU_CTLD                       = "CTLD",
        MENU_MANAGE_TROOPS              = "Truppen verwalten",
        MENU_MANAGE_CRATES              = "Kisten verwalten",
        MENU_MANAGE_UNITS               = "Einheiten verwalten",
        -- ============================================================
        -- Menübezeichnungen - Truppen
        -- ============================================================
        MENU_LOAD_TROOPS                = "Truppen einladen",
        MENU_DROP_TROOPS                = "Truppen absetzen",
        MENU_DROP_ALL_TROOPS            = "ALLE Truppen absetzen",
        MENU_EXTRACT_TROOPS             = "Truppen aufnehmen",
        MENU_DROP_N_TROOPS              = "(%d) %s absetzen",
        -- ============================================================
        -- Menübezeichnungen - Kisten: Holen
        -- ============================================================
        MENU_GET_CRATES                 = "Kisten holen",
        MENU_GET                        = "Holen",
        MENU_GET_AND_LOAD               = "Holen und laden",
        MENU_GET_ANYWAY                 = "Trotzdem holen",
        MENU_PARTIALLY_LOAD             = "Teilweise laden",
        MENU_OUT_OF_STOCK               = "Nicht vorrätig",
        MENU_TROOP_LIMIT                = "Truppenlimit erreicht",
        -- ============================================================
        -- Menübezeichnungen - Kisten: Laden
        -- ============================================================
        MENU_LOAD_CRATES                = "Kisten laden",
        MENU_LOAD_ALL                   = "ALLE laden",
        MENU_SHOW_LOADABLE_CRATES       = "Ladbare Kisten anzeigen",
        MENU_NO_CRATES_FOUND_RESCAN     = "Keine Kisten gefunden! Neu scannen?",
        MENU_USE_C130_LOAD              = "C-130-Ladesystem verwenden",
        MENU_LOAD_SINGLE                = "Lade",
        -- ============================================================
        -- Menübezeichnungen - Kisten: Abwerfen
        -- ============================================================
        MENU_DROP_CRATES                = "Kisten abwerfen",
        MENU_DROP_ALL_CRATES            = "ALLE Kisten abwerfen",
        MENU_DROP                       = "Abwerfen",
        MENU_DROP_AND_BUILD             = "Abwerfen und bauen",
        MENU_DROP_N_SETS                = "%d Set%s abwerfen",
        MENU_NO_CRATES_TO_DROP          = "Keine Kisten zum Abwerfen!",
        -- ============================================================
        -- Menübezeichnungen - Kisten: Bauen / Reparieren / Packen / Entfernen
        -- ============================================================
        MENU_BUILD_CRATES               = "Kisten bauen",
        MENU_REPAIR                     = "Reparieren",
        MENU_PACK_CRATES                = "Kisten packen",
        MENU_PACK                       = "Packen",
        MENU_PACK_AND_LOAD              = "Packen und laden",
        MENU_PACK_AND_REMOVE            = "Packen und entfernen",
        MENU_REMOVE_CRATES              = "Kisten entfernen",
        MENU_REMOVE_CRATES_NEARBY       = "Nahe Kisten entfernen",
        MENU_LIST_CRATES_NEARBY         = "Nahe Kisten auflisten",
        MENU_CRATES_NEEDED              = "%d Kiste%s %s (%dkg)",
        -- ============================================================
        -- Menübezeichnungen - Einheiten (C-130)
        -- ============================================================
        MENU_GET_UNITS                  = "Einheiten holen",
        MENU_REMOVE_UNITS_NEARBY        = "Nahe Einheiten entfernen",
        -- ============================================================
        -- Menübezeichnungen - Info / Fracht
        -- ============================================================
        MENU_LIST_BOARDED_CARGO         = "Geladene Fracht anzeigen",
        MENU_INVENTORY                  = "Inventar",
        MENU_LIST_ZONE_BEACONS          = "Aktive Zonenfeuer anzeigen",
        -- ============================================================
        -- Menübezeichnungen - Rauch / Leuchtfeuer / Baken
        -- ============================================================
        MENU_SMOKES_FLARES_BEACONS      = "Rauch, Leuchtfeuer, Baken",
        MENU_SMOKE_ZONES_NEARBY         = "Nahe Zonen einrauchen",
        MENU_DROP_SMOKE_NOW             = "Rauch jetzt setzen",
        MENU_RED_SMOKE                  = "Roter Rauch",
        MENU_BLUE_SMOKE                 = "Blauer Rauch",
        MENU_GREEN_SMOKE                = "Grüner Rauch",
        MENU_ORANGE_SMOKE               = "Oranger Rauch",
        MENU_WHITE_SMOKE                = "Weißer Rauch",
        MENU_FLARE_ZONES_NEARBY         = "Nahe Zonen befeuern",
        MENU_FIRE_FLARE_NOW             = "Leuchtfeuer jetzt abfeuern",
        MENU_DROP_BEACON_NOW            = "Bake jetzt setzen",
        -- ============================================================
        -- Menübezeichnungen - Parameter
        -- ============================================================
        MENU_SHOW_FLIGHT_PARAMS         = "Flugparameter anzeigen",
        MENU_SHOW_HOVER_PARAMS          = "Schwebeparameter anzeigen",
        STOCK_NONE                      = "keiner",
        STOCK_UNLIMITED                 = "unbegrenzt",
        BUILD_YES                       = "JA",
        BUILD_NO                        = "NEIN",
},
FR = {
        --- ============================================================
        -- Chargement caisse / fret
        -- ============================================================
        CRATE_LOADED_GROUNDCREW         = "Caisse(s) %s chargée(s) par l'équipe au sol !",
        CRATE_UNLOADED_GROUNDCREW       = "Caisse(s) %s déchargée(s) par l'équipe au sol !",
        CRATE_LOADED_ID                 = "Caisse(s) ID %d pour %s chargée(s) !",
        LOADED_FULL                     = "%d %s chargé(s).",
        LOADED_SETS_LEFTOVER            = "%d %s chargé(s), %d caisse(s) restante(s).",
        LOADED_SETS                     = "%d %s chargé(s).",
        LOADED_PARTIAL                  = "Seulement %d/%d caisse(s) de %s chargée(s).",
        LOADED_PARTIAL_LIMIT            = "Seulement %d/%d caisse(s) de %s chargée(s). Limite de fret atteinte !",
        LOADED_BATCH                    = "%d %s chargé(s).",
        LOADED_BATCH_PARTIAL            = "Certains ensembles n'ont pas pu être complètement chargés.",
        -- ============================================================
        -- Largage / Déchargement
        -- ============================================================
        DROPPED_FULL                    = "%d %s largué(s).",
        DROPPED_SETS_LEFTOVER           = "%d %s largué(s), %d caisse(s) restante(s).",
        DROPPED_SETS                    = "%d %s largué(s).",
        DROPPED_PARTIAL                 = "%d/%d caisse(s) de %s larguée(s).",
        DROPPED_INTO_ACTION             = "%s engagé(s) en action !",
        DROPPED_BEACON                  = "%s largué | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        CRATES_POSITIONED               = "%d caisses pour %s positionnées près de vous !",
        CRATES_DROPPED                  = "%d caisses pour %s larguées !",
        -- ============================================================
        -- Troupes
        -- ============================================================
        BOARDED                         = "%s embarqué(s) !",
        BOARDING                        = "%s en cours d'embarquement !",
        TROOPS_RETURNED                 = "Les troupes sont retournées à la base !",
        -- ============================================================
        -- Déploiement
        -- ============================================================
        DEPLOYED_NEAR_YOU               = "%s déployé(s) près de vous !",
        UNITS_REMOVED                   = "%s supprimé(s)",
        -- ============================================================
        -- Construction / Réparation
        -- ============================================================
        BUILD_STARTED                   = "Construction démarrée, prête dans %d secondes !",
        REPAIR_STARTED                  = "Réparation démarrée avec %s, durée %d sec.",
        NO_UNIT_TO_REPAIR               = "Aucune unité(s) assez proche pour être réparée(s) !",
        CANT_REPAIR_WITH                = "Impossible de réparer cette unité avec %s",
        CRATES_MOVE_BEFORE_BUILD        = "*** Les caisses doivent être déplacées avant la construction !",
        -- ============================================================
        -- Erreurs - Hélicoptère / Poids / Capacité
        -- ============================================================
        CHOPPER_CANNOT_CARRY            = "Cet hélicoptère ne peut pas transporter de caisses !",
        TOO_HEAVY                       = "Désolé, c'est trop lourd à charger !",
        FULLY_LOADED                    = "Désolé, capacité maximale atteinte !",
        CRAMMED                         = "Désolé, nous sommes déjà au complet !",
        NO_CAPACITY_NOW                 = "Aucune capacité de chargement disponible pour le moment !",
        NO_MORE_CAPACITY                = "Plus de capacité pour charger des caisses !",
        CANNOT_LOAD_NONE_OR_FULL        = "Chargement impossible : aucune caisse trouvée ou capacité épuisée.",
        -- ============================================================
        -- Erreurs - Position
        -- ============================================================
        NEED_TO_LAND_OR_HOVER_LOAD      = "Vous devez atterrir ou rester en vol stationnaire pour charger !",
        HOVER_OVER_CRATES               = "Survolez les caisses en stationnaire pour les récupérer !",
        LAND_OR_HOVER_OVER_CRATES       = "Atterrissez ou survolez les caisses en stationnaire pour les récupérer !",
        MUST_LAND_OR_HOVER_CRATES       = "Vous devez atterrir ou rester en stationnaire pour charger les caisses !",
        NEED_TO_LAND_BUILD              = "Vous devez atterrir / vous arrêter pour construire quelque chose, Pilote !",
        NOT_CLOSE_ENOUGH_LOGISTICS      = "Vous n'êtes pas assez proche d'une zone logistique !",
        NOT_CLOSE_ENOUGH_DROP           = "Vous n'êtes pas assez proche d'une zone de largage !",
        NOT_CLOSE_ENOUGH_ZONE_NM        = "Négatif, vous devez être à moins de %d nm d'une zone !",
        CANNOT_BUILD_LOADING_AREA       = "Vous ne pouvez pas construire dans une zone de chargement, Pilote !",
        -- ============================================================
        -- Erreurs - Portes
        -- ============================================================
        OPEN_DOORS_LOAD_CARGO           = "Vous devez ouvrir la/les porte(s) pour charger du fret !",
        OPEN_DOORS_LOAD_TROOPS          = "Vous devez ouvrir la/les porte(s) pour embarquer des troupes !",
        OPEN_DOORS_EXTRACT_TROOPS       = "Vous devez ouvrir la/les porte(s) pour extraire des troupes !",
        OPEN_DOORS_UNLOAD_TROOPS        = "Vous devez ouvrir la/les porte(s) pour débarquer des troupes !",
        OPEN_DOORS_DROP_CARGO           = "Vous devez ouvrir la/les porte(s) pour larguer du fret !",
        -- ============================================================
        -- Erreurs - Stock / Disponibilité
        -- ============================================================
        ALL_GONE                        = "Désolé, tous les %s sont épuisés !",
        RAN_OUT_OF                      = "Désolé, nous n'avons plus de %s !",
        CARGO_NOT_AVAILABLE_ZONE        = "Le fret demandé n'est pas disponible dans cette zone !",
        ENOUGH_CRATES_NEARBY            = "Il y a déjà suffisamment de caisses à proximité ! Occupez-vous d'abord de celles-ci !",
        NO_CRATES_WITHIN                = "Aucune caisse (chargeable) dans un rayon de %d mètres !",
        NO_CRATES_WITHIN_PLAIN          = "Aucune caisse dans un rayon de %d mètres !",
        NO_CRATES_IN_RANGE              = "Aucune caisse trouvée à portée !",
        NO_NAMED_CRATES_IN_RANGE        = "Aucune caisse \"%s\" trouvée à portée !",
        NO_LOADABLE_CRATES              = "Désolé, aucune caisse chargeable à proximité ou poids maximum atteint !",
        NO_UNITS_TO_EXTRACT             = "Aucune unité assez proche pour être extraite !",
        NO_UNIT_CONFIG                  = "Aucune configuration d'unité trouvée pour %s",
        CANT_ONBOARD                    = "Impossible d'embarquer %s",
        TOO_MANY_UNITS_NEARBY           = "Vous avez déjà %d unités à proximité !",
        NO_CRATE_GROUPS                 = "Aucun groupe de caisses trouvé pour cette unité !",
        NO_CRATE_SET                    = "Aucun ensemble de caisses trouvé ou index invalide !",
        NO_CRATE_IN_SET                 = "Aucune caisse trouvée dans cet ensemble !",
        NO_TROOP_CHUNK                  = "Aucun bloc de fret de troupes trouvé pour l'ID %d !",
        TROOP_CHUNK_EMPTY               = "Le bloc de fret de troupes pour l'ID %d est vide !",
        -- ============================================================
        -- Rien de chargé / en stock
        -- ============================================================
        NOTHING_LOADED                  = "Rien de chargé !\nLimite de troupes : %d | Limite de caisses : %d | Limite en poids : %d kg",
        NOTHING_LOADED_AIRDROP          = "Rien de chargé ou paramètres de largage non respectés !",
        NOTHING_LOADED_HOVER            = "Rien de chargé ou paramètres de vol stationnaire non respectés !",
        NOTHING_IN_STOCK                = "Rien en stock !",
        NOTHING_TO_PACK                 = "Rien à charger à cette distance, Pilote !",
        NOTHING_TO_REMOVE               = "Rien à retirer à cette distance, Pilote !",
        -- ============================================================
        -- Zone / Info
        -- ============================================================
        ROGER_ZONE                      = "Compris, zone %s %s !",
        -- ============================================================
        -- Rapport : Paramètres stationnaire / vol
        -- ============================================================
        HOVER_PARAMS_METRIC             = "Paramètres stationnaires (autochargement/largage) :\n - Hauteur min. %dm \n - Hauteur max. %dm \n - Vitesse max. 2m/s \n - Dans les paramètres : %s",
        HOVER_PARAMS_IMPERIAL           = "Paramètres stationnaires (autochargement/largage) :\n - Hauteur min. %dft \n - Hauteur max. %dft \n - Vitesse max. 6ft/s \n - Dans les paramètres : %s",
        FLIGHT_PARAMS_IMPERIAL          = "Paramètres de vol (largage aérien) :\n - Hauteur min. %dft \n - Hauteur max. %dft \n - Dans les paramètres : %s",
        FLIGHT_PARAMS_METRIC            = "Paramètres de vol (largage aérien) :\n - Hauteur min. %dm \n - Hauteur max. %dm \n - Dans les paramètres : %s",
        -- ============================================================
        -- Titres de rapport
        -- ============================================================
        REPORT_CRATES_FOUND             = "Caisses trouvées à proximité :",
        REPORT_REMOVING_CRATES          = "Suppression des caisses à proximité :",
        REPORT_TRANSPORT_CHECKOUT       = "Fiche de contrôle transport",
        REPORT_INVENTORY                = "Fiche d'inventaire",
        REPORT_BUILD_CHECKLIST          = "Checklist caisses constructibles",
        REPORT_REPAIR_CHECKLIST         = "Checklist réparations",
        REPORT_BEACONS                  = "Balises de zone actives",
        -- ============================================================
        -- En-têtes de sections de rapport
        -- ============================================================
        REPORT_SECTION_TROOPS           = "        -- TROUPES --",
        REPORT_SECTION_CRATES           = "       -- CAISSES --",
        REPORT_SECTION_CRATES_GC        = "       -- CAISSES chargées via équipe au sol --",
        REPORT_SECTION_NONE             = "        A U C U N",
        REPORT_SECTION_NONE_ALT         = "     --- Aucun trouvé ! ---",
        REPORT_SECTION_NONE_REPAIR      = "     --- Aucun trouvé ---",
        REPORT_GC_LOADABLE_HINT         = "Probablement chargeable via l’équipe au sol (F8)",
        REPORT_TOTAL_MASS               = "Masse totale : %s kg. Chargeable : %s kg.",
        REPORT_TROOPS_CRATES_COUNT      = "Troupes : %d(%d), Caisses : %d(%d)",
        REPORT_TROOPS_CRATETYPES_COUNT  = "Troupes : %d, Types de caisses : %d",
        -- ============================================================
        -- Modèles de lignes de rapport
        -- ============================================================
        REPORT_ROW_TROOP                = "Troupe : %s taille %d",
        REPORT_ROW_CRATE                = "Caisse : %s %d/%d",
        REPORT_ROW_CRATE_SIZE1          = "Caisse : %s taille 1",
        REPORT_ROW_GC_CRATE             = "Caisses chargées par l'équipe au sol : %s taille 1",
        REPORT_ROW_DROPPED_CRATE        = "Caisses larguées pour %s, %dkg",
        REPORT_ROW_CRATE_KG             = "Caisses pour %s, %dkg",
        REPORT_ROW_CRATE_REMOVED        = "Caisses pour %s, %dkg retirées",
        REPORT_ROW_UNIT_STOCK           = "Unités : %s | Soldats : %d | Stock : %s",
        REPORT_ROW_TYPE_CRATE_STOCK     = "Type : %s | Caisses par ensemble : %d | Stock : %s",
        REPORT_ROW_TYPE_STOCK           = "Type : %s | Stock : %s",
        REPORT_ROW_BUILD_CHECK          = "Type : %s | Requis : %d | Trouvé : %d | Constructible : %s",
        REPORT_ROW_REPAIR_CHECK         = "Type : %s | Requis : %d | Trouvé : %d | Réparable : %s",
        REPORT_ROW_BEACON               = " %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        -- ============================================================
        -- Tokens limite poids / caisses
        -- ============================================================
        WEIGHT_LIMIT                    = "Limite de poids atteinte",
        CRATE_LIMIT                     = "Limite de caisses atteinte",
        -- ============================================================
        -- Libellés de menu - Niveau supérieur
        -- ============================================================
        MENU_CTLD                       = "CTLD",
        MENU_MANAGE_TROOPS              = "Gérer les troupes",
        MENU_MANAGE_CRATES              = "Gérer les caisses",
        MENU_MANAGE_UNITS               = "Gérer les unités",
        -- ============================================================
        -- Libellés de menu - Troupes
        -- ============================================================
        MENU_LOAD_TROOPS                = "Embarquer troupes",
        MENU_DROP_TROOPS                = "Déposer troupes",
        MENU_DROP_ALL_TROOPS            = "Déposer TOUTES les troupes",
        MENU_EXTRACT_TROOPS             = "Extraire troupes",
        MENU_DROP_N_TROOPS              = "Déposer (%d) %s",
        -- ============================================================
        -- Libellés de menu - Caisses : Récupérer
        -- ============================================================
        MENU_GET_CRATES                 = "Récupérer caisses",
        MENU_GET                        = "Récupérer",
        MENU_GET_AND_LOAD               = "Récupérer et charger",
        MENU_GET_ANYWAY                 = "Récupérer quand même",
        MENU_PARTIALLY_LOAD             = "Chargement partiel",
        MENU_OUT_OF_STOCK               = "Rupture de stock",
        MENU_TROOP_LIMIT                = "Limite de troupes atteinte",
        -- ============================================================
        -- Libellés de menu - Caisses : Charger
        -- ============================================================
        MENU_LOAD_CRATES                = "Charger caisses",
        MENU_LOAD_ALL                   = "Tout charger",
        MENU_SHOW_LOADABLE_CRATES       = "Afficher caisses chargeables",
        MENU_NO_CRATES_FOUND_RESCAN     = "Aucune caisse trouvée ! Rescanner ?",
        MENU_USE_C130_LOAD              = "Utiliser le système de chargement C-130",
        MENU_LOAD_SINGLE                = "Charger",
        -- ============================================================
        -- Libellés de menu - Caisses : Larguer
        -- ============================================================
        MENU_DROP_CRATES                = "Larguer caisses",
        MENU_DROP_ALL_CRATES            = "Larguer TOUTES les caisses",
        MENU_DROP                       = "Larguer",
        MENU_DROP_AND_BUILD             = "Larguer et construire",
        MENU_DROP_N_SETS                = "Larguer %d ensemble%s",
        MENU_NO_CRATES_TO_DROP          = "Aucune caisse à larguer !",
        -- ============================================================
        -- Libellés de menu - Caisses : Construire / Réparer / Emballer / Retirer
        -- ============================================================
        MENU_BUILD_CRATES               = "Construire caisses",
        MENU_REPAIR                     = "Réparer",
        MENU_PACK_CRATES                = "Emballer caisses",
        MENU_PACK                       = "Emballer",
        MENU_PACK_AND_LOAD              = "Emballer et charger",
        MENU_PACK_AND_REMOVE            = "Emballer et retirer",
        MENU_REMOVE_CRATES              = "Retirer caisses",
        MENU_REMOVE_CRATES_NEARBY       = "Retirer caisses proches",
        MENU_LIST_CRATES_NEARBY         = "Lister caisses proches",
        MENU_CRATES_NEEDED              = "%d caisse%s %s (%dkg)",
        -- ============================================================
        -- Libellés de menu - Unités (C-130)
        -- ============================================================
        MENU_GET_UNITS                  = "Récupérer unités",
        MENU_REMOVE_UNITS_NEARBY        = "Retirer les unités proches",
        -- ============================================================
        -- Libellés de menu - Info / Fret
        -- ============================================================
        MENU_LIST_BOARDED_CARGO         = "Lister le fret embarqué",
        MENU_INVENTORY                  = "Inventaire",
        MENU_LIST_ZONE_BEACONS          = "Lister les balises de zones actives",
        -- ============================================================
        -- Libellés de menu - Fumigènes / Fusées / Balises
        -- ============================================================
        MENU_SMOKES_FLARES_BEACONS      = "Fumigènes, Fusées, Balises",
        MENU_SMOKE_ZONES_NEARBY         = "Fumigène sur les zones proches",
        MENU_DROP_SMOKE_NOW             = "Poser fumigène maintenant",
        MENU_RED_SMOKE                  = "Fumigène rouge",
        MENU_BLUE_SMOKE                 = "Fumigène bleu",
        MENU_GREEN_SMOKE                = "Fumigène vert",
        MENU_ORANGE_SMOKE               = "Fumigène orange",
        MENU_WHITE_SMOKE                = "Fumigène blanc",
        MENU_FLARE_ZONES_NEARBY         = "Baliser zones proches",
        MENU_FIRE_FLARE_NOW             = "Tirer une fusée maintenant",
        MENU_DROP_BEACON_NOW            = "Poser une balise maintenant",
        -- ============================================================
        -- Libellés de menu - Paramètres
        -- ============================================================
        MENU_SHOW_FLIGHT_PARAMS         = "Afficher paramètres de vol",
        MENU_SHOW_HOVER_PARAMS          = "Afficher les paramètres stationnaire",
        STOCK_NONE                      = "aucun",
        STOCK_UNLIMITED                 = "illimité",
        BUILD_YES                       = "OUI",
        BUILD_NO                        = "NON",
    },
  }
  