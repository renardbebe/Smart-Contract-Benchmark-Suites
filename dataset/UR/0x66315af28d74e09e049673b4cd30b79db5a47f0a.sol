 

pragma solidity 0.4.16;

 
library SafeMath {

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

contract Vezt is Owned {
    using SafeMath for uint256;

    address[]   public  veztUsers;
    uint256     public  totalSupply;
    uint8       public  decimals;
    string      public  name;
    string      public  symbol;
    bool        public  tokenTransfersFrozen;
    bool        public  tokenMintingEnabled;
    bool        public  contractLaunched;

    mapping (address => mapping (address => uint256))   public allowance;
    mapping (address => uint256)                        public balances;
    mapping (address => uint256)                        public royaltyTracking;
    mapping (address => uint256)                        public icoBalances;
    mapping (address => uint256)                        public veztUserArrayIdentifier;
    mapping (address => bool)                           public veztUserRegistered;

    event Transfer(address indexed _sender, address indexed _recipient, uint256 _amount);
    event Approve(address indexed _owner, address indexed _spender, uint256 _amount);
    event LaunchContract(address indexed _launcher, bool _launched);
    event FreezeTokenTransfers(address indexed _invoker, bool _frozen);
    event ThawTokenTransfers(address indexed _invoker, bool _thawed);
    event MintTokens(address indexed _minter, uint256 _amount, bool indexed _minted);
    event TokenMintingDisabled(address indexed _invoker, bool indexed _disabled);
    event TokenMintingEnabled(address indexed _invoker, bool indexed _enabled);

    function Vezt() {
        name = "Vezt";
        symbol = "VZT";
        decimals = 18;
         
        totalSupply = 125000000000000000000000000;
        balances[msg.sender] = balances[msg.sender].add(totalSupply);
        tokenTransfersFrozen = true;
        tokenMintingEnabled = false;
        contractLaunched = false;
    }

     
     
     
    function logRoyalty(address _receiver, uint256 _amount)
        onlyOwner
        public 
        returns (bool logged)
    {
        require(transferCheck(msg.sender, _receiver, _amount));
        if (!veztUserRegistered[_receiver]) {
            veztUsers.push(_receiver);
            veztUserRegistered[_receiver] = true;
        }
        require(royaltyTracking[_receiver].add(_amount) > 0);
        require(royaltyTracking[_receiver].add(_amount) > royaltyTracking[_receiver]);
        royaltyTracking[_receiver] = royaltyTracking[_receiver].add(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(owner, _receiver, _amount);
        return true;
    }

    function transactionReplay(address _receiver, uint256 _amount)
        onlyOwner
        public
        returns (bool replayed)
    {
        require(transferCheck(msg.sender, _receiver, _amount));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(msg.sender, _receiver, _amount);
        return true;
    }

     
    function launchContract() onlyOwner {
        require(!contractLaunched);
        tokenTransfersFrozen = false;
        tokenMintingEnabled = true;
        contractLaunched = true;
        LaunchContract(msg.sender, true);
    }

    function disableTokenMinting() onlyOwner returns (bool disabled) {
        tokenMintingEnabled = false;
        TokenMintingDisabled(msg.sender, true);
        return true;
    }

    function enableTokenMinting() onlyOwner returns (bool enabled) {
        tokenMintingEnabled = true;
        TokenMintingEnabled(msg.sender, true);
        return true;
    }

    function freezeTokenTransfers() onlyOwner returns (bool success) {
        tokenTransfersFrozen = true;
        FreezeTokenTransfers(msg.sender, true);
        return true;
    }

    function thawTokenTransfers() onlyOwner returns (bool success) {
        tokenTransfersFrozen = false;
        ThawTokenTransfers(msg.sender, true);
        return true;
    }

     
     
     
    function transfer(address _receiver, uint256 _amount)
        public
        returns (bool success)
    {
        require(transferCheck(msg.sender, _receiver, _amount));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(msg.sender, _receiver, _amount);
        return true;
    }

     
     
     
     
    function transferFrom(address _owner, address _receiver, uint256 _amount) 
        public 
        returns (bool success)
    {
        require(allowance[_owner][msg.sender] >= _amount);
        require(transferCheck(_owner, _receiver, _amount));
        allowance[_owner][msg.sender] = allowance[_owner][msg.sender].sub(_amount);
        balances[_owner] =  balances[_owner].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        Transfer(_owner, _receiver, _amount);
        return true;
    }

     
     
     
    function approve(address _spender, uint256 _amount)
        public
        returns (bool approved)
    {
        require(_amount > 0);
        require(balances[msg.sender] >= _amount);
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_amount);
        return true;
    }

     
     
    function tokenBurner(uint256 _amount)
        onlyOwner
        returns (bool burned)
    {
        require(_amount > 0);
        require(totalSupply.sub(_amount) > 0);
        require(balances[msg.sender] > _amount);
        require(balances[msg.sender].sub(_amount) > 0);
        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        Transfer(msg.sender, 0, _amount);
        return true;
    }

     
     
    function tokenMinter(uint256 _amount)
        private
        returns (bool minted)
    {
        require(tokenMintingEnabled);
        require(_amount > 0);
        require(totalSupply.add(_amount) > 0);
        require(totalSupply.add(_amount) > totalSupply);
        require(balances[owner].add(_amount) > 0);
        require(balances[owner].add(_amount) > balances[owner]);
        return true;
    }
     
     
    function tokenFactory(uint256 _amount) 
        onlyOwner
        returns (bool success)
    {
        require(tokenMinter(_amount));
        totalSupply = totalSupply.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        Transfer(0, msg.sender, _amount);
        return true;
    }

     

    function lookupRoyalty(address _veztUser)
        public
        constant
        returns (uint256 royalties)
    {
        return royaltyTracking[_veztUser];
    }

     
    function transferCheck(address _sender, address _receiver, uint256 _amount)
        private
        constant
        returns (bool success)
    {
        require(!tokenTransfersFrozen);
        require(_amount > 0);
        require(_receiver != address(0));
        require(balances[_sender].sub(_amount) >= 0);
        require(balances[_receiver].add(_amount) > 0);
        require(balances[_receiver].add(_amount) > balances[_receiver]);
        return true;
    }

     
    function totalSupply() 
        public
        constant
        returns (uint256 _totalSupply)
    {
        return totalSupply;
    }

     
    function balanceOf(address _person)
        public
        constant
        returns (uint256 _balance)
    {
        return balances[_person];
    }

     
    function allowance(address _owner, address _spender)
        public
        constant 
        returns (uint256 _amount)
    {
        return allowance[_owner][_spender];
    }
}