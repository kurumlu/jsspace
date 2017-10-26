debugThis = debug.context "companies"

Meteor.methods
   'reloadCompanyTypes': ->
      unless Roles.userIsInRole this.userId, ['bepi']
         throw new Meteor.Error 'unauthorized'
      CompanyTypes.remove {}
      console.log 'Preloading company types'
      companyTypes = EJSON.parse(Assets.getText("assets/companyTypes.json"))
      _.each companyTypes, (companyType) ->
         # todo: this should be removed once '_id' is used everywhere instead of 'type'
         companyType.type = companyType._id
         CompanyTypes.insert companyType

      Translation.registerContext
         context: "companies"
         translations: -> EJSON.parse Assets.getText "assets/companies.json"

      Translation.registerContext
         context: "bp_invitations"
         translations: -> EJSON.parse Assets.getText "assets/bp_invitations.json"
