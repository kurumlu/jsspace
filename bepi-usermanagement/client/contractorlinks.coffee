debugThis = false

Router.route 'user/contractorlinks/:_id?',
   template: 'contractorLinks'
   name: 'contractorLinks'
   onBeforeAction: ->
      Translation.addContext  'general','user_management', 'countries'
      this.next()
   waitOn: -> 
      Meteor.subscribe 'users', {},  subCb('users',debugThis)
   data: ->
   	if this.ready() and Meteor.user()
         id=this.params?._id
         contractor = Meteor.users.findOne {_id:id}
         type = contractorContact(id)
         Meteor.autorun =>
            Meteor.subscribe 'sites',{"#{type}.id":id},subCb('sites',debugThis)
         data = 
            contractor:contractor
            contractorlinks:Meteor.users.find 
               $and: [{"profile.contractorContactId":id} , {_id:{$ne:id}}]
         return data

contractorContact = (userId)->
   contractors =  Meteor.users.findOne {_id:userId}
   return (_.intersection contractors.roles, ['consultantContact','assessorContact','chemicalauditorContact','testlabContact'])[0]
individualRoles = (roles) ->
   newRoles=[]
   _.each roles, (role)->
      index= role.search "Contact"
      unless index is -1
         newRoles.push role.substring(0, index)
      else
         newRoles.push role
   return _.compact _.uniq newRoles

surveys =
   assessor:"af"
   consultant:"ipr"
   chemicalauditor:"sccm_audit"
   testlab:"sccm_testing"  

Template.contractorUserRows.helpers
   sites: ->
      # user = Meteor.users.findOne this._id
      # if user
      #    sites = Sites.find {""}
      email = @.emails[0].address
      if email
         roles = individualRoles @.roles
         consultantSites = []
         _.each roles , (role) ->
            survey=surveys[role]
            sites = Sites.find({ "#{role}Individual.email":email , "status.#{survey}":{$in:['ongoing','assigned','open']}}).fetch()
            if sites 
               consultantSites = _.concat consultantSites , sites
      return _.compact _.uniq  consultantSites
   queryString:-> "contractor="+Template.instance().data._id
   hasContact:->
      data = Template.instance().data
      if data.profile?.contractorContactId
         return true
      return true




