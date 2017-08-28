var defer = require('config/defer').deferConfig;

module.exports = {
    port: 3333,
    publicAddress: defer(function(cfg) { return "http://localhost:" +  cfg.port; }),

    db: {
        host: 'mysql',
        user: 'narrows',
        password: 'narrowsnarrows',
        database: 'narrows'
    },

    files: {
        // Make "path" point to a new directory. The user running the
        // server should have permissions to write in it. This
        // directory will hold files like music and images used in the
        // chapters.
        path: 'files/',
        tmpPath: '/tmp/'
    },

    mail: {
        from: '"Narrows" <no-reply@narrows.localhost>',
        options: 'direct://?sendmail=true',
        // If set, means that e-mails will always sent to this
        // address,regardless of the player real e-mail
        // address. Useful for development.
        // alwaysSendTo: 'developer@example.com',
        // This should point to the "mail-templates" in this repo. It
        // may need to be an absolute path (depends on your setup).
        templateDir: './mail-templates'
    }
};
