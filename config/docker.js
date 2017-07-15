const port = process.env.PORT || 3333;
module.exports = {
    port: port,
    publicAddress: `http://localhost:${port}`,

    db: {
        host: process.env.DB_HOST || 'mysql',
        user: process.env.DB_USER || 'narrows',
        password: process.env.DB_PASSWORD || 'narrowsnarrows',
        database: process.env.DB_NAME || 'narrows'
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
        from: process.env.FROM_EMAIL || '"Narrows" <no-reply@narrows.localhost>',
        options: process.env.NODEMAILER || 'direct://?sendmail=true',
        // If set, means that e-mails will always sent to this
        // address,regardless of the player real e-mail
        // address. Useful for development.
        // alwaysSendTo: 'developer@example.com',
        // This should point to the "mail-templates" in this repo. It
        // may need to be an absolute path (depends on your setup).
        templateDir: './mail-templates'
    }
};
