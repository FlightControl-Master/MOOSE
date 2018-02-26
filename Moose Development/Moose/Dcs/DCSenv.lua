-------------------------------------------------------------------------------
-- @module env

--- @type env

--- Add message to simulator log with caption "INFO". Message box is optional.
-- @function [parent=#env] info
-- @field #string message message string to add to log.
-- @field #boolean showMessageBox If the parameter is true Message Box will appear. Optional.

--- Add message to simulator log with caption "WARNING". Message box is optional. 
-- @function [parent=#env] warning
-- @field #string message message string to add to log.
-- @field #boolean showMessageBox If the parameter is true Message Box will appear. Optional.

--- Add message to simulator log with caption "ERROR". Message box is optional.
-- @function [parent=#env] error
-- @field #string message message string to add to log.
-- @field #boolean showMessageBox If the parameter is true Message Box will appear. Optional.

--- Enables/disables appearance of message box each time lua error occurs.
-- @function [parent=#env] setErrorMessageBoxEnabled
-- @field #boolean on if true message box appearance is enabled.



env = {} --#env
