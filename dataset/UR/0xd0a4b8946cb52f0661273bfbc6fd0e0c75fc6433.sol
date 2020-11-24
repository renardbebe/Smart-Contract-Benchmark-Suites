 

pragma solidity ^0.4.13;

contract ItokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

library SafeMath {
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

contract Owned {
    address public owner;
    address public newOwner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

contract IERC20Token {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  function approve(address _spender, uint256 _value) returns (bool success) {}
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is IERC20Token, Owned {

  using SafeMath for uint256;

   
  string public standard;
  string public name;
  string public symbol;
  uint8 public decimals;

  address public crowdsaleContractAddress;

   
  uint256 supply = 0;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowances;

   
  event Mint(address indexed _to, uint256 _value);

   
  modifier onlyCrowdsaleOwner() {
      require(msg.sender == crowdsaleContractAddress);
      _;
  }

   
  function totalSupply() constant returns (uint256) {
    return supply;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transfer(address _to, uint256 _value) returns (bool success) {
    require(_to != 0x0 && _to != address(this));
    balances[msg.sender] = balances[msg.sender].sub(_value);  
    balances[_to] = balances[_to].add(_value);                
    Transfer(msg.sender, _to, _value);                        
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool success) {
    allowances[msg.sender][_spender] = _value;         
    Approval(msg.sender, _spender, _value);            
    return true;
  }

   
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
    ItokenRecipient spender = ItokenRecipient(_spender);             
    approve(_spender, _value);                                       
    spender.receiveApproval(msg.sender, _value, this, _extraData);   
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    require(_to != 0x0 && _to != address(this));
    balances[_from] = balances[_from].sub(_value);                               
    balances[_to] = balances[_to].add(_value);                                   
    allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);   
    Transfer(_from, _to, _value);                                                
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowances[_owner][_spender];
  }

  function mintTokens(address _to, uint256 _amount) onlyCrowdsaleOwner {
    supply = supply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(msg.sender, _to, _amount);
  }

  function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner {
    IERC20Token(_tokenAddress).transfer(_to, _amount);
  }
}

contract StormToken is Token {

	bool public transfersEnabled = false;     

	 
	event Issuance(uint256 _amount);
	 
	event Destruction(uint256 _amount);


   
  function StormToken(address _crowdsaleAddress) public {
    standard = "Storm Token v1.0";
    name = "Storm Token";
    symbol = "STORM";  
    decimals = 18;
    crowdsaleContractAddress = _crowdsaleAddress;
  }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     
    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

    
    function disableTransfers(bool _disable) public onlyOwner {
        transfersEnabled = !_disable;
    }

     
    function issue(address _to, uint256 _amount)
        public
        onlyOwner
        validAddress(_to)
        notThis(_to)
    {
        supply = supply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        Issuance(_amount);
        Transfer(this, _to, _amount);
    }

     
    function destroy(address _from, uint256 _amount) public {
        require(msg.sender == _from || msg.sender == owner);  

        balances[_from] = balances[_from].sub(_amount);
        supply = supply.sub(_amount);

        Transfer(_from, this, _amount);
        Destruction(_amount);
    }

     

     
    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transfer(_to, _value));
        return true;
    }
  
    function transfers(address[] _recipients, uint256[] _values) public transfersAllowed onlyOwner returns (bool success) {
        require(_recipients.length == _values.length);  

        for (uint cnt = 0; cnt < _recipients.length; cnt++) {
            assert(super.transfer(_recipients[cnt], _values[cnt]));
        }
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transferFrom(_from, _to, _value));
        return true;
    }
}