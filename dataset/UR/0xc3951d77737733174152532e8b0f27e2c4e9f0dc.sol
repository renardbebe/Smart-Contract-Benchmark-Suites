 

pragma solidity ^0.4.16;

library Math {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract Token {
     
    uint256 public totalSupply;

    uint256 public decimals;                
     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract Cloud is Token {

    using Math for uint256;
    bool trading=false;

    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    function transfer(address _to, uint256 _value) canTrade returns (bool success) {
        require(_value > 0);
        require(!frozenAccount[msg.sender]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) canTrade returns (bool success) {
        require(_value > 0);
        require(!frozenAccount[_from]);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
         
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
     
    modifier canTrade {
        require(trading==true ||(canRelease==true && msg.sender==owner));
        _;
    }
    
    function setTrade(bool allow) onlyOwner {
        trading=allow;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    
     
    event Invested(address investor, uint256 tokens);

    uint256 public employeeShare=8;
     
    address[4] employeeWallets = [0x9caeD53A6C6E91546946dD866dFD66c0aaB9f347,0xf1Df495BE71d1E5EdEbCb39D85D5F6b620aaAF47,0xa3C38bc8dD6e26eCc0D64d5B25f5ce855bb57Cd5,0x4d67a23b62399eDec07ad9c0f748D89655F0a0CB];

    string public name;                 
    string public symbol;               
    address public owner;               
    uint256 public tokensReleased=0;
    bool canRelease=false;

     
    function Cloud(
        uint256 _initialAmount,
        uint256 _decimalUnits,
        string _tokenName,
        string _tokenSymbol,
        address ownerWallet
        ) {
        owner=ownerWallet;
        decimals = _decimalUnits;                             
        totalSupply = _initialAmount*(10**decimals);          
        balances[owner] = totalSupply;                        
        name = _tokenName;                                    
        symbol = _tokenSymbol;                                
    }

     
    function freezeAccount(address target, bool freeze) onlyOwner{
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
     
    function releaseTokens(bool allow) onlyOwner {
        canRelease=allow;
    }
     
     
     
    function invest(address receiver, uint256 _value) onlyOwner returns (bool success) {
        require(canRelease);
        require(_value > 0);
        uint256 numTokens = _value;
        uint256 employeeTokens = 0;
        uint256 employeeTokenShare=0;
         
        employeeTokens = numTokens.mul(employeeShare).div(100);
        employeeTokenShare = employeeTokens.div(employeeWallets.length);
         
        approve(owner,employeeTokens.add(numTokens));
        for(uint i = 0; i < employeeWallets.length; i++)
        {
            require(transferFrom(owner, employeeWallets[i], employeeTokenShare));
        }
        require(transferFrom(owner, receiver, numTokens));
        tokensReleased = tokensReleased.add(numTokens).add(employeeTokens.mul(4));
        Invested(receiver,numTokens);
        return true;
    }
}