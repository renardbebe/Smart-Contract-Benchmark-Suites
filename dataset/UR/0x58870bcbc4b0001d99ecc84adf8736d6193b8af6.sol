 

pragma solidity ^0.4.18;

 

 
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
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

 

 
contract CappedMintableToken is StandardToken, Ownable {
  using SafeMath for uint256;

  event Mint(address indexed to, uint256 amount);

  modifier canMint() {
    require(now <= publicSaleEnd);
    _;
  }

  modifier onlyOwnerOrCrowdsale() {
    require(msg.sender == owner || msg.sender == crowdsale);
    _;
  }

  uint256 public publicSaleEnd;
  uint256 public cap;
  address public crowdsale;

	function setCrowdsale(address _crowdsale) public onlyOwner {
		crowdsale = _crowdsale;
	}

  

  function CappedMintableToken(uint256 _cap, uint256 _publicSaleEnd) public {
    require(_publicSaleEnd > now);
    require(_cap > 0);

    publicSaleEnd = _publicSaleEnd;
    cap = _cap;
  }

   
  function send(address target, uint256 mintedAmount, uint256 lockTime) public onlyOwnerOrCrowdsale {
    mint(target, mintedAmount);
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
    require(now > publicSaleEnd);

    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(now > publicSaleEnd);

    return super.transferFrom(_from, _to, _value);
  }
  
}

 

 
contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

 

 
 




contract GMBCToken is HasNoEther, CappedMintableToken {
	using SafeMath for uint256;

	string public constant name = "Official Gamblica Coin";
	string public constant symbol = "GMBC";
	uint8 public constant decimals = 18;

	uint256 public TOKEN_SALE_CAP = 600000000 * (10 ** uint256(decimals));
	uint256 public END_OF_MINT_DATE = 1527811200;	 

	bool public finalized = false;

	

	 
	function GMBCToken() public 
		CappedMintableToken(TOKEN_SALE_CAP, END_OF_MINT_DATE)
	{
		
	}

	 
	function finalize(address _fund) public onlyOwner returns (bool) {
		require(!finalized && now > publicSaleEnd);		
		require(_fund != address(0));

		uint256 amount = totalSupply_.mul(4).div(6);	 

		totalSupply_ = totalSupply_.add(amount);
    	balances[_fund] = balances[_fund].add(amount);
    	Mint(_fund, amount);
    	Transfer(address(0), _fund, amount);
    
		finalized = true;

		return true;
	}


	
}