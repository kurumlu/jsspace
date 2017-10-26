Package.describe({
   name: 'fta:bepi-dormants',
  summary: 'BEPI - BSCI Interface',
  version: '1.0.0'
});

Package.onUse(function(api) {
   api.versionsFrom('1.1.0.2');
   Npm.depends({
            'formidable':'1.0.17',
            'fast-csv':'1.0.0',
            'ftp':'0.3.10',
            'uuid':'3.1.0'});
   api.use(['coffeescript@1.0.6',
            'underscore@1.0.3',
            'stevezhu:lodash',
            'mongo@1.1.0',
            'iron:router@1.0.9',
            'email',
            'fta:bepi-alerts',
            'fta:bepi-translation'],['client','server']);
   api.use(['http',
            'harrison:papa-parse'],['server']);
   api.use(['templating@1.1.1',
            'session@1.1.0',
            'tracker@1.0.7',
            'mquandalle:jade@0.4.3',
            'ian:accounts-ui-bootstrap-3@1.2.60',
            'jquery@1.11.3_2'],'client');
   api.addFiles(['client/dormants.jade',
                'client/dormants.coffee',
                'client/dormantErrors.coffee'
                ],'client');
   api.addFiles(['lib/collections.coffee'],['client','server']);
   api.addFiles(['server/dormants.coffee',
                 'server/publish.coffee'],'server');
   api.export('Dormants',['client','server']);
});


