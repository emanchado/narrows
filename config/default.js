module.exports = {
    port: 3000,
    publicAddress: 'http://localhost:3000',

    db: {
        host: 'localhost',
        user: 'narrows',
        password: 'narratornarrows',
        database: 'narrows'
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
