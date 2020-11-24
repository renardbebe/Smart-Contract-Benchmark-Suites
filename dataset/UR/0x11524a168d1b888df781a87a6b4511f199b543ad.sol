 

pragma solidity ^0.4.18;

 
contract AllPubs {
     
    uint256 constant public registrationBounty = 50 finney;
     
    uint256 constant public invalidationBounty = 5 finney;

    enum Membership {
        UNCONTACTED,  
        REJECTED,  
        APPLIED,  
        ACCEPTED,  
        BOARD,  
        SOURCE  
    }

    mapping (address => Membership) public membership;
     
    mapping (address => string) public abis;
    address[] public pubs;

    function AllPubs()
    public {
        membership[msg.sender] = Membership.SOURCE;
    }

    event PubRegistered(address location);

    event PubAccepted(address location);

    event PubRejected(address location, string reason);

    function pubCount()
    public view
    returns (uint256) {
        return pubs.length;
    }


    function register(address _pubish, string _abi)
    external payable {
        assert(msg.value == registrationBounty);
        assert(membership[_pubish] <= Membership.REJECTED);
        membership[_pubish] = Membership.APPLIED;
        abis[_pubish] = _abi;
        PubRegistered(_pubish);
    }

    function accept(address _pubish)
    external {
        assert(membership[msg.sender] >= Membership.BOARD);
        assert(membership[_pubish] == Membership.APPLIED);
        membership[_pubish] = Membership.ACCEPTED;
        msg.sender.transfer(registrationBounty);
        pubs.push(_pubish);
        PubAccepted(_pubish);
    }

    function reject(address _pubish, string _reason)
    external {
        assert(membership[msg.sender] >= Membership.BOARD);
        assert(membership[_pubish] == Membership.APPLIED);
        membership[_pubish] = Membership.REJECTED;
        msg.sender.transfer(invalidationBounty);
        PubRejected(_pubish, _reason);
    }

    event NewBoardMember(address _boardMember);

    function appoint(address _delegate)
    external {
        assert(membership[msg.sender] >= Membership.BOARD);
        assert(membership[_delegate] == Membership.UNCONTACTED);
        membership[_delegate] = Membership.BOARD;
        NewBoardMember(_delegate);
    }
}