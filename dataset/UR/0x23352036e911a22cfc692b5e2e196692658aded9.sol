 

pragma solidity 0.4.19;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    require(newOwner != owner);

    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Whitelisted is Ownable {

	 
	mapping (address => bool) public whitelist;

	 
	event WhitelistChanged(address indexed account, bool state);

	 

	 
	modifier isWhitelisted(address _addr) {
		require(whitelist[_addr] == true);

		_;
	}

	 
	function setWhitelist(address _addr, bool _state) onlyOwner external {
		require(_addr != address(0));
		require(whitelist[_addr] != _state);

		whitelist[_addr] = _state;

		WhitelistChanged(_addr, _state);
	}

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value > 0);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {
	 
	event Burn(address indexed burner, uint256 amount);

	 
	function burn(uint256 _value) public {
		balances[msg.sender] = balances[msg.sender].sub(_value);
		totalSupply = totalSupply.sub(_value);

		Burn(msg.sender, _value);
	}
}

contract FriendzToken is BurnableToken, Ownable {

	 
	mapping(address => uint256) public release_dates;
	mapping(address => uint256) public purchase_dates;
	mapping(address => uint256) public blocked_amounts;
	mapping (address => mapping (address => uint256)) public allowed;
	bool public free_transfer = false;
	uint256 public RELEASE_DATE = 1522540800;  

	 
	address private co_owner;
	address private presale_holder = 0x1ea128767610c944Ff9a60E4A1Cbd0C88773c17c;
	address private ico_holder = 0xc1c643701803eca8DDfA2017547E8441516BE047;
	address private reserved_holder = 0x26226CfaB092C89eF3D79653D692Cc1425a0B907;
	address private wallet_holder = 0xBF0B56276e90fc4f0f1e2Ec66fa418E30E717215;

	 
	string public name;
	string public symbol;
	uint256 public decimals;

	 

	 
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event UpdatedBlockingState(address indexed to, uint256 purchase, uint256 end_date, uint256 value);
	event CoOwnerSet(address indexed owner);
	event ReleaseDateChanged(address indexed from, uint256 date);

	function FriendzToken(string _name, string _symbol, uint256 _decimals, uint256 _supply) public {
		 
		require(_decimals > 0);
		require(_supply > 0);

		 
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		totalSupply = _supply;

		 
		balances[owner] = _supply;
	}

	 

	 
	modifier canTransfer(address _sender, uint256 _value) {
		require(_sender != address(0));

		require(
			(free_transfer) ||
			canTransferBefore(_sender) ||
			canTransferIfLocked(_sender, _value)
	 	);

	 	_;
	}

	 
	modifier isFreeTransfer() {
		require(free_transfer);

		_;
	}

	 
	modifier isBlockingTransfer() {
		require(!free_transfer);

		_;
	}

	 

	function canTransferBefore(address _sender) public view returns(bool) {
		return (
			_sender == owner ||
			_sender == presale_holder ||
			_sender == ico_holder ||
			_sender == reserved_holder ||
			_sender == wallet_holder
		);
	}

	function canTransferIfLocked(address _sender, uint256 _value) public view returns(bool) {
		uint256 after_math = balances[_sender].sub(_value);
		return (
			now >= RELEASE_DATE &&
		    after_math >= getMinimumAmount(_sender)
        );
	}

	 
	function setCoOwner(address _addr) onlyOwner public {
		require(_addr != co_owner);

		co_owner = _addr;

		CoOwnerSet(_addr);
	}

	 
	function setReleaseDate(uint256 _date) onlyOwner public {
		require(_date > 0);
		require(_date != RELEASE_DATE);

		RELEASE_DATE = _date;

		ReleaseDateChanged(msg.sender, _date);
	}

	 
	function getMinimumAmount(address _addr) constant public returns (uint256) {
		 
		if(blocked_amounts[_addr] == 0x0)
			return 0x0;

		 
		if(purchase_dates[_addr] > now){
			return blocked_amounts[_addr];
		}

		uint256 alpha = uint256(now).sub(purchase_dates[_addr]);  
		uint256 beta = release_dates[_addr].sub(purchase_dates[_addr]);  
		uint256 tokens = blocked_amounts[_addr].sub(alpha.mul(blocked_amounts[_addr]).div(beta));  

		return tokens;
	}

	 
	function setBlockingState(address _addr, uint256 _end, uint256 _value) isBlockingTransfer public {
		 
		require(
			msg.sender == owner ||
			msg.sender == co_owner
		);
		require(_addr != address(0));

		uint256 final_value = _value;

		if(release_dates[_addr] != 0x0){
			 
			 
			final_value = blocked_amounts[_addr].add(_value);
		}

		release_dates[_addr] = _end;
		purchase_dates[_addr] = RELEASE_DATE;
		blocked_amounts[_addr] = final_value;

		UpdatedBlockingState(_addr, _end, RELEASE_DATE, final_value);
	}

	 
	function freeToken() public onlyOwner {
		free_transfer = true;
	}

	 
	function transfer(address _to, uint _value) canTransfer(msg.sender, _value) public returns (bool success) {
		return super.transfer(_to, _value);
	}

	 
	function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) public returns (bool success) {
		require(_from != address(0));
		require(_to != address(0));

	     
	    balances[_from] = balances[_from].sub(_value);
	    balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);  

	     
	    Transfer(_from, _to, _value);

	    return true;
	}

	 
  	function approve(address _spender, uint256 _value) public returns (bool) {
	 	require(_value == 0 || allowed[msg.sender][_spender] == 0);

	 	allowed[msg.sender][_spender] = _value;
	 	Approval(msg.sender, _spender, _value);

	 	return true;
  	}

	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    	return allowed[_owner][_spender];
  	}

	 
	function increaseApproval (address _spender, uint256 _addedValue) public returns (bool success) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval (address _spender, uint256 _subtractedValue) public returns (bool success) {
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue >= oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

}