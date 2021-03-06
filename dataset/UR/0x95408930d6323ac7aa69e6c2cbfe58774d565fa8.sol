 

pragma solidity ^0.4.13;

 
contract SafeMath {
     
    function SafeMath() {
    }

     
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
} 

 
contract IOwned {
     
    function owner() public constant returns (address owner) { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

 
contract TokenHolder is ITokenHolder, Owned {
     
    function TokenHolder() {
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }
     
    modifier validAddressForSecond(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddressForSecond(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}

 
contract IERC20Token {
     
    function name() public constant returns (string name) { name; }
    function symbol() public constant returns (string symbol) { symbol; }
    function decimals() public constant returns (uint8 decimals) { decimals; }
    function totalSupply() public constant returns (uint256 totalSupply) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 
contract ERC20Token is IERC20Token, SafeMath {
    string public standard = 'Token 0.1';
    string public name = 'DEBIT Coin Token';
    string public symbol = 'DBC';
    uint8 public decimals = 8;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function ERC20Token(string _name, string _symbol, uint8 _decimals) {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0);  

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }
    
     
    modifier validAddressForSecond(address _address) {
        require(_address != 0x0);
        _;
    }

     
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddressForSecond(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
         
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

 
contract IDebitCoinToken is ITokenHolder, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

 
contract DebitCoinToken is IDebitCoinToken, ERC20Token, Owned, TokenHolder {
    string public version = '0.2';

    bool public transfersEnabled = true;     
    uint public MiningRewardPerETHBlock = 5;   
    uint public lastBlockRewarded;
    
     
    event DebitCoinTokenGenesis(address _token);
     
    event Issuance(uint256 _amount);
     
    event Destruction(uint256 _amount);
     
    event MiningRewardChanged(uint256 _amount);
     
    event MiningRewardSent(address indexed _from, address indexed _to, uint256 _value);

     
    function DebitCoinToken(string _name, string _symbol, uint8 _decimals)
        ERC20Token(_name, _symbol, _decimals)
    {
        require(bytes(_symbol).length <= 6);  
        DebitCoinTokenGenesis(address(this));
    }

     
    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

     
    function disableTransfers(bool _disable) public ownerOnly {
        transfersEnabled = !_disable;
    }

     
    function TransferMinersReward() {
        require(lastBlockRewarded < block.number);
        lastBlockRewarded = block.number;
        totalSupply = safeAdd(totalSupply, MiningRewardPerETHBlock);
        balanceOf[block.coinbase] = safeAdd(balanceOf[block.coinbase], MiningRewardPerETHBlock);
        MiningRewardSent(this, block.coinbase, MiningRewardPerETHBlock);
    }
    
     
    function ChangeMiningReward(uint256 _amount) public ownerOnly {
        MiningRewardPerETHBlock = _amount;
        MiningRewardChanged(_amount);
    }
    
     
    function issue(address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_to)
        notThis(_to)
    {
        totalSupply = safeAdd(totalSupply, _amount);
        balanceOf[_to] = safeAdd(balanceOf[_to], _amount);

        Issuance(_amount);
        Transfer(this, _to, _amount);
    }

     
    function destroy(address _from, uint256 _amount)
        public
        ownerOnly
    {
        balanceOf[_from] = safeSub(balanceOf[_from], _amount);
        totalSupply = safeSub(totalSupply, _amount);

        Transfer(_from, this, _amount);
        Destruction(_amount);
    }

     

     
    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transfer(_to, _value));

         
        if (_to == address(this)) {
            balanceOf[_to] -= _value;
            totalSupply -= _value;
            Destruction(_value);
        }

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transferFrom(_from, _to, _value));

         
        if (_to == address(this)) {
            balanceOf[_to] -= _value;
            totalSupply -= _value;
            Destruction(_value);
        }

        return true;
    }
}

 
contract UpgradeAgent {

  uint public originalSupply;

   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}


 
contract UpgradeableToken is DebitCoinToken {

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint256 public totalUpgraded;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

   
  event UpgradeAgentSet(address agent);

   
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

   
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);
       
      require(value != 0);

      balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);

       
      totalSupply = safeSub(totalSupply, value);
      totalUpgraded = safeAdd(totalUpgraded, value);

       
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) external {

      require(canUpgrade());

      require(agent != 0x0);
       
      require(msg.sender == upgradeMaster);
       
      require(getUpgradeState() != UpgradeState.Upgrading);

      upgradeAgent = UpgradeAgent(agent);

       
      require(upgradeAgent.isUpgradeAgent());
       
      require(upgradeAgent.originalSupply() == totalSupply);

      UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

   
  function setUpgradeMaster(address master) public {
      require(master != 0x0);
      require(msg.sender == upgradeMaster);
      upgradeMaster = master;
  }

   
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}