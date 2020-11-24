 

pragma solidity 0.4.19;

 
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
  
}

contract ESZCoin {

    using SafeMath for uint256;

    address     public      owner;
    string      public      name;
    string      public      symbol;
    uint256     public      totalSupply;
    uint8       public      decimals;
    bool        public      globalTransferLock;

    mapping (address => bool)                           public      accountLock;
    mapping (address => uint256)                        public      balances;
    mapping (address => mapping(address => uint256))    public      allowed;

    event Transfer(address indexed _sender, address indexed _recipient, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    event GlobalTransfersLocked(bool indexed _transfersFrozenGlobally);
    event GlobalTransfersUnlocked(bool indexed _transfersThawedGlobally);
    event AccountTransfersFrozen(address indexed _eszHolder, bool indexed _accountTransfersFrozen);
    event AccountTransfersThawed(address indexed _eszHolder, bool indexed _accountTransfersThawed);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier transfersUnlocked() {
        require(!globalTransferLock);
        _;
    }

     
    function ESZCoin() {
        owner = msg.sender;
        totalSupply = 10000000000000000000000000;
        balances[msg.sender] = totalSupply;
        name = "ESZCoin";
        symbol = "ESZ";
        decimals = 18;
        globalTransferLock = false;
    } 

     
    function freezeGlobalTansfers()
        public
        onlyOwner
        returns (bool)
    {
        globalTransferLock = true;
        GlobalTransfersLocked(true);
        return true;
    }

     
    function thawGlobalTransfers()
        public
        onlyOwner
        returns (bool)
    {
        globalTransferLock = false;
        GlobalTransfersUnlocked(true);
    }

     
    function freezeAccountTransfers(
        address _eszHolder
    )
        public
        onlyOwner
        returns (bool)
    {
        accountLock[_eszHolder] = true;
        AccountTransfersFrozen(_eszHolder, true);
        return true;
    }

     
    function thawAccountTransfers(
        address _eszHolder
    )
        public
        onlyOwner
        returns (bool)
    {
        accountLock[_eszHolder] = false;
        AccountTransfersThawed(_eszHolder, true);
        return true;
    }

     
    function transfer(
        address _recipient,
        uint256 _amount
    )
        public
        returns (bool)
    {
        require(accountLock[msg.sender] == false);
        require(transferCheck(msg.sender, _recipient, _amount));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_recipient] = balances[_recipient].add(_amount);
        Transfer(msg.sender, _recipient, _amount);
        return true;
    }

     
    function transferFrom(
        address _owner,
        address _recipient,
        uint256 _amount
    )
        public
        returns (bool)
    {
        require(accountLock[_owner] == false);
        require(allowed[_owner][msg.sender] >= _amount);
        require(transferCheck(_owner, _recipient, _amount));
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender].sub(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        balances[_recipient] = balances[_recipient].add(_amount);
        Transfer(_owner, _recipient, _amount);
        return true;
    }

     
    function approve(
        address _spender,
        uint256 _amount
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     

     
    function transferCheck(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        internal
        view
        transfersUnlocked
        returns (bool)
    {
        require(_amount > 0);
        require(balances[_sender] >= _amount);
        require(balances[_sender].sub(_amount) >= 0);
        require(balances[_recipient].add(_amount) > balances[_recipient]);
        return true;
    }

     
    
     
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupply;
    }

     
    function balanceOf(
        address _eszHolder
    )
        public
        view
        returns (uint256)
    {
        return balances[_eszHolder];
    }

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

}