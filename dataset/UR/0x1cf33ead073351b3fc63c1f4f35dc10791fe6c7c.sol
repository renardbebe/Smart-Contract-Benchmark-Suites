 

pragma solidity 0.4.24;

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BGAudit is Ownable {

    using SafeMath for uint;

    event AddedAuditor(address indexed auditor);
    event BannedAuditor(address indexed auditor);
    event AllowedAuditor(address indexed auditor);

    event CreatedAudit(uint indexed id);
    event ReviewingAudit(uint indexed id);
    event AuditorRewarded(uint indexed id, address indexed auditor, uint indexed reward);

    event AuditorStaked(uint indexed id, address indexed auditor, uint indexed amount);
    event WithdrawedStake(uint indexed id, address indexed auditor, uint indexed amount);
    event SlashedStake(uint indexed id, address indexed auditor);

    enum AuditStatus { New, InProgress, InReview, Completed }

    struct Auditor {
        bool banned;
        address addr;
        uint totalEarned;
        uint completedAudits;
        uint[] stakedAudits;  
        mapping(uint => bool) stakedInAudit;  
        mapping(uint => bool) canWithdrawStake;  
    }

    struct Audit {
        AuditStatus status;
        address owner;
        uint id;
        uint totalReward;  
        uint remainingReward;  
        uint stake;  
        uint endTime;  
        uint maxAuditors;  
        address[] participants;  
    }

     
    uint public stakePeriod = 90 days;  
    uint public maxAuditDuration = 365 days;  
    Audit[] public audits;
    mapping(address => Auditor) public auditors;

     
    function transfer(address _to, uint _amountInWei) external onlyOwner {
        require(address(this).balance > _amountInWei);
        _to.transfer(_amountInWei);
    }

    function setStakePeriod(uint _days) external onlyOwner {
        stakePeriod = _days * 1 days;
    }

    function setMaxAuditDuration(uint _days) external onlyOwner {
        maxAuditDuration = _days * 1 days;
    }


     
    function addAuditor(address _auditor) external onlyOwner {
        require(auditors[_auditor].addr == address(0));  

        auditors[_auditor].banned = false;
        auditors[_auditor].addr = _auditor;
        auditors[_auditor].completedAudits = 0;
        auditors[_auditor].totalEarned = 0;
        emit AddedAuditor(_auditor);
    }

    function banAuditor(address _auditor) external onlyOwner {
        require(auditors[_auditor].addr != address(0));
        auditors[_auditor].banned = true;
        emit BannedAuditor(_auditor);
    }

    function allowAuditor(address _auditor) external onlyOwner {
        require(auditors[_auditor].addr != address(0));
        auditors[_auditor].banned = false;
        emit AllowedAuditor(_auditor);
    }


     
    function createAudit(uint _stake, uint _endTimeInDays, uint _maxAuditors) external payable onlyOwner {
        uint endTime = _endTimeInDays * 1 days;
        require(endTime < maxAuditDuration);
        require(block.timestamp + endTime * 1 days > block.timestamp);
        require(msg.value > 0 && _maxAuditors > 0 && _stake > 0);

        Audit memory audit;
        audit.status = AuditStatus.New;
        audit.owner = msg.sender;
        audit.id = audits.length;
        audit.totalReward = msg.value;
        audit.remainingReward = audit.totalReward;
        audit.stake = _stake;
        audit.endTime = block.timestamp + endTime;
        audit.maxAuditors = _maxAuditors;

        audits.push(audit);  
        emit CreatedAudit(audit.id);
    }

    function reviewAudit(uint _id) external onlyOwner {
        require(audits[_id].status == AuditStatus.InProgress);
        require(block.timestamp >= audits[_id].endTime);
        audits[_id].endTime = block.timestamp;  
        audits[_id].status = AuditStatus.InReview;
        emit ReviewingAudit(_id);
    }

    function rewardAuditor(uint _id, address _auditor, uint _reward) external onlyOwner {

        audits[_id].remainingReward.sub(_reward);
        audits[_id].status = AuditStatus.Completed;

        auditors[_auditor].totalEarned.add(_reward);
        auditors[_auditor].completedAudits.add(1);
        auditors[_auditor].canWithdrawStake[_id] = true;  
        _auditor.transfer(_reward);
        emit AuditorRewarded(_id, _auditor, _reward);
    }

    function slashStake(uint _id, address _auditor) external onlyOwner {
        require(auditors[_auditor].addr != address(0));
        require(auditors[_auditor].stakedInAudit[_id]);  
        auditors[_auditor].canWithdrawStake[_id] = false;
        emit SlashedStake(_id, _auditor);
    }

     
    function stake(uint _id) public payable {
         
        require(msg.value == audits[_id].stake);
        require(block.timestamp < audits[_id].endTime);
        require(audits[_id].participants.length < audits[_id].maxAuditors);
        require(audits[_id].status == AuditStatus.New || audits[_id].status == AuditStatus.InProgress);

         
        require(auditors[msg.sender].addr == msg.sender && !auditors[msg.sender].banned);  
        require(!auditors[msg.sender].stakedInAudit[_id]);  

         
        audits[_id].status = AuditStatus.InProgress;
        audits[_id].participants.push(msg.sender);

         
        auditors[msg.sender].stakedInAudit[_id] = true;
        auditors[msg.sender].stakedAudits.push(_id);
        emit AuditorStaked(_id, msg.sender, msg.value);
    }

    function withdrawStake(uint _id) public {
        require(audits[_id].status == AuditStatus.Completed);
        require(auditors[msg.sender].canWithdrawStake[_id]);
        require(block.timestamp >= audits[_id].endTime + stakePeriod);

        auditors[msg.sender].canWithdrawStake[_id] = false;  
        address(msg.sender).transfer(audits[_id].stake);  
        emit WithdrawedStake(_id, msg.sender, audits[_id].stake);
    }

     
    function auditorHasStaked(uint _id, address _auditor) public view returns(bool) {
        return auditors[_auditor].stakedInAudit[_id];
    }

    function auditorCanWithdrawStake(uint _id, address _auditor) public view returns(bool) {
        if(auditors[_auditor].stakedInAudit[_id] && auditors[_auditor].canWithdrawStake[_id]) {
            return true;
        }
        return false;
    }

     
    function getStakedAudits(address _auditor) public view returns(uint[]) {
        return auditors[_auditor].stakedAudits;
    }

     
    function getAuditors(uint _id) public view returns(address[]) {
        return audits[_id].participants;
    }
}