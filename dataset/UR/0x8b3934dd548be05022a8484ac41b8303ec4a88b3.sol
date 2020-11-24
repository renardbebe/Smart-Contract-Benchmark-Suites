 

 

pragma solidity ^0.4.24;


 
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
 
 
contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    
    uint256 public price = 5000;
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    address agent;
    address finance;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        uint256 _allowance = allowed[_from][msg.sender];

         
         
		balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
       
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  
  function buy() payable public{
    uint256 value = price.mul(msg.value);
    require(value <= balances[agent]);
    balances[agent] = balances[agent].sub(value);
    balances[msg.sender] = balances[msg.sender].add(value);
    emit Transfer(agent, msg.sender, value);
    finance.transfer(msg.value);
  }
  
  function () payable public{
      buy();
  }
  
  function withdrawal () public{
    require(owner == msg.sender);
    msg.sender.transfer(address(this).balance);
  }
	
}

 
contract XDO is StandardToken {
    

	function setPrice(uint256 price_) public {
	   require(owner == msg.sender);
       price = price_;
	}
	
	function setAgent(address agent_) public {
	    require(owner == msg.sender);
	    balances[agent_] = balances[agent];
	    balances[agent] = 0;
	}
	
	function setFinance(address finance_) public {
	    require(owner == msg.sender);
	    finance = finance_;
	}
	
	function setOwner(address owner_) public {
	    require(owner == msg.sender);
	    owner = owner_;
	}
	
    constructor (uint256 total_,string name_,string symbol_,uint8 decimals_,address agent_) public {
        agent = agent_;
        finance = agent_;
        owner = msg.sender;
        balances[agent_] = total_;
		totalSupply = total_;
		name = name_;
		symbol = symbol_;
		decimals = decimals_;
    }
}