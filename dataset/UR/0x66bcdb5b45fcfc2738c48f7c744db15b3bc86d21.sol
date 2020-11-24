 

pragma solidity 0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

 
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

 
contract RBACBurnableToken is BurnableToken, Ownable, RBAC {
   
  string public constant ROLE_BURNER = "burner";

   
  function _burn(address _who, uint256 _value) internal {
    checkRole(msg.sender, ROLE_BURNER);
    super._burn(_who, _value);    
  }

   
  function addBurner(address _burner) public onlyOwner {
    addRole(_burner, ROLE_BURNER);
  }

   
  function removeBurner(address _burner) public onlyOwner {
    removeRole(_burner, ROLE_BURNER);
  }
}

 

contract ABCToken is MintableToken, CappedToken, RBACBurnableToken {
    string public name = "ABC Token";
    string public symbol = "ABC";
    uint8 public decimals = 18;
    function ABCToken
        (
            uint256 _cap
        )
        public 
        CappedToken(_cap) {

        }
}

 

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 

 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
     
    require(MintableToken(address(token)).mint(_beneficiary, _tokenAmount));
  }
}

 

 
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

 

 
contract WhitelistedCrowdsale is Whitelist, Crowdsale {
   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyIfWhitelisted(_beneficiary)
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 

 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  constructor(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 

 
contract FinalizableCrowdsale is Ownable, TimedCrowdsale {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() public onlyOwner {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }

}

 

 
contract Escrow is Ownable {
  using SafeMath for uint256;

  event Deposited(address indexed payee, uint256 weiAmount);
  event Withdrawn(address indexed payee, uint256 weiAmount);

  mapping(address => uint256) private deposits;

  function depositsOf(address _payee) public view returns (uint256) {
    return deposits[_payee];
  }

   
  function deposit(address _payee) public onlyOwner payable {
    uint256 amount = msg.value;
    deposits[_payee] = deposits[_payee].add(amount);

    emit Deposited(_payee, amount);
  }

   
  function withdraw(address _payee) public onlyOwner {
    uint256 payment = deposits[_payee];
    assert(address(this).balance >= payment);

    deposits[_payee] = 0;

    _payee.transfer(payment);

    emit Withdrawn(_payee, payment);
  }
}

 

 
contract ConditionalEscrow is Escrow {
   
  function withdrawalAllowed(address _payee) public view returns (bool);

  function withdraw(address _payee) public {
    require(withdrawalAllowed(_payee));
    super.withdraw(_payee);
  }
}

 

 
contract RefundEscrow is Ownable, ConditionalEscrow {
  enum State { Active, Refunding, Closed }

  event Closed();
  event RefundsEnabled();

  State public state;
  address public beneficiary;

   
  constructor(address _beneficiary) public {
    require(_beneficiary != address(0));
    beneficiary = _beneficiary;
    state = State.Active;
  }

   
  function deposit(address _refundee) public payable {
    require(state == State.Active);
    super.deposit(_refundee);
  }

   
  function close() public onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
  }

   
  function enableRefunds() public onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

   
  function beneficiaryWithdraw() public {
    require(state == State.Closed);
    beneficiary.transfer(address(this).balance);
  }

   
  function withdrawalAllowed(address _payee) public view returns (bool) {
    return state == State.Refunding;
  }
}

 

 
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  RefundEscrow private escrow;

   
  constructor(uint256 _goal) public {
    require(_goal > 0);
    escrow = new RefundEscrow(wallet);
    goal = _goal;
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    escrow.withdraw(msg.sender);
  }

   
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

   
  function finalization() internal {
    if (goalReached()) {
      escrow.close();
      escrow.beneficiaryWithdraw();
    } else {
      escrow.enableRefunds();
    }

    super.finalization();
  }

   
  function _forwardFunds() internal {
    escrow.deposit.value(msg.value)(msg.sender);
  }

}

 

 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
     
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
     
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(address(this));
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

 

contract ABCTokenCrowdsale is WhitelistedCrowdsale, RefundableCrowdsale, MintedCrowdsale {
    
     
    enum CrowdsaleStage { PrivateSale, PreSale, ICO }
    CrowdsaleStage public stage = CrowdsaleStage.PrivateSale; 

    uint256 public privateSaleRate;
    uint256 public preSaleRate;
    uint256 public publicRate;
    uint256 public totalTokensForSaleDuringPrivateSale;
    uint256 public totalTokensForSaleDuringPreSale;
    uint256 public totalTokensForSale;
    uint256 public privateSaleMinimumTokens;
    uint256 public preSaleMinimumTokens;
    uint256 public tokensForTeam;
    uint256 public tokensForAdvisors;

    uint256 public privateSaleTokensSold = 0;
    uint256 public preSaleTokensSold = 0;
    uint256 public tokensSold = 0;


     
    address public teamWallet;
    address public advisorsWallet;

	address public teamTimelock1;
	address public teamTimelock2;
	address public teamTimelock3;
	address public teamTimelock4;
	address public teamTimelock5;
	address public teamTimelock6;
	address public teamTimelock7;
	address public advisorTimelock;
    
	function ABCTokenCrowdsale
        (
        	uint256 _goal,
            uint256 _openingTime,
            uint256 _closingTime,
            uint256 _privateSaleRate,
            uint256 _preSaleRate,
            uint256 _rate,
            uint256 _totalTokensForSaleDuringPrivateSale,
            uint256 _totalTokensForSaleDuringPreSale,
            uint256 _totalTokensForSale,
            uint256 _privateSaleMinimumTokens,
            uint256 _preSaleMinimumTokens,
            uint256 _tokensForTeam,
            uint256 _tokensForAdvisors,
            address _wallet,
            MintableToken _token
        )
        public
        Crowdsale(_rate, _wallet, _token)
        TimedCrowdsale(_openingTime, _closingTime)
        RefundableCrowdsale(_goal) {
        
        	uint256 tokenCap = CappedToken(address(_token)).cap();
			require(_totalTokensForSale.add(_tokensForTeam).add(_tokensForAdvisors) <= tokenCap);			
			
            publicRate = _rate;
            preSaleRate = _preSaleRate;
            privateSaleRate = _privateSaleRate;           

			totalTokensForSaleDuringPrivateSale = _totalTokensForSaleDuringPrivateSale;
            totalTokensForSaleDuringPreSale = _totalTokensForSaleDuringPreSale;
            totalTokensForSale = _totalTokensForSale;

			preSaleMinimumTokens = _preSaleMinimumTokens;
    		privateSaleMinimumTokens = _privateSaleMinimumTokens;

			tokensForTeam = _tokensForTeam;
    		tokensForAdvisors = _tokensForAdvisors;

            setCrowdsaleStage(uint(CrowdsaleStage.PrivateSale));
    }
    
    function setCrowdsaleStage(uint value) public onlyOwner {
    
        CrowdsaleStage _stage;
        
        if (uint(CrowdsaleStage.PrivateSale) == value) {
            _stage = CrowdsaleStage.PrivateSale;
        } else if (uint(CrowdsaleStage.PreSale) == value) {
            _stage = CrowdsaleStage.PreSale;
        } else if (uint(CrowdsaleStage.ICO) == value) {
            _stage = CrowdsaleStage.ICO;
        }
        
        stage = _stage;
        
        
        if (stage == CrowdsaleStage.PrivateSale) {
            setCurrentRate(privateSaleRate);
        } else if (stage == CrowdsaleStage.PreSale) {
            setCurrentRate(preSaleRate);
        } else if (stage == CrowdsaleStage.ICO) {
            setCurrentRate(publicRate);
        }
    }
    
    function setTeamWallet(address _wallet) public onlyOwner {
		teamWallet = _wallet;
	}    
    function setAdvisorWallet(address _wallet) public onlyOwner {
		advisorsWallet = _wallet;
	}    

    function setCurrentRate(uint256 _rate) private {
        rate = _rate;
    }
    
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);

        uint256 tokens = _getTokenAmount(_weiAmount);
        if (stage == CrowdsaleStage.PrivateSale) {
            require(tokens >= privateSaleMinimumTokens);
            require(privateSaleTokensSold.add(tokens) <= totalTokensForSaleDuringPrivateSale);
        } else if (stage == CrowdsaleStage.PreSale) {
            require(tokens >= preSaleMinimumTokens);
            require(preSaleTokensSold.add(tokens) <= totalTokensForSaleDuringPreSale);
        }
        require(tokensSold.add(tokens) <= totalTokensForSale);
    }    

    function _postValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
        super._postValidatePurchase(_beneficiary, _weiAmount);

        uint256 tokens = _getTokenAmount(_weiAmount);
        if (stage == CrowdsaleStage.PrivateSale) {
            privateSaleTokensSold = privateSaleTokensSold.add(tokens);
        } else if (stage == CrowdsaleStage.PreSale) {
            preSaleTokensSold = preSaleTokensSold.add(tokens);
        }
        tokensSold = tokensSold.add(tokens);
    }    

	function finalization() 
	internal 
	{
    	if(goalReached()) {        
			require(teamWallet != address(0));
			require(advisorsWallet != address(0));

	         
    	    uint256 teamReleaseTime1 = now + (182.5 * 24 * 60 * 60);  
        	teamTimelock1 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 25 / 100 ), teamReleaseTime1);
        
	        uint256 teamReleaseTime2 = teamReleaseTime1 + (91.25 * 24 * 60 * 60);  
    	    teamTimelock2 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 125 / 1000), teamReleaseTime2);
        
        	uint256 teamReleaseTime3 = teamReleaseTime2 + (91.25 * 24 * 60 * 60);  
	        teamTimelock3 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 125 / 1000), teamReleaseTime3);
        
        	uint256 teamReleaseTime4 = teamReleaseTime3 + (91.25 * 24 * 60 * 60);  
        	teamTimelock4 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 125 / 1000), teamReleaseTime4);
        
	        uint256 teamReleaseTime5 = teamReleaseTime4 + (91.25 * 24 * 60 * 60);  
    	    teamTimelock5 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 125 / 1000), teamReleaseTime5);
        
	        uint256 teamReleaseTime6 = teamReleaseTime5 + (91.25 * 24 * 60 * 60);  
    	    teamTimelock6 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 125 / 1000), teamReleaseTime6);
        
	        uint256 teamReleaseTime7 = teamReleaseTime6 + (91.25 * 24 * 60 * 60);  
    	    teamTimelock7 = mintTimeLockedTokens(teamWallet, (tokensForTeam * 125 / 1000), teamReleaseTime7);

	         
	        uint256 advisorReleaseTime = now + (91.25 * 24 * 60 * 60);  
    	    advisorTimelock = mintTimeLockedTokens(advisorsWallet, tokensForAdvisors, advisorReleaseTime);
        
			MintableToken _mintableToken = MintableToken(token);
			_mintableToken.finishMinting();
		
	      	_mintableToken.transferOwnership(wallet);
    	}
	    super.finalization();    	          
    }    

    function mintTimeLockedTokens(address _to, uint256 _amount, uint256 _releaseTime) private returns (TokenTimelock) {
        TokenTimelock timelock = new TokenTimelock(token, _to, _releaseTime);
        MintableToken(address(token)).mint(timelock, _amount);
        return timelock;
    }        
}