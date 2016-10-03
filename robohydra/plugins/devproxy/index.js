var heads = require("robohydra").heads,
    RoboHydraHead = heads.RoboHydraHead,
    RoboHydraHeadProxy = heads.RoboHydraHeadProxy;

module.exports.getBodyParts = function() {
    return {
        heads: [
            new RoboHydraHead({
                path: '/static/.*',
                handler: function(req, res, next) {
                    setTimeout(function() {
                        next(req, res);
                    }, 4000);
                }
            }),

            new RoboHydraHeadProxy({
                mountPath: '/',
                proxyTo: 'http://localhost:3000'
            })
        ]
    };
};
