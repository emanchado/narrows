module.exports = {
    paths: {
        watched: ['app', 'src/frontend'],
        public: 'public/compiled'
    },

    files: {
        javascripts: {joinTo: {
            'js/ports.bundle.js': /^(src\/frontend|node_modules)/
        }}
    },

    plugins: {
        elmBrunch: {
            mainModules: ['app/Main.elm'],
            makeParameters: []
        },

        babel: {presets: ['es2015']}
    }
};
