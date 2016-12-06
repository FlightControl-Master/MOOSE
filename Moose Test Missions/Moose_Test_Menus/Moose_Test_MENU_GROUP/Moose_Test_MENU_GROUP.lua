
do
  -- This demo creates a menu structure for the two groups of planes.
  -- Each group will receive a different menu structure.
  -- To test, join the planes, then look at the other radio menus (Option F10).
  -- Then switch planes and check if the menu is still there.
  -- And play with the Add and Remove menu options.
  
  -- Note that in multi player, this will only work after the DCS groups bug is solved.

  local function ShowStatus( PlaneGroup, StatusText, Coalition )

    MESSAGE:New( Coalition, 15 ):ToRed()
    PlaneGroup:Message( StatusText, 15 )
  end

  local MenuStatus = {}

  local function RemoveStatusMenu( MenuGroup )
    local MenuGroupName = MenuGroup:GetName()
    MenuStatus[MenuGroupName]:Remove()
  end

  --- @param Wrapper.Group#GROUP MenuGroup
  local function AddStatusMenu( MenuGroup )
    local MenuGroupName = MenuGroup:GetName()
    -- This would create a menu for the red coalition under the MenuCoalitionRed menu object.
    MenuStatus[MenuGroupName] = MENU_GROUP:New( MenuGroup, "Status for Planes" )
    MENU_GROUP_COMMAND:New( MenuGroup, "Show Status", MenuStatus[MenuGroupName], ShowStatus, MenuGroup, "Status of planes is ok!", "Message to Red Coalition" )
  end

  SCHEDULER:New( nil,
    function()
      local PlaneGroup = GROUP:FindByName( "Plane 1" )
      if PlaneGroup and PlaneGroup:IsAlive() then
        local MenuManage = MENU_GROUP:New( PlaneGroup, "Manage Menus" )
        MENU_GROUP_COMMAND:New( PlaneGroup, "Add Status Menu Plane 1", MenuManage, AddStatusMenu, PlaneGroup )
        MENU_GROUP_COMMAND:New( PlaneGroup, "Remove Status Menu Plane 1", MenuManage, RemoveStatusMenu, PlaneGroup )
      end
    end, {}, 10, 10 )

  SCHEDULER:New( nil,
    function()
      local PlaneGroup = GROUP:FindByName( "Plane 2" )
      if PlaneGroup and PlaneGroup:IsAlive() then
        local MenuManage = MENU_GROUP:New( PlaneGroup, "Manage Menus" )
        MENU_GROUP_COMMAND:New( PlaneGroup, "Add Status Menu Plane 2", MenuManage, AddStatusMenu, PlaneGroup )
        MENU_GROUP_COMMAND:New( PlaneGroup, "Remove Status Menu Plane 2", MenuManage, RemoveStatusMenu, PlaneGroup )
      end
    end, {}, 10, 10 )

end




