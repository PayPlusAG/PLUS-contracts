pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/math/Math.sol";


// https://www.tooploox.com/blog/create-and-distribute-your-erc20-token-with-openzeppelin

/**** 
ganache-cli -a 20
PRIVATE_KEY=70e879b407d6c086603943bac437401847bd37b93a644bb86cb4ce9fea948d18  truffle  migrate --network ganache




 */

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

contract PlusToken is StandardToken {
  string public constant name = "PayPlus Token";
  string public constant symbol = "PLUS";
  uint8 public constant decimals = 18;                      //         0123456789012345678
  uint256 public INITIAL_SUPPLY = uint256(uint256(500000000) * uint256(1000000000000000000));

  constructor() public
  {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }
}