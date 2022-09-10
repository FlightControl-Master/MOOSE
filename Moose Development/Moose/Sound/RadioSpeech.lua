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
-- @module Sound.RadioSpeech
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
    DE = {},
    RU = {},
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
  ["200"] = { "200", 0.55 },
  ["300"] = { "300", 0.61 },
  ["400"] = { "400", 0.60 },
  ["500"] = { "500", 0.61 },
  ["600"] = { "600", 0.65 },
  ["700"] = { "700", 0.70 },
  ["800"] = { "800", 0.54 },
  ["900"] = { "900", 0.60 },
  ["1000"] = { "1000", 0.60 },
  ["2000"] = { "2000", 0.61 },
  ["3000"] = { "3000", 0.64 },
  ["4000"] = { "4000", 0.62 },
  ["5000"] = { "5000", 0.69 },
  ["6000"] = { "6000", 0.69 },
  ["7000"] = { "7000", 0.75 },
  ["8000"] = { "8000", 0.59 },
  ["9000"] = { "9000", 0.65 },

  ["chevy"] = { "chevy", 0.35 },
  ["colt"] = { "colt", 0.35 },
  ["springfield"] = { "springfield", 0.65 },
  ["dodge"] = { "dodge", 0.35 },
  ["enfield"] = { "enfield", 0.5 },
  ["ford"] = { "ford", 0.32 },
  ["pontiac"] = { "pontiac", 0.55 },
  ["uzi"] = { "uzi", 0.28 },

  ["degrees"] = { "degrees", 0.5 },
  ["kilometers"] = { "kilometers", 0.65 },
  ["km"] = { "kilometers", 0.65 },
  ["miles"] = { "miles", 0.45 },
  ["meters"] = { "meters", 0.41 },
  ["mi"] = { "miles", 0.45 },
  ["feet"] = { "feet", 0.29 },

  ["br"] = { "br", 1.1 },
  ["bra"] = { "bra", 0.3 },


  ["returning to base"] = { "returning_to_base", 0.85 },
  ["on route to ground target"] = { "on_route_to_ground_target", 1.05 },
  ["intercepting bogeys"] = { "intercepting_bogeys", 1.00 },
  ["engaging ground target"] = { "engaging_ground_target", 1.20 },
  ["engaging bogeys"] = { "engaging_bogeys", 0.81 },
  ["wheels up"] = { "wheels_up", 0.42 },
  ["landing at base"] = { "landing at base", 0.8 },
  ["patrolling"] = { "patrolling", 0.55 },

  ["for"] = { "for", 0.31 },
  ["and"] = { "and", 0.31 },
  ["at"] = { "at", 0.3 },
  ["dot"] = { "dot", 0.26 },
  ["defender"] = { "defender", 0.45 },
}

RADIOSPEECH.Vocabulary.RU = {
  ["1"] = { "1", 0.34 },
  ["2"] = { "2", 0.30 },
  ["3"] = { "3", 0.23 },
  ["4"] = { "4", 0.51 },
  ["5"] = { "5", 0.31 },
  ["6"] = { "6", 0.44 },
  ["7"] = { "7", 0.25 },
  ["8"] = { "8", 0.43 },
  ["9"] = { "9", 0.45 },
  ["10"] = { "10", 0.53 },
  ["11"] = { "11", 0.66 },
  ["12"] = { "12", 0.70 },
  ["13"] = { "13", 0.66 },
  ["14"] = { "14", 0.80 },
  ["15"] = { "15", 0.65 },
  ["16"] = { "16", 0.75 },
  ["17"] = { "17", 0.74 },
  ["18"] = { "18", 0.85 },
  ["19"] = { "19", 0.80 },
  ["20"] = { "20", 0.58 },
  ["30"] = { "30", 0.51 },
  ["40"] = { "40", 0.51 },
  ["50"] = { "50", 0.67 },
  ["60"] = { "60", 0.76 },
  ["70"] = { "70", 0.68 },
  ["80"] = { "80", 0.84 },
  ["90"] = { "90", 0.71 },
  ["100"] = { "100", 0.35 },
  ["200"] = { "200", 0.59 },
  ["300"] = { "300", 0.53 },
  ["400"] = { "400", 0.70 },
  ["500"] = { "500", 0.50 },
  ["600"] = { "600", 0.58 },
  ["700"] = { "700", 0.64 },
  ["800"] = { "800", 0.77 },
  ["900"] = { "900", 0.75 },
  ["1000"] = { "1000", 0.87 },
  ["2000"] = { "2000", 0.83 },
  ["3000"] = { "3000", 0.84 },
  ["4000"] = { "4000", 1.00 },
  ["5000"] = { "5000", 0.77 },
  ["6000"] = { "6000", 0.90 },
  ["7000"] = { "7000", 0.77 },
  ["8000"] = { "8000", 0.92 },
  ["9000"] = { "9000", 0.87 },

  ["градусы"] = { "degrees", 0.5 },
  ["километры"] = { "kilometers", 0.65 },
  ["km"] = { "kilometers", 0.65 },
  ["мили"] = { "miles", 0.45 },
  ["mi"] = { "miles", 0.45 },
  ["метров"] = { "meters", 0.41 },
  ["m"] = { "meters", 0.41 },
  ["ноги"] = { "feet", 0.37 },

  ["br"] = { "br", 1.1 },
  ["bra"] = { "bra", 0.3 },


  ["возвращение на базу"] = { "returning_to_base", 1.40 },
  ["на пути к наземной цели"] = { "on_route_to_ground_target", 1.45 },
  ["перехват боги"] = { "intercepting_bogeys", 1.22 },
  ["поражение наземной цели"] = { "engaging_ground_target", 1.53 },
  ["привлечение болотных птиц"] = { "engaging_bogeys", 1.68 },
  ["колёса вверх..."] = { "wheels_up", 0.92 },
  ["посадка на базу"] = { "landing at base", 1.04 },
  ["патрулирование"] = { "patrolling", 0.96 },

  ["для"] = { "for", 0.27 },
  ["и"] = { "and", 0.17 },
  ["на сайте"] = { "at", 0.19 },
  ["точка"] = { "dot", 0.51 },
  ["защитник"] = { "defender", 0.45 },
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

function RADIOSPEECH:SetLanguage( Langauge )

  self.Language = Langauge
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

  local Token, RemainingSentence = RemainingSentence:match( "^ *([^ ]+)(.*)" )
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
function RADIOSPEECH:SpeakWords( Sentence, Speech, Language )

  local OriginalSentence = Sentence

  -- lua does not parse UTF-8, so the match statement will fail on cyrillic using %a.
  -- therefore, the only way to parse the statement is to use blank, comma or dot as a delimiter.
  -- and then check if the character can be converted to a number or not.
  local Word, RemainderSentence = Sentence:match( "^[., ]*([^ .,]+)(.*)" )

  self:I( { Word = Word, Speech = Speech[Word], RemainderSentence = RemainderSentence } )


  if Word then
    if Word ~= "" and tonumber(Word) == nil then

      -- Construct of words
      Word = Word:lower()
      if Speech[Word] then
        -- The end of the sentence has been reached. Now Speech.Next should be nil, otherwise there is an error.
        if Speech[Word].Next == nil then
          self:I( { Sentence = Speech[Word].Sentence, Data = Speech[Word].Data } )
          self:NewTransmission( Speech[Word].Data[1] .. ".wav", Speech[Word].Data[2], Language .. "/" )
        else
          if RemainderSentence and RemainderSentence ~= "" then
            return self:SpeakWords( RemainderSentence, Speech[Word].Next, Language )
          end
        end
      end
      return RemainderSentence
    end
    return OriginalSentence
  else
    return ""
  end

end

--- Speak a sentence.
-- @param #RADIOSPEECH self
-- @param #string Sentence The sentence to be spoken.
function RADIOSPEECH:SpeakDigits( Sentence, Speech, Langauge )

  local OriginalSentence = Sentence

  -- lua does not parse UTF-8, so the match statement will fail on cyrillic using %a.
  -- therefore, the only way to parse the statement is to use blank, comma or dot as a delimiter.
  -- and then check if the character can be converted to a number or not.
  local Digits, RemainderSentence = Sentence:match( "^[., ]*([^ .,]+)(.*)" )

  self:I( { Digits = Digits, Speech = Speech[Digits], RemainderSentence = RemainderSentence } )

  if Digits then
    if Digits ~= "" and tonumber( Digits ) ~= nil then

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
          self:NewTransmission( Speech[Sentence].Data[1] .. ".wav", Speech[Sentence].Data[2], Langauge .. "/" )
        end
        Number = Number - Multiple
        Number = ( Number == 0 ) and -1 or Number
      end
      return RemainderSentence
    end
    return OriginalSentence
  else
    return ""
  end

end



--- Speak a sentence.
-- @param #RADIOSPEECH self
-- @param #string Sentence The sentence to be spoken.
function RADIOSPEECH:Speak( Sentence, Language )

  self:I( { Sentence, Language } )

  local Language = Language or "EN"

  self:I( { Language = Language } )

  -- If there is no node for Speech, then we start at the first nodes of the language.
  local Speech = self.Speech[Language]

  self:I( { Speech = Speech, Language = Language } )

  self:NewTransmission( "_In.wav", 0.52, Language .. "/" )

  repeat

    Sentence = self:SpeakWords( Sentence, Speech, Language )

    self:I( { Sentence = Sentence } )

    Sentence = self:SpeakDigits( Sentence, Speech, Language )

    self:I( { Sentence = Sentence } )

--    Sentence = self:SpeakSymbols( Sentence, Speech )
--
--    self:I( { Sentence = Sentence } )

  until not Sentence or Sentence == ""

  self:NewTransmission( "_Out.wav", 0.28, Language .. "/" )

end
