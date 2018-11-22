var Migrations = artifacts.require("./Migrations.sol");
const config = require('config')
module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
