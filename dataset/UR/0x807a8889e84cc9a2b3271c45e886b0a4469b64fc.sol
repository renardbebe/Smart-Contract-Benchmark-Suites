 

pragma solidity ^0.4.24;

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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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

contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
	

}

contract VoteToken is HasNoEther, BurnableToken {
	
    struct stSuggestion {
		string  text;	 
		uint256 total_yes;	 
		uint256 total_no;	 
		uint256 timeStop;  
		bool 	finished;
		uint	voters_count;
		mapping(uint 	 => address) voters_addrs;  
		mapping(address  => uint256) voters_value;  
    }
	
	 
	uint lastID;
    mapping (uint => stSuggestion) suggestions;
	
	 
    uint256 public Price;
	
	function setSuggPrice( uint256 newPrice ) public onlyOwner 
    {
        Price = newPrice;
    }

	function getListSize() public view returns (uint count) 
    {
        return lastID;
    }
	
	function addSuggestion(string s, uint  forDays) public returns (uint newID)
    {
        require ( Price <= balances[msg.sender] );
       
		newID = lastID++;
        suggestions[newID].text = s;
        suggestions[newID].total_yes = 0;
        suggestions[newID].total_no  = 0;
        suggestions[newID].timeStop =  now + forDays * 1 days;
        suggestions[newID].finished = false;
        suggestions[newID].voters_count = 0;

		balances[msg.sender] = balances[msg.sender].sub(Price);
        totalSupply = totalSupply.sub(Price);
    }
	
	function getSuggestion(uint id) public constant returns(string, uint256, uint256, uint256, bool, uint )
    {
		require ( id <= lastID );
        return (
            suggestions[id].text,
            suggestions[id].total_yes,
            suggestions[id].total_no,
            suggestions[id].timeStop,
            suggestions[id].finished,
            suggestions[id].voters_count
            );
    } 
	
	function isSuggestionNeedToFinish(uint id) public view returns ( bool ) 
    {
		if ( id > lastID ) return false;
		if ( suggestions[id].finished ) return false;
		if ( now <= suggestions[id].timeStop ) return false;
		
        return true;
    } 
	
	function finishSuggestion( uint id ) public onlyOwner returns (bool)
	{
	    
		if ( !isSuggestionNeedToFinish(id) ) return false;
		
		uint i;
		address addr;
		uint256 val;
		for ( i = 1; i <= suggestions[id].voters_count; i++){
			addr = suggestions[id].voters_addrs[i];
			val  = suggestions[id].voters_value[addr];
			
			balances[addr] = balances[addr].add( val );
			totalSupply = totalSupply.add( val );
			
			suggestions[id].voters_value[addr] = 0;
		}
		suggestions[id].finished = true;
		
		return true;
	}
	
	function Vote( uint id, bool MyVote, uint256 Value ) public returns (bool)
	{
		if ( id > lastID ) return false;
		if ( Value > balances[msg.sender] ) return false;
		if ( suggestions[id].finished ) return false;
	
		if (MyVote)
			suggestions[id].total_yes += Value;
		else
			suggestions[id].total_no  += Value;
		
		suggestions[id].voters_count++;
		suggestions[id].voters_addrs[ suggestions[id].voters_count ] = msg.sender;
		suggestions[id].voters_value[msg.sender] = suggestions[id].voters_value[msg.sender].add(Value);
		
		balances[msg.sender] = balances[msg.sender].sub(Value);
		
		totalSupply = totalSupply.sub(Value);
		
		return true;
	}
	
	
}



contract YourVoteMatters is VoteToken {

    string public constant name = "Your Vote Matters";
    string public constant symbol = "YVM";
    uint8 public constant decimals = 18;
	string public constant version = "YVM version: 1.7";
    uint256 constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));

     
    function YourVoteMatters() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(address(0), msg.sender, totalSupply);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function multiTransfer(address[] recipients, uint256[] amounts) public {
        require(recipients.length == amounts.length);
        for (uint i = 0; i < recipients.length; i++) {
            transfer(recipients[i], amounts[i]);
        }
    }
	
	 
    function mintToken(uint256 mintedAmount) public onlyOwner {
			totalSupply += mintedAmount;
			balances[owner] += mintedAmount;
			Transfer(address(0), owner, mintedAmount);
    }
}