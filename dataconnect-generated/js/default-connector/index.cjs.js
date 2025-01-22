const { getDataConnect, validateArgs } = require('firebase/data-connect');

const connectorConfig = {
  connector: 'default',
  service: 'quran_mobile',
  location: 'us-central1'
};
exports.connectorConfig = connectorConfig;

