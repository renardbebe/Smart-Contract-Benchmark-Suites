 

pragma solidity ^0.4.24;


 
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


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}


 
contract Locker is Ownable {
  using SafeMath for uint;
  using SafeERC20 for ERC20Basic;

   
  enum State { Init, Ready, Active, Drawn }

  struct Beneficiary {
    uint ratio;              
    uint withdrawAmount;     
    bool releaseAllTokens;
  }

   
  struct Release {
    bool isStraight;         
    uint[] releaseTimes;     
    uint[] releaseRatios;    
  }

  uint public activeTime;

   
  ERC20Basic public token;

  uint public coeff;
  uint public initialBalance;
  uint public withdrawAmount;  

  mapping (address => Beneficiary) public beneficiaries;
  mapping (address => Release) public releases;   
  mapping (address => bool) public locked;  

  uint public numBeneficiaries;
  uint public numLocks;

  State public state;

  modifier onlyState(State v) {
    require(state == v);
    _;
  }

  modifier onlyBeneficiary(address _addr) {
    require(beneficiaries[_addr].ratio > 0);
    _;
  }

  event StateChanged(State _state);
  event Locked(address indexed _beneficiary, bool _isStraight);
  event Released(address indexed _beneficiary, uint256 _amount);

  function Locker(address _token, uint _coeff, address[] _beneficiaries, uint[] _ratios) public {
    require(_token != address(0));
    require(_beneficiaries.length == _ratios.length);

    token = ERC20Basic(_token);
    coeff = _coeff;
    numBeneficiaries = _beneficiaries.length;

    uint accRatio;

    for(uint i = 0; i < numBeneficiaries; i++) {
      require(_ratios[i] > 0);
      beneficiaries[_beneficiaries[i]].ratio = _ratios[i];

      accRatio = accRatio.add(_ratios[i]);
    }

    require(coeff == accRatio);
  }

   
  function activate() external onlyOwner onlyState(State.Ready) {
    require(numLocks == numBeneficiaries);  

    initialBalance = token.balanceOf(this);
    require(initialBalance > 0);

    activeTime = now;  

     
    state = State.Active;
    emit StateChanged(state);
  }

  function getReleaseType(address _beneficiary)
    public
    view
    onlyBeneficiary(_beneficiary)
    returns (bool)
  {
    return releases[_beneficiary].isStraight;
  }

  function getTotalLockedAmounts(address _beneficiary)
    public
    view
    onlyBeneficiary(_beneficiary)
    returns (uint)
  {
    return getPartialAmount(beneficiaries[_beneficiary].ratio, coeff, initialBalance);
  }

  function getReleaseTimes(address _beneficiary)
    public
    view
    onlyBeneficiary(_beneficiary)
    returns (uint[])
  {
    return releases[_beneficiary].releaseTimes;
  }

  function getReleaseRatios(address _beneficiary)
    public
    view
    onlyBeneficiary(_beneficiary)
    returns (uint[])
  {
    return releases[_beneficiary].releaseRatios;
  }

   
  function lock(address _beneficiary, bool _isStraight, uint[] _releaseTimes, uint[] _releaseRatios)
    external
    onlyOwner
    onlyState(State.Init)
    onlyBeneficiary(_beneficiary)
  {
    require(!locked[_beneficiary]);
    require(_releaseRatios.length != 0);
    require(_releaseRatios.length == _releaseTimes.length);

    uint i;
    uint len = _releaseRatios.length;

     
    require(_releaseRatios[len - 1] == coeff);

     
    for(i = 0; i < len - 1; i++) {
      require(_releaseTimes[i] < _releaseTimes[i + 1]);
      require(_releaseRatios[i] < _releaseRatios[i + 1]);
    }

     
    if (_isStraight) {
      require(len == 2);
    }

    numLocks = numLocks.add(1);

     
    releases[_beneficiary].isStraight = _isStraight;

     
    releases[_beneficiary].releaseTimes = _releaseTimes;
    releases[_beneficiary].releaseRatios = _releaseRatios;

     
    locked[_beneficiary] = true;
    emit Locked(_beneficiary, _isStraight);

     
    if (numLocks == numBeneficiaries) {
      state = State.Ready;
      emit StateChanged(state);
    }
  }

   
  function release() external onlyState(State.Active) onlyBeneficiary(msg.sender) {
    require(!beneficiaries[msg.sender].releaseAllTokens);

    uint releasableAmount = getReleasableAmount(msg.sender);
    beneficiaries[msg.sender].withdrawAmount = beneficiaries[msg.sender].withdrawAmount.add(releasableAmount);

    beneficiaries[msg.sender].releaseAllTokens = beneficiaries[msg.sender].withdrawAmount == getPartialAmount(
      beneficiaries[msg.sender].ratio,
      coeff,
      initialBalance);

    withdrawAmount = withdrawAmount.add(releasableAmount);

    if (withdrawAmount == initialBalance) {
      state = State.Drawn;
      emit StateChanged(state);
    }

    token.transfer(msg.sender, releasableAmount);
    emit Released(msg.sender, releasableAmount);
  }

  function getReleasableAmount(address _beneficiary) internal view returns (uint) {
    if (releases[_beneficiary].isStraight) {
      return getStraightReleasableAmount(_beneficiary);
    } else {
      return getVariableReleasableAmount(_beneficiary);
    }
  }

   
  function getStraightReleasableAmount(address _beneficiary) internal view returns (uint releasableAmount) {
    Beneficiary memory _b = beneficiaries[_beneficiary];
    Release memory _r = releases[_beneficiary];

     
    uint totalReleasableAmount = getTotalLockedAmounts(_beneficiary);

    uint firstTime = _r.releaseTimes[0];
    uint lastTime = _r.releaseTimes[1];

     
    require(now >= firstTime);  
     

    if(now >= lastTime) {  
      releasableAmount = totalReleasableAmount;
    } else {
       
      uint firstAmount = getPartialAmount(
        _r.releaseRatios[0],
        coeff,
        totalReleasableAmount);

       
      releasableAmount = getPartialAmount(
        now.sub(firstTime),
        lastTime.sub(firstTime),
        totalReleasableAmount.sub(firstAmount));
      releasableAmount = releasableAmount.add(firstAmount);
    }

     
    releasableAmount = releasableAmount.sub(_b.withdrawAmount);
  }

   
  function getVariableReleasableAmount(address _beneficiary) internal view returns (uint releasableAmount) {
    Beneficiary memory _b = beneficiaries[_beneficiary];
    Release memory _r = releases[_beneficiary];

     
    uint totalReleasableAmount = getTotalLockedAmounts(_beneficiary);

    uint releaseRatio;

     
    for(uint i = _r.releaseTimes.length - 1; i >= 0; i--) {
      if (now >= _r.releaseTimes[i]) {
        releaseRatio = _r.releaseRatios[i];
        break;
      }
    }

    require(releaseRatio > 0);

    releasableAmount = getPartialAmount(
      releaseRatio,
      coeff,
      totalReleasableAmount);
    releasableAmount = releasableAmount.sub(_b.withdrawAmount);
  }

   
   
   
   
   
   
  function getPartialAmount(uint numerator, uint denominator, uint target) public pure returns (uint) {
    return numerator.mul(target).div(denominator);
  }
}