 

pragma solidity ^0.4.24;

 
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

  function min(uint a, uint b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}



 
contract Membership {
    using SafeMath for uint256;
    
     
    address public owner;
     
    uint public memberFee;

     
     
    struct Member {
        uint memberId;
        uint membershipType;
    }
    
     
     
    mapping(address => Member) public members;
    address[] public membersAccts;
    mapping (address => uint) public membersAcctsIndex;

     
    event UpdateMemberAddress(address _from, address _to);
    event NewMember(address _address, uint _memberId, uint _membershipType);
    event Refund(address _address, uint _amount);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     
     
     constructor() public {
        owner = msg.sender;
    }

     
    function setFee(uint _memberFee) public onlyOwner() {
         
        memberFee = _memberFee;
    }
    
     
    function requestMembership() public payable {
        Member storage sender = members[msg.sender];
        require(msg.value >= memberFee && sender.membershipType == 0 );
        membersAccts.push(msg.sender);
        sender.memberId = membersAccts.length;
        sender.membershipType = 1;
        emit NewMember(msg.sender, sender.memberId, sender.membershipType);
    }
    
     
    function updateMemberAddress(address _from, address _to) public onlyOwner {
        require(_to != address(0));
        Member storage currentAddress = members[_from];
        Member storage newAddress = members[_to];
        require(newAddress.memberId == 0);
        newAddress.memberId = currentAddress.memberId;
        newAddress.membershipType = currentAddress.membershipType;
        membersAccts[currentAddress.memberId - 1] = _to;
        currentAddress.memberId = 0;
        currentAddress.membershipType = 0;
        emit UpdateMemberAddress(_from, _to);
    }

     
    function setMembershipType(address _memberAddress,  uint _membershipType) public onlyOwner{
        Member storage memberAddress = members[_memberAddress];
        memberAddress.membershipType = _membershipType;
    }

     
    function setMemberId(address _memberAddress,  uint _memberId) public onlyOwner{
        Member storage memberAddress = members[_memberAddress];
        memberAddress.memberId = _memberId;
    }

     
    function removeMemberAcct(address _memberAddress) public onlyOwner{
        require(_memberAddress != address(0));
        uint256 indexToDelete;
        uint256 lastAcctIndex;
        address lastAdd;
        Member storage memberAddress = members[_memberAddress];
        memberAddress.memberId = 0;
        memberAddress.membershipType = 0;
        indexToDelete = membersAcctsIndex[_memberAddress];
        lastAcctIndex = membersAccts.length.sub(1);
        lastAdd = membersAccts[lastAcctIndex];
        membersAccts[indexToDelete]=lastAdd;
        membersAcctsIndex[lastAdd] = indexToDelete;   
        membersAccts.length--;
        membersAcctsIndex[_memberAddress]=0; 
    }


     
    function addMemberAcct(address _memberAddress) public onlyOwner{
        require(_memberAddress != address(0));
        Member storage memberAddress = members[_memberAddress];
        membersAcctsIndex[_memberAddress] = membersAccts.length; 
        membersAccts.push(_memberAddress);
        memberAddress.memberId = membersAccts.length;
        memberAddress.membershipType = 1;
        emit NewMember(_memberAddress, memberAddress.memberId, memberAddress.membershipType);
    }

     
    function getMembers() view public returns (address[]){
        return membersAccts;
    }
    
     
    function getMember(address _memberAddress) view public returns(uint, uint) {
        return(members[_memberAddress].memberId, members[_memberAddress].membershipType);
    }

     
    function countMembers() view public returns(uint) {
        return membersAccts.length;
    }

     
    function getMembershipType(address _memberAddress) public constant returns(uint){
        return members[_memberAddress].membershipType;
    }
    
     
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }

     
    function refund(address _to, uint _amount) public onlyOwner {
        require (_to != address(0));
        if (_amount == 0) {_amount = memberFee;}
        removeMemberAcct(_to);
        _to.transfer(_amount);
        emit Refund(_to, _amount);
    }

     
    function withdraw(address _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }    
}