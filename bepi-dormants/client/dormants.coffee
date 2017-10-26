Router.route '/valuechain',
   name: 'dormants'
   template: 'dormants'
   waitOn: -> 
      Session.set "page", 1
      Meteor.subscribe 'dormants'
   onBeforeAction: ->
      Translation.addContext 'dormants', 'general','companies','address', 'countries'
      $(window).bind( "scroll" , () ->
         if $(window).scrollTop() == $(document).height()-$(window).height()
            Session.set("page", Session.get("page") + 1);
      )
      Session.set  'supplyChainSearch', {}
      this.next()        
   data: ->
      # wait untill the  router is setup
      if this.ready() and Meteor.user()
         pages = Session.get "page"
         selector = Session.get "supplyChainSearch"
         Meteor.subscribe "dormants" , selector, pages, (e,r) ->
            if e
               console.log Translation.translate 'dormant_data_is_not_available'
         dormants = Dormants.find(selector).fetch()
         if _.isEmpty dormants then  warning = Translation.translate 'no_result_found' else warning =''
         data =
            title:Translation.translate 'Showing_type' , [{replace:"__type",with:"BSCI_Data"}] 
            dormants:dormants
            warning:warning
      return data
   onStop: ->
      Session.set  'supplyChainSearch', {}

scoreColorMatch = 
   "A":"green"
   "B":"green"
   "C":"orange"
   "D":"orange"
   "E":"red"

scoreSurveyColorMatch = 
   'YES':"green"
   'NO':"red"
   'PARTIALLY':"orange"
   'NOT RATED':"gray"
   'N/A':"gray"

entityType =
   1:"participant"
   2:"producer"
   3:"supplier"

environmentalScoreValues =   ["A","B","C","D","E","-"]
otherScoreValues = ["YES","PARTIALLY","NO","NOT RATED","N/A","-"]

Session.setDefault "hideColumns", true

Template.dormantrows.events
   'click .activateDormant': (e,t)->
      #dormant data will be used for creating  a new BEPI company
      message =  Translation.translate 'dormant_activation_warning' 
      if Dialog.confirm message
         Meteor.call 'activateDormant' , @_id, (err,result) ->
            if err
               msg = Translation.translate err.error
               Alert.new msg, 'danger' 
            if result 
               type = entityType["#{t.data.EntityType}"]
               Router.go 'company', {type:type, _id:result}, {query:"dormantActivation=#{t.data.DBID}&new=true"}            

Template.dormants.events
   'click .columnController':-> Session.set "hideColumns", !Session.get "hideColumns"

Template.registerHelper 'isExtendedTable', -> if Session.get("hideColumns") then "display:none" else ""

Template.dormantrows.helpers
   'scoreColorOverallRating': -> scoreColorMatch["#{this.LastAuditResult}"]
   'scoreColorEnvironmentalScore': -> scoreColorMatch["#{this.EnvironmentalScore}"]
   'scoreColorLegalScore':-> scoreSurveyColorMatch["#{this.LegalScore}"]
   'scoreColorWaterScore': -> scoreSurveyColorMatch["#{this.WaterScore}"]
   'scoreColorWasteScore': -> scoreSurveyColorMatch["#{this.WasteScore}"]
   'scoreColorChemicalScore': -> scoreSurveyColorMatch["#{this.ChemicalScore}"]
   'companyType': -> entityType["#{this.EntityType}"]
   'activeInBepi': -> 
      if this.BepiStatus is 'active' then return true
      return false
   'overallScoreContent' : ->
      if this.LastAuditResult is 'Non-Compliant' or this.LastAuditResult is 'Improvements Needed' or this.LastAuditResult is 'Good' 
         return ''
      else return this.LastAuditResult
   isSupplier: ->
      if this.EntityType is 3 then return true
      else return false

changeSearch = (key, option) ->
   search = Session.get 'supplyChainSearch'
   searchKey = "#search#{key}"
   unless option
      #without option
      value = $(searchKey).val()
      if value is "" then delete search["#{key}"]
      else if value is "-" then search["#{key}"] = ""
      else if key is 'EntityName' or key is 'SocialAuditNames'
         search["#{key}"]  =
            '$regex':value
            $options:"i"
      else if key is "DBID" 
         value = _.toUpper value  
         search["#{key}"] = _.split( value ,'S')[0] 
      else
         search["#{key}"] = value
   else
      #with option
      if option is "-" then option=""
      if search["#{key}"]
         if search["#{key}"]["$in"] instanceof Array
            arr = search["#{key}"]["$in"] 
            if key is "EntityType" then arr.push Number(option)
            else arr.push option
            search["#{key}"] = 
               $in:_.uniq arr
      else
         if key is "EntityType" then val =  [Number(option)]
         else val = [option]
         search["#{key}"] = 
            $in:val
   Session.set 'supplyChainSearch', search

Template.dormantsTableWrapper.helpers
   selector: -> Session.get 'supplyChainSearch'
   
Template.dormantsTableWrapper.events
   'keyup #searchDBID': (e,t) -> changeSearch 'DBID'
   'keyup #searchEntityName': (e,t) ->  changeSearch 'EntityName'
   'keyup #searchSocialAuditNames': (e,t) -> changeSearch 'SocialAuditNames'

Template.SectorSelector.events
   'click .searchSector': (e,t) -> changeSearch 'Sector' , e.target.id

Template.SectorSelector.helpers
   options: -> ["Food","Non Food","-"]

Template.OverallEnvScoreSelector.events
   'click .searchOverallEnvScoreSelector': (e,t) -> 
      if e.target.id is "-" then option = ""
      else option = e.target.id
      changeSearch 'EnvironmentalScore' , option

Template.OverallEnvScoreSelector.helpers
   options: -> environmentalScoreValues

Template.LegalScoreSelector.events
   'click .LegalScoreSelector': (e,t) -> 
      if e.target.id is "-" then option = ""
      else option = e.target.id
      changeSearch 'LegalScore' , option

Template.LegalScoreSelector.helpers
   options: -> otherScoreValues

Template.WaterScoreSelector.events
   'click .WaterScoreSelector': (e,t) -> 
      if e.target.id is "-" then option = ""
      else option = e.target.id
      changeSearch 'WaterScore' , option

Template.WaterScoreSelector.helpers
   options: -> otherScoreValues

Template.WasteScoreSelector.events
   'click .WasteScoreSelector': (e,t) -> 
      if e.target.id is "-" then option = ""
      else option = e.target.id
      changeSearch 'WasteScore' , option

Template.WasteScoreSelector.helpers
   options: -> otherScoreValues

Template.ChemicalScoreSelector.events
   'click .ChemicalScoreSelector': (e,t) -> 
      if e.target.id is "-" then option = ""
      else option = e.target.id
      changeSearch 'ChemicalScore' , option

Template.ChemicalScoreSelector.helpers
   options: -> otherScoreValues

Template.CountrySelector.events
   'click .CountrySelector': (e,t) -> changeSearch 'Country' , e.target.id

Template.CountrySelector.helpers
   options: ->
      options=[]
      lang = Session.get('current_language')
      countries = Translation.translations.find({context:"countries"}).fetch()
      _.each countries , (country) ->
         option =
            name:country["#{lang}"]
            code:country._id
         options.push option
      return _.sortBy options , "name"

Template.selectorRow.helpers
   selector: -> Session.get 'supplyChainSearch'
   entityType: ->
      entitytypes = []
      selector = Session.get 'supplyChainSearch'
      if selector?.EntityType
         types = selector.EntityType.$in
         _.each types, (type) ->
            entitytypes.push Translation.translate {_id:entityType["#{type}"]}
      return entitytypes
   countries: ->
      values =[]
      selector = Session.get 'supplyChainSearch'
      if selector?.Country
         countries = selector.Country.$in
         _.each countries, (country) ->
            values.push Translation.translate {_id:country}
      return values

Template.selectorRow.events
   'click #resetSelector': -> 
      Session.set 'supplyChainSearch', {}
      $('#searchDBID').val("")
      $('#searchEntityName').val("")
      $('#searchSocialAuditNames').val("")

Template.CompanyTypeSelector.helpers
   options: ->
      options=[]
      lang = Session.get('current_language')
      _.each [1,2,3], (type)->
         name = Translation.translations.findOne({_id:entityType["#{type}"]})
         if name
            option =
               code:type
               name:name["#{lang}"]
            options.push option
      return options      

Template.CompanyTypeSelector.events
   'click .CompanyTypeSelector': (e,t) -> changeSearch 'EntityType' , Number(e.target.id)



 
