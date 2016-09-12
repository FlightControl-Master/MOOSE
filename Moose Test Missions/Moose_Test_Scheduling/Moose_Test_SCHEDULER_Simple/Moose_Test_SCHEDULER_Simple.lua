GroupTest = GROUP:FindByName("Test")

TestScheduler = SCHEDULER:New( nil, 
  function()
  
    MESSAGE:New("Hello World", 5 ):ToAll()
  
  end, {}, 10, 10 )