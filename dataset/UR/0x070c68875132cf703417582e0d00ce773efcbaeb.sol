 

pragma solidity ^0.4.23;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract TokenTimelockController is Ownable {
  using SafeMath for uint;

  struct TokenTimelock {
    uint256 amount;
    uint256 releaseTime;
    bool released;
    bool revocable;
    bool revoked;
  }

  event TokenTimelockCreated(
    address indexed beneficiary, 
    uint256 releaseTime, 
    bool revocable, 
    uint256 amount
  );

  event TokenTimelockRevoked(
    address indexed beneficiary
  );

  event TokenTimelockBeneficiaryChanged(
    address indexed previousBeneficiary, 
    address indexed newBeneficiary
  );
  
  event TokenTimelockReleased(
    address indexed beneficiary,
    uint256 amount
  );

  uint256 public constant TEAM_LOCK_DURATION_PART1 = 1 * 365 days;
  uint256 public constant TEAM_LOCK_DURATION_PART2 = 2 * 365 days;
  uint256 public constant INVESTOR_LOCK_DURATION = 6 * 30 days;

  mapping (address => TokenTimelock[]) tokenTimeLocks;
  
  ERC20 public token;
  address public crowdsale;
  bool public activated;

   
  constructor(ERC20 _token) public {
    token = _token;
  }

  modifier onlyCrowdsale() {
    require(msg.sender == crowdsale);
    _;
  }
  
  modifier onlyWhenActivated() {
    require(activated);
    _;
  }

  modifier onlyValidTokenTimelock(address _beneficiary, uint256 _id) {
    require(_beneficiary != address(0));
    require(_id < tokenTimeLocks[_beneficiary].length);
    require(!tokenTimeLocks[_beneficiary][_id].revoked);
    _;
  }

   
  function setCrowdsale(address _crowdsale) external onlyOwner {
    require(_crowdsale != address(0));
    crowdsale = _crowdsale;
  }

   
  function activate() external onlyCrowdsale {
    activated = true;
  }

   
  function createInvestorTokenTimeLock(
    address _beneficiary,
    uint256 _amount, 
    uint256 _start,
    address _tokenHolder
  ) external onlyCrowdsale returns (bool)
    {
    require(_beneficiary != address(0) && _amount > 0);
    require(_tokenHolder != address(0));

    TokenTimelock memory tokenLock = TokenTimelock(
      _amount,
      _start.add(INVESTOR_LOCK_DURATION),
      false,
      false,
      false
    );
    tokenTimeLocks[_beneficiary].push(tokenLock);
    require(token.transferFrom(_tokenHolder, this, _amount));
    
    emit TokenTimelockCreated(
      _beneficiary,
      tokenLock.releaseTime,
      false,
      _amount);
    return true;
  }

   
  function createTeamTokenTimeLock(
    address _beneficiary,
    uint256 _amount, 
    uint256 _start,
    address _tokenHolder
  ) external onlyOwner returns (bool)
    {
    require(_beneficiary != address(0) && _amount > 0);
    require(_tokenHolder != address(0));

    uint256 amount = _amount.div(2);
    TokenTimelock memory tokenLock1 = TokenTimelock(
      amount,
      _start.add(TEAM_LOCK_DURATION_PART1),
      false,
      true,
      false
    );
    tokenTimeLocks[_beneficiary].push(tokenLock1);

    TokenTimelock memory tokenLock2 = TokenTimelock(
      amount,
      _start.add(TEAM_LOCK_DURATION_PART2),
      false,
      true,
      false
    );
    tokenTimeLocks[_beneficiary].push(tokenLock2);

    require(token.transferFrom(_tokenHolder, this, _amount));
    
    emit TokenTimelockCreated(
      _beneficiary,
      tokenLock1.releaseTime,
      true,
      amount);
    emit TokenTimelockCreated(
      _beneficiary,
      tokenLock2.releaseTime,
      true,
      amount);
    return true;
  }

   
  function revokeTokenTimelock(
    address _beneficiary,
    uint256 _id) 
    external onlyWhenActivated onlyOwner onlyValidTokenTimelock(_beneficiary, _id)
  {
    require(tokenTimeLocks[_beneficiary][_id].revocable);
    require(!tokenTimeLocks[_beneficiary][_id].released);
    TokenTimelock storage tokenLock = tokenTimeLocks[_beneficiary][_id];
    tokenLock.revoked = true;
    require(token.transfer(owner, tokenLock.amount));
    emit TokenTimelockRevoked(_beneficiary);
  }

   
  function getTokenTimelockCount(address _beneficiary) view external returns (uint) {
    return tokenTimeLocks[_beneficiary].length;
  }

   
  function getTokenTimelockDetails(address _beneficiary, uint256 _id) view external returns (
    uint256 _amount,
    uint256 _releaseTime,
    bool _released,
    bool _revocable,
    bool _revoked) 
    {
    require(_id < tokenTimeLocks[_beneficiary].length);
    _amount = tokenTimeLocks[_beneficiary][_id].amount;
    _releaseTime = tokenTimeLocks[_beneficiary][_id].releaseTime;
    _released = tokenTimeLocks[_beneficiary][_id].released;
    _revocable = tokenTimeLocks[_beneficiary][_id].revocable;
    _revoked = tokenTimeLocks[_beneficiary][_id].revoked;
  }

   
  function changeBeneficiary(uint256 _id, address _newBeneficiary) external onlyWhenActivated onlyValidTokenTimelock(msg.sender, _id) {
    tokenTimeLocks[_newBeneficiary].push(tokenTimeLocks[msg.sender][_id]);
    if (tokenTimeLocks[msg.sender].length > 1) {
      tokenTimeLocks[msg.sender][_id] = tokenTimeLocks[msg.sender][tokenTimeLocks[msg.sender].length.sub(1)];
      delete(tokenTimeLocks[msg.sender][tokenTimeLocks[msg.sender].length.sub(1)]);
    }
    tokenTimeLocks[msg.sender].length--;
    emit TokenTimelockBeneficiaryChanged(msg.sender, _newBeneficiary);
  }

   
  function release(uint256 _id) external {
    releaseFor(msg.sender, _id);
  }

    
  function releaseFor(address _beneficiary, uint256 _id) public onlyWhenActivated onlyValidTokenTimelock(_beneficiary, _id) {
    TokenTimelock storage tokenLock = tokenTimeLocks[_beneficiary][_id];
    require(!tokenLock.released);
     
    require(block.timestamp >= tokenLock.releaseTime);
    tokenLock.released = true;
    require(token.transfer(_beneficiary, tokenLock.amount));
    emit TokenTimelockReleased(_beneficiary, tokenLock.amount);
  }
}