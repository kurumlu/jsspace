Package.describe({
   name: 'fta:bepi-usermanagement',
  version: '0.0.1',
  summary: 'management of users.'
});
Package.onUse(function(api) {
	api.use([ 'meteor',
            'stevezhu:lodash',
            'coffeescript',
            'fta:bepi-core',
            'fta:bepi-translation',
            'mquandalle:jade',
            'templating',
            'mongo',
            'iron:router',
            'aldeed:autoform@5.3.2',
            'aldeed:simple-schema',
            'aldeed:autoform-select2',
            'natestrauser:select2',
            'zimme:select2-bootstrap3-css',
            'accounts-password',
            'accounts-base',
            'alanning:roles',
            'fta:bepi-search',
            'ian:accounts-ui-bootstrap-3',
            'gwendall:auth-client-callbacks',
            'fta:bepi-alerts',
            'fta:bepi-companies',
            'reactive-var']);
    api.addFiles(['server/publish.coffee',
            'server/users.coffee'], 'server');
    api.addFiles([ 'client/assignContractor.jade',
            'client/users.jade',
            'client/user.jade',
            'client/contractorlinks.jade',
            'client/schema.coffee',
            'client/users.coffee',
            'client/user.coffee',                
            'client/contractorlinks.coffee',
            'client/assignContractor.coffee'
            ], 'client');
});
