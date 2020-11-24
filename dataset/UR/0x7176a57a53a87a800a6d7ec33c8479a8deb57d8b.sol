 

pragma solidity ^0.4.11;

 

contract ARIToken {

     
     
    function ARIToken(address _tokenManager, address _escrow) {
        tokenManager = _tokenManager;
        escrow = _escrow;
    }


     

    string public constant name = "ARI Token";
    string public constant symbol = "ARI";
    uint   public constant decimals = 18;

     

    enum Phase {
        Created,
        Running,
        Paused,
        Migrating,
        Migrated
    }

    Phase public currentPhase = Phase.Created;
    uint public totalSupply = 0;  

    uint public price = 2000;
    uint public tokenSupplyLimit = 2000 * 10000 * (1 ether / 1 wei);

    bool public transferable = false;

     
     
    address public tokenManager;

     
    address public escrow;

     
    address public crowdsaleManager;

    mapping (address => uint256) private balance;


    modifier onlyTokenManager()     { if(msg.sender != tokenManager) throw; _; }
    modifier onlyCrowdsaleManager() { if(msg.sender != crowdsaleManager) throw; _; }


     

    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);
    event LogPhaseSwitch(Phase newPhase);
     
    event Transfer(address indexed from, address indexed to, uint256 value);


     

    function() payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _buyer) public payable {
         
        if(currentPhase != Phase.Running) throw;

        if(msg.value <= 0) throw;
        uint newTokens = msg.value * price;
        if (totalSupply + newTokens > tokenSupplyLimit) throw;
        balance[_buyer] += newTokens;
        totalSupply += newTokens;
        LogBuy(_buyer, newTokens);
    }


     
     
    function burnTokens(address _owner) public
        onlyCrowdsaleManager
    {
         
        if(currentPhase != Phase.Migrating) throw;

        uint tokens = balance[_owner];
        if(tokens == 0) throw;
        balance[_owner] = 0;
        totalSupply -= tokens;
        LogBurn(_owner, tokens);

         
        if(totalSupply == 0) {
            currentPhase = Phase.Migrated;
            LogPhaseSwitch(Phase.Migrated);
        }
    }


     
     
    function balanceOf(address _owner) constant returns (uint256) {
        return balance[_owner];
    }


     

    function setPresalePhase(Phase _nextPhase) public
        onlyTokenManager
    {
        bool canSwitchPhase
            =  (currentPhase == Phase.Created && _nextPhase == Phase.Running)
            || (currentPhase == Phase.Running && _nextPhase == Phase.Paused)
                 
            || ((currentPhase == Phase.Running || currentPhase == Phase.Paused)
                && _nextPhase == Phase.Migrating
                && crowdsaleManager != 0x0)
            || (currentPhase == Phase.Paused && _nextPhase == Phase.Running)
                 
            || (currentPhase == Phase.Migrating && _nextPhase == Phase.Migrated
                && totalSupply == 0);

        if(!canSwitchPhase) throw;
        currentPhase = _nextPhase;
        LogPhaseSwitch(_nextPhase);
    }


    function withdrawEther() public
        onlyTokenManager
    {
         
        if(this.balance > 0) {
            if(!escrow.send(this.balance)) throw;
        }
    }


    function setCrowdsaleManager(address _mgr) public
        onlyTokenManager
    {
         
        if(currentPhase == Phase.Migrating) throw;
        crowdsaleManager = _mgr;
    }
    
     
    function transfer(address _to, uint256 _value) {
        if (!transferable) throw;
        if (balance[msg.sender] < _value) throw;            
        if (balance[_to] + _value < balance[_to]) throw;  
        balance[msg.sender] -= _value;                      
        balance[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }
    
    function setTransferable(bool _value) public
        onlyTokenManager
    {
        transferable = _value;
    }
    
    function setPrice(uint256 _price) public
        onlyTokenManager
    {
        if(currentPhase != Phase.Paused) throw;
        if(_price <= 0) throw;

        price = _price;
    }

    function setTokenSupplyLimit(uint256 _value) public
        onlyTokenManager
    {
        if(currentPhase != Phase.Paused) throw;
        if(_value <= 0) throw;

        uint _tokenSupplyLimit;
        _tokenSupplyLimit = _value * (1 ether / 1 wei);

        if(totalSupply > _tokenSupplyLimit) throw;

        tokenSupplyLimit = _tokenSupplyLimit;
    }
}