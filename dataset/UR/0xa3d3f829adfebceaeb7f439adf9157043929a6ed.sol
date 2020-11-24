 

pragma solidity ^0.4.15;

 

contract InRiddimCrowdsale {

     

    function InRiddimCrowdsale(address _tokenManager, address _escrow) public {
        tokenManager = _tokenManager;
        escrow = _escrow;
        balanceOf[escrow] += 49000000000000000000000000;  
        totalSupply += 49000000000000000000000000;
    }

     

    string public name = "InRiddim";
    string public  symbol = "IRDM";
    uint   public decimals = 18;

    uint public constant PRICE = 400;  
    
     
     
     

    uint public constant TOKEN_SUPPLY_LIMIT = PRICE * 250000 * (1 ether / 1 wei);
     
    
     

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

     
    address public escrow;

     
    address public crowdsaleManager;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public isSaler;

    modifier onlyTokenManager() { 
        require(msg.sender == tokenManager); 
        _; 
    }
    modifier onlyCrowdsaleManager() {
        require(msg.sender == crowdsaleManager); 
        _; 
    }

    modifier onlyEscrow() {
        require(msg.sender == escrow);
        _;
    }

     

    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);
    event LogPhaseSwitch(Phase newPhase);
     
    event Transfer(address indexed from, address indexed to, uint256 value);

     

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[_from] > _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(balanceOf[msg.sender] - _value < balanceOf[msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }
    
     
    function transfer(address _to, uint256 _value) public
        onlyEscrow
    {
        _transfer(msg.sender, _to, _value);
    }


    function() payable public {
        buy(msg.sender);
    }
    
    function buy(address _buyer) payable public {
         
        require(currentPhase == Phase.Running);
        require(msg.value != 0);
        uint newTokens = msg.value * PRICE;
        require (totalSupply + newTokens < TOKEN_SUPPLY_LIMIT);
        balanceOf[_buyer] += newTokens;
        totalSupply += newTokens;
        LogBuy(_buyer, newTokens);
    }
    
    function buyTokens(address _saler) payable public {
         
        require(isSaler[_saler] == true);
        require(currentPhase == Phase.Running);

        require(msg.value != 0);
        uint newTokens = msg.value * PRICE;
        uint tokenForSaler = newTokens / 20;
        
        require(totalSupply + newTokens + tokenForSaler <= TOKEN_SUPPLY_LIMIT);
        
        balanceOf[_saler] += tokenForSaler;
        balanceOf[msg.sender] += newTokens;

        totalSupply += newTokens;
        totalSupply += tokenForSaler;
        
        LogBuy(msg.sender, newTokens);
    }


     
     
    function burnTokens(address _owner) public
        onlyCrowdsaleManager
    {
         
        require(currentPhase == Phase.Migrating);

        uint tokens = balanceOf[_owner];
        require(tokens != 0);
        balanceOf[_owner] = 0;
        totalSupply -= tokens;
        LogBurn(_owner, tokens);

         
        if (totalSupply == 0) {
            currentPhase = Phase.Migrated;
            LogPhaseSwitch(Phase.Migrated);
        }
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

        require(canSwitchPhase);
        currentPhase = _nextPhase;
        LogPhaseSwitch(_nextPhase);
    }


    function withdrawEther() public
        onlyTokenManager
    {
        require(escrow != 0x0);
         
        if (this.balance > 0) {
            escrow.transfer(this.balance);
        }
    }


    function setCrowdsaleManager(address _mgr) public
        onlyTokenManager
    {
         
        require(currentPhase != Phase.Migrating);
        crowdsaleManager = _mgr;
    }

    function addSaler(address _mgr) public
        onlyTokenManager
    {
        require(currentPhase != Phase.Migrating);
        isSaler[_mgr] = true;
    }

    function removeSaler(address _mgr) public
        onlyTokenManager
    {
        require(currentPhase != Phase.Migrating);
        isSaler[_mgr] = false;
    }
}