 

pragma solidity ^0.4.24;



 
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


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

     
    uint public constant MIN_AUDIT_TIME = 24 hours;

     
    uint public constant MAX_AUDIT_TIME = 28 days;

     
    uint public TotalRequestsAmount = 0;

     
    uint public AvailableCommission = 0;

     
    uint public Commission = 1;

     
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
     
    event ContractAudited(address auditor, bytes32 codeHash, bytes reportIPFS, bool isApproved, uint reward);

     
     
     
     
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

     
     
     
     
     
    function auditContract(address _auditor, bytes32 _codeHash, bytes _reportIPFS, bool _isApproved)
    public whenNotPaused onlySolidStampRegisterContract
    {
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));
        uint reward = Rewards[hashAuditorCode];
        TotalRequestsAmount = TotalRequestsAmount.sub(reward);
        uint commissionKept = calcCommission(reward);
        AvailableCommission = AvailableCommission.add(commissionKept);
        emit ContractAudited(_auditor, _codeHash, _reportIPFS, _isApproved, reward);
        _auditor.transfer(reward.sub(commissionKept));
    }

     
    modifier onlySolidStampRegisterContract() {
      require(msg.sender == SolidStampRegisterAddress, "can be only run by SolidStampRegister contract");
      _;
    }

     
    uint public constant MAX_COMMISSION = 9;

     
     
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

contract SolidStampRegister is Ownable
{
 
    address public ContractSolidStamp;

     
    uint8 public constant NOT_AUDITED = 0x00;

     
    uint8 public constant AUDITED_AND_APPROVED = 0x01;

     
    uint8 public constant AUDITED_AND_REJECTED = 0x02;

     
    struct Audit {
         
        uint8 outcome;
         
        bytes reportIPFS;
    }

     
     
     
    mapping (bytes32 => Audit) public Audits;

     
    event AuditRegistered(address auditor, bytes32 codeHash, bytes reportIPFS, bool isApproved);

     
    constructor() public {
    }

     
     
     
    function getAuditOutcome(address _auditor, bytes32 _codeHash) public view returns (uint8)
    {
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));
        return Audits[hashAuditorCode].outcome;
    }

     
     
     
    function getAuditReportIPFS(address _auditor, bytes32 _codeHash) public view returns (bytes)
    {
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(_auditor, _codeHash));
        return Audits[hashAuditorCode].reportIPFS;
    }

     
     
     
     
    function registerAudit(bytes32 _codeHash, bytes _reportIPFS, bool _isApproved) public
    {
        require(_codeHash != 0x0, "codeHash cannot be 0x0");
        require(_reportIPFS.length != 0x0, "report IPFS cannot be 0x0");
        bytes32 hashAuditorCode = keccak256(abi.encodePacked(msg.sender, _codeHash));

        Audit storage audit = Audits[hashAuditorCode];
        require(audit.outcome == NOT_AUDITED, "already audited");

        if ( _isApproved )
            audit.outcome = AUDITED_AND_APPROVED;
        else
            audit.outcome = AUDITED_AND_REJECTED;
        audit.reportIPFS = _reportIPFS;
        SolidStamp(ContractSolidStamp).auditContract(msg.sender, _codeHash, _reportIPFS, _isApproved);
        emit AuditRegistered(msg.sender, _codeHash, _reportIPFS, _isApproved);
    }

     
     
     
     
    function registerAudits(bytes32[] _codeHashes, bytes _reportIPFS, bool _isApproved) public
    {
        for(uint i=0; i<_codeHashes.length; i++ )
        {
            registerAudit(_codeHashes[i], _reportIPFS, _isApproved);
        }
    }


    event SolidStampContractChanged(address newSolidStamp);

     
     
    function changeSolidStampContract(address _newSolidStamp) public onlyOwner {
      require(_newSolidStamp != address(0), "SolidStamp contract cannot be 0x0");
      emit SolidStampContractChanged(_newSolidStamp);
      ContractSolidStamp = _newSolidStamp;
    }

     
    function() payable public {
        revert();
    }    
}