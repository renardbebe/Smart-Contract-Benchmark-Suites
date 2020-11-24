 

 
 

pragma solidity ^0.4.23;


 
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

pragma solidity ^0.4.23;

 
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

pragma solidity ^0.4.23;


 
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

pragma solidity ^0.4.24;

contract SolidStampRegister is Ownable
{
 
    address public contractSolidStamp;

     
    uint8 public constant NOT_AUDITED = 0x00;

     
    uint8 public constant AUDITED_AND_APPROVED = 0x01;

     
    uint8 public constant AUDITED_AND_REJECTED = 0x02;

     
     
     
     
    mapping (bytes32 => uint8) public AuditOutcomes;

     
    event AuditRegistered(address auditor, bytes32 codeHash, bool isApproved);

     
     
     
     
     
     
     
    constructor(address[] _existingAuditors, bytes32[] _existingCodeHashes, bool[] _outcomes) public {
        uint noOfExistingAudits = _existingAuditors.length;
        require(noOfExistingAudits == _existingCodeHashes.length, "paramters mismatch");
        require(noOfExistingAudits == _outcomes.length, "paramters mismatch");

         
        contractSolidStamp = msg.sender;
        for (uint i=0; i<noOfExistingAudits; i++){
            registerAuditOutcome(_existingAuditors[i], _existingCodeHashes[i], _outcomes[i]);
        }
        contractSolidStamp = 0x0;
    }

    function getAuditOutcome(address _auditor, bytes32 _codeHash) public view returns (uint8)
    {
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));
        return AuditOutcomes[hashAuditorCode];
    }

    function registerAuditOutcome(address _auditor, bytes32 _codeHash, bool _isApproved) public onlySolidStampContract
    {
        require(_auditor != 0x0, "auditor cannot be 0x0");
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));
        if ( _isApproved )
            AuditOutcomes[hashAuditorCode] = AUDITED_AND_APPROVED;
        else
            AuditOutcomes[hashAuditorCode] = AUDITED_AND_REJECTED;
        emit AuditRegistered(_auditor, _codeHash, _isApproved);
    }


    event SolidStampContractChanged(address newSolidStamp);
     
    modifier onlySolidStampContract() {
      require(msg.sender == contractSolidStamp, "cannot be run by not SolidStamp contract");
      _;
    }

     
    function changeSolidStampContract(address _newSolidStamp) public onlyOwner {
      require(_newSolidStamp != address(0), "SolidStamp contract cannot be 0x0");
      emit SolidStampContractChanged(_newSolidStamp);
      contractSolidStamp = _newSolidStamp;
    }

}

pragma solidity ^0.4.24;

 
contract SolidStamp is Ownable, Pausable, Upgradable {
    using SafeMath for uint;

     
    uint8 public constant NOT_AUDITED = 0x00;

     
    uint public constant MIN_AUDIT_TIME = 24 hours;

     
    uint public constant MAX_AUDIT_TIME = 28 days;

     
    uint public TotalRequestsAmount = 0;

     
    uint public AvailableCommission = 0;

     
    uint public Commission = 9;

     
    event NewCommission(uint commmission);

    address public SolidStampRegisterAddress;

     
    constructor(address _addressRegistrySolidStamp) public {
        SolidStampRegisterAddress = _addressRegistrySolidStamp;
    }

     
    struct AuditRequest {
         
        uint amount;
         
        uint expireDate;
    }

     
     
     
     
    mapping (bytes32 => uint) public Rewards;

     
     
    mapping (bytes32 => AuditRequest) public AuditRequests;

     
    event AuditRequested(address auditor, address bidder, bytes32 codeHash, uint amount, uint expireDate);
     
    event RequestWithdrawn(address auditor, address bidder, bytes32 codeHash, uint amount);
     
    event ContractAudited(address auditor, bytes32 codeHash, uint reward, bool isApproved);

     
     
     
     
    function requestAudit(address _auditor, bytes32 _codeHash, uint _auditTime)
    public whenNotPaused payable
    {
        require(_auditor != 0x0, "_auditor cannot be 0x0");
         
        require(_auditTime >= MIN_AUDIT_TIME, "_auditTime should be >= MIN_AUDIT_TIME");
        require(_auditTime <= MAX_AUDIT_TIME, "_auditTime should be <= MIN_AUDIT_TIME");
        require(msg.value > 0, "msg.value should be >0");

         
        uint8 outcome = SolidStampRegister(SolidStampRegisterAddress).getAuditOutcome(_auditor, _codeHash);
        require(outcome == NOT_AUDITED, "contract already audited");

        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));
        uint currentReward = Rewards[hashAuditorCode];
        uint expireDate = now.add(_auditTime);
        Rewards[hashAuditorCode] = currentReward.add(msg.value);
        TotalRequestsAmount = TotalRequestsAmount.add(msg.value);

        bytes32 hashAuditorRequestorCode = keccak256(abi.encodePacked(_auditor, msg.sender, _codeHash));
        AuditRequest storage request = AuditRequests[hashAuditorRequestorCode];
        if ( request.amount == 0 ) {
             
            AuditRequests[hashAuditorRequestorCode] = AuditRequest({
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
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));

         
        uint8 outcome = SolidStampRegister(SolidStampRegisterAddress).getAuditOutcome(_auditor, _codeHash);
        require(outcome == NOT_AUDITED, "contract already audited");

        bytes32 hashAuditorRequestorCode = keccak256(abi.encodePacked(_auditor, msg.sender, _codeHash));
        AuditRequest storage request = AuditRequests[hashAuditorRequestorCode];
        require(request.amount > 0, "nothing to withdraw");
        require(now > request.expireDate, "cannot withdraw before request.expireDate");

        uint amount = request.amount;
        delete request.amount;
        delete request.expireDate;
        Rewards[hashAuditorCode] = Rewards[hashAuditorCode].sub(amount);
        TotalRequestsAmount = TotalRequestsAmount.sub(amount);
        emit RequestWithdrawn(_auditor, msg.sender, _codeHash, amount);
        msg.sender.transfer(amount);
    }

     
     
     
    function auditContract(bytes32 _codeHash, bool _isApproved)
    public whenNotPaused
    {
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(msg.sender, _codeHash));

         
        uint8 outcome = SolidStampRegister(SolidStampRegisterAddress).getAuditOutcome(msg.sender, _codeHash);
        require(outcome == NOT_AUDITED, "contract already audited");

        SolidStampRegister(SolidStampRegisterAddress).registerAuditOutcome(msg.sender, _codeHash, _isApproved);
        uint reward = Rewards[hashAuditorCode];
        TotalRequestsAmount = TotalRequestsAmount.sub(reward);
        uint commissionKept = calcCommission(reward);
        AvailableCommission = AvailableCommission.add(commissionKept);
        emit ContractAudited(msg.sender, _codeHash, reward, _isApproved);
        msg.sender.transfer(reward.sub(commissionKept));
    }

     
    uint public constant MAX_COMMISSION = 33;

     
     
    function changeCommission(uint _newCommission) public onlyOwner whenNotPaused {
        require(_newCommission <= MAX_COMMISSION, "commission should be <= MAX_COMMISSION");
        require(_newCommission != Commission, "_newCommission==Commmission");
        Commission = _newCommission;
        emit NewCommission(Commission);
    }

     
     
    function calcCommission(uint _amount) private view returns(uint) {
        return _amount.mul(Commission)/100;  
    }

     
     
    function withdrawCommission(uint _amount) public onlyOwner {
         
        require(_amount <= AvailableCommission, "Cannot withdraw more than available");
        AvailableCommission = AvailableCommission.sub(_amount);
        msg.sender.transfer(_amount);
    }

     
     
     
     
    function unpause() public onlyOwner whenPaused {
        require(newContractAddress == address(0), "new contract cannot be 0x0");

         
        super.unpause();
    }

     
    function() payable public {
        revert();
    }
}