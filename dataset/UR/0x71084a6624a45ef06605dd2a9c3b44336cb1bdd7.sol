 

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
  address public contractAddress;
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
  event Deposit(address indexed buyer, uint256 weiAmount, uint256 tokensAmount, uint256 tokenPrice, address referral, uint256 referralFee, uint256 managersFee, uint256 supportFee);
  event Withdraw(address indexed buyer, uint256 tokensAmount, uint256 tokenPrice, uint256 commission);

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    if (_to == contractAddress) {
      emit Withdraw(msg.sender, _value, tokenPrice, withdrawFee);
    }
    
    balances[_to] = balances[_to].add(_value);
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

    if (_to == contractAddress) {
      emit Withdraw(msg.sender, _value, tokenPrice, withdrawFee);
    }
    
    balances[_to] = balances[_to].add(_value);
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

contract CrescoFinanceToken is StandardToken {

  string constant public name = "CrescoFinanceToken";
  uint256 constant public decimals = 4;
  string constant public symbol = "CFT";
  mapping (address => address) public referrals;

  event NewTokenPrice(uint256 tokenPrice);
  event AddTokens(address indexed user, uint256 tokensAmount, uint256 _price);
  event DeleteTokens(address indexed user, uint256 tokensAmount, uint256 tokenPrice);
  event SupportFee(uint256 supportFee);
  event ManagersFee(uint256 managersFee);
  event ReferralFee(uint256 referralFee);
  event WithdrawFee(uint256 withdrawFee);
  event PaymentDone(address _user, uint256 ethAmount, uint256 tokenPrice, uint256 tokenBurned, uint256 successFee, uint256 withdrawFee);

  event NewEthAddress(address ethAddress);
  event NewFundManagers(address fundManagers);
  event NewSupportWallet (address supportWallet);
  event NewSetPriceAccount (address setPriceAccount);
  event NewSetRefferalAccount (address referral);

  constructor() public {
    contractAddress = address(this);
    tokenPrice = 5041877658000000;
    newManagersFee(0);
    newSupportFee(0);
    newReferralFee(0);
    newWithdrawFee(0);
    newEthAddress(0x3075fc666FA2c3667083aF9bCEa9C62467dE6C78);
    newFundManagers(0xE72484208B359AD2AB9b31e454BfeFB81f922DB5);
    newSupportWallet(0x18DD6bE30CdE8E753a25dc139F29463f040B0A76);
    newPriceAccount(0xAA50E4651572a9c655e014C567596Cc4c79Fb909);
    newReferralAccount(0xAA50E4651572a9c655e014C567596Cc4c79Fb909);
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
    uint256 tokens = msg.value.mul(uint256(10000)).mul(100-depositFee).div(uint256(100)).div(tokenPrice);

    totalSupply_ = totalSupply_.add(tokens);
    balances[msg.sender] = balances[msg.sender].add(tokens);

    fundManagers.transfer(msg.value.mul(managersFee).div(100));
    supportWallet.transfer(msg.value.mul(supportFee).div(100));
    if (referrals[msg.sender]!=0){
        referrals[msg.sender].transfer(msg.value.mul(referralFee).div(100));
    }
    else {
        fundManagers.transfer(msg.value.mul(referralFee).div(100));
    }
    
    ethAddress.transfer(msg.value.mul(uint256(100).sub(depositFee)).div(100));
    emit Deposit(msg.sender, msg.value, tokens, tokenPrice, referrals[msg.sender], referralFee, managersFee, supportFee);
    emit Transfer(contractAddress, msg.sender, tokens);
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
  
  function deleteInvestorTokens(address[] user, uint256[] amount) external onlyOwner {
    require(user.length > 0 && user.length == amount.length);
    
    for(uint256 i = 0; i < user.length; i++) {
      uint256 tokens = amount[i];
      require(tokens <= balances[user[i]]);
      totalSupply_ = totalSupply_.sub(tokens);
      balances[user[i]] = balances[user[i]].sub(tokens);
      emit Transfer(user[i], address(this), tokens);
      emit DeleteTokens(user[i], tokens, tokenPrice);
    }
  }
  
  function manualDeposit(address investor, uint256 weiAmount) external onlyOwner{
    uint depositFee = managersFee.add(referralFee).add(supportFee);
    uint256 tokens = weiAmount.mul(uint256(10000)).mul(100-depositFee).div(uint256(100)).div(tokenPrice);

    totalSupply_ = totalSupply_.add(tokens);
    balances[investor] = balances[investor].add(tokens);
    
    emit Deposit(investor, weiAmount, tokens, tokenPrice, referrals[investor], referralFee, managersFee, supportFee);
    emit Transfer(contractAddress, investor, tokens);
  }
 
  
  function takeSuccessFee(address[] user, uint256[] amount) external onlyOwner{
    require(user.length > 0 && user.length == amount.length);
    
    for(uint256 i = 0; i < user.length; i++) {
      uint256 tokens = amount[i];
      require(tokens <= balances[user[i]]);
      balances[user[i]] = balances[user[i]].sub(tokens);
      balances[fundManagers] = balances[fundManagers].add(tokens);
      emit Transfer(user[i], address(fundManagers), tokens);
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
        return valueInWei.mul(uint256(10000)).mul(100-depositFee).div(uint256(100)).div(tokenPrice);
    }
    
    function estimateEthers(uint256 tokenCount)
        public
        constant
        returns (uint256)
    {
        uint256 weiAmount = tokenCount.mul(uint256(100).sub(withdrawFee)).div(100).mul(tokenPrice).div(uint256(10000));
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

}