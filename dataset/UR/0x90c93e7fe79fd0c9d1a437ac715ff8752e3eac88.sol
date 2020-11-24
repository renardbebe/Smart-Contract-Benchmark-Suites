 

pragma solidity ^0.4.24;
 
 
 

library SafeMath {                              
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) { return 0; }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract QurozToken {
  using SafeMath for uint256;
  address public owner;                                               
  string public name = "Qfora";                                       
  string public symbol = "Quroz";                                     
  string public version = "Quroz v1.1";               
  uint256 public decimals = 18;                                         
  uint256 totalSupply_ = 12e8 * (10**uint256(decimals));              
  uint256 public cap = totalSupply_;                                  
  bool public paused = false;                                          
  bool public mintingFinished = true;                                 
  mapping(address => uint256) balances;                               
  mapping(address => mapping (address => uint256)) internal allowed;  
  mapping(address => bool) internal locked;           
  event Burn(address indexed burner, uint256 value);                                
  event Approval(address indexed owner, address indexed spender,uint256 value);     
  event Transfer(address indexed from, address indexed to, uint256 value);          
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);  
  event Pause();                                                                    
  event Unpause();                                                                  
  event Mint(address indexed to, uint256 amount, string reason);                    
  event MintFinished();                                                             
  event MintStarted(string reason);                       
  event Lock(address indexed LockedAddress);              
  event Unlock(address indexed LockedAddress);            
  event CapChange(uint256 Cap, string reason);            

  constructor() public { 
    owner = msg.sender;
    balances[owner] = totalSupply_ ;
  }

  modifier onlyOwner()         {require(msg.sender == owner); _;}   
  modifier whenPaused()        {require(paused); _; }               
  modifier whenNotPaused()     {require(!paused); _;}               
  modifier canMint()           {require(!mintingFinished); _;}      
  modifier cannotMint()        {require(mintingFinished); _;}       
  modifier hasMintPermission() {require(msg.sender == owner);  _;}  

  function balanceOf(address _owner) public view returns (uint256) {   
    return balances[_owner];
  }

  function totalSupply() public view returns (uint256) {   
    return totalSupply_;
  }
  
  function burn(uint256 _value) public {  
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {   
    require(_value <= balances[_who]);
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
  
  function burnFrom(address _from, uint256 _value) public {   
    require(_value <= allowed[_from][msg.sender]);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
  
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
       
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {  
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint256 _addedValue) public whenNotPaused returns(bool){
       
    allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) public whenNotPaused returns(bool) {
       
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) { allowed[msg.sender][_spender] = 0;
    } else                           { allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);}
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) { 
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(locked[msg.sender] != true);                                                              
    require(locked[_to] != true);                                                                     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns(bool) {  
       
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(locked[_from] != true);                                                              
    require(locked[_to] != true);                                                                
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function transferOwnership(address _newOwner) public onlyOwner {    
    _transferOwnership(_newOwner);
  }

  function _transferOwnership(address _newOwner) internal {    
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  function pause() onlyOwner whenNotPaused public {    
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {    
    paused = false;
    emit Unpause();
  }

  function mint(address _to, uint256 _amount, string _reason) hasMintPermission canMint public returns (bool)  { 
       
    require(totalSupply_.add(_amount) <= cap);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount, _reason);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() onlyOwner canMint public returns (bool) {  
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

  function destroyAndSend(address _recipient) onlyOwner public {    
    selfdestruct(_recipient);
  }
  
 
  function startMinting(string reason) onlyOwner cannotMint public returns (bool) {
    mintingFinished = false;
    emit MintStarted(reason);
    return true;
  }

  function burnOf(address _who, uint256 _value) public onlyOwner {  
    _burn(_who, _value);
  }

  function setCap(uint256 _cap, string _reason) public onlyOwner {
    _setCap(_cap, _reason);
  }

  function _setCap(uint256 _cap, string _reason) internal onlyOwner {  
    cap = _cap;
    emit CapChange(_cap, _reason);
  }
  
  function multiTransfer(address[] _to, uint256[] _amount) whenNotPaused public returns (bool) {
    require(locked[msg.sender] != true);
    require(_to.length == _amount.length);
    uint256 i;
    uint256 amountSum = 0;
    for (i=0; i < _amount.length; i++){
      require(_amount[i] > 0);
      require(_to[i] != address(0));
      require(locked[_to[i]] != true);                                                            
      amountSum = amountSum.add(_amount[i]);
    }
    require(amountSum <= balances[msg.sender]);
    for (i=0; i < _to.length; i++){
      balances[_to[i]] = balances[_to[i]].add(_amount[i]);
      emit Transfer(msg.sender, _to[i], _amount[i]);
    }
    balances[msg.sender] = balances[msg.sender].sub(amountSum);
    return true;
  }
  
  function multiMint(address[] _to, uint256[] _amount, string _reason) hasMintPermission canMint public returns (bool) {
    require(_to.length == _amount.length);
    uint16 i;               
    uint256 amountSum = 0;
    for (i=0; i < _amount.length; i++){
      require(_amount[i] > 0);
      require(_to[i] != address(0));
      amountSum = amountSum.add(_amount[i]);
    }
    require(totalSupply_.add(amountSum) <= cap);
    for (i=0; i < _to.length; i++){
      mint(_to[i], _amount[i], _reason);
    }
    return true;
  }
  
  function lock(address _lockAddress) public onlyOwner returns (bool) {   
    require(_lockAddress != address(0));
    require(_lockAddress != owner);
    require(locked[_lockAddress] != true);
    locked[_lockAddress] = true;
    emit Lock(_lockAddress);
    return true;
  }

  function unlock(address _lockAddress) public onlyOwner returns (bool) {
    require(_lockAddress != address(0));
    require(_lockAddress != owner);
    require(locked[_lockAddress] ==  true);
    locked[_lockAddress] = false;
    emit Unlock(_lockAddress);
    return true;
  }

  function multiLock(address[] _lockAddress) public onlyOwner {
    for (uint i=0; i < _lockAddress.length; i++){
      lock(_lockAddress[i]);
    }
  }

  function multiUnlock(address[] _lockAddress) public onlyOwner {
    for (uint i=0; i < _lockAddress.length; i++){
      unlock(_lockAddress[i]);
    }
  }
  
  function checkLock(address _address) public view onlyOwner returns (bool) {
    return locked[_address];
  }

}