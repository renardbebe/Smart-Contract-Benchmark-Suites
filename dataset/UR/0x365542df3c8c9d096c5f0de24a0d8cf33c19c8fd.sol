 

 

pragma solidity ^0.4.25;
 
 
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
 constructor() public  {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_ = 0;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
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
    emit  Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit  Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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
		emit Mint(_to, _amount);
		emit Transfer(address(0), _to, _amount);
		return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract HSN is MintableToken {

    using SafeMath for uint256;
    string public name = "Hyper Speed Network";
    string public   symbol = "HSN";
    uint public   decimals = 8;
    bool public  TRANSFERS_ALLOWED = false;
    uint256 public MAX_TOTAL_SUPPLY = 1000000000 * (10 **8);


    struct LockParams {
        uint256 TIME;
        address ADDRESS;
        uint256 AMOUNT;
    }

     
    mapping(address => LockParams[]) private locks; 

    event Burn(address indexed burner, uint256 value);

    function burnFrom(uint256 _value, address victim) onlyOwner canMint public{
        require(_value <= balances[victim]);

        balances[victim] = balances[victim].sub(_value);
        totalSupply_ = totalSupply().sub(_value);

        emit Burn(victim, _value);
    }

    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply().sub(_value);

        emit Burn(msg.sender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public validAddress(_to) returns (bool) {
        require(TRANSFERS_ALLOWED || msg.sender == owner);
        require(canBeTransfered(_from, _value));

        return super.transferFrom(_from, _to, _value);
    }


    function lock(address _to, uint256 releaseTime, uint256 lockamount) onlyOwner public returns (bool) {

         
         
         
         
         

        LockParams memory lockdata;
        lockdata.TIME = releaseTime;
        lockdata.AMOUNT = lockamount;
        lockdata.ADDRESS = _to;

        locks[_to].push(lockdata);

        return true;
    }

    function canBeTransfered(address _addr, uint256 value) public view validAddress(_addr) returns (bool){
		uint256 total = 0;
        for (uint i=0; i < locks[_addr].length; i++) {
            if (locks[_addr][i].TIME > now && locks[_addr][i].ADDRESS == _addr){					
				total = total.add(locks[_addr][i].AMOUNT);                
            }
        }
		
		if ( value > balanceOf(_addr).sub(total)){
            return false;
        }
        return true;
    }

	function gettotalHold(address _addr) public view validAddress(_addr) returns (uint256){
		require( msg.sender == _addr || msg.sender == owner);
		
	    uint256 total = 0;
		for (uint i=0; i < locks[_addr].length; i++) {
			if (locks[_addr][i].TIME > now && locks[_addr][i].ADDRESS == _addr){					
				total = total.add(locks[_addr][i].AMOUNT);                
			}
		}
			
		return total;
	}

    function mint(address _to, uint256 _amount) public validAddress(_to) onlyOwner canMint returns (bool) {
		
        if (totalSupply_.add(_amount) > MAX_TOTAL_SUPPLY){
            return false;
        }

        return super.mint(_to, _amount);
    }


    function transfer(address _to, uint256 _value) public validAddress(_to) returns (bool){
        require(TRANSFERS_ALLOWED || msg.sender == owner);
        require(canBeTransfered(msg.sender, _value));

        return super.transfer(_to, _value);
    }

    function stopTransfers() onlyOwner public{
        TRANSFERS_ALLOWED = false;
    }

    function resumeTransfers() onlyOwner public{
        TRANSFERS_ALLOWED = true;
    }
	
	function removeHoldByAddress(address _address) public onlyOwner {      
        delete locks[_address];                 
		locks[_address].length = 0; 
    }

    function removeHoldByAddressIndex(address _address, uint256 _index) public onlyOwner {
		if (_index >= locks[_address].length) return;
		
		for (uint256 i = _index; i < locks[_address].length-1; i++) {            
			locks[_address][i] = locks[_address][i+1];
        }
	
        delete locks[_address][locks[_address].length-1];
		locks[_address].length--;
    }
	
	function isValidAddress(address _address) public view returns (bool) {
        return (_address != 0x0 && _address != address(0) && _address != 0 && _address != address(this));
    }

    modifier validAddress(address _address) {
        require(isValidAddress(_address)); 
        _;
    }
    
    function getlockslen(address _address) public view onlyOwner returns (uint256){
        return locks[_address].length;
    }
     
    function getlocksbyindex(address _address, uint256 _index) public view returns (uint256 TIME,address ADDRESS,uint256 AMOUNT){
		require( msg.sender == _address || msg.sender == owner);
        return (locks[_address][_index].TIME,locks[_address][_index].ADDRESS,locks[_address][_index].AMOUNT);
    }    

}