 

pragma solidity ^0.4.17;


 
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

contract IKanCoin is PausableToken {
	function releaseTeam() public returns (bool);
	function fund(address _funder, uint256 _amount) public returns (bool);
	function releaseFund(address _funder) public returns (bool);
	function freezedBalanceOf(address _owner) public view returns (uint256 balance);
	function burn(uint256 _value) public returns (bool);

	event ReleaseTeam(address indexed team, uint256 value);
	event Fund(address indexed funder, uint256 value);
	event ReleaseFund(address indexed funder, uint256 value);
}

contract KanCoin is IKanCoin {
	string public name = 'KAN';
	string public symbol = 'KAN';
	uint8 public decimals = 18;
	uint256 public INITIAL_SUPPLY = 10000000000 * 10 ** uint256(decimals); 
	mapping(address => uint256) freezedBalances; 
	mapping(address => uint256) fundings; 
	uint256 fundingBalance;
	address launch; 
	uint256 teamBalance; 

	function KanCoin(address _launch) public {
		launch = _launch;
		totalSupply_ = INITIAL_SUPPLY;
		teamBalance = INITIAL_SUPPLY.mul(2).div(10);  
		fundingBalance = INITIAL_SUPPLY.mul(45).div(100);  
		balances[launch] = INITIAL_SUPPLY.mul(35).div(100);  
	}

	function releaseTeam() public onlyOwner returns (bool) {
		require(teamBalance > 0); 
		uint256 amount = INITIAL_SUPPLY.mul(4).div(100);  
		teamBalance = teamBalance.sub(amount); 
		balances[owner] = balances[owner].add(amount); 
		ReleaseTeam(owner, amount);
		return true;
	}

	function fund(address _funder, uint256 _amount) public onlyOwner returns (bool) {
		require(_funder != address(0));
		require(fundingBalance >= _amount); 
		fundingBalance = fundingBalance.sub(_amount); 
		balances[_funder] = balances[_funder].add(_amount); 
		freezedBalances[_funder] = freezedBalances[_funder].add(_amount); 
		fundings[_funder] = fundings[_funder].add(_amount); 
		Fund(_funder, _amount);
		return true;
	}

	function releaseFund(address _funder) public onlyOwner returns (bool) {
		require(freezedBalances[_funder] > 0); 
		uint256 fundReleaseRate = freezedBalances[_funder] == fundings[_funder] ? 25 : 15; 
		uint256 released = fundings[_funder].mul(fundReleaseRate).div(100); 
		freezedBalances[_funder] = released < freezedBalances[_funder] ? freezedBalances[_funder].sub(released) : 0; 
		ReleaseFund(_funder, released);
		return true;
	}

	function freezedBalanceOf(address _owner) public view returns (uint256 balance) {
		return freezedBalances[_owner];
	}

	function burn(uint256 _value) public onlyOwner returns (bool) {
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[address(0)] = balances[address(0)].add(_value); 
		Transfer(msg.sender, address(0), _value);
		return true;
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_value <= balances[msg.sender] - freezedBalances[msg.sender]); 
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_value <= balances[_from] - freezedBalances[_from]); 
		return super.transferFrom(_from, _to, _value);
	}
}