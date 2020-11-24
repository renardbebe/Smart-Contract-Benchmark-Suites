 

pragma solidity ^0.4.24;

 
contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract Ownable {
    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

 
contract GAM is Ownable, ERC20Interface {
    using SafeMath for uint256;
    
    string public constant symbol = "GAM";
    string public constant name = "GAM";
    uint8 public constant decimals = 18;
    uint256 private _unmintedTokens = 300000000;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Burn(address indexed _address, uint256 _value);
    event Mint(address indexed _address, uint256 _value);
      
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
       
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        assert(balances[_to] + _value >= balances[_to]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        assert(balances[_to] + _value >= balances[_to]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub( _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

         
    function mintTokens(address _account, uint256 _mintedAmount) public onlyOwner returns (bool success){
        require(_mintedAmount <= _unmintedTokens);
        
        balances[_account] = balances[_account].add(_mintedAmount);
        _unmintedTokens = _unmintedTokens.sub(_mintedAmount);
        totalSupply = totalSupply.add(_mintedAmount);
        emit Mint(_account, _mintedAmount);
        return true;
    }
    
     
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        require(_spender != address(0));

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(_spender != address(0));

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_subtractedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
      
    function mintTokensWithApproval(address _target, uint256 _mintedAmount, address _spender) public onlyOwner returns (bool success){
        require(_mintedAmount <= _unmintedTokens);
        
        balances[_target] = balances[_target].add(_mintedAmount);
        _unmintedTokens = _unmintedTokens.sub(_mintedAmount);
        totalSupply = totalSupply.add(_mintedAmount);
        allowed[_target][_spender] = allowed[_target][_spender].add(_mintedAmount);
        emit Mint(_target, _mintedAmount);
        return true;
    }
    
      
    function burnUnmintedTokens(uint256 _burnedAmount) public onlyOwner returns (bool success){
        require(_burnedAmount <= _unmintedTokens);
        _unmintedTokens = _unmintedTokens.sub(_burnedAmount);
        emit Burn(msg.sender, _burnedAmount);
        return true;
    }
    

     
    function burn(address _account, uint256 _value) onlyOwner public {
        require(_account != address(0));

        totalSupply = totalSupply.sub(_value);
        balances[_account] = balances[_account].sub(_value);
        
        emit Burn(_account, _value);

    }

     
    function burnFrom(address _account, uint256 _value) onlyOwner public {
        allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_value);
        burn(_account, _value);
        
        emit Burn(_account, _value);
    }
    

     
    function unmintedTokens() onlyOwner view public returns (uint256 tokens){
        return _unmintedTokens;
    }

}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    assert(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    assert(c >= _a);

    return c;
  }
}