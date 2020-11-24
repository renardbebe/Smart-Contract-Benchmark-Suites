 

pragma solidity ^0.4.15;

 
contract ERC20 {
     
     
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
 


 
 
 
 
contract OfflineSecret {

     
    modifier validSecret(address to, string secret, bytes32 hashed) {
        require(checkSecret(to, secret, hashed));
        _;
    }

     
     
     
     
    function generateHash(address to, string secret) public pure returns(bytes32 hashed) {
        return keccak256(to, secret);
    }

     
     
     
     
     
    function checkSecret(address to, string secret, bytes32 hashed) public pure returns(bool valid) {
        if (hashed == keccak256(to, secret)) {
            return true;
        }

        return false;
    }
}
 
 



 
 
 
contract OwnableWithFoundation is OfflineSecret {
    address public owner;
    address public newOwnerCandidate;
    address public foundation;
    address public newFoundationCandidate;

    bytes32 public ownerHashed;
    bytes32 public foundationHashed;

    event OwnershipRequested(address indexed by, address indexed to, bytes32 hashed);
    event OwnershipTransferred(address indexed from, address indexed to);
    event FoundationRequested(address indexed by, address indexed to, bytes32 hashed);
    event FoundationTransferred(address indexed from, address indexed to);

     
     
    function OwnableWithFoundation(address _owner) public {
        foundation = msg.sender;
        owner = _owner;
    }

     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }

        _;
    }

    modifier onlyOwnerCandidate() {
        if (msg.sender != newOwnerCandidate) {
            revert();
        }

        _;
    }

     
    modifier onlyFoundation() {
        if (msg.sender != foundation) {
            revert();
        }

        _;
    }

    modifier onlyFoundationCandidate() {
        if (msg.sender != newFoundationCandidate) {
            revert();
        }

        _;
    }

     
     
     
    function requestOwnershipTransfer(
        address _newOwnerCandidate, 
        bytes32 _ownerHashed) 
        external 
        onlyFoundation
    {
        require(_newOwnerCandidate != address(0));
        require(_newOwnerCandidate != owner);

        newOwnerCandidate = _newOwnerCandidate;
        ownerHashed = _ownerHashed;

        OwnershipRequested(msg.sender, newOwnerCandidate, ownerHashed);
    }

     
     
    function acceptOwnership(
        string _ownerSecret) 
        external 
        onlyOwnerCandidate 
        validSecret(newOwnerCandidate, _ownerSecret, ownerHashed)
    {
        address previousOwner = owner;

        owner = newOwnerCandidate;
        newOwnerCandidate = address(0);

        OwnershipTransferred(previousOwner, owner);
    }

     
     
     
    function requestFoundationTransfer(
        address _newFoundationCandidate, 
        bytes32 _foundationHashed) 
        external 
        onlyFoundation 
    {
        require(_newFoundationCandidate != address(0));
        require(_newFoundationCandidate != foundation);

        newFoundationCandidate = _newFoundationCandidate;
        foundationHashed = _foundationHashed;

        FoundationRequested(msg.sender, newFoundationCandidate, foundationHashed);
    }

     
     
    function acceptFoundation(
        string _foundationSecret) 
        external 
        onlyFoundationCandidate 
        validSecret(newFoundationCandidate, _foundationSecret, foundationHashed)
    {
        address previousFoundation = foundation;

        foundation = newFoundationCandidate;
        newFoundationCandidate = address(0);

        FoundationTransferred(previousFoundation, foundation);
    }
}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
 
 



 
contract Pausable is OwnableWithFoundation {
  event Pause();
  event Unpause();

  bool public paused = false;

  function Pausable(address _owner) public OwnableWithFoundation(_owner) {
  }

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 
 

contract BasicToken is ERC20 {
    using SafeMath for uint256;

    uint256 public totalSupply;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) balances;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool) {
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
            revert();
        }

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


     
     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

        return true;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = _allowance.sub(_value);

        Transfer(_from, _to, _value);

        return true;
    }
}
 
 



 
contract D1Coin is BasicToken, Pausable {
    using SafeMath for uint256;

    string public constant name = "D1 Coin";
    string public constant symbol = "D1";

     
     
    uint8 public constant decimals = 3;

    address theCoin = address(this);

     
    struct ProtectedBalanceStruct {
        uint256 balance;
        bytes32 hashed;
    }
    mapping (address => mapping (address => ProtectedBalanceStruct)) protectedBalances;
    uint256 public protectedSupply;

     
    function D1Coin(address _owner) public Pausable(_owner) {
    }

    event Mint(address indexed minter, address indexed receiver, uint256 value);
    event ProtectedTransfer(address indexed from, address indexed to, uint256 value, bytes32 hashed);
    event ProtectedUnlock(address indexed from, address indexed to, uint256 value);
    event ProtectedReclaim(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);

     
     
     
     
    function transferToMint(uint256 _value) external whenNotPaused returns (bool) {
        return transfer(theCoin, _value);
    }

     
     
     
     
    function approveToMint(uint256 _value) external whenNotPaused returns (bool) {
        return approve(theCoin, _value);
    }

     
     
     
     
     
    function protectedTransferToMint(uint256 _value, bytes32 _hashed) external whenNotPaused returns (bool) {
        return protectedTransfer(theCoin, _value, _hashed);
    }

     
     
     
     
     
    function withdrawByMint(address _from, uint256 _value) external onlyOwner whenNotPaused returns (bool) {
         
        uint256 _allowance = allowed[_from][theCoin];

         
        balances[_from] = balances[_from].sub(_value);
        balances[theCoin] = balances[theCoin].add(_value);

         
        allowed[_from][theCoin] = _allowance.sub(_value);

        Transfer(_from, theCoin, _value);

        return true;
    }

     
     
    function mint(uint256 _amount) external onlyOwner whenNotPaused {
        require(_amount > 0);

        totalSupply = totalSupply.add(_amount);
        balances[theCoin] = balances[theCoin].add(_amount);

        Mint(msg.sender, theCoin, _amount);

         
        Transfer(address(0), theCoin, _amount);
    }

     
     
     
    function protectedBalance(address _from, address _to) public constant returns (uint256 balance, bytes32 hashed) {
        return(protectedBalances[_from][_to].balance, protectedBalances[_from][_to].hashed);
    }

     
     
     
     
    function protectedTransfer(address _to, uint256 _value, bytes32 _hashed) public whenNotPaused returns (bool) {
        require(_value > 0);

         
        require(_to != address(0));

         
         
        require(_to != owner);

        address from = msg.sender;

         
        if (msg.sender == owner) {
            from = theCoin;

             
            require(balances[theCoin].sub(protectedSupply) >= _value);
        } else {
             
            balances[from] = balances[from].sub(_value);
            balances[theCoin] = balances[theCoin].add(_value);
        }

         
         
        if (protectedBalances[from][_to].balance != 0) {
            revert();
        }

         
         
        require(protectedBalances[from][_to].hashed != _hashed);

         
        protectedBalances[from][_to].balance = _value;
        protectedBalances[from][_to].hashed = _hashed;

         
        protectedSupply = protectedSupply.add(_value);

        ProtectedTransfer(from, _to, _value, _hashed);

        return true;
    }

     
     
     
     
    function protectedUnlock(address _from, uint256 _value, string _secret) external whenNotPaused returns (bool) {
        address to = msg.sender;

         
        if (msg.sender == owner) {
            to = theCoin;
        }

         
        require(checkSecret(to, _secret, protectedBalances[_from][to].hashed));

         
        require(protectedBalances[_from][to].balance == _value);

         
        balances[theCoin] = balances[theCoin].sub(_value);
        balances[to] = balances[to].add(_value);
        
         
        protectedBalances[_from][to].balance = 0;
        protectedSupply = protectedSupply.sub(_value);

        ProtectedUnlock(_from, to, _value);
        Transfer(_from, to, _value);

        return true;
    }

     
     
     
    function protectedReclaim(address _to, uint256 _value) external whenNotPaused returns (bool) {
        address from = msg.sender;

         
        if (msg.sender == owner) {
            from = theCoin;
        } else {
             
            balances[theCoin] = balances[theCoin].sub(_value);
            balances[from] = balances[from].add(_value);
        }

         
        require(protectedBalances[from][_to].balance == _value);
        
         
        protectedBalances[from][_to].balance = 0;
        protectedSupply = protectedSupply.sub(_value);

        ProtectedReclaim(from, _to, _value);

        return true;
    }

     
     
    function burn(uint256 _amount) external onlyOwner whenNotPaused {
         
         
         
        require(_amount > 0);
        require(_amount <= balances[theCoin].sub(protectedSupply));  

         
        balances[theCoin] = balances[theCoin].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

         
        Transfer(theCoin, address(0), _amount);

        Burn(theCoin, _amount);
    }

     
     
     
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

     
     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return super.allowance(_owner, _spender);
    }

     
     
     
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
         
        require(_to != address(0));

        return super.transfer(_to, _value);
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
         
        require(_to != address(0));

         
         
        if (_from == theCoin) {
             
            require(_value <= balances[theCoin].sub(protectedSupply));
        }

        return super.transferFrom(_from, _to, _value);
    }
}