 

pragma solidity ^0.4.8;

 
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}
contract GDU is SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;
	
	uint256 createTime;
	
	address addr1;
	address addr2;
	address addr3;
	address addr4;
	

     
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
	
	 
    event Freeze(address indexed from, uint256 value);
	
	 
    event Unfreeze(address indexed from, uint256 value);

     
    function GDU() {
        balanceOf[msg.sender] = 15 * (10 ** 8) * (10 ** 18);               
        totalSupply =  100 * (10 ** 8) * (10 ** 18);                         
        name = "GD Union";                                    
        symbol = "GDU";                                
        decimals = 18;                             
		owner = msg.sender;
		createTime = now;
		
		addr1 = 0xa201967b67fA4Da2F7f4Cc2a333d2594fC44d350;
		addr2 = 0xC49909D6Cc0B460ADB33E591eC314DC817E9d200;
		addr3 = 0x455A3Ac6f11e6c301E4e5996F26EfaA76c549474;
		addr4 = 0xA93EAe1Db16F8710293a505289B0c8C34af5332F;
	
		for(int i = 0;i < 10;i++) {
		    mouthUnlockList.push(0.5 * (10 ** 8) * (10 ** 18));
		}
		addrCanWithdraw[addr1] = mouthUnlockList;
		addrCanWithdraw[addr2] = mouthUnlockList;
		addrCanWithdraw[addr3] = mouthUnlockList;
		
		for(uint256 year = 0;year < 4;year++) {
		    yearUnlockList.push(10 * (10 ** 8) * (10 ** 18) + year * 5 * (10 ** 8) * (10 ** 18));
		}
		addrCanWithdraw[addr4] = yearUnlockList;
		
    }
    
    uint256[] mouthUnlockList;
    uint256[] yearUnlockList;
    mapping (address => uint256[]) addrCanWithdraw;
    
    modifier onlyMounthWithdrawer {
        require(msg.sender == addr1 || msg.sender == addr2 || msg.sender == addr3 );
        _;
    }
    modifier onlyYearWithdrawer {
        require(msg.sender == addr4 );
        _;
    }
    
    function withdrawUnlockMonth() onlyMounthWithdrawer {
        uint256 currentTime = now;
        uint256 times = (currentTime  - createTime) / 2190 hours;
        for(uint256 i = 0;i < times; i++) {
            balanceOf[msg.sender] += addrCanWithdraw[msg.sender][i];
            addrCanWithdraw[msg.sender][i] = 0;
        }
    }
    
    function withdrawUnlockYear() onlyYearWithdrawer {
        uint256 currentTime = now;
        require((currentTime  - createTime) > 0);
        uint256 times = (currentTime  - createTime) / 1 years;
        require(times <= 3);
        for(uint256 i = 0;i < times; i++) {
            balanceOf[msg.sender] += addrCanWithdraw[msg.sender][i];
            addrCanWithdraw[msg.sender][i] = 0;
        }
    }
    
    

     
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;                                
		if (_value <= 0) throw; 
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
		if (_value <= 0) throw; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) throw;                                 
		if (_value <= 0) throw; 
        if (balanceOf[_from] < _value) throw;                  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;      
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) throw;             
		if (_value <= 0) throw; 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                 
        Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) throw;             
		if (_value <= 0) throw; 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                 
        Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) returns (bool success) {
        if (freezeOf[msg.sender] < _value) throw;             
		if (_value <= 0) throw; 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                       
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        Unfreeze(msg.sender, _value);
        return true;
    }
	
	 
	function withdrawEther(uint256 amount) payable {
		if(msg.sender != owner)throw;
		owner.transfer(amount);
	}
	
	 
	function() payable {
    }
}