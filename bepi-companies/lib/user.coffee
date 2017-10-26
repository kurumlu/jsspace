###
# Add a helper to the user object that determines visibility of company (fields).
###

all = (type)-> Companies.findIds {type:type,status:{$ne:'closed'}} # ALL companies of this type

Meteor.users.helpers
   company: -> Companies.findOne(@profile.company) if @profile.company
   isOwnCompany: (company)->
      company = company._id unless _.isString(company) # pass an object or an _id
      return @profile.company is company
   hasPermission: (type,direction,action)->
      return true if @isBepi() # one rule to rule them all
      return @company().hasPermission(type,direction,action)
   canEdit: (company)->
      return true if @isBepi() # one rule to rule them all
      return company.status is 'open' or @company().equals(company)
   canInvite: (company)-> @canDo(company,'invite')
   canDetail: (company)-> @isOwnCompany(company) or @canDo(company,'detail')
   canDelink: (company)-> @canDo(company,'delink')
   canDo: (company,action)->
      return true if @isBepi() # one rule to rule them all
      return @company().canDo(company,action)
   'linked.upstream': (type)->
      return all(type) if @isBepi()
      return @company()['linked.upstream'](type)
   'linked.downstream': (type)->
      return all(type) if @isBepi()
      return @company()['linked.downstream'](type)
   linkable: (type)->
      return all(type) if @isBepi() # ALL companies of this type
      return @company().linked(type)
   visible: (type)->
      return all(type) if @isBepi() # ALL companies of this type
      return @company().visible(type)

