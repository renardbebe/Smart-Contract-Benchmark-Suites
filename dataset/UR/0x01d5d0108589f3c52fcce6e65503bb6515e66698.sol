 

pragma solidity ^0.4.15;

 
contract IOwnership {

     
    function isOwner(address _account) constant returns (bool);


     
    function getOwner() constant returns (address);
}


 
contract Ownership is IOwnership {

     
    address internal owner;


     
    function Ownership() {
        owner = msg.sender;
    }


     
    modifier only_owner() {
        require(msg.sender == owner);
        _;
    }


     
    function isOwner(address _account) public constant returns (bool) {
        return _account == owner;
    }


     
    function getOwner() public constant returns (address) {
        return owner;
    }
}


 
contract ITransferableOwnership {
    

     
    function transferOwnership(address _newOwner);
}


 
contract TransferableOwnership is ITransferableOwnership, Ownership {


     
    function transferOwnership(address _newOwner) public only_owner {
        owner = _newOwner;
    }
}


 
contract IMultiOwned {

     
    function isOwner(address _account) constant returns (bool);


     
    function getOwnerCount() constant returns (uint);


     
    function getOwnerAt(uint _index) constant returns (address);


      
    function addOwner(address _account);


     
    function removeOwner(address _account);
}


 
contract ITokenRetriever {

     
    function retrieveTokens(address _tokenContract);
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


 
contract ITokenObserver {

     
    function notifyTokensReceived(address _from, uint _value);
}


 
contract TokenObserver is ITokenObserver {

     
    function notifyTokensReceived(address _from, uint _value) public {
        onTokensReceived(msg.sender, _from, _value);
    }


     
    function onTokensReceived(address _token, address _from, uint _value) internal;
}


 
contract IToken { 

     
    function totalSupply() constant returns (uint);


     
    function balanceOf(address _owner) constant returns (uint);


     
    function transfer(address _to, uint _value) returns (bool);


     
    function transferFrom(address _from, address _to, uint _value) returns (bool);


     
    function approve(address _spender, uint _value) returns (bool);


     
    function allowance(address _owner, address _spender) constant returns (uint);
}


 
contract DcorpProxy is TokenObserver, TransferableOwnership, TokenRetriever {

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

    struct Vote {
        uint datetime;
        bool support;
        uint index;
    }

    struct Proposal {
        uint createdTimestamp;
        uint supportingWeight;
        uint rejectingWeight;
        mapping(address => Vote) votes;
        address[] voteIndex;
        uint index;
    }

     
    Stages private stage;

     
    uint private constant VOTING_DURATION = 7 days;
    uint private constant MIN_QUORUM = 5;  

     
    mapping (address => Balance) private allocated;
    address[] private allocatedIndex;

     
    mapping(address => Proposal) private proposals;
    address[] private proposalIndex;

     
    IToken private drpsToken;
    IToken private drpuToken;

     
    address private drpCrowdsale;
    uint public drpCrowdsaleRecordedBalance;


     
    modifier only_at_stage(Stages _stage) {
        require(stage == _stage);
        _;
    }


     
    modifier only_accepted_token(address _token) {
        require(_token == address(drpsToken) || _token == address(drpuToken));
        _;
    }


     
    modifier not_accepted_token(address _token) {
        require(_token != address(drpsToken) && _token != address(drpuToken));
        _;
    }


     
    modifier only_token_holder() {
        require(allocated[msg.sender].drps > 0 || allocated[msg.sender].drpu > 0);
        _;
    }


     
    modifier only_proposed(address _proposedAddress) {
        require(isProposed(_proposedAddress));
        _;
    }


     
    modifier only_during_voting_period(address _proposedAddress) {
        require(now <= proposals[_proposedAddress].createdTimestamp + VOTING_DURATION);
        _;
    }


     
    modifier only_after_voting_period(address _proposedAddress) {
        require(now > proposals[_proposedAddress].createdTimestamp + VOTING_DURATION);
        _;
    }


     
    modifier only_when_supported(address _proposedAddress) {
        require(isSupported(_proposedAddress, false));
        _;
    }
    

     
    function DcorpProxy(address _drpsToken, address _drpuToken, address _drpCrowdsale) {
        drpsToken = IToken(_drpsToken);
        drpuToken = IToken(_drpuToken);
        drpCrowdsale = _drpCrowdsale;
        drpCrowdsaleRecordedBalance = _drpCrowdsale.balance;
        stage = Stages.Deploying;
    }


     
    function isDeploying() public constant returns (bool) {
        return stage == Stages.Deploying;
    }


     
    function isDeployed() public constant returns (bool) {
        return stage == Stages.Deployed;
    }


     
    function isExecuted() public constant returns (bool) {
        return stage == Stages.Executed;
    }


     
    function () public payable only_at_stage(Stages.Deploying) {
        require(msg.sender == drpCrowdsale);
    }


     
    function deploy() only_owner only_at_stage(Stages.Deploying) {
        require(this.balance >= drpCrowdsaleRecordedBalance);
        stage = Stages.Deployed;
    }


     
    function getTotalSupply() public constant returns (uint) {
        uint sum = 0; 
        sum += drpsToken.totalSupply();
        sum += drpuToken.totalSupply();
        return sum;
    }


     
    function hasBalance(address _owner) public constant returns (bool) {
        return allocatedIndex.length > 0 && _owner == allocatedIndex[allocated[_owner].index];
    }


     
    function balanceOf(address _token, address _owner) public constant returns (uint) {
        uint balance = 0;
        if (address(drpsToken) == _token) {
            balance = allocated[_owner].drps;
        } 
        
        else if (address(drpuToken) == _token) {
            balance = allocated[_owner].drpu;
        }

        return balance;
    }


     
    function isProposed(address _proposedAddress) public constant returns (bool) {
        return proposalIndex.length > 0 && _proposedAddress == proposalIndex[proposals[_proposedAddress].index];
    }


     
    function getProposalCount() public constant returns (uint) {
        return proposalIndex.length;
    }


     
    function propose(address _proposedAddress) public only_owner only_at_stage(Stages.Deployed) {
        require(!isProposed(_proposedAddress));

         
        Proposal storage p = proposals[_proposedAddress];
        p.createdTimestamp = now;
        p.index = proposalIndex.push(_proposedAddress) - 1;
    }


     
    function getVotingDuration() public constant returns (uint) {              
        return VOTING_DURATION;
    }


     
    function getVoteCount(address _proposedAddress) public constant returns (uint) {              
        return proposals[_proposedAddress].voteIndex.length;
    }


     
    function hasVoted(address _proposedAddress, address _account) public constant returns (bool) {
        bool voted = false;
        if (getVoteCount(_proposedAddress) > 0) {
            Proposal storage p = proposals[_proposedAddress];
            voted = p.voteIndex[p.votes[_account].index] == _account;
        }

        return voted;
    }


     
    function getVote(address _proposedAddress, address _account) public constant returns (bool) {
        return proposals[_proposedAddress].votes[_account].support;
    }


     
    function vote(address _proposedAddress, bool _support) public only_at_stage(Stages.Deployed) only_proposed(_proposedAddress) only_during_voting_period(_proposedAddress) only_token_holder {    
        Proposal storage p = proposals[_proposedAddress];
        Balance storage b = allocated[msg.sender];
        
         
        if (!hasVoted(_proposedAddress, msg.sender)) {
            p.votes[msg.sender] = Vote(
                now, _support, p.voteIndex.push(msg.sender) - 1);

             
            if (_support) {
                p.supportingWeight += b.drps + b.drpu;
            } else {
                p.rejectingWeight += b.drps + b.drpu;
            }
        } else {
            Vote storage v = p.votes[msg.sender];
            if (v.support != _support) {

                 
                if (_support) {
                    p.supportingWeight += b.drps + b.drpu;
                    p.rejectingWeight -= b.drps + b.drpu;
                } else {
                    p.rejectingWeight += b.drps + b.drpu;
                    p.supportingWeight -= b.drps + b.drpu;
                }

                v.support = _support;
                v.datetime = now;
            }
        }
    }


     
    function getVotingResult(address _proposedAddress) public constant returns (uint, uint) {      
        Proposal storage p = proposals[_proposedAddress];    
        return (p.supportingWeight, p.rejectingWeight);
    }


     
    function isSupported(address _proposedAddress, bool _strict) public constant returns (bool) {        
        Proposal storage p = proposals[_proposedAddress];
        bool supported = false;

        if (!_strict || now > p.createdTimestamp + VOTING_DURATION) {
            var (support, reject) = getVotingResult(_proposedAddress);
            supported = support > reject;
            if (supported) {
                supported = support + reject >= getTotalSupply() * MIN_QUORUM / 100;
            }
        }
        
        return supported;
    }


     
    function execute(address _acceptedAddress) public only_owner only_at_stage(Stages.Deployed) only_proposed(_acceptedAddress) only_after_voting_period(_acceptedAddress) only_when_supported(_acceptedAddress) {
        
         
        stage = Stages.Executed;

         
        IMultiOwned(drpsToken).addOwner(_acceptedAddress);
        IMultiOwned(drpuToken).addOwner(_acceptedAddress);

         
        IMultiOwned(drpsToken).removeOwner(this);
        IMultiOwned(drpuToken).removeOwner(this);

         
        uint balanceBefore = _acceptedAddress.balance;
        uint balanceToSend = this.balance;
        _acceptedAddress.transfer(balanceToSend);

         
        assert(balanceBefore + balanceToSend == _acceptedAddress.balance);
        assert(this.balance == 0);
    }


     
    function onTokensReceived(address _token, address _from, uint _value) internal only_at_stage(Stages.Deployed) only_accepted_token(_token) {
        require(_token == msg.sender);

         
        if (!hasBalance(_from)) {
            allocated[_from] = Balance(
                0, 0, allocatedIndex.push(_from) - 1);
        }

        Balance storage b = allocated[_from];
        if (_token == address(drpsToken)) {
            b.drps += _value;
        } else {
            b.drpu += _value;
        }

         
        _adjustWeight(_from, _value, true);
    }


     
    function withdrawDRPS(uint _value) public {
        Balance storage b = allocated[msg.sender];

         
        require(b.drps >= _value);
        require(b.drps - _value <= b.drps);

         
        b.drps -= _value;

         
        _adjustWeight(msg.sender, _value, false);

         
        if (!drpsToken.transfer(msg.sender, _value)) {
            revert();
        }
    }


     
    function withdrawDRPU(uint _value) public {
        Balance storage b = allocated[msg.sender];

         
        require(b.drpu >= _value);
        require(b.drpu - _value <= b.drpu);

         
        b.drpu -= _value;

         
        _adjustWeight(msg.sender, _value, false);

         
        if (!drpuToken.transfer(msg.sender, _value)) {
            revert();
        }
    }


     
    function retrieveTokens(address _tokenContract) public only_owner not_accepted_token(_tokenContract) {
        super.retrieveTokens(_tokenContract);
    }


     
    function _adjustWeight(address _owner, uint _value, bool _increase) private {
        for (uint i = proposalIndex.length; i > 0; i--) {
            Proposal storage p = proposals[proposalIndex[i - 1]];
            if (now > p.createdTimestamp + VOTING_DURATION) {
                break;  
            }

            if (hasVoted(proposalIndex[i - 1], _owner)) {
                if (p.votes[_owner].support) {
                    if (_increase) {
                        p.supportingWeight += _value;
                    } else {
                        p.supportingWeight -= _value;
                    }
                } else {
                    if (_increase) {
                        p.rejectingWeight += _value;
                    } else {
                        p.rejectingWeight -= _value;
                    }
                }
            }
        }
    }
}