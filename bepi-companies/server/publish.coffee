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




