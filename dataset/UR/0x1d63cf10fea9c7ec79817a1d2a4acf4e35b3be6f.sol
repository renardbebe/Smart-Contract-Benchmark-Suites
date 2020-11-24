 

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

 

 
contract ChildToken is StandardToken {
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

 

 
contract Slogan is Ownable {
	string public slogan;

	event SloganChanged(string indexed oldSlogan, string indexed newSlogan);

	function Slogan(string _slogan) public {
		slogan = _slogan;
	}

	function ownerChangeSlogan(string _slogan) onlyOwner public {
		SloganChanged(slogan, _slogan);
		slogan = _slogan;
	}
}

 
contract Bitansuo is Slogan {
	function Bitansuo() Slogan("币探索 (bitansuo.com | bitansuo.eth)") public {
	}
}

 

 
contract Refundable is Bitansuo {
	event RefundETH(address indexed owner, address indexed payee, uint256 amount);
	event RefundERC20(address indexed owner, address indexed payee, address indexed token, uint256 amount);

	function Refundable() public payable {
	}

	function refundETH(address payee, uint256 amount) onlyOwner public {
		require(payee != address(0));
		require(this.balance >= amount);
		assert(payee.send(amount));
		RefundETH(owner, payee, amount);
	}

	function refundERC20(address tokenContract, address payee, uint256 amount) onlyOwner public {
		require(payee != address(0));
		bool isContract;
		assembly {
			isContract := gt(extcodesize(tokenContract), 0)
		}
		require(isContract);

		ERC20 token = ERC20(tokenContract);
		assert(token.transfer(payee, amount));
		RefundERC20(owner, payee, tokenContract, amount);
	}
}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
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
    totalSupply_ = totalSupply_.add(_amount);
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

 

 
contract ComplexChildToken is ChildToken, Refundable, MintableToken, BurnableToken {
	string public name;
	string public symbol;
	uint8 public decimals;
	bool public canBurn;

	event Burn(address indexed burner, uint256 value);

	function ComplexChildToken(address _owner, string _name, string _symbol, uint256 _initSupply, uint8 _decimals,
		bool _canMint, bool _canBurn) public {
		require(_owner != address(0));
		owner = _owner;
		name = _name;
		symbol = _symbol;
		decimals = _decimals;

		uint256 amount = _initSupply;
		totalSupply_ = totalSupply_.add(amount);
		balances[owner] = balances[owner].add(amount);
		Transfer(address(0), owner, amount);

		if (!_canMint) {
			mintingFinished = true;
		}
		canBurn = _canBurn;
	}

	 
	function burn(uint256 _value) public {
		require(canBurn);
		BurnableToken.burn(_value);
	}

	function ownerCanBurn(bool _canBurn) onlyOwner public {
		canBurn = _canBurn;
	}
}