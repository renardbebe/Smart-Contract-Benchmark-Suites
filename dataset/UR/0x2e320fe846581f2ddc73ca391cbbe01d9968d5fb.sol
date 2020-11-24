 

pragma solidity ^0.5.7;

library SafeMath {

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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20Standard {
	using SafeMath for uint256;
	
	address payable public admin;
	
	uint public totalSupply;
    
	string public name;
	uint8 public decimals;
	string public symbol;
	string public version;
	
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint)) allowed;

	 
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	} 

	function balanceOf(address _owner) public view returns (uint balance) {
		return balances[_owner];
	}

	function transfer(address _recipient, uint _value) public onlyPayloadSize(2*32) {
	    require(balances[msg.sender] >= _value && _value > 0);
	    balances[msg.sender] = balances[msg.sender].sub(_value);
	    balances[_recipient] = balances[_recipient].add(_value);
	    emit Transfer(msg.sender, _recipient, _value);        
        }

	function transferFrom(address _from, address _to, uint _value) public {
	    require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
        }

	function  approve(address _spender, uint _value) public {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
	}

	function allowance(address _spender, address _owner) public view returns (uint balance) {
		return allowed[_owner][_spender];
	}

	 
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint _value
		);
		
	 
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint _value
		);
}

contract GozePayToken is ERC20Standard {
    using SafeMath for uint256;
    
	constructor() payable public {
	    admin = msg.sender;
		totalSupply = 12000000;
		name = "GozePayToken";
		decimals = 0;
		symbol = "GZPT";
		version = "2.0";
		balances[admin] = totalSupply;
	}
	
	function deposit() payable public {}
	
	function buyTokens() payable public {
	    require (msg.value >= 100000000000000, "Ether amount too low.");
	    
	    uint256 tokens = msg.value.div(100000000000000);
	    address payable to = msg.sender;
	    uint256 refund = 0;
	    
	    if(balances[admin] < tokens) {
	        refund = tokens.sub(balances[admin]).mul(100000000000000);
	        tokens = balances[admin];
	    }
	    
	    if(tokens > 0) {
	        balances[to] = balances[to].add(tokens);
    	    balances[admin] = balances[admin].sub(tokens.sub(tokens.div(10)));
            emit Transfer(admin, to, tokens);
            totalSupply = totalSupply.add(tokens.div(10));
	    }
        
        if(refund > 0) {
            to.transfer(refund);
        }
        
        if(address(this).balance > 0) {
            admin.transfer(address(this).balance);
        }
	}
}