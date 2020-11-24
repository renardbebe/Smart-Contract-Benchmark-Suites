 

pragma solidity ^0.4.4;

 
 
 
 
 
 
contract PresaleToken
{
 
    string public constant name = "IMMLA Presale Token v.2";
    string public constant symbol = "IML";
    uint public constant decimals = 18;
    uint public constant PRICE = 5200;   

     
     
     
     
     
    uint public constant TOKEN_SUPPLY_LIMIT = PRICE * 600 * (1 ether / 1 wei);

    enum State{
       Init,
       Running,
       Paused,
       Migrating,
       Migrated
    }

    State public currentState = State.Init;
    uint public totalSupply = 0;  

     
    address public escrow = 0;

     
     
    address public tokenManager = 0;

     
    address public crowdsaleManager = 0;

    mapping (address => uint256) private balance;

 
    modifier onlyTokenManager()     { if(msg.sender != tokenManager) throw; _; }
    modifier onlyCrowdsaleManager() { if(msg.sender != crowdsaleManager) throw; _; }
    modifier onlyInState(State state){ if(state != currentState) throw; _; }

 
    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);
    event LogStateSwitch(State newState);

 
     
     
    function PresaleToken(address _tokenManager, address _escrow) 
    {
        if(_tokenManager==0) throw;
        if(_escrow==0) throw;

        tokenManager = _tokenManager;
        escrow = _escrow;
    }

    function buyTokens(address _buyer) public payable onlyInState(State.Running)
    {
        if(msg.value == 0) throw;
        uint newTokens = msg.value * PRICE;

        if (totalSupply + newTokens > TOKEN_SUPPLY_LIMIT) throw;

        balance[_buyer] += newTokens;
        totalSupply += newTokens;

        LogBuy(_buyer, newTokens);
    }

     
     
    function burnTokens(address _owner) public onlyCrowdsaleManager onlyInState(State.Migrating)
    {
        uint tokens = balance[_owner];
        if(tokens == 0) throw;

        balance[_owner] = 0;
        totalSupply -= tokens;

        LogBurn(_owner, tokens);

         
        if(totalSupply == 0) 
        {
            currentState = State.Migrated;
            LogStateSwitch(State.Migrated);
        }
    }

     
     
    function balanceOf(address _owner) constant returns (uint256) 
    {
        return balance[_owner];
    }

    function setPresaleState(State _nextState) public onlyTokenManager
    {
         
         
         
         
         
         
        bool canSwitchState
             =  (currentState == State.Init && _nextState == State.Running)
             || (currentState == State.Running && _nextState == State.Paused)
              
             || ((currentState == State.Running || currentState == State.Paused)
                 && _nextState == State.Migrating
                 && crowdsaleManager != 0x0)
             || (currentState == State.Paused && _nextState == State.Running)
              
             || (currentState == State.Migrating && _nextState == State.Migrated
                 && totalSupply == 0);

        if(!canSwitchState) throw;

        currentState = _nextState;
        LogStateSwitch(_nextState);
    }

    function withdrawEther() public onlyTokenManager
    {
        if(this.balance > 0) 
        {
            if(!escrow.send(this.balance)) throw;
        }
    }

 
    function setTokenManager(address _mgr) public onlyTokenManager
    {
        tokenManager = _mgr;
    }

    function setCrowdsaleManager(address _mgr) public onlyTokenManager
    {
         
        if(currentState == State.Migrating) throw;

        crowdsaleManager = _mgr;
    }

    function getTokenManager()constant returns(address)
    {
        return tokenManager;
    }

    function getCrowdsaleManager()constant returns(address)
    {
        return crowdsaleManager;
    }

    function getCurrentState()constant returns(State)
    {
        return currentState;
    }

    function getPrice()constant returns(uint)
    {
        return PRICE;
    }

    function getTotalSupply()constant returns(uint)
    {
        return totalSupply;
    }


     
    function() payable 
    {
        buyTokens(msg.sender);
    }
}