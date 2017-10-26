
###
# Add these events to a template to add (company) search.
# It relies on 'search' and 'searching' being present as
# (reactive) variables in the template context.
#
# It will call @search.set() with the (new and complete) search query,
# with a max rate of once/searchTimeout (1s)
# and call @searching.set(true).
###

searchTimeout = 1000 # ms

Template.companySearch.onRendered -> $('select').select2({placeholder:Translation.translate('country'),allowClear: true})

searchTimer = undefined
updateSearch = (id,val)->
   key = id.replace(/_/g,'.') # DOM ids cannot contain '.', so a placeholde '_' is used
   Meteor.clearTimeout searchTimer if searchTimer # clear previous delay
   searchTimer = Meteor.setTimeout =>
      q = @search.get()
      if _.isEmpty val
         delete q[key] # remove empty fields
      else
         switch key
            # DBID and country refs need to be exact match (efficiency!)
            # otherwise, it becomes a case insensitive search
            when 'details.DBID', 'details.address.country'
               q[key] = val
            else
               q[key] = {$regex:val,$options:'i'}
      @search.set q
      @searching.set true
      return
   , searchTimeout

Template.companySearch.events
   'keyup input': (e,t)->
      # a character is added or removed from an input field
      id = e.target.id
      val = t.$("##{id}").val()
      updateSearch.bind(@) id,val # 'this' is bound to the function, so template vars are accessible
   'change select': (e,t)->
      # a country is selected which has a slightly different jQuery approach 
      id = e.target.id
      val = $('option:selected',e.target).val()
      updateSearch.bind(@) id,val
   'click #clear_search': (e,t)->
      t.$('input').val('')
      @search.set {}
      @searching.set false
      return

Template.registerHelper 'countries', ->
   language = Translation.language()
   Translation.translations.find
         context:"countries"
      ,
         sort:
            "#{language}": 1
         transform: (c)->
            label: c[language]
            value: c._id
