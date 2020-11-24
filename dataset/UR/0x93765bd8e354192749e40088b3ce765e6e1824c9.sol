 

pragma solidity ^0.4.11;

 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

contract Ryancoin {
    using SafeMath for uint256;
    
    uint256 public constant _initialSupply = 15000000 * (10 ** uint256(decimals));
    uint256 _totalSupply = 0;
    uint256 _totalSold = 0;
    
    string public constant symbol = "RYC";
    string public constant name = "Ryancoin";
    uint8 public constant decimals = 6;
    uint256 public rate = 1 ether / (500 * (10 ** uint256(decimals)));
    address public owner;
    
    bool public _contractStatus = true;
    
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;  
    mapping (address => bool)  _frozenAccount;
    mapping (address => bool)  _tokenAccount;

    address[] tokenHolders;
    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event UpdateStatus(string newStatus);
    event Burn(address target, uint256 _value);
    event MintedToken(address target, uint256 _value);
    event FrozenFunds(address target, bool _value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function Ryancoin()  {
        owner = msg.sender;
        _totalSupply = _initialSupply;
        balances[owner] = _totalSupply;
        setTokenHolders(owner);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != 0x0);
        owner = newOwner;
    }
    
    function stopContract() public onlyOwner {
        _contractStatus = false;
        UpdateStatus("Contract is stop");
    }
    
    function enableContract() public onlyOwner {
        _contractStatus = true;
        UpdateStatus("Contract is enable");
    }
    
    function totalSupply() public constant returns (uint256){
        return _totalSupply;
    }
    
    function totalSold() public constant returns (uint256){
        return _totalSold;
    }
    
    function totalRate() public constant returns (uint256){
        return rate;
    }
    
   
    function updateRate(uint256 _value) onlyOwner public returns (bool success){
        require(_value > 0);
        rate = 1 ether / (_value * (10 ** uint256(decimals)));
        return true;
    }
    
    function () payable public {
        createTokens();  
    }
    
    function createTokens() public payable{
        require(msg.value > 0 && msg.value > rate && _contractStatus);
        
        uint256 tokens = msg.value.div(rate);
        
        require(tokens + _totalSold < _totalSupply);
        
        require(
            balances[owner]  >= tokens
            && tokens > 0
        );
        
        _transfer(owner, msg.sender, tokens);
        Transfer(owner, msg.sender, tokens);
        _totalSold = _totalSold.add(tokens);
        
        owner.transfer(msg.value);  
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance){
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
         
        require(_contractStatus);
        require(!_frozenAccount[msg.sender]);
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
         
        require(_to != 0x0);
         
        require(_value > 0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint256 previousBalances = balances[_from] + balances[_to];
         
        balances[_from] -= _value;
         
        setTokenHolders(_to);
         
        balances[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }
    
    function transferFromOwner(address _from, address _to, uint256 _value) onlyOwner public returns (bool success){
        _transfer(_from, _to, _value);
        return true;
    }
    
    function setTokenHolders(address _holder) internal {
        if (_tokenAccount[_holder]) return;
        tokenHolders.push(_holder) -1;
        _tokenAccount[_holder] = true;
    }
    
    function getTokenHolders() view public returns (address[]) {
        return tokenHolders;
    }
    
    function countTokenHolders() view public returns (uint) {
        return tokenHolders.length;
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(balances[msg.sender] >= _value);     
        balances[msg.sender] -= _value;              
        _totalSupply -= _value;                      
        Burn(msg.sender, _value);
        return true;
    }
    
    function burnFromOwner(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(_from != address(0));
        require(_value > 0);
        require(balances[_from] >= _value);                 
        balances[_from] -= _value;                          
        _totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
    
    function mintToken(address _target, uint256 _mintedAmount) onlyOwner public {
        require(_target != address(0));
        require(_mintedAmount > 0);
        balances[_target] += _mintedAmount;
        _totalSupply += _mintedAmount;
        setTokenHolders(_target);
        Transfer(0, owner, _mintedAmount);
        Transfer(owner, _target, _mintedAmount);
        MintedToken(_target, _mintedAmount);
    }
    
    function getfreezeAccount(address _target) public constant returns (bool freeze) {
        require(_target != 0x0);
        return _frozenAccount[_target];
    }
    
    function freezeAccount(address _target, bool freeze) onlyOwner public {
        require(_target != 0x0);
        _frozenAccount[_target] = freeze;
        FrozenFunds(_target, freeze);
    }
    
      
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0));
        require(_to != address(0));
        require(_value <= allowed[_from][msg.sender]);
        _transfer(_from, _to, _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return true;
    }
  
   
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
     }
   
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        require(_owner != address(0));
        require(_spender != address(0));
        return allowed[_owner][_spender];
    }
    
     
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        require(_spender != address(0));
        require(_addedValue > 0);
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        require(_spender != address(0));
        require(_subtractedValue > 0);
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
  }
    
}