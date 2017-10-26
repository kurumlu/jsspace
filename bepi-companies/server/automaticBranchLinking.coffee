class @AutomaticBranchLinking
   constructor:()->
      unless Meteor.user()
         throw new Meteor.Error 'unauthorized', "You need to be logged in as bepi"
      _.extend @, 
         participant:[]
         branch:[]  
         cont:true
   findLinks: (branchId) ->
      branchCompany = Companies.findOne branchId
      if branchCompany?.link?.participant 
         @participant = @participant.concat branchCompany.link.participant 
      if branchCompany?.link?.branch
         @branch = @branch.concat  branchCompany.link.branch
         return branchCompany.link.branch
      else
         @cont= false
   branchLinks: (branchId) ->
      #we go all the way up to find the participant of a branch
      goOn = @findLinks branchId 
      context = @
      #possible that some branches has no participant at all . Therefor we need to limit our recursive search
      if _.isEmpty @participant 
         while _.isEmpty(@participant) and @cont
            #because it is a recursive function we need to keep the context of the class
            _.each goOn, (branch)-> goOn = context.findLinks branch
   multipleParticipantLinks: (target) ->
      # Check if a company has more then 1 branches linked to the same participant
      company = Companies.findOne target
      participant = @participant[0]
      count = 0
      _.each company.link.branch, (branchId) ->
         if _.includes Companies.findOne(branchId).link.participant, participant
            count++
      if count > 1 then return true else false
   automaticLinking: (source, target, action) ->
      #this sets all the related branches and participant id into internal parameters
      @branchLinks source
      unless @participant then return false
      user = Meteor.user()
      if action is "delink"
         q = "$pull"
         if @multipleParticipantLinks target
            console.log "not unlinking"
            return false
      else if action is "link"
         q = "$addToSet"
      else
         return false
      Companies.update target,
         "#{q}":
            "link.participant": @participant[0]
         $push:
            "metaData.links.#{@participant[0]}":
               linkedAt: new Date()
               linkedBy: user._id
               linkAction: action
               automaticLinksBy:source
updateProducer = (producerId,participantId,branchId) ->
   user = Meteor.user()
   Companies.update producerId,
      "$addToSet":
         "link.participant": participantId
      $push:
         "metaData.links.#{participantId}":
            linkedAt: new Date()
            linkedBy: user._id
            linkAction: "link"
            automaticLinksBy:branchId

Meteor.methods
   automaticLinkToProducers: ->
      unless Roles.userIsInRole this.userId, ['bepi']
         throw new Meteor.Error 'unauthorized'
      branches = Companies.find {type:"branch",status:{$in:["active","open"]}}
      branches.forEach (branch) ->
         console.log "Branch name:#{branch.details.companyName} - id: #{branch._id}   data is being processed "
         producers = Companies.find({type:"producer" , "link.branch":branch._id, status:{$in:["active","open"]}}).fetch()
         if _.isEmpty producers then console.log "No linked producers found  to this branch"
         _.each producers,(producer) -> 
            console.log "Producer id:#{producer._id}  name:#{producer.details.companyName}"
            branchLinking = new AutomaticBranchLinking()
            branchLinking.branchLinks(branch._id)
            #check if the link is already exist for this producer
            update = false
            if _.isEmpty branchLinking.participant  then console.log "No participant found to be linked."
            else 
               if producer?.link?.participant
                  check = _.intersection branchLinking.participant, producer.link
                  if _.isEmpty check
                     updateProducer producer._id, branchLinking.participant[0], branch._id
                     console.log "Participant #{branchLinking.participant} is being linked to producer id:#{producer._id} - name:#{producer.details.companyName}"
                  else
                     console.log "Participant #{branchLinking.participant} is already linked to producer id:#{producer._id} - name:#{producer.details.companyName}"
               else
                  updateProducer producer._id, branchLinking.participant[0], branch._id
                  console.log "Participant #{branchLinking.participant} is being linked to producer id:#{producer._id} - name:#{producer.details.companyName}"

