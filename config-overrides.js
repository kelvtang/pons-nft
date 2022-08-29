const webpack = require('webpack');
module.exports = function override(config) {
  const fallback = config.resolve.fallback || {};
  Object.assign(fallback, {
    "assert": require.resolve('assert'),
    "crypto": require.resolve('crypto-browserify'),
    "http": require.resolve('stream-http'),
    "https": require.resolve('https-browserify'),
    "os": require.resolve('os-browserify/browser'),
    "stream": require.resolve('stream-browserify'),
    "buffer": require.resolve("buffer"),
    "path": false,
    "fs": false,
    "child_process": false,
  })
  // config.resolve.fallback = {
  //   "path": false,
  //   "fs": false,
  //   "child_process": false,
  // }
  config.plugins = (config.plugins || []).concat([
    new webpack.ProvidePlugin({
      process: 'process/browser',
      Buffer: ['buffer', 'Buffer']
    })
  ])
  return config;
}