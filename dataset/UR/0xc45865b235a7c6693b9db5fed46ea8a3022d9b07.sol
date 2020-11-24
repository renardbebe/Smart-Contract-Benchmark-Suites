 

pragma solidity ^0.4.18;

 
interface IOwnership {

     
    function isOwner(address _account) public view returns (bool);


     
    function getOwner() public view returns (address);
}


 
contract Ownership is IOwnership {

     
    address internal owner;


     
    modifier only_owner() {
        require(msg.sender == owner);
        _;
    }


     
    function Ownership() public {
        owner = msg.sender;
    }


     
    function isOwner(address _account) public view returns (bool) {
        return _account == owner;
    }


     
    function getOwner() public view returns (address) {
        return owner;
    }
}


 
interface IToken { 

     
    function totalSupply() public view returns (uint);


     
    function balanceOf(address _owner) public view returns (uint);


     
    function transfer(address _to, uint _value) public returns (bool);


     
    function transferFrom(address _from, address _to, uint _value) public returns (bool);


     
    function approve(address _spender, uint _value) public returns (bool);


     
    function allowance(address _owner, address _spender) public view returns (uint);
}


 
interface ITokenObserver {


     
    function notifyTokensReceived(address _from, uint _value) public;
}


 
contract TokenObserver is ITokenObserver {


     
    function notifyTokensReceived(address _from, uint _value) public {
        onTokensReceived(msg.sender, _from, _value);
    }


     
    function onTokensReceived(address _token, address _from, uint _value) internal;
}


 
interface ITokenRetriever {

     
    function retrieveTokens(address _tokenContract) public;
}


 
contract TokenRetriever is ITokenRetriever {

     
    function retrieveTokens(address _tokenContract) public {
        IToken tokenInstance = IToken(_tokenContract);
        uint tokenBalance = tokenInstance.balanceOf(this);
        if (tokenBalance > 0) {
            tokenInstance.transfer(msg.sender, tokenBalance);
        }
    }
}


 
interface IDcorpCrowdsaleAdapter {

     
    function isEnded() public view returns (bool);


     
    function contribute() public payable returns (uint);


     
    function contributeFor(address _beneficiary) public payable returns (uint);


     
    function withdrawTokens() public;


     
    function withdrawEther() public;


     
    function refund() public;
}


 
interface IDcorpPersonalCrowdsaleProxy {

     
    function () public payable;
}


 
contract DcorpPersonalCrowdsaleProxy is IDcorpPersonalCrowdsaleProxy {

    address public member;
    IDcorpCrowdsaleAdapter public target;
    

     
    function DcorpPersonalCrowdsaleProxy(address _member, address _target) public {
        target = IDcorpCrowdsaleAdapter(_target);
        member = _member;
    }


     
    function () public payable {
        target.contributeFor.value(msg.value)(member);
    }
}


 
interface IDcorpCrowdsaleProxy {

     
    function () public payable;


     
    function contribute() public payable returns (uint);


     
    function contributeFor(address _beneficiary) public payable returns (uint);
}


 
contract DcorpCrowdsaleProxy is IDcorpCrowdsaleProxy, Ownership, TokenObserver, TokenRetriever {

    enum Stages {
        Deploying,
        Attached,
        Deployed
    }

    struct Record {
        uint weight;
        uint contributed;
        uint withdrawnTokens;
        uint index;
    }

    Stages public stage;
    bool private updating;

     
    mapping (address => Record) private records;
    address[] private recordIndex;

    uint public totalContributed;
    uint public totalTokensReceived;
    uint public totalTokensWithdrawn;
    uint public totalWeight;

     
    uint public factorWeight;
    uint public factorContributed;

     
    IDcorpCrowdsaleAdapter public crowdsale;
    IToken public token;

     
    IToken public drpsToken;
    IToken public drpuToken;


     
    modifier at_stage(Stages _stage) {
        require(stage == _stage);
        _;
    }


     
    modifier only_when_ended() {
        require(crowdsale.isEnded());
        _;
    }


     
    modifier only_when_not_updating() {
        require(!updating);
        _;
    }


     
    event DcorpProxyCreated(address proxy, address beneficiary);


     
    function DcorpCrowdsaleProxy() public {
        stage = Stages.Deploying;
    }


     
    function setup(address _drpsToken, address _drpuToken, uint _factorWeight, uint _factorContributed) public only_owner at_stage(Stages.Deploying) {
        drpsToken = IToken(_drpsToken);
        drpuToken = IToken(_drpuToken);
        factorWeight = _factorWeight;
        factorContributed = _factorContributed;
    }

    
     
    function attachCrowdsale(address _crowdsale, address _token) public only_owner at_stage(Stages.Deploying) {
        stage = Stages.Attached;
        crowdsale = IDcorpCrowdsaleAdapter(_crowdsale);
        token = IToken(_token);
    }


     
    function deploy() public only_owner at_stage(Stages.Attached) {
        stage = Stages.Deployed;
    }


     
    function createPersonalDepositAddress() public returns (address) {
        address proxy = new DcorpPersonalCrowdsaleProxy(msg.sender, this);
        DcorpProxyCreated(proxy, msg.sender);
        return proxy;
    }


     
    function createPersonalDepositAddressFor(address _beneficiary) public returns (address) {
        address proxy = new DcorpPersonalCrowdsaleProxy(_beneficiary, this);
        DcorpProxyCreated(proxy, _beneficiary);
        return proxy;
    }


     
    function hasRecord(address _member) public view returns (bool) {
        return records[_member].index < recordIndex.length && _member == recordIndex[records[_member].index];
    }


     
    function contributedAmountOf(address _member) public view returns (uint) {
        return records[_member].contributed;
    }


     
    function balanceOf(address _member) public view returns (uint) {
        Record storage r = records[_member];
        uint balance = 0;
        uint share = shareOf(_member);
        if (share > 0 && r.withdrawnTokens < share) {
            balance = share - r.withdrawnTokens;
        }

        return balance;
    }


     
    function shareOf(address _member) public view returns (uint) {
        Record storage r = records[_member];

         
        uint factoredTotalWeight = totalWeight * factorWeight;
        uint factoredTotalContributed = totalContributed * factorContributed;

         
        uint factoredWeight = r.weight * factorWeight;
        uint factoredContributed = r.contributed * factorContributed;

         
        return (factoredWeight + factoredContributed) * totalTokensReceived / (factoredTotalWeight + factoredTotalContributed);
    }


     
    function requestTokensFromCrowdsale() public only_when_not_updating {
        crowdsale.withdrawTokens();
    }


     
    function updateBalances() public only_when_not_updating {
        updating = true;

        uint recordedBalance = totalTokensReceived - totalTokensWithdrawn;
        uint actualBalance = token.balanceOf(this);
        
         
        if (actualBalance > recordedBalance) {
            totalTokensReceived += actualBalance - recordedBalance;
        }

        updating = false;
    }


     
    function withdrawTokens() public only_when_ended only_when_not_updating {
        address member = msg.sender;
        uint balance = balanceOf(member);

         
        records[member].withdrawnTokens += balance;
        totalTokensWithdrawn += balance;

         
        if (!token.transfer(member, balance)) {
            revert();
        }
    }


     
    function () public payable {
        require(msg.sender == tx.origin);
        _handleTransaction(msg.sender);
    }


     
    function contribute() public payable returns (uint) {
        return _handleTransaction(msg.sender);
    }


     
    function contributeFor(address _beneficiary) public payable returns (uint) {
        return _handleTransaction(_beneficiary);
    }


     
    function retrieveTokens(address _tokenContract) public only_owner {
        require(_tokenContract != address(token));
        super.retrieveTokens(_tokenContract);
    }


     
    function onTokensReceived(address _token, address _from, uint _value) internal {
        require(_token == msg.sender);
        require(_token == address(token));
        require(_from == address(0));
        
         
        totalTokensReceived += _value;
    }


     
    function _handleTransaction(address _beneficiary) private only_when_not_updating at_stage(Stages.Deployed) returns (uint) {
        uint weight = _getWeight(_beneficiary);
        uint received = msg.value;

         
        uint acceptedAmount = crowdsale.contributeFor.value(received)(_beneficiary);

         
        if (!hasRecord(_beneficiary)) {
            records[_beneficiary] = Record(
                weight, acceptedAmount, 0, recordIndex.push(_beneficiary) - 1);
            totalWeight += weight;
        } else {
            Record storage r = records[_beneficiary];
            r.contributed += acceptedAmount;
            if (weight < r.weight) {
                 
                r.weight = weight;
                totalWeight -= r.weight - weight;
            }
        }

         
        totalContributed += acceptedAmount;
        return acceptedAmount;
    }


     
    function _getWeight(address _account) private view returns (uint) {
        return drpsToken.balanceOf(_account) + drpuToken.balanceOf(_account);
    }
}


contract KATXDcorpMemberProxy is DcorpCrowdsaleProxy {
    function KATXDcorpMemberProxy() public DcorpCrowdsaleProxy() {}
}