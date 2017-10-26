buildOptions = (type) ->
   options = []
   q =
      _id:
         $ne: Router.current().params._id
      type:type
      status: 'active'
   if type is 'producer'
      upstreamSelector = "link.producer": Router.current().params._id
      selector =
         $or:
            [
               upstreamSelector
               q
            ]
      q = selector
   _.each Companies.find(q).fetch(), (company) ->
      unless company?.details?.invisibleToProducers and Meteor.user().isProducer()
         options.push
            label: company.details.companyName
            value: company._id
   id=Router.current().params._id
   return options

@LinkSchema = {}

LinkSchema.branch = new SimpleSchema
   participant:
      type: ["String"],
      label: -> Translation.translate "link_participant",
      optional: true,
      autoform:
         type:"select-checkbox",
         options: -> buildOptions 'participant'
   branch:
      type: ["String"],
      label: -> Translation.translate "link_branch",
      optional: true,
      autoform:
         type:"select-checkbox",
         options: -> buildOptions 'branch'

LinkSchema.supplier = new SimpleSchema
   participant:
      type: ["String"],
      label: -> Translation.translate "link_participant",
      optional: true,
      autoform:
         type:"select-checkbox",
         options: -> buildOptions 'participant'
   branch:
      type: ["String"],
      label: -> Translation.translate "link_branch",
      optional: true,
      autoform:
         type:"select-checkbox",
         options: -> buildOptions 'branch'

LinkSchema.producer = new SimpleSchema
   participant:
      type: ["String"],
      label: -> Translation.translate "link_participant",
      optional: true,
      autoform:
         type:"select-checkbox",
         options: -> buildOptions 'participant'
   branch:
      type: ["String"],
      label: -> Translation.translate "link_branch",
      optional: true,
      autoform:
         type:"select-checkbox",
         options: -> buildOptions 'branch'
   supplier:
      type: ["String"],
      label: -> Translation.translate "link_supplier",
      optional: true,
      autoform:
         type:"select-checkbox",
         options: -> buildOptions 'supplier'
   producer:
      type: ["String"],
      label: -> Translation.translate "link_producer",
      optional: true,
      autoform:
         type:"select-checkbox",
         options: -> buildOptions 'producer'
   upstream:
      type: ["String"],
      label: -> Translation.translate "link_upstream_producer" , 
      optional: true,
      autoform:
         type:"select-checkbox",
         options: -> buildOptions 'producer'