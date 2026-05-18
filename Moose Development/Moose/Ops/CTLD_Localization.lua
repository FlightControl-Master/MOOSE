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
        TROOPS_LABEL                    = "Troops",
        ENGINEERS_LABEL                 = "Engineers",
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
        MENU_SCAN_PACKABLE_UNITS        = "Scan packable units nearby",
        MENU_NO_PACKABLE_UNITS_FOUND_RESCAN = "No packable units found! Rescan?",
        MENU_PACK_ALL                   = "Pack nearby",
        MENU_PACK_AND_LOAD              = "Pack and Load",
        MENU_PACK_AND_LOAD_ALL          = "Pack and Load nearby",
        MENU_PACK_AND_REMOVE            = "Pack and Remove",
        MENU_PACK_AND_REMOVE_ALL        = "Pack and Remove nearby",
        MENU_REMOVE_CRATES              = "Remove crates",
        MENU_REMOVE_CRATES_NEARBY       = "Remove crates nearby",
        MENU_LIST_CRATES_NEARBY         = "List crates nearby",
        MENU_CRATES_NEEDED              = "%d crate%s %s (%dkg)",
        MENU_CRATE_SINGLE               = "%s (%dkg)",
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
        TROOPS_LABEL                    = "Truppen",
        ENGINEERS_LABEL                 = "Pioniere",
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
        MENU_SCAN_PACKABLE_UNITS        = "Packbare Einheiten in der Nähe scannen",
        MENU_NO_PACKABLE_UNITS_FOUND_RESCAN = "Keine packbaren Einheiten gefunden! Neu scannen?",
        MENU_PACK_ALL                   = "In der Nähe packen",
        MENU_PACK_AND_LOAD              = "Packen und laden",
        MENU_PACK_AND_LOAD_ALL          = "In der Nähe packen und laden",
        MENU_PACK_AND_REMOVE            = "Packen und entfernen",
        MENU_PACK_AND_REMOVE_ALL        = "In der Nähe packen und entfernen",
        MENU_REMOVE_CRATES              = "Kisten entfernen",
        MENU_REMOVE_CRATES_NEARBY       = "Nahe Kisten entfernen",
        MENU_LIST_CRATES_NEARBY         = "Nahe Kisten auflisten",
        MENU_CRATES_NEEDED              = "%d Kiste%s %s (%dkg)",
        MENU_CRATE_SINGLE               = "%s (%dkg)",
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
        TROOPS_LABEL                    = "troupes",
        ENGINEERS_LABEL                 = "sapeurs",
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
        MENU_SCAN_PACKABLE_UNITS        = "Scanner unités emballables à proximité",
        MENU_NO_PACKABLE_UNITS_FOUND_RESCAN = "Aucune unité emballable trouvée ! Rescanner ?",
        MENU_PACK_ALL                   = "Emballer à proximité",
        MENU_PACK_AND_LOAD              = "Emballer et charger",
        MENU_PACK_AND_LOAD_ALL          = "Emballer et charger à proximité",
        MENU_PACK_AND_REMOVE            = "Emballer et retirer",
        MENU_PACK_AND_REMOVE_ALL        = "Emballer et retirer à proximité",
        MENU_REMOVE_CRATES              = "Retirer caisses",
        MENU_REMOVE_CRATES_NEARBY       = "Retirer caisses proches",
        MENU_LIST_CRATES_NEARBY         = "Lister caisses proches",
        MENU_CRATES_NEEDED              = "%d caisse%s %s (%dkg)",
        MENU_CRATE_SINGLE               = "%s (%dkg)",
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
    ES={
      CRATE_LOADED_GROUNDCREW="Contenedor %s cargado por el quipo de tierra.",
      CRATE_UNLOADED_GROUNDCREW="Contenedor %s descargado por el quipo de tierra.",
      CRATE_LOADED_ID="Contenedor ID %d para %s cargado.",
      LOADED_FULL="Cargado %d %s.",
      LOADED_SETS_LEFTOVER="Cargado %d %s(s), de %d contenedor(es) restante(s).",
      LOADED_SETS="Cargado %d %s(s).",
      LOADED_PARTIAL="Cargado sólo %d/%d contenedor(es) de %s.",
      LOADED_PARTIAL_LIMIT="Cargado sólo %d/%d contenedor(es) de %s. Límite de carga alcanzado.",
      LOADED_BATCH="Cargado %d %s.",
      LOADED_BATCH_PARTIAL="Some sets could not be fully loaded.",
      DROPPED_FULL="Entregado %d %s.",
      DROPPED_SETS_LEFTOVER="Entregado %d %s(s), de %d conenedor(es) restante(s).",
      DROPPED_SETS="Entregado %d %s(s).",
      DROPPED_PARTIAL="Entregado %d/%d contenedor(es) de %s.",
      DROPPED_INTO_ACTION="¡Soltados %s en acción!",
      DROPPED_BEACON="Entregado %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
      CRATES_POSITIONED="%d contenedores para %s servidos cerca de ti.",
      CRATES_DROPPED="%d contenedores para %s han sido entregados.",
      BOARDED="¡%s a bordo!",
      BOARDING="¡%s entrando!",
      TROOPS_RETURNED="¡Las tropas han vuelto a la base!",
      TROOPS_LABEL="tropas",
      ENGINEERS_LABEL="ingenieros",
      DEPLOYED_NEAR_YOU="%s han sido servidas cerca de tí.",
      UNITS_REMOVED="%s ha sido eliminado",
      BUILD_STARTED="Construcción comenzada, listo en %d segundos.",
      REPAIR_STARTED="Reparación comenzaza usando %s, tardará %d segundos.",
      NO_UNIT_TO_REPAIR="No hay unidades cercanas que necesiten reparación.",
      CANT_REPAIR_WITH="No se puede reparar esta unidad con %s",
      CRATES_MOVE_BEFORE_BUILD="*** Los contenedores deben ser movidos antes de construirse.",
      CHOPPER_CANNOT_CARRY="Lo siento, este helicóptero no puede transportar contenedores.",
      TOO_HEAVY="Lo siento, esta carga es muy pesada.",
      FULLY_LOADED="Lo siento, vamos hasta arriba.",
      CRAMMED="Lo siento, vamos a tope.",
      NO_CAPACITY_NOW="No queda capacidad para cargar más.",
      NO_MORE_CAPACITY="No queda capacidad para cargar más contenedores.",
      CANNOT_LOAD_NONE_OR_FULL="No se pueden cargar contenedores: n hay o no queda capacidad.",
      NEED_TO_LAND_OR_HOVER_LOAD="Necesitas aterrizar o mantenerte en estacionario para cargar.",
      HOVER_OVER_CRATES="Mantente en estacionario sobre el contenedor para recogerlo.",
      LAND_OR_HOVER_OVER_CRATES="Aterriza o mantente en estacionario para recoger el contenedor.",
      MUST_LAND_OR_HOVER_CRATES="Necesitas aterrizar o mantenerte en eestacionario para cargar contenedores.",
      NEED_TO_LAND_BUILD="Necesitas aterrizar/parar para construir algo.",
      NOT_CLOSE_ENOUGH_LOGISTICS="No estás cerca de una zona de logística.",
      NOT_CLOSE_ENOUGH_DROP="No estás en una zona de entrega.",
      NOT_CLOSE_ENOUGH_ZONE_NM="Negativo, tienes que estar a menos de %dnm de la zona.",
      CANNOT_BUILD_LOADING_AREA="No puedes construir en la zona de carga.",
      OPEN_DOORS_LOAD_CARGO="Necesitas abrir las puertas para cargar.",
      OPEN_DOORS_LOAD_TROOPS="Necesitas abrir las puertas para que embarquen las tropas.",
      OPEN_DOORS_EXTRACT_TROOPS="Necesitas abrir las puertas para poder sacar a las tropas de aquí.",
      OPEN_DOORS_UNLOAD_TROOPS="Necesitas abrir las puertas para que desembarquen las tropas.",
      OPEN_DOORS_DROP_CARGO="Necesitas abrir las puertas para descargar la carga.",
      ALL_GONE="Lo siento, todos %s se han servido.",
      RAN_OUT_OF="Lo siento, nos hemos quedad sin %s",
      CARGO_NOT_AVAILABLE_ZONE="La carga solicitada no está disponible en esta zona.",
      ENOUGH_CRATES_NEARBY="Hay contenedores cerca de ti listas. Encárgate primero de ellos.",
      NO_CRATES_WITHIN="No ha contenedores (cargables) en %d metros.",
      NO_CRATES_WITHIN_PLAIN="No hay contenedores en %d metros.",
      NO_CRATES_IN_RANGE="No se han encontrado contenedores en rango.",
      NO_NAMED_CRATES_IN_RANGE="No se han encontrado \"%s\" conenedores en rango.",
      NO_LOADABLE_CRATES="Lo siento, no hay contenedores cercanos o se ha alcanzado el peso máximo.",
      NO_UNITS_TO_EXTRACT="No hay unidades cercanas para extracción.",
      NO_UNIT_CONFIG="No se ha encontrado configuración de unidad para %s",
      CANT_ONBOARD="No puede subir %s",
      TOO_MANY_UNITS_NEARBY="Ya tienes %d unidades próximas.",
      NO_CRATE_GROUPS="No se han encontrado grupos de contendeores para esta unidad.",
      NO_CRATE_SET="No se ha encontrado contenedor o su index es inválido.",
      NO_CRATE_IN_SET="No se ha encontrado contenedor para este set.",
      NO_TROOP_CHUNK="No se han encontrado tropas para el id %d!",
      TROOP_CHUNK_EMPTY="Troop chunk is empty for ID %d!",
      NOTHING_LOADED="Nada cargado.\nLímite tropas: %d | Límite contenedores: %d | Peso límite: %d kg.",
      NOTHING_LOADED_AIRDROP="Nada cargado o no estás en parámetros de lanzamiento aéreo.",
      NOTHING_LOADED_HOVER="Nada cargado o no estás en parámetros de estacionario.",
      NOTHING_IN_STOCK="¡Nada en stock!",
      NOTHING_TO_PACK="Nada para empaquetar a esta distancia.",
      NOTHING_TO_REMOVE="Nada para eliminar a esta distancia.",
      ROGER_ZONE="Recibido, %s cona %s!",
      HOVER_PARAMS_METRIC="Parámetros en estacionario (autocarga/suelta):\n - Altura mínima %dm \n - Altura máxima %dm \n - Velocidad máxima 2mps \n - En parámetros: %s",
      HOVER_PARAMS_IMPERIAL="Parámetros en estacionario (autocarga/suelta):\n - Altura mínima  %dft \n - Altura máxima %dft \n - Velocidad máxima 6ftps \n - En parámetros: %s",
      FLIGHT_PARAMS_IMPERIAL="Parámetros vuelo (lanzamiento aéreo):\n - Altura mínima  %dft \n - Altura máxima %dft \n - En parámetros: %s",
      FLIGHT_PARAMS_METRIC="Parámetros vuelo (lanzamiento aéreo):\n - Altura mínima  %dm \n - Altura máxima %dm \n - En parámetros: %s",
      REPORT_CRATES_FOUND="Contenedores encontrados cerca:",
      REPORT_REMOVING_CRATES="Contenedores eliminados cerca:",
      REPORT_TRANSPORT_CHECKOUT="Informe de transporte",
      REPORT_INVENTORY="Inventario",
      REPORT_BUILD_CHECKLIST="Contenedores construibles",
      REPORT_REPAIR_CHECKLIST="Reparaciones",
      REPORT_BEACONS="Active Zone Beacons",
      REPORT_SECTION_TROOPS="        -- TROPAS --",
      REPORT_SECTION_CRATES="    -- CONTENEDORES --",
      REPORT_SECTION_CRATES_GC="       -- Contenedores cargados por equipo de tierra --",
      REPORT_SECTION_NONE="        N A D A",
      REPORT_SECTION_NONE_ALT="     --- Nada encontrado ---",
      REPORT_SECTION_NONE_REPAIR="     --- Nada encontrado ---",
      REPORT_GC_LOADABLE_HINT="Probablemente cargable por el equipo de tierra (F8)",
      REPORT_TOTAL_MASS="Peso total: %s kg. Cargable: %s kg.",
      REPORT_TROOPS_CRATES_COUNT="Tropas: %d(%d), Contenedores: %d(%d)",
      REPORT_TROOPS_CRATETYPES_COUNT="Tropas: %d, Tipos contenedores: %d",
      REPORT_ROW_TROOP="Tropas: %s tamaño %d",
      REPORT_ROW_CRATE="Contenedores: %s %d/%d",
      REPORT_ROW_CRATE_SIZE1="Contenedores: %s tamaño 1",
      REPORT_ROW_GC_CRATE="Contenedores cargados: %s tamaño 1",
      REPORT_ROW_DROPPED_CRATE="Entregado contenedor para %s, %dkg",
      REPORT_ROW_CRATE_KG="Contenedor para %s, %dkg",
      REPORT_ROW_CRATE_REMOVED="Contenedor para %s, %dkg eliminado",
      REPORT_ROW_UNIT_STOCK="Unidad: %s | Soldados: %d | Stock: %s",
      REPORT_ROW_TYPE_CRATE_STOCK="Tipo: %s | Contenedores por set: %d | Stock: %s",
      REPORT_ROW_TYPE_STOCK="Tipo: %s | Stock: %s",
      REPORT_ROW_BUILD_CHECK="Tipo: %s | Rquiere %d | Encontrados %d | Construible %s",
      REPORT_ROW_REPAIR_CHECK="Tipo: %s | Requiere %d | Encontrados %d | Reparable %s",
      REPORT_ROW_BEACON=" %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
      WEIGHT_LIMIT="Alcanzado límite de pesoWeight limit reached",
      CRATE_LIMIT="Alcanzado límite contenedores",
      MENU_CTLD="CTLD",
      MENU_MANAGE_TROOPS="Gestionar tropas",
      MENU_MANAGE_CRATES="Gestionar contenedores",
      MENU_MANAGE_UNITS="Gestionar unidades",
      MENU_LOAD_TROOPS="Cargar tropas",
      MENU_DROP_TROOPS="Entregar tropas",
      MENU_DROP_ALL_TROOPS="Entregar TODAS tropas",
      MENU_EXTRACT_TROOPS="Extraer tropas",
      MENU_DROP_N_TROOPS="Soltar (%d) %s",
      MENU_GET_CRATES="Solicitar contenedores",
      MENU_GET="Solicitar",
      MENU_GET_AND_LOAD="Solicitar y cargar",
      MENU_GET_ANYWAY="Solicitar de todas formas",
      MENU_PARTIALLY_LOAD="Carga parcial",
      MENU_OUT_OF_STOCK="Sin stock",
      MENU_TROOP_LIMIT="Limite de tropas alcanzado",
      MENU_LOAD_CRATES="Cargar contenedores",
      MENU_LOAD_ALL="Cargar TODO",
      MENU_SHOW_LOADABLE_CRATES="Mostrar contenedores carbables",
      MENU_NO_CRATES_FOUND_RESCAN="Contenedores no encontrados, ¿buscar?",
      MENU_USE_C130_LOAD="Usar sistmea de carga del C-130",
      MENU_LOAD_SINGLE="Cargar",
      MENU_DROP_CRATES="Soltar cargas",
      MENU_DROP_ALL_CRATES="Soltar TODAS cargas",
      MENU_DROP="Soltar",
      MENU_DROP_AND_BUILD="Soltar y constuir",
      MENU_DROP_N_SETS="Soltar %d Set %s",
      MENU_NO_CRATES_TO_DROP="No hay cargas para soltar",
      MENU_BUILD_CRATES="Construir contenedores",
      MENU_REPAIR="Reparar",
      MENU_PACK_CRATES="Empaquetar cargas",
      MENU_PACK="Empaquetar",
      MENU_SCAN_PACKABLE_UNITS="Buscar unidades empaquetables cercanas",
      MENU_NO_PACKABLE_UNITS_FOUND_RESCAN="No se encontraron unidades empaquetables. ¿Buscar de nuevo?",
      MENU_PACK_ALL="Empaquetar cercanas",
      MENU_PACK_AND_LOAD="Empaquetar y cargar",
      MENU_PACK_AND_LOAD_ALL="Empaquetar y cargar cercanas",
      MENU_PACK_AND_REMOVE="Empaquetar y eliminar",
      MENU_PACK_AND_REMOVE_ALL="Empaquetar y eliminar cercanas",
      MENU_REMOVE_CRATES="Eliminar cargas",
      MENU_REMOVE_CRATES_NEARBY="Eliminar cargas cercanas",
      MENU_LIST_CRATES_NEARBY="Listar cargas cercanas",
      MENU_CRATES_NEEDED="%d contenedor%s %s (%dkg)",
      MENU_CRATE_SINGLE="%s (%dkg)",
      MENU_GET_UNITS="Obtener unidades",
      MENU_REMOVE_UNITS_NEARBY="Eliminar unidades cercanas",
      MENU_LIST_BOARDED_CARGO="Lista de cargas a bordo",
      MENU_INVENTORY="Inventario",
      MENU_LIST_ZONE_BEACONS="Lista de balizas activas",
      MENU_SMOKES_FLARES_BEACONS="Humos, Bengalas, Balizas",
      MENU_SMOKE_ZONES_NEARBY="Humo en zonas cercanas",
      MENU_DROP_SMOKE_NOW="Lanzar humo ahora",
      MENU_RED_SMOKE="Humo rojo",
      MENU_BLUE_SMOKE="Humo azul",
      MENU_GREEN_SMOKE="Humo verde",
      MENU_ORANGE_SMOKE="Humo naranja",
      MENU_WHITE_SMOKE="Humo blanco",
      MENU_FLARE_ZONES_NEARBY="Bengalas en zonas cercanas",
      MENU_FIRE_FLARE_NOW="Disparar bengala ahora",
      MENU_DROP_BEACON_NOW="Soltar baliza ahora",
      MENU_SHOW_FLIGHT_PARAMS="Mostrar parámetros de vuelo",
      MENU_SHOW_HOVER_PARAMS="Mostrar parámetros estacionario",
      STOCK_NONE="Nada",
      STOCK_UNLIMITED="ilimitado",
      BUILD_YES="SI",
      BUILD_NO="NO",
      },
    IT = {
        -- ============================================================
        -- Crate / Cargo Loading
        -- ============================================================
        CRATE_LOADED_GROUNDCREW         = "Cassa %s caricata dal personale di terra!",
        CRATE_UNLOADED_GROUNDCREW       = "Cassa %s scaricata dal personale di terra!",
        CRATE_LOADED_ID                 = "ID cassa %d per %s caricato!",
        LOADED_FULL                     = "Caricato %d %s.",
        LOADED_SETS_LEFTOVER            = "Caricato %d %s(s), con %d casse rimanenti.",
        LOADED_SETS                     = "Caricato %d %s(s).",
        LOADED_PARTIAL                  = "Caricato solo %d/%d casse di %s.",
        LOADED_PARTIAL_LIMIT            = "Caricato solo %d/%d casse di %s. Il limite di carico è stato raggiunto.!",
        LOADED_BATCH                    = "Caricato %d %s.",
        LOADED_BATCH_PARTIAL            = "Alcuni set non sono stati caricati completamente.",
        -- ============================================================
        -- Dropping / Unloading
        -- ============================================================
        DROPPED_FULL                    = "Scaricati %d %s.",
        DROPPED_SETS_LEFTOVER           = "Sono stati scaricati %d %s(s), con %d casse rimanenti.",
        DROPPED_SETS                    = "Scaricati %d %s(s).",
        DROPPED_PARTIAL                 = "Scaricati %d/%d cassa(e) di %s.",
        DROPPED_INTO_ACTION             = "Scaricati %s in azione!",
        DROPPED_BEACON                  = "Scaricati %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        CRATES_POSITIONED               = "%d Le casse per %s sono state posizionate vicino a te!",
        CRATES_DROPPED                  = "%d casse per %s sono state rilasciate!",
        -- ============================================================
        -- Troops
        -- ============================================================
        BOARDED                         = "%s a bordo!",
        BOARDING                        = "%s Imbarco!",
        TROOPS_RETURNED                 = "Le truppe sono rientrate alla base!",
        TROOPS_LABEL                    = "Ttuppe",
        ENGINEERS_LABEL                 = "Ingenieri",
        -- ============================================================
        -- Deployment
        -- ============================================================
        DEPLOYED_NEAR_YOU               = "%s sono stati dispiegati vicino a te!",
        UNITS_REMOVED                   = "%s sono stati rimossi",
        -- ============================================================
        -- Build / Repair
        -- ============================================================
        BUILD_STARTED                   = "Costruzione avviata, pronta tra %d secondi!",
        REPAIR_STARTED                  = "Riparazione avviata utilizzando %s e impiegando %d secondi",
        NO_UNIT_TO_REPAIR               = "Nessuna unità è abbastanza vicina per essere riparata!",
        CANT_REPAIR_WITH                = "Non è possibile riparare questa unità con %s",
        CRATES_MOVE_BEFORE_BUILD        = "*** Le casse devono essere spostate prima della costruzione.!",
        -- ============================================================
        -- Errors - Chopper / Weight / Capacity
        -- ============================================================
        CHOPPER_CANNOT_CARRY            = "Spiacenti, questo elicottero non può trasportare casse!",
        TOO_HEAVY                       = "Mi dispiace, è troppo pesante da caricare.!",
        FULLY_LOADED                    = "Ci dispiace, abbiamo raggiunto la capacità massima!",
        CRAMMED                         = "Ci dispiace, siamo già pieni.!",
        NO_CAPACITY_NOW                 = "Impossibile caricare altro al momento!",
        NO_MORE_CAPACITY                = "Non c'è più capacità di carico per le casse!",
        CANNOT_LOAD_NONE_OR_FULL        = "Impossibile caricare le casse: non ne sono state trovate oppure non c'è più spazio disponibile.",
        -- ============================================================
        -- Errors - Position
        -- ============================================================
        NEED_TO_LAND_OR_HOVER_LOAD      = "È necessario atterrare o rimanere in posizione per caricare!",
        HOVER_OVER_CRATES               = "Resta in hover sopra le casse per raccoglierle!",
        LAND_OR_HOVER_OVER_CRATES       = "Atterra o sorvola le casse per raccoglierle!",
        MUST_LAND_OR_HOVER_CRATES       = "Devi atterrare o rimanere in volo stazionario per caricare le casse!",
        NEED_TO_LAND_BUILD              = "Devi atterrare/fermarti per costruire qualcosa, pilota!",
        NOT_CLOSE_ENOUGH_LOGISTICS      = "Non sei abbastanza vicino a una zona logistica!",
        NOT_CLOSE_ENOUGH_DROP           = "Non sei abbastanza vicino a una zona di lancio!",
        NOT_CLOSE_ENOUGH_ZONE_NM        = "Negativo, è necessario essere più vicini di %dnm a una zona!",
        CANNOT_BUILD_LOADING_AREA       = "Non è possibile costruire in un'area di carico, Pilota!",
        -- ============================================================
        -- Errors - Doors
        -- ============================================================
        OPEN_DOORS_LOAD_CARGO           = "È necessario aprire la/le porta/e per caricare la merce!",
        OPEN_DOORS_LOAD_TROOPS          = "È necessario aprire la/le porta/e per caricare le truppe!",
        OPEN_DOORS_EXTRACT_TROOPS       = "È necessario aprire la/le porta/e per estrarre le truppe!",
        OPEN_DOORS_UNLOAD_TROOPS        = "Devi aprire la/le porta/e per far scendere le truppe!",
        OPEN_DOORS_DROP_CARGO           = "È necessario aprire la/le porta/e per scaricare il carico!",
        -- ============================================================
        -- Errors - Stock / Availability
        -- ============================================================
        ALL_GONE                        = "Spiacenti, tutti i %s sono esauriti!",
        RAN_OUT_OF                      = "Ci dispiace, abbiamo finito %s",
        CARGO_NOT_AVAILABLE_ZONE        = "Il carico richiesto non è disponibile in questa zona!",
        ENOUGH_CRATES_NEARBY            = "Ci sono già abbastanza casse qui vicino! Occupati prima di quelle!",
        NO_CRATES_WITHIN                = "Nessuna cassa (caricabile) entro %d metri!",
        NO_CRATES_WITHIN_PLAIN          = "Niente casse entro %d metri!",
        NO_CRATES_IN_RANGE              = "Nessuna cassa trovata nel raggio d'azione!",
        NO_NAMED_CRATES_IN_RANGE        = "Nessuna \"%s\" Casse trovate nel raggio d'azione!",
        NO_LOADABLE_CRATES              = "Spiacenti, nessuna cassa caricabile nelle vicinanze oppure peso massimo del carico raggiunto!",
        NO_UNITS_TO_EXTRACT             = "Nessuna unità è abbastanza vicina per l'estrazione!",
        NO_UNIT_CONFIG                  = "Nessuna configurazione dell'unità trovata per %s",
        CANT_ONBOARD                    = "Impossibile salire a bordo %s",
        TOO_MANY_UNITS_NEARBY           = "Hai già %d unità nelle vicinanze!",
        NO_CRATE_GROUPS                 = "Nessun gruppo di casse trovato per questa unità!",
        NO_CRATE_SET                    = "Nessun set di casse trovato o indice non valido!",
        NO_CRATE_IN_SET                 = "Nessuna cassa trovata in quel set!",
        NO_TROOP_CHUNK                  = "Nessun blocco di carico truppe trovato per l'ID %d!",
        TROOP_CHUNK_EMPTY               = "Il blocco truppe è vuoto per l'ID %d!",
        -- ============================================================
        -- Nothing loaded / in stock
        -- ============================================================
        NOTHING_LOADED                  = "Nessun caricamento effettuato!\nLimite truppe: %d | Limite casse: %d | Limite peso: %d kg",
        NOTHING_LOADED_AIRDROP          = "Nessun file caricato o non conforme ai parametri di AirDrop.!",
        NOTHING_LOADED_HOVER            = "Nessun caricamento effettuato o il puntatore del mouse non si trova all'interno dei parametri!",
        NOTHING_IN_STOCK                = "Nessun prodotto disponibile!",
        NOTHING_TO_PACK                 = "Nothing to pack at this distance pilot!",
        NOTHING_TO_REMOVE               = "Niente da rimuovere a questa distanza pilota!",
        -- ============================================================
        -- Zone / Info
        -- ============================================================
        ROGER_ZONE                      = "Roger, %s Zona %s!",
        -- ============================================================
        -- Report: Hover / Flight Parameters
        -- ============================================================
        HOVER_PARAMS_METRIC             = "Hover parametri (caricamento/rilascio automatico):\n - Altezza minima %dm \n - Altezza massima %dm \n - Velocità massima 2mps \n - Nel parametro: %s",
        HOVER_PARAMS_IMPERIAL           = "Hover parametri (caricamento/rilascio automatico):\n - Altezza minima %dft \n - Altezza massima %dft \n - Velocità massima 6ftps \n - Nel parametro: %s",
        FLIGHT_PARAMS_IMPERIAL          = "Flight parameters (airdrop):\n - Altezza minima %dft \n -Altezza massima %dft \n - Nel parametro: %s",
        FLIGHT_PARAMS_METRIC            = "Flight parameters (airdrop):\n - Altezza minima %dm \n - Altezza massima %dm \n - Nel parametro: %s",
        -- ============================================================
        -- Report Titles  (REPORT:New())
        -- ============================================================
        REPORT_CRATES_FOUND             = "Casse trovate nelle vicinanze:",
        REPORT_REMOVING_CRATES          = "Rimozione delle casse trovate nelle vicinanze:",
        REPORT_TRANSPORT_CHECKOUT       = "Documento di verifica del trasporto",
        REPORT_INVENTORY                = "Documento di inventario",
        REPORT_BUILD_CHECKLIST          = "Checklist Buildable Crates",
        REPORT_REPAIR_CHECKLIST         = "Lista di controllo per le riparazioni",
        REPORT_BEACONS                  = "Segnalatori di zona attiva",
        -- ============================================================
        -- Report Section Headers  (report:Add())
        -- ============================================================
        REPORT_SECTION_TROOPS           = "        -- TRUPPE --",
        REPORT_SECTION_CRATES           = "       -- CASSE --",
        REPORT_SECTION_CRATES_GC        = "       -- CASSE caricate tramite Ground Crew --",
        REPORT_SECTION_NONE             = "        NESSUNO",
        REPORT_SECTION_NONE_ALT         = "     --- Nessun risultato trovato! ---",
        REPORT_SECTION_NONE_REPAIR      = "     --- Nessun risultato trovato ---",
        REPORT_GC_LOADABLE_HINT         = "Probabilmente caricabile dal personale di terra (F8)",
        REPORT_TOTAL_MASS               = "Massa totale: %s kg. Caricabile: %s kg.",
        REPORT_TROOPS_CRATES_COUNT      = "Truppe: %d(%d), Casse: %d(%d)",
        REPORT_TROOPS_CRATETYPES_COUNT  = "Truppe: %d, Tipi di casse: %d",
        -- ============================================================
        -- Report Row Templates  (per-item lines in reports)
        -- ============================================================
        REPORT_ROW_TROOP                = "Truppa: %s dimensione %d",
        REPORT_ROW_CRATE                = "Casse: %s %d/%d",
        REPORT_ROW_CRATE_SIZE1          = "Cassa: %s dimensione 1",
        REPORT_ROW_GC_CRATE             = "GC Cassa caricata: %s dimensione 1",
        REPORT_ROW_DROPPED_CRATE        = "Cassa scaricata per %s, %dkg",
        REPORT_ROW_CRATE_KG             = "Cassa per %s, %dkg",
        REPORT_ROW_CRATE_REMOVED        = "Cassa per %s, %dkg rimossa",
        REPORT_ROW_UNIT_STOCK           = "Unità: %s | Soldati: %d | Stock: %s",
        REPORT_ROW_TYPE_CRATE_STOCK     = "Tipo: %s | Casse per set: %d | Stock: %s",
        REPORT_ROW_TYPE_STOCK           = "Tipo: %s | Stock: %s",
        REPORT_ROW_BUILD_CHECK          = "Tipo: %s | Richiesto %d | Trovato %d | puo' essere costruita %s",
        REPORT_ROW_REPAIR_CHECK         = "Tipo: %s | Richiesto %d | Trovato %d | Riparabile %s",
        REPORT_ROW_BEACON               = " %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        -- ============================================================
        -- Weight / Crate limit tokens
        -- ============================================================
        WEIGHT_LIMIT                    = "Limite di peso raggiunto",
        CRATE_LIMIT                     = "Limite di casse raggiunto",
        -- ============================================================
        -- Menu labels - Top level
        -- ============================================================
        MENU_CTLD                       = "CTLD",
        MENU_MANAGE_TROOPS              = "Gestire le truppe",
        MENU_MANAGE_CRATES              = "Gestisci casse",
        MENU_MANAGE_UNITS               = "Gestisci unita'",
        -- ============================================================
        -- Menu labels - Troops
        -- ============================================================
        MENU_LOAD_TROOPS                = "Carica truppe",
        MENU_DROP_TROOPS                = "Scarica truppe",
        MENU_DROP_ALL_TROOPS            = "Scarica tutte le truppe",
        MENU_EXTRACT_TROOPS             = "Estrai truppe",
        MENU_DROP_N_TROOPS              = "Scarica (%d) %s",
        -- ============================================================
        -- Menu labels - Crates: Get
        -- ============================================================
        MENU_GET_CRATES                 = "Prendi casse",
        MENU_GET                        = "Prendi",
        MENU_GET_AND_LOAD               = "Prendi e carica",
        MENU_GET_ANYWAY                 = "Prendi comunque",
        MENU_PARTIALLY_LOAD             = "Carico parziale",
        MENU_OUT_OF_STOCK               = "Esaurito",
        MENU_TROOP_LIMIT                = "Limite truppe raggiunto",
        -- ============================================================
        -- Menu labels - Crates: Load
        -- ============================================================
        MENU_LOAD_CRATES                = "Carica casse",
        MENU_LOAD_ALL                   = "Carica tutto",
        MENU_SHOW_LOADABLE_CRATES       = "Mostra casse caricate",
        MENU_NO_CRATES_FOUND_RESCAN     = "Nessuna cassa trovata! Esegui una nuova scansione.?",
        MENU_USE_C130_LOAD              = "Utilizzare il sistema di carico C-130",
        MENU_LOAD_SINGLE                = "Carica",
        -- ============================================================
        -- Menu labels - Crates: Drop
        -- ============================================================
        MENU_DROP_CRATES                = "Scarica casse",
        MENU_DROP_ALL_CRATES            = "Scarica tutte le casse",
        MENU_DROP                       = "Scarica",
        MENU_DROP_AND_BUILD             = "Scarica e costruisci",
        MENU_DROP_N_SETS                = "Scarica %d Set%s",
        MENU_NO_CRATES_TO_DROP          = "Nessuna cassa da scaricare!",
        -- ============================================================
        -- Menu labels - Crates: Build / Repair / Pack / Remove
        -- ============================================================
        MENU_BUILD_CRATES               = "Sballa le casse",
        MENU_REPAIR                     = "Ripara",
        MENU_PACK_CRATES                = "Casse da imballaggio",
        MENU_PACK                       = "Imballaggio",
        MENU_SCAN_PACKABLE_UNITS        = "Scansiona le unità imballabili nelle vicinanze",
        MENU_NO_PACKABLE_UNITS_FOUND_RESCAN = "Nessuna unità imballabile trovata! Esegui una nuova scansione.?",
        MENU_PACK_ALL                   = "Pacchetto nelle vicinanze",
        MENU_PACK_AND_LOAD              = "Imballare e caricare",
        MENU_PACK_AND_LOAD_ALL          = "Imballaggio e carico nelle vicinanze",
        MENU_PACK_AND_REMOVE            = "Imballare e rimuovere",
        MENU_PACK_AND_REMOVE_ALL        = "Imballare e rimuovere nelle vicinanze",
        MENU_REMOVE_CRATES              = "Rimuovere le casse",
        MENU_REMOVE_CRATES_NEARBY       = "Rimuovere le casse nelle vicinanze",
        MENU_LIST_CRATES_NEARBY         = "Elenco delle casse nelle vicinanze",
        MENU_CRATES_NEEDED              = "%d cass%s %s (%dkg)",
        MENU_CRATE_SINGLE               = "%s (%dkg)",
        -- ============================================================
        -- Menu labels - Units (C-130)
        -- ============================================================
        MENU_GET_UNITS                  = "Ottieni unità",
        MENU_REMOVE_UNITS_NEARBY        = "Rimuovere le unità vicine",
        -- ============================================================
        -- Menu labels - Info / Cargo
        -- ============================================================
        MENU_LIST_BOARDED_CARGO         = "Lista del carico a bordo",
        MENU_INVENTORY                  = "Inventario",
        MENU_LIST_ZONE_BEACONS          = "Elenco dei beacon di zona attivi",
        -- ============================================================
        -- Menu labels - Smokes / Flares / Beacons
        -- ============================================================
        MENU_SMOKES_FLARES_BEACONS      = "Fumogeni, razzi, segnalatori luminosi",
        MENU_SMOKE_ZONES_NEARBY         = "Fumogeni nelle vicinanze",
        MENU_DROP_SMOKE_NOW             = "Scarica fumogeni ora",
        MENU_RED_SMOKE                  = "Fumogeno rosso",
        MENU_BLUE_SMOKE                 = "Fumogeno blu",
        MENU_GREEN_SMOKE                = "Fumogeno verde",
        MENU_ORANGE_SMOKE               = "Fumogeno arancione",
        MENU_WHITE_SMOKE                = "Fumogeno bianco",
        MENU_FLARE_ZONES_NEARBY         = "Razzi di segnalazione nelle vicinanze",
        MENU_FIRE_FLARE_NOW             = "Razzi di segnalazione ora",
        MENU_DROP_BEACON_NOW            = "Scarica segnalatori luminosi",
        -- ============================================================
        -- Menu labels - Parameters
        -- ============================================================
        MENU_SHOW_FLIGHT_PARAMS         = "Mostra i parametri di volo",
        MENU_SHOW_HOVER_PARAMS          = "Mostra parametri di hovering",
        STOCK_NONE                      = "Nessuno",
        STOCK_UNLIMITED                 = "Illimitato",
        BUILD_YES                       = "SI",
        BUILD_NO                        = "NO",
    },

    ["PT-BR"] = {
        -- ============================================================
        -- Carregamento de caixa / carga
        -- ============================================================
        CRATE_LOADED_GROUNDCREW         = "Caixa %s carregada pela equipe de solo!",
        CRATE_UNLOADED_GROUNDCREW       = "Caixa %s descarregada pela equipe de solo!",
        CRATE_LOADED_ID                 = "Caixa ID %d para %s carregada!",
        LOADED_FULL                     = "%d %s carregado.",
        LOADED_SETS_LEFTOVER            = "%d %s carregado(s), com %d caixa(s) sobrando.",
        LOADED_SETS                     = "%d %s carregado(s).",
        LOADED_PARTIAL                  = "Carregado apenas %d/%d caixa(s) de %s.",
        LOADED_PARTIAL_LIMIT            = "Carregado apenas %d/%d caixa(s) de %s. O limite de carga foi atingido!",
        LOADED_BATCH                    = "%d %s carregado.",
        LOADED_BATCH_PARTIAL            = "Alguns conjuntos não puderam ser carregados completamente.",
        -- ============================================================
        -- Soltar / descarregar
        -- ============================================================
        DROPPED_FULL                    = "%d %s solto.",
        DROPPED_SETS_LEFTOVER           = "%d %s solto(s), com %d caixa(s) sobrando.",
        DROPPED_SETS                    = "%d %s solto(s).",
        DROPPED_PARTIAL                 = "%d/%d caixa(s) de %s solta(s).",
        DROPPED_INTO_ACTION             = "Unidades desembarcadas para a ação: %s!",
        DROPPED_BEACON                  = "Baliza %s posicionada | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        CRATES_POSITIONED               = "%d caixas para %s foram posicionadas perto de você!",
        CRATES_DROPPED                  = "%d caixas para %s foram soltas!",
        -- ============================================================
        -- Tropas
        -- ============================================================
        BOARDED                         = "%s embarcou!",
        BOARDING                        = "%s embarcando!",
        TROOPS_RETURNED                 = "As tropas retornaram à base!",
        TROOPS_LABEL                    = "tropas",
        ENGINEERS_LABEL                 = "engenheiros",
        -- ============================================================
        -- Implantação
        -- ============================================================
        DEPLOYED_NEAR_YOU               = "%s foram posicionados perto de você!",
        UNITS_REMOVED                   = "%s foram removidos",
        -- ============================================================
        -- Construir / reparar
        -- ============================================================
        BUILD_STARTED                   = "Construção iniciada, pronta em %d segundos!",
        REPAIR_STARTED                  = "Reparo iniciado usando %s, levando %d segundos",
        NO_UNIT_TO_REPAIR               = "Nenhuma unidade perto o suficiente para reparar!",
        CANT_REPAIR_WITH                = "Não é possível reparar esta unidade com %s",
        CRATES_MOVE_BEFORE_BUILD        = "*** As caixas precisam ser movidas antes da construção!",
        -- ============================================================
        -- Erros - Helicóptero / peso / capacidade
        -- ============================================================
        CHOPPER_CANNOT_CARRY            = "Desculpe, este helicóptero não pode carregar caixas!",
        TOO_HEAVY                       = "Desculpe, isso é pesado demais para carregar!",
        FULLY_LOADED                    = "Desculpe, estamos totalmente carregados!",
        CRAMMED                         = "Desculpe, já estamos lotados!",
        NO_CAPACITY_NOW                 = "Sem capacidade para carregar mais agora!",
        NO_MORE_CAPACITY                = "Não há mais capacidade para carregar caixas!",
        CANNOT_LOAD_NONE_OR_FULL        = "Não é possível carregar caixas: nenhuma encontrada ou sem capacidade restante.",
        -- ============================================================
        -- Erros - posição
        -- ============================================================
        NEED_TO_LAND_OR_HOVER_LOAD      = "Você precisa pousar ou pairar na posição para carregar!",
        HOVER_OVER_CRATES               = "Paire sobre as caixas para pegá-las!",
        LAND_OR_HOVER_OVER_CRATES       = "Pouse ou paire sobre as caixas para pegá-las!",
        MUST_LAND_OR_HOVER_CRATES       = "Você deve pousar ou pairar para carregar caixas!",
        NEED_TO_LAND_BUILD              = "Você precisa pousar / parar para construir algo, piloto!",
        NOT_CLOSE_ENOUGH_LOGISTICS      = "Você não está perto o suficiente de uma zona logística!",
        NOT_CLOSE_ENOUGH_DROP           = "Você não está perto o suficiente de uma zona de lançamento!",
        NOT_CLOSE_ENOUGH_ZONE_NM        = "Negativo, precisa estar a menos de %d nm de uma zona!",
        CANNOT_BUILD_LOADING_AREA       = "Você não pode construir em uma área de carregamento, piloto!",
        -- ============================================================
        -- Erros - portas
        -- ============================================================
        OPEN_DOORS_LOAD_CARGO           = "Você precisa abrir a(s) porta(s) para carregar carga!",
        OPEN_DOORS_LOAD_TROOPS          = "Você precisa abrir a(s) porta(s) para carregar tropas!",
        OPEN_DOORS_EXTRACT_TROOPS       = "Você precisa abrir a(s) porta(s) para extrair tropas!",
        OPEN_DOORS_UNLOAD_TROOPS        = "Você precisa abrir a(s) porta(s) para descarregar tropas!",
        OPEN_DOORS_DROP_CARGO           = "Você precisa abrir a(s) porta(s) para soltar carga!",
        -- ============================================================
        -- Erros - estoque / disponibilidade
        -- ============================================================
        ALL_GONE                        = "Desculpe, todos os %s acabaram!",
        RAN_OUT_OF                      = "Desculpe, ficamos sem %s",
        CARGO_NOT_AVAILABLE_ZONE        = "A carga solicitada não está disponível nesta zona!",
        ENOUGH_CRATES_NEARBY            = "Já há caixas suficientes por perto! Cuide delas primeiro!",
        NO_CRATES_WITHIN                = "Nenhuma caixa carregável em um raio de %d metros!",
        NO_CRATES_WITHIN_PLAIN          = "Nenhuma caixa em um raio de %d metros!",
        NO_CRATES_IN_RANGE              = "Nenhuma caixa encontrada no alcance!",
        NO_NAMED_CRATES_IN_RANGE        = "Nenhuma caixa \"%s\" encontrada no alcance!",
        NO_LOADABLE_CRATES              = "Desculpe, nenhuma caixa carregável por perto ou peso máximo de carga atingido!",
        NO_UNITS_TO_EXTRACT             = "Nenhuma unidade perto o suficiente para extrair!",
        NO_UNIT_CONFIG                  = "Nenhuma configuração de unidade encontrada para %s",
        CANT_ONBOARD                    = "Não é possível embarcar %s",
        TOO_MANY_UNITS_NEARBY           = "Você já tem %d unidades por perto!",
        NO_CRATE_GROUPS                 = "Nenhum grupo de caixas encontrado para esta unidade!",
        NO_CRATE_SET                    = "Nenhum conjunto de caixas encontrado ou índice inválido!",
        NO_CRATE_IN_SET                 = "Nenhuma caixa encontrada nesse conjunto!",
        NO_TROOP_CHUNK                  = "Nenhum bloco de carga de tropas encontrado para ID %d!",
        TROOP_CHUNK_EMPTY               = "O bloco de tropas está vazio para ID %d!",
        -- ============================================================
        -- Nada carregado / em estoque
        -- ============================================================
        NOTHING_LOADED                  = "Nada carregado!\nLimite de tropas: %d | Limite de caixas %d | Limite de peso %d kg",
        NOTHING_LOADED_AIRDROP          = "Nada carregado ou fora dos parâmetros de lançamento aéreo!",
        NOTHING_LOADED_HOVER            = "Nada carregado ou fora dos parâmetros de pairado!",
        NOTHING_IN_STOCK                = "Nada em estoque!",
        NOTHING_TO_PACK                 = "Nada para empacotar nesta distância, piloto!",
        NOTHING_TO_REMOVE               = "Nada para remover nesta distância, piloto!",
        -- ============================================================
        -- Zona / informações
        -- ============================================================
        ROGER_ZONE                      = "Entendido, zona %s %s!",
        -- ============================================================
        -- Relatório: parâmetros de pairado / voo
        -- ============================================================
        HOVER_PARAMS_METRIC             = "Parâmetros de pairado (carregamento automático/soltar):\n - Altura mínima %dm \n - Altura máxima %dm \n - Velocidade máxima 2mps \n - Dentro dos parâmetros: %s",
        HOVER_PARAMS_IMPERIAL           = "Parâmetros de pairado (carregamento automático/soltar):\n - Altura mínima %dft \n - Altura máxima %dft \n - Velocidade máxima 6ftps \n - Dentro dos parâmetros: %s",
        FLIGHT_PARAMS_IMPERIAL          = "Parâmetros de voo (lançamento aéreo):\n - Altura mínima %dft \n - Altura máxima %dft \n - Dentro dos parâmetros: %s",
        FLIGHT_PARAMS_METRIC            = "Parâmetros de voo (lançamento aéreo):\n - Altura mínima %dm \n - Altura máxima %dm \n - Dentro dos parâmetros: %s",
        -- ============================================================
        -- Títulos de relatório (REPORT:New())
        -- ============================================================
        REPORT_CRATES_FOUND             = "Caixas encontradas por perto:",
        REPORT_REMOVING_CRATES          = "Removendo caixas encontradas por perto:",
        REPORT_TRANSPORT_CHECKOUT       = "Ficha de verificação de transporte",
        REPORT_INVENTORY                = "Ficha de inventário",
        REPORT_BUILD_CHECKLIST          = "Checklist de caixas construíveis",
        REPORT_REPAIR_CHECKLIST         = "Checklist de reparos",
        REPORT_BEACONS                  = "Balizas de zona ativas",
        -- ============================================================
        -- Cabeçalhos de seção do relatório (report:Add())
        -- ============================================================
        REPORT_SECTION_TROOPS           = "        -- TROPAS --",
        REPORT_SECTION_CRATES           = "       -- CAIXAS --",
        REPORT_SECTION_CRATES_GC        = "       -- CAIXAS carregadas pela equipe de solo --",
        REPORT_SECTION_NONE             = "        N E N H U M",
        REPORT_SECTION_NONE_ALT         = "     --- Nada encontrado! ---",
        REPORT_SECTION_NONE_REPAIR      = "     --- Nada encontrado ---",
        REPORT_GC_LOADABLE_HINT         = "Provavelmente carregável pela equipe de solo (F8)",
        REPORT_TOTAL_MASS               = "Massa total: %s kg. Carregável: %s kg.",
        REPORT_TROOPS_CRATES_COUNT      = "Tropas: %d(%d), Caixas: %d(%d)",
        REPORT_TROOPS_CRATETYPES_COUNT  = "Tropas: %d, Tipos de caixas: %d",
        -- ============================================================
        -- Modelos de linha do relatório (linhas por item)
        -- ============================================================
        REPORT_ROW_TROOP                = "Tropa: %s tamanho %d",
        REPORT_ROW_CRATE                = "Caixa: %s %d/%d",
        REPORT_ROW_CRATE_SIZE1          = "Caixa: %s tamanho 1",
        REPORT_ROW_GC_CRATE             = "Caixa carregada pela equipe de solo: %s tamanho 1",
        REPORT_ROW_DROPPED_CRATE        = "Caixa solta para %s, %dkg",
        REPORT_ROW_CRATE_KG             = "Caixa para %s, %dkg",
        REPORT_ROW_CRATE_REMOVED        = "Caixa para %s, %dkg removida",
        REPORT_ROW_UNIT_STOCK           = "Unidade: %s | Soldados: %d | Estoque: %s",
        REPORT_ROW_TYPE_CRATE_STOCK     = "Tipo: %s | Caixas por conjunto: %d | Estoque: %s",
        REPORT_ROW_TYPE_STOCK           = "Tipo: %s | Estoque: %s",
        REPORT_ROW_BUILD_CHECK          = "Tipo: %s | Necessário %d | Encontrado %d | Pode construir %s",
        REPORT_ROW_REPAIR_CHECK         = "Tipo: %s | Necessário %d | Encontrado %d | Pode reparar %s",
        REPORT_ROW_BEACON               = " %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        -- ============================================================
        -- Tokens de limite de peso / caixas
        -- ============================================================
        WEIGHT_LIMIT                    = "Limite de peso atingido",
        CRATE_LIMIT                     = "Limite de caixas atingido",
        -- ============================================================
        -- Rótulos de menu - nível superior
        -- ============================================================
        MENU_CTLD                       = "CTLD",
        MENU_MANAGE_TROOPS              = "Gerenciar tropas",
        MENU_MANAGE_CRATES              = "Gerenciar caixas",
        MENU_MANAGE_UNITS               = "Gerenciar unidades",
        -- ============================================================
        -- Rótulos de menu - tropas
        -- ============================================================
        MENU_LOAD_TROOPS                = "Carregar tropas",
        MENU_DROP_TROOPS                = "Desembarcar tropas",
        MENU_DROP_ALL_TROOPS            = "Desembarcar TODAS as tropas",
        MENU_EXTRACT_TROOPS             = "Extrair tropas",
        MENU_DROP_N_TROOPS              = "Desembarcar (%d) %s",
        -- ============================================================
        -- Rótulos de menu - caixas: obter
        -- ============================================================
        MENU_GET_CRATES                 = "Solicitar caixas",
        MENU_GET                        = "Solicitar",
        MENU_GET_AND_LOAD               = "Solicitar e carregar",
        MENU_GET_ANYWAY                 = "Solicitar mesmo assim",
        MENU_PARTIALLY_LOAD             = "Carregar parcialmente",
        MENU_OUT_OF_STOCK               = "Sem estoque",
        MENU_TROOP_LIMIT                = "Limite de tropas atingido",
        -- ============================================================
        -- Rótulos de menu - caixas: carregar
        -- ============================================================
        MENU_LOAD_CRATES                = "Carregar caixas",
        MENU_LOAD_ALL                   = "Carregar TUDO",
        MENU_SHOW_LOADABLE_CRATES       = "Mostrar caixas carregáveis",
        MENU_NO_CRATES_FOUND_RESCAN     = "Nenhuma caixa encontrada! Procurar novamente?",
        MENU_USE_C130_LOAD              = "Usar sistema de carga do C-130",
        MENU_LOAD_SINGLE                = "Carregar",
        -- ============================================================
        -- Rótulos de menu - caixas: soltar
        -- ============================================================
        MENU_DROP_CRATES                = "Soltar caixas",
        MENU_DROP_ALL_CRATES            = "Soltar TODAS as caixas",
        MENU_DROP                       = "Soltar",
        MENU_DROP_AND_BUILD             = "Soltar e construir",
        MENU_DROP_N_SETS                = "Soltar %d conjunto%s",
        MENU_NO_CRATES_TO_DROP          = "Nenhuma caixa para soltar!",
        -- ============================================================
        -- Rótulos de menu - caixas: construir / reparar / empacotar / remover
        -- ============================================================
        MENU_BUILD_CRATES               = "Construir caixas",
        MENU_REPAIR                     = "Reparar",
        MENU_PACK_CRATES                = "Empacotar caixas",
        MENU_PACK                       = "Empacotar",
        MENU_SCAN_PACKABLE_UNITS        = "Procurar unidades empacotáveis por perto",
        MENU_NO_PACKABLE_UNITS_FOUND_RESCAN = "Nenhuma unidade empacotável encontrada! Procurar novamente?",
        MENU_PACK_ALL                   = "Empacotar próximas",
        MENU_PACK_AND_LOAD              = "Empacotar e carregar",
        MENU_PACK_AND_LOAD_ALL          = "Empacotar e carregar próximas",
        MENU_PACK_AND_REMOVE            = "Empacotar e remover",
        MENU_PACK_AND_REMOVE_ALL        = "Empacotar e remover próximas",
        MENU_REMOVE_CRATES              = "Remover caixas",
        MENU_REMOVE_CRATES_NEARBY       = "Remover caixas próximas",
        MENU_LIST_CRATES_NEARBY         = "Listar caixas próximas",
        MENU_CRATES_NEEDED              = "%d caixa%s %s (%dkg)",
        MENU_CRATE_SINGLE               = "%s (%dkg)",
        -- ============================================================
        -- Rótulos de menu - unidades (C-130)
        -- ============================================================
        MENU_GET_UNITS                  = "Solicitar unidades",
        MENU_REMOVE_UNITS_NEARBY        = "Remover unidades próximas",
        -- ============================================================
        -- Rótulos de menu - informações / carga
        -- ============================================================
        MENU_LIST_BOARDED_CARGO         = "Listar carga embarcada",
        MENU_INVENTORY                  = "Inventário",
        MENU_LIST_ZONE_BEACONS          = "Listar balizas de zona ativas",
        -- ============================================================
        -- Rótulos de menu - fumaças / sinalizadores / beacons
        -- ============================================================
        MENU_SMOKES_FLARES_BEACONS      = "Fumaças, sinalizadores, balizas",
        MENU_SMOKE_ZONES_NEARBY         = "Fumaça em zonas próximas",
        MENU_DROP_SMOKE_NOW             = "Lançar fumaça agora",
        MENU_RED_SMOKE                  = "Fumaça vermelha",
        MENU_BLUE_SMOKE                 = "Fumaça azul",
        MENU_GREEN_SMOKE                = "Fumaça verde",
        MENU_ORANGE_SMOKE               = "Fumaça laranja",
        MENU_WHITE_SMOKE                = "Fumaça branca",
        MENU_FLARE_ZONES_NEARBY         = "Sinalizadores em zonas próximas",
        MENU_FIRE_FLARE_NOW             = "Disparar sinalizador agora",
        MENU_DROP_BEACON_NOW            = "Posicionar baliza agora",
        -- ============================================================
        -- Rótulos de menu - parâmetros
        -- ============================================================
        MENU_SHOW_FLIGHT_PARAMS         = "Mostrar parâmetros de voo",
        MENU_SHOW_HOVER_PARAMS          = "Mostrar parâmetros de pairado",
        STOCK_NONE                      = "nenhum",
        STOCK_UNLIMITED                 = "ilimitado",
        BUILD_YES                       = "SIM",
        BUILD_NO                        = "NÃO",
    },
    TR = {
        -- ============================================================
        -- Sandık / kargo yükleme
        -- ============================================================
        CRATE_LOADED_GROUNDCREW         = "%s sandığı yer ekibi tarafından yüklendi!",
        CRATE_UNLOADED_GROUNDCREW       = "%s sandığı yer ekibi tarafından boşaltıldı!",
        CRATE_LOADED_ID                 = "Sandık ID %d %s için yüklendi!",
        LOADED_FULL                     = "%d %s yüklendi.",
        LOADED_SETS_LEFTOVER            = "%d %s yüklendi, %d sandık kaldı.",
        LOADED_SETS                     = "%d %s yüklendi.",
        LOADED_PARTIAL                  = "Yalnızca %d/%d sandık %s için yüklendi.",
        LOADED_PARTIAL_LIMIT            = "Yalnızca %d/%d sandık %s için yüklendi. Kargo limiti artık doldu!",
        LOADED_BATCH                    = "%d %s yüklendi.",
        LOADED_BATCH_PARTIAL            = "Bazı setler tamamen yüklenemedi.",
        -- ============================================================
        -- Bırakma / boşaltma
        -- ============================================================
        DROPPED_FULL                    = "%d %s bırakıldı.",
        DROPPED_SETS_LEFTOVER           = "%d %s bırakıldı, %d sandık kaldı.",
        DROPPED_SETS                    = "%d %s bırakıldı.",
        DROPPED_PARTIAL                 = "%d/%d sandık %s için bırakıldı.",
        DROPPED_INTO_ACTION             = "Çatışma alanına konuşlandırılanlar: %s!",
        DROPPED_BEACON                  = "Radyo işaretçisi %s bırakıldı | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        CRATES_POSITIONED               = "%d sandık %s için yakınınıza yerleştirildi!",
        CRATES_DROPPED                  = "%d sandık %s için bırakıldı!",
        -- ============================================================
        -- Birlikler
        -- ============================================================
        BOARDED                         = "%s bindirildi!",
        BOARDING                        = "%s biniyor!",
        TROOPS_RETURNED                 = "Birlikler üsse döndü!",
        TROOPS_LABEL                    = "birlik",
        ENGINEERS_LABEL                 = "mühendis",
        -- ============================================================
        -- Konuşlandırma
        -- ============================================================
        DEPLOYED_NEAR_YOU               = "%s yakınınıza konuşlandırıldı!",
        UNITS_REMOVED                   = "%s kaldırıldı",
        -- ============================================================
        -- İnşa / onarım
        -- ============================================================
        BUILD_STARTED                   = "İnşa başladı, %d saniye içinde hazır!",
        REPAIR_STARTED                  = "%s kullanılarak onarım başladı, %d saniye sürecek",
        NO_UNIT_TO_REPAIR               = "Onarmak için yeterince yakın bir birim yok!",
        CANT_REPAIR_WITH                = "Bu birim %s ile onarılamaz",
        CRATES_MOVE_BEFORE_BUILD        = "*** İnşa etmeden önce sandıkların taşınması gerekiyor!",
        -- ============================================================
        -- Hatalar - helikopter / ağırlık / kapasite
        -- ============================================================
        CHOPPER_CANNOT_CARRY            = "Üzgünüm, bu helikopter sandık taşıyamaz!",
        TOO_HEAVY                       = "Üzgünüm, bu yük çok ağır!",
        FULLY_LOADED                    = "Üzgünüm, tamamen doluyuz!",
        CRAMMED                         = "Üzgünüm, zaten tıka basa doluyuz!",
        NO_CAPACITY_NOW                 = "Şu anda daha fazla yüklemek için kapasite yok!",
        NO_MORE_CAPACITY                = "Sandık yüklemek için daha fazla kapasite yok!",
        CANNOT_LOAD_NONE_OR_FULL        = "Sandıklar yüklenemiyor: ya hiç bulunamadı ya da kapasite kalmadı.",
        -- ============================================================
        -- Hatalar - konum
        -- ============================================================
        NEED_TO_LAND_OR_HOVER_LOAD      = "Yüklemek için inmen veya pozisyonda asılı kalman gerekiyor!",
        HOVER_OVER_CRATES               = "Sandıkları almak için üzerlerinde asılı kal!",
        LAND_OR_HOVER_OVER_CRATES       = "Sandıkları almak için in veya üzerlerinde asılı kal!",
        MUST_LAND_OR_HOVER_CRATES       = "Sandık yüklemek için inmen veya asılı kalman gerekiyor!",
        NEED_TO_LAND_BUILD              = "Bir şey inşa etmek için inmen / durman gerekiyor, pilot!",
        NOT_CLOSE_ENOUGH_LOGISTICS      = "Lojistik bölgesine yeterince yakın değilsin!",
        NOT_CLOSE_ENOUGH_DROP           = "Bırakma bölgesine yeterince yakın değilsin!",
        NOT_CLOSE_ENOUGH_ZONE_NM        = "Negatif, bir bölgeye %d nm'den daha yakın olmalısın!",
        CANNOT_BUILD_LOADING_AREA       = "Yükleme alanında inşa yapamazsın, pilot!",
        -- ============================================================
        -- Hatalar - kapılar
        -- ============================================================
        OPEN_DOORS_LOAD_CARGO           = "Kargo yüklemek için kapı(ları) açman gerekiyor!",
        OPEN_DOORS_LOAD_TROOPS          = "Birlik yüklemek için kapı(ları) açman gerekiyor!",
        OPEN_DOORS_EXTRACT_TROOPS       = "Birlik tahliye etmek için kapı(ları) açman gerekiyor!",
        OPEN_DOORS_UNLOAD_TROOPS        = "Birlik boşaltmak için kapı(ları) açman gerekiyor!",
        OPEN_DOORS_DROP_CARGO           = "Kargo bırakmak için kapı(ları) açman gerekiyor!",
        -- ============================================================
        -- Hatalar - stok / kullanılabilirlik
        -- ============================================================
        ALL_GONE                        = "Üzgünüm, tüm %s bitti!",
        RAN_OUT_OF                      = "Üzgünüm, %s tükendi",
        CARGO_NOT_AVAILABLE_ZONE        = "İstenen kargo bu bölgede mevcut değil!",
        ENOUGH_CRATES_NEARBY            = "Yakında zaten yeterince sandık var! Önce onlarla ilgilen!",
        NO_CRATES_WITHIN                = "%d metre içinde yüklenebilir sandık yok!",
        NO_CRATES_WITHIN_PLAIN          = "%d metre içinde sandık yok!",
        NO_CRATES_IN_RANGE              = "Menzilde sandık bulunamadı!",
        NO_NAMED_CRATES_IN_RANGE        = "Menzilde \"%s\" sandığı bulunamadı!",
        NO_LOADABLE_CRATES              = "Üzgünüm, yakında yüklenebilir sandık yok veya maksimum kargo ağırlığına ulaşıldı!",
        NO_UNITS_TO_EXTRACT             = "Tahliye etmek için yeterince yakın birim yok!",
        NO_UNIT_CONFIG                  = "%s için birim yapılandırması bulunamadı",
        CANT_ONBOARD                    = "%s bindirilemiyor",
        TOO_MANY_UNITS_NEARBY           = "Yakında zaten %d birimin var!",
        NO_CRATE_GROUPS                 = "Bu birim için sandık grubu bulunamadı!",
        NO_CRATE_SET                    = "Sandık seti bulunamadı veya indeks geçersiz!",
        NO_CRATE_IN_SET                 = "Bu sette sandık bulunamadı!",
        NO_TROOP_CHUNK                  = "ID %d için birlik kargo parçası bulunamadı!",
        TROOP_CHUNK_EMPTY               = "ID %d için birlik parçası boş!",
        -- ============================================================
        -- Yüklü bir şey yok / stokta yok
        -- ============================================================
        NOTHING_LOADED                  = "Hiçbir şey yüklü değil!\nBirlik limiti: %d | Sandık limiti %d | Ağırlık limiti %d kg",
        NOTHING_LOADED_AIRDROP          = "Hiçbir şey yüklü değil veya havadan bırakma parametreleri dahilinde değil!",
        NOTHING_LOADED_HOVER            = "Hiçbir şey yüklü değil veya asılı kalma parametreleri dahilinde değil!",
        NOTHING_IN_STOCK                = "Stokta hiçbir şey yok!",
        NOTHING_TO_PACK                 = "Bu mesafede paketlenecek bir şey yok, pilot!",
        NOTHING_TO_REMOVE               = "Bu mesafede kaldırılacak bir şey yok, pilot!",
        -- ============================================================
        -- Bölge / bilgi
        -- ============================================================
        ROGER_ZONE                      = "Anlaşıldı, %s bölgesi %s!",
        -- ============================================================
        -- Rapor: asılı kalma / uçuş parametreleri
        -- ============================================================
        HOVER_PARAMS_METRIC             = "Asılı kalma parametreleri (otomatik yükleme/bırakma):\n - Minimum irtifa %dm \n - Maksimum irtifa %dm \n - Maksimum hız 2mps \n - Parametreler dahilinde: %s",
        HOVER_PARAMS_IMPERIAL           = "Asılı kalma parametreleri (otomatik yükleme/bırakma):\n - Minimum irtifa %dft \n - Maksimum irtifa %dft \n - Maksimum hız 6ftps \n - Parametreler dahilinde: %s",
        FLIGHT_PARAMS_IMPERIAL          = "Uçuş parametreleri (havadan bırakma):\n - Minimum irtifa %dft \n - Maksimum irtifa %dft \n - Parametreler dahilinde: %s",
        FLIGHT_PARAMS_METRIC            = "Uçuş parametreleri (havadan bırakma):\n - Minimum irtifa %dm \n - Maksimum irtifa %dm \n - Parametreler dahilinde: %s",
        -- ============================================================
        -- Rapor başlıkları (REPORT:New())
        -- ============================================================
        REPORT_CRATES_FOUND             = "Yakında bulunan sandıklar:",
        REPORT_REMOVING_CRATES          = "Yakında bulunan sandıklar kaldırılıyor:",
        REPORT_TRANSPORT_CHECKOUT       = "Taşıma kontrol formu",
        REPORT_INVENTORY                = "Envanter formu",
        REPORT_BUILD_CHECKLIST          = "İnşa edilebilir sandık kontrol listesi",
        REPORT_REPAIR_CHECKLIST         = "Onarım kontrol listesi",
        REPORT_BEACONS                  = "Aktif bölge radyo işaretçileri",
        -- ============================================================
        -- Rapor bölüm başlıkları (report:Add())
        -- ============================================================
        REPORT_SECTION_TROOPS           = "        -- BİRLİKLER --",
        REPORT_SECTION_CRATES           = "       -- SANDIKLAR --",
        REPORT_SECTION_CRATES_GC        = "       -- Yer ekibiyle yüklenen SANDIKLAR --",
        REPORT_SECTION_NONE             = "        Y O K",
        REPORT_SECTION_NONE_ALT         = "     --- Hiçbir şey bulunamadı! ---",
        REPORT_SECTION_NONE_REPAIR      = "     --- Hiçbir şey bulunamadı ---",
        REPORT_GC_LOADABLE_HINT         = "Muhtemelen yer ekibiyle yüklenebilir (F8)",
        REPORT_TOTAL_MASS               = "Toplam kütle: %s kg. Yüklenebilir: %s kg.",
        REPORT_TROOPS_CRATES_COUNT      = "Birlikler: %d(%d), Sandıklar: %d(%d)",
        REPORT_TROOPS_CRATETYPES_COUNT  = "Birlikler: %d, Sandık tipleri: %d",
        -- ============================================================
        -- Rapor satır şablonları (öğe başına satırlar)
        -- ============================================================
        REPORT_ROW_TROOP                = "Birlik: %s boyut %d",
        REPORT_ROW_CRATE                = "Sandık: %s %d/%d",
        REPORT_ROW_CRATE_SIZE1          = "Sandık: %s boyut 1",
        REPORT_ROW_GC_CRATE             = "Yer ekibiyle yüklenen sandık: %s boyut 1",
        REPORT_ROW_DROPPED_CRATE        = "%s için bırakılan sandık, %dkg",
        REPORT_ROW_CRATE_KG             = "%s için sandık, %dkg",
        REPORT_ROW_CRATE_REMOVED        = "%s için sandık, %dkg kaldırıldı",
        REPORT_ROW_UNIT_STOCK           = "Birim: %s | Askerler: %d | Stok: %s",
        REPORT_ROW_TYPE_CRATE_STOCK     = "Tip: %s | Set başına sandık: %d | Stok: %s",
        REPORT_ROW_TYPE_STOCK           = "Tip: %s | Stok: %s",
        REPORT_ROW_BUILD_CHECK          = "Tip: %s | Gerekli %d | Bulunan %d | İnşa edilebilir %s",
        REPORT_ROW_REPAIR_CHECK         = "Tip: %s | Gerekli %d | Bulunan %d | Onarılabilir %s",
        REPORT_ROW_BEACON               = " %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        -- ============================================================
        -- Ağırlık / sandık limiti belirteçleri
        -- ============================================================
        WEIGHT_LIMIT                    = "Ağırlık limitine ulaşıldı",
        CRATE_LIMIT                     = "Sandık limitine ulaşıldı",
        -- ============================================================
        -- Menü etiketleri - üst seviye
        -- ============================================================
        MENU_CTLD                       = "CTLD",
        MENU_MANAGE_TROOPS              = "Birlikleri yönet",
        MENU_MANAGE_CRATES              = "Sandıkları yönet",
        MENU_MANAGE_UNITS               = "Birimleri yönet",
        -- ============================================================
        -- Menü etiketleri - birlikler
        -- ============================================================
        MENU_LOAD_TROOPS                = "Birlik yükle",
        MENU_DROP_TROOPS                = "Birlik indir",
        MENU_DROP_ALL_TROOPS            = "TÜM birlikleri indir",
        MENU_EXTRACT_TROOPS             = "Birlik tahliye et",
        MENU_DROP_N_TROOPS              = "(%d) %s indir",
        -- ============================================================
        -- Menü etiketleri - sandıklar: al
        -- ============================================================
        MENU_GET_CRATES                 = "Sandık talep et",
        MENU_GET                        = "Talep et",
        MENU_GET_AND_LOAD               = "Talep et ve yükle",
        MENU_GET_ANYWAY                 = "Yine de talep et",
        MENU_PARTIALLY_LOAD             = "Kısmen yükle",
        MENU_OUT_OF_STOCK               = "Stokta yok",
        MENU_TROOP_LIMIT                = "Birlik limitine ulaşıldı",
        -- ============================================================
        -- Menü etiketleri - sandıklar: yükle
        -- ============================================================
        MENU_LOAD_CRATES                = "Sandık yükle",
        MENU_LOAD_ALL                   = "TÜMÜNÜ yükle",
        MENU_SHOW_LOADABLE_CRATES       = "Yüklenebilir sandıkları göster",
        MENU_NO_CRATES_FOUND_RESCAN     = "Sandık bulunamadı! Tekrar tara?",
        MENU_USE_C130_LOAD              = "C-130 yükleme sistemini kullan",
        MENU_LOAD_SINGLE                = "Yükle",
        -- ============================================================
        -- Menü etiketleri - sandıklar: bırak
        -- ============================================================
        MENU_DROP_CRATES                = "Sandık bırak",
        MENU_DROP_ALL_CRATES            = "TÜM sandıkları bırak",
        MENU_DROP                       = "Bırak",
        MENU_DROP_AND_BUILD             = "Bırak ve inşa et",
        MENU_DROP_N_SETS                = "%d set%.0s bırak",
        MENU_NO_CRATES_TO_DROP          = "Bırakılacak sandık yok!",
        -- ============================================================
        -- Menü etiketleri - sandıklar: inşa / onar / paketle / kaldır
        -- ============================================================
        MENU_BUILD_CRATES               = "Sandıkları inşa et",
        MENU_REPAIR                     = "Onar",
        MENU_PACK_CRATES                = "Sandıkları paketle",
        MENU_PACK                       = "Paketle",
        MENU_SCAN_PACKABLE_UNITS        = "Yakındaki paketlenebilir birimleri tara",
        MENU_NO_PACKABLE_UNITS_FOUND_RESCAN = "Paketlenebilir birim bulunamadı! Tekrar tara?",
        MENU_PACK_ALL                   = "Yakındakileri paketle",
        MENU_PACK_AND_LOAD              = "Paketle ve yükle",
        MENU_PACK_AND_LOAD_ALL          = "Yakındakileri paketle ve yükle",
        MENU_PACK_AND_REMOVE            = "Paketle ve kaldır",
        MENU_PACK_AND_REMOVE_ALL        = "Yakındakileri paketle ve kaldır",
        MENU_REMOVE_CRATES              = "Sandıkları kaldır",
        MENU_REMOVE_CRATES_NEARBY       = "Yakındaki sandıkları kaldır",
        MENU_LIST_CRATES_NEARBY         = "Yakındaki sandıkları listele",
        MENU_CRATES_NEEDED              = "%d sandık%.0s %s (%dkg)",
        MENU_CRATE_SINGLE               = "%s (%dkg)",
        -- ============================================================
        -- Menü etiketleri - birimler (C-130)
        -- ============================================================
        MENU_GET_UNITS                  = "Birim talep et",
        MENU_REMOVE_UNITS_NEARBY        = "Yakındaki birimleri kaldır",
        -- ============================================================
        -- Menü etiketleri - bilgi / kargo
        -- ============================================================
        MENU_LIST_BOARDED_CARGO         = "Bindirilmiş kargoyu listele",
        MENU_INVENTORY                  = "Envanter",
        MENU_LIST_ZONE_BEACONS          = "Aktif bölge radyo işaretçilerini listele",
        -- ============================================================
        -- Menü etiketleri - dumanlar / işaret fişekleri / beaconlar
        -- ============================================================
        MENU_SMOKES_FLARES_BEACONS      = "Dumanlar, işaret fişekleri, radyo işaretçileri",
        MENU_SMOKE_ZONES_NEARBY         = "Yakındaki bölgelerde duman",
        MENU_DROP_SMOKE_NOW             = "Şimdi duman işareti bırak",
        MENU_RED_SMOKE                  = "Kırmızı duman",
        MENU_BLUE_SMOKE                 = "Mavi duman",
        MENU_GREEN_SMOKE                = "Yeşil duman",
        MENU_ORANGE_SMOKE               = "Turuncu duman",
        MENU_WHITE_SMOKE                = "Beyaz duman",
        MENU_FLARE_ZONES_NEARBY         = "Yakındaki bölgelerde işaret fişekleri",
        MENU_FIRE_FLARE_NOW             = "Şimdi işaret fişeği ateşle",
        MENU_DROP_BEACON_NOW            = "Şimdi radyo işaretçisi bırak",
        -- ============================================================
        -- Menü etiketleri - parametreler
        -- ============================================================
        MENU_SHOW_FLIGHT_PARAMS         = "Uçuş parametrelerini göster",
        MENU_SHOW_HOVER_PARAMS          = "Asılı kalma parametrelerini göster",
        STOCK_NONE                      = "yok",
        STOCK_UNLIMITED                 = "sınırsız",
        BUILD_YES                       = "EVET",
        BUILD_NO                        = "HAYIR",
    },
    RU = {
        -- ============================================================
        -- Crate / Cargo Loading
        -- ============================================================
        CRATE_LOADED_GROUNDCREW         = "Ящик %s загружен наземной службой!",
        CRATE_UNLOADED_GROUNDCREW       = "Ящик %s выгружен наземной службой!",
        CRATE_LOADED_ID                 = "Ящик ID %d для %s загружен!",
        LOADED_FULL                     = "Загружено %d %s.",
        LOADED_SETS_LEFTOVER            = "Загружено %d %s, осталось %d ящик(ов).",
        LOADED_SETS                     = "Загружено %d %s.",
        LOADED_PARTIAL                  = "Загружено только %d/%d ящик(ов) для %s.",
        LOADED_PARTIAL_LIMIT            = "Загружено только %d/%d ящик(ов) для %s. Достигнут лимит груза!",
        LOADED_BATCH                    = "Загружено %d %s.",
        LOADED_BATCH_PARTIAL            = "Некоторые комплекты не удалось загрузить полностью.",
        -- ============================================================
        -- Dropping / Unloading
        -- ============================================================
        DROPPED_FULL                    = "Сброшено %d %s.",
        DROPPED_SETS_LEFTOVER           = "Сброшено %d %s, осталось %d ящик(ов).",
        DROPPED_SETS                    = "Сброшено %d %s.",
        DROPPED_PARTIAL                 = "Сброшено %d/%d ящик(ов) для %s.",
        DROPPED_INTO_ACTION             = "%s сброшено в бой!",
        DROPPED_BEACON                  = "Сброшен %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        CRATES_POSITIONED               = "%d ящик(ов) для %s размещены рядом с вами!",
        CRATES_DROPPED                  = "%d ящик(ов) для %s сброшены!",
        -- ============================================================
        -- Troops
        -- ============================================================
        BOARDED                         = "%s на борту!",
        BOARDING                        = "%s грузится!",
        TROOPS_RETURNED                 = "Войска вернулись на базу!",
        TROOPS_LABEL                    = "войска",
        ENGINEERS_LABEL                 = "инженеры",
        -- ============================================================
        -- Deployment
        -- ============================================================
        DEPLOYED_NEAR_YOU               = "%s развернуты рядом с вами!",
        UNITS_REMOVED                   = "%s удалены",
        -- ============================================================
        -- Build / Repair
        -- ============================================================
        BUILD_STARTED                   = "Строительство начато, готово через %d секунд!",
        REPAIR_STARTED                  = "Ремонт начат с использованием %s, займет %d сек",
        NO_UNIT_TO_REPAIR               = "Нет достаточно близкого юнита для ремонта!",
        CANT_REPAIR_WITH                = "Нельзя отремонтировать этот юнит с помощью %s",
        CRATES_MOVE_BEFORE_BUILD        = "*** Ящики нужно переместить перед строительством!",
        -- ============================================================
        -- Errors - Chopper / Weight / Capacity
        -- ============================================================
        CHOPPER_CANNOT_CARRY            = "Извините, этот вертолет не может перевозить ящики!",
        TOO_HEAVY                       = "Извините, это слишком тяжело для загрузки!",
        FULLY_LOADED                    = "Извините, мы полностью загружены!",
        CRAMMED                         = "Извините, у нас уже нет места!",
        NO_CAPACITY_NOW                 = "Сейчас нет места для дополнительной загрузки!",
        NO_MORE_CAPACITY                = "Больше нет места для загрузки ящиков!",
        CANNOT_LOAD_NONE_OR_FULL        = "Нельзя загрузить ящики: ничего не найдено или нет свободной вместимости.",
        -- ============================================================
        -- Errors - Position
        -- ============================================================
        NEED_TO_LAND_OR_HOVER_LOAD      = "Нужно приземлиться или зависнуть на месте для загрузки!",
        HOVER_OVER_CRATES               = "Зависните над ящиками, чтобы подобрать их!",
        LAND_OR_HOVER_OVER_CRATES       = "Приземлитесь или зависните над ящиками, чтобы подобрать их!",
        MUST_LAND_OR_HOVER_CRATES       = "Нужно приземлиться или зависнуть, чтобы загрузить ящики!",
        NEED_TO_LAND_BUILD              = "Нужно приземлиться / остановиться, чтобы что-то построить, пилот!",
        NOT_CLOSE_ENOUGH_LOGISTICS      = "Вы недостаточно близко к логистической зоне!",
        NOT_CLOSE_ENOUGH_DROP           = "Вы недостаточно близко к зоне сброса!",
        NOT_CLOSE_ENOUGH_ZONE_NM        = "Отказ, нужно быть ближе чем %d nm к зоне!",
        CANNOT_BUILD_LOADING_AREA       = "Нельзя строить в зоне погрузки, пилот!",
        -- ============================================================
        -- Errors - Doors
        -- ============================================================
        OPEN_DOORS_LOAD_CARGO           = "Нужно открыть дверь(и), чтобы загрузить груз!",
        OPEN_DOORS_LOAD_TROOPS          = "Нужно открыть дверь(и), чтобы загрузить войска!",
        OPEN_DOORS_EXTRACT_TROOPS       = "Нужно открыть дверь(и), чтобы эвакуировать войска!",
        OPEN_DOORS_UNLOAD_TROOPS        = "Нужно открыть дверь(и), чтобы выгрузить войска!",
        OPEN_DOORS_DROP_CARGO           = "Нужно открыть дверь(и), чтобы сбросить груз!",
        -- ============================================================
        -- Errors - Stock / Availability
        -- ============================================================
        ALL_GONE                        = "Извините, все %s закончились!",
        RAN_OUT_OF                      = "Извините, у нас закончились %s",
        CARGO_NOT_AVAILABLE_ZONE        = "Запрошенный груз недоступен в этой зоне!",
        ENOUGH_CRATES_NEARBY            = "Рядом уже достаточно ящиков! Сначала разберитесь с ними!",
        NO_CRATES_WITHIN                = "Нет загружаемых ящиков в пределах %d метров!",
        NO_CRATES_WITHIN_PLAIN          = "Нет ящиков в пределах %d метров!",
        NO_CRATES_IN_RANGE              = "Ящики в радиусе не найдены!",
        NO_NAMED_CRATES_IN_RANGE        = "Ящики «%s» в радиусе не найдены!",
        NO_LOADABLE_CRATES              = "Извините, рядом нет загружаемых ящиков или достигнут максимальный вес груза!",
        NO_UNITS_TO_EXTRACT             = "Нет достаточно близких юнитов для эвакуации!",
        NO_UNIT_CONFIG                  = "Конфигурация юнита для %s не найдена",
        CANT_ONBOARD                    = "Нельзя взять на борт %s",
        TOO_MANY_UNITS_NEARBY           = "У вас уже есть %d юнитов поблизости!",
        NO_CRATE_GROUPS                 = "Группы ящиков для этого юнита не найдены!",
        NO_CRATE_SET                    = "Набор ящиков не найден или индекс недействителен!",
        NO_CRATE_IN_SET                 = "Ящик в этом наборе не найден!",
        NO_TROOP_CHUNK                  = "Часть войскового груза с ID %d не найдена!",
        TROOP_CHUNK_EMPTY               = "Часть войскового груза с ID %d пуста!",
        -- ============================================================
        -- Nothing loaded / in stock
        -- ============================================================
        NOTHING_LOADED                  = "Ничего не загружено!\nЛимит войск: %d | Лимит ящиков %d | Лимит веса %d кг",
        NOTHING_LOADED_AIRDROP          = "Ничего не загружено или параметры воздушного сброса не соблюдены!",
        NOTHING_LOADED_HOVER            = "Ничего не загружено или висение вне допустимых параметров!",
        NOTHING_IN_STOCK                = "На складе ничего нет!",
        NOTHING_TO_PACK                 = "На этой дистанции нечего упаковывать, пилот!",
        NOTHING_TO_REMOVE               = "На этой дистанции нечего удалять, пилот!",
        -- ============================================================
        -- Zone / Info
        -- ============================================================
        ROGER_ZONE                      = "Принято, зона %s %s!",
        -- ============================================================
        -- Report: Hover / Flight Parameters
        -- ============================================================
        HOVER_PARAMS_METRIC             = "Параметры висения (автозагрузка/сброс):\n - Мин. высота %dм \n - Макс. высота %dм \n - Макс. скорость 2м/с \n - В параметрах: %s",
        HOVER_PARAMS_IMPERIAL           = "Параметры висения (автозагрузка/сброс):\n - Мин. высота %dфт \n - Макс. высота %dфт \n - Макс. скорость 6фт/с \n - В параметрах: %s",
        FLIGHT_PARAMS_IMPERIAL          = "Параметры полета (воздушный сброс):\n - Мин. высота %dфт \n - Макс. высота %dфт \n - В параметрах: %s",
        FLIGHT_PARAMS_METRIC            = "Параметры полета (воздушный сброс):\n - Мин. высота %dм \n - Макс. высота %dм \n - В параметрах: %s",
        -- ============================================================
        -- Report Titles  (REPORT:New())
        -- ============================================================
        REPORT_CRATES_FOUND             = "Ящики поблизости:",
        REPORT_REMOVING_CRATES          = "Удаление найденных поблизости ящиков:",
        REPORT_TRANSPORT_CHECKOUT       = "Транспортная ведомость",
        REPORT_INVENTORY                = "Инвентарная ведомость",
        REPORT_BUILD_CHECKLIST          = "Чек-лист строящихся ящиков",
        REPORT_REPAIR_CHECKLIST         = "Чек-лист ремонта",
        REPORT_BEACONS                  = "Активные маяки зон",
        -- ============================================================
        -- Report Section Headers  (report:Add())
        -- ============================================================
        REPORT_SECTION_TROOPS           = "        -- ВОЙСКА --",
        REPORT_SECTION_CRATES           = "       -- ЯЩИКИ --",
        REPORT_SECTION_CRATES_GC        = "       -- ЯЩИКИ загружены наземной службой --",
        REPORT_SECTION_NONE             = "        Н Е Т",
        REPORT_SECTION_NONE_ALT         = "     --- Ничего не найдено! ---",
        REPORT_SECTION_NONE_REPAIR      = "     --- Ничего не найдено ---",
        REPORT_GC_LOADABLE_HINT         = "Вероятно, можно загрузить наземной службой (F8)",
        REPORT_TOTAL_MASS               = "Общая масса: %s кг. Можно загрузить: %s кг.",
        REPORT_TROOPS_CRATES_COUNT      = "Войска: %d(%d), Ящики: %d(%d)",
        REPORT_TROOPS_CRATETYPES_COUNT  = "Войска: %d, Типы ящиков: %d",
        -- ============================================================
        -- Report Row Templates  (per-item lines in reports)
        -- ============================================================
        REPORT_ROW_TROOP                = "Войска: %s размер %d",
        REPORT_ROW_CRATE                = "Ящик: %s %d/%d",
        REPORT_ROW_CRATE_SIZE1          = "Ящик: %s размер 1",
        REPORT_ROW_GC_CRATE             = "Ящик загружен НС: %s размер 1",
        REPORT_ROW_DROPPED_CRATE        = "Сброшен ящик для %s, %dкг",
        REPORT_ROW_CRATE_KG             = "Ящик для %s, %dкг",
        REPORT_ROW_CRATE_REMOVED        = "Ящик для %s, %dкг удален",
        REPORT_ROW_UNIT_STOCK           = "Юнит: %s | Солдаты: %d | Запас: %s",
        REPORT_ROW_TYPE_CRATE_STOCK     = "Тип: %s | Ящиков на комплект: %d | Запас: %s",
        REPORT_ROW_TYPE_STOCK           = "Тип: %s | Запас: %s",
        REPORT_ROW_BUILD_CHECK          = "Тип: %s | Требуется %d | Найдено %d | Можно строить %s",
        REPORT_ROW_REPAIR_CHECK         = "Тип: %s | Требуется %d | Найдено %d | Можно ремонтировать %s",
        REPORT_ROW_BEACON               = " %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ",
        -- ============================================================
        -- Weight / Crate limit tokens
        -- ============================================================
        WEIGHT_LIMIT                    = "Достигнут лимит веса",
        CRATE_LIMIT                     = "Достигнут лимит ящиков",
        -- ============================================================
        -- Menu labels - Top level
        -- ============================================================
        MENU_CTLD                       = "CTLD",
        MENU_MANAGE_TROOPS              = "Управление войсками",
        MENU_MANAGE_CRATES              = "Управление ящиками",
        MENU_MANAGE_UNITS               = "Управление юнитами",
        -- ============================================================
        -- Menu labels - Troops
        -- ============================================================
        MENU_LOAD_TROOPS                = "Загрузить войска",
        MENU_DROP_TROOPS                = "Высадить войска",
        MENU_DROP_ALL_TROOPS            = "Высадить ВСЕ войска",
        MENU_EXTRACT_TROOPS             = "Эвакуировать войска",
        MENU_DROP_N_TROOPS              = "Высадить (%d) %s",
        -- ============================================================
        -- Menu labels - Crates: Get
        -- ============================================================
        MENU_GET_CRATES                 = "Получить ящики",
        MENU_GET                        = "Получить",
        MENU_GET_AND_LOAD               = "Получить и загрузить",
        MENU_GET_ANYWAY                 = "Все равно получить",
        MENU_PARTIALLY_LOAD             = "Частично загрузить",
        MENU_OUT_OF_STOCK               = "Нет в наличии",
        MENU_TROOP_LIMIT                = "Достигнут лимит войск",
        -- ============================================================
        -- Menu labels - Crates: Load
        -- ============================================================
        MENU_LOAD_CRATES                = "Загрузить ящики",
        MENU_LOAD_ALL                   = "Загрузить ВСЕ",
        MENU_SHOW_LOADABLE_CRATES       = "Показать загружаемые ящики",
        MENU_NO_CRATES_FOUND_RESCAN     = "Ящики не найдены! Сканировать снова?",
        MENU_USE_C130_LOAD              = "Использовать систему загрузки C-130",
        MENU_LOAD_SINGLE                = "Загрузить",
        -- ============================================================
        -- Menu labels - Crates: Drop
        -- ============================================================
        MENU_DROP_CRATES                = "Сбросить ящики",
        MENU_DROP_ALL_CRATES            = "Сбросить ВСЕ ящики",
        MENU_DROP                       = "Сбросить",
        MENU_DROP_AND_BUILD             = "Сбросить и построить",
        MENU_DROP_N_SETS                = "Сбросить %d комплект%s",
        MENU_NO_CRATES_TO_DROP          = "Нет ящиков для сброса!",
        -- ============================================================
        -- Menu labels - Crates: Build / Repair / Pack / Remove
        -- ============================================================
        MENU_BUILD_CRATES               = "Построить из ящиков",
        MENU_REPAIR                     = "Ремонт",
        MENU_PACK_CRATES                = "Упаковать ящики",
        MENU_PACK                       = "Упаковать",
        MENU_SCAN_PACKABLE_UNITS        = "Сканировать упаковываемые юниты поблизости",
        MENU_NO_PACKABLE_UNITS_FOUND_RESCAN = "Упаковываемые юниты не найдены! Сканировать снова?",
        MENU_PACK_ALL                   = "Упаковать поблизости",
        MENU_PACK_AND_LOAD              = "Упаковать и загрузить",
        MENU_PACK_AND_LOAD_ALL          = "Упаковать и загрузить поблизости",
        MENU_PACK_AND_REMOVE            = "Упаковать и удалить",
        MENU_PACK_AND_REMOVE_ALL        = "Упаковать и удалить поблизости",
        MENU_REMOVE_CRATES              = "Удалить ящики",
        MENU_REMOVE_CRATES_NEARBY       = "Удалить ящики поблизости",
        MENU_LIST_CRATES_NEARBY         = "Список ящиков поблизости",
        MENU_CRATES_NEEDED              = "%d ящик%s %s (%dкг)",
        MENU_CRATE_SINGLE               = "%s (%dкг)",
        -- ============================================================
        -- Menu labels - Units (C-130)
        -- ============================================================
        MENU_GET_UNITS                  = "Получить юниты",
        MENU_REMOVE_UNITS_NEARBY        = "Удалить юниты поблизости",
        -- ============================================================
        -- Menu labels - Info / Cargo
        -- ============================================================
        MENU_LIST_BOARDED_CARGO         = "Список груза на борту",
        MENU_INVENTORY                  = "Инвентарь",
        MENU_LIST_ZONE_BEACONS          = "Список активных маяков зон",
        -- ============================================================
        -- Menu labels - Smokes / Flares / Beacons
        -- ============================================================
        MENU_SMOKES_FLARES_BEACONS      = "Дымы, ракеты, маяки",
        MENU_SMOKE_ZONES_NEARBY         = "Дым в ближайших зонах",
        MENU_DROP_SMOKE_NOW             = "Сбросить дым сейчас",
        MENU_RED_SMOKE                  = "Красный дым",
        MENU_BLUE_SMOKE                 = "Синий дым",
        MENU_GREEN_SMOKE                = "Зеленый дым",
        MENU_ORANGE_SMOKE               = "Оранжевый дым",
        MENU_WHITE_SMOKE                = "Белый дым",
        MENU_FLARE_ZONES_NEARBY         = "Ракеты в ближайших зонах",
        MENU_FIRE_FLARE_NOW             = "Выпустить ракету сейчас",
        MENU_DROP_BEACON_NOW            = "Сбросить маяк сейчас",
        -- ============================================================
        -- Menu labels - Parameters
        -- ============================================================
        MENU_SHOW_FLIGHT_PARAMS         = "Показать параметры полета",
        MENU_SHOW_HOVER_PARAMS          = "Показать параметры висения",
        STOCK_NONE                      = "нет",
        STOCK_UNLIMITED                 = "без ограничений",
        BUILD_YES                       = "ДА",
        BUILD_NO                        = "НЕТ",
    },
    ["zh-TW"] = {
        -- ============================================================
        -- Crate / Cargo Loading
        -- ============================================================
        CRATE_LOADED_GROUNDCREW         = "地勤已裝載貨箱 %s！",
        CRATE_UNLOADED_GROUNDCREW       = "地勤已卸載貨箱 %s！",
        CRATE_LOADED_ID                 = "貨箱 ID %d（%s）已裝載！",
        LOADED_FULL                     = "已裝載 %d 個 %s。",
        LOADED_SETS_LEFTOVER            = "已裝載 %d 組 %s，剩餘 %d 個貨箱。",
        LOADED_SETS                     = "已裝載 %d 組 %s。",
        LOADED_PARTIAL                  = "僅裝載 %d/%d 個 %s 的貨箱。",
        LOADED_PARTIAL_LIMIT            = "僅裝載 %d/%d 個 %s 的貨箱，已達載運上限！",
        LOADED_BATCH                    = "已裝載 %d 個 %s。",
        LOADED_BATCH_PARTIAL            = "部分組合無法完全裝載。",
        -- ============================================================
        -- Dropping / Unloading
        -- ============================================================
        DROPPED_FULL                    = "已投放 %d 個 %s。",
        DROPPED_SETS_LEFTOVER           = "已投放 %d 組 %s，剩餘 %d 個貨箱。",
        DROPPED_SETS                    = "已投放 %d 組 %s。",
        DROPPED_PARTIAL                 = "已投放 %d/%d 個 %s 的貨箱。",
        DROPPED_INTO_ACTION             = "已將 %s 投入作戰！",
        DROPPED_BEACON                  = "已投放 %s | FM %s MHz | VHF %s KHz | UHF %s MHz ",
        CRATES_POSITIONED               = "已在你附近部署 %d 個 %s 貨箱！",
        CRATES_DROPPED                  = "已投放 %d 個 %s 貨箱！",
        -- ============================================================
        -- Troops
        -- ============================================================
        BOARDED                         = "%s 已登機！",
        BOARDING                        = "%s 正在登機！",
        TROOPS_RETURNED                 = "部隊已返回基地！",
        TROOPS_LABEL                    = "部隊",
        ENGINEERS_LABEL                 = "工程兵",
        -- ============================================================
        -- Deployment
        -- ============================================================
        DEPLOYED_NEAR_YOU               = "%s 已在你附近部署！",
        UNITS_REMOVED                   = "%s 已移除",
        -- ============================================================
        -- Build / Repair
        -- ============================================================
        BUILD_STARTED                   = "建設開始，將於%d 秒後完成！",
        REPAIR_STARTED                  = "使用 %s 開始維修，需時 %d 秒",
        NO_UNIT_TO_REPAIR               = "附近沒有可維修單位！",
        CANT_REPAIR_WITH                = "無法使用 %s 維修此單位",
        CRATES_MOVE_BEFORE_BUILD        = "*** 建設前需先移動貨箱！",
        -- ============================================================
        -- Errors - Chopper / Weight / Capacity
        -- ============================================================
        CHOPPER_CANNOT_CARRY            = "此直升機無法運載貨箱！",
        TOO_HEAVY                       = "重量過重，無法裝載！",
        FULLY_LOADED                    = "已達滿載！",
        CRAMMED                         = "空間已滿！",
        NO_CAPACITY_NOW                 = "目前無法再裝載！",
        NO_MORE_CAPACITY                = "已無空間裝載貨箱！",
        CANNOT_LOAD_NONE_OR_FULL        = "無法裝載貨箱：未找到或已無容量。",
        -- ============================================================
        -- Errors - Position
        -- ============================================================
        NEED_TO_LAND_OR_HOVER_LOAD      = "需降落或穩定懸停才能裝載！",
        HOVER_OVER_CRATES               = "請懸停於貨箱上方進行拾取！",
        LAND_OR_HOVER_OVER_CRATES       = "請降落或懸停於貨箱上方進行拾取！",
        MUST_LAND_OR_HOVER_CRATES       = "必須降落或懸停才能裝載貨箱！",
        NEED_TO_LAND_BUILD              = "飛行員，需降落或停止才能建設！",
        NOT_CLOSE_ENOUGH_LOGISTICS      = "距離後勤區域過遠！",
        NOT_CLOSE_ENOUGH_DROP           = "距離投放區域過遠！",
        NOT_CLOSE_ENOUGH_ZONE_NM        = "距離區域需小於 %d 海浬！",
        CANNOT_BUILD_LOADING_AREA       = "無法在裝載區域進行建設！",
        -- ============================================================
        -- Errors - Doors
        -- ============================================================
        OPEN_DOORS_LOAD_CARGO           = "需開啟艙門才能裝載貨物！",
        OPEN_DOORS_LOAD_TROOPS          = "需開啟艙門才能裝載部隊！",
        OPEN_DOORS_EXTRACT_TROOPS       = "需開啟艙門才能撤離部隊！",
        OPEN_DOORS_UNLOAD_TROOPS        = "需開啟艙門才能卸載部隊！",
        OPEN_DOORS_DROP_CARGO           = "需開啟艙門才能投放貨物！",
        -- ============================================================
        -- Errors - Stock / Availability
        -- ============================================================
        ALL_GONE                        = "%s 已全部耗盡！",
        RAN_OUT_OF                      = "%s 已用盡",
        CARGO_NOT_AVAILABLE_ZONE        = "此區域無法取得該貨物！",
        ENOUGH_CRATES_NEARBY            = "附近已有足夠貨箱，請先處理現有貨箱！",
        NO_CRATES_WITHIN                = "%d 公尺內沒有可裝載貨箱！",
        NO_CRATES_WITHIN_PLAIN          = "%d 公尺內沒有貨箱！",
        NO_CRATES_IN_RANGE              = "範圍內未發現貨箱！",
        NO_NAMED_CRATES_IN_RANGE        = "範圍內未發現「%s」貨箱！",
        NO_LOADABLE_CRATES              = "附近沒有可裝載貨箱或已達重量上限！",
        NO_UNITS_TO_EXTRACT             = "附近沒有可撤離單位！",
        NO_UNIT_CONFIG                  = "未找到 %s 的單位設定",
        CANT_ONBOARD                    = "無法登載 %s",
        TOO_MANY_UNITS_NEARBY           = "附近已有 %d 個單位！",
        NO_CRATE_GROUPS                 = "未找到此單位的貨箱群組！",
        NO_CRATE_SET                    = "未找到貨箱組或索引無效！",
        NO_CRATE_IN_SET                 = "該組中沒有貨箱！",
        NO_TROOP_CHUNK                  = "未找到 ID %d 的部隊資料！",
        TROOP_CHUNK_EMPTY               = "ID %d 的部隊資料為空！",
        -- ============================================================
        -- Nothing loaded / in stock
        -- ============================================================
        NOTHING_LOADED                  = "未裝載任何內容！\n部隊上限：%d | 貨箱上限 %d | 重量上限 %d 公斤",
        NOTHING_LOADED_AIRDROP          = "未裝載或不符合空投條件！",
        NOTHING_LOADED_HOVER            = "未裝載或未達懸停條件！",
        NOTHING_IN_STOCK                = "庫存為空！",
        NOTHING_TO_PACK                 = "此距離內無可打包目標！",
        NOTHING_TO_REMOVE               = "此距離內無可移除目標！",
        -- ============================================================
        -- Zone / Info
        -- ============================================================
        ROGER_ZONE                      = "收到，%s 區域 %s！",
        -- ============================================================
        -- Report: Hover / Flight Parameters
        -- ============================================================
        HOVER_PARAMS_METRIC             = "懸停參數（自動裝載/投放）：\n - 最低高度 %d 公尺 \n - 最高高度 %d 公尺 \n - 最大速度 2 公尺/秒 \n - 是否符合：%s",
        HOVER_PARAMS_IMPERIAL           = "懸停參數（自動裝載/投放）：\n - 最低高度 %d 英尺 \n - 最高高度 %d 英尺 \n - 最大速度 6 英尺/秒 \n - 是否符合：%s",
        FLIGHT_PARAMS_IMPERIAL          = "飛行參數（空投）：\n - 最低高度 %d 英尺 \n - 最高高度 %d 英尺 \n - 是否符合：%s",
        FLIGHT_PARAMS_METRIC            = "飛行參數（空投）：\n - 最低高度 %d 公尺 \n - 最高高度 %d 公尺 \n - 是否符合：%s",
        -- ============================================================
        -- Report Titles  (REPORT:New())
        -- ============================================================
        REPORT_CRATES_FOUND             = "附近發現貨箱：",
        REPORT_REMOVING_CRATES          = "移除附近貨箱：",
        REPORT_TRANSPORT_CHECKOUT       = "運輸檢查表",
        REPORT_INVENTORY                = "庫存報表",
        REPORT_BUILD_CHECKLIST          = "建設檢查清單",
        REPORT_REPAIR_CHECKLIST         = "維修檢查清單",
        REPORT_BEACONS                  = "區域信標狀態",
        -- ============================================================
        -- Report Section Headers  (report:Add())
        -- ============================================================
        REPORT_SECTION_TROOPS           = "        -- 部隊 --",
        REPORT_SECTION_CRATES           = "       -- 貨箱 --",
        REPORT_SECTION_CRATES_GC        = "       -- 地勤裝載貨箱 --",
        REPORT_SECTION_NONE             = "        無",
        REPORT_SECTION_NONE_ALT         = "     --- 未發現 ---",
        REPORT_SECTION_NONE_REPAIR      = "     --- 未發現 ---",
        REPORT_GC_LOADABLE_HINT         = "可能可由地勤裝載（F8）",
        REPORT_TOTAL_MASS               = "總重量：%s 公斤，可裝載：%s 公斤",
        REPORT_TROOPS_CRATES_COUNT      = "部隊：%d(%d)，貨箱：%d(%d)",
        REPORT_TROOPS_CRATETYPES_COUNT  = "部隊：%d，貨箱種類：%d",
        -- ============================================================
        -- Report Row Templates  (per-item lines in reports)
        -- ============================================================
        REPORT_ROW_TROOP                = "部隊：%s 人數 %d",
        REPORT_ROW_CRATE                = "貨箱：%s %d/%d",
        REPORT_ROW_CRATE_SIZE1          = "貨箱：%s 尺寸 1",
        REPORT_ROW_GC_CRATE             = "地勤裝載貨箱：%s 尺寸 1",
        REPORT_ROW_DROPPED_CRATE        = "已投放 %s 貨箱，%d 公斤",
        REPORT_ROW_CRATE_KG             = "%s 貨箱，%d 公斤",
        REPORT_ROW_CRATE_REMOVED        = "%s 貨箱，%d 公斤 已移除",
        REPORT_ROW_UNIT_STOCK           = "單位：%s | 士兵：%d | 庫存：%s",
        REPORT_ROW_TYPE_CRATE_STOCK     = "類型：%s | 每組貨箱：%d | 庫存：%s",
        REPORT_ROW_TYPE_STOCK           = "類型：%s | 庫存：%s",
        REPORT_ROW_BUILD_CHECK          = "類型：%s | 需求 %d | 已有 %d | 可建設 %s",
        REPORT_ROW_REPAIR_CHECK         = "類型：%s | 需求 %d | 已有 %d | 可維修 %s",
        REPORT_ROW_BEACON               = " %s | FM %s MHz | VHF %s KHz | UHF %s MHz ",
        -- ============================================================
        -- Weight / Crate limit tokens
        -- ============================================================
        WEIGHT_LIMIT                    = "已達重量上限",
        CRATE_LIMIT                     = "已達貨箱上限",
        -- ============================================================
        -- Menu labels - Top level
        -- ============================================================
        MENU_CTLD                       = "後勤管理(CTLD)",
        MENU_MANAGE_TROOPS              = "部隊管理",
        MENU_MANAGE_CRATES              = "貨箱管理",
        MENU_MANAGE_UNITS               = "單位管理",
        -- ============================================================
        -- Menu labels - Troops
        -- ============================================================
        MENU_LOAD_TROOPS                = "裝載部隊",
        MENU_DROP_TROOPS                = "投放部隊",
        MENU_DROP_ALL_TROOPS            = "投放全部部隊",
        MENU_EXTRACT_TROOPS             = "撤離部隊",
        MENU_DROP_N_TROOPS              = "投放 (%d) %s",
        -- ============================================================
        -- Menu labels - Crates: Get
        -- ============================================================
        MENU_GET_CRATES                 = "取得貨箱",
        MENU_GET                        = "取得",
        MENU_GET_AND_LOAD               = "取得並裝載",
        MENU_GET_ANYWAY                 = "強制取得",
        MENU_PARTIALLY_LOAD             = "部分裝載",
        MENU_OUT_OF_STOCK               = "無庫存",
        MENU_TROOP_LIMIT                = "已達部隊上限",
        -- ============================================================
        -- Menu labels - Crates: Load
        -- ============================================================
        MENU_LOAD_CRATES                = "裝載貨箱",
        MENU_LOAD_ALL                   = "全部裝載",
        MENU_SHOW_LOADABLE_CRATES       = "顯示可裝載貨箱",
        MENU_NO_CRATES_FOUND_RESCAN     = "未發現貨箱，重新掃描？",
        MENU_USE_C130_LOAD              = "使用 C-130 裝載系統",
        MENU_LOAD_SINGLE                = "裝載",
        -- ============================================================
        -- Menu labels - Crates: Drop
        -- ============================================================
        MENU_DROP_CRATES                = "投放貨箱",
        MENU_DROP_ALL_CRATES            = "投放全部貨箱",
        MENU_DROP                       = "投放",
        MENU_DROP_AND_BUILD             = "投放並建設",
        MENU_DROP_N_SETS                = "投放 %d 組%s",
        MENU_NO_CRATES_TO_DROP          = "沒有可投放貨箱",
        -- ============================================================
        -- Menu labels - Crates: Build / Repair / Pack / Remove
        -- ============================================================
        MENU_BUILD_CRATES               = "建設貨箱",
        MENU_REPAIR                     = "維修",
        MENU_PACK_CRATES                = "打包貨箱",
        MENU_PACK                       = "打包",
        MENU_SCAN_PACKABLE_UNITS        = "掃描可打包單位",
        MENU_NO_PACKABLE_UNITS_FOUND_RESCAN = "未發現可打包單位，重新掃描？",
        MENU_PACK_ALL                   = "打包附近",
        MENU_PACK_AND_LOAD              = "打包並裝載",
        MENU_PACK_AND_LOAD_ALL          = "打包並裝載附近",
        MENU_PACK_AND_REMOVE            = "打包並移除",
        MENU_PACK_AND_REMOVE_ALL        = "打包並移除附近",
        MENU_REMOVE_CRATES              = "移除貨箱",
        MENU_REMOVE_CRATES_NEARBY       = "移除附近貨箱",
        MENU_LIST_CRATES_NEARBY         = "列出附近貨箱",
        MENU_CRATES_NEEDED              = "%d 個貨箱%s %s（%d 公斤）",
        MENU_CRATE_SINGLE               = "%s（%d 公斤）",
        -- ============================================================
        -- Menu labels - Units (C-130)
        -- ============================================================
        MENU_GET_UNITS                  = "取得單位",
        MENU_REMOVE_UNITS_NEARBY        = "移除附近單位",
        -- ============================================================
        -- Menu labels - Info / Cargo
        -- ============================================================
        MENU_LIST_BOARDED_CARGO         = "查看已裝載貨物",
        MENU_INVENTORY                  = "庫存",
        MENU_LIST_ZONE_BEACONS          = "列出區域信標",
        -- ============================================================
        -- Menu labels - Smokes / Flares / Beacons
        -- ============================================================
        MENU_SMOKES_FLARES_BEACONS      = "煙霧、照明彈、信標",
        MENU_SMOKE_ZONES_NEARBY         = "標記附近區域",
        MENU_DROP_SMOKE_NOW             = "立即投放煙霧",
        MENU_RED_SMOKE                  = "紅色煙霧",
        MENU_BLUE_SMOKE                 = "藍色煙霧",
        MENU_GREEN_SMOKE                = "綠色煙霧",
        MENU_ORANGE_SMOKE               = "橙色煙霧",
        MENU_WHITE_SMOKE                = "白色煙霧",
        MENU_FLARE_ZONES_NEARBY         = "標記附近區域（照明彈）",
        MENU_FIRE_FLARE_NOW             = "立即發射照明彈",
        MENU_DROP_BEACON_NOW            = "立即投放信標",
        -- ============================================================
        -- Menu labels - Parameters
        -- ============================================================
        MENU_SHOW_FLIGHT_PARAMS         = "顯示飛行參數",
        MENU_SHOW_HOVER_PARAMS          = "顯示懸停參數",
        STOCK_NONE                      = "無",
        STOCK_UNLIMITED                 = "無限制",
        BUILD_YES                       = "是",
        BUILD_NO                        = "否",
    },
    ["zh-CN"] = {
        -- ============================================================
        -- Crate / Cargo Loading
        -- ============================================================
        CRATE_LOADED_GROUNDCREW         = "地勤已装载货箱 %s！",
        CRATE_UNLOADED_GROUNDCREW       = "地勤已卸载货箱 %s！",
        CRATE_LOADED_ID                 = "货箱 ID %d（%s）已装载！",
        LOADED_FULL                     = "已装载 %d 个 %s。",
        LOADED_SETS_LEFTOVER            = "已装载 %d 组 %s，剩余 %d 个货箱。",
        LOADED_SETS                     = "已装载 %d 组 %s。",
        LOADED_PARTIAL                  = "仅装载 %d/%d 个 %s 的货箱。",
        LOADED_PARTIAL_LIMIT            = "仅装载 %d/%d 个 %s 的货箱，已达到载重上限！",
        LOADED_BATCH                    = "已装载 %d 个 %s。",
        LOADED_BATCH_PARTIAL            = "部分组合未能完整装载。",
        
        -- ============================================================
        -- Dropping / Unloading
        -- ============================================================
        DROPPED_FULL                    = "已投放 %d 个 %s。",
        DROPPED_SETS_LEFTOVER           = "已投放 %d 组 %s，剩余 %d 个货箱。",
        DROPPED_SETS                    = "已投放 %d 组 %s。",
        DROPPED_PARTIAL                 = "已投放 %d/%d 个 %s 的货箱。",
        DROPPED_INTO_ACTION             = "已将 %s 投入作战！",
        DROPPED_BEACON                  = "已投放 %s | FM %s MHz | VHF %s KHz | UHF %s MHz ",
        CRATES_POSITIONED               = "已在你附近部署 %d 个 %s 货箱！",
        CRATES_DROPPED                  = "已投放 %d 个 %s 货箱！",
        
        -- ============================================================
        -- Troops
        -- ============================================================
        BOARDED                         = "%s 已登机！",
        BOARDING                        = "%s 正在登机！",
        TROOPS_RETURNED                 = "部队已返回基地！",
        TROOPS_LABEL                    = "部队",
        ENGINEERS_LABEL                 = "工兵",
        
        -- ============================================================
        -- Deployment
        -- ============================================================
        DEPLOYED_NEAR_YOU               = "%s 已在你附近部署！",
        UNITS_REMOVED                   = "%s 已移除",
        
        -- ============================================================
        -- Build / Repair
        -- ============================================================
        BUILD_STARTED                   = "开始建造，%d 秒后完成！",
        REPAIR_STARTED                  = "使用 %s 开始维修，耗时 %d 秒",
        NO_UNIT_TO_REPAIR               = "附近没有可维修单位！",
        CANT_REPAIR_WITH                = "无法使用 %s 修复该单位",
        CRATES_MOVE_BEFORE_BUILD        = "*** 建造前请先移动货箱！",
        
        -- ============================================================
        -- Errors - Chopper / Weight / Capacity
        -- ============================================================
        CHOPPER_CANNOT_CARRY            = "该直升机无法运输货箱！",
        TOO_HEAVY                       = "重量超限，无法装载！",
        FULLY_LOADED                    = "已满载！",
        CRAMMED                         = "空间已满！",
        NO_CAPACITY_NOW                 = "当前无法继续装载！",
        NO_MORE_CAPACITY                = "没有剩余空间可装载货箱！",
        CANNOT_LOAD_NONE_OR_FULL        = "无法装载货箱：未找到或已满载。",
        
        -- ============================================================
        -- Errors - Position
        -- ============================================================
        NEED_TO_LAND_OR_HOVER_LOAD      = "需要降落或稳定悬停才能装载！",
        HOVER_OVER_CRATES               = "请在货箱上方悬停进行拾取！",
        LAND_OR_HOVER_OVER_CRATES       = "请降落或在货箱上方悬停进行拾取！",
        MUST_LAND_OR_HOVER_CRATES       = "必须降落或悬停才能装载货箱！",
        NEED_TO_LAND_BUILD              = "飞行员，请降落或停止后再建造！",
        NOT_CLOSE_ENOUGH_LOGISTICS      = "距离后勤区域过远！",
        NOT_CLOSE_ENOUGH_DROP           = "距离投放区域过远！",
        NOT_CLOSE_ENOUGH_ZONE_NM        = "距离区域必须小于 %d 海里！",
        CANNOT_BUILD_LOADING_AREA       = "无法在装载区域建造！",
        
        -- ============================================================
        -- Errors - Doors
        -- ============================================================
        OPEN_DOORS_LOAD_CARGO           = "需要打开舱门才能装载货物！",
        OPEN_DOORS_LOAD_TROOPS          = "需要打开舱门才能装载部队！",
        OPEN_DOORS_EXTRACT_TROOPS       = "需要打开舱门才能撤离部队！",
        OPEN_DOORS_UNLOAD_TROOPS        = "需要打开舱门才能卸载部队！",
        OPEN_DOORS_DROP_CARGO           = "需要打开舱门才能投放货物！",
        
        -- ============================================================
        -- Errors - Stock / Availability
        -- ============================================================
        ALL_GONE                        = "%s 已全部耗尽！",
        RAN_OUT_OF                      = "%s 已用完",
        CARGO_NOT_AVAILABLE_ZONE        = "该区域无法获取此类货物！",
        ENOUGH_CRATES_NEARBY            = "附近已有足够货箱，请先处理现有货箱！",
        NO_CRATES_WITHIN                = "%d 米内没有可装载货箱！",
        NO_CRATES_WITHIN_PLAIN          = "%d 米内没有货箱！",
        NO_CRATES_IN_RANGE              = "范围内未发现货箱！",
        NO_NAMED_CRATES_IN_RANGE        = "范围内未发现“%s”货箱！",
        NO_LOADABLE_CRATES              = "附近没有可装载货箱或已超重！",
        NO_UNITS_TO_EXTRACT             = "附近没有可撤离单位！",
        NO_UNIT_CONFIG                  = "未找到 %s 的单位配置",
        CANT_ONBOARD                    = "无法装载 %s",
        TOO_MANY_UNITS_NEARBY           = "附近已有 %d 个单位！",
        NO_CRATE_GROUPS                 = "未找到该单位对应的货箱组！",
        NO_CRATE_SET                    = "未找到货箱组或索引无效！",
        NO_CRATE_IN_SET                 = "该组中没有货箱！",
        NO_TROOP_CHUNK                  = "未找到 ID %d 的部队数据！",
        TROOP_CHUNK_EMPTY               = "ID %d 的部队数据为空！",
        
        -- ============================================================
        -- Nothing loaded / in stock
        -- ============================================================
        NOTHING_LOADED                  = "未装载任何内容！\n部队上限：%d | 货箱上限 %d | 重量上限 %d 公斤",
        NOTHING_LOADED_AIRDROP          = "未装载或不满足空投条件！",
        NOTHING_LOADED_HOVER            = "未装载或未满足悬停条件！",
        NOTHING_IN_STOCK                = "库存为空！",
        NOTHING_TO_PACK                 = "该范围内没有可打包目标！",
        NOTHING_TO_REMOVE               = "该范围内没有可移除目标！",
        
        -- ============================================================
        -- Zone / Info
        -- ============================================================
        ROGER_ZONE                      = "收到，%s 区域 %s！",
        -- ============================================================
        -- Report: Hover / Flight Parameters
        -- ============================================================
        HOVER_PARAMS_METRIC             = "悬停参数（自动装载/投放）：\n - 最低高度 %d 米 \n - 最高高度 %d 米 \n - 最大速度 2 米/秒 \n - 是否符合条件：%s",
        HOVER_PARAMS_IMPERIAL           = "悬停参数（自动装载/投放）：\n - 最低高度 %d 英尺 \n - 最高高度 %d 英尺 \n - 最大速度 6 英尺/秒 \n - 是否符合条件：%s",
        FLIGHT_PARAMS_IMPERIAL          = "飞行参数（空投）：\n - 最低高度 %d 英尺 \n - 最高高度 %d 英尺 \n - 是否符合条件：%s",
        FLIGHT_PARAMS_METRIC            = "飞行参数（空投）：\n - 最低高度 %d 米 \n - 最高高度 %d 米 \n - 是否符合条件：%s",
        -- ============================================================
        -- Report Titles  (REPORT:New())
        -- ============================================================
        REPORT_CRATES_FOUND             = "附近发现货箱：",
        REPORT_REMOVING_CRATES          = "删除附近货箱：",
        REPORT_TRANSPORT_CHECKOUT       = "运输检查表",
        REPORT_INVENTORY                = "库存报表",
        REPORT_BUILD_CHECKLIST          = "建造检查清单",
        REPORT_REPAIR_CHECKLIST         = "维修检查清单",
        REPORT_BEACONS                  = "区域信标状态",
        -- ============================================================
        -- Report Section Headers  (report:Add())
        -- ============================================================
        REPORT_SECTION_TROOPS           = "        -- 部队 --",
        REPORT_SECTION_CRATES           = "       -- 货箱 --",
        REPORT_SECTION_CRATES_GC        = "       -- 地勤装载货箱 --",
        REPORT_SECTION_NONE             = "        无",
        REPORT_SECTION_NONE_ALT         = "     --- 未发现 ---",
        REPORT_SECTION_NONE_REPAIR      = "     --- 未发现 ---",
        REPORT_GC_LOADABLE_HINT         = "可能可由地勤装载（F8）",
        REPORT_TOTAL_MASS               = "总重量：%s 公斤，可装载：%s 公斤",
        REPORT_TROOPS_CRATES_COUNT      = "部队：%d(%d)，货箱：%d(%d)",
        REPORT_TROOPS_CRATETYPES_COUNT  = "部队：%d，货箱种类：%d",
        -- ============================================================
        -- Report Row Templates  (per-item lines in reports)
        -- ============================================================
        REPORT_ROW_TROOP                = "部队：%s 人数 %d",
        REPORT_ROW_CRATE                = "货箱：%s %d/%d",
        REPORT_ROW_CRATE_SIZE1          = "货箱：%s 尺寸 1",
        REPORT_ROW_GC_CRATE             = "地勤装载货箱：%s 尺寸 1",
        REPORT_ROW_DROPPED_CRATE        = "已投放 %s 货箱，%d 公斤",
        REPORT_ROW_CRATE_KG             = "%s 货箱，%d 公斤",
        REPORT_ROW_CRATE_REMOVED        = "%s 货箱，%d 公斤 已移除",
        REPORT_ROW_UNIT_STOCK           = "单位：%s | 士兵：%d | 库存：%s",
        REPORT_ROW_TYPE_CRATE_STOCK     = "类型：%s | 每组货箱：%d | 库存：%s",
        REPORT_ROW_TYPE_STOCK           = "类型：%s | 库存：%s",
        REPORT_ROW_BUILD_CHECK          = "类型：%s | 需求 %d | 已有 %d | 可建造 %s",
        REPORT_ROW_REPAIR_CHECK         = "类型：%s | 需求 %d | 已有 %d | 可维修 %s",
        REPORT_ROW_BEACON               = " %s | FM %s MHz | VHF %s KHz | UHF %s MHz ",
        -- ============================================================
        -- Weight / Crate limit tokens
        -- ============================================================
        WEIGHT_LIMIT                    = "已达重量上限",
        CRATE_LIMIT                     = "已达货箱上限",
        -- ============================================================
        -- Menu labels - Top level
        -- ============================================================
        MENU_CTLD                       = "后勤系统(CTLD)",
        MENU_MANAGE_TROOPS              = "部队管理",
        MENU_MANAGE_CRATES              = "货箱管理",
        MENU_MANAGE_UNITS               = "单位管理",
        -- ============================================================
        -- Menu labels - Troops
        -- ============================================================
        MENU_LOAD_TROOPS                = "装载部队",
        MENU_DROP_TROOPS                = "投放部队",
        MENU_DROP_ALL_TROOPS            = "投放全部部队",
        MENU_EXTRACT_TROOPS             = "撤离部队",
        MENU_DROP_N_TROOPS              = "投放 (%d) %s",
        -- ============================================================
        -- Menu labels - Crates: Get
        -- ============================================================
        MENU_GET_CRATES                 = "获取货箱",
        MENU_GET                        = "获取",
        MENU_GET_AND_LOAD               = "获取并装载",
        MENU_GET_ANYWAY                 = "强制获取",
        MENU_PARTIALLY_LOAD             = "部分装载",
        MENU_OUT_OF_STOCK               = "无库存",
        MENU_TROOP_LIMIT                = "已达部队上限",
        -- ============================================================
        -- Menu labels - Crates: Load
        -- ============================================================
        MENU_LOAD_CRATES                = "装载货箱",
        MENU_LOAD_ALL                   = "全部装载",
        MENU_SHOW_LOADABLE_CRATES       = "显示可装载货箱",
        MENU_NO_CRATES_FOUND_RESCAN     = "未检测到货箱，是否重新扫描？",
        MENU_USE_C130_LOAD              = "使用 C-130 装载系统",
        MENU_LOAD_SINGLE                = "装载",
        -- ============================================================
        -- Menu labels - Crates: Drop
        -- ============================================================
        MENU_DROP_CRATES                = "投放货箱",
        MENU_DROP_ALL_CRATES            = "投放全部货箱",
        MENU_DROP                       = "投放",
        MENU_DROP_AND_BUILD             = "投放并建造",
        MENU_DROP_N_SETS                = "投放 %d 组%s",
        MENU_NO_CRATES_TO_DROP          = "无可投放货箱",
        -- ============================================================
        -- Menu labels - Crates: Build / Repair / Pack / Remove
        -- ============================================================
        MENU_BUILD_CRATES               = "建造货箱",
        MENU_REPAIR                     = "维修",
        MENU_PACK_CRATES                = "打包货箱",
        MENU_PACK                       = "打包",
        MENU_SCAN_PACKABLE_UNITS        = "扫描可打包单位",
        MENU_NO_PACKABLE_UNITS_FOUND_RESCAN = "未发现可打包单位，重新扫描？",
        MENU_PACK_ALL                   = "打包附近单位",
        MENU_PACK_AND_LOAD              = "打包并装载",
        MENU_PACK_AND_LOAD_ALL          = "打包并装载附近",
        MENU_PACK_AND_REMOVE            = "打包并移除",
        MENU_PACK_AND_REMOVE_ALL        = "打包并移除附近",
        MENU_REMOVE_CRATES              = "移除货箱",
        MENU_REMOVE_CRATES_NEARBY       = "删除附近货箱",
        MENU_LIST_CRATES_NEARBY         = "显示附近货箱",
        MENU_CRATES_NEEDED              = "%d 个货箱%s %s（%d 公斤）",
        MENU_CRATE_SINGLE               = "%s（%d 公斤）",
        -- ============================================================
        -- Menu labels - Units (C-130)
        -- ============================================================
        MENU_GET_UNITS                  = "获取单位",
        MENU_REMOVE_UNITS_NEARBY        = "移除附近单位",
        -- ============================================================
        -- Menu labels - Info / Cargo
        -- ============================================================
        MENU_LIST_BOARDED_CARGO         = "查看已装载货物",
        MENU_INVENTORY                  = "库存",
        MENU_LIST_ZONE_BEACONS          = "显示区域信标",
        -- ============================================================
        -- Menu labels - Smokes / Flares / Beacons
        -- ============================================================
        MENU_SMOKES_FLARES_BEACONS      = "烟雾、照明弹、信标",
        MENU_SMOKE_ZONES_NEARBY         = "标记附近区域",
        MENU_DROP_SMOKE_NOW             = "立即释放烟雾",
        MENU_RED_SMOKE                  = "红色烟雾",
        MENU_BLUE_SMOKE                 = "蓝色烟雾",
        MENU_GREEN_SMOKE                = "绿色烟雾",
        MENU_ORANGE_SMOKE               = "橙色烟雾",
        MENU_WHITE_SMOKE                = "白色烟雾",
        MENU_FLARE_ZONES_NEARBY         = "标记附近区域（照明弹）",
        MENU_FIRE_FLARE_NOW             = "立即发射照明弹",
        MENU_DROP_BEACON_NOW            = "立即投放信标",
        -- ============================================================
        -- Menu labels - Parameters
        -- ============================================================
        MENU_SHOW_FLIGHT_PARAMS         = "显示飞行参数",
        MENU_SHOW_HOVER_PARAMS          = "显示悬停参数",
        STOCK_NONE                      = "无",
        STOCK_UNLIMITED                 = "无限制",
        BUILD_YES                       = "是",
        BUILD_NO                        = "否",
    },
}
