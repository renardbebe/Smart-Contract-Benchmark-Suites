 

pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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

 

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 
contract AidCoin is MintableToken, BurnableToken {
    string public name = "AidCoin";
    string public symbol = "AID";
    uint256 public decimals = 18;
    uint256 public maxSupply = 100000000 * (10 ** decimals);

    function AidCoin() public {

    }

    modifier canTransfer(address _from, uint _value) {
        require(mintingFinished);
        _;
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender, _value) public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

 

 
contract JulyAirdrop is Ownable {
  using SafeMath for uint256;

  address airdropWallet;
  mapping (address => uint256) public claimedAirdropTokens;
  mapping (address => uint256) public previousAirdropSurplus;
  mapping (address => uint256) public remainingAirdropSurplus;
  address[] public remainingAirdropSurplusAddresses;

  AidCoin public token;

  constructor(address _airdropWallet, address _token) public {
    require(_airdropWallet != address(0));
    require(_token != address(0));

    airdropWallet = _airdropWallet;
    token = AidCoin(_token);
  }

  function setPreviousSurplus(address[] users, uint256[] amounts) public onlyOwner {
    require(users.length > 0);
    require(amounts.length > 0);
    require(users.length == amounts.length);

    for (uint i = 0; i < users.length; i++) {
      address to = users[i];
      uint256 value = amounts[i];
      previousAirdropSurplus[to] = value;
    }
  }

  function multisend(address[] users, uint256[] amounts) public onlyOwner {
    require(users.length > 0);
    require(amounts.length > 0);
    require(users.length == amounts.length);

    for (uint i = 0; i < users.length; i++) {
      address to = users[i];
      uint256 value = (amounts[i] * (10 ** 18)).mul(75).div(1000);

      if (claimedAirdropTokens[to] == 0) {
        claimedAirdropTokens[to] = value;

        if (value > previousAirdropSurplus[to]) {
          value = value.sub(previousAirdropSurplus[to]);
          token.transferFrom(airdropWallet, to, value);
        } else {
          remainingAirdropSurplus[to] = previousAirdropSurplus[to].sub(value);
          remainingAirdropSurplusAddresses.push(to);
        }
      }
    }
  }

  function getRemainingAirdropSurplusAddressesLength() view public returns (uint) {
    return remainingAirdropSurplusAddresses.length;
  }
}

 

 
contract OctoberAirdrop is Ownable {
	using SafeMath for uint256;

	address airdropWallet;
	mapping (address => uint256) public claimedAirdropTokens;
	mapping (address => uint256) public remainingAirdropSurplus;
	address[] public remainingAirdropSurplusAddresses;

	JulyAirdrop previousAirdrop;
	AidCoin public token;

	constructor(address _airdropWallet, address _token, address _previousAirdrop) public {
		require(_airdropWallet != address(0));
		require(_token != address(0));
		require(_previousAirdrop != address(0));

		airdropWallet = _airdropWallet;
		token = AidCoin(_token);
		previousAirdrop = JulyAirdrop(_previousAirdrop);
	}

	function multisend(address[] users, uint256[] amounts) public onlyOwner {
		require(users.length > 0);
		require(amounts.length > 0);
		require(users.length == amounts.length);

		for (uint i = 0; i < users.length; i++) {
			address to = users[i];
			uint256 value = (amounts[i] * (10 ** 18)).mul(125).div(1000);

			if (claimedAirdropTokens[to] == 0) {
				claimedAirdropTokens[to] = value;

				uint256 previousSurplus = previousAirdrop.remainingAirdropSurplus(to);
				if (value > previousSurplus) {
					value = value.sub(previousSurplus);
					token.transferFrom(airdropWallet, to, value);
				} else {
					remainingAirdropSurplus[to] = previousSurplus.sub(value);
					remainingAirdropSurplusAddresses.push(to);
				}
			}
		}
	}

	function getRemainingAirdropSurplusAddressesLength() view public returns (uint) {
		return remainingAirdropSurplusAddresses.length;
	}
}