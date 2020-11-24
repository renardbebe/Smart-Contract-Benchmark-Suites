 

pragma solidity ^0.4.13;

 
 
 
 
 
 
contract PresaleToken
{
 
    string public constant name = "Remechain Presale Token";
    string public constant symbol = "RMC";
    uint public constant decimals = 18;
    uint public constant PRICE = 320;   

     
     
     
     
    uint public constant TOKEN_SUPPLY_LIMIT = PRICE * 1875 * (1 ether / 1 wei);

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

struct Purchase {
      address buyer;
      uint amount;
    }
   Purchase[] purchases;
 
    modifier onlyTokenManager()     { require(msg.sender == tokenManager); _;}
    modifier onlyCrowdsaleManager() { require(msg.sender == crowdsaleManager); _;}
    modifier onlyInState(State state){ require(state == currentState); _;}

 
    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);
    event LogStateSwitch(State newState);

 
     
     
    function PresaleToken(address _tokenManager, address _escrow) 
    {
        require(_tokenManager!=0);
        require(_escrow!=0);

        tokenManager = _tokenManager;
        escrow = _escrow;
    }

    function buyTokens(address _buyer) public payable onlyInState(State.Running)
    {
       
        require(msg.value != 0);
        uint newTokens = msg.value * PRICE;
       
        require(!(totalSupply + newTokens < totalSupply));
    
        require(!(totalSupply + newTokens > TOKEN_SUPPLY_LIMIT));

        balance[_buyer] += newTokens;
        totalSupply += newTokens;

        purchases[purchases.length++] = Purchase({buyer: _buyer, amount: newTokens});

        LogBuy(_buyer, newTokens);
    }

     
     
    function burnTokens(address _owner) public onlyCrowdsaleManager onlyInState(State.Migrating)
    {
        uint tokens = balance[_owner];
        require(tokens != 0);

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

        require(canSwitchState);

        currentState = _nextState;
        LogStateSwitch(_nextState);
    }

    function withdrawEther() public onlyTokenManager
    {
        if(this.balance > 0) 
        {
            require(escrow.send(this.balance));
        }
    }

 
    function setTokenManager(address _mgr) public onlyTokenManager
    {
        tokenManager = _mgr;
    }

    function setCrowdsaleManager(address _mgr) public onlyTokenManager
    {
         
        require(currentState != State.Migrating);

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
    function getNumberOfPurchases()constant returns(uint) {
        return purchases.length;
    }
    
    function getPurchaseAddress(uint index)constant returns(address) {
        return purchases[index].buyer;
    }
    
    function getPurchaseAmount(uint index)constant returns(uint) {
        return purchases[index].amount;
    }
     
    function() payable 
    {
        buyTokens(msg.sender);
    }
}