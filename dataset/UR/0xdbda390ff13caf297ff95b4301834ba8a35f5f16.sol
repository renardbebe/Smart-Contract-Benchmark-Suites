 

 

pragma solidity ^0.5.8;

 
contract IToken { 

     
    function totalSupply() external view returns (uint);


     
    function balanceOf(address _owner) external view returns (uint);


     
    function transfer(address _to, uint _value) external returns (bool);


     
    function transferFrom(address _from, address _to, uint _value) external returns (bool);


     
    function approve(address _spender, uint _value) external returns (bool);


     
    function allowance(address _owner, address _spender) external view returns (uint);
}


 
contract IManagedToken is IToken { 

     
    function isLocked() external view returns (bool);


     
    function lock() external returns (bool);


     
    function unlock() external returns (bool);


     
    function issue(address _to, uint _value) external returns (bool);


     
    function burn(address _from, uint _value) external returns (bool);
}


 
contract ITokenObserver {


     
    function notifyTokensReceived(address _from, uint _value) external;
}


 
contract TokenObserver is ITokenObserver {


     
    function notifyTokensReceived(address _from, uint _value) public {
        onTokensReceived(msg.sender, _from, _value);
    }


     
    function onTokensReceived(address _token, address _from, uint _value) internal;
}


 
contract ITokenRetriever {

     
    function retrieveTokens(address _tokenContract) external;
}


 
contract TokenRetriever is ITokenRetriever {

     
    function retrieveTokens(address _tokenContract) public {
        IToken tokenInstance = IToken(_tokenContract);
        uint tokenBalance = tokenInstance.balanceOf(address(this));
        if (tokenBalance > 0) {
            tokenInstance.transfer(msg.sender, tokenBalance);
        }
    }
}


 
contract IObservable {


     
    function isObserver(address _account) external view returns (bool);


     
    function getObserverCount() external view returns (uint);


     
    function getObserverAtIndex(uint _index) external view returns (address);


     
    function registerObserver(address _observer) external;


     
    function unregisterObserver(address _observer) external;
}


 
contract IOwnership {

     
    function isOwner(address _account) public view returns (bool);


     
    function getOwner() public view returns (address);
}


 
contract Ownership is IOwnership {

     
    address internal owner;


     
    constructor() public {
        owner = msg.sender;
    }


     
    modifier only_owner() {
        require(msg.sender == owner, "m:only_owner");
        _;
    }


     
    function isOwner(address _account) public view returns (bool) {
        return _account == owner;
    }


     
    function getOwner() public view returns (address) {
        return owner;
    }
}

 
contract ITransferableOwnership {
    

     
    function transferOwnership(address _newOwner) external;
}


 
contract TransferableOwnership is ITransferableOwnership, Ownership {


     
    function transferOwnership(address _newOwner) public only_owner {
        owner = _newOwner;
    }
}

 
contract IMultiOwned {

     
    function isOwner(address _account) public view returns (bool);


     
    function getOwnerCount() public view returns (uint);


     
    function getOwnerAt(uint _index) public view returns (address);


      
    function addOwner(address _account) public;


     
    function removeOwner(address _account) public;
}

 
contract IAuthenticator {
    

     
    function authenticate(address _account) public view returns (bool);
}


 
contract DcorpDissolvementProposal is TokenObserver, TransferableOwnership, TokenRetriever {

    enum Stages {
        Deploying,
        Deployed,
        Executed
    }

    struct Balance {
        uint drps;
        uint drpu;
        uint index;
    }

     
    Stages private stage;

     
    uint public constant CLAIMING_DURATION = 60 days;
    uint public constant WITHDRAW_DURATION = 60 days;
    uint public constant DISSOLVEMENT_AMOUNT = 948 ether;  

     
    mapping (address => Balance) private allocated;
    address[] private allocatedIndex;

     
    IAuthenticator public authenticator;

     
    IToken public drpsToken;
    IToken public drpuToken;

     
    address public prevProxy;
    uint public prevProxyRecordedBalance;

     
    address payable public dissolvementFund;

    uint public claimTotalWeight;
    uint public claimTotalEther;
    uint public claimDeadline;
    uint public withdrawDeadline;
    

     
    modifier only_authenticated() {
        require(authenticator.authenticate(msg.sender), "m:only_authenticated");
        _;
    }


     
    modifier only_at_stage(Stages _stage) {
        require(stage == _stage, "m:only_at_stage");
        _;
    }


     
    modifier only_accepted_token(address _token) {
        require(_token == address(drpsToken) || _token == address(drpuToken), "m:only_accepted_token");
        _;
    }


     
    modifier not_accepted_token(address _token) {
        require(_token != address(drpsToken) && _token != address(drpuToken), "m:not_accepted_token");
        _;
    }


     
    modifier only_token_holder() {
        require(allocated[msg.sender].drps > 0 || allocated[msg.sender].drpu > 0, "m:only_token_holder");
        _;
    }


     
    modifier only_during_claiming_period() {
        require(claimDeadline > 0 && now <= claimDeadline, "m:only_during_claiming_period");
        _;
    }


     
    modifier only_after_claiming_period() {
        require(claimDeadline > 0 && now > claimDeadline, "m:only_after_claiming_period");
        _;
    }


     
    modifier only_during_withdraw_period() {
        require(withdrawDeadline > 0 && now <= withdrawDeadline, "m:only_during_withdraw_period");
        _;
    }


     
    modifier only_after_withdraw_period() {
        require(withdrawDeadline > 0 && now > withdrawDeadline, "m:only_after_withdraw_period");
        _;
    }
    

     
    constructor(address _authenticator, address _drpsToken, address _drpuToken, address _prevProxy, address payable _dissolvementFund) public {
        authenticator = IAuthenticator(_authenticator);
        drpsToken = IToken(_drpsToken);
        drpuToken = IToken(_drpuToken);
        prevProxy = _prevProxy;
        prevProxyRecordedBalance = _prevProxy.balance;
        dissolvementFund = _dissolvementFund;
        stage = Stages.Deploying;
    }


     
    function isDeploying() public view returns (bool) {
        return stage == Stages.Deploying;
    }


     
    function isDeployed() public view returns (bool) {
        return stage == Stages.Deployed;
    }


     
    function isExecuted() public view returns (bool) {
        return stage == Stages.Executed;
    }


     
    function () external payable only_at_stage(Stages.Deploying) {
        require(msg.sender == address(prevProxy), "f:fallback;e:invalid_sender");
    }


     
    function deploy() public only_owner only_at_stage(Stages.Deploying) {
        require(address(this).balance >= prevProxyRecordedBalance, "f:deploy;e:invalid_balance");

         
        stage = Stages.Deployed;
        
         
        claimDeadline = now + CLAIMING_DURATION;

         
        IObservable(address(drpsToken)).unregisterObserver(prevProxy);
        IObservable(address(drpuToken)).unregisterObserver(prevProxy);

         
        IObservable(address(drpsToken)).registerObserver(address(this));
        IObservable(address(drpuToken)).registerObserver(address(this));

         
        uint amountToTransfer = DISSOLVEMENT_AMOUNT;
        if (amountToTransfer > address(this).balance) {
            amountToTransfer = address(this).balance;
        }

        dissolvementFund.transfer(amountToTransfer);
    }


     
    function getTotalSupply() public view returns (uint) {
        uint sum = 0; 
        sum += drpsToken.totalSupply();
        sum += drpuToken.totalSupply();
        return sum;
    }


     
    function hasBalance(address _owner) public view returns (bool) {
        return allocatedIndex.length > 0 && _owner == allocatedIndex[allocated[_owner].index];
    }


     
    function balanceOf(address _token, address _owner) public view returns (uint) {
        uint balance = 0;
        if (address(drpsToken) == _token) {
            balance = allocated[_owner].drps;
        } 
        
        else if (address(drpuToken) == _token) {
            balance = allocated[_owner].drpu;
        }

        return balance;
    }


     
    function execute() public only_at_stage(Stages.Deployed) only_after_claiming_period {
        
         
        stage = Stages.Executed;
        withdrawDeadline = now + WITHDRAW_DURATION;

         
        claimTotalEther = address(this).balance;

         
        IManagedToken(address(drpsToken)).lock();
        IManagedToken(address(drpuToken)).lock();

         
        IMultiOwned(address(drpsToken)).removeOwner(address(this));
        IMultiOwned(address(drpuToken)).removeOwner(address(this));
    }


     
    function withdraw() public only_at_stage(Stages.Executed) only_during_withdraw_period only_token_holder only_authenticated {
        Balance storage b = allocated[msg.sender];
        uint weight = b.drpu + _convertDrpsWeight(b.drps);

         
        b.drpu = 0;
        b.drps = 0;

         
        uint amountToTransfer = weight * claimTotalEther / claimTotalWeight;
        msg.sender.transfer(amountToTransfer);
    }


     
    function onTokensReceived(address _token, address _from, uint _value) internal only_during_claiming_period only_accepted_token(_token) {
        require(_token == msg.sender, "f:onTokensReceived;e:only_receiving_token");

         
        if (!hasBalance(_from)) {
            allocated[_from] = Balance(
                0, 0, allocatedIndex.push(_from) - 1);
        }

        Balance storage b = allocated[_from];
        if (_token == address(drpsToken)) {
            b.drps += _value;
            claimTotalWeight += _convertDrpsWeight(_value);
        } else {
            b.drpu += _value;
            claimTotalWeight += _value;
        }
    }


     
    function retrieveEther() public only_owner only_after_withdraw_period {
        selfdestruct(msg.sender);
    }


     
    function retrieveTokens(address _tokenContract) public only_owner not_accepted_token(_tokenContract) {
        super.retrieveTokens(_tokenContract);
    }


     
    function _convertDrpsWeight(uint _value) private pure returns (uint) {
        return _value * 2;
    }
}