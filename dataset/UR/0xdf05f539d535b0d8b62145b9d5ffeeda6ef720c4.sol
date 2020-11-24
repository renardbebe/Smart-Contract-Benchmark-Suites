 

pragma solidity 0.4.18;

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

contract Administration {

    address     public owner;
    
    mapping (address => bool) public moderators;
    mapping (address => string) privilegeStatus;

    event AddMod(address indexed _invoker, address indexed _newMod, bool indexed _modAdded);
    event RemoveMod(address indexed _invoker, address indexed _removeMod, bool indexed _modRemoved);

    function Administration() public {
        owner = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner)
        public
        onlyOwner
        returns (bool success)
    {
        owner = _newOwner;
        return true;
        
    }

    function addModerator(address _newMod)
        public
        onlyOwner
        returns (bool added)
     {
        require(_newMod != address(0x0));
        moderators[_newMod] = true;
        AddMod(msg.sender, _newMod, true);
        return true;
    }
    
    function removeModerator(address _removeMod)
        public
        onlyOwner
        returns (bool removed)
    {
        require(_removeMod != address(0x0));
        moderators[_removeMod] = false;
        RemoveMod(msg.sender, _removeMod, true);
        return true;
    }

    function getRoleStatus(address _addr)
        public
        view   
        returns (string _role)
    {
        return privilegeStatus[_addr];
    }
}

contract CoinMarketAlert is Administration {
    using SafeMath for uint256;

    address[]   public      userAddresses;
    uint256     public      totalSupply;
    uint256     public      usersRegistered;
    uint8       public      decimals;
    string      public      name;
    string      public      symbol;
    bool        public      tokenTransfersFrozen;
    bool        public      tokenMintingEnabled;
    bool        public      contractLaunched;


    struct AlertCreatorStruct {
        address alertCreator;
        uint256 alertsCreated;
    }

    AlertCreatorStruct[]   public      alertCreators;
    
     
    mapping (address => bool) public userRegistered;
     
    mapping (address => mapping (address => uint256)) public allowance;
     
    mapping (address => uint256) public balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    event MintTokens(address indexed _minter, uint256 _amountMinted, bool indexed Minted);
    event FreezeTransfers(address indexed _freezer, bool indexed _frozen);
    event ThawTransfers(address indexed _thawer, bool indexed _thawed);
    event TokenBurn(address indexed _burner, uint256 _amount, bool indexed _burned);
    event EnableTokenMinting(bool Enabled);

    function CoinMarketAlert()
        public {
        symbol = "CMA";
        name = "Coin Market Alert";
        decimals = 18;
         
        totalSupply = 50000000000000000000000000;
        balances[msg.sender] = 50000000000000000000000000;
        tokenTransfersFrozen = true;
        tokenMintingEnabled = false;
    }

     
    function launchContract()
        public
        onlyAdmin
        returns (bool launched)
    {
        require(!contractLaunched);
        tokenTransfersFrozen = false;
        tokenMintingEnabled = true;
        contractLaunched = true;
        EnableTokenMinting(true);
        return true;
    }
    
     
    function registerUser(address _user) 
        private
        returns (bool registered)
    {
        usersRegistered = usersRegistered.add(1);
        AlertCreatorStruct memory acs;
        acs.alertCreator = _user;
        alertCreators.push(acs);
        userAddresses.push(_user);
        userRegistered[_user] = true;
        return true;
    }

     
     
     
    function singlePayout(address _user, uint256 _amount)
        public
        onlyAdmin
        returns (bool paid)
    {
        require(!tokenTransfersFrozen);
        require(_amount > 0);
        require(transferCheck(owner, _user, _amount));
        if (!userRegistered[_user]) {
            registerUser(_user);
        }
        balances[_user] = balances[_user].add(_amount);
        balances[owner] = balances[owner].add(_amount);
        Transfer(owner, _user, _amount);
        return true;
    }

     
    function tokenMint(address _invoker, uint256 _amount) 
        private
        returns (bool raised)
    {
        require(balances[owner].add(_amount) > balances[owner]);
        require(balances[owner].add(_amount) > 0);
        require(totalSupply.add(_amount) > 0);
        require(totalSupply.add(_amount) > totalSupply);
        totalSupply = totalSupply.add(_amount);
        balances[owner] = balances[owner].add(_amount);
        MintTokens(_invoker, _amount, true);
        return true;
    }

     
     
    function tokenFactory(uint256 _amount)
        public
        onlyAdmin
        returns (bool success)
    {
        require(_amount > 0);
        require(tokenMintingEnabled);
        require(tokenMint(msg.sender, _amount));
        return true;
    }

     
     
    function tokenBurn(uint256 _amount)
        public
        onlyAdmin
        returns (bool burned)
    {
        require(_amount > 0);
        require(_amount < totalSupply);
        require(balances[owner] > _amount);
        require(balances[owner].sub(_amount) >= 0);
        require(totalSupply.sub(_amount) >= 0);
        balances[owner] = balances[owner].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        TokenBurn(msg.sender, _amount, true);
        return true;
    }

     
    function freezeTransfers()
        public
        onlyAdmin
        returns (bool frozen)
    {
        tokenTransfersFrozen = true;
        FreezeTransfers(msg.sender, true);
        return true;
    }

     
    function thawTransfers()
        public
        onlyAdmin
        returns (bool thawed)
    {
        tokenTransfersFrozen = false;
        ThawTransfers(msg.sender, true);
        return true;
    }

     
     
     
    function transfer(address _receiver, uint256 _amount)
        public
        returns (bool _transferred)
    {
        require(!tokenTransfersFrozen);
        require(transferCheck(msg.sender, _receiver, _amount));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(msg.sender, _receiver, _amount);
        return true;
    }

     
     
     
     
    function transferFrom(address _owner, address _receiver, uint256 _amount)
        public
        returns (bool _transferredFrom)
    {
        require(!tokenTransfersFrozen);
        require(allowance[_owner][msg.sender].sub(_amount) >= 0);
        require(transferCheck(_owner, _receiver, _amount));
        balances[_owner] = balances[_owner].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        allowance[_owner][msg.sender] = allowance[_owner][msg.sender].sub(_amount);
        Transfer(_owner, _receiver, _amount);
        return true;
    }

     
     
     
    function approve(address _spender, uint256 _amount)
        public
        returns (bool approved)
    {
        require(_amount > 0);
        require(balances[msg.sender] > 0);
        allowance[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

      
     

    
     
     
     
     
    function transferCheck(address _sender, address _receiver, uint256 _value) 
        private
        view
        returns (bool safe) 
    {
        require(_value > 0);
        require(_receiver != address(0));
        require(balances[_sender].sub(_value) >= 0);
        require(balances[_receiver].add(_value) > balances[_receiver]);
        return true;
    }

     
    function totalSupply()
        public
        view
        returns (uint256 _totalSupply)
    {
        return totalSupply;
    }

     
    function balanceOf(address _person)
        public
        view
        returns (uint256 balance)
    {
        return balances[_person];
    }

     
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 allowed)
    {
        return allowance[_owner][_spender];
    }
}