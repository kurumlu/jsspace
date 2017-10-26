debugThis = false

Meteor.startup -> CompanyTypes.subscription = Meteor.subscribe 'companyTypes',subCb('companyTypes',debugThis)
Meteor.startup -> Companies.userSub = Meteor.subscribe 'userCompany',subCb('userCompany',debugThis)

