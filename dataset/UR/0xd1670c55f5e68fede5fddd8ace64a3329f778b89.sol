 

pragma solidity ^0.4.23;

 
contract ATSTokenReservation {

     

    enum States {
        Init,  
        Open,  
        Locked,  
        Over  
    }

     

     
    uint32 FALLBACK_PAYOUT_TS = 1538352000;

     

    States public state = States.Init;

     
    address public stateController;

     
    address public whitelistController;

     
    address public payoutAddress;

     
    uint256 public cumAcceptedDeposits = 0;
     
    uint256 public cumAlienDeposits = 0;

     
    uint256 public maxCumAcceptedDeposits = 1E9 * 1E18;  

    uint256 public minDeposit = 0.1 * 1E18;  

    uint256 minLockingTs;  

     
    mapping (address => bool) public whitelist;

     
    bool public requireWhitelistingBeforeDeposit = false;

     
    mapping (address => uint256) public acceptedDeposits;

     
    mapping (address => uint256) public alienDeposits;

     

     
     

    event StateTransition(States oldState, States newState);
    event Whitelisted(address addr);
    event Deposit(address addr, uint256 amount);
    event Refund(address addr, uint256 amount);

     
    event FetchedDeposits(uint256 amount);

     

    modifier onlyStateControl() { require(msg.sender == stateController, "no permission"); _; }

    modifier onlyWhitelistControl()	{
        require(msg.sender == stateController || msg.sender == whitelistController, "no permission");
        _;
    }

    modifier requireState(States _requiredState) { require(state == _requiredState, "wrong state"); _; }

     

     
    constructor(address _whitelistController, address _payoutAddress) public {
        whitelistController = _whitelistController;
        payoutAddress = _payoutAddress;
        stateController = msg.sender;
    }

     

     
    function () payable public {
        if(msg.value > 0) {
            require(state == States.Open || state == States.Locked);
            if(requireWhitelistingBeforeDeposit) {
                require(whitelist[msg.sender] == true, "not whitelisted");
            }
            tryDeposit();
        } else {
            tryRefund();
        }
    }

     

    function stateSetOpen(uint32 _minLockingTs) public
        onlyStateControl
        requireState(States.Init)
    {
        minLockingTs = _minLockingTs;
        setState(States.Open);
    }

    function stateSetLocked() public
        onlyStateControl
        requireState(States.Open)
    {
        require(block.timestamp >= minLockingTs);
        setState(States.Locked);
    }

    function stateSetOver() public
        onlyStateControl
        requireState(States.Locked)
    {
        setState(States.Over);
    }

     
    function updateMaxAcceptedDeposits(uint256 _newMaxDeposits) public onlyStateControl {
        require(cumAcceptedDeposits <= _newMaxDeposits);
        maxCumAcceptedDeposits = _newMaxDeposits;
    }

     
    function updateMinDeposit(uint256 _newMinDeposit) public onlyStateControl {
        minDeposit = _newMinDeposit;
    }

     
    function setRequireWhitelistingBeforeDeposit(bool _newState) public onlyStateControl {
        requireWhitelistingBeforeDeposit = _newState;
    }

     
     
     
     
     
     
    function addToWhitelist(address _addr) public onlyWhitelistControl {
        if(whitelist[_addr] != true) {
             
            if(alienDeposits[_addr] > 0) {
                cumAcceptedDeposits += alienDeposits[_addr];
                acceptedDeposits[_addr] += alienDeposits[_addr];
                cumAlienDeposits -= alienDeposits[_addr];
                delete alienDeposits[_addr];  
            }
            whitelist[_addr] = true;
            emit Whitelisted(_addr);
        }
    }

     
     
    function batchAddToWhitelist(address[] _addresses) public onlyWhitelistControl {
        for (uint i = 0; i < _addresses.length; i++) {
            addToWhitelist(_addresses[i]);
        }
    }


     
    function refundAlienDeposit(address _addr) public onlyWhitelistControl {
         
         
        uint256 withdrawAmount = alienDeposits[_addr];
        require(withdrawAmount > 0);
        delete alienDeposits[_addr];  
        cumAlienDeposits -= withdrawAmount;
        emit Refund(_addr, withdrawAmount);
        _addr.transfer(withdrawAmount);  
    }

     
    function payout() public
        onlyStateControl
        requireState(States.Over)
    {
        uint256 amount = cumAcceptedDeposits;
        cumAcceptedDeposits = 0;
        emit FetchedDeposits(amount);
        payoutAddress.transfer(amount);
         
    }

     
     
     
     
    function fallbackPayout() public {
        require(msg.sender == stateController || msg.sender == whitelistController || msg.sender == payoutAddress);
        require(block.timestamp > FALLBACK_PAYOUT_TS);
        payoutAddress.transfer(address(this).balance);
    }

     

     
    function tryDeposit() internal {
        require(cumAcceptedDeposits + msg.value <= maxCumAcceptedDeposits);
        if(whitelist[msg.sender] == true) {
            require(acceptedDeposits[msg.sender] + msg.value >= minDeposit);
            acceptedDeposits[msg.sender] += msg.value;
            cumAcceptedDeposits += msg.value;
        } else {
            require(alienDeposits[msg.sender] + msg.value >= minDeposit);
            alienDeposits[msg.sender] += msg.value;
            cumAlienDeposits += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }

     
    function tryRefund() internal {
         
         
        uint256 withdrawAmount;
        if(whitelist[msg.sender] == true) {
            require(state == States.Open);
            withdrawAmount = acceptedDeposits[msg.sender];
            require(withdrawAmount > 0);
            delete acceptedDeposits[msg.sender];  
            cumAcceptedDeposits -= withdrawAmount;
        } else {
             
            withdrawAmount = alienDeposits[msg.sender];
            require(withdrawAmount > 0);
            delete alienDeposits[msg.sender];  
            cumAlienDeposits -= withdrawAmount;
        }
        emit Refund(msg.sender, withdrawAmount);
         
        msg.sender.transfer(withdrawAmount);  
    }

    function setState(States _newState) internal {
        state = _newState;
        emit StateTransition(state, _newState);
    }
}