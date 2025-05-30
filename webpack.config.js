const webpack = require('webpack');

module.exports = (config) => {
    config.resolve = {
        ...config.resolve,
        fallback: {
            ...config.resolve.fallback,
            crypto: require.resolve('crypto-browserify'),
        },
    };
    config.plugins = [
        ...(config.plugins || []),
        new webpack.ProvidePlugin({
            crypto: 'crypto-browserify',
        }),
    ];
    return config;
};
