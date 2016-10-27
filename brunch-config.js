module.exports = {
    paths: {
        public: 'public/'
    },

    files: {
        javascripts: {joinTo: 'app.js'}
    },

    plugins: {
        elmBrunch: {
            mainModules: ['app/Main.elm'],
            makeParameters: ['--warn']
        }
    }
};
