 

pragma solidity ^0.4.25;
 
contract ERC20Interface {
  string public name;            
  string public symbol;          
  uint8 public  decimals;        
  uint public totalSupply;       
   
  function transfer(address _to, uint256 _value) returns (bool success);
   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
   
  function approve(address _spender, uint256 _value) returns (bool success);
   
  function allowance(address _owner, address _spender) view returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract ERC20 is ERC20Interface{
    mapping(address => uint256) public balanceOf; 
    mapping(address =>mapping(address => uint256)) allowed;
    constructor(string _name,string _symbol,uint8 _decimals,uint _totalSupply) public{
         name = _name;                           
         symbol = _symbol;                       
         decimals = _decimals;                    
         totalSupply = _totalSupply * 10 ** uint256(decimals);             
         balanceOf[msg.sender]=_totalSupply;
    }
    
  function transfer(address _to, uint256 _value) public returns (bool success){
      require(_to!=address(0)); 
      require(balanceOf[msg.sender] >= _value);
      require(balanceOf[_to] + _value >=balanceOf[_to]);
      balanceOf[msg.sender]-=_value;
      balanceOf[_to]+=_value;
      emit Transfer(msg.sender,_to,_value); 
      return true;
  }
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
      require(_to!=address(0));
      require(balanceOf[_from]>=_value);
      require(balanceOf[_to]+_value>balanceOf[_to]);
      require(allowed[_from][msg.sender]>_value);
      balanceOf[_from]-=_value;
      balanceOf[_to]+=_value;
      allowed[_from][msg.sender]-=_value;
      emit Transfer(_from,_to,_value);
      return true;
  }
   
  function approve(address _spender, uint256 _value) public returns (bool success){
      allowed[msg.sender][_spender] = _value;
      emit Approval(msg.sender,_spender,_value);
      return true;
  }
   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining){
      return allowed[_owner][_spender];
  }
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract owned{
    address public owner;
    constructor() public{
        owner=msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender==owner);
        _;
    }
    function transferOwnerShip(address newOwner) public onlyOwner{
        owner=newOwner;
    }
}
 
contract CAR is ERC20,owned {
    mapping(address => bool) public frozenAccount; 
    event AddSupply(uint256 amount); 
    event FrozenFunds(address target,bool freeze); 
    event Burn(address account,uint256 values);
     
    constructor(string _name,string _symbol,uint8 _decimals,uint _totalSupply) ERC20 ( _name,_symbol, _decimals,_totalSupply) public{
    }
     
    function mine(address target,uint256 amount) public onlyOwner{
        totalSupply+=amount;
        balanceOf[target]+=amount;
        emit AddSupply(amount); 
        emit Transfer(0,target,amount);
    }
     
    function freezeAccount(address target,bool freeze) public onlyOwner{
        frozenAccount[target]=freeze;
        emit FrozenFunds(target,freeze);
    }
        
  function transfer(address _to, uint256 _value) public returns (bool success){
      require(!frozenAccount[msg.sender]); 
      require(_to!=address(0)); 
      require(balanceOf[msg.sender] >= _value);
      require(balanceOf[_to] + _value >=balanceOf[_to]);
      balanceOf[msg.sender]-=_value;
      balanceOf[_to]+=_value;
      emit Transfer(msg.sender,_to,_value); 
      return true;
  }
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
      require(!frozenAccount[msg.sender]); 
      require(_to!=address(0));
      require(balanceOf[_from]>=_value);
      require(balanceOf[_to]+_value>balanceOf[_to]);
      require(allowed[_from][msg.sender]>_value);
      balanceOf[_from]-=_value;
      balanceOf[_to]+=_value;
      allowed[_from][msg.sender]-=_value;
      emit Transfer(_from,_to,_value);
      return true;
  }
   
  function burn(uint256 values) public returns(bool success){
      require(balanceOf[msg.sender]>=values);
      totalSupply-=values;
      balanceOf[msg.sender]-=values;
      emit Burn(msg.sender,values);
      return true;
  }
}