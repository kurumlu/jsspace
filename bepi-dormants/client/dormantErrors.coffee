Tracker.autorun ->
   if _.includes Meteor.user()?.roles , 'bepi'
      Alert.closeContext "dormantError"
      status = Status.findOne {}
      if status?.dormantErrors
         _.each status.dormantErrors, (err) ->
            unless err.processed
               msg = "<a class=\"deactivateDormantError\" dormantErrorId=\"#{err.id}\" href=\"#\">Click here to deactivate this message</a>" 
               Alert.new  "#{err.message} #{msg}", "danger", 0, "dormantError"


Template.alert.events
   'click .deactivateDormantError': (e,t)-> 
      if @.msg
         errorId = _.split(@.msg , 'dormantErrorId=\"')[1]
         errorId = (_.split errorId, '"')[0]
         if errorId 
            Meteor.call 'dormantErrorProcessed' , errorId, (e,r) ->
               if e
                  console.log "error during dormant error update."
                  console.log e



