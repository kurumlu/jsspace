debugThis = debug.context 'users'

companies = ['participant','supplier','producer','branch']
contractors = ['consultant','assessor','chemicalauditor','testlab']

Meteor.publish 'users', (roles)->
   unless this.userId
      return []
   q = {roles:{$ne:"inactive"}}
   s =
      sort:
         'profile.companyName':1,
         'profile.name':1
   user = Meteor.users.findOne this.userId
   if user.isBepi()
      # Basically, we only load portions of the users list, when needed.
      r = []
      if !roles or roles is 'bepi'
         r.push 'bepi'
      else if roles is 'companies'
         _.each companies , (company) ->
            r.push company
            r.push "#{company}Admin"
      else if roles is 'contractors'
         _.each contractors , (contractor)->
            r.push contractor
            r.push "#{contractor}Contact"
      _.extend q,
         roles:{$in:r}
   else if Roles.userIsInRole this.userId, ['producerAdmin','supplierAdmin','branchAdmin']
      _.extend q,
         "profile.company":user.profile.company
   else if Roles.userIsInRole this.userId, ['participantAdmin']
      branches = Companies.find({"link.participant":user.profile.company,type:"branch"}).fetch()
      branchesUsers =[]
      _.each branches, (branch) ->
         users = Meteor.users.find({"profile.company":branch._id}).fetch()
         branchesUsers = branchesUsers.concat users unless _.isEmpty users
      brachUserIds = _.map branchesUsers, "_id"
      _.extend q,
         $or:[{"profile.company":user.profile.company},{"_id":{$in:brachUserIds}}]
   else if Roles.userIsInRole this.userId, ['consultantContact','assessorContact', 'chemicalauditorContact', 'testlabContact']
      _.extend q,
         $or: [ {_id:this.userId},{ "profile.contractorContactId":this.userId}]
   if debugThis
      # count = Meteor.users.find(q).count()
      console.log  "publishing Users data #{EJSON.stringify(q)}"
   return Meteor.users.find q, { fields: { "emails.address": 1, "roles": 1 , "profile.name": 1, "profile.company": 1,"profile.companyName": 1,"profile.city": 1,"profile.country": 1, "profile.contractorContactId":1} }, {sort:{"roles": 1, "profile.name": 1, "profile.company": 1, "profile.companyName": 1}}

Meteor.publish 'user', (_id)->
   # TODO: Add screening
   return Meteor.users.find _id
	
