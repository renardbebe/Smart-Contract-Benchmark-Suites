 

pragma solidity ^0.4.24;



 
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



 
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
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



contract CTFOCrowdsale is StandardToken {

	using SafeMath for uint256;

	string public constant name = "Orinoco D. F. Co-founder Token";
	string public constant symbol = "CTFO";
	uint8 public constant decimals = 18;

	uint256 public constant INITIAL_SUPPLY = 1000000 * (10 ** uint256(decimals));
	uint256 public constant TEAM_TOKENS = 140000 * (10 ** uint256(decimals));
	uint256 public constant SALE_TOKENS = 860000 * (10 ** uint256(decimals));	
	uint256 public constant exchangeRate = 500;

	bool public isFinalized = false;

	address public constant etherAddress = 0xFC20A4238ABAfBFa29F582CbcF93e23cD3c9858b;
	address public constant teamWallet = 0x4c646420d8A8ae7C66de9c40FfE31c295c87272B;
	address public constant saleWallet = 0x9D4537094Fa30d8042A51F4F0CD29F170B28456B;

	uint256 public constant crowdsaleStart = 1534204800;
	uint256 public constant crowdsaleEnd = 1536019200;


	event Mint(address indexed to, uint256 amount);

	constructor () public {

		totalSupply_ = INITIAL_SUPPLY;

		balances[teamWallet] = TEAM_TOKENS;
		emit Mint(teamWallet, TEAM_TOKENS);
		emit Transfer(address(0), teamWallet, TEAM_TOKENS);

		balances[saleWallet] = SALE_TOKENS;
		emit Mint(saleWallet, SALE_TOKENS);
		emit Transfer(address(0), saleWallet, SALE_TOKENS);

	}


	function purchaseTokens() public payable  {

		require( now >= crowdsaleStart );
		require( now <= crowdsaleEnd );

		require( msg.value >= 1000 finney );

		uint256 tokens = 0;
		tokens = msg.value.mul(exchangeRate);
		
		uint256 unsoldTokens = balances[saleWallet];

		require( unsoldTokens >= tokens );

		balances[saleWallet] -= tokens;
		balances[msg.sender] += tokens;
		emit Transfer(saleWallet, msg.sender, tokens);
		
		etherAddress.transfer(msg.value.mul(90).div(100));
		teamWallet.transfer(msg.value.mul(10).div(100));

	}


	function() public payable {

		purchaseTokens();

	}


	event Burn(address indexed burner, uint256 value);

	function burn(uint256 _value) public {
		require( !isFinalized );
		require( msg.sender == saleWallet );
		require( now > crowdsaleEnd || balances[msg.sender] == 0);

		_burn(msg.sender, _value);
	}

	function _burn(address _who, uint256 _value) internal {
		require(_value <= balances[_who]);

		balances[_who] = balances[_who].sub(_value);
		totalSupply_ = totalSupply_.sub(_value);
		emit Burn(_who, _value);
		emit Transfer(_who, address(0), _value);

		if (balances[_who] == 0) {
			isFinalized = true;
		}
	}

}