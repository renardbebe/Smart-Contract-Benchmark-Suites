 

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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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




 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
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

}


contract Authorizable is Ownable {

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender]);
        _;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        authorized[_toRemove] = false;
    }

}


contract LiteNetCoin is StandardToken, Authorizable{
	
	uint256 public INITIAL_SUPPLY = 300000000 * 1 ether;  
	string public constant name = "LiteNetCoin";
    string public constant symbol = "LNC";
	uint8 public constant decimals = 18;
	
	constructor() public  {
        totalSupply_ = INITIAL_SUPPLY;
		balances[owner] = totalSupply_;
    }
	
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
    }
}



contract Crowdsale is LiteNetCoin {

	using SafeMath for uint256;

    LiteNetCoin public token = new LiteNetCoin();
	
	uint256 public constant BASE_RATE = 2500;
 
	 
	uint64 public constant PRE_SALE_START_1 = 1526256000;  
	 
	
	 
	uint64 public constant PRE_SALE_START_2 = 1527465600;  
	 
	
	 
	uint64 public constant PRE_SALE_START_3 = 1529884800;  
	 
	
	 
	
	 
	uint64 public constant PRE_SALE_START_4 = 1535328000;  
	 
	
	 
	uint64 public constant PRE_ICO_START = 1538870400;  
	 
	
	 
	uint64 public constant ICO_START = 1541030400;  
	
	 
	uint64 public constant ICO_FINISH = 1541376000;  
 
	 
	bool public icoClosed = false;

	uint256 totalBuyTokens_ = 0;

	event BoughtTokens(address indexed to, uint256 value);
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	

	enum TokenDistributions { crowdsale, reserve, bounty, team, founders }
	mapping(uint => uint256) public distributions;
	
	address public teamTokens = 0xC7FDAE4f201D76281975D890d5491D90Ec433B0E;
	address public notSoldTokens = 0x6CccCD6fa8184D29950dF21DDDE1069F5B37F3d1;
	
	
	constructor() public  {
		distributions[uint8(TokenDistributions.crowdsale)] = 240000000 * 1 ether;
		distributions[uint8(TokenDistributions.founders)] = 12000000 * 1 ether;
		distributions[uint8(TokenDistributions.reserve)] = 30000000 * 1 ether;
		distributions[uint8(TokenDistributions.bounty)] = 9000000 * 1 ether;
		distributions[uint8(TokenDistributions.team)] = 9000000 * 1 ether;
	}

	 
	function changeOwner(address _newOwner) external onlyOwner{
        owner = _newOwner;
    }
	 
	function changeTeamTokens(address _teamTokens) external onlyOwner{
        teamTokens = _teamTokens;
    }
	 
	function changeNotSoldTokens(address _notSoldTokens) external onlyOwner{
        notSoldTokens = _notSoldTokens;
    }


	 
    function() public payable {
		buyTokens(msg.sender);
    }
    
     
    function buyTokens(address _addr) public payable {
		require(msg.value >= 0.001 ether);
		require(distributions[0] > 0);
		require(totalBuyTokens_ <= INITIAL_SUPPLY );
		require(getCurrentRound() > 0);
		
		uint discountPercent = getCurrentDiscountPercent();
		
		uint256 weiAmount = msg.value;
        uint256 tokens = getRate(weiAmount);
		uint256 bonusTokens = tokens.mul(discountPercent).div(100);
		tokens += bonusTokens;
		totalBuyTokens_ = totalBuyTokens_.add(tokens);

	    token.transfer(_addr, tokens);
		totalSupply_ = totalSupply_.sub(tokens);
		distributions[0] = distributions[0].sub(tokens);
		
	    owner.transfer(msg.value);
		
		emit TokenPurchase(msg.sender, _addr, weiAmount, tokens);
    }


	
	function getCurrentRound() public view returns (uint8 round) {
        round = 0;
		
		if(now > ICO_START + 3 days  && now <= ICO_START + 5 days)      round = 7;
		if(now > ICO_START        && now <= ICO_START        + 3 days)  round = 6;
		if(now > PRE_ICO_START    && now <= PRE_ICO_START    + 7 days)  round = 5;
		if(now > PRE_SALE_START_4 && now <= PRE_SALE_START_4 + 6 days)  round = 4;
		if(now > PRE_SALE_START_3 && now <= PRE_SALE_START_3 + 6 days)  round = 3;
		if(now > PRE_SALE_START_2 && now <= PRE_SALE_START_2 + 13 days) round = 2;
		if(now > PRE_SALE_START_1 && now <= PRE_SALE_START_1 + 8 days)  round = 1;
		

		 
		
		
        return round;
    }
	
	
	function getCurrentDiscountPercent() constant returns (uint){
		uint8 round = getCurrentRound();
		uint discountPercent = 0;
		
		
		if(round == 1 ) discountPercent = 65;
		if(round == 2 ) discountPercent = 65;
		if(round == 3 ) discountPercent = 60;
		if(round == 4 ) discountPercent = 55;
		if(round == 5 ) discountPercent = 40;
		if(round == 6 ) discountPercent = 30;
		if(round == 7 ) discountPercent = 0;
		
		return discountPercent;
		
	}
	

	function totalBuyTokens() public view returns (uint256) {
		return totalBuyTokens_;
	}
	
	function getRate(uint256 _weiAmount) internal view returns (uint256) {
		return _weiAmount.mul(BASE_RATE);
	}
	
	
	function sendOtherTokens(address _addr,uint256 _amount) onlyOwner onlyAuthorized isNotIcoClosed public {
        require(totalBuyTokens_ <= INITIAL_SUPPLY);
		
		token.transfer(_addr, _amount);
		totalSupply_ = totalSupply_.sub(_amount);
		totalBuyTokens_ = totalBuyTokens_.add(_amount);
		
    }
	
	
	function sendBountyTokens(address _addr,uint256 _amount) onlyOwner onlyAuthorized isNotIcoClosed public {
        require(distributions[3] > 0);
		sendOtherTokens(_addr, _amount);
		distributions[3] = distributions[3].sub(_amount);
    }
	

	
	 
    function close() public onlyOwner isNotIcoClosed {
         
		require(now > ICO_FINISH);
		
		if(distributions[0] > 0){
			token.transfer(notSoldTokens, distributions[0]);
			totalSupply_ = totalSupply_.sub(distributions[0]);
			totalBuyTokens_ = totalBuyTokens_.add(distributions[0]);
			distributions[0] = 0;
		}
		token.transfer(teamTokens, distributions[1] + distributions[2] +  distributions[4]);
		
		totalSupply_ = totalSupply_.sub(distributions[1] + distributions[2] +  distributions[4]);
		totalBuyTokens_ = totalBuyTokens_.add(distributions[1] + distributions[2] +  distributions[4]);
		
		distributions[1] = 0;
		distributions[2] = 0;
		distributions[4] = 0;
		
		
        icoClosed = true;
    }
	
	modifier isNotIcoClosed {
        require(!icoClosed);
        _;
    }
  
}