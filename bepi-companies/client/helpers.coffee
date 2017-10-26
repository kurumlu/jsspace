Template.registerHelper 'myCompany', -> Meteor.user().profile.company
Template.registerHelper 'myCompanyType', -> 
	userCompany=Meteor.user().profile.company
	company = Companies.findOne userCompany
	return company?.type
