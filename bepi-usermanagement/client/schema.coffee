@AddbepiUser = new SimpleSchema
   name:
      type: String
      label: -> Translation.translate "name"
   email:
      type: String
      label: -> Translation.translate "Email"
      regEx: SimpleSchema.RegEx.Email

@AddcontractorUser = new SimpleSchema
   name:
      type: String
      label: -> Translation.translate "name"
   email:
      type: String
      label: -> Translation.translate "Email"
      regEx: SimpleSchema.RegEx.Email
   companyName:
      type: String
      label: -> Translation.translate "company_name"
      autoform:
         type:"select2"
         options: ->
            companyNames=[]
            contractors = Meteor.users.find ({roles:{$in:['consultant','consultantContact','assessor','assessorContact','chemicalauditor','chemicalauditorContact','testlab','testlabContact']}})
            _.each contractors.fetch(), (contractor) ->
               companyNames.push contractor.profile.companyName
            companyNames = _.uniq companyNames
            namesObj = []
            _.each companyNames, (name) ->
               obj =
                  label:name
                  value:name
               namesObj.push obj
            return namesObj
   city:
      type: String
      label: -> Translation.translate "city"
   country:
      type: String
      label: -> Translation.translate "country"
      autoform: 
         type: "select2"
         options: -> 
            return [{ "value": "AFG","label": "Afghanistan"},{"value": "ALA","label": "Aland Islands"}, {"value": "ALB","label": "Albania"}, {"value": "DZA","label": "Algeria"}, {"value": "ASM","label": "American Samoa"}, {"value": "AND","label": "Andorra"}, {"value": "AGO","label": "Angola"}, {"value": "AIA","label": "Anguilla"}, {"value": "ATA","label": "Antarctica"}, {"value": "ATG","label": "Antigua and Barbuda"}, {"value": "ARG","label": "Argentina"}, {"value": "ARM","label": "Armenia"}, {"value": "ABW","label": "Aruba"}, {"value": "AUS","label": "Australia"}, {"value": "AUT","label": "Austria"}, {"value": "AZE","label": "Azerbaijan"}, {"value": "BHS","label": "Bahamas"}, {"value": "BHR","label": "Bahrain"}, {"value": "BGD","label": "Bangladesh"}, {"value": "BRB","label": "Barbados"}, {"value": "BLR","label": "Belarus"}, {"value": "BEL","label": "Belgium"}, {"value": "BLZ","label": "Belize"}, {"value": "BEN","label": "Benin"}, {"value": "BMU","label": "Bermuda"}, {"value": "BTN","label": "Bhutan"}, {"value": "BOL","label": "Bolivia"}, {"value": "BES","label": "Bonaire, Saint Eustatius and Saba"}, {"value": "BIH","label": "Bosnia and Herzegovina"}, {"value": "BWA","label": "Botswana"}, {"value": "BVT","label": "Bouvet Island"}, {"value": "BRA","label": "Brazil"}, {"value": "IOT","label": "British Indian Ocean Territory"}, {"value": "VGB","label": "British Virgin Islands"}, {"value": "BRN","label": "Brunei"}, {"value": "BGR","label": "Bulgaria"}, {"value": "BFA","label": "Burkina Faso"}, {"value": "BDI","label": "Burundi"}, {"value": "KHM","label": "Cambodia"}, {"value": "CMR","label": "Cameroon"}, {"value": "CAN","label": "Canada"}, {"value": "CPV","label": "Cape Verde"}, {"value": "CYM","label": "Cayman Islands"}, {"value": "CAF","label": "Central African Republic"}, {"value": "TCD","label": "Chad"}, {"value": "CHL","label": "Chile"}, {"value": "CHN","label": "China"}, {"value": "CXR","label": "Christmas Island"}, { "value": "CCK","label": "Cocos Islands"}, {"value": "COL", "label": "Colombia"}, {"value": "COM","label": "Comoros"}, {"value": "COK","label": "Cook Islands"}, {"value": "CRI","label": "Costa Rica"}, { "value": "HRV","label": "Croatia"}, {"value": "CUB","label": "Cuba"}, {"value": "CUW","label": "Curacao"}, {"value": "CYP","label": "Cyprus"}, {"value": "CZE","label": "Czech Republic"}, {"value": "COD","label": "Democratic Republic of the Congo"}, {"value": "DNK","label": "Denmark" }, {"value": "DJI","label": "Djibouti"}, {"value": "DMA","label": "Dominica"}, {"value": "DOM","label": "Dominican Republic"}, {"value": "TLS","label": "East Timor"}, {"value": "ECU","label": "Ecuador"}, {"value": "EGY","label": "Egypt"}, {"value": "SLV","label": "El Salvador"}, {"value": "GNQ","label": "Equatorial Guinea"}, {"value": "ERI","label": "Eritrea"}, {"value": "EST","label": "Estonia"}, {"value": "ETH","label": "Ethiopia"}, {"value": "FLK","label": "Falkland Islands"}, {"value": "FRO","label": "Faroe Islands"}, {"value": "FJI","label": "Fiji"}, {"value": "FIN","label": "Finland"}, {"value": "FRA","label": "France"}, {"value": "GUF","label": "French Guiana"}, {"value": "PYF","label": "French Polynesia"}, { "value": "ATF","label": "French Southern Territories"}, {"value": "GAB","label": "Gabon"}, {"value": "GMB","label": "Gambia"}, { "value": "GEO","label": "Georgia" }, {"value": "DEU","label": "Germany"}, {"value": "GHA","label": "Ghana"}, {"value": "GIB","label": "Gibraltar"}, {"value": "GRC", "label": "Greece"}, {"value": "GRL","label": "Greenland"}, {"value": "GRD","label": "Grenada"}, {"value": "GLP","label": "Guadeloupe"}, {"value": "GUM","label": "Guam"}, {"value": "GTM","label": "Guatemala"}, {"value": "GGY", "label": "Guernsey"}, {"value": "GIN","label": "Guinea"}, {"value": "GNB","label": "Guinea-Bissau"}, {"value": "GUY","label": "Guyana"}, {"value": "HTI","label": "Haiti"}, {"value": "HMD","label": "Heard Island and McDonald Islands"}, {"value": "HND", "label": "Honduras"}, { "value": "HKG","label": "Hong Kong"}, {"value": "HUN", "label": "Hungary"}, {"value": "ISL","label": "Iceland"}, {"value": "IND","label": "India"}, {"value": "IDN","label": "Indonesia"}, {"value": "IRN","label": "Iran"}, {"value": "IRQ","label": "Iraq"}, {"value": "IRL","label": "Ireland"}, {"value": "IMN","label": "Isle of Man"}, {"value": "ISR","label": "Israel"}, {"value": "ITA","label": "Italy"}, {"value": "JAM","label": "Jamaica"}, {"value": "JPN","label": "Japan"}, {"value": "JEY", "label": "Jersey"}, { "value": "JOR","label": "Jordan"}, {"value": "KAZ","label": "Kazakhstan"}, {"value": "KEN","label": "Kenya"}, {"value": "KIR","label": "Kiribati"}, {"value": "KOR","label": "Korea (South Korea)" }, {"value": "XKX","label": "Kosova"},{"value": "KWT","label": "Kuwait"}, {"value": "KGZ","label": "Kyrgyzstan"}, {"value": "LAO","label": "Laos"}, {"value": "LVA","label": "Latvia"}, {"value": "LBN","label": "Lebanon" }, {"value": "LSO", "label": "Lesotho" }, { "value": "LBR", "label": "Liberia" }, { "value": "LBY", "label": "Libya" }, { "value": "LIE", "label": "Liechtenstein" }, { "value": "LTU", "label": "Lithuania" }, { "value": "LUX", "label": "Luxembourg" }, { "value": "MAC", "label": "Macao" }, { "value": "MKD", "label": "Macedonia" }, { "value": "MDG", "label": "Madagascar" }, { "value": "MWI", "label": "Malawi" }, { "value": "MYS", "label": "Malaysia" }, { "value": "MDV", "label": "Maldives" }, { "value": "MLI", "label": "Mali" }, { "value": "MLT", "label": "Malta" }, { "value": "MHL", "label": "Marshall Islands" }, { "value": "MTQ", "label": "Martinique" }, { "value": "MRT", "label": "Mauritania" }, { "value": "MUS", "label": "Mauritius" }, { "value": "MYT", "label": "Mayotte" }, { "value": "MEX", "label": "Mexico" }, { "value": "FSM", "label": "Micronesia" }, { "value": "MDA", "label": "Moldova" }, { "value": "MCO", "label": "Monaco" }, { "value": "MNG", "label": "Mongolia" }, { "value": "MNE", "label": "Montenegro" }, { "value": "MSR", "label": "Montserrat" }, { "value": "MAR", "label": "Morocco" }, { "value": "MOZ", "label": "Mozambique" }, { "value": "MMR", "label": "Myanmar" }, { "value": "NAM", "label": "Namibia" }, { "value": "NRU", "label": "Nauru" }, { "value": "NPL", "label": "Nepal" }, { "value": "NLD", "label": "Netherlands" }, { "value": "NCL", "label": "New Caledonia" }, { "value": "NZL", "label": "New Zealand" }, { "value": "NIC", "label": "Nicaragua" }, { "value": "NER", "label": "Niger" }, { "value": "NGA", "label": "Nigeria" }, { "value": "NIU", "label": "Niue" }, { "value": "NFK", "label": "Norfolk Island" }, { "value": "MNP", "label": "Northern Mariana Islands" }, { "value": "NOR", "label": "Norway" }, { "value": "OMN", "label": "Oman" }, { "value": "PAK", "label": "Pakistan" }, { "value": "PLW", "label": "Palau" }, { "value": "PSE", "label": "Palestinian Territories" }, { "value": "PAN", "label": "Panama" }, { "value": "PNG", "label": "Papua New Guinea" }, { "value": "PRY", "label": "Paraguay" }, { "value": "PRK", "label": "People\u00e9s Republic of Korea (North Korea)" }, { "value": "PER", "label": "Peru" }, { "value": "PHL", "label": "Philippines" }, { "value": "PCN", "label": "Pitcairn" }, { "value": "POL", "label": "Poland" }, { "value": "PRT", "label": "Portugal" }, { "value": "PRI", "label": "Puerto Rico" }, { "value": "QAT", "label": "Qatar" }, { "value": "COG", "label": "Republic of the Congo" }, { "value": "REU", "label": "Reunion" },{ "value": "ROU", "label": "Romania" }, { "value": "RUS", "label": "Russia" }, { "value": "RWA", "label": "Rwanda" }, { "value": "BLM", "label": "Saint Barth\u00e9lemy" }, { "value": "SHN", "label": "Saint Helena" }, { "value": "SKN", "label": "Saint Kitts and Nevis" }, { "value": "LCA", "label": "Saint Lucia" }, { "value": "MAF", "label": "Saint Martin" }, { "value": "SPM", "label": "Saint Pierre and Miquelon" }, { "value": "VCT", "label": "Saint Vincent and the Grenadines" }, { "value": "WSM", "label": "Samoa" }, { "value": "SMR", "label": "San Marino" }, { "value": "STP", "label": "Sao Tome and Principe" },{ "value": "SAU", "label": "Saudi Arabia" }, { "value": "SEN", "label": "Senegal" }, { "value": "SRB", "label": "Serbia" }, { "value": "SYC", "label": "Seychelles" }, { "value": "SLE", "label": "Sierra Leone" }, { "value": "SGP", "label": "Singapore" },  { "value": "SXM", "label": "Sint Maarten" },{ "value": "SVK", "label": "Slovakia" }, { "value": "SVN", "label": "Slovenia" }, { "value": "SLB", "label": "Solomon Islands" }, { "value": "SOM", "label": "Somalia" }, { "value": "ZAF", "label": "South Africa" }, { "value": "SGS", "label": "South Georgia and the South Sandwich Islands" }, { "value": "ESP", "label": "Spain" }, { "value": "LKA", "label": "Sri Lanka" }, { "value": "SDN", "label": "Sudan" }, { "value": "SUR", "label": "Suriname" }, { "value": "SJM", "label": "Svalbard and Jan Mayen" }, { "value": "SWZ", "label": "Swaziland" }, { "value": "SWE", "label": "Sweden" }, { "value": "CHE", "label": "Switzerland" }, { "value": "SYR", "label": "Syria" }, { "value": "TWN", "label": "Taiwan" }, { "value": "TJK", "label": "Tajikistan" }, { "value": "TZA", "label": "Tanzania" }, { "value": "THA", "label": "Thailand" }, { "value": "TGO", "label": "Togo" }, { "value": "TKL", "label": "Tokelau" }, { "value": "TON", "label": "Tonga" }, { "value": "TTO", "label": "Trinidad and Tobago" }, { "value": "TUN", "label": "Tunisia" }, { "value": "TUR", "label": "Turkey" }, { "value": "TKM", "label": "Turkmenistan" }, { "value": "TCA", "label": "Turks and Caicos Islands" }, { "value": "TUV", "label": "Tuvalu" }, { "value": "VIR", "label": "U.S. Virgin Islands" }, { "value": "UGA", "label": "Uganda" }, { "value": "UKR", "label": "Ukraine" }, { "value": "ARE", "label": "United Arab Emirates" }, { "value": "GBR", "label": "United Kingdom" }, { "value": "USA", "label": "United States" }, { "value": "UMI", "label": "United States Minor Outlying Islands" }, { "value": "URY", "label": "Uruguay" }, { "value": "UZB", "label": "Uzbekistan" }, { "value": "VUT", "label": "Vanuatu" }, { "value": "VAT", "label": "Vatican City" }, { "value": "VEN", "label": "Venezuela" }, { "value": "VNM", "label": "Vietnam" },  { "value": "WLF", "label": "Wallis and Futuna" }, { "value": "ESH", "label": "Western Sahara" }, { "value": "YEM", "label": "Yemen" }, { "value": "ZMB", "label": "Zambia" }, { "value": "ZWE", "label": "Zimbabwe" }]
   roles:
      type: [String]
      label:->Translation.translate "roles"
      autoform: 
         type: "select2"
         afFieldInput:
            multiple: true
         options: -> 
            return [
               {"label": "Consultant", "value": "consultant"}
               {"label": "Consultant Contact", "value": "consultantContact"}
               {"label": "Assessor", "value": "assessor"}
               {"label": "Assessor Contact", "value": "assessorContact"}
               {"label": "Chemical Auditor", "value": "chemicalauditor"}
               {"label": "Chemical Auditor Contact", "value": "chemicalauditorContact"}
               {"label": "Test Lab", "value": "testlab"}
               {"label": "Test Lab Contact", "value": "testlabContact"}
            ]

@AddcompanyUser = new SimpleSchema
   name:
      type: String
      label: -> Translation.translate "name"
   email:
      type: String
      label: -> Translation.translate "Email"
      regEx: SimpleSchema.RegEx.Email
   company:
      type: String
      label: ->Translation.translate "company"
      autoform: 
         type: "select2"
         options: ->
            if Meteor.user().isBepi()
               return Companies.find({},{$sort:{"details.companyName":1}}).map (client)->
                  return (
                     label: client.details.companyName
                     value: client._id
                     )
            else
               userCompany = Meteor.user().company()
               return [
                  "label":userCompany.details.companyName
                  "value":userCompany._id
                  ]

   roles:
      type: [String]
      label:->Translation.translate "roles"
      autoform: 
         type: "select2"
         afFieldInput:
            multiple: true
         options: ->
            if Roles.userIsInRole Meteor.userId(), ['bepi']
               return [
                     {"label": "Producer", "value": "producer"}
                     {"label": "Producer Admin", "value": "producerAdmin"}
                     {"label": "Participant", "value": "participant"}
                     {"label": "Participant Admin", "value": "participantAdmin"}
                     {"label": "Branch", "value": "branch"}
                     {"label": "Branch Admin", "value": "branchAdmin"}
                     {"label": "Supplier", "value": "supplier"}
                     {"label": "Supplier Admin", "value": "supplierAdmin"}
               ]
            else if Roles.userIsInRole Meteor.userId(), ['participantAdmin']
               return [
                     {"label": "Participant", "value": "participant"}
                     {"label": "Participant Admin", "value": "participantAdmin"}
               ]
            else if Roles.userIsInRole Meteor.userId(), [ 'branchAdmin']
               return [
                  {"label": "Branch", "value": "branch"}
                  {"label": "Branch Admin", "value": "branchAdmin"}
               ]
            else if Roles.userIsInRole Meteor.userId(), [ 'supplierAdmin']
               return [
                     {"label": "Supplier", "value": "supplier"}
                     {"label": "Supplier Admin", "value": "supplierAdmin"}
               ]
            else if Roles.userIsInRole Meteor.userId(), [ 'producerAdmin']
               return [
                     {"label": "Producer", "value": "producer"}
                     {"label": "Producer Admin", "value": "producerAdmin"}
               ]


