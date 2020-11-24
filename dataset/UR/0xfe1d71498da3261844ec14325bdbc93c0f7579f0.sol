 

pragma solidity ^0.4.21;

 

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract CappedMintableToken is StandardToken, Ownable {
  using SafeMath for uint256;

  event Mint(address indexed to, uint256 amount);

  modifier canMint() {
    require(mintEnabled);
    _;
  }

  modifier onlyOwnerOrCrowdsale() {
    require(msg.sender == owner || msg.sender == crowdsale);
    _;
  }

  bool public mintEnabled;
  bool public transferEnabled;
  uint256 public cap;
  address public crowdsale;
  

	function setCrowdsale(address _crowdsale) public onlyOwner {
		crowdsale = _crowdsale;
	}

  function CappedMintableToken(uint256 _cap) public {    
    require(_cap > 0);

    mintEnabled = true;
    transferEnabled = false;
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwnerOrCrowdsale canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);
    require(_amount > 0);

    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(transferEnabled);

    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(transferEnabled);

    return super.transferFrom(_from, _to, _value);
  }
  
}

 

contract GMBCTokenBuyable is CappedMintableToken {  
  bool public payableEnabled;  
  uint256 public minPurchase;  

  function () external payable {    
    buyTokens(msg.sender);
  }

  function setPayableEnabled(bool _payableEnabled) onlyOwner external {
    payableEnabled = _payableEnabled;
  }

  function setMinPurchase(uint256 _minPurchase) onlyOwner external {
    minPurchase = _minPurchase;
  }

  function buyTokens(address _beneficiary) public payable {
    require(payableEnabled);

    uint256 weiAmount = msg.value;
    require(_beneficiary != address(0));
    require(weiAmount >= minPurchase);

     
    uint256 tokens = getTokenAmount(weiAmount);
    mint(_beneficiary, tokens);
  }

  function getTokenAmount(uint256 _weiAmount) public view returns (uint256);

    
  function claimEther(uint256 _weiAmount) external onlyOwner {    
    owner.transfer(_weiAmount);
  }
}

 

 
contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(this.balance);
  }
}

 

contract GMBCToken is GMBCTokenBuyable {
	using SafeMath for uint256;

	string public constant name = "Gamblica Token";
	string public constant symbol = "GMBC";
	uint8 public constant decimals = 18;

	bool public finalized = false;
	uint8 public bonus = 0;				 
	uint256 public basePrice = 10000;	 

	 
	function GMBCToken() public 
		CappedMintableToken( 600000000 * (10 ** uint256(decimals)) )  
	{}

	 
	function setBonus(uint8 _bonus) onlyOwnerOrCrowdsale external {		
		require(_bonus >= 0 && _bonus <= 100);
		bonus = _bonus;
	}

	function setBasePrice(uint256 _basePrice) onlyOwner external {
		require(_basePrice > 0);
		basePrice = _basePrice;
	}

	 
	function getTokenAmount(uint256 _weiAmount) public view returns (uint256) {		
		require(decimals == 18);
		uint256 gmbc = _weiAmount.mul(basePrice);
		return gmbc.add(gmbc.mul(bonus).div(100));
	}

	 
	function finalize(address _fund) public onlyOwner returns (bool) {
		require(!finalized);		
		require(_fund != address(0));

		uint256 amount = totalSupply_.mul(4).div(6);	 

		totalSupply_ = totalSupply_.add(amount);
    	balances[_fund] = balances[_fund].add(amount);
    	emit Mint(_fund, amount);
    	emit Transfer(address(0), _fund, amount);
    
		mintEnabled = false;
		transferEnabled = true;
		finalized = true;

		return true;
	}


	
}