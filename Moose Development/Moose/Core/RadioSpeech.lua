--- **Core** - Makes the radio talk.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * Send text strings using a vocabulary that is converted in spoken language.
--   * Possiblity to implement multiple language.
--
-- ===
--
-- ### Authors: FlightControl
--
-- @module Core.Speech
-- @image Core_Radio.JPG

--- Makes the radio speak.
-- 
-- # RADIOSPEECH usage
-- 
--   
-- @type RADIOSPEECH
-- @extends Core.RadioQueue#RADIOQUEUE
RADIOSPEECH = {
  ClassName = "RADIOSPEECH",
  Vocabulary = {
    EN = {},
  }
}


RADIOSPEECH.Vocabulary.EN = {
  ["1"] = { "1", 0.25 },
  ["2"] = { "2", 0.25 },
  ["3"] = { "3", 0.30 },
  ["4"] = { "4", 0.35 },
  ["5"] = { "5", 0.35 },
  ["6"] = { "6", 0.42 },
  ["7"] = { "7", 0.38 },
  ["8"] = { "8", 0.20 },
  ["9"] = { "9", 0.32 },
  ["10"] = { "10", 0.35 },
  ["11"] = { "11", 0.40 },
  ["12"] = { "12", 0.42 },
  ["13"] = { "13", 0.38 },
  ["14"] = { "14", 0.42 },
  ["15"] = { "15", 0.42 },
  ["16"] = { "16", 0.52 },
  ["17"] = { "17", 0.59 },
  ["18"] = { "18", 0.40 },
  ["19"] = { "19", 0.47 },
  ["20"] = { "20", 0.38 },
  ["30"] = { "30", 0.29 },
  ["40"] = { "40", 0.35 },
  ["50"] = { "50", 0.32 },
  ["60"] = { "60", 0.44 },
  ["70"] = { "70", 0.48 },
  ["80"] = { "80", 0.26 },
  ["90"] = { "90", 0.36 },
  ["100"] = { "100", 0.55 },    
  ["1000"] = { "1000", 1 },    

  ["chevy"] = { "chevy", 0.35 },
  ["colt"] = { "colt", 0.35 },
  ["springfield"] = { "springfield", 0.65 },
  ["dodge"] = { "dodge", 0.35 },
  ["enfield"] = { "enfield", 0.5 },
  ["ford"] = { "ford", 0.32 },
  ["pontiac"] = { "pontiac", 0.55 },
  ["uzi"] = { "uzi", 0.28 },

  ["degrees"] = { "degrees", 0.5 },
  ["�"] = { "degrees", 0.5 },
  ["kilometers"] = { "kilometers", 0.65 },
  ["km"] = { "kilometers", 0.65 },
  ["miles"] = { "miles", 0.45 },
  ["mi"] = { "miles", 0.45 },
  
  ["br"] = { "br", 1.1 },
  ["bra"] = { "bra", 0.3 },
  

  ["returning to base"] = { "returning_to_base", 0.85 },
  ["moving on to ground target"] = { "moving_on_to_ground_target", 1.20 },
  ["engaging ground target"] = { "engaging_ground_target", 1.20 },
  ["wheels up"] = { "wheels_up", 0.42 },
  ["landing at base"] = { "landing at base", 0.8 },
  ["patrolling"] = { "patrolling", 0.55 },

  ["for"] = { "for", 0.31 },
  ["and"] = { "and", 0.31 },
  ["at"] = { "at", 0.3 },
  ["dot"] = { "dot", 0.26 },
  ["defender"] = { "defender", 0.45 },
}



--- Create a new RADIOSPEECH object for a given radio frequency/modulation.
-- @param #RADIOSPEECH self
-- @param #number frequency The radio frequency in MHz.
-- @param #number modulation (Optional) The radio modulation. Default radio.modulation.AM.
-- @return #RADIOSPEECH self The RADIOSPEECH object.
function RADIOSPEECH:New(frequency, modulation)

  -- Inherit base
  local self = BASE:Inherit( self, RADIOQUEUE:New( frequency, modulation ) ) -- #RADIOSPEECH
  
  self.Language = "EN"
  
  self:BuildTree()
  
  return self
end


--- Add Sentence to the Speech collection.
-- @param #RADIOSPEECH self
-- @param #string RemainingSentence The remaining sentence during recursion.
-- @param #table Speech The speech node.
-- @param #string Sentence The full sentence.
-- @param #string Data The speech data.
-- @return #RADIOSPEECH self The RADIOSPEECH object.
function RADIOSPEECH:AddSentenceToSpeech( RemainingSentence, Speech, Sentence, Data )

  self:I( { RemainingSentence, Speech, Sentence, Data } )

  local Token, RemainingSentence = RemainingSentence:match( "^ *(%w+)(.*)" )
  self:I( { Token = Token, RemainingSentence = RemainingSentence } )

  -- Is there a Token?
  if Token then

    -- We check if the Token is already in the Speech collection.
    if not Speech[Token] then

      -- There is not yet a vocabulary registered for this.
      Speech[Token] = {}

      if RemainingSentence and RemainingSentence ~= "" then
        -- We use recursion to iterate through the complete Sentence, and make a chain of Tokens.
        -- The last Speech node in the collection contains the Sentence and the Data to be spoken.
        -- This to ensure that during the actual speech:
        -- - Complete sentences are being understood.
        -- - Words without speech are ignored.
        -- - Incorrect sequence of words are ignored.
        Speech[Token].Next = {}
        self:AddSentenceToSpeech( RemainingSentence, Speech[Token].Next, Sentence, Data )
      else
        -- There is no remaining sentence, so we add speech to the Sentence.
        -- The recursion stops here.
        Speech[Token].Sentence = Sentence
        Speech[Token].Data = Data
      end
    end
  end
end

--- Build the tree structure based on the language words, in order to find the correct sentences and to ignore incomprehensible words.
-- @param #RADIOSPEECH self
-- @return #RADIOSPEECH self The RADIOSPEECH object.
function RADIOSPEECH:BuildTree()

  self.Speech = {}
  
  for Language, Sentences in pairs( self.Vocabulary ) do
    self:I( { Language = Language, Sentences = Sentences })
    self.Speech[Language] = {}
    for Sentence, Data in pairs( Sentences ) do
      self:I( { Sentence = Sentence, Data = Data } )
      self:AddSentenceToSpeech( Sentence, self.Speech[Language], Sentence, Data )
    end
  end
  
  self:I( { Speech = self.Speech } )

  return self
end

--- Speak a sentence.
-- @param #RADIOSPEECH self
-- @param #string Sentence The sentence to be spoken.
function RADIOSPEECH:SpeakWords( Sentence, Speech )

  local Word, RemainderSentence = Sentence:match( "^[^%d%a]*(%a*)(.*)" )

  self:I( { Word = Word, Speech = Speech[Word], RemainderSentence = RemainderSentence } )

  if Word and Word ~= "" then

    -- Construct of words
    Word = Word:lower()
    if Speech[Word] then
      -- The end of the sentence has been reached. Now Speech.Next should be nil, otherwise there is an error.
      if Speech[Word].Next == nil then
        self:I( { Sentence = Speech[Word].Sentence, Data = Speech[Word].Data } )
        self:NewTransmission( Speech[Word].Data[1] .. ".wav", Speech[Word].Data[2], "EN/" )
      else 
        if RemainderSentence and RemainderSentence ~= "" then
          RemainderSentence = self:SpeakWords( RemainderSentence, Speech[Word].Next )
        end
      end
    end
  end        
  
  return RemainderSentence

end

--- Speak a sentence.
-- @param #RADIOSPEECH self
-- @param #string Sentence The sentence to be spoken.
function RADIOSPEECH:SpeakDigits( Sentence, Speech )

  local Digits, RemainderSentence = Sentence:match( "^[^%a%d]*(%d*)(.*)" )

  self:I( { Digits = Digits, Speech = Speech[Digits], RemainderSentence = RemainderSentence } )

  if Digits and Digits ~= "" then
    
    -- Construct numbers
    local Number = tonumber( Digits )
    local Multiple = nil
    while Number >= 0 do
      if Number > 1000 then
        Multiple = math.floor( Number / 1000 ) * 1000
      elseif Number > 100 then
        Multiple = math.floor( Number / 100 ) * 100
      elseif Number > 20 then
        Multiple = math.floor( Number / 10 ) * 10
      elseif Number >= 0 then
        Multiple = Number
      end
      Sentence = tostring( Multiple )
      if Speech[Sentence] then
        self:I( { Speech = Speech[Sentence].Sentence, Data = Speech[Sentence].Data } )
        self:NewTransmission( Speech[Sentence].Data[1] .. ".wav", Speech[Sentence].Data[2], "EN/" )
      end
      Number = Number - Multiple
      Number = ( Number == 0 ) and -1 or Number
    end
  end

  return RemainderSentence
end


--- Speak a sentence.
-- @param #RADIOSPEECH self
-- @param #string Sentence The sentence to be spoken.
function RADIOSPEECH:SpeakSymbols( Sentence, Speech )

  local Symbol, RemainderSentence = Sentence:match( "^[^%a%d]*(°*)(.*)" )

  self:I( { Sentence = Sentence, Symbol = Symbol, Speech = Speech[Symbol], RemainderSentence = RemainderSentence } )

  if Symbol and Symbol ~= "" then
    local Word = nil
    if Symbol == "°" then    
      Word = "degrees"
    end
    if Word then
      if Speech[Word] then
        self:I( { Speech = Speech[Word].Sentence, Data = Speech[Word].Data } )
        self:NewTransmission( Speech[Word].Data[1] .. ".wav", Speech[Word].Data[2], "EN/" )
      end
    end
  end

  return RemainderSentence
end


--- Speak a sentence.
-- @param #RADIOSPEECH self
-- @param #string Sentence The sentence to be spoken.
function RADIOSPEECH:Speak( Sentence, Speech )

  self:I( { Sentence, Speech } )

  local Language = self.Language
  
  -- If there is no node for Speech, then we start at the first nodes of the language.
  if not Speech then
    Speech = self.Speech[Language]
  end
  
  self:I( { Speech = Speech, Language = Language } )
  
  self:NewTransmission( "_In.wav", 0.52, "EN/" )
  
  repeat

    Sentence = self:SpeakWords( Sentence, Speech )
    
    self:I( { Sentence = Sentence } )

    Sentence = self:SpeakDigits( Sentence, Speech )

    self:I( { Sentence = Sentence } )
    
--    Sentence = self:SpeakSymbols( Sentence, Speech )
--
--    self:I( { Sentence = Sentence } )

  until not Sentence or Sentence == ""

  self:NewTransmission( "_Out.wav", 0.28, "EN/" )

end
