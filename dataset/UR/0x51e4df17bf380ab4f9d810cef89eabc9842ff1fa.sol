 

pragma solidity ^0.4.11;

 
contract Owned {
     
    address public contractOwner;

     
    address public pendingContractOwner;

    function Owned() {
        contractOwner = msg.sender;
    }

     
    modifier onlyContractOwner() {
        if (contractOwner == msg.sender) {
            _;
        }
    }

     
    function destroy() onlyContractOwner {
        suicide(msg.sender);
    }

     
    function changeContractOwnership(address _to) onlyContractOwner() returns(bool) {
        if (_to  == 0x0) {
            return false;
        }

        pendingContractOwner = _to;
        return true;
    }

     
    function claimContractOwnership() returns(bool) {
        if (pendingContractOwner != msg.sender) {
            return false;
        }

        contractOwner = pendingContractOwner;
        delete pendingContractOwner;

        return true;
    }
}

contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

 
contract Object is Owned {
     
    uint constant OK = 1;
    uint constant OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER = 8;

    function withdrawnTokens(address[] tokens, address _to) onlyContractOwner returns(uint) {
        for(uint i=0;i<tokens.length;i++) {
            address token = tokens[i];
            uint balance = ERC20Interface(token).balanceOf(this);
            if(balance != 0)
                ERC20Interface(token).transfer(_to,balance);
        }
        return OK;
    }

    function checkOnlyContractOwner() internal constant returns(uint) {
        if (contractOwner == msg.sender) {
            return OK;
        }

        return OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER;
    }
}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract GroupsAccessManagerEmitter {

    event UserCreated(address user);
    event UserDeleted(address user);
    event GroupCreated(bytes32 groupName);
    event GroupActivated(bytes32 groupName);
    event GroupDeactivated(bytes32 groupName);
    event UserToGroupAdded(address user, bytes32 groupName);
    event UserFromGroupRemoved(address user, bytes32 groupName);
}

 
 
 
 
contract GroupsAccessManager is Object, GroupsAccessManagerEmitter {

    uint constant USER_MANAGER_SCOPE = 111000;
    uint constant USER_MANAGER_MEMBER_ALREADY_EXIST = USER_MANAGER_SCOPE + 1;
    uint constant USER_MANAGER_GROUP_ALREADY_EXIST = USER_MANAGER_SCOPE + 2;
    uint constant USER_MANAGER_OBJECT_ALREADY_SECURED = USER_MANAGER_SCOPE + 3;
    uint constant USER_MANAGER_CONFIRMATION_HAS_COMPLETED = USER_MANAGER_SCOPE + 4;
    uint constant USER_MANAGER_USER_HAS_CONFIRMED = USER_MANAGER_SCOPE + 5;
    uint constant USER_MANAGER_NOT_ENOUGH_GAS = USER_MANAGER_SCOPE + 6;
    uint constant USER_MANAGER_INVALID_INVOCATION = USER_MANAGER_SCOPE + 7;
    uint constant USER_MANAGER_DONE = USER_MANAGER_SCOPE + 11;
    uint constant USER_MANAGER_CANCELLED = USER_MANAGER_SCOPE + 12;

    using SafeMath for uint;

    struct Member {
        address addr;
        uint groupsCount;
        mapping(bytes32 => uint) groupName2index;
        mapping(uint => uint) index2globalIndex;
    }

    struct Group {
        bytes32 name;
        uint priority;
        uint membersCount;
        mapping(address => uint) memberAddress2index;
        mapping(uint => uint) index2globalIndex;
    }

    uint public membersCount;
    mapping(uint => address) index2memberAddress;
    mapping(address => uint) memberAddress2index;
    mapping(address => Member) address2member;

    uint public groupsCount;
    mapping(uint => bytes32) index2groupName;
    mapping(bytes32 => uint) groupName2index;
    mapping(bytes32 => Group) groupName2group;
    mapping(bytes32 => bool) public groupsBlocked;  

    function() payable public {
        revert();
    }

     
     
     
     
     
     
    function registerUser(address _user) external onlyContractOwner returns (uint) {
        require(_user != 0x0);

        if (isRegisteredUser(_user)) {
            return USER_MANAGER_MEMBER_ALREADY_EXIST;
        }

        uint _membersCount = membersCount.add(1);
        membersCount = _membersCount;
        memberAddress2index[_user] = _membersCount;
        index2memberAddress[_membersCount] = _user;
        address2member[_user] = Member(_user, 0);

        UserCreated(_user);
        return OK;
    }

     
     
     
     
     
     
    function unregisterUser(address _user) external onlyContractOwner returns (uint) {
        require(_user != 0x0);

        uint _memberIndex = memberAddress2index[_user];
        if (_memberIndex == 0 || address2member[_user].groupsCount != 0) {
            return USER_MANAGER_INVALID_INVOCATION;
        }

        uint _membersCount = membersCount;
        delete memberAddress2index[_user];
        if (_memberIndex != _membersCount) {
            address _lastUser = index2memberAddress[_membersCount];
            index2memberAddress[_memberIndex] = _lastUser;
            memberAddress2index[_lastUser] = _memberIndex;
        }
        delete address2member[_user];
        delete index2memberAddress[_membersCount];
        delete memberAddress2index[_user];
        membersCount = _membersCount.sub(1);

        UserDeleted(_user);
        return OK;
    }

     
     
     
     
     
     
     
    function createGroup(bytes32 _groupName, uint _priority) external onlyContractOwner returns (uint) {
        require(_groupName != bytes32(0));

        if (isGroupExists(_groupName)) {
            return USER_MANAGER_GROUP_ALREADY_EXIST;
        }

        uint _groupsCount = groupsCount.add(1);
        groupName2index[_groupName] = _groupsCount;
        index2groupName[_groupsCount] = _groupName;
        groupName2group[_groupName] = Group(_groupName, _priority, 0);
        groupsCount = _groupsCount;

        GroupCreated(_groupName);
        return OK;
    }

     
     
     
     
     
     
     
    function changeGroupActiveStatus(bytes32 _groupName, bool _blocked) external onlyContractOwner returns (uint) {
        require(isGroupExists(_groupName));
        groupsBlocked[_groupName] = _blocked;
        return OK;
    }

     
     
     
     
     
     
     
    function addUsersToGroup(bytes32 _groupName, address[] _users) external onlyContractOwner returns (uint) {
        require(isGroupExists(_groupName));

        Group storage _group = groupName2group[_groupName];
        uint _groupMembersCount = _group.membersCount;

        for (uint _userIdx = 0; _userIdx < _users.length; ++_userIdx) {
            address _user = _users[_userIdx];
            uint _memberIndex = memberAddress2index[_user];
            require(_memberIndex != 0);

            if (_group.memberAddress2index[_user] != 0) {
                continue;
            }

            _groupMembersCount = _groupMembersCount.add(1);
            _group.memberAddress2index[_user] = _groupMembersCount;
            _group.index2globalIndex[_groupMembersCount] = _memberIndex;

            _addGroupToMember(_user, _groupName);

            UserToGroupAdded(_user, _groupName);
        }
        _group.membersCount = _groupMembersCount;

        return OK;
    }

     
     
     
     
     
     
     
    function removeUsersFromGroup(bytes32 _groupName, address[] _users) external onlyContractOwner returns (uint) {
        require(isGroupExists(_groupName));

        Group storage _group = groupName2group[_groupName];
        uint _groupMembersCount = _group.membersCount;

        for (uint _userIdx = 0; _userIdx < _users.length; ++_userIdx) {
            address _user = _users[_userIdx];
            uint _memberIndex = memberAddress2index[_user];
            uint _groupMemberIndex = _group.memberAddress2index[_user];

            if (_memberIndex == 0 || _groupMemberIndex == 0) {
                continue;
            }

            if (_groupMemberIndex != _groupMembersCount) {
                uint _lastUserGlobalIndex = _group.index2globalIndex[_groupMembersCount];
                address _lastUser = index2memberAddress[_lastUserGlobalIndex];
                _group.index2globalIndex[_groupMemberIndex] = _lastUserGlobalIndex;
                _group.memberAddress2index[_lastUser] = _groupMemberIndex;
            }
            delete _group.memberAddress2index[_user];
            delete _group.index2globalIndex[_groupMembersCount];
            _groupMembersCount = _groupMembersCount.sub(1);

            _removeGroupFromMember(_user, _groupName);

            UserFromGroupRemoved(_user, _groupName);
        }
        _group.membersCount = _groupMembersCount;

        return OK;
    }

     
     
     
     
     
    function isRegisteredUser(address _user) public view returns (bool) {
        return memberAddress2index[_user] != 0;
    }

     
     
     
     
     
     
    function isUserInGroup(bytes32 _groupName, address _user) public view returns (bool) {
        return isRegisteredUser(_user) && address2member[_user].groupName2index[_groupName] != 0;
    }

     
     
     
     
     
    function isGroupExists(bytes32 _groupName) public view returns (bool) {
        return groupName2index[_groupName] != 0;
    }

     
     
     
    function getGroups() public view returns (bytes32[] _groups) {
        uint _groupsCount = groupsCount;
        _groups = new bytes32[](_groupsCount);
        for (uint _groupIdx = 0; _groupIdx < _groupsCount; ++_groupIdx) {
            _groups[_groupIdx] = index2groupName[_groupIdx + 1];
        }
    }

     

    function _removeGroupFromMember(address _user, bytes32 _groupName) private {
        Member storage _member = address2member[_user];
        uint _memberGroupsCount = _member.groupsCount;
        uint _memberGroupIndex = _member.groupName2index[_groupName];
        if (_memberGroupIndex != _memberGroupsCount) {
            uint _lastGroupGlobalIndex = _member.index2globalIndex[_memberGroupsCount];
            bytes32 _lastGroupName = index2groupName[_lastGroupGlobalIndex];
            _member.index2globalIndex[_memberGroupIndex] = _lastGroupGlobalIndex;
            _member.groupName2index[_lastGroupName] = _memberGroupIndex;
        }
        delete _member.groupName2index[_groupName];
        delete _member.index2globalIndex[_memberGroupsCount];
        _member.groupsCount = _memberGroupsCount.sub(1);
    }

    function _addGroupToMember(address _user, bytes32 _groupName) private {
        Member storage _member = address2member[_user];
        uint _memberGroupsCount = _member.groupsCount.add(1);
        _member.groupName2index[_groupName] = _memberGroupsCount;
        _member.index2globalIndex[_memberGroupsCount] = groupName2index[_groupName];
        _member.groupsCount = _memberGroupsCount;
    }
}

contract PendingManagerEmitter {

    event PolicyRuleAdded(bytes4 sig, address contractAddress, bytes32 key, bytes32 groupName, uint acceptLimit, uint declinesLimit);
    event PolicyRuleRemoved(bytes4 sig, address contractAddress, bytes32 key, bytes32 groupName);

    event ProtectionTxAdded(bytes32 key, bytes32 sig, uint blockNumber);
    event ProtectionTxAccepted(bytes32 key, address indexed sender, bytes32 groupNameVoted);
    event ProtectionTxDone(bytes32 key);
    event ProtectionTxDeclined(bytes32 key, address indexed sender, bytes32 groupNameVoted);
    event ProtectionTxCancelled(bytes32 key);
    event ProtectionTxVoteRevoked(bytes32 key, address indexed sender, bytes32 groupNameVoted);
    event TxDeleted(bytes32 key);

    event Error(uint errorCode);

    function _emitError(uint _errorCode) internal returns (uint) {
        Error(_errorCode);
        return _errorCode;
    }
}

contract PendingManagerInterface {

    function signIn(address _contract) external returns (uint);
    function signOut(address _contract) external returns (uint);

    function addPolicyRule(
        bytes4 _sig, 
        address _contract, 
        bytes32 _groupName, 
        uint _acceptLimit, 
        uint _declineLimit 
        ) 
        external returns (uint);
        
    function removePolicyRule(
        bytes4 _sig, 
        address _contract, 
        bytes32 _groupName
        ) 
        external returns (uint);

    function addTx(bytes32 _key, bytes4 _sig, address _contract) external returns (uint);
    function deleteTx(bytes32 _key) external returns (uint);

    function accept(bytes32 _key, bytes32 _votingGroupName) external returns (uint);
    function decline(bytes32 _key, bytes32 _votingGroupName) external returns (uint);
    function revoke(bytes32 _key) external returns (uint);

    function hasConfirmedRecord(bytes32 _key) public view returns (uint);
    function getPolicyDetails(bytes4 _sig, address _contract) public view returns (
        bytes32[] _groupNames,
        uint[] _acceptLimits,
        uint[] _declineLimits,
        uint _totalAcceptedLimit,
        uint _totalDeclinedLimit
        );
}

 
 
 
 
contract PendingManager is Object, PendingManagerEmitter, PendingManagerInterface {

    uint constant NO_RECORDS_WERE_FOUND = 4;
    uint constant PENDING_MANAGER_SCOPE = 4000;
    uint constant PENDING_MANAGER_INVALID_INVOCATION = PENDING_MANAGER_SCOPE + 1;
    uint constant PENDING_MANAGER_HASNT_VOTED = PENDING_MANAGER_SCOPE + 2;
    uint constant PENDING_DUPLICATE_TX = PENDING_MANAGER_SCOPE + 3;
    uint constant PENDING_MANAGER_CONFIRMED = PENDING_MANAGER_SCOPE + 4;
    uint constant PENDING_MANAGER_REJECTED = PENDING_MANAGER_SCOPE + 5;
    uint constant PENDING_MANAGER_IN_PROCESS = PENDING_MANAGER_SCOPE + 6;
    uint constant PENDING_MANAGER_TX_DOESNT_EXIST = PENDING_MANAGER_SCOPE + 7;
    uint constant PENDING_MANAGER_TX_WAS_DECLINED = PENDING_MANAGER_SCOPE + 8;
    uint constant PENDING_MANAGER_TX_WAS_NOT_CONFIRMED = PENDING_MANAGER_SCOPE + 9;
    uint constant PENDING_MANAGER_INSUFFICIENT_GAS = PENDING_MANAGER_SCOPE + 10;
    uint constant PENDING_MANAGER_POLICY_NOT_FOUND = PENDING_MANAGER_SCOPE + 11;

    using SafeMath for uint;

    enum GuardState {
        Decline, Confirmed, InProcess
    }

    struct Requirements {
        bytes32 groupName;
        uint acceptLimit;
        uint declineLimit;
    }

    struct Policy {
        uint groupsCount;
        mapping(uint => Requirements) participatedGroups;  
        mapping(bytes32 => uint) groupName2index;  
        
        uint totalAcceptedLimit;
        uint totalDeclinedLimit;

        uint securesCount;
        mapping(uint => uint) index2txIndex;
        mapping(uint => uint) txIndex2index;
    }

    struct Vote {
        bytes32 groupName;
        bool accepted;
    }

    struct Guard {
        GuardState state;
        uint basePolicyIndex;

        uint alreadyAccepted;
        uint alreadyDeclined;
        
        mapping(address => Vote) votes;  
        mapping(bytes32 => uint) acceptedCount;  
        mapping(bytes32 => uint) declinedCount;  
    }

    address public accessManager;

    mapping(address => bool) public authorized;

    uint public policiesCount;
    mapping(uint => bytes32) index2PolicyId;  
    mapping(bytes32 => uint) policyId2Index;  
    mapping(bytes32 => Policy) policyId2policy;  

    uint public txCount;
    mapping(uint => bytes32) index2txKey;
    mapping(bytes32 => uint) txKey2index;  
    mapping(bytes32 => Guard) txKey2guard;

     
    modifier onlyAuthorized {
        if (authorized[msg.sender] || address(this) == msg.sender) {
            _;
        }
    }

     
     
     
    function PendingManager(address _accessManager) public {
        require(_accessManager != 0x0);
        accessManager = _accessManager;
    }

    function() payable public {
        revert();
    }

     
     
     
    function setAccessManager(address _accessManager) external onlyContractOwner returns (uint) {
        require(_accessManager != 0x0);
        accessManager = _accessManager;
        return OK;
    }

     
     
     
    function signIn(address _contract) external onlyContractOwner returns (uint) {
        require(_contract != 0x0);
        authorized[_contract] = true;
        return OK;
    }

     
     
     
    function signOut(address _contract) external onlyContractOwner returns (uint) {
        require(_contract != 0x0);
        delete authorized[_contract];
        return OK;
    }

     
     
     
     
     
     
     
     
     
     
    function addPolicyRule(
        bytes4 _sig,
        address _contract,
        bytes32 _groupName,
        uint _acceptLimit,
        uint _declineLimit
    )
    onlyContractOwner
    external
    returns (uint)
    {
        require(_sig != 0x0);
        require(_contract != 0x0);
        require(GroupsAccessManager(accessManager).isGroupExists(_groupName));
        require(_acceptLimit != 0);
        require(_declineLimit != 0);

        bytes32 _policyHash = keccak256(_sig, _contract);
        
        if (policyId2Index[_policyHash] == 0) {
            uint _policiesCount = policiesCount.add(1);
            index2PolicyId[_policiesCount] = _policyHash;
            policyId2Index[_policyHash] = _policiesCount;
            policiesCount = _policiesCount;
        }

        Policy storage _policy = policyId2policy[_policyHash];
        uint _policyGroupsCount = _policy.groupsCount;

        if (_policy.groupName2index[_groupName] == 0) {
            _policyGroupsCount += 1;
            _policy.groupName2index[_groupName] = _policyGroupsCount;
            _policy.participatedGroups[_policyGroupsCount].groupName = _groupName;
            _policy.groupsCount = _policyGroupsCount;
        }

        uint _previousAcceptLimit = _policy.participatedGroups[_policyGroupsCount].acceptLimit;
        uint _previousDeclineLimit = _policy.participatedGroups[_policyGroupsCount].declineLimit;
        _policy.participatedGroups[_policyGroupsCount].acceptLimit = _acceptLimit;
        _policy.participatedGroups[_policyGroupsCount].declineLimit = _declineLimit;
        _policy.totalAcceptedLimit = _policy.totalAcceptedLimit.sub(_previousAcceptLimit).add(_acceptLimit);
        _policy.totalDeclinedLimit = _policy.totalDeclinedLimit.sub(_previousDeclineLimit).add(_declineLimit);

        PolicyRuleAdded(_sig, _contract, _policyHash, _groupName, _acceptLimit, _declineLimit);
        return OK;
    }

     
     
     
     
     
     
    function removePolicyRule(
        bytes4 _sig,
        address _contract,
        bytes32 _groupName
    ) 
    onlyContractOwner 
    external 
    returns (uint) 
    {
        require(_sig != bytes4(0));
        require(_contract != 0x0);
        require(GroupsAccessManager(accessManager).isGroupExists(_groupName));

        bytes32 _policyHash = keccak256(_sig, _contract);
        Policy storage _policy = policyId2policy[_policyHash];
        uint _policyGroupNameIndex = _policy.groupName2index[_groupName];

        if (_policyGroupNameIndex == 0) {
            return _emitError(PENDING_MANAGER_INVALID_INVOCATION);
        }

        uint _policyGroupsCount = _policy.groupsCount;
        if (_policyGroupNameIndex != _policyGroupsCount) {
            Requirements storage _requirements = _policy.participatedGroups[_policyGroupsCount];
            _policy.participatedGroups[_policyGroupNameIndex] = _requirements;
            _policy.groupName2index[_requirements.groupName] = _policyGroupNameIndex;
        }

        _policy.totalAcceptedLimit = _policy.totalAcceptedLimit.sub(_policy.participatedGroups[_policyGroupsCount].acceptLimit);
        _policy.totalDeclinedLimit = _policy.totalDeclinedLimit.sub(_policy.participatedGroups[_policyGroupsCount].declineLimit);

        delete _policy.groupName2index[_groupName];
        delete _policy.participatedGroups[_policyGroupsCount];
        _policy.groupsCount = _policyGroupsCount.sub(1);

        PolicyRuleRemoved(_sig, _contract, _policyHash, _groupName);
        return OK;
    }

     
     
     
     
     
    function addTx(bytes32 _key, bytes4 _sig, address _contract) external onlyAuthorized returns (uint) {
        require(_key != bytes32(0));
        require(_sig != bytes4(0));
        require(_contract != 0x0);

        bytes32 _policyHash = keccak256(_sig, _contract);
        require(isPolicyExist(_policyHash));

        if (isTxExist(_key)) {
            return _emitError(PENDING_DUPLICATE_TX);
        }

        if (_policyHash == bytes32(0)) {
            return _emitError(PENDING_MANAGER_POLICY_NOT_FOUND);
        }

        uint _index = txCount.add(1);
        txCount = _index;
        index2txKey[_index] = _key;
        txKey2index[_key] = _index;

        Guard storage _guard = txKey2guard[_key];
        _guard.basePolicyIndex = policyId2Index[_policyHash];
        _guard.state = GuardState.InProcess;

        Policy storage _policy = policyId2policy[_policyHash];
        uint _counter = _policy.securesCount.add(1);
        _policy.securesCount = _counter;
        _policy.index2txIndex[_counter] = _index;
        _policy.txIndex2index[_index] = _counter;

        ProtectionTxAdded(_key, _policyHash, block.number);
        return OK;
    }

     
     
     
    function deleteTx(bytes32 _key) external onlyContractOwner returns (uint) {
        require(_key != bytes32(0));

        if (!isTxExist(_key)) {
            return _emitError(PENDING_MANAGER_TX_DOESNT_EXIST);
        }

        uint _txsCount = txCount;
        uint _txIndex = txKey2index[_key];
        if (_txIndex != _txsCount) {
            bytes32 _last = index2txKey[txCount];
            index2txKey[_txIndex] = _last;
            txKey2index[_last] = _txIndex;
        }

        delete txKey2index[_key];
        delete index2txKey[_txsCount];
        txCount = _txsCount.sub(1);

        uint _basePolicyIndex = txKey2guard[_key].basePolicyIndex;
        Policy storage _policy = policyId2policy[index2PolicyId[_basePolicyIndex]];
        uint _counter = _policy.securesCount;
        uint _policyTxIndex = _policy.txIndex2index[_txIndex];
        if (_policyTxIndex != _counter) {
            uint _movedTxIndex = _policy.index2txIndex[_counter];
            _policy.index2txIndex[_policyTxIndex] = _movedTxIndex;
            _policy.txIndex2index[_movedTxIndex] = _policyTxIndex;
        }

        delete _policy.index2txIndex[_counter];
        delete _policy.txIndex2index[_txIndex];
        _policy.securesCount = _counter.sub(1);

        TxDeleted(_key);
        return OK;
    }

     
     
     
     
     
     
    function accept(bytes32 _key, bytes32 _votingGroupName) external returns (uint) {
        if (!isTxExist(_key)) {
            return _emitError(PENDING_MANAGER_TX_DOESNT_EXIST);
        }

        if (!GroupsAccessManager(accessManager).isUserInGroup(_votingGroupName, msg.sender)) {
            return _emitError(PENDING_MANAGER_INVALID_INVOCATION);
        }

        Guard storage _guard = txKey2guard[_key];
        if (_guard.state != GuardState.InProcess) {
            return _emitError(PENDING_MANAGER_INVALID_INVOCATION);
        }

        if (_guard.votes[msg.sender].groupName != bytes32(0) && _guard.votes[msg.sender].accepted) {
            return _emitError(PENDING_MANAGER_INVALID_INVOCATION);
        }

        Policy storage _policy = policyId2policy[index2PolicyId[_guard.basePolicyIndex]];
        uint _policyGroupIndex = _policy.groupName2index[_votingGroupName];
        uint _groupAcceptedVotesCount = _guard.acceptedCount[_votingGroupName];
        if (_groupAcceptedVotesCount == _policy.participatedGroups[_policyGroupIndex].acceptLimit) {
            return _emitError(PENDING_MANAGER_INVALID_INVOCATION);
        }

        _guard.votes[msg.sender] = Vote(_votingGroupName, true);
        _guard.acceptedCount[_votingGroupName] = _groupAcceptedVotesCount + 1;
        uint _alreadyAcceptedCount = _guard.alreadyAccepted + 1;
        _guard.alreadyAccepted = _alreadyAcceptedCount;

        ProtectionTxAccepted(_key, msg.sender, _votingGroupName);

        if (_alreadyAcceptedCount == _policy.totalAcceptedLimit) {
            _guard.state = GuardState.Confirmed;
            ProtectionTxDone(_key);
        }

        return OK;
    }

     
     
     
     
     
     
    function decline(bytes32 _key, bytes32 _votingGroupName) external returns (uint) {
        if (!isTxExist(_key)) {
            return _emitError(PENDING_MANAGER_TX_DOESNT_EXIST);
        }

        if (!GroupsAccessManager(accessManager).isUserInGroup(_votingGroupName, msg.sender)) {
            return _emitError(PENDING_MANAGER_INVALID_INVOCATION);
        }

        Guard storage _guard = txKey2guard[_key];
        if (_guard.state != GuardState.InProcess) {
            return _emitError(PENDING_MANAGER_INVALID_INVOCATION);
        }

        if (_guard.votes[msg.sender].groupName != bytes32(0) && !_guard.votes[msg.sender].accepted) {
            return _emitError(PENDING_MANAGER_INVALID_INVOCATION);
        }

        Policy storage _policy = policyId2policy[index2PolicyId[_guard.basePolicyIndex]];
        uint _policyGroupIndex = _policy.groupName2index[_votingGroupName];
        uint _groupDeclinedVotesCount = _guard.declinedCount[_votingGroupName];
        if (_groupDeclinedVotesCount == _policy.participatedGroups[_policyGroupIndex].declineLimit) {
            return _emitError(PENDING_MANAGER_INVALID_INVOCATION);
        }

        _guard.votes[msg.sender] = Vote(_votingGroupName, false);
        _guard.declinedCount[_votingGroupName] = _groupDeclinedVotesCount + 1;
        uint _alreadyDeclinedCount = _guard.alreadyDeclined + 1;
        _guard.alreadyDeclined = _alreadyDeclinedCount;


        ProtectionTxDeclined(_key, msg.sender, _votingGroupName);

        if (_alreadyDeclinedCount == _policy.totalDeclinedLimit) {
            _guard.state = GuardState.Decline;
            ProtectionTxCancelled(_key);
        }

        return OK;
    }

     
     
     
     
     
     
     
    function forceRejectVotes(bytes32 _key, address _user) external onlyContractOwner returns (uint) {
        return _revoke(_key, _user);
    }

     
     
     
     
    function revoke(bytes32 _key) external returns (uint) {
        return _revoke(_key, msg.sender);
    }

     
     
     
    function hasConfirmedRecord(bytes32 _key) public view returns (uint) {
        require(_key != bytes32(0));

        if (!isTxExist(_key)) {
            return NO_RECORDS_WERE_FOUND;
        }

        Guard storage _guard = txKey2guard[_key];
        return _guard.state == GuardState.InProcess
        ? PENDING_MANAGER_IN_PROCESS
        : _guard.state == GuardState.Confirmed
        ? OK
        : PENDING_MANAGER_REJECTED;
    }


     
     
     
     
     
    function getPolicyDetails(bytes4 _sig, address _contract)
    public
    view
    returns (
        bytes32[] _groupNames,
        uint[] _acceptLimits,
        uint[] _declineLimits,
        uint _totalAcceptedLimit,
        uint _totalDeclinedLimit
    ) {
        require(_sig != bytes4(0));
        require(_contract != 0x0);
        
        bytes32 _policyHash = keccak256(_sig, _contract);
        uint _policyIdx = policyId2Index[_policyHash];
        if (_policyIdx == 0) {
            return;
        }

        Policy storage _policy = policyId2policy[_policyHash];
        uint _policyGroupsCount = _policy.groupsCount;
        _groupNames = new bytes32[](_policyGroupsCount);
        _acceptLimits = new uint[](_policyGroupsCount);
        _declineLimits = new uint[](_policyGroupsCount);

        for (uint _idx = 0; _idx < _policyGroupsCount; ++_idx) {
            Requirements storage _requirements = _policy.participatedGroups[_idx + 1];
            _groupNames[_idx] = _requirements.groupName;
            _acceptLimits[_idx] = _requirements.acceptLimit;
            _declineLimits[_idx] = _requirements.declineLimit;
        }

        (_totalAcceptedLimit, _totalDeclinedLimit) = (_policy.totalAcceptedLimit, _policy.totalDeclinedLimit);
    }

     
     
     
     
    function isGroupInPolicy(bytes32 _policyHash, bytes32 _groupName) public view returns (bool) {
        Policy storage _policy = policyId2policy[_policyHash];
        return _policy.groupName2index[_groupName] != 0;
    }

     
     
     
    function isPolicyExist(bytes32 _policyHash) public view returns (bool) {
        return policyId2Index[_policyHash] != 0;
    }

     
     
     
    function isTxExist(bytes32 _key) public view returns (bool){
        return txKey2index[_key] != 0;
    }

    function _updateTxState(Policy storage _policy, Guard storage _guard, uint confirmedAmount, uint declineAmount) private {
        if (declineAmount != 0 && _guard.state != GuardState.Decline) {
            _guard.state = GuardState.Decline;
        } else if (confirmedAmount >= _policy.groupsCount && _guard.state != GuardState.Confirmed) {
            _guard.state = GuardState.Confirmed;
        } else if (_guard.state != GuardState.InProcess) {
            _guard.state = GuardState.InProcess;
        }
    }

    function _revoke(bytes32 _key, address _user) private returns (uint) {
        require(_key != bytes32(0));
        require(_user != 0x0);

        if (!isTxExist(_key)) {
            return _emitError(PENDING_MANAGER_TX_DOESNT_EXIST);
        }

        Guard storage _guard = txKey2guard[_key];
        if (_guard.state != GuardState.InProcess) {
            return _emitError(PENDING_MANAGER_INVALID_INVOCATION);
        }

        bytes32 _votedGroupName = _guard.votes[_user].groupName;
        if (_votedGroupName == bytes32(0)) {
            return _emitError(PENDING_MANAGER_HASNT_VOTED);
        }

        bool isAcceptedVote = _guard.votes[_user].accepted;
        if (isAcceptedVote) {
            _guard.acceptedCount[_votedGroupName] = _guard.acceptedCount[_votedGroupName].sub(1);
            _guard.alreadyAccepted = _guard.alreadyAccepted.sub(1);
        } else {
            _guard.declinedCount[_votedGroupName] = _guard.declinedCount[_votedGroupName].sub(1);
            _guard.alreadyDeclined = _guard.alreadyDeclined.sub(1);

        }

        delete _guard.votes[_user];

        ProtectionTxVoteRevoked(_key, _user, _votedGroupName);
        return OK;
    }
}

 
 
 
 
contract MultiSigAdapter is Object {

    uint constant MULTISIG_ADDED = 3;
    uint constant NO_RECORDS_WERE_FOUND = 4;

    modifier isAuthorized {
        if (msg.sender == contractOwner || msg.sender == getPendingManager()) {
            _;
        }
    }

     
     
     
     
    function getPendingManager() public view returns (address);

     
     
     
    function _multisig(bytes32 _args, uint _block) internal returns (uint _code) {
        bytes32 _txHash = _getKey(_args, _block);
        address _manager = getPendingManager();

        _code = PendingManager(_manager).hasConfirmedRecord(_txHash);
        if (_code != NO_RECORDS_WERE_FOUND) {
            return _code;
        }

        if (OK != PendingManager(_manager).addTx(_txHash, msg.sig, address(this))) {
            revert();
        }

        return MULTISIG_ADDED;
    }

    function _isTxExistWithArgs(bytes32 _args, uint _block) internal view returns (bool) {
        bytes32 _txHash = _getKey(_args, _block);
        address _manager = getPendingManager();
        return PendingManager(_manager).isTxExist(_txHash);
    }

    function _getKey(bytes32 _args, uint _block) private view returns (bytes32 _txHash) {
        _block = _block != 0 ? _block : block.number;
        _txHash = keccak256(msg.sig, _args, _block);
    }
}

 
 
 
 
contract ServiceController is MultiSigAdapter {

    event Error(uint _errorCode);

    uint constant SERVICE_CONTROLLER = 350000;
    uint constant SERVICE_CONTROLLER_EMISSION_EXIST = SERVICE_CONTROLLER + 1;
    uint constant SERVICE_CONTROLLER_BURNING_MAN_EXIST = SERVICE_CONTROLLER + 2;
    uint constant SERVICE_CONTROLLER_ALREADY_INITIALIZED = SERVICE_CONTROLLER + 3;
    uint constant SERVICE_CONTROLLER_SERVICE_EXIST = SERVICE_CONTROLLER + 4;

    address public profiterole;
    address public treasury;
    address public pendingManager;
    address public proxy;

    uint public sideServicesCount;
    mapping(uint => address) public index2sideService;
    mapping(address => uint) public sideService2index;
    mapping(address => bool) public sideServices;

    uint public emissionProvidersCount;
    mapping(uint => address) public index2emissionProvider;
    mapping(address => uint) public emissionProvider2index;
    mapping(address => bool) public emissionProviders;

    uint public burningMansCount;
    mapping(uint => address) public index2burningMan;
    mapping(address => uint) public burningMan2index;
    mapping(address => bool) public burningMans;

     
     
     
     
     
     
    function ServiceController(address _pendingManager, address _proxy, address _profiterole, address _treasury) public {
        require(_pendingManager != 0x0);
        require(_proxy != 0x0);
        require(_profiterole != 0x0);
        require(_treasury != 0x0);
        pendingManager = _pendingManager;
        proxy = _proxy;
        profiterole = _profiterole;
        treasury = _treasury;
    }

     
     
     
    function getPendingManager() public view returns (address) {
        return pendingManager;
    }

     
     
     
     
     
    function addEmissionProvider(address _provider, uint _block) public returns (uint _code) {
        if (emissionProviders[_provider]) {
            return _emitError(SERVICE_CONTROLLER_EMISSION_EXIST);
        }
        _code = _multisig(keccak256(_provider), _block);
        if (OK != _code) {
            return _code;
        }

        emissionProviders[_provider] = true;
        uint _count = emissionProvidersCount + 1;
        index2emissionProvider[_count] = _provider;
        emissionProvider2index[_provider] = _count;
        emissionProvidersCount = _count;

        return OK;
    }

     
     
     
     
     
    function removeEmissionProvider(address _provider, uint _block) public returns (uint _code) {
        _code = _multisig(keccak256(_provider), _block);
        if (OK != _code) {
            return _code;
        }

        uint _idx = emissionProvider2index[_provider];
        uint _lastIdx = emissionProvidersCount;
        if (_idx != 0) {
            if (_idx != _lastIdx) {
                address _lastEmissionProvider = index2emissionProvider[_lastIdx];
                index2emissionProvider[_idx] = _lastEmissionProvider;
                emissionProvider2index[_lastEmissionProvider] = _idx;
            }

            delete emissionProvider2index[_provider];
            delete index2emissionProvider[_lastIdx];
            delete emissionProviders[_provider];
            emissionProvidersCount = _lastIdx - 1;
        }

        return OK;
    }

     
     
     
     
     
    function addBurningMan(address _burningMan, uint _block) public returns (uint _code) {
        if (burningMans[_burningMan]) {
            return _emitError(SERVICE_CONTROLLER_BURNING_MAN_EXIST);
        }

        _code = _multisig(keccak256(_burningMan), _block);
        if (OK != _code) {
            return _code;
        }

        burningMans[_burningMan] = true;
        uint _count = burningMansCount + 1;
        index2burningMan[_count] = _burningMan;
        burningMan2index[_burningMan] = _count;
        burningMansCount = _count;

        return OK;
    }

     
     
     
     
     
    function removeBurningMan(address _burningMan, uint _block) public returns (uint _code) {
        _code = _multisig(keccak256(_burningMan), _block);
        if (OK != _code) {
            return _code;
        }

        uint _idx = burningMan2index[_burningMan];
        uint _lastIdx = burningMansCount;
        if (_idx != 0) {
            if (_idx != _lastIdx) {
                address _lastBurningMan = index2burningMan[_lastIdx];
                index2burningMan[_idx] = _lastBurningMan;
                burningMan2index[_lastBurningMan] = _idx;
            }
            
            delete burningMan2index[_burningMan];
            delete index2burningMan[_lastIdx];
            delete burningMans[_burningMan];
            burningMansCount = _lastIdx - 1;
        }

        return OK;
    }

     
     
     
     
     
    function updateProfiterole(address _profiterole, uint _block) public returns (uint _code) {
        _code = _multisig(keccak256(_profiterole), _block);
        if (OK != _code) {
            return _code;
        }

        profiterole = _profiterole;
        return OK;
    }

     
     
     
     
     
    function updateTreasury(address _treasury, uint _block) public returns (uint _code) {
        _code = _multisig(keccak256(_treasury), _block);
        if (OK != _code) {
            return _code;
        }

        treasury = _treasury;
        return OK;
    }

     
     
     
     
     
    function updatePendingManager(address _pendingManager, uint _block) public returns (uint _code) {
        _code = _multisig(keccak256(_pendingManager), _block);
        if (OK != _code) {
            return _code;
        }

        pendingManager = _pendingManager;
        return OK;
    }

    function addSideService(address _service, uint _block) public returns (uint _code) {
        if (sideServices[_service]) {
            return SERVICE_CONTROLLER_SERVICE_EXIST;
        }
        _code = _multisig(keccak256(_service), _block);
        if (OK != _code) {
            return _code;
        }

        sideServices[_service] = true;
        uint _count = sideServicesCount + 1;
        index2sideService[_count] = _service;
        sideService2index[_service] = _count;
        sideServicesCount = _count;

        return OK;
    }

    function removeSideService(address _service, uint _block) public returns (uint _code) {
        _code = _multisig(keccak256(_service), _block);
        if (OK != _code) {
            return _code;
        }

        uint _idx = sideService2index[_service];
        uint _lastIdx = sideServicesCount;
        if (_idx != 0) {
            if (_idx != _lastIdx) {
                address _lastSideService = index2sideService[_lastIdx];
                index2sideService[_idx] = _lastSideService;
                sideService2index[_lastSideService] = _idx;
            }
            
            delete sideService2index[_service];
            delete index2sideService[_lastIdx];
            delete sideServices[_service];
            sideServicesCount = _lastIdx - 1;
        }

        return OK;
    }

    function getEmissionProviders()
    public
    view
    returns (address[] _emissionProviders)
    {
        _emissionProviders = new address[](emissionProvidersCount);
        for (uint _idx = 0; _idx < _emissionProviders.length; ++_idx) {
            _emissionProviders[_idx] = index2emissionProvider[_idx + 1];
        }
    }

    function getBurningMans()
    public
    view
    returns (address[] _burningMans)
    {
        _burningMans = new address[](burningMansCount);
        for (uint _idx = 0; _idx < _burningMans.length; ++_idx) {
            _burningMans[_idx] = index2burningMan[_idx + 1];
        }
    }

    function getSideServices()
    public
    view
    returns (address[] _sideServices)
    {
        _sideServices = new address[](sideServicesCount);
        for (uint _idx = 0; _idx < _sideServices.length; ++_idx) {
            _sideServices[_idx] = index2sideService[_idx + 1];
        }
    }

     
     
     
     
     
    function isService(address _address) public view returns (bool check) {
        return _address == profiterole ||
            _address == treasury || 
            _address == proxy || 
            _address == pendingManager || 
            emissionProviders[_address] || 
            burningMans[_address] ||
            sideServices[_address];
    }

    function _emitError(uint _errorCode) internal returns (uint) {
        Error(_errorCode);
        return _errorCode;
    }
}