debugThis = debug.context 'companies'
###
# The downstream companies, aka the "supply chain".
# These companies are listed in the "link" section of the 
# supplied company.
#
# _id: company id
# 
# q:
#  type: (sub)selection of company types
#  details:
#     DBID:
#     companyName:
#     address:
#        country:
#     contact:
#        name:
#        email:
#
#  Subscription for all companies in this company's supply chain (aka downstream),
#  that are visible to the current user. In other words, the companies need to be
#  part of the downstream supply chain of the company's user as well.
###

baseOpts = {sort:{'details.companyName':1},fields:{_id:1}}

statusQueries =
   active: 'active'
   invite: {$in:['open','rejected','error']}
   all: {$in:['open','active']}

Meteor.methods
   downstream: (_id,type,status='active',q={})->
      check type, String
      guard = new CompanyGuard @userId, 'companies.downstream'
      # guard.hasPermission(type,'downstream','query')

      ids = []
      if _id
         check _id, String
         company = Companies.findOne _id
         guard.canDetail(company)
         ids = company['linked.downstream'](type)
         # Is this company accessible to the current user?
         # Filter by visible ids
         ids = guard.screen(ids,type)
      else
         ids = guard.user['linked.downstream'](type)
      return [] if _.isEmpty(ids) # shortcut
      _.extend q,
         _id: {$in:ids}
         status: statusQueries[status]
      return Companies.findIds(q)

###
# Upstream companies of the specified company(_id), which
# means it is listed in a link of those companies.
###
Meteor.methods
   upstream: (_id,type,status='active',query={})->
      guard = new CompanyGuard @userId, 'companies.upstream'
      unless _id or guard.user.isBepi() # defaults to the user's company
         _id = guard.user.profile.company
      q =
         type: type
         status: statusQueries[status]
      if _id
         check _id, String
         company = Companies.findOne _id
         guard.canDetail company
         _.extend q,
            "link.#{company.type}":company._id
      if query
         _.extend q, query
      console.log "Querying upstream with #{EJSON.stringify(q)}" if debugThis
      ids = Companies.findIds q
      unscreened = ids.length
      ids = guard.screen(ids,type)
      console.log "Found #{ids.length} ids (#{unscreened-ids.length} were hidden): #{_.take(ids,5).concat(',')},..." if debugThis
      return ids
###
# Provide a (fixed) list of companies that are linked
# to the current user's company but not yet linked
# to the supplied company, in other words,
# the companies to who the user can link this company.
###

automaticLinking = (source, target, action) ->
   console.log "automaticLinking...#{source}...#{target}...#{action}"
   @AutomaticBranchLinking.emptyBranchLinks()
   # participant of a branch should be automatically delinked as well
   participantId = @AutomaticBranchLinking.branchLinks source._id
   console.log "found participantId...#{participantId}"
   user = Meteor.user()
   if participantId
      if action is "delink"
         Companies.update target._id,
            $pull:
               "link.participant": participantId
            $push:
               "metaData.links.#{participantId}":
                  linkedAt: new Date()
                  linkedBy: user._id
                  linkAction: action
                  automaticLinksBy:source._id
      else if actions is "link"
         Companies.update target._id,
            $addToSet:
               "link.participant": participantId
            $push:
               "metaData.links.#{participantId}":
                  linkedAt: new Date()
                  linkedBy: user._id
                  linkAction: action
                  automaticLinksBy:source._id

Meteor.methods
   linkable: (_id,type,direction,query={})->
      guard = new CompanyGuard @userId, 'companies.linkable'
      check _id, String
      check direction, Match.OneOf 'upstream','downstream'
      company = Companies.findOne _id
      guard.canDetail(company)
      allIds = _.difference(guard.user.linkable(type),company["linked.#{direction}"](type)) # the companies that are linkable for this user, but not yet linked
      _.extend query, {_id:{$in:allIds}}
      return Companies.findIds query # rerun to make sure sorting is done correctly

Meteor.methods
   link: (arg)->
      {source,target,direction} = arg
      guard = new CompanyGuard @userId, 'companies.link'
      check direction, Match.OneOf 'upstream','downstream'
      check source, String
      check target, String
      sourceCompany = Companies.findOne source
      targetCompany = Companies.findOne target
      if direction is 'upstream'
         upstream = sourceCompany
         downstream = targetCompany
      else
         upstream = targetCompany
         downstream = sourceCompany
      guard.canLink(upstream, downstream) # is it possible to connect these companies in this direction?

      #if a branch links one of its producer then the participant of a branch should be linked automatically  
      if sourceCompany.type is 'branch' and targetCompany.type is 'producer' 
         console.log 'auto linking'
         branchLinking = new AutomaticBranchLinking()
         branchLinking.automaticLinking(source,target,"link")

      # Actual update
      Companies.update upstream._id,
         $addToSet:
            "link.#{downstream.type}": downstream._id
         $push:
            "metaData.links.#{downstream._id}":
               linkedAt: new Date()
               linkedBy: @userId
               linkAction: "link"
      return {type:sourceCompany.type,direction:direction} # return this so the correct lists can be reloaded
   delink: (arg)->
      console.log arg
      {source,target,direction} = arg
      guard = new CompanyGuard @userId, 'companies.delink'
      check direction, Match.OneOf 'upstream','downstream'
      check source, String
      check target, String
      sourceCompany = Companies.findOne source
      targetCompany = Companies.findOne target
      if direction is 'upstream'
         upstream = sourceCompany
         downstream = targetCompany
      else
         upstream = targetCompany
         downstream = sourceCompany
      
      unless upstream.isUpstreamFrom(downstream)
         throw new Meteor.Error "not-linked","No link found between upstream #{upstream.type} (#{upstream._id} and downstream #{downstream.type} (#{downstream._id})"

      # If a branch is delinked from a producer, the branch linked participant should be delinked, unless there is another branch linking to the same participant
      if sourceCompany.type is 'branch' and targetCompany.type is 'producer' 
         branchLinking = new AutomaticBranchLinking()
         branchLinking.automaticLinking(source,target,"delink")
         
      #if a branch delinking a producer it should be automatically delinked to its participant as well, unless there is another branch linking to the same participant
      Companies.update upstream._id,
         $pull:
            "link.#{downstream.type}": downstream._id
         $push:
            "metaData.links.#{downstream._id}":
               linkedAt: new Date()
               linkedBy: @userId
               linkAction: "delink"
      return {type:sourceCompany.type,direction:direction} # return this so the correct lists can be reloaded

###
# Publishes all companies for which the _ids are specified 
# and which are linked to the current user.
###

Meteor.publish "companies", (ids,type,direction)->
   unless this.userId
      return
   console.log "Subscribing to company ids #{EJSON.stringify(_.take(ids,5))}..." if debugThis
   if _.isEmpty ids
      return this.ready()
   # limit visibility!
   guard = new CompanyGuard @userId, "companies.companies"
   fields = guard.fields(type,direction)
   console.log "Limiting companies subs for ids #{EJSON.stringify(ids)} to #{EJSON.stringify(fields)}" if debugThis
   user = Meteor.user()
   return Companies.find({_id:{$in:ids}},fields)
