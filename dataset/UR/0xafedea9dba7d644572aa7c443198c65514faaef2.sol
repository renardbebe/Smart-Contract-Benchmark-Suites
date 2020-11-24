 

pragma solidity 0.4.16;

 
contract Owned {

    address public owner;  

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner)
            revert();
        _;  
    }

    function transferOwnership(address _newOwner) onlyOwner returns (bool success) {
        if (msg.sender != owner)
            revert();
        owner = _newOwner;
        return true;
        
    }
}

contract SafeMath {

    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}


contract CoinMarketAlert is Owned, SafeMath {

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
    event Approve(address indexed _owner, address indexed _spender, uint256 _amount);
    event MintTokens(address indexed _minter, uint256 _amountMinted, bool indexed Minted);
    event FreezeTransfers(address indexed _freezer, bool indexed _frozen);
    event ThawTransfers(address indexed _thawer, bool indexed _thawed);
    event TokenBurn(address indexed _burner, uint256 _amount, bool indexed _burned);
    event EnableTokenMinting(bool Enabled);

    function CoinMarketAlert() {
        symbol = "CMA";
        name = "Coin Market Alert";
        decimals = 18;
         
        totalSupply = 50000000000000000000000000;
        balances[msg.sender] = add(balances[msg.sender], totalSupply);
        tokenTransfersFrozen = true;
        tokenMintingEnabled = false;
    }

     
    function launchContract() onlyOwner returns (bool launched) {
        require(!contractLaunched);
        tokenTransfersFrozen = false;
        tokenMintingEnabled = true;
        contractLaunched = true;
        EnableTokenMinting(true);
        return true;
    }
    
     
    function registerUser(address _user) private returns (bool registered) {
        usersRegistered = add(usersRegistered, 1);
        AlertCreatorStruct memory acs;
        acs.alertCreator = _user;
        alertCreators.push(acs);
        userAddresses.push(_user);
        userRegistered[_user] = true;
        return true;
    }

     
     
     
    function singlePayout(address _user, uint256 _amount) onlyOwner returns (bool paid) {
        require(!tokenTransfersFrozen);
        require(_amount > 0);
        require(transferCheck(owner, _user, _amount));
        if (!userRegistered[_user]) {
            registerUser(_user);
        }
        balances[_user] = add(balances[_user], _amount);
        balances[owner] = sub(balances[owner], _amount);
        Transfer(owner, _user, _amount);
        return true;
    }

     
    function tokenMint(address _invoker, uint256 _amount) private returns (bool raised) {
        require(add(balances[owner], _amount) > balances[owner]);
        require(add(balances[owner], _amount) > 0);
        require(add(totalSupply, _amount) > 0);
        require(add(totalSupply, _amount) > totalSupply);
        totalSupply = add(totalSupply, _amount);
        balances[owner] = add(balances[owner], _amount);
        MintTokens(_invoker, _amount, true);
        return true;
    }

     
     
    function tokenFactory(uint256 _amount) onlyOwner returns (bool success) {
        require(_amount > 0);
        require(tokenMintingEnabled);
        if (!tokenMint(msg.sender, _amount))
            revert();
        return true;
    }

     
     
    function tokenBurn(uint256 _amount) onlyOwner returns (bool burned) {
        require(_amount > 0);
        require(_amount < totalSupply);
        require(balances[owner] > _amount);
        require(sub(balances[owner], _amount) > 0);
        require(sub(totalSupply, _amount) > 0);
        balances[owner] = sub(balances[owner], _amount);
        totalSupply = sub(totalSupply, _amount);
        TokenBurn(msg.sender, _amount, true);
        return true;
    }

     
    function freezeTransfers() onlyOwner returns (bool frozen) {
        tokenTransfersFrozen = true;
        FreezeTransfers(msg.sender, true);
        return true;
    }

     
    function thawTransfers() onlyOwner returns (bool thawed) {
        tokenTransfersFrozen = false;
        ThawTransfers(msg.sender, true);
        return true;
    }

     
     
     
    function transfer(address _receiver, uint256 _amount) {
        require(!tokenTransfersFrozen);
        if (transferCheck(msg.sender, _receiver, _amount)) {
            balances[msg.sender] = sub(balances[msg.sender], _amount);
            balances[_receiver] = add(balances[_receiver], _amount);
            Transfer(msg.sender, _receiver, _amount);
        } else {
             
            revert();
        }
    }

     
     
     
     
    function transferFrom(address _owner, address _receiver, uint256 _amount) {
        require(!tokenTransfersFrozen);
        require(sub(allowance[_owner][msg.sender], _amount) >= 0);
        if (transferCheck(_owner, _receiver, _amount)) {
            balances[_owner] = sub(balances[_owner], _amount);
            balances[_receiver] = add(balances[_receiver], _amount);
            allowance[_owner][_receiver] = sub(allowance[_owner][_receiver], _amount);
            Transfer(_owner, _receiver, _amount);
        } else {
             
            revert();
        }
    }

     
     
     
    function approve(address _spender, uint256 _amount) returns (bool approved) {
        require(_amount > 0);
        require(balances[msg.sender] > 0);
        allowance[msg.sender][_spender] = _amount;
        Approve(msg.sender, _spender, _amount);
        return true;
    }

      
     

    
     
     
     
     
    function transferCheck(address _sender, address _receiver, uint256 _value) 
        private
        constant 
        returns (bool safe) 
    {
        require(_value > 0);
         
        require(_receiver != address(0));
        require(sub(balances[_sender], _value) >= 0);
        require(add(balances[_receiver], _value) > balances[_receiver]);
        return true;
    }

     
    function totalSupply() constant returns (uint256 _totalSupply) {
        return totalSupply;
    }

     
    function balanceOf(address _person) constant returns (uint256 balance) {
        return balances[_person];
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 allowed) {
        return allowance[_owner][_spender];
    }
}