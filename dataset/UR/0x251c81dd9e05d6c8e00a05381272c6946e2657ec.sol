 

pragma solidity ^ 0.4.15;

 
library SafeMath {

   
   
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
     
    return c;
  }

   
   
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

   
   
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
   
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }


 
contract Token {
     
    using SafeMath for uint256;

     
    string public standard = 'DSCS.GODZ.TOKEN';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function Token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;                   
        totalSupply = initialSupply;                             
        name = tokenName;                                        
        symbol = tokenSymbol;                                    
        decimals = decimalUnits;                                 
    }

     
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) revert();                                
        if (balanceOf[msg.sender] < _value) revert();            
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                         
        balanceOf[_to] = balanceOf[_to].add(_value);                                
        Transfer(msg.sender, _to, _value);                       
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function transferFromOrigin(address _to, uint256 _value)  returns (bool success) {
        address origin = tx.origin;
        if (origin == 0x0) revert();
        if (_to == 0x0) revert();                                 
        if (balanceOf[origin] < _value) revert();                 
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();   
        balanceOf[origin] = balanceOf[origin].sub(_value);        
        balanceOf[_to] = balanceOf[_to].add(_value);              
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) revert();                                 
        if (balanceOf[_from] < _value) revert();                  
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();   
        if (_value > allowance[_from][msg.sender]) revert();      
        balanceOf[_from] = balanceOf[_from].sub(_value);                               
        balanceOf[_to] = balanceOf[_to].add(_value);                                 
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

}