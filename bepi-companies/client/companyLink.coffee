debugThis = debug.context 'companies'

Router.route 'match/company/:invitedById/:invitedId',
   name: 'company.match'
   template: 'companyMatch'
   waitOn: -> [
      Meteor.subscribe 'company', @params.invitedById, subCb('companyMatch',debugThis)
      Meteor.subscribe 'company', @params.invitedId, subCb('companyMatch',debugThis)
   ]
   onBeforeAction: ->
      Translation.addContext 'companies','general', 'countries'
      this.next()
   data: ->
      data = {}
      if this.ready()
         invitedCompany= Companies.findOne this.params.invitedId
         invitedByCompany = Companies.findOne this.params.invitedById
         if invitedCompany and invitedByCompany
            data =
               company:invitedByCompany
               title: Translation.translate 'Do_you_wish_to_link_this_to_your_company', [{replace:"__type",with:"#{invitedByCompany.type}"}]
               linkButton: Translation.translate 'Link_type', [{replace:"__type",with:"#{invitedByCompany.type}"}]
      return data

Template.companyMatch.events
   'click #link': ->
      #get the invitedBy invite and company relation
      invitedByCompanyId = Router.current().params.invitedById
      invitedCompanyId = Router.current().params.invitedId
      relation = Router.current().params.query?.relation
      if relation
         if _.includes relation, "downstream" then relation = "downstream" else relation ="upstream"
      type = this.company.type
      #userCompanyId = Meteor.user().profile.company
      #Meteor.call 'matchCompany', this.company._id,this.companyRelation, (e,r) ->
      Meteor.call 'matchCompany', invitedByCompanyId,invitedCompanyId, relation, (e,r) ->
         if e
            Alert.new e.error, "danger"
         else
            invitedByCompany = Companies.findOne invitedByCompanyId
            if invitedByCompany
               message = Translation.translate 'link_invitation_accepted', [{replace:"__type",with:"#{invitedByCompany.type}"},{noTranslation:"__companyName", with:"#{invitedByCompany.details.companyName}"}]
               Alert.new message, "success"
         Router.go 'home'
   'click #cancel': ->
      invitedByCompany = Companies.findOne Router.current().params.invitedById
      invitedCompany = Companies.findOne Router.current().params.invitedId
      message = Translation.translate 'link_invitation_cancelled_warning', [{replace:"__type",with:"#{invitedByCompany.type}"},{noTranslation:"__companyName", with:"#{invitedByCompany.details.companyName}"}]
      Alert.new message, "warning"
      #inform invitedBy company that the link request is cancelled 
      Meteor.call 'linkRequestCancelled' , invitedByCompany, invitedCompany
      Router.go 'home'




