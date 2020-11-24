 

pragma solidity ^0.4.18;



contract AimiToken {
     
    string public name = "艾米币"; 
    string public symbol = "AT";  
    uint8 public decimals = 8;  
    uint256 public _totalSupply ;  
     mapping(address => uint256) balances;
     
    mapping(address=>bool) public frozenATAccount;
    event Approval(address indexed owner, address indexed spender, uint256 value);
    bool  transfersEnabled = false ; 
    mapping (address => mapping (address => uint256)) internal allowed;
    address public owner;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(frozenATAccount[_to]==false);
    require(frozenATAccount[msg.sender]==false);
    require(transfersEnabled==true);
    balances[_from] = sub(balances[_from],_value);
    balances[_to] = add(balances[_to],_value);
    allowed[_from][msg.sender] = sub(allowed[_from][msg.sender],_value);
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

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = add(allowed[msg.sender][_spender],_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = sub(oldValue,_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(frozenATAccount[_to]==false);
    require(frozenATAccount[msg.sender]==false);
    require(transfersEnabled==true);
     
    balances[msg.sender] = sub(balances[msg.sender],_value);
    balances[_to] = add(balances[_to],_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
   
    function totalSupply() public view returns (uint256) {
       return _totalSupply;
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
  
  
  
  
    
     
     
    function AimiToken(address _sentM,uint256 __totalSupply) public payable{
         
        if(_sentM !=0){
            owner = _sentM;
        }
        if(__totalSupply!=0){
            _totalSupply = __totalSupply;
        }
         
        balances[owner] = _totalSupply;
   
    }
 
 function frozenAccount(address froze_address) public onlyOwner{
     frozenATAccount[froze_address]=true;
 } 
  function unfrozenATAccount(address unfroze_address) public onlyOwner{
     frozenATAccount[unfroze_address]=false;
 } 
 
   function openTransfer() public onlyOwner{
    transfersEnabled=true;
 } 
   function closeTransfer() public onlyOwner{
     transfersEnabled=true;
 } 
}