 

pragma solidity ^0.4.18;
contract Hurify {
 
string public name = "Hurify Token";                   
string public symbol = "HUR";                          
uint public decimals = 18;                             
address public owner;                                  
uint256 totalHurify;                                   
uint256 totalToken;                                    
bool public hault = false;                             
  
mapping (address => uint256) balances;
mapping (address => mapping (address => uint256)) allowed;
 
event Transfer(address indexed from, address indexed to, uint256 value);
 
 event Burn(address _from, uint256 _value);
 event Approval(address _from, address _to, uint256 _value);
 
function Hurify (
  address _hurclan
  ) public {
   owner = msg.sender;                                             
   balances[msg.sender] = 212500000 * (10 ** decimals);             
   totalHurify = 273125000 * (10 ** decimals);
   balances[_hurclan] = safeAdd(balances[_hurclan], 53125000 * (10 ** decimals));
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
modifier onlyPayloadSize(uint size) {
   require(msg.data.length >= size + 4) ;
   _;
}
modifier onlyowner {
  require (owner == msg.sender);
  _;
}
 
function tokensup(uint256 _value) onlyowner public{
  totalHurify = safeAdd(totalHurify, _value * (10 ** decimals));
  balances[owner] = safeAdd(balances[owner], _value * (10 ** decimals));
}
 
function hurifymint( address _client, uint _value, uint _type) onlyowner public {
  uint numHur;
  require(totalToken <= totalHurify);
  if(_type == 1){
      numHur = _value * 6000 * (10 ** decimals);
  }
  else if (_type == 2){
      numHur = _value * 5000 * (10 ** decimals);
  }
  balances[owner] = safeSub(balances[owner], numHur);
  balances[_client] = safeAdd(balances[_client], numHur);
  totalToken = safeAdd(totalToken, numHur);
  Transfer(owner, _client, numHur);
}
 
function hurmint( address _client, uint256 _value) onlyowner public {
  require(totalToken <= totalHurify);
  uint256 numHur = _value * ( 10 ** decimals);
  balances[owner] = safeSub(balances[owner], numHur);
  balances[_client] = safeAdd(balances[_client], numHur);
  totalToken = safeAdd(totalToken, numHur);
  Transfer(owner, _client, numHur);
}
 
 
 
function transfer(address _to, uint256 _value) public returns (bool success) {
    require(!hault);
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = safeSub(balances[msg.sender],_value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
}
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      if (balances[_from] < _value || allowed[_from][msg.sender] < _value) {
           
          revert();
      }
      require(!hault);
      balances[_to] = safeAdd(balances[_to], _value);
      balances[_from] = safeSub(balances[_from],_value);
      allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
      Transfer(_from, _to, _value);
      return true;
}
 
 
 
 
function approve(address _spender, uint256 _value)
    public
    returns (bool)
{
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
}
 
 
 
 
function allowance(address _owner, address _spender)
    constant
    public
    returns (uint256)
{
    return allowed[_owner][_spender];
}
 
 
function balanceOf(address _from) public view returns (uint balance) {
    return balances[_from];
  }

 
function totalSupply() public view returns (uint Supply){
  return totalHurify;
}
 
function pauseable() public onlyowner {
    hault = true;
  }
 
function unpause() public onlyowner {
    hault = false;
}

 
function burn(uint256 _value) onlyowner public returns (bool success) {
    require (balances[msg.sender] >= _value);                                           
    balances[msg.sender] = safeSub(balances[msg.sender], _value);                       
    totalHurify = safeSub(totalHurify, _value);                                         
    Burn(msg.sender, _value);
    return true;
}
}