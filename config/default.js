module.exports = {
    port: 3000,
    publicAddress: 'http://localhost:3000',

    db: {
        path: 'dev.db'
    },

    files: {
        path: 'files/',
        tmpPath: '/tmp/'
    },

    mail: {
        from: '"Narrows" <no-reply@narrows.localhost>',
        templateDir: './mail-templates'
    }
};
