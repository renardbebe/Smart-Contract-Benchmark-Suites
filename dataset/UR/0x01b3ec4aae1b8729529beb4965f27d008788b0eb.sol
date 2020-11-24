 

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
contract ItokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}
contract IToken {
  function totalSupply() constant returns (uint256 totalSupply);
  function mintTokens(address _to, uint256 _amount) {}
}
contract IMintableToken {
  function mintTokens(address _to, uint256 _amount){}
}
contract ReentrnacyHandlingContract{

    bool locked;

    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
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
contract Lockable is Owned{

  uint256 public lockedUntilBlock;

  event ContractLocked(uint256 _untilBlock, string _reason);

  modifier lockAffected {
      require(block.number > lockedUntilBlock);
      _;
  }

  function lockFromSelf(uint256 _untilBlock, string _reason) internal {
    lockedUntilBlock = _untilBlock;
    ContractLocked(_untilBlock, _reason);
  }


  function lockUntil(uint256 _untilBlock, string _reason) onlyOwner {
    lockedUntilBlock = _untilBlock;
    ContractLocked(_untilBlock, _reason);
  }
}

contract Token is IERC20Token, Owned, Lockable{

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

   
  function totalSupply() constant returns (uint256) {
    return supply;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transfer(address _to, uint256 _value) lockAffected returns (bool success) {
    require(_to != 0x0 && _to != address(this));
    balances[msg.sender] = balances[msg.sender].sub(_value);  
    balances[_to] = balances[_to].add(_value);                
    Transfer(msg.sender, _to, _value);                        
    return true;
  }

   
  function approve(address _spender, uint256 _value) lockAffected returns (bool success) {
    allowances[msg.sender][_spender] = _value;         
    Approval(msg.sender, _spender, _value);            
    return true;
  }

   
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) lockAffected returns (bool success) {
    ItokenRecipient spender = ItokenRecipient(_spender);             
    approve(_spender, _value);                                       
    spender.receiveApproval(msg.sender, _value, this, _extraData);   
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) lockAffected returns (bool success) {
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

  function mintTokens(address _to, uint256 _amount) {
    require(msg.sender == crowdsaleContractAddress);

    supply = supply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
  }

  function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner{
    IERC20Token(_tokenAddress).transfer(_to, _amount);
  }
}






contract DPPToken is Token {

   
  function DPPToken() {
    standard = "DA Power Play Token token v1.0";
    name = "DA Power Play Token";
    symbol = "DPP";
    decimals = 18;
    crowdsaleContractAddress = 0x6f0d792B540afA2c8772B9bA4805E7436ad8413e; 
    lockFromSelf(4393122, "Lock before crowdsale starts");
  }
}