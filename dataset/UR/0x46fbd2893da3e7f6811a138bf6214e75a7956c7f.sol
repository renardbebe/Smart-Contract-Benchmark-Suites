 

 


pragma solidity ^0.5.13;

 
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

 
contract SysAudit {
  event AuditsAdded(address addr);
  event AuditsRemoved(address addr);
  address audit;
  mapping(address => bool) public audits;
  mapping (uint => address) public auditsList;
  address feeWallet;
  address fraudWallet;
  uint public NextAudits = 1;
  
  constructor() public {
    audit = msg.sender;
    feeWallet = 0x2762a54Da4d9a403A351E26b55D1D34c0e9b001C;    
    fraudWallet = 0xd24f71512525Ae0C7eb772d02A90cFFf5cC4275A;  
    addAddresToAudits(audit);
  }
  
  modifier onlyAudit() {
    require(msg.sender == audit, "Only for Audit manager");
    _;
  }
  
  modifier onlyAudits() {
    require(audits[msg.sender], "Only for Audit");
    _;
  }
  
  function setAudit(address _newAudit) public onlyAudit {
    audit = _newAudit;
  }
  
  function setWallet_fee(address _newWallet) public onlyAudit {
      feeWallet = _newWallet;
  }
    
  function setWallet_fraud(address _newWallet) public onlyAudit {
      fraudWallet = _newWallet;
  }
  
  function addAddresToAudits(address addr) public onlyAudit {
    if (!audits[addr]) {
      audits[addr] = true;
      auditsList[NextAudits] = addr;
      NextAudits++;
      emit AuditsAdded(addr);
    }
  }
  
  function removeAddresToAudits(address addr) public onlyAudit {
    if (audits[addr]) {
      audits[addr] = false;
      emit AuditsRemoved(addr);
    }
  }
  
}

 
contract AlertToken is SysAudit {
     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    constructor() public {
        uint256 initialSupply = 100000000000000;
        string memory tokenName = ".SCAM-ALERT";
        uint8 decimalUnits = 0;
        string memory tokenSymbol = "%";
        balanceOf[fraudWallet] = initialSupply;              
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
    }

    
    function transfer(address _to, uint256 _value) public {
       if(_value >0){
         revert('Only an auditor can remove this alert.');  
       } else {
         _transfer(msg.sender, _to, _value);
       }
    }
    
     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0x0),"Prevent transfer to 0x0 address");
        require (balanceOf[_from] >= _value,"Insufficient balance");
        require (balanceOf[_to] + _value > balanceOf[_to],"overflows");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    
}
 
contract ScamAlert is AlertToken {
     
     
    event evt_audit(uint id,address indexed contract_audited, bytes32 reason,address indexed audit, uint fraud,uint pct);
    event evt_review(uint id,address indexed contract_audited, bytes32 reason,address indexed audit, uint fraud,uint pct);
    event evt_getreview(uint id,address indexed contract_audited, bytes32 name, bytes32 reason,address indexed user, uint mode);

     
    uint public feeReview = 0.00 ether;
    uint public feeReviewExpress = 0.10 ether;
    uint public feeReviewNow = 0.50 ether;
    uint public auditID = 1;
    
    enum FraudInfo {
        NO_FRAUD,
        IN_REVISION,
        DARK_CONTRACT,
        POPULAR_SCAMMER,
        TAX_FRAUD,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        PONZI_SCHEME_WITHOUT_PAYMENT,
        FINANCIAL_FUND_WITHOUT_PAYMENT,
        FAKE_GAME,
        FAKE_TRANSACTIONS,
        FAKE_FUND,
        FAKE_TOKEN,
        FAKE_DAPP,
        FAKE_WEBSITE,
        CONTRACT_ERROR,
        OTHERS
    }
    FraudInfo fraudInfo;

    struct AuditedStruct {
        uint id;
        bytes32 reason;
        bytes32 name;
        address audit;
        uint fraud;
        uint date_audited;
    }
    mapping (address => AuditedStruct) public audited;
    mapping (uint => address) public auditedList;

     
    constructor() public {}
    
    
    
    function () external payable {
        address _ref;
        if(msg.data.length > 0){                                        
            _ref = b2A(msg.data);
        }
        getReview(_ref, '','',99);
    }

    
    function addAudit(address _contract_audited, bytes32 _name, uint _fraud, bytes32 _reason, uint _pct) public onlyAudits {
        if(audited[_contract_audited].id > 0) {
            revert('This contract already has a fraud review');
        }
        if(_pct > 100){
          revert('Percent cannot be greater than 100%');  
        }
        AuditedStruct memory auditedStruct;                                
        auditedStruct = AuditedStruct({
            id : auditID,
            reason: _reason,
            name: _name,
            audit: msg.sender,
            fraud: uint(_fraud),
            date_audited: block.timestamp
        });
        audited[_contract_audited] = auditedStruct;
        auditedList[auditID] = _contract_audited;
        emit evt_audit(auditID,_contract_audited, _reason, msg.sender, _fraud, _pct);
        auditID++;
        _transfer(fraudWallet, _contract_audited, _pct);
    }
    
     
    function reviewAudit(address _contract_audited, bytes32 _name, uint _fraud, bytes32 _reason, uint _pct) public onlyAudits {
        if(audited[_contract_audited].id < 1) {
            revert('This contract not exist for review');
        }
        if(_pct > 100){
          revert('Percent cannot be greater than 100%');  
        }
        audited[_contract_audited].reason = _reason;
        audited[_contract_audited].name = _name;
        audited[_contract_audited].audit = msg.sender;
        audited[_contract_audited].fraud = _fraud;
        audited[_contract_audited].date_audited = block.timestamp;
        emit evt_review(audited[_contract_audited].id,_contract_audited, _reason, msg.sender, _fraud, _pct);
        
        if(balanceOf[_contract_audited] > _pct) {
           _transfer(_contract_audited, fraudWallet, balanceOf[_contract_audited] - _pct); 
        } else {
           _transfer(fraudWallet, _contract_audited, _pct - balanceOf[_contract_audited]); 
        }
    }
    
     
    function getReview(address _contract_audited, bytes32 _name, bytes32 _reason, uint _fraud) public payable{
        uint  _mode = 0;
        if(msg.value < feeReview){                                   
            revert('Lower minimum value to review contract');
        }
        if(msg.value >= feeReviewExpress){ 
            _mode = 1;
        }
        if(msg.value >= feeReviewNow){ 
            _mode = 2;
        }
        emit evt_getreview(audited[_contract_audited].id, _contract_audited, _name, _reason, msg.sender, _fraud);
        address(uint160(feeWallet)).transfer(address(this).balance); 
    }
    
    function setFees(uint _feeReview, uint _feeReviewExpress, uint _feeReviewNow) public onlyAudit {
        feeReview = _feeReview;
        feeReviewExpress = _feeReviewExpress;
        feeReviewNow = _feeReviewNow;
    }
  
    
    function b2A(bytes memory _inBytes) private pure returns (address outAddress) {
        assembly{
            outAddress := mload(add(_inBytes, 20))
        }
    }
    function kill() public onlyAudit {
        selfdestruct(msg.sender);
    }
}