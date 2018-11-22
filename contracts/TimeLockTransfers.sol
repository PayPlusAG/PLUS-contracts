pragma solidity ^0.4.24;

/** a better take on time lock token
  * NOTE: USE AT YOUR OWN RISK
  * NOTE: NO WARRANTY OR GUARANTEE IS GIVEN THIS WILL WORK
  * NOTE: YOU COULD LOSE EVERYTHING
  * NOTE: USE AT YOUR OOWN RISK
  *
  *   Install the contract
  *   There are two public methods of interest
  *     grant("adddressToGiveTokensTo",  amount,  releaseTime);
  *   
  *   before calling grant you need to send tokens to the contract address
  *   grant checks its balance and if there are not enough tokens for the grant
  *   it quits.
  *
  *   grant will emit a Grant event to record the tokens owed to the address
  * 
  *   unlockIfTime()
  *     will unlock the tokens and transfer them if blocktime is greater than release time
  *     this must be called periodically to releas the tokens
  *
  *   unlockIfTime will emit a Given event for each transfer it does
  *
  *   As this is a fully compatible ERC20 token your balance for your grant
  *   can be checked in your wallet.  All transfers and allowance functions will fail.
  *
  * Bret Schlussman, NY NY (C) 2018
  * MIT License is granted\
 */
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TimeLockTransfers {
  using SafeERC20 for ERC20;
  using SafeMath for uint256;

  string public constant name = "Timelock PLUS Token";
  string public constant symbol = "TPLUS";
  uint8 public constant decimals = 18;

  // ERC20 basic token contract being held
  ERC20 public token;

  address[] public walletsLockedup;
  uint256 public  greatestLockTime;

  event Grant(address indexed beneficiary, uint256 amount, uint256 indexed releaseTime);
  event Given(address indexed beneficiary, uint256 amount, uint256 indexed releasedTime);

  struct TimelockMember {
    // beneficiary of tokens after they are released
    address beneficiary;

    // timestamp when token release is enabled
    uint256 releaseTime;

    // flag if this was released 
    bool wasReleased;

    // amount to release 
    uint256 amount;
  }

  mapping (address=>TimelockMember[]) public TimeLocks;

  uint256 totalBalancesLocked;

  constructor(
    ERC20 _token
 )
    public
  {
    token = _token;
     // solium-disable-next-line security/no-block-members
    greatestLockTime = block.timestamp;
    totalBalancesLocked;
  }

  function grant(address _beneficiary, uint256 _releaseTime, uint256 _amountPast) public  returns(uint256) {
      
    // solium-disable-next-line security/no-block-members
    require(_releaseTime > block.timestamp, "Invalid release time");
      


    // make sure this contract has enough coins 
    // to handle the liability
    uint256 amount = token.balanceOf(address(this));
    uint256 totLockedAmount = totalBalancesLocked.add(_amountPast);
    require(amount >= totLockedAmount, "Not enough tokens to lock");

    TimeLocks[_beneficiary].push(TimelockMember(_beneficiary, _releaseTime, false, _amountPast));

    // we need our keys to iterate the mapping
    // if not already there
    if (TimeLocks[_beneficiary].length == 1) {
      walletsLockedup.push(_beneficiary);
    }

    if (_releaseTime > greatestLockTime) {
      greatestLockTime = _releaseTime;
    }

    emit Grant(_beneficiary, _amountPast, _releaseTime);

    totalBalancesLocked = totalBalancesLocked.add(_amountPast);
    return totalBalancesLocked;

  }

  /**
   * @return the balance at a certain release time if we called unlockIfTime
   */
  function balanceAtTime(address _beneficiary, uint256 _releaseTime) public view returns(uint256) {
    // solium-disable-next-line security/no-block-members
    //require(_releaseTime > block.timestamp, "Release time not valid.");

    uint256 total = 0;
    if (TimeLocks[_beneficiary].length > 0) {
      for (uint i = 0 ; i < TimeLocks[_beneficiary].length ; i++) {
        if (TimeLocks[_beneficiary][i].wasReleased == false) {
          // solium-disable-next-line security/no-block-members
          if (TimeLocks[_beneficiary][i].releaseTime <= _releaseTime) {
            // we can add this money
            total = total.add(TimeLocks[_beneficiary][i].amount);
          }
        }
      }
    }
    return total;
  }
  
  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function unlockIfTime() public returns(uint256) {
    // iterate through our array of walletsLockedup
    uint arrayLength = walletsLockedup.length;
    uint totalReleased = 0;
    for (uint x = 0; x<arrayLength; x++) {
      address adr = walletsLockedup[x];
      for (uint i = 0 ; i < TimeLocks[adr].length ; i++) {
        if (TimeLocks[adr][i].wasReleased == false) {
          // solium-disable-next-line security/no-block-members
          if (TimeLocks[adr][i].releaseTime <= block.timestamp) {
            // we can send this money
            //
            token.safeTransfer(TimeLocks[adr][i].beneficiary, TimeLocks[adr][i].amount);
            // do not process this time lock again
            TimeLocks[adr][i].wasReleased = true;
            // decrease the total balances that are locked
            totalBalancesLocked = totalBalancesLocked.sub(TimeLocks[adr][i].amount);
            // tell the caller how much was released
            totalReleased = totalReleased.add(TimeLocks[adr][i].amount);
            // fire the event to 
            // solium-disable-next-line security/no-block-members
            emit Given(TimeLocks[adr][i].beneficiary, TimeLocks[adr][i].amount,  block.timestamp);
          }
          } 
        }
    }
    return totalReleased;
  }

  function allowance(address /* _owner */, address /* _spender */) public pure returns (uint256)
  {
    return 0;
  }

  function transferFrom(address /* _from */, address /* _to */, uint256 /*_value */)  public pure returns (bool)
  {
    return false;
  }

  function approve(address /* _spender */, uint256 /* _value */) public pure returns (bool)
  {
    return false;
  }

  function balanceOf(address _who) public view returns (uint256)
  {
    return balanceAtTime(_who, greatestLockTime); 
  }

  function transfer(address /* _to */, uint256 /* _value */) public pure returns (bool)
  {
    require(false, "Transfer not allowed");
  }

  function availableTokens() public view returns (uint256)
  {
    return token.balanceOf(address(this));
  }

  function assignedTokens() public view returns (uint256)
  {
    return totalBalancesLocked;
  }
    
  function assignableTokens() public view returns (uint256)
  {
    return (availableTokens() - assignedTokens());
  }
}