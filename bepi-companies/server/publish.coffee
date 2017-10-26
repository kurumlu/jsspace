debugThis = debug.context 'companies'

Meteor.publish 'companyTypes', (q={}) ->
   CompanyTypes.find q

###
# Provide the details for one single company.
# Fields are reduced when:
# - a user is not logged in (invitation)
# - a company isn't matched yet (company matches)
###
Meteor.publish 'company', (_id)->
   check _id, String
   fields = {}
   if this.userId
      guard = new CompanyGuard this.userId
      unless guard.canView(_id)
         fields =  {status:1,details:1,type:1,invitedBy:1}
   return Companies.find {_id:_id},{fields:fields}

###
# Publication for the current users' company.
###
Meteor.publish "userCompany", ->
   unless this.userId
      return # returning 'undefined' will keep the subscription open
   user = Meteor.users.findOne this.userId
   if user?.profile?.company
      return Companies.find user.profile.company
   else
      return this.ready() # mark this subscription as 'ready' as there won't be any data coming

###
# TODO: re-evaluate!
#
# This appears to only be used in dormants anymore.
###

###
# Provide a list of companies that this user's company is
# linked to.
#
###

###
Meteor.publish 'supplyChain', (type)->
   unless this.userId
      return
   check type, String
   user = Meteor.users.findOne this.userId
   if user.isBepi() or user.isContractor()
      # BEPI is not part of a supply chain.
      return this.ready()
   unless user.profile.company
      throw new Meteor.Error "unlinked-user", "Current user is not linked to a company."
   company = Companies.findOne user.profile.company
   #companies direct links
   companies = Companies.find({"link.#{company.type}":company._id}, {metaData:0} ).fetch()
   if _.isEmpty companies then return []
   else
      ids=[company._id]
      _.each companies, (directCompany) -> ids.push directCompany._id
      #companies indirect list of its suppliers  and producers
      linksOfsuppliers = linksOfDirectSuppliers companies
      unless _.isEmpty linksOfsuppliers then ids = ids.concat linksOfsuppliers
      if Roles.userIsInRole user,  ['participant','participantAdmin','branch','branchAdmin']
         branchCompanies = findBranchesSupplyChain companies
      unless _.isEmpty branchCompanies then ids=ids.concat branchCompanies
      return Companies.find {_id:{$in:ids},type:type}, {metaData:0}
branchesIds = (parentIds)->
   tierIds=[]
   companies = Companies.find({_id:{$in:parentIds}}).fetch()
   _.each companies, (company)->
      unless company.type is "producer"
         tiers = Companies.find({"link.#{company.type}":company._id}).fetch()
         unless _.isEmpty tiers
            _.each tiers, (tier) -> tierIds.push tier._id
   return tierIds

findBranchesSupplyChain = (companies)->
   ids=[]
   parentIds=[]
   _.each companies,  (company) -> ids.push company._id
   branchesids=ids
   _.each [1..9], (times) ->
      branchesids = branchesIds branchesids
      unless _.isEmpty branchesids
         ids= ids.concat branchesids
   return _.uniq _.compact ids


linksOfDirectSuppliers = (companies) ->
   producerIds=[]
   _.each companies, (company) ->
      if company.type is "supplier"
         #producers of a direct supplier
         producers = Companies.find({"link.supplier":company._id}, {metaData:0} ).fetch()
         unless _.isEmpty producers
            _.each producers, (producer)-> producerIds.push producer._id
   return producerIds
<<<<<<< HEAD

contractorCompanies = (user)->
   roles = []
   _.each user.roles, (role)->
      if _.includes role, "Contact" then roles.push role.split("Contact")[0]
      else roles.push role
      roles = _.uniq _.compact roles
   contractors = []
   _.each roles , (role) -> 
      contractors.push "#{role}Individual"
      contractors.push "#{role}Contact"
   producersId=[]
   _.each contractors, (assignment) ->
     sites = Sites.find({"#{assignment}.id":user._id}).fetch()
     _.each sites, (site) -> producersId.push site.producerId
   return producersId


###
# Provide a list of companies that this user's company is
# linked to.
###
Meteor.publish 'supplyChain', ->
   unless this.userId
      # Do not throw error if not logged in yet, 
      # but return undefined. The subscription will not be 'ready'.
      return
   user = Meteor.users.findOne this.userId
   if Roles.userIsInRole user, 'bepi'
      # BEPI is not part of a supply chain.
      return []
   if Roles.userIsInRole user,['assessor','consultant','consultantContact', 'assessorContact','chemicalauditor','chemicalauditorContact', 'testlab', 'testlabContact']
      #send all companies assigned to this contractor user
      producerIds = contractorCompanies user
      return Companies.find {_id:{$in:producerIds}}, {metaData:0} 
   unless user.profile.company
      throw new Meteor.Error "unlinked-user", "Current user is not linked to a company."
   company = Companies.findOne user.profile.company
   #companies direct links
   companies = Companies.find({"link.#{company.type}":company._id}, {metaData:0} ).fetch()
   if _.isEmpty companies then return []
   else
      ids=[company._id]
      _.each companies, (directCompany) -> ids.push directCompany._id
      #companies indirect list of its suppliers  and producers
      linksOfsuppliers = linksOfDirectSuppliers companies
      unless _.isEmpty linksOfsuppliers then ids = ids.concat linksOfsuppliers
      if Roles.userIsInRole user,  ['participant','participantAdmin','branch','branchAdmin']
         branchCompanies = findBranchesSupplyChain companies
      unless _.isEmpty branchCompanies then ids=ids.concat branchCompanies
      return Companies.find {_id:{$in:ids}}, {metaData:0} 
###



