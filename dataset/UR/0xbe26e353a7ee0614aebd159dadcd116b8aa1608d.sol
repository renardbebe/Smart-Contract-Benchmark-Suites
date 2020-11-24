 

pragma solidity ^0.4.18;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
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

 

 
library SafeMath {
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
}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 

 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 

 
 
 
contract SeeleToken is PausableToken {
    using SafeMath for uint;

     
    string public constant name = "SeeleToken";
    string public constant symbol = "Seele";
    uint public constant decimals = 18;

     
    uint public currentSupply;

     
     
    address public minter; 

     
    mapping (address => uint) public lockedBalances;

     
    bool public claimedFlag;  

     
    modifier onlyMinter {
        require(msg.sender == minter);
        _;
    }

    modifier canClaimed {
        require(claimedFlag == true);
        _;
    }

    modifier maxTokenAmountNotReached (uint amount){
        require(currentSupply.add(amount) <= totalSupply);
        _;
    }

    modifier validAddress( address addr ) {
        require(addr != address(0x0));
        require(addr != address(this));
        _;
    }

     
    function SeeleToken(address _minter, address _admin, uint _maxTotalSupply) 
        public 
        validAddress(_admin)
        validAddress(_minter)
        {
        minter = _minter;
        totalSupply = _maxTotalSupply;
        claimedFlag = false;
        paused = true;
        transferOwnership(_admin);
    }

     

    function mint(address receipent, uint amount, bool isLock)
        external
        onlyMinter
        maxTokenAmountNotReached(amount)
        returns (bool)
    {
        if (isLock ) {
            lockedBalances[receipent] = lockedBalances[receipent].add(amount);
        } else {
            balances[receipent] = balances[receipent].add(amount);
        }
        currentSupply = currentSupply.add(amount);
        return true;
    }


    function setClaimedFlag(bool flag) 
        public
        onlyOwner 
    {
        claimedFlag = flag;
    }

      

     
    function claimTokens(address[] receipents)
        external
        onlyOwner
        canClaimed
    {        
        for (uint i = 0; i < receipents.length; i++) {
            address receipent = receipents[i];
            balances[receipent] = balances[receipent].add(lockedBalances[receipent]);
            lockedBalances[receipent] = 0;
        }
    }

    function airdrop(address[] receipents, uint[] tokens)
        external
    {        
        for (uint i = 0; i < receipents.length; i++) {
            address receipent = receipents[i];
            uint token = tokens[i];
            if(balances[msg.sender] >= token ){
                balances[msg.sender] = balances[msg.sender].sub(token);
                balances[receipent] = balances[receipent].add(token);
            }
        }
    }
}

 

 
contract SeeleTokenLock is Ownable {
    using SafeMath for uint;


    SeeleToken public token;

     
    uint public firstPrivateLockTime =  90 days;
    uint public secondPrivateLockTime = 180 days;
    uint public minerLockTime = 120 days;
    
     
    uint public firstPrivateReleaseTime = 0;
    uint public secondPrivateReleaseTime = 0;
    uint public minerRelaseTime = 0;
    
     
    uint public firstPrivateLockedAmount = 160000000 ether;
    uint public secondPrivateLockedAmount = 80000000 ether;
    uint public minerLockedAmount = 300000000 ether;

    address public privateLockAddress;
    address public minerLockAddress;

    uint public lockedAt = 0; 

     
    modifier notLocked {
        require(lockedAt == 0);
        _;
    }

    modifier locked {
        require(lockedAt > 0);
        _;
    }

    modifier validAddress( address addr ) {
        require(addr != address(0x0));
        require(addr != address(this));
        _;
    }

    function SeeleTokenLock(address _seeleToken, address _privateLockAddress,  address _minerLockAddress) 
        public 
        validAddress(_seeleToken)
        validAddress(_privateLockAddress)
        validAddress(_minerLockAddress) 
        {

        token = SeeleToken(_seeleToken);
        privateLockAddress = _privateLockAddress;
        minerLockAddress = _minerLockAddress;
    }

     
     
    function recoverFailedLock() public 
        notLocked  
        onlyOwner 
        {
         
        require(token.transfer(owner, token.balanceOf(address(this))));
    }


    function lock() public 
        notLocked 
        onlyOwner 
        {
            
        uint totalLockedAmount = firstPrivateLockedAmount.add(secondPrivateLockedAmount);
        totalLockedAmount = totalLockedAmount.add(minerLockedAmount);

        require(token.balanceOf(address(this)) == totalLockedAmount);
        
        lockedAt = block.timestamp;

        firstPrivateReleaseTime = lockedAt.add(firstPrivateLockTime);
        secondPrivateReleaseTime = lockedAt.add(secondPrivateLockTime);
        minerRelaseTime = lockedAt.add(minerLockTime);
    }

     
    function unlockFirstPrivate() public 
        locked 
        onlyOwner
        {
        require(block.timestamp >= firstPrivateReleaseTime);
        require(firstPrivateLockedAmount > 0);

        uint256 amount = token.balanceOf(this);
        require(amount >= firstPrivateLockedAmount);

        token.transfer(privateLockAddress, firstPrivateLockedAmount);
        firstPrivateLockedAmount = 0;
    }


     
    function unlockSecondPrivate() public 
        locked 
        onlyOwner
        {
        require(block.timestamp >= secondPrivateReleaseTime);
        require(secondPrivateLockedAmount > 0);

        uint256 amount = token.balanceOf(this);
        require(amount >= secondPrivateLockedAmount);

        token.transfer(privateLockAddress, secondPrivateLockedAmount);
        secondPrivateLockedAmount = 0;
    }

     
    function unlockMiner() public 
        locked 
        onlyOwner
        {
        require(block.timestamp >= minerRelaseTime);
        require(minerLockedAmount > 0);
        uint256 amount = token.balanceOf(this);
        require(amount >= minerLockedAmount);
        token.transfer(minerLockAddress, minerLockedAmount);

        minerLockedAmount = 0;
    }
}