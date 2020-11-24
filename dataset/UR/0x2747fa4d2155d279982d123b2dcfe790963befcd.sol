 

pragma solidity ^0.5.3;

contract Ownable {
    address public owner;

    event OwnerLog(address indexed previousOwner, address indexed newOwner, bytes4 sig);

    constructor() public { 
        owner = msg.sender; 
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner  public {
        require(newOwner != address(0));
        emit OwnerLog(owner, newOwner, msg.sig);
        owner = newOwner;
    }
}

contract WEPSPaused is Ownable {

    bool public pauesed = false;

    modifier isNotPaued {
        require (!pauesed);
        _;
    }
    function stop() onlyOwner public {
        pauesed = true;
    }
    function start() onlyOwner public {
        pauesed = false;
    }
}

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
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;
    uint256 internal totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function _transfer(address _sender, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[_sender] = balances[_sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_sender, _to, _value);
    
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}



 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) blackList;
	
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(blackList[msg.sender] <= 0);
		return _transfer(msg.sender, _to, _value);
	}
 

     
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

contract PausableToken is StandardToken, WEPSPaused {

    function transfer(address _to, uint256 _value) public isNotPaued returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public isNotPaued returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public isNotPaued returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public isNotPaued returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public isNotPaued returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract WEPSToken is PausableToken {
    string public constant name = "WE PLATFORM TOKEN";
    string public constant symbol = "WEPS";
    uint public constant decimals = 18;
    using SafeMath for uint256;

    event Burn(address indexed from, uint256 value);  
    event BurnFrom(address indexed from, uint256 value);  

    constructor (uint256 _totsupply) public {
		totalSupply_ = _totsupply.mul(1e18);
        balances[msg.sender] = totalSupply_;
    }

    function transfer(address _to, uint256 _value) isNotPaued public returns (bool) {
        if(isBlackList(_to) == true || isBlackList(msg.sender) == true) {
            revert();
        } else {
            return super.transfer(_to, _value);
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) isNotPaued public returns (bool) {
        if(isBlackList(_to) == true || isBlackList(msg.sender) == true) {
            revert();
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }
    
    function burn(uint256 value) public {
        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply_ = totalSupply_.sub(value);
        emit Burn(msg.sender, value);
    }
    
    function burnFrom(address who, uint256 value) public onlyOwner payable returns (bool) {
        balances[who] = balances[who].sub(value);
        balances[owner] = balances[owner].add(value);

        emit BurnFrom(who, value);
        return true;
    }
	
	function setBlackList(bool bSet, address badAddress) public onlyOwner {
		if (bSet == true) {
			blackList[badAddress] = now;
		} else {
			if ( blackList[badAddress] > 0 ) {
				delete blackList[badAddress];
			}
		}
	}
	
    function isBlackList(address badAddress) public view returns (bool) {
        if ( blackList[badAddress] > 0 ) {
            return true;
        }
        return false;
    }
}