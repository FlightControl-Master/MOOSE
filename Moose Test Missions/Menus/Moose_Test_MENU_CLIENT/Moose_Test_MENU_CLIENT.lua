
do
  -- This demo creates a menu structure for the two clients of planes.
  -- Each client will receive a different menu structure.
  -- To test, join the planes, then look at the other radio menus (Option F10).
  -- Then switch planes and check if the menu is still there.
  -- And play with the Add and Remove menu options.
  
  -- Note that in multi player, this will only work after the DCS clients bug is solved.

  local function ShowStatus( PlaneClient, StatusText, Coalition )

    MESSAGE:New( Coalition, 15 ):ToRed()
    PlaneClient:Message( StatusText, 15 )
  end

  local MenuStatus = {}

  local function RemoveStatusMenu( MenuClient )
    local MenuClientName = MenuClient:GetName()
    MenuStatus[MenuClientName]:Remove()
  end

  --- @param Wrapper.Client#CLIENT MenuClient
  local function AddStatusMenu( MenuClient )
    local MenuClientName = MenuClient:GetName()
    -- This would create a menu for the red coalition under the MenuCoalitionRed menu object.
    MenuStatus[MenuClientName] = MENU_CLIENT:New( MenuClient, "Status for Planes" )
    MENU_CLIENT_COMMAND:New( MenuClient, "Show Status", MenuStatus[MenuClientName], ShowStatus, MenuClient, "Status of planes is ok!", "Message to Red Coalition" )
  end

  SCHEDULER:New( nil,
    function()
      local PlaneClient = CLIENT:FindByName( "Plane 1" )
      if PlaneClient and PlaneClient:IsAlive() then
        local MenuManage = MENU_CLIENT:New( PlaneClient, "Manage Menus" )
        MENU_CLIENT_COMMAND:New( PlaneClient, "Add Status Menu Plane 1", MenuManage, AddStatusMenu, PlaneClient )
        MENU_CLIENT_COMMAND:New( PlaneClient, "Remove Status Menu Plane 1", MenuManage, RemoveStatusMenu, PlaneClient )
      end
    end, {}, 10, 10 )

  SCHEDULER:New( nil,
    function()
      local PlaneClient = CLIENT:FindByName( "Plane 2" )
      if PlaneClient and PlaneClient:IsAlive() then
        local MenuManage = MENU_CLIENT:New( PlaneClient, "Manage Menus" )
        MENU_CLIENT_COMMAND:New( PlaneClient, "Add Status Menu Plane 2", MenuManage, AddStatusMenu, PlaneClient )
        MENU_CLIENT_COMMAND:New( PlaneClient, "Remove Status Menu Plane 2", MenuManage, RemoveStatusMenu, PlaneClient )
      end
    end, {}, 10, 10 )

end




