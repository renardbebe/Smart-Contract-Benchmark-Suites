 

pragma solidity ^0.4.24;

 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }
}

 
contract HasOwner {
     
    address public owner;

     
    address public newOwner;

     
    constructor(address _owner) internal {
        owner = _owner;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    event OwnershipTransfer(address indexed _oldOwner, address indexed _newOwner);

     
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);

        emit OwnershipTransfer(owner, newOwner);

        owner = newOwner;
    }
}

 
contract ERC20TokenInterface {
    uint256 public totalSupply;   
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
}

 
contract ERC20Token is ERC20TokenInterface {
    using SafeMath for uint256;

     
    mapping (address => uint256) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    function balanceOf(address _account) public constant returns (uint256 balance) {
        return balances[_account];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_value > 0);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

	 
	function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

		return true;
	}

	 
	function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue >= oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}

		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function () public payable {
        revert();
    }
}

 
contract Freezable is HasOwner {
    bool public frozen = false;

     
    modifier requireNotFrozen() {
        require(!frozen);
        _;
    }

     
    function freeze() onlyOwner public {
        frozen = true;
    }

     
    function unfreeze() onlyOwner public {
        frozen = false;
    }
}

 
contract FreezableERC20Token is ERC20Token, Freezable {
     
    function transfer(address _to, uint _value) public requireNotFrozen returns (bool success) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) public requireNotFrozen returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint _value) public requireNotFrozen returns (bool success) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint256 _addedValue) public requireNotFrozen returns (bool) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public requireNotFrozen returns (bool) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

 
contract BonusCloudTokenConfig {
     
    string constant NAME = "BonusCloud Token";

     
    string constant SYMBOL = "BxC";

     
    uint8 constant DECIMALS = 18;

     
    uint256 constant DECIMALS_FACTOR = 10 ** uint(DECIMALS);

     
    uint256 constant TOTAL_SUPPLY = 7000000000 * DECIMALS_FACTOR;
}

 
contract BonusCloudToken is BonusCloudTokenConfig, HasOwner, FreezableERC20Token {
     
    string public name;

     
    string public symbol;

     
    uint8 public decimals;

     
    constructor() public HasOwner(msg.sender) {
        name = NAME;
        symbol = SYMBOL;
        decimals = DECIMALS;
        totalSupply = TOTAL_SUPPLY;
        balances[owner] = TOTAL_SUPPLY;
    }
}