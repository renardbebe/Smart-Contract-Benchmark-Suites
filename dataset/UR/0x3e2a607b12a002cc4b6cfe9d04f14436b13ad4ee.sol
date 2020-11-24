 

pragma solidity ^0.4.23;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract TalaoMarketplace is Ownable {
  using SafeMath for uint256;

  TalaoToken public token;

  struct MarketplaceData {
    uint buyPrice;
    uint sellPrice;
    uint unitPrice;
  }

  MarketplaceData public marketplace;

  event SellingPrice(uint sellingPrice);
  event TalaoBought(address buyer, uint amount, uint price, uint unitPrice);
  event TalaoSold(address seller, uint amount, uint price, uint unitPrice);

   
  constructor(address talao)
      public
  {
      token = TalaoToken(talao);
  }

   
  function setPrices(uint256 newSellPrice, uint256 newBuyPrice, uint256 newUnitPrice)
      public
      onlyOwner
  {
      require (newSellPrice > 0 && newBuyPrice > 0 && newUnitPrice > 0, "wrong inputs");
      marketplace.sellPrice = newSellPrice;
      marketplace.buyPrice = newBuyPrice;
      marketplace.unitPrice = newUnitPrice;
  }

   
  function buy()
      public
      payable
      returns (uint amount)
  {
      amount = msg.value.mul(marketplace.unitPrice).div(marketplace.buyPrice);
      token.transfer(msg.sender, amount);
      emit TalaoBought(msg.sender, amount, marketplace.buyPrice, marketplace.unitPrice);
      return amount;
  }

   
  function sell(uint amount)
      public
      returns (uint revenue)
  {
      require(token.balanceOf(msg.sender) >= amount, "sender has not enough tokens");
      token.transferFrom(msg.sender, this, amount);
      revenue = amount.mul(marketplace.sellPrice).div(marketplace.unitPrice);
      msg.sender.transfer(revenue);
      emit TalaoSold(msg.sender, amount, marketplace.sellPrice, marketplace.unitPrice);
      return revenue;
  }

   
  function withdrawEther(uint256 ethers)
      public
      onlyOwner
  {
      if (this.balance >= ethers) {
          msg.sender.transfer(ethers);
      }
  }

   
  function withdrawTalao(uint256 tokens)
      public
      onlyOwner
  {
      token.transfer(msg.sender, tokens);
  }


   
  function ()
      public
      payable
      onlyOwner
  {

  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);

    token.safeTransfer(beneficiary, amount);
  }
}


 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function Crowdsale(uint256 _rate, uint256 _startTime, uint256 _endTime, address _wallet) public {
    require(_rate > 0);
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
   
  function validPurchase() internal returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}


 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}


 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}



 
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  RefundVault public vault;

  function RefundableCrowdsale(uint256 _goal) public {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

}


 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
   
  function validPurchase() internal returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

 
contract ProgressiveIndividualCappedCrowdsale is RefundableCrowdsale, CappedCrowdsale {

    uint public startGeneralSale;
    uint public constant TIME_PERIOD_IN_SEC = 1 days;
    uint public constant minimumParticipation = 10 finney;
    uint public constant GAS_LIMIT_IN_WEI = 5E10 wei;  
    uint256 public baseEthCapPerAddress;

    mapping(address=>uint) public participated;

    function ProgressiveIndividualCappedCrowdsale(uint _baseEthCapPerAddress, uint _startGeneralSale)
        public
    {
        baseEthCapPerAddress = _baseEthCapPerAddress;
        startGeneralSale = _startGeneralSale;
    }

     
    function setBaseCap(uint _newBaseCap)
        public
        onlyOwner
    {
        require(now < startGeneralSale);
        baseEthCapPerAddress = _newBaseCap;
    }

     
    function validPurchase()
        internal
        returns(bool)
    {
        bool gasCheck = tx.gasprice <= GAS_LIMIT_IN_WEI;
        uint ethCapPerAddress = getCurrentEthCapPerAddress();
        participated[msg.sender] = participated[msg.sender].add(msg.value);
        bool enough = participated[msg.sender] >= minimumParticipation;
        return participated[msg.sender] <= ethCapPerAddress && enough && gasCheck;
    }

     
    function getCurrentEthCapPerAddress()
        public
        constant
        returns(uint)
    {
        if (block.timestamp < startGeneralSale) return 0;
        uint timeSinceStartInSec = block.timestamp.sub(startGeneralSale);
        uint currentPeriod = timeSinceStartInSec.div(TIME_PERIOD_IN_SEC).add(1);

         
        return (2 ** currentPeriod.sub(1)).mul(baseEthCapPerAddress);
    }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

 
contract TalaoToken is MintableToken {
  using SafeMath for uint256;

   
  string public constant name = "Talao";
  string public constant symbol = "TALAO";
  uint8 public constant decimals = 18;

   
  address public marketplace;

   
  uint256 public vaultDeposit;
   
  uint256 public totalDeposit;

  struct FreelanceData {
       
      uint256 accessPrice;
       
      address appointedAgent;
       
      uint sharingPlan;
       
      uint256 userDeposit;
  }

   
  struct ClientAccess {
       
      bool clientAgreement;
       
      uint clientDate;
  }

   
  mapping (address => mapping (address => ClientAccess)) public accessAllowance;

   
  mapping (address=>FreelanceData) public data;

  enum VaultStatus {Closed, Created, PriceTooHigh, NotEnoughTokensDeposited, AgentRemoved, NewAgent, NewAccess, WrongAccessPrice}

   
   
   
   
   
   
   
   
   
  event Vault(address indexed client, address indexed freelance, VaultStatus status);

  modifier onlyMintingFinished()
  {
      require(mintingFinished == true, "minting has not finished");
      _;
  }

   
  function setMarketplace(address theMarketplace)
      public
      onlyMintingFinished
      onlyOwner
  {
      marketplace = theMarketplace;
  }

   
  function approve(address _spender, uint256 _value)
      public
      onlyMintingFinished
      returns (bool)
  {
      return super.approve(_spender, _value);
  }

   
  function transfer(address _to, uint256 _value)
      public
      onlyMintingFinished
      returns (bool result)
  {
      return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value)
      public
      onlyMintingFinished
      returns (bool)
  {
      return super.transferFrom(_from, _to, _value);
  }

   
  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
      public
      onlyMintingFinished
      returns (bool)
  {
      tokenRecipient spender = tokenRecipient(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value, this, _extraData);
          return true;
      }
  }

   
  function withdrawEther(uint256 ethers)
      public
      onlyOwner
  {
      msg.sender.transfer(ethers);
  }

   
  function withdrawTalao(uint256 tokens)
      public
      onlyOwner
  {
      require(balanceOf(this).sub(totalDeposit) >= tokens, "too much tokens asked");
      _transfer(this, msg.sender, tokens);
  }

   
   
   

   
  function createVaultAccess (uint256 price)
      public
      onlyMintingFinished
  {
      require(accessAllowance[msg.sender][msg.sender].clientAgreement==false, "vault already created");
      require(price<=vaultDeposit, "price asked is too high");
      require(balanceOf(msg.sender)>vaultDeposit, "user has not enough tokens to send deposit");
      data[msg.sender].accessPrice=price;
      super.transfer(this, vaultDeposit);
      totalDeposit = totalDeposit.add(vaultDeposit);
      data[msg.sender].userDeposit=vaultDeposit;
      data[msg.sender].sharingPlan=100;
      accessAllowance[msg.sender][msg.sender].clientAgreement=true;
      emit Vault(msg.sender, msg.sender, VaultStatus.Created);
  }

   
  function closeVaultAccess()
      public
      onlyMintingFinished
  {
      require(accessAllowance[msg.sender][msg.sender].clientAgreement==true, "vault has not been created");
      require(_transfer(this, msg.sender, data[msg.sender].userDeposit), "token deposit transfer failed");
      accessAllowance[msg.sender][msg.sender].clientAgreement=false;
      totalDeposit=totalDeposit.sub(data[msg.sender].userDeposit);
      data[msg.sender].sharingPlan=0;
      emit Vault(msg.sender, msg.sender, VaultStatus.Closed);
  }

   
  function _transfer(address _from, address _to, uint _value)
      internal
      returns (bool)
  {
      require(_to != 0x0, "destination cannot be 0x0");
      require(balances[_from] >= _value, "not enough tokens in sender wallet");

      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      emit Transfer(_from, _to, _value);
      return true;
  }

   
  function agentApproval (address newagent, uint newplan)
      public
      onlyMintingFinished
  {
      require(newplan>=0&&newplan<=100, "plan must be between 0 and 100");
      require(accessAllowance[msg.sender][msg.sender].clientAgreement==true, "vault has not been created");
      emit Vault(data[msg.sender].appointedAgent, msg.sender, VaultStatus.AgentRemoved);
      data[msg.sender].appointedAgent=newagent;
      data[msg.sender].sharingPlan=newplan;
      emit Vault(newagent, msg.sender, VaultStatus.NewAgent);
  }

   
  function setVaultDeposit (uint newdeposit)
      public
      onlyOwner
  {
      vaultDeposit = newdeposit;
  }

   
  function getVaultAccess (address freelance)
      public
      onlyMintingFinished
      returns (bool)
  {
      require(accessAllowance[freelance][freelance].clientAgreement==true, "vault does not exist");
      require(accessAllowance[msg.sender][freelance].clientAgreement!=true, "access was already granted");
      require(balanceOf(msg.sender)>data[freelance].accessPrice, "user has not enough tokens to get access to vault");

      uint256 freelance_share = data[freelance].accessPrice.mul(data[freelance].sharingPlan).div(100);
      uint256 agent_share = data[freelance].accessPrice.sub(freelance_share);
      if(freelance_share>0) super.transfer(freelance, freelance_share);
      if(agent_share>0) super.transfer(data[freelance].appointedAgent, agent_share);
      accessAllowance[msg.sender][freelance].clientAgreement=true;
      accessAllowance[msg.sender][freelance].clientDate=block.number;
      emit Vault(msg.sender, freelance, VaultStatus.NewAccess);
      return true;
  }

   
  function getFreelanceAgent(address freelance)
      public
      view
      returns (address)
  {
      return data[freelance].appointedAgent;
  }

   
  function hasVaultAccess(address freelance, address user)
      public
      view
      returns (bool)
  {
      return ((accessAllowance[user][freelance].clientAgreement) || (data[freelance].appointedAgent == user));
  }

}



 
contract TalaoCrowdsale is ProgressiveIndividualCappedCrowdsale {
  using SafeMath for uint256;

  uint256 public weiRaisedPreSale;
  uint256 public presaleCap;
  uint256 public startGeneralSale;

  mapping (address => uint256) public presaleParticipation;
  mapping (address => uint256) public presaleIndividualCap;

  uint256 public constant generalRate = 1000;
  uint256 public constant presaleBonus = 250;
  uint256 public constant presaleBonusTier2 = 150;
  uint256 public constant presaleBonusTier3 = 100;
  uint256 public constant presaleBonusTier4 = 50;

  uint256 public dateOfBonusRelease;

  address public constant reserveWallet = 0xC9a2BE82Ba706369730BDbd64280bc1132347F85;
  address public constant futureRoundWallet = 0x80a27A56C29b83b25492c06b39AC049e8719a8fd;
  address public constant advisorsWallet = 0xC9a2BE82Ba706369730BDbd64280bc1132347F85;
  address public constant foundersWallet1 = 0x76934C75Ef9a02D444fa9d337C56c7ab0094154C;
  address public constant foundersWallet2 = 0xd21aF5665Dc81563328d5cA2f984b4f6281c333f;
  address public constant foundersWallet3 = 0x0DceD36d883752203E01441bD006725Acd128049;
  address public constant shareholdersWallet = 0x554bC53533876fC501b230274F47598cbD435B5E;

  uint256 public constant cliffTeamTokensRelease = 3 years;
  uint256 public constant lockTeamTokens = 4 years;
  uint256 public constant cliffAdvisorsTokens = 1 years;
  uint256 public constant lockAdvisorsTokens = 2 years;
  uint256 public constant futureRoundTokensRelease = 1 years;
  uint256 public constant presaleBonusLock = 90 days;
  uint256 public constant presaleParticipationMinimum = 10 ether;

   
  uint256 public constant dateTier2 = 1528761600;  
   
  uint256 public constant dateTier3 = 1529366400;  
   
  uint256 public constant dateTier4 = 1529971200;  

  uint256 public baseEthCapPerAddress = 3 ether;

  mapping (address => address) public timelockedTokensContracts;

  mapping (address => bool) public whiteListedAddress;
  mapping (address => bool) public whiteListedAddressPresale;

   
  constructor(uint256 _startDate, uint256 _startGeneralSale, uint256 _endDate,
                          uint256 _goal, uint256 _presaleCap, uint256 _cap,
                          address _wallet)
      public
      CappedCrowdsale(_cap)
      FinalizableCrowdsale()
      RefundableCrowdsale(_goal)
      Crowdsale(generalRate, _startDate, _endDate, _wallet)
      ProgressiveIndividualCappedCrowdsale(baseEthCapPerAddress, _startGeneralSale)
  {
      require(_goal <= _cap, "goal is superior to cap");
      require(_startGeneralSale > _startDate, "general sale is starting before presale");
      require(_endDate > _startGeneralSale, "sale ends before general start");
      require(_presaleCap > 0, "presale cap is inferior or equal to 0");
      require(_presaleCap <= _cap, "presale cap is superior to sale cap");

      startGeneralSale = _startGeneralSale;
      presaleCap = _presaleCap;
      dateOfBonusRelease = endTime.add(presaleBonusLock);
  }

   
  function createTokenContract()
      internal
      returns (MintableToken)
  {
      return new TalaoToken();
  }

   
  modifier onlyPresaleWhitelisted()
  {
      require(isWhitelistedPresale(msg.sender), "address is not whitelisted for presale");
      _;
  }

   
  modifier onlyWhitelisted()
  {
      require(isWhitelisted(msg.sender) || isWhitelistedPresale(msg.sender),
              "address is not whitelisted for sale");
      _;
  }

   
  function whitelistAddresses(address[] _users)
      public
      onlyOwner
  {
      for(uint i = 0 ; i < _users.length ; i++) {
        whiteListedAddress[_users[i]] = true;
      }
  }

   
  function unwhitelistAddress(address _user)
      public
      onlyOwner
  {
      whiteListedAddress[_user] = false;
  }

   
  function whitelistAddressPresale(address _user, uint _cap)
      public
      onlyOwner
  {
      require(_cap > presaleParticipation[_user], "address has reached participation cap");
      whiteListedAddressPresale[_user] = true;
      presaleIndividualCap[_user] = _cap;
  }

   
  function unwhitelistAddressPresale(address _user)
      public
      onlyOwner
  {
      whiteListedAddressPresale[_user] = false;
  }

   
  function buyTokens(address beneficiary)
      public
      payable
      onlyWhitelisted
  {
      require(beneficiary != 0x0, "beneficiary cannot be 0x0");
      require(validPurchase(), "purchase is not valid");

      uint256 weiAmount = msg.value;
      uint256 tokens = weiAmount.mul(generalRate);
      weiRaised = weiRaised.add(weiAmount);

      token.mint(beneficiary, tokens);
      emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
      forwardFunds();
  }

   
  function buyTokensPresale(address beneficiary)
      public
      payable
      onlyPresaleWhitelisted
  {
      require(beneficiary != 0x0, "beneficiary cannot be 0x0");
      require(validPurchasePresale(), "presale purchase is not valid");

       
      uint256 weiAmount = msg.value;
      uint256 tokens = weiAmount.mul(generalRate);

       
       
      if(timelockedTokensContracts[beneficiary] == 0) {
        timelockedTokensContracts[beneficiary] = new TokenTimelock(token, beneficiary, dateOfBonusRelease);
      }

       
      uint256 timelockedTokens = preSaleBonus(weiAmount);
      weiRaisedPreSale = weiRaisedPreSale.add(weiAmount);

      token.mint(beneficiary, tokens);
      token.mint(timelockedTokensContracts[beneficiary], timelockedTokens);
      emit TokenPurchase(msg.sender, beneficiary, weiAmount, (tokens.add(timelockedTokens)));
      forwardFunds();
  }

   
  function finalization()
      internal
  {
      if (goalReached()) {
         
        timelockedTokensContracts[advisorsWallet] = new TokenVesting(advisorsWallet, now, cliffAdvisorsTokens, lockAdvisorsTokens, false);

         
        timelockedTokensContracts[foundersWallet1] = new TokenVesting(foundersWallet1, now, cliffTeamTokensRelease, lockTeamTokens, false);
        timelockedTokensContracts[foundersWallet2] = new TokenVesting(foundersWallet2, now, cliffTeamTokensRelease, lockTeamTokens, false);
        timelockedTokensContracts[foundersWallet3] = new TokenVesting(foundersWallet3, now, cliffTeamTokensRelease, lockTeamTokens, false);

         
        uint dateOfFutureRoundRelease = now.add(futureRoundTokensRelease);
        timelockedTokensContracts[futureRoundWallet] = new TokenTimelock(token, futureRoundWallet, dateOfFutureRoundRelease);

        token.mint(timelockedTokensContracts[advisorsWallet], 3000000000000000000000000);
        token.mint(timelockedTokensContracts[foundersWallet1], 4000000000000000000000000);
        token.mint(timelockedTokensContracts[foundersWallet2], 4000000000000000000000000);
        token.mint(timelockedTokensContracts[foundersWallet3], 4000000000000000000000000);

         
        token.mint(shareholdersWallet, 6000000000000000000000000);
         
        token.mint(reserveWallet, 29000000000000000000000000);

        uint256 totalSupply = token.totalSupply();
        uint256 maxSupply = 150000000000000000000000000;
        uint256 toMint = maxSupply.sub(totalSupply);
        token.mint(timelockedTokensContracts[futureRoundWallet], toMint);
        token.finishMinting();
         
        TalaoToken talao = TalaoToken(address(token));
        TalaoMarketplace marketplace = new TalaoMarketplace(address(token));
        talao.setMarketplace(address(marketplace));
        marketplace.transferOwnership(owner);

         
        token.transferOwnership(owner);
      }
       
      super.finalization();
  }

   
  function ()
      external
      payable
  {
      if (now >= startTime && now < startGeneralSale){
        buyTokensPresale(msg.sender);
      } else {
        buyTokens(msg.sender);
      }
  }

   
  function validPurchase()
      internal
      returns (bool)
  {
      bool withinPeriod = now >= startGeneralSale && now <= endTime;
      bool nonZeroPurchase = msg.value != 0;
      uint256 totalWeiRaised = weiRaisedPreSale.add(weiRaised);
      bool withinCap = totalWeiRaised.add(msg.value) <= cap;
      return withinCap && withinPeriod && nonZeroPurchase && super.validPurchase();
  }

   
  function validPurchasePresale()
      internal
      returns (bool)
  {
      presaleParticipation[msg.sender] = presaleParticipation[msg.sender].add(msg.value);
      bool enough = presaleParticipation[msg.sender] >= presaleParticipationMinimum;
      bool notTooMuch = presaleIndividualCap[msg.sender] >= presaleParticipation[msg.sender];
      bool withinPeriod = now >= startTime && now < startGeneralSale;
      bool nonZeroPurchase = msg.value != 0;
      bool withinCap = weiRaisedPreSale.add(msg.value) <= presaleCap;
      return withinPeriod && nonZeroPurchase && withinCap && enough && notTooMuch;
  }

  function preSaleBonus(uint amount)
      internal
      returns (uint)
  {
      if(now < dateTier2) {
        return amount.mul(presaleBonus);
      } else if (now < dateTier3) {
        return amount.mul(presaleBonusTier2);
      } else if (now < dateTier4) {
        return amount.mul(presaleBonusTier3);
      } else {
        return amount.mul(presaleBonusTier4);
      }
  }

   
  function goalReached()
      public
      constant
      returns (bool)
  {
      uint256 totalWeiRaised = weiRaisedPreSale.add(weiRaised);
      return totalWeiRaised >= goal || super.goalReached();
  }

   
  function isWhitelisted(address _user)
      public
      constant
      returns (bool)
  {
      return whiteListedAddress[_user];
  }

   
  function isWhitelistedPresale(address _user)
      public
      constant
      returns (bool)
  {
      return whiteListedAddressPresale[_user];
  }

}