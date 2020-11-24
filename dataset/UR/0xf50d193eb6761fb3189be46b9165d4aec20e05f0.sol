 

pragma solidity ^0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract FLEBToken{
    
 address public owner;
 string public name = "FLEBToken";  
 string public symbol = "FLB";
 uint8 public decimals = 8;        
 uint256 public totalSupply = 0; 
 
 mapping(address => uint256) balances;
 mapping(address => mapping(address => uint256)) internal allowed;  
 
 
 constructor() public{
     owner = msg.sender;
 } 
 
 
 function changeOwner(address _addr) public{
     
     require(owner == msg.sender);
     owner = _addr;
 }
   
 function transfer(address _to, uint256 _value) public returns (bool) {
     require(_to != address(0));
     require(_value <= balances[msg.sender]);
     
     balances[msg.sender] = balances[msg.sender] - _value;
     balances[_to] = balances[_to] + _value;
     emit Transfer(msg.sender, _to, _value);
     
     return true;
}

function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
}

  
function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
     require(_to != address(0));
     require(_value <= balances[_from]);
     require(_value <= allowed[_from][msg.sender]);
     
     balances[_from] = balances[_from] - _value;
     balances[_to] = balances[_to] + _value;
     
     allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
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

  
 
function approveAndCall(address _spender, uint256 _value, bytes _extraData)  public returns (bool success) {
    
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }
}
 
    
 function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
  }
  
    
 function burnFrom(address _from, uint256 _value) public returns (bool success) {
      require(balances[_from] >= _value);                 
      require(_value <= allowed[_from][msg.sender]);     
      balances[_from] -= _value;                          
      allowed[_from][msg.sender] -= _value;              
      totalSupply -= _value;                             
      emit Burn(_from, _value);
      return true;
 }
 
 function mint(address _to, uint256 _amount) public returns (bool) {
     require(msg.sender == owner);
     
     totalSupply = totalSupply + _amount;
     balances[_to] = balances[_to] + _amount;
     
     emit Mint(_to, _amount);
     emit Transfer(address(0), _to, _amount);
     
     return true;
 }
 
 function mintSub(address _to,uint256 _amount) public returns (bool){
     
     require(msg.sender == owner);
     require(balances[msg.sender] >= _amount && balances[msg.sender] != 0 );
     
     totalSupply = totalSupply - _amount;
     balances[_to] = balances[_to] - _amount;
     
     emit Mint(_to,_amount);
     emit Transfer(address(0), _to,_amount);
     
     return true;
     
 }
 
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
 event Mint(address indexed to, uint256 amount); 
  
 event Burn(address indexed from, uint256 value);
 
}