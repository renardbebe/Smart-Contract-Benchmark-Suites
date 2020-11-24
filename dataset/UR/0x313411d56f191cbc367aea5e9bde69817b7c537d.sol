 

pragma solidity ^0.4.13;

 
 
 
 
 
 
contract PresaleToken
{
 
    string public constant name = "Remechain Presale Token";
    string public constant symbol = "RMC";
    uint public constant decimals = 18;
    uint public constant PRICE = 320;   

     
     
     
     
    uint public constant HARDCAP_ETH_LIMIT = 1875;
    uint public constant SOFTCAP_ETH_LIMIT = 500;
    uint public constant TOKEN_SUPPLY_LIMIT = PRICE * HARDCAP_ETH_LIMIT * (1 ether / 1 wei);
    uint public constant SOFTCAP_LIMIT = PRICE * SOFTCAP_ETH_LIMIT * (1 ether / 1 wei);
    
     
    uint public icoDeadline = 1511618400;
    
    uint public constant BOUNTY_LIMIT = 350000 * (1 ether / 1 wei);

    enum State{
       Init,
       Running,
       Paused,
       Migrating,
       Migrated
    }

    State public currentState = State.Init;
    uint public totalSupply = 0;  
    uint public bountySupply = 0;  

     
    address public escrow = 0;

     
     
    address public tokenManager = 0;

     
    address public crowdsaleManager = 0;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public ethBalances;

 
    modifier onlyTokenManager()     { require(msg.sender == tokenManager); _;}
    modifier onlyCrowdsaleManager() { require(msg.sender == crowdsaleManager); _;}
    modifier onlyInState(State state){ require(state == currentState); _;}

 
    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);
    event LogStateSwitch(State newState);

 
     
     
    function PresaleToken(address _tokenManager, address _escrow) public
    {
        require(_tokenManager!=0);
        require(_escrow!=0);

        tokenManager = _tokenManager;
        escrow = _escrow;
    }
    
    function reward(address _user, uint  _amount) public onlyTokenManager {
        require(_user != 0x0);
        
        assert(bountySupply + _amount >= bountySupply);
        assert(bountySupply + _amount <= BOUNTY_LIMIT);
        bountySupply += _amount;
        
        assert(balances[_user] + _amount >= balances[_user]);
        balances[_user] += _amount;
        
        addAddressToList(_user);
    }
    
    function isIcoSuccessful() constant public returns(bool successful)  {
        return totalSupply >= SOFTCAP_LIMIT;
    }
    
    function isIcoOver() constant public returns(bool isOver) {
        return now >= icoDeadline;
    }

    function buyTokens(address _buyer) public payable onlyInState(State.Running)
    {
        assert(!isIcoOver());
        require(msg.value != 0);
        
        uint ethValue = msg.value;
        uint newTokens = msg.value * PRICE;
       
        require(!(totalSupply + newTokens > TOKEN_SUPPLY_LIMIT));
        assert(ethBalances[_buyer] + ethValue >= ethBalances[_buyer]);
        assert(balances[_buyer] + newTokens >= balances[_buyer]);
        assert(totalSupply + newTokens >= totalSupply);
        
        ethBalances[_buyer] += ethValue;
        balances[_buyer] += newTokens;
        totalSupply += newTokens;
        
        addAddressToList(_buyer);

        LogBuy(_buyer, newTokens);
    }
    
    address[] public addressList;
    mapping (address => bool) isAddressInList;
    function addAddressToList(address _address) private {
        if (isAddressInList[_address]) {
            return;
        }
        addressList.push(_address);
        isAddressInList[_address] = true;
    }

     
     
    function burnTokens(address _owner) public onlyCrowdsaleManager onlyInState(State.Migrating)
    {
        uint tokens = balances[_owner];
        require(tokens != 0);

        balances[_owner] = 0;
        totalSupply -= tokens;

        LogBurn(_owner, tokens);

         
        if(totalSupply == 0) 
        {
            currentState = State.Migrated;
            LogStateSwitch(State.Migrated);
        }
    }

     
     
    function balanceOf(address _owner) public constant returns (uint256) 
    {
        return balances[_owner];
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

    uint public nextInListToReturn = 0;
    uint private constant transfersPerIteration = 50;
    function returnToFunders() private {
        uint afterLast = nextInListToReturn + transfersPerIteration < addressList.length ? nextInListToReturn + transfersPerIteration : addressList.length; 
        
        for (uint i = nextInListToReturn; i < afterLast; i++) {
            address currentUser = addressList[i];
            if (ethBalances[currentUser] > 0) {
                currentUser.transfer(ethBalances[currentUser]);
                ethBalances[currentUser] = 0;
            }
        }
        
        nextInListToReturn = afterLast;
    }
    function withdrawEther() public
    {
        if (isIcoSuccessful()) {
            if(msg.sender == tokenManager && this.balance > 0) 
            {
                escrow.transfer(this.balance);
            }
        }
        else {
            if (isIcoOver()) {
                returnToFunders();
            }
        }
    }
    
    function returnFunds() public {
        returnFundsFor(msg.sender);
    }
    function returnFundsFor(address _user) public {
        assert(isIcoOver() && !isIcoSuccessful());
        assert(msg.sender == tokenManager || msg.sender == address(this));
        
        if (ethBalances[_user] > 0) {
            _user.transfer(ethBalances[_user]);
            ethBalances[_user] = 0;
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

     
    function()  public payable 
    {
        buyTokens(msg.sender);
    }
}