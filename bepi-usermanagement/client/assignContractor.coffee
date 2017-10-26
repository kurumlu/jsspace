Router.route '/users/assigncontractor/:_id?',
   name: 'assignNewContractor'
   layout: 'assignNewContractor'
   onBeforeAction: ->
      Translation.addContext  'general','user_management', 'countries'
      this.next()
   waitOn: -> 
      Meteor.subscribe 'users', {},  subCb('users',debugThis)
   data: ->
   	if this.ready() and Meteor.user()
         siteId=this.params?._id
         site = Sites.findOne siteId
         assignedContractorId= this.params?.query?.contractor
         assignedIndividual=Meteor.users.findOne assignedContractorId
         contractorContact=Meteor.users.findOne assignedIndividual.profile?.contractorContactId
         #if there is no contact person assigned then assigned contractors is also the contractorContact
         if contractorContact then contractorContactId=contractorContact._id
         else contractorContactId=assignedIndividual._id
         otherContractors= Meteor.users.find 
            $or: [ { $and: [{"profile.contractorContactId":contractorContactId} , {_id:{$ne:assignedContractorId}}]} , {_id:contractorContactId}]
         data = 
            site:site
            assignedIndividual:Meteor.users.find assignedContractorId
            contractorContact:Meteor.users.find contractorContactId
            otherContractors:otherContractors
         return data

sendMessage = (title, msg1, msg2) ->
   translatedMsg = Translation.translate msg1
   if msg2
      translatedMsg= translatedMsg.concat msg2
   Alert.new translatedMsg, title

Template.contractorRows.events
   'click .assign': (e,t) -> 
      siteId = Router.current().params?._id
      site=Sites.findOne siteId
      assignedContractorId = Router.current().params?.query?.contractor
      newContractorId = t.data.data._id
      if confirm  Translation.translate("Are_you_sure_you_want_to_assign_another_contractor_to_this_site") 
         Meteor.call 'reassignContractor', siteId, assignedContractorId, newContractorId, (e,r) ->
            if e
               Alert.new e , 'danger'
            else
               sendMessage 'success' , 'New contractor is assigned to  ', "#{site.siteName}" 
               #Alert.new "New contractor is assigned to  #{site.siteName}" , 'success'
      Router.go 'usermanagement'



