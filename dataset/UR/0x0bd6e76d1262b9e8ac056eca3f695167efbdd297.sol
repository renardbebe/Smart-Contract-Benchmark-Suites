 

pragma solidity ^0.4.4;


 

 
 
 
 

contract PresaleToken {

    
    function PresaleToken(address _tokenManager) {
        tokenManager = _tokenManager;
    }


   

    string public name = "Dobi Presale Token";
    string public symbol = "Dobi";
    uint   public decimals = 18;



     
     
     

    uint public PRICE = 17; 

    uint public TOKEN_SUPPLY_LIMIT = 30000 * (1 ether / 1 wei);



    

    enum Phase {
        Created,
        Running,
        Paused,
        Migrating,
        Migrated
    }

    Phase public currentPhase = Phase.Created;

     
    uint public totalSupply = 0; 

     
     
    address public tokenManager;
     
    address public crowdsaleManager;

    mapping (address => uint256) private balance;


    modifier onlyTokenManager()     { if(msg.sender != tokenManager) throw; _; }
    modifier onlyCrowdsaleManager() { if(msg.sender != crowdsaleManager) throw; _; }


    

    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);
    event LogPhaseSwitch(Phase newPhase);


    

    function() payable {
        buyTokens(msg.sender);
    }

   
    function buyTokens(address _buyer) public payable {
         
        if(currentPhase != Phase.Running) throw;

        if(msg.value == 0) throw;
        uint newTokens = msg.value * PRICE;
        if (totalSupply + newTokens > TOKEN_SUPPLY_LIMIT) throw;
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
            if(!tokenManager.send(this.balance)) throw;
        }
    }


    function setCrowdsaleManager(address _mgr) public
        onlyTokenManager
    {
         
        if(currentPhase == Phase.Migrating) throw;
        crowdsaleManager = _mgr;
    }
}