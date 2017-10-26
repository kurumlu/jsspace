
debugThis = true

Router.route 'invite/company/:type/:_id',
   name: 'invite'
   template: 'companyInvite'
   onBeforeAction: ->
      Translation.addContext  'countries','companies','company_profile','address', 'surveys', 'general', 'address'
      this.next()
   waitOn: ->  [CompanyTypes.subscription, Meteor.subscribe 'company', @params._id, subCb('company',debugThis) ]
   data: ->
      data =
         type: this.params.type
         company: Companies.findOne this.params._id
      companyType = CompanyTypes.findOne {type:this.params.type}
      _.extend data, FormMode.extended this.params,
         roles:
            canEdit: companyType?.canEdit or []
            canInsert: companyType?.canInvite or []
         omitFields:
            edit: ["contactName","contactEmail","contactEmailConfirm"]
            readonly:["contactEmailConfirm"]
         schemas:
            edit: companyType?.simpleSchema()
            insert: companyType?.fullSchema()
            readonly: companyType?.fullSchema()
            invitation: companyType?.invitationSchema()
      return data

Template.companyInvite.events
   'click #acceptButton':-> $('#acceptModal').modal('show')
   'click #rejectButton':-> $('#rejectModal').modal('show')
   'click #rejectCancelButton': -> $('#acceptModal').modal('hide')
   'click #rejectCancelButton': -> $('#rejectModal').modal('hide')
   'click #rejectSubmitButton': ->
      message = $("textarea[name='message']").val()
      Meteor.call 'rejectInvitation', message, this.company._id, (e)->
         if e then console.log e else $('.modal-backdrop').remove()



