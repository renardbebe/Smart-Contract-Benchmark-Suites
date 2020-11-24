 

pragma solidity ^0.4.25;

 
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

  event OwnershipTransferred(
    address previousOwner,
    address newOwner
  );

   
  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == address(this));
    _;
  }

   
  constructor() public {
    owner = msg.sender;
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

 
contract Pausable is Ownable {
  event Pause(bool isPause);

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause(paused);
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Pause(paused);
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

 
contract BasicToken is ERC20Basic, Pausable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  uint256 totalSupply_;
  address public altTokenFundAddress;
  address public setPriceAccount;
  address public setReferralAccount;
  uint256 public tokenPrice;
  uint256 public managersFee;
  uint256 public referralFee;
  uint256 public supportFee;
  uint256 public withdrawFee;

  address public ethAddress;
  address public supportWallet;
  address public fundManagers;
  bool public lock;
  event Deposit(address indexed buyer, uint256 weiAmount, uint256 tokensAmount, uint256 tokenPrice, uint256 commission);
  event Withdraw(address indexed buyer, uint256 weiAmount, uint256 tokensAmount, uint256 tokenPrice, uint256 commission);


   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    if (_to == altTokenFundAddress) {
      require(!lock);
      uint256 weiAmount = _value.mul(uint256(100).sub(withdrawFee)).div(100).mul(tokenPrice).div(uint256(1000000000000000000));
      uint256 feeAmount = _value.mul(withdrawFee).div(100);

      totalSupply_ = totalSupply_.sub(_value-feeAmount);
      balances[fundManagers] = balances[fundManagers].add(feeAmount);
      emit Transfer(address(this), fundManagers, feeAmount);
      emit Withdraw(msg.sender, weiAmount, _value, tokenPrice, feeAmount);
    } else {
      balances[_to] = balances[_to].add(_value);
    }

    balances[msg.sender] = balances[msg.sender].sub(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    uint256 availableTokens = balances[_owner];
    return availableTokens;
  }
}

 
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    if (_to == altTokenFundAddress) {
      require(!lock);
      uint256 weiAmount = _value.mul(uint256(100).sub(withdrawFee)).div(100).mul(tokenPrice).div(uint256(1000000000000000000));
      uint256 feeAmount = _value.mul(withdrawFee).div(100);

      totalSupply_ = totalSupply_.sub(_value-feeAmount);
      balances[fundManagers] = balances[fundManagers].add(feeAmount);
      emit Transfer(address(this), fundManagers, feeAmount);
      emit Withdraw(msg.sender, weiAmount, _value, tokenPrice, withdrawFee);
    } else {
      balances[_to] = balances[_to].add(_value);
    }

    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract AltTokenFundToken is StandardToken {

  string constant public name = "Alt Token Fund Token";
  uint256 constant public decimals = 18;
  string constant public symbol = "ATF";
  mapping (address => address) public referrals;

  event Lock(bool lockStatus);
  event NewTokenPrice(uint256 tokenPrice);
  event AddTokens(address indexed user, uint256 tokensAmount, uint256 _price);

  event SupportFee(uint256 supportFee);
  event ManagersFee(uint256 managersFee);
  event ReferralFee(uint256 referralFee);
  event WithdrawFee(uint256 withdrawFee);

  event NewEthAddress(address ethAddress);
  event NewFundManagers(address fundManagers);
  event NewSupportWallet (address supportWallet);
  event NewSetPriceAccount (address setPriceAccount);
  event NewSetRefferalAccount (address referral);

  constructor() public {
    altTokenFundAddress = address(this);
     
    tokenPrice = 5041877658000000;
    lockUp(false);
    newManagersFee(1);
    newSupportFee(1);
    newReferralFee(3);
    newWithdrawFee(5);
    newEthAddress(0x8C5dA48233D4CC180c8f62617D4eF39040Bb2E2d);
    newFundManagers(0x3FacdA7A379F8bB21F2aAfDDc8fbe7231B538746);
    newSupportWallet(0x8C5dA48233D4CC180c8f62617D4eF39040Bb2E2d);
    newPriceAccount(0x9c8B73EB8B2668654e204E6B8292DE2Fc8DA2135);
    newReferralAccount(0x9c8B73EB8B2668654e204E6B8292DE2Fc8DA2135);
    
  }

   
  modifier onlySetPriceAccount {
      if (msg.sender != setPriceAccount) revert();
      _;
  }

  modifier onlySetReferralAccount {
      if (msg.sender != setReferralAccount) revert();
      _;
  }

  function priceOf() external view returns(uint256) {
    return tokenPrice;
  }

  function () payable external whenNotPaused {
    uint depositFee = managersFee.add(referralFee).add(supportFee);
    uint256 tokens = msg.value.mul(uint256(1000000000000000000)).mul(100-depositFee).div(uint256(100)).div(tokenPrice);


    totalSupply_ = totalSupply_.add(tokens);
    balances[msg.sender] = balances[msg.sender].add(tokens);

    fundManagers.transfer(msg.value.mul(managersFee).div(100));
    supportWallet.transfer(msg.value.mul(supportFee).div(100));
    if (referrals[msg.sender]!=0){
        referrals[msg.sender].transfer(msg.value.mul(referralFee).div(100));
    }
    else {
        supportWallet.transfer(msg.value.mul(referralFee).div(100));
    }
    
    ethAddress.transfer(msg.value.mul(uint256(100).sub(depositFee)).div(100));
    emit Transfer(altTokenFundAddress, msg.sender, tokens);
    emit Deposit(msg.sender, msg.value, tokens, tokenPrice, depositFee);
  }


  function airdrop(address[] receiver, uint256[] amount) external onlyOwner {
    require(receiver.length > 0 && receiver.length == amount.length);

    for(uint256 i = 0; i < receiver.length; i++) {
      uint256 tokens = amount[i];
      totalSupply_ = totalSupply_.add(tokens);
      balances[receiver[i]] = balances[receiver[i]].add(tokens);
      emit Transfer(address(this), receiver[i], tokens);
      emit AddTokens(receiver[i], tokens, tokenPrice);
    }
  }

  function setTokenPrice(uint256 _tokenPrice) public onlySetPriceAccount {
    tokenPrice = _tokenPrice;
    emit NewTokenPrice(tokenPrice);
  }
  
  function setReferral(address client, address referral)
        public
        onlySetReferralAccount
    {
        referrals[client] = referral;
    }

  function getReferral(address client)
        public
        constant
        returns (address)
    {
        return referrals[client];
    }

    function estimateTokens(uint256 valueInWei)
        public
        constant
        returns (uint256)
    {
        uint256 depositFee = managersFee.add(referralFee).add(supportFee);
        return valueInWei.mul(uint256(1000000000000000000)).mul(100-depositFee).div(uint256(100)).div(tokenPrice);
    }
    
    function estimateEthers(uint256 tokenCount)
        public
        constant
        returns (uint256)
    {
        uint256 weiAmount = tokenCount.mul(uint256(100).sub(withdrawFee)).div(100).mul(tokenPrice).div(uint256(1000000000000000000));
        return weiAmount;
    }

  function newSupportFee(uint256 _supportFee) public onlyOwner {
    supportFee = _supportFee;
    emit SupportFee(supportFee);
  }

  function newManagersFee(uint256 _managersFee) public onlyOwner {
    managersFee = _managersFee;
    emit ManagersFee(managersFee);
  }

  function newReferralFee(uint256 _referralFee) public onlyOwner {
    referralFee = _referralFee;
    emit ReferralFee(referralFee);
  }

  function newWithdrawFee(uint256 _newWithdrawFee) public onlyOwner {
    withdrawFee = _newWithdrawFee;
    emit WithdrawFee(withdrawFee);
  }

  function newEthAddress(address _ethAddress) public onlyOwner {
    ethAddress = _ethAddress;
    emit NewEthAddress(ethAddress);
  }

  function newFundManagers(address _fundManagers) public onlyOwner {
    fundManagers = _fundManagers;
    emit NewFundManagers(fundManagers);
  }
  
  function newSupportWallet(address _supportWallet) public onlyOwner {
    supportWallet = _supportWallet;
    emit NewSupportWallet(supportWallet);
  }
  
  function newPriceAccount(address _setPriceAccount) public onlyOwner {
    setPriceAccount = _setPriceAccount;
    emit NewSetPriceAccount(setPriceAccount);
  }
  
  function newReferralAccount(address _setReferralAccount) public onlyOwner {
    setReferralAccount = _setReferralAccount;
    emit NewSetRefferalAccount(setReferralAccount);
  }

  function lockUp(bool _lock) public onlyOwner {
    lock = _lock;
    emit Lock(lock);
  }
}