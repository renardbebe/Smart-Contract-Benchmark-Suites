 

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


contract SafeMath {  
    uint256 constant public MAX_UINT256 =0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

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
    assert(c >= a);
    return c;
  }
}

contract MITToken is SafeMath{
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
    address public owner;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    mapping(uint => Holder) public lockholders;
    uint public lockholderNumber;
    struct Holder {
          address eth_address;
          uint exp_time;
         
      }
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
  constructor () public {
        totalSupply = 10000000000 * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = "Mundellian Infrastructure Technology";                                    
        symbol = "MIT";                                
        
         owner = msg.sender;
    }
  
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
        
        require(validHolder(_from));
        
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] <= MAX_UINT256 - _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
         
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
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
    
function _lockToken(address addr,uint expireTime) public payable returns (bool) {
    require(msg.sender == owner);
    for(uint i = 0; i < lockholderNumber; i++) {
      if (lockholders[i].eth_address == addr) {
          lockholders[i].exp_time = expireTime;
        return true;
      }
    }
    lockholders[lockholderNumber]=Holder(addr,expireTime);
    lockholderNumber++;
    return true;
  }
  
function _unlockToken(address addr) public payable returns (bool){
    require(msg.sender == owner);
    for(uint i = 0; i < lockholderNumber; i++) {
      if (lockholders[i].eth_address == addr) {
          delete lockholders[i];
        return true;
      }
    }
    return true;
  }
  
  function validHolder(address addr) public constant returns (bool) {
    for(uint i = 0; i < lockholderNumber; i++) {
      if (lockholders[i].eth_address == addr && now <lockholders[i].exp_time) {
        return false;
      }
    }
    return true;
  }
}