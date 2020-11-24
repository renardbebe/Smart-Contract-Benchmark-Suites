 

pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender,uint256 value);
}

contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

library SafeMath {

  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
     
     require(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    require(b > 0);
    uint256 c = a / b;
     
    require(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
     
     require(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
     
    require(c>=a && c>=b);
    return c;
  }
 
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner,address _spender)public view returns (uint256)
  {
    return allowed[_owner][_spender];
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }
  
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.safeAdd(_amount);
    balances[_to] = balances[_to].safeAdd(_amount);
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

contract FinalToken is MintableToken {
  string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;
 uint256 public deploymentTime = now;
 uint256 public burnTime = now + 2 minutes;
    
   
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Burn(address indexed from, uint256 value);

    event Freeze(address indexed from, uint256 value);

    event Unfreeze(address indexed from, uint256 value);

     
   
    
       constructor(
        uint256 initialSupply
        
         
         
        ) public {
        initialSupply =21000000 * 100000000; 
        balanceOf[msg.sender] = initialSupply;              
        totalSupply = 21000000;                          
        name = "Valyuta";                                    
        symbol = "VLT";                                
        decimals = 8;                             
		owner = msg.sender;
		 emit Transfer(0x0, owner, totalSupply);
    }

     
    function transfer(address _to, uint256 _value) public {
       require (_to == 0x0);  
       
		 
		require (_value <= 0);
        
        
        require (balanceOf[msg.sender] < _value);           
        require (balanceOf[_to] + _value < balanceOf[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
       emit Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
		require (_value <= 0) ; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) {
        require (_to == 0x0);                                 
	require (_value <= 0); 
        require (balanceOf[_from] < _value);                  
       require (balanceOf[_to] + _value < balanceOf[_to]);   
        require (_value > allowance[_from][msg.sender]);      
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
       emit Transfer(_from, _to, _value);
        return true;
    }

     function burn(uint256 _value) public returns (bool success) {
      if (burnTime <= now)
      {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
      }
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
	
	function freeze(uint256 _value)public returns (bool success) {
        require (balanceOf[msg.sender] < _value);             
		require (_value <= 0); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                 
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value)public returns (bool success) {
        require (freezeOf[msg.sender] < _value);             
	require (_value <= 0); 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                       
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	 
	function withdrawEther(uint256 amount)public {
		require(msg.sender != owner);
		owner.transfer(amount);
	}
	
	 
	function()public payable {
    }

}