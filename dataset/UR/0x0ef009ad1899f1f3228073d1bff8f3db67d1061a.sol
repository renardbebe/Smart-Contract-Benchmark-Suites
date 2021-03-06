 

pragma solidity ^0.4.21;

 
contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
   }
}


contract BTBToken is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    bool public isContractFrozen;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    mapping (address => uint256) public freezeOf;

    mapping (address => string) public btbAddressMapping;


     
    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
     
    event Burn(address indexed from, uint256 value);

     
    event Freeze(address indexed from, string content);

     
    event Unfreeze(address indexed from, string content);

     
    function BTBToken() public {
        totalSupply = 10*10**26;                         
        balanceOf[msg.sender] = totalSupply;               
        name = "BiTBrothers";                                    
        symbol = "BTB";                                
        decimals = 18;                             
        owner = msg.sender;
        isContractFrozen = false;
    }

     
    function transfer(address _to, uint256 _value) external returns (bool success) {
        assert(!isContractFrozen);
        assert(_to != 0x0);                                
        assert(_value > 0);
        assert(balanceOf[msg.sender] >= _value);            
        assert(balanceOf[_to] + _value >= balanceOf[_to]);  
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
        emit Transfer(msg.sender, _to, _value);                    
        return true;
    }

     
    function approve(address _spender, uint256 _value) external returns (bool success) {
        assert(!isContractFrozen);
        assert(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        assert(!isContractFrozen);
        assert(_to != 0x0);                                 
        assert(_value > 0);
        assert(balanceOf[_from] >= _value);                  
        assert(balanceOf[_to] + _value >= balanceOf[_to]);   
        assert(_value <= allowance[_from][msg.sender]);      
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) external returns (bool success) {
        assert(!isContractFrozen);
        assert(msg.sender == owner);
        assert(balanceOf[msg.sender] >= _value);             
        assert(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                 
        emit Burn(msg.sender, _value);
        return true;
    }
	
    function freeze() external returns (bool success) {
        assert(!isContractFrozen);
        assert(msg.sender == owner);
        isContractFrozen = true;
        emit Freeze(msg.sender, "contract is frozen");
        return true;
    }
	
    function unfreeze() external returns (bool success) {
        assert(isContractFrozen);
        assert(msg.sender == owner);
        isContractFrozen = false;
        emit Unfreeze(msg.sender, "contract is unfrozen");
        return true;
    }

    function setBTBAddress(string btbAddress) external returns (bool success) {
        assert(!isContractFrozen);
        btbAddressMapping[msg.sender] = btbAddress;
        return true;
    }
     
    function withdrawEther(uint256 amount) external {
        assert(msg.sender == owner);
        owner.transfer(amount);
    }
	
     
    function() public payable {
    }
}