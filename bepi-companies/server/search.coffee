debugThis = debug.context 'companies'

Meteor.methods
   # Returns only the ids of matching companies
   quickSearch: (selector)->
      unless this.userId
         throw new Meteor.Error "unauthorized"
      started = clock()
      guard = new CompanyGuard(this.userId)
      guard.limitQuery selector
      ids = _.map Companies.find(selector,{fields:{_id: 1}}).fetch(), (r)->r._id
      console.log "#{ids.length} ids foundin #{clock(started)}ms for companies #{JSON.stringify(selector)}" if debugThis
      return ids
