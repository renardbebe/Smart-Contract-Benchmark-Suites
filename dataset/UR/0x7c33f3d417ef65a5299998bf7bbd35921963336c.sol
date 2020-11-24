 

 
 
 pragma solidity ^0.4.18;


 


 


 
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
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}
 
 

 


 


 
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
 


 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
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

   
  function validPurchase() internal view returns (bool) {
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

   
  function finalize() onlyOwner public {
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
 


 
contract FNTRefundableCrowdsale is RefundableCrowdsale {

   
  bool public vaultClosed = false;

   
  function closeVault() public onlyOwner {
    require(!vaultClosed);
    require(goalReached());
    vault.close();
    vaultClosed = true;
  }

   
   
   
   
  function forwardFunds() internal {
    if (!vaultClosed) {
      vault.deposit.value(msg.value)(msg.sender);
    } else {
      wallet.transfer(msg.value);
    }
  }

   
  function finalization() internal {
    if (!vaultClosed && goalReached()) {
      vault.close();
      vaultClosed = true;
    } else if (!goalReached()) {
      vault.enableRefunds();
    }
  }
}
 
 


 



 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}
 
 


 





 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
 

 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}
 

 
contract FNTToken is BurnableToken, MintableToken, PausableToken {
   
  string public constant NAME = "Friend Network Token";

   
  string public constant SYMBOL = "FRND";

   
  uint8 public constant DECIMALS = 18;

}
 

 
contract FNTCrowdsale is FNTRefundableCrowdsale {

  uint256 public maxICOSupply;

  uint256 public maxTotalSupply;

  uint256 public minFunding;

  uint256 public mediumFunding;

  uint256 public highFunding;

  uint256 public presaleWei;

  address public teamAddress;

  address public FSNASAddress;

  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);
  event VestedTeamTokens(address first, address second, address thrid, address fourth);

   
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

   
  function FNTCrowdsale(
    uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _minFunding,
    uint256 _mediumFunding, uint256 _highFunding, address _wallet,
    uint256 _maxTotalSupply, address _teamAddress, address _FSNASAddress
  ) public
    RefundableCrowdsale(_minFunding)
    Crowdsale(_startTime, _endTime, _rate, _wallet)
  {
    require(_maxTotalSupply > 0);
    require(_minFunding > 0);
    require(_mediumFunding > _minFunding);
    require(_highFunding > _mediumFunding);
    require(_teamAddress != address(0));
    require(_FSNASAddress != address(0));
    minFunding = _minFunding;
    mediumFunding = _mediumFunding;
    highFunding = _highFunding;
    maxTotalSupply = _maxTotalSupply;
    maxICOSupply = maxTotalSupply.mul(82).div(100);
    teamAddress = _teamAddress;
    FSNASAddress = _FSNASAddress;
    FNTToken(token).pause();
  }

   
  function createTokenContract() internal returns (MintableToken) {
    return new FNTToken();
  }

   
  function buyTokens(address beneficiary) public onlyWhitelisted payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = 0;
    if (weiRaised < minFunding) {

       
      if (weiRaised.add(weiAmount) > highFunding) {
        tokens = minFunding.sub(weiRaised)
          .mul(rate).mul(115).div(100);
        tokens = tokens.add(
          mediumFunding.sub(minFunding).mul(rate).mul(110).div(100)
        );
        tokens = tokens.add(
          highFunding.sub(mediumFunding).mul(rate).mul(105).div(100)
        );
        tokens = tokens.add(
          weiRaised.add(weiAmount).sub(highFunding).mul(rate)
        );

       
      } else if (weiRaised.add(weiAmount) > mediumFunding) {
        tokens = minFunding.sub(weiRaised)
          .mul(rate).mul(115).div(100);
        tokens = tokens.add(
          mediumFunding.sub(minFunding).mul(rate).mul(110).div(100)
        );
        tokens = tokens.add(
          weiRaised.add(weiAmount).sub(mediumFunding).mul(rate).mul(105).div(100)
        );

       
       
      } else if (weiRaised.add(weiAmount) > minFunding) {
        tokens = minFunding.sub(weiRaised)
          .mul(rate).mul(115).div(100);
        tokens = tokens.add(
          weiRaised.add(weiAmount).sub(minFunding).mul(rate).mul(110).div(100)
        );

       
      } else {
        tokens = weiAmount.mul(rate).mul(115).div(100);
      }

    } else if ((weiRaised >= minFunding) && (weiRaised < mediumFunding)) {

       
       
      if (weiRaised.add(weiAmount) > highFunding) {
        tokens = mediumFunding.sub(weiRaised)
          .mul(rate).mul(110).div(100);
        tokens = tokens.add(
          highFunding.sub(mediumFunding).mul(rate).mul(105).div(100)
        );
        tokens = tokens.add(
          weiRaised.add(weiAmount).sub(highFunding).mul(rate)
        );

       
       
      } else if (weiRaised.add(weiAmount) > mediumFunding) {
        tokens = mediumFunding.sub(weiRaised)
          .mul(rate).mul(110).div(100);
        tokens = tokens.add(
          weiRaised.add(weiAmount).sub(mediumFunding).mul(rate).mul(105).div(100)
        );

       
      } else {
        tokens = weiAmount.mul(rate).mul(110).div(100);
      }

    } else if ((weiRaised >= mediumFunding) && (weiRaised < highFunding)) {

       
       
      if (weiRaised.add(weiAmount) > highFunding) {
        tokens = highFunding.sub(weiRaised)
          .mul(rate).mul(105).div(100);
        tokens = tokens.add(
          weiRaised.add(weiAmount).sub(highFunding).mul(rate)
        );

       
      } else {
        tokens = weiAmount.mul(rate).mul(105).div(100);
      }

     
    } else {
      tokens = weiAmount.mul(rate);
    }

     
    require(token.totalSupply().add(tokens) <= maxICOSupply);

     
    weiRaised = weiRaised.add(weiAmount);

     
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

     
    forwardFunds();
  }

   
  function addPresaleTokens(
    address[] addrs, uint256[] values, uint256 rate
  ) onlyOwner external {
    require(now < endTime);
    require(addrs.length == values.length);
    require(rate > 0);

    uint256 totalTokens = 0;

    for(uint256 i = 0; i < addrs.length; i ++) {
      token.mint(addrs[i], values[i].mul(rate));
      totalTokens = totalTokens.add(values[i].mul(rate));

       
      weiRaised = weiRaised.add(values[i]);
      presaleWei = presaleWei.add(values[i]);
    }

     
    require(token.totalSupply() <= maxICOSupply);
  }

   
  function addToWhitelist(address[] addrs) onlyOwner external {
    for(uint256 i = 0; i < addrs.length; i ++) {
      require(!whitelist[addrs[i]]);
      whitelist[addrs[i]] = true;
      WhitelistedAddressAdded(addrs[i]);
    }
  }

   
  function removeFromWhitelist(address[] addrs) onlyOwner public {
    for(uint256 i = 0; i < addrs.length; i ++) {
      require(whitelist[addrs[i]]);
      whitelist[addrs[i]] = false;
      WhitelistedAddressRemoved(addrs[i]);
    }
  }


   
  function finalize() onlyOwner public {
    require(!isFinalized);
    
    if( goalReached() )
    {
	    finalization();
	    Finalized();
	
	    isFinalized = true;
    }
	else
	{
		if( hasEnded() )
		{
		    vault.enableRefunds();
		    
		    Finalized();
		    isFinalized = true;
		}
	}    
  }

   
  function finalization() internal {
    super.finalization();

     
     
     
    uint256 extraTokens = token.totalSupply().mul(219512195122).div(1000000000000);
    uint256 teamTokens = extraTokens.div(3);
    uint256 FSNASTokens = extraTokens.div(3).mul(2);

     
    TokenTimelock firstBatch = new TokenTimelock(token, teamAddress, now.add(30 days));
    token.mint(firstBatch, teamTokens.div(2));

    TokenTimelock secondBatch = new TokenTimelock(token, teamAddress, now.add(1 years));
    token.mint(secondBatch, teamTokens.div(2).div(3));

    TokenTimelock thirdBatch = new TokenTimelock(token, teamAddress, now.add(2 years));
    token.mint(thirdBatch, teamTokens.div(2).div(3));

    TokenTimelock fourthBatch = new TokenTimelock(token, teamAddress, now.add(3 years));
    token.mint(fourthBatch, teamTokens.div(2).div(3));

    VestedTeamTokens(firstBatch, secondBatch, thirdBatch, fourthBatch);

     
    token.mint(FSNASAddress, FSNASTokens);

     
    token.finishMinting();

     
    token.transferOwnership(wallet);

  }

}