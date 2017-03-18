

FACSetGroup = SET_GROUP:New():FilterPrefixes( "FAC Group" ):FilterStart()

FACDetection = DETECTION_AREAS:New( FACSetGroup, 1000, 250 )
SeadClientSet = SET_CLIENT:New():FilterCoalitions( "blue" ):FilterStart()
DestroyClientSet = SET_CLIENT:New():FilterCoalitions( "blue" ):FilterStart()

FACReporting = FAC_REPORTING:New( FACClientSet, FACDetection )
