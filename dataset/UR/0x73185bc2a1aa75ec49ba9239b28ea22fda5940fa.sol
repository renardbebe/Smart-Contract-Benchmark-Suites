 

pragma solidity ^0.4.13;

contract DSExec {
    function tryExec( address target, bytes calldata, uint value)
             internal
             returns (bool call_ret)
    {
        return target.call.value(value)(calldata);
    }
    function exec( address target, bytes calldata, uint value)
             internal
    {
        if(!tryExec(target, calldata, value)) {
            revert();
        }
    }

     
    function exec( address t, bytes c )
        internal
    {
        exec(t, c, 0);
    }
    function exec( address t, uint256 v )
        internal
    {
        bytes memory c; exec(t, c, v);
    }
    function tryExec( address t, bytes c )
        internal
        returns (bool)
    {
        return tryExec(t, c, 0);
    }
    function tryExec( address t, uint256 v )
        internal
        returns (bool)
    {
        bytes memory c; return tryExec(t, c, v);
    }
}

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

contract DSGroup is DSExec, DSNote {
    address[]  public  members;
    uint       public  quorum;
    uint       public  window;
    uint       public  actionCount;

    mapping (uint => Action)                     public  actions;
    mapping (uint => mapping (address => bool))  public  confirmedBy;
    mapping (address => bool)                    public  isMember;

     
    event Proposed   (uint id, bytes calldata);
    event Confirmed  (uint id, address member);
    event Triggered  (uint id);

    struct Action {
        address  target;
        bytes    calldata;
        uint     value;

        uint     confirmations;
        uint     deadline;
        bool     triggered;
    }

    function DSGroup(
        address[]  members_,
        uint       quorum_,
        uint       window_
    ) {
        members  = members_;
        quorum   = quorum_;
        window   = window_;

        for (uint i = 0; i < members.length; i++) {
            isMember[members[i]] = true;
        }
    }

    function memberCount() constant returns (uint) {
        return members.length;
    }

    function target(uint id) constant returns (address) {
        return actions[id].target;
    }
    function calldata(uint id) constant returns (bytes) {
        return actions[id].calldata;
    }
    function value(uint id) constant returns (uint) {
        return actions[id].value;
    }

    function confirmations(uint id) constant returns (uint) {
        return actions[id].confirmations;
    }
    function deadline(uint id) constant returns (uint) {
        return actions[id].deadline;
    }
    function triggered(uint id) constant returns (bool) {
        return actions[id].triggered;
    }

    function confirmed(uint id) constant returns (bool) {
        return confirmations(id) >= quorum;
    }
    function expired(uint id) constant returns (bool) {
        return now > deadline(id);
    }

    function deposit() note payable {
    }

    function propose(
        address  target,
        bytes    calldata,
        uint     value
    ) onlyMembers note returns (uint id) {
        id = ++actionCount;

        actions[id].target    = target;
        actions[id].calldata  = calldata;
        actions[id].value     = value;
        actions[id].deadline  = now + window;

        Proposed(id, calldata);
    }

    function confirm(uint id) onlyMembers onlyActive(id) note {
        assert(!confirmedBy[id][msg.sender]);

        confirmedBy[id][msg.sender] = true;
        actions[id].confirmations++;

        Confirmed(id, msg.sender);
    }

    function trigger(uint id) onlyMembers onlyActive(id) note {
        assert(confirmed(id));

        actions[id].triggered = true;
        exec(actions[id].target, actions[id].calldata, actions[id].value);

        Triggered(id);
    }

    modifier onlyMembers {
        assert(isMember[msg.sender]);
        _;
    }

    modifier onlyActive(uint id) {
        assert(!expired(id));
        assert(!triggered(id));
        _;
    }

     
     
     

    function getInfo() constant returns (
        uint  quorum_,
        uint  memberCount,
        uint  window_,
        uint  actionCount_
    ) {
        return (quorum, members.length, window, actionCount);
    }

    function getActionStatus(uint id) constant returns (
        uint     confirmations,
        uint     deadline,
        bool     triggered,
        address  target,
        uint     value
    ) {
        return (
            actions[id].confirmations,
            actions[id].deadline,
            actions[id].triggered,
            actions[id].target,
            actions[id].value
        );
    }
}

contract DSGroupFactory is DSNote {
    mapping (address => bool)  public  isGroup;

    function newGroup(
        address[]  members,
        uint       quorum,
        uint       window
    ) note returns (DSGroup group) {
        group = new DSGroup(members, quorum, window);
        isGroup[group] = true;
    }
}

contract DBC {

     

    modifier pre_cond(bool condition) {
        require(condition);
        _;
    }

    modifier post_cond(bool condition) {
        _;
        assert(condition);
    }

    modifier invariant(bool condition) {
        require(condition);
        _;
        assert(condition);
    }
}

contract Owned is DBC {

     

    address public owner;

     

    function Owned() { owner = msg.sender; }

    function changeOwner(address ofNewOwner) pre_cond(isOwner()) { owner = ofNewOwner; }

     

    function isOwner() internal returns (bool) { return msg.sender == owner; }

}

contract Governance is DBC, Owned, DSGroup {

     

    struct Version {
        address version;
        bool active;
        uint timestamp;
    }

     

     
    address public MELON_ASSET;  
    address[] public authorities;  
     
    Version[] public versions;
    mapping (address => uint) public versionToProposalIds;  
    mapping (uint => uint) public versionIdToShutdownIds;  

     

    event VersionUpdated(uint id);

     

     

     
     
     
    function Governance(
        address[] ofAuthorities,
        uint ofQuorum,
        uint ofWindow
    )
        DSGroup(ofAuthorities, ofQuorum, ofWindow)
    {}

     

    function() payable { }

     

     
     
    function proposeVersion(address ofVersion) {
        versionToProposalIds[ofVersion] = propose(address(this), new bytes(0), 0);
    }

     
     
    function approveVersion(address ofVersion) {
        confirm(versionToProposalIds[ofVersion]);
    }

     
     
    function triggerVersion(address ofVersion) {
        trigger(versionToProposalIds[ofVersion]);
        addVersion(ofVersion);
    }

     
     
    function proposeShutdown(uint ofVersionId) {
        versionIdToShutdownIds[ofVersionId] = propose(address(this), new bytes(0), 0);
    }

     
     
    function approveShutdown(uint ofVersionId) {
        confirm(versionIdToShutdownIds[ofVersionId]);
    }

     
     
    function triggerShutdown(uint ofVersionId) {
        trigger(versionIdToShutdownIds[ofVersionId]);
        shutDownVersion(ofVersionId);
    }

     

     
    function getVersionById(uint id) view returns (address ofVersion, bool active, uint timestamp) {
        return (
            versions[id].version,
            versions[id].active,
            versions[id].timestamp
        );
    }

     

     
     
     
    function addVersion(
        address ofVersion
    )
         
         
        internal returns (uint id)
    {
        Version memory info;
        info.version = ofVersion;
        info.active = true;
        info.timestamp = now;
        versions.push(info);
        VersionUpdated(versions.length - 1);
    }

     
     
    function shutDownVersion(uint id)
        pre_cond(isActive(id)) internal
    {
        VersionInterface Version = VersionInterface(versions[id].version);
        Version.shutDown();
        delete versions[id];
        VersionUpdated(id);
    }

    function isActive(uint id) internal returns (bool active) {
        (, active, ) = getVersionById(id);
    }


}

interface VersionInterface {

     

    event FundUpdated(uint id);

     

    function shutDown() external;

    function setupFund(
        string ofFundName,
        address ofQuoteAsset,
        uint ofManagementFee,
        uint ofPerformanceFee,
        address ofCompliance,
        address ofRiskMgmt,
        address ofPriceFeed,
        address[] ofExchanges,
        address[] ofExchangeAdapters,
        uint8 v,
        bytes32 r,
        bytes32 s
    );
    function shutDownFund(address ofFund);

     

    function getNativeAsset() view returns (address);
    function getFundById(uint withId) view returns (address);
    function getLastFundId() view returns (uint);
    function getFundByManager(address ofManager) view returns (address);
    function termsAndConditionsAreSigned(uint8 v, bytes32 r, bytes32 s) view returns (bool signed);

}