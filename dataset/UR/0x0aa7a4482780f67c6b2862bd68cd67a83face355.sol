 

pragma solidity ^0.4.21;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

pragma solidity ^0.4.23;


contract Upgradable is Ownable, Pausable {
     
    address public newContractAddress;

     
    event ContractUpgrade(address newContract);

     
     
     
     
     
     
    function setNewAddress(address _v2Address) external onlyOwner whenPaused {
        require(_v2Address != 0x0);
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

}

 
contract SolidStamp is Ownable, Pausable, Upgradable {
    using SafeMath for uint;

     
    uint8 public constant NOT_AUDITED = 0x00;

     
    uint8 public constant AUDITED_AND_APPROVED = 0x01;

     
    uint8 public constant AUDITED_AND_REJECTED = 0x02;

     
    uint public constant MIN_AUDIT_TIME = 24 hours;

     
    uint public constant MAX_AUDIT_TIME = 28 days;

     
    uint public totalRequestsAmount = 0;

     
    uint public availableCommission = 0;

     
    uint public commission = 9;

     
    event NewCommission(uint commmission);

     
    constructor() public {
    }

     
    struct AuditRequest {
         
        uint amount;
         
        uint expireDate;
    }

     
     
     
     
    mapping (bytes32 => uint) public rewards;

     
     
     
     
    mapping (bytes32 => uint8) public auditOutcomes;

     
     
    mapping (bytes32 => AuditRequest) public auditRequests;

     
    event AuditRequested(address auditor, address bidder, bytes32 codeHash, uint amount, uint expireDate);
     
    event RequestWithdrawn(address auditor, address bidder, bytes32 codeHash, uint amount);
     
    event ContractAudited(address auditor, bytes32 codeHash, uint reward, bool isApproved);

     
     
     
     
    function requestAudit(address _auditor, bytes32 _codeHash, uint _auditTime)
    public whenNotPaused payable
    {
        require(_auditor != 0x0);
         
        require(_auditTime >= MIN_AUDIT_TIME);
        require(_auditTime <= MAX_AUDIT_TIME);
        require(msg.value > 0);

        bytes32 hashAuditorCode = keccak256(_auditor, _codeHash);

         
        uint8 outcome = auditOutcomes[hashAuditorCode];
        require(outcome == NOT_AUDITED);

        uint currentReward = rewards[hashAuditorCode];
        uint expireDate = now.add(_auditTime);
        rewards[hashAuditorCode] = currentReward.add(msg.value);
        totalRequestsAmount = totalRequestsAmount.add(msg.value);

        bytes32 hashAuditorRequestorCode = keccak256(_auditor, msg.sender, _codeHash);
        AuditRequest storage request = auditRequests[hashAuditorRequestorCode];
        if ( request.amount == 0 ) {
             
            auditRequests[hashAuditorRequestorCode] = AuditRequest({
                amount : msg.value,
                expireDate : expireDate
            });
            emit AuditRequested(_auditor, msg.sender, _codeHash, msg.value, expireDate);
        } else {
             
            request.amount = request.amount.add(msg.value);
             
            if ( expireDate > request.expireDate )
                request.expireDate = expireDate;
             
            emit AuditRequested(_auditor, msg.sender, _codeHash, request.amount, request.expireDate);
        }
    }

     
     
     
    function withdrawRequest(address _auditor, bytes32 _codeHash)
    public
    {
        bytes32 hashAuditorCode = keccak256(_auditor, _codeHash);

         
        uint8 outcome = auditOutcomes[hashAuditorCode];
        require(outcome == NOT_AUDITED);

        bytes32 hashAuditorRequestorCode = keccak256(_auditor, msg.sender, _codeHash);
        AuditRequest storage request = auditRequests[hashAuditorRequestorCode];
        require(request.amount > 0);
        require(now > request.expireDate);

        uint amount = request.amount;
        delete request.amount;
        delete request.expireDate;
        rewards[hashAuditorCode] = rewards[hashAuditorCode].sub(amount);
        totalRequestsAmount = totalRequestsAmount.sub(amount);
        emit RequestWithdrawn(_auditor, msg.sender, _codeHash, amount);
        msg.sender.transfer(amount);
    }

     
     
     
    function auditContract(bytes32 _codeHash, bool _isApproved)
    public whenNotPaused
    {
        bytes32 hashAuditorCode = keccak256(msg.sender, _codeHash);

         
        uint8 outcome = auditOutcomes[hashAuditorCode];
        require(outcome == NOT_AUDITED);

        if ( _isApproved )
            auditOutcomes[hashAuditorCode] = AUDITED_AND_APPROVED;
        else
            auditOutcomes[hashAuditorCode] = AUDITED_AND_REJECTED;
        uint reward = rewards[hashAuditorCode];
        totalRequestsAmount = totalRequestsAmount.sub(reward);
        commission = calcCommission(reward);
        availableCommission = availableCommission.add(commission);
        emit ContractAudited(msg.sender, _codeHash, reward, _isApproved);
        msg.sender.transfer(reward.sub(commission));
    }

     
    uint public constant MAX_COMMISION = 33;

     
     
    function changeCommission(uint _newCommission) public onlyOwner whenNotPaused {
        require(_newCommission <= MAX_COMMISION);
        require(_newCommission != commission);
        commission = _newCommission;
        emit NewCommission(commission);
    }

     
     
    function calcCommission(uint _amount) private view returns(uint) {
        return _amount.mul(commission)/100;  
    }

     
     
    function withdrawCommission(uint _amount) public onlyOwner {
         
        require(_amount <= availableCommission);
        availableCommission = availableCommission.sub(_amount);
        msg.sender.transfer(_amount);
    }

     
     
     
     
    function unpause() public onlyOwner whenPaused {
        require(newContractAddress == address(0));

         
        super.unpause();
    }

     
    function() payable public {
        revert();
    }
}