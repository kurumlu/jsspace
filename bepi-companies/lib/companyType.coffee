debugThis = debug.context "company_types"

schemaMap =
   label: (val) -> (-> Translation.translate(val))
   regEx: (val) -> SimpleSchema.RegEx[val]
   max: (val) -> if val is 'today' then return new Date().getFullYear()
   type: (val) ->
      switch val
         when 'Number' then Number
         when 'String' then String
         when ['String'] then String
         when 'addressSchema' then Schemas.addressSchema
         when 'contact' then Schemas.contact
   custom: (val) ->
      if val is 'ownershipTypeOther'
         return ->
            if this.field('ownershipType').value is 'other'
               if this.value
                  if this.value is null or this.value is ''
                     return 'required'
               else
                  return 'required'
      else if val is 'otherCountries'
         return ->
            if this.field('otherCountriesPresence').value is 'yes'
               if this.value
                  if this.value.length is 0
                     return 'required'
               else
                  return 'required'
   autoform: (val) ->
      options = []
      _.each val.options, (option) ->
         options.push
            label: -> Translation.translate option.label
            value: option.value
      return {
         type: val.type
         options: options
      }

buildSchema = (schema) ->
   returnSchema = _.mapValues schema, (obj) ->
      return _.mapValues obj, (val,key) -> schemaMap[key]?(val) or val
   return new SimpleSchema returnSchema

class CompanyType
   constructor: (doc) ->
      _.assign @, doc
   simpleSchema: -> buildSchema @schema
   fullSchema: -> buildSchema _.assign _.clone(@schema), @extendedSchema
   invitationSchema: -> buildSchema _.assign _.clone(@schema), @signUpSchema
   isUpstreamFrom: (type)->
      type = CompanyTypes.findOne(type) if _.isString(type)  # allow either the type object or the corresponding String
      _.includes type.upstream,@_id
   isDownstreamFrom: (type)->
      type = type._id if type._id # allow either the type object or the corresponding String
      _.includes @upstream, type
   hasPermission: (type,direction,action)->
      check type, Match.OneOf String,CompanyType
      check direction, Match.OneOf "upstream", "downstream"
      check action, Match.OneOf "query","invite","link","delink","detail"
      type = type._id if type._id # allow either the type object or the corresponding String
      return @permissions[type]?[direction]?[action]?
   isBidirectional: -> _.includes @downstream, @_id

@CompanyTypes = new Mongo.Collection 'companyTypes',
   transform: (doc) -> new CompanyType doc
