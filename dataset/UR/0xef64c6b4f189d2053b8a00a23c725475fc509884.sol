 

pragma solidity ^0.5.0;

 
interface ERC165 {
   
   
   
   
   
   
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 
 
interface ISimpleStaking {

  event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
  event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

  function stake(uint256 amount, bytes calldata data) external;
  function stakeFor(address user, uint256 amount, bytes calldata data) external;
  function unstake(uint256 amount, bytes calldata data) external;
  function totalStakedFor(address addr) external view returns (uint256);
  function totalStaked() external view returns (uint256);
  function token() external view returns (address);
  function supportsHistory() external pure returns (bool);

   
   
   
   
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract ERC20 {

   
  function totalSupply() public view returns (uint256 supply);

   
   
  function balanceOf(address _owner) public view returns (uint256 balance);

   
   
   
   
  function transfer(address _to, uint256 _value) public returns (bool success);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

   
   
   
   
  function approve(address _spender, uint256 _value) public returns (bool success);

   
   
   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract TimeLockedStaking is ERC165, ISimpleStaking {
  using SafeMath for uint256;

  struct StakeRecord {
    uint256 amount;
    uint256 unlockedAt;
  }

  struct StakeInfo {
     
    uint256 totalAmount;
     
    uint256 effectiveAt;
     
     
    mapping (bytes32 => StakeRecord) stakeRecords;
  }

   
   
   
  bool public emergency;

   
  address public owner;

   
  ERC20 internal erc20Token;

   
  uint256 internal totalStaked_ = 0;

   
  mapping (address => StakeInfo) public stakers;

  modifier greaterThanZero(uint256 num) {
    require(num > 0, "Must be greater than 0.");
    _;
  }

   
   
   
  constructor(address token_, address owner_) public {
    erc20Token = ERC20(token_);
    owner = owner_;
    emergency = false;
  }

   
   
   
  function supportsInterface(bytes4 interfaceID) external view returns (bool) {
    return
      interfaceID == this.supportsInterface.selector ||
      interfaceID == this.stake.selector ^ this.stakeFor.selector ^ this.unstake.selector ^ this.totalStakedFor.selector ^ this.totalStaked.selector ^ this.token.selector ^ this.supportsHistory.selector;
  }

   
   
   
  function stake(uint256 amount, bytes calldata data) external {
    registerStake(msg.sender, amount, data);
  }

   
   
   
  function stakeFor(address user, uint256 amount, bytes calldata data) external {
    registerStake(user, amount, data);
  }

   
   
   
   
  function unstake(uint256 amount, bytes calldata data)
    external
    greaterThanZero(stakers[msg.sender].effectiveAt)  
    greaterThanZero(amount)
  {
    address user = msg.sender;

    bytes32 recordId = keccak256(data);

    StakeRecord storage record = stakers[user].stakeRecords[recordId];

    require(amount <= record.amount, "Amount must be equal or smaller than the record.");

     
     
    if (!emergency) {
      require(block.timestamp >= record.unlockedAt, "This stake is still locked.");
    }

    record.amount = record.amount.sub(amount);

    stakers[user].totalAmount = stakers[user].totalAmount.sub(amount);
    stakers[user].effectiveAt = block.timestamp;

    totalStaked_ = totalStaked_.sub(amount);

    require(erc20Token.transfer(user, amount), "Transfer failed.");
    emit Unstaked(user, amount, stakers[user].totalAmount, data);
  }

   
  function totalStakedFor(address addr) external view returns (uint256) {
    return stakers[addr].totalAmount;
  }

   
  function totalStaked() external view returns (uint256) {
    return totalStaked_;
  }

   
  function token() external view returns (address) {
    return address(erc20Token);
  }

   
   
  function supportsHistory() external pure returns (bool) {
    return false;
  }


   
  function setEmergency(bool status) external {
    require(msg.sender == owner, "msg.sender must be owner.");
    emergency = status;
  }

   
   

  function max(uint256 a, uint256 b) public pure returns (uint256) {
    return a > b ? a : b;
  }

  function min(uint256 a, uint256 b) public pure returns (uint256) {
    return a > b ? b : a;
  }

  function getStakeRecordUnlockedAt(address user, bytes memory data) public view returns (uint256) {
    return stakers[user].stakeRecords[keccak256(data)].unlockedAt;
  }

  function getStakeRecordAmount(address user, bytes memory data) public view returns (uint256) {
    return stakers[user].stakeRecords[keccak256(data)].amount;
  }

   
   
   
   
   
  function getUnlockedAtSignal(bytes memory data) public view returns (uint256) {
    uint256 unlockedAt;

    if (data.length >= 32) {
      assembly {
        let d := add(data, 32)  
        unlockedAt := mload(d)
      }
    }

     
    uint256 oneYearFromNow = block.timestamp + 365 days;
    uint256 capped = min(unlockedAt, oneYearFromNow);

    return max(1, capped);
  }

   
  function registerStake(address user, uint256 amount, bytes memory data) private greaterThanZero(amount) {
    require(!emergency, "Cannot stake due to emergency.");
    require(erc20Token.transferFrom(msg.sender, address(this), amount), "Transfer failed.");

    StakeInfo storage info = stakers[user];

     
    info.effectiveAt = info.effectiveAt == 0 ? block.timestamp : info.effectiveAt;

     
    bytes32 recordId = keccak256(data);
    StakeRecord storage record = info.stakeRecords[recordId];
    record.amount = amount.add(record.amount);
    record.unlockedAt = record.unlockedAt == 0 ? getUnlockedAtSignal(data) : record.unlockedAt;

     
    info.totalAmount = amount.add(info.totalAmount);
    totalStaked_ = totalStaked_.add(amount);

    emit Staked(user, amount, stakers[user].totalAmount, data);
  }
}