--- **Core** -- **REPORT** class provides a handy means to create messages and reports.
--
-- ===
--
-- ### Authors:
--
--   * FlightControl : Design & Programming
--
-- ### Contributions:
--
-- @module Core.Report
-- @image Core_Report.JPG


--- The REPORT class
-- @type REPORT
-- @extends Core.Base#BASE
REPORT = {
  ClassName = "REPORT",
  Title = "",
}

--- Create a new REPORT.
-- @param #REPORT self
-- @param #string Title
-- @return #REPORT
function REPORT:New( Title )

  local self = BASE:Inherit( self, BASE:New() ) -- #REPORT

  self.Report = {}

  self:SetTitle( Title or "" )  
  self:SetIndent( 3 )

  return self
end

--- Has the REPORT Text?
-- @param #REPORT self
-- @return #boolean
function REPORT:HasText() --R2.1
  
  return #self.Report > 0
end


--- Set indent of a REPORT.
-- @param #REPORT self
-- @param #number Indent
-- @return #REPORT
function REPORT:SetIndent( Indent ) --R2.1
  self.Indent = Indent
  return self
end


--- Add a new line to a REPORT.
-- @param #REPORT self
-- @param #string Text
-- @return #REPORT
function REPORT:Add( Text )
  self.Report[#self.Report+1] = Text
  return self
end

--- Add a new line to a REPORT.
-- @param #REPORT self
-- @param #string Text
-- @return #REPORT
function REPORT:AddIndent( Text, Separator ) --R2.1
  self.Report[#self.Report+1] = ( ( Separator and Separator .. string.rep( " ", self.Indent - 1 ) ) or string.rep(" ", self.Indent ) ) .. Text:gsub("\n","\n"..string.rep( " ", self.Indent ) )
  return self
end

--- Produces the text of the report, taking into account an optional delimeter, which is \n by default.
-- @param #REPORT self
-- @param #string Delimiter (optional) A delimiter text.
-- @return #string The report text.
function REPORT:Text( Delimiter )
  Delimiter = Delimiter or "\n"
  local ReportText = ( self.Title ~= "" and self.Title .. Delimiter or self.Title ) .. table.concat( self.Report, Delimiter ) or ""
  return ReportText
end

--- Sets the title of the report.
-- @param #REPORT self
-- @param #string Title The title of the report.
-- @return #REPORT
function REPORT:SetTitle( Title )
  self.Title = Title  
  return self
end

--- Gets the amount of report items contained in the report.
-- @param #REPORT self
-- @return #number Returns the number of report items contained in the report. 0 is returned if no report items are contained in the report. The title is not counted for.
function REPORT:GetCount()
  return #self.Report
end
