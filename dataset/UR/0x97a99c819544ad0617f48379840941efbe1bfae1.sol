 

pragma solidity ^0.4.19;


contract SupportedContract {
   
  function theCyberMessage(string) public;
}


contract ERC20 {
   
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
}


contract theCyber {
   
   
   
   
   
   
   

  event NewMember(uint8 indexed memberId, bytes32 memberName, address indexed memberAddress);
  event NewMemberName(uint8 indexed memberId, bytes32 newMemberName);
  event NewMemberKey(uint8 indexed memberId, string newMemberKey);
  event MembershipTransferred(uint8 indexed memberId, address newMemberAddress);
  event MemberProclaimedInactive(uint8 indexed memberId, uint8 indexed proclaimingMemberId);
  event MemberHeartbeated(uint8 indexed memberId);
  event MembershipRevoked(uint8 indexed memberId, uint8 indexed revokingMemberId);
  event BroadcastMessage(uint8 indexed memberId, string message);
  event DirectMessage(uint8 indexed memberId, uint8 indexed toMemberId, string message);
  event Call(uint8 indexed memberId, address indexed contractAddress, string message);
  event FundsDonated(uint8 indexed memberId, uint256 value);
  event TokensDonated(uint8 indexed memberId, address tokenContractAddress, uint256 value);

   
  uint16 private constant MAXMEMBERS_ = 256;

   
  uint64 private constant INACTIVITYTIMEOUT_ = 90 days;

   
  address private constant DONATIONADDRESS_ = 0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359;

   
   
  struct Member {
    bool member;
    bytes32 name;
    string pubkey;
    uint64 memberSince;
    uint64 inactiveSince;
  }

   
  Member[MAXMEMBERS_] internal members_;

   
  mapping (address => bool) internal addressIsMember_;

   
  mapping (address => uint8) internal addressToMember_;

   
  mapping (uint => address) internal memberToAddress_;

   
   
  modifier membersOnly() {
     
    require(addressIsMember_[msg.sender]);
    _;
  }

   
   
  function theCyber() public {
     
    NewMember(0, "", msg.sender);

     
    members_[0] = Member(true, bytes32(""), "", uint64(now), 0);
    
     
    memberToAddress_[0] = msg.sender;

     
    addressToMember_[msg.sender] = 0;

     
    addressIsMember_[msg.sender] = true;
  }

   
   
  function newMember(uint8 _memberId, bytes32 _memberName, address _memberAddress) public membersOnly {
     
    require(_memberAddress != address(0));

     
    require (!members_[_memberId].member);

     
    require (!addressIsMember_[_memberAddress]);

     
    NewMember(_memberId, _memberName, _memberAddress);

     
    members_[_memberId] = Member(true, _memberName, "", uint64(now), 0);
    
     
    memberToAddress_[_memberId] = _memberAddress;

     
    addressToMember_[_memberAddress] = _memberId;

     
    addressIsMember_[_memberAddress] = true;
  }

   
   
  function changeName(bytes32 _newMemberName) public membersOnly {
     
    NewMemberName(addressToMember_[msg.sender], _newMemberName);

     
    members_[addressToMember_[msg.sender]].name = _newMemberName;
  }

   
   
  function changeKey(string _newMemberKey) public membersOnly {
     
    NewMemberKey(addressToMember_[msg.sender], _newMemberKey);

     
    members_[addressToMember_[msg.sender]].pubkey = _newMemberKey;
  }

   
   
  function transferMembership(address _newMemberAddress) public membersOnly {
     
    require(_newMemberAddress != address(0));

     
    require (!addressIsMember_[_newMemberAddress]);

     
    MembershipTransferred(addressToMember_[msg.sender], _newMemberAddress);
    
     
    delete addressIsMember_[msg.sender];
    
     
    members_[addressToMember_[msg.sender]].memberSince = uint64(now);
    members_[addressToMember_[msg.sender]].inactiveSince = 0;
    members_[addressToMember_[msg.sender]].name = bytes32("");
    members_[addressToMember_[msg.sender]].pubkey = "";
    
     
    memberToAddress_[addressToMember_[msg.sender]] = _newMemberAddress;

     
    addressToMember_[_newMemberAddress] = addressToMember_[msg.sender];
    delete addressToMember_[msg.sender];

     
    addressIsMember_[_newMemberAddress] = true;
  }

   
   
  function proclaimInactive(uint8 _memberId) public membersOnly {
     
    require(members_[_memberId].member);
    require(memberIsActive(_memberId));
    
     
    require(addressToMember_[msg.sender] != _memberId);

     
    MemberProclaimedInactive(_memberId, addressToMember_[msg.sender]);
    
     
    members_[_memberId].inactiveSince = uint64(now);
  }

   
   
  function heartbeat() public membersOnly {
     
    MemberHeartbeated(addressToMember_[msg.sender]);

     
    members_[addressToMember_[msg.sender]].inactiveSince = 0;
  }

   
   
  function revokeMembership(uint8 _memberId) public membersOnly {
     
    require(members_[_memberId].member);

     
    require(!memberIsActive(_memberId));

     
    require(addressToMember_[msg.sender] != _memberId);

     
    require(now >= members_[_memberId].inactiveSince + INACTIVITYTIMEOUT_);

     
    MembershipRevoked(_memberId, addressToMember_[msg.sender]);

     
    delete addressIsMember_[memberToAddress_[_memberId]];

     
    delete addressToMember_[memberToAddress_[_memberId]];
    
     
    delete memberToAddress_[_memberId];

     
    delete members_[_memberId];
  }

   
   
  function broadcastMessage(string _message) public membersOnly {
     
    BroadcastMessage(addressToMember_[msg.sender], _message);
  }

   
   
  function directMessage(uint8 _toMemberId, string _message) public membersOnly {
     
    DirectMessage(addressToMember_[msg.sender], _toMemberId, _message);
  }

   
   
  function passMessage(address _contractAddress, string _message) public membersOnly {
     
    Call(addressToMember_[msg.sender], _contractAddress, _message);

     
    SupportedContract(_contractAddress).theCyberMessage(_message);
  }

   
   
  function donateFunds() public membersOnly {
     
    FundsDonated(addressToMember_[msg.sender], this.balance);

     
    DONATIONADDRESS_.transfer(this.balance);
  }

   
  function donateTokens(address _tokenContractAddress) public membersOnly {
     
    require(_tokenContractAddress != address(this));

     
    TokensDonated(addressToMember_[msg.sender], _tokenContractAddress, ERC20(_tokenContractAddress).balanceOf(this));

     
    ERC20(_tokenContractAddress).transfer(DONATIONADDRESS_, ERC20(_tokenContractAddress).balanceOf(this));
  }

  function getMembershipStatus(address _memberAddress) public view returns (bool member, uint8 memberId) {
    return (
      addressIsMember_[_memberAddress],
      addressToMember_[_memberAddress]
    );
  }

  function getMemberInformation(uint8 _memberId) public view returns (bytes32 memberName, string memberKey, uint64 memberSince, uint64 inactiveSince, address memberAddress) {
    return (
      members_[_memberId].name,
      members_[_memberId].pubkey,
      members_[_memberId].memberSince,
      members_[_memberId].inactiveSince,
      memberToAddress_[_memberId]
    );
  }

  function maxMembers() public pure returns(uint16) {
    return MAXMEMBERS_;
  }

  function inactivityTimeout() public pure returns(uint64) {
    return INACTIVITYTIMEOUT_;
  }

  function donationAddress() public pure returns(address) {
    return DONATIONADDRESS_;
  }

  function memberIsActive(uint8 _memberId) internal view returns (bool) {
    return (members_[_memberId].inactiveSince == 0);
  }
}