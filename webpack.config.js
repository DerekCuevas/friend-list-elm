const path = require('path');

module.exports = {
  entry: {
    app: ['./src/index.js'],
  },

  output: {
    path: path.resolve(__dirname + '/dist'),
    filename: 'app.js',
  },

  module: {
    loaders: [
      {
        test: /\.(css)$/,
        loaders: ['style-loader', 'css-loader'],
      },
      {
        test: /\.html$/,
        exclude: /node_modules/,
        loader: 'file-loader?name=[name].[ext]',
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: 'elm-webpack-loader?verbose=true&warn=true&debug=true',
      }
    ],

    noParse: /\.elm$/,
  },

  resolve: {
    extensions: ['.js'],
  },

  devServer: {
    inline: true,
    stats: { colors: true },
  },
};
