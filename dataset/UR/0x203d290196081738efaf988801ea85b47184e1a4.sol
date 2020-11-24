 

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 
contract Fund is
    Ownable
{
   
   
   
  struct Member {
    string name;
    uint256 usedKm;
    uint256 activityKm;
    uint256 updatedActivityID;
    bool isClaimed;
  }

  mapping(address=>Member) public members;
  mapping(address=>bool) public isMember;
   
   

   
   
  enum ActivityStatus {
    END,     
    START,
    CLAIM
  }

  uint256 public totalKm;
  uint256 public activityID;
  uint256 public activityTotalKm;
  ActivityStatus public activityStatus;

  mapping(uint256=>bool) private isUsedActivityID;
   
   

   
   
  uint256 public totalReward;
  uint256 public usedReward;
   
   

   
   
  event RegisterMember(address member, string name);
  event DeregisterMember(address member);
  event SetName(address member, string name);
  event SetAddress(address oldAddress,  address newAddress);
  event StartActivity(uint256 id, uint256 reward);
  event AdditionalReward(uint256 id, uint256 addReward);
  event AddKm(uint256 id, address member, uint256 addKm);
  event SubKm(uint256 id, address member, uint256 subKm);
  event StartClaim();
  event Claim(uint256 id, address member, uint256 activityKm, uint256 reward);
  event EndActivity(uint256 surplus);
   
   

   
   
  modifier onlyMember() {
    require(
      isMember[msg.sender],
      "NOT_MEMBER"
    );
    _;
  }

  function registerMembers(address[] memory _members, string[] memory _names) public onlyOwner {
    require(
      _members.length == _names.length,
      "REGISTER_LENGTH_NOT_EQUAL"
    );

    for(uint i = 0; i < _members.length; i++) {
      require(
        !isMember[_members[i]],
        "MEMBER_REGISTERED"
      );

      members[_members[i]] = Member({
        name: _names[i],
        usedKm: 0,
        activityKm: 0,
        updatedActivityID: 0,
        isClaimed: false});
      isMember[_members[i]] = true;

      emit RegisterMember(_members[i], _names[i]);
    }
  }

  function deregisterMembers(address[] memory _members) public onlyOwner {
    for(uint i = 0; i < _members.length; i++) {
      isMember[_members[i]] = false;

      emit DeregisterMember(_members[i]);
    }
  }

  function setName(string memory _name) public onlyMember {
    members[msg.sender].name = _name;

    emit SetName(msg.sender, _name);
  }

  function setAddress(address _newAddress) public onlyMember {
    require(
      !isMember[_newAddress],
      "MEMBER_REGISTERED"
    );

    members[_newAddress] = members[msg.sender];
    isMember[_newAddress] = true;
    isMember[msg.sender] = false;

    emit SetAddress(msg.sender, _newAddress);
  }
   
   


   
   
   
  function startActivity(uint256 _id) public payable onlyOwner {
    require(
      activityStatus == ActivityStatus.END,
      "ACTIVITY_NOT_END"
    );

    require(
      !isUsedActivityID[_id],
      "USED_ACTIVITYID"
    );

    activityID = _id;
    activityStatus = ActivityStatus.START;

    totalReward = msg.value;

    isUsedActivityID[activityID] = true;

    emit StartActivity(activityID, totalReward);
  }

   
  function() external payable{
    require(
      activityStatus == ActivityStatus.START,
      "ACTIVITY_NOT_START"
    );

    totalReward = SafeMath.add(totalReward, msg.value);

    emit AdditionalReward(activityID, msg.value);
  }

  function addKm(address[] memory _members, uint256[] memory _kms) public onlyOwner{
    require(
      activityStatus == ActivityStatus.START,
      "ACTIVITY_NOT_START"
    );

    require(
      _members.length == _kms.length,
      "UPDATEKM_LENGTH_NOT_EQUAL"
    );

    for(uint i = 0; i < _members.length; i++) {
      require(
        isMember[_members[i]],
        "NOT_MEMBER"
      );

      if(members[_members[i]].updatedActivityID != activityID) {
        members[_members[i]].activityKm = 0;
        members[_members[i]].updatedActivityID = activityID;
        members[_members[i]].isClaimed = false;
      }

      members[_members[i]].activityKm = SafeMath.add(
        members[_members[i]].activityKm,
        _kms[i]); 

      activityTotalKm = SafeMath.add(activityTotalKm, _kms[i]);

      emit AddKm(activityID, _members[i], _kms[i]);
    }
  }

  function subKm(address[] memory _members, uint256[] memory _kms) public onlyOwner{
    require(
      activityStatus == ActivityStatus.START,
      "ACTIVITY_NOT_START"
    );

    require(
      _members.length == _kms.length,
      "UPDATEKM_LENGTH_NOT_EQUAL"
    );

    for(uint i = 0; i < _members.length; i++) {
      require(
        isMember[_members[i]],
        "NOT_MEMBER"
      );

      require(
        members[_members[i]].updatedActivityID == activityID,
        "NO_KM_UPDATE"
      );

      require(
        members[_members[i]].activityKm > _kms[i],
        "KM_MORE_THEN_ACTIVITYKM"
      );

      members[_members[i]].activityKm = SafeMath.sub(
        members[_members[i]].activityKm,
        _kms[i]);

      activityTotalKm = SafeMath.sub(activityTotalKm, _kms[i]);

      emit SubKm(activityID, _members[i], _kms[i]);
    }
  }

  function startClaim() public onlyOwner {
    require(
      activityStatus == ActivityStatus.START,
      "ACTIVITY_NOT_START"
    );

    activityStatus = ActivityStatus.CLAIM;

    emit StartClaim();
  }

  function claim() public onlyMember {
    require(
      activityStatus == ActivityStatus.CLAIM,
      "ACTIVITY_NOT_CLAIM"
    );

    require(
      members[msg.sender].updatedActivityID == activityID,
      "ACTIVITYID_NOT_EQUAL"
    );

    require(
      !members[msg.sender].isClaimed,
      "IS_CLAIMED"
    );

    members[msg.sender].isClaimed = true;
    members[msg.sender].usedKm = SafeMath.add(
      members[msg.sender].usedKm,
      members[msg.sender].activityKm
    );
    totalKm = SafeMath.add(totalKm, members[msg.sender].activityKm);

    uint256 value = SafeMath.div(
      SafeMath.mul(
        totalReward,
        members[msg.sender].activityKm),
      activityTotalKm
    );

    usedReward = SafeMath.add(usedReward, value);
    msg.sender.transfer(value);

    emit Claim(activityID, msg.sender, members[msg.sender].activityKm, value);
  }

   
  function endActivity() public onlyOwner {
    activityStatus = ActivityStatus.END;

    activityID = 0;
    activityTotalKm = 0;
    totalReward = 0;
    usedReward = 0;

    uint256 value = address(this).balance;
    msg.sender.transfer(value);

    emit EndActivity(value);
  }
   
   
}