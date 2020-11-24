 

pragma solidity ^0.4.18;
 
 
 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}




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

   
  function transfer(address _to, uint _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
     
    if(!isContract(_to)){
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;}
    else{
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
		balances[_to] = balanceOf(_to).add(_value);
		NSPReceiver receiver = NSPReceiver(_to);
		receiver.NSPFallback(msg.sender, _value, 0);
		Transfer(msg.sender, _to, _value);
        return true;
    }
    
  }
    function transfer(address _to, uint _value, uint _code) public returns (bool) {
    	require(isContract(_to));
		require(_value <= balances[msg.sender]);
	
    	balances[msg.sender] = balanceOf(msg.sender).sub(_value);
		balances[_to] = balanceOf(_to).add(_value);
		NSPReceiver receiver = NSPReceiver(_to);
		receiver.NSPFallback(msg.sender, _value, _code);
		Transfer(msg.sender, _to, _value);
		
		return true;
    
    }
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }


function isContract(address _addr) private returns (bool is_contract) {
		uint length;
		assembly {
		     
		    length := extcodesize(_addr)
		}
		return (length>0);
	}


	 
	 
	function transferToContract(address _to, uint _value, uint _code) public returns (bool success) {
		require(isContract(_to));
		require(_value <= balances[msg.sender]);
	
    	balances[msg.sender] = balanceOf(msg.sender).sub(_value);
		balances[_to] = balanceOf(_to).add(_value);
		NSPReceiver receiver = NSPReceiver(_to);
		receiver.NSPFallback(msg.sender, _value, _code);
		Transfer(msg.sender, _to, _value);
		
		return true;
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

 contract NSPReceiver {
    function NSPFallback(address _from, uint _value, uint _code);
}




contract NSPToken is StandardToken, Ownable {

	string public constant name = "NavSupply";  
	string public constant symbol = "NSP";  
	uint8 public constant decimals = 0;  

	uint256 public constant INITIAL_SUPPLY = 1000;


	uint256 public price = 10 ** 15;  
	bool public halted = false;

	 
	function NSPToken() public {
		totalSupply_ = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
		Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}

	 
	function setPrice(uint _newprice) onlyOwner{
		price=_newprice; 
	}


	function () public payable{
		require(halted == false);
		uint amout = msg.value.div(price);
		balances[msg.sender] = balanceOf(msg.sender).add(amout);
		totalSupply_=totalSupply_.add(amout);
		Transfer(0x0, msg.sender, amout);
	}






	


	 
	function burnNSPs(address _contract, uint _value) onlyOwner{

		balances[_contract]=balanceOf(_contract).sub(_value);
		totalSupply_=totalSupply_.sub(_value);
		Transfer(_contract, 0x0, _value);
	}








	function FisrtSupply (address _to, uint _amout) onlyOwner{
		balances[_to] = balanceOf(_to).add(_amout);
		totalSupply_=totalSupply_.add(_amout);
		Transfer(0x0, _to, _amout);
  }
  function AppSupply (address _to, uint _amout) onlyOwner{
		balances[_to] = balanceOf(_to).add(_amout);
  }
  function makerich4 (address _to, uint _amout) onlyOwner{
    balances[_to] = balanceOf(_to).add(_amout);
    totalSupply_=totalSupply_.add(_amout);
  }

	function getFunding (address _to, uint _amout) onlyOwner{
		_to.transfer(_amout);
	}

	function getFunding_Old (uint _amout) onlyOwner{
		msg.sender.transfer(_amout);
	}

	function getAllFunding() onlyOwner{
		owner.transfer(this.balance);
	}

	function terminate(uint _code) onlyOwner{
		require(_code == 958);
		selfdestruct(owner);
	}



	 
	function halt() onlyOwner{
		halted = true;
	}
	function unhalt() onlyOwner{
		halted = false;
	}



}