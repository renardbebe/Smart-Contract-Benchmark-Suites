 

pragma solidity 0.4.18;
 

contract Administration {

     
    address     public  owner;
     
    address     public  administrator;
     
    address     public  songTokenExchange;
     
    address     public  royaltyInformationContract;
     
    bool        public  administrationContractFrozen;

     
    mapping (address => bool) public moderators;

    event ModeratorAdded(address indexed _invoker, address indexed _newMod, bool indexed _newModAdded);
    event ModeratorRemoved(address indexed _invoker, address indexed _removeMod, bool indexed _modRemoved);
    event AdministratorAdded(address indexed _invoker, address indexed _newAdmin, bool indexed _newAdminAdded);
    event RoyaltyInformationContractSet(address indexed _invoker, address indexed _newRoyaltyContract, bool indexed _newRoyaltyContractSet);
    event SongTokenExchangeContractSet(address indexed _invoker, address indexed _newSongTokenExchangeContract, bool indexed _newSongTokenExchangeSet);

    function Administration() {
        owner = 0x79926C875f2636808de28CD73a45592587A537De;
        administrator = 0x79926C875f2636808de28CD73a45592587A537De;
        administrationContractFrozen = false;
    }

     
    modifier isFrozen() {
        require(administrationContractFrozen);
        _;
    }

     
    modifier notFrozen() {
        require(!administrationContractFrozen);
        _;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == administrator);
        _;
    }

     
    modifier onlyAdminOrExchange() {
        require(msg.sender == owner || msg.sender == songTokenExchange || msg.sender == administrator);
        _;
    }

     
    modifier onlyModerator() {
        if (msg.sender == owner) {_;}
        if (msg.sender == administrator) {_;}
        if (moderators[msg.sender]) {_;}
    }

     
    function freezeAdministrationContract() public onlyAdmin notFrozen returns (bool frozen) {
        administrationContractFrozen = true;
        return true;
    }

     
    function unfreezeAdministrationContract() public onlyAdmin isFrozen returns (bool unfrozen) {
        administrationContractFrozen = false;
        return true;
    }

     
    function setRoyaltyInformationContract(address _royaltyInformationContract) public onlyAdmin notFrozen returns (bool set) {
        royaltyInformationContract = _royaltyInformationContract;
        RoyaltyInformationContractSet(msg.sender, _royaltyInformationContract, true);
        return true;
    }

     
    function setTokenExchange(address _songTokenExchange) public onlyAdmin notFrozen returns (bool set) {
        songTokenExchange = _songTokenExchange;
        SongTokenExchangeContractSet(msg.sender, _songTokenExchange, true);
        return true;
    }

     
    function addModerator(address _newMod) public onlyAdmin notFrozen returns (bool success) {
        moderators[_newMod] = true;
        ModeratorAdded(msg.sender, _newMod, true);
        return true;
    }

     
    function removeModerator(address _removeMod) public onlyAdmin notFrozen returns (bool success) {
        moderators[_removeMod] = false;
        ModeratorRemoved(msg.sender, _removeMod, true);
        return true;
    }

     
    function setAdministrator(address _administrator) public onlyOwner notFrozen returns (bool success) {
        administrator = _administrator;
        AdministratorAdded(msg.sender, _administrator, true);
        return true;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner notFrozen returns (bool success) {
        owner = _newOwner;
        return true;
    }
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

 

contract Vezt is Administration {
    using SafeMath for uint256;

    uint256                 public  totalSupply;
    uint8                   public  decimals;
    string                  public  name;
    string                  public  symbol;
    bool                    public  tokenTransfersFrozen;
    bool                    public  tokenMintingEnabled;
    bool                    public  contractLaunched;

    mapping (address => uint256)                        public balances;
    mapping (address => mapping (address => uint256))   public allowed;


    event Transfer(address indexed _sender, address indexed _recipient, uint256 _amount);
    event Approve(address indexed _owner, address indexed _spender, uint256 _amount);
    event LaunchContract(address indexed _launcher, bool _launched);
    event FreezeTokenTransfers(address indexed _invoker, bool _frozen);
    event ThawTokenTransfers(address indexed _invoker, bool _thawed);
    event MintTokens(address indexed _minter, uint256 _amount, bool indexed _minted);
    event TokenMintingDisabled(address indexed _invoker, bool indexed _disabled);
    event TokenMintingEnabled(address indexed _invoker, bool indexed _enabled);
    event SongTokenAdded(address indexed _songTokenAddress, bool indexed _songTokenAdded);
    event SongTokenRemoved(address indexed _songTokenAddress, bool indexed _songTokenRemoved);

    function Vezt() {
        name = "Vezt";
        symbol = "VZT";
        decimals = 18;
        totalSupply = 125000000000000000000000000;
        balances[0x79926C875f2636808de28CD73a45592587A537De] = balances[0x79926C875f2636808de28CD73a45592587A537De].add(totalSupply);
        tokenTransfersFrozen = true;
        tokenMintingEnabled = false;
        contractLaunched = false;
    }

     
    function transactionReplay(address _receiver, uint256 _amount)
        public
        onlyOwner
        returns (bool replayed)
    {
        require(transferCheck(msg.sender, _receiver, _amount));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(msg.sender, _receiver, _amount);
        return true;
    }

     
    function launchContract() 
        public
        onlyOwner
        returns (bool launched)
    {
        require(!contractLaunched);
        tokenTransfersFrozen = false;
        tokenMintingEnabled = true;
        contractLaunched = true;
        LaunchContract(msg.sender, true);
        return true;
    }

     
    function disableTokenMinting() 
        public
        onlyOwner
        returns (bool disabled) 
    {
        tokenMintingEnabled = false;
        TokenMintingDisabled(msg.sender, true);
        return true;
    }

     
    function enableTokenMinting() 
        public
        onlyOwner
        returns (bool enabled)
    {
        tokenMintingEnabled = true;
        TokenMintingEnabled(msg.sender, true);
        return true;
    }

     
    function freezeTokenTransfers()
        public
        onlyOwner
        returns (bool frozen)
    {
        tokenTransfersFrozen = true;
        FreezeTokenTransfers(msg.sender, true);
        return true;
    }

     
    function thawTokenTransfers()
        public
        onlyOwner
        returns (bool thawed)
    {
        tokenTransfersFrozen = false;
        ThawTokenTransfers(msg.sender, true);
        return true;
    }

     
    function transfer(address _receiver, uint256 _amount)
        public
        returns (bool transferred)
    {
        require(transferCheck(msg.sender, _receiver, _amount));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(msg.sender, _receiver, _amount);
        return true;
    }

     
    function transferFrom(address _owner, address _receiver, uint256 _amount) 
        public 
        returns (bool transferred)
    {
        require(allowed[_owner][msg.sender] >= _amount);
        require(transferCheck(_owner, _receiver, _amount));
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender].sub(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(_owner, _receiver, _amount);
        return true;
    }

     
    function approve(address _spender, uint256 _amount)
        public
        returns (bool approved)
    {
        require(_amount > 0);
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_amount);
        Approve(msg.sender, _spender, _amount);
        return true;
    }
    
     
    function tokenBurner(uint256 _amount)
        public
        onlyOwner
        returns (bool burned)
    {
        require(_amount > 0);
        require(totalSupply.sub(_amount) >= 0);
        require(balances[msg.sender] >= _amount);
        require(balances[msg.sender].sub(_amount) >= 0);
        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        Transfer(msg.sender, 0, _amount);
        return true;
    }

     
    function tokenFactory(uint256 _amount)
        public 
        onlyOwner
        returns (bool minted)
    {
         
        require(tokenMinter(_amount, msg.sender));
        totalSupply = totalSupply.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        Transfer(0, msg.sender, _amount);
        return true;
    }

     

     
    function tokenMinter(uint256 _amount, address _sender)
        internal
        view
        returns (bool valid)
    {
        require(tokenMintingEnabled);
        require(_amount > 0);
        require(_sender != address(0x0));
        require(totalSupply.add(_amount) > 0);
        require(totalSupply.add(_amount) > totalSupply);
        require(balances[_sender].add(_amount) > 0);
        require(balances[_sender].add(_amount) > balances[_sender]);
        return true;
    }
    
     
    function transferCheck(address _sender, address _receiver, uint256 _amount)
        internal
        view
        returns (bool valid)
    {
        require(!tokenTransfersFrozen);
        require(_amount > 0);
        require(_receiver != address(0));
        require(balances[_sender] >= _amount);  
        require(balances[_sender].sub(_amount) >= 0);
        require(balances[_receiver].add(_amount) > 0);
        require(balances[_receiver].add(_amount) > balances[_receiver]);
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
        returns (uint256 _balanceOf)
    {
        return balances[_person];
    }

     
    function allowance(address _owner, address _spender)
        public 
        view
        returns (uint256 _allowance)
    {
        return allowed[_owner][_spender];
    }

}