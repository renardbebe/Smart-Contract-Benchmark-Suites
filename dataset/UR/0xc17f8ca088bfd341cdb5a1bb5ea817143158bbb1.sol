 

pragma solidity 0.4.25;

 

 


library LinkedListLib {

    uint256 constant NULL = 0;
    uint256 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;

    struct LinkedList{
        mapping (uint256 => mapping (bool => uint256)) list;
    }

     
     
    function listExists(LinkedList storage self)
        public
        view returns (bool)
    {
         
        if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
            return true;
        } else {
            return false;
        }
    }

     
     
     
    function nodeExists(LinkedList storage self, uint256 _node)
        public
        view returns (bool)
    {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

     
     
    function sizeOf(LinkedList storage self) public view returns (uint256 numElements) {
        bool exists;
        uint256 i;
        (exists,i) = getAdjacent(self, HEAD, NEXT);
        while (i != HEAD) {
            (exists,i) = getAdjacent(self, i, NEXT);
            numElements++;
        }
        return;
    }

     
     
     
    function getNode(LinkedList storage self, uint256 _node)
        public view returns (bool,uint256,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0,0);
        } else {
            return (true,self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

     
     
     
     
    function getAdjacent(LinkedList storage self, uint256 _node, bool _direction)
        public view returns (bool,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0);
        } else {
            return (true,self.list[_node][_direction]);
        }
    }

     
     
     
     
     
     
    function getSortedSpot(LinkedList storage self, uint256 _node, uint256 _value, bool _direction)
        public view returns (uint256)
    {
        if (sizeOf(self) == 0) { return 0; }
        require((_node == 0) || nodeExists(self,_node));
        bool exists;
        uint256 next;
        (exists,next) = getAdjacent(self, _node, _direction);
        while  ((next != 0) && (_value != next) && ((_value < next) != _direction)) next = self.list[next][_direction];
        return next;
    }

     
     
     
     
    function createLink(LinkedList storage self, uint256 _node, uint256 _link, bool _direction) private  {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

     
     
     
     
     
    function insert(LinkedList storage self, uint256 _node, uint256 _new, bool _direction) internal returns (bool) {
        if(!nodeExists(self,_new) && nodeExists(self,_node)) {
            uint256 c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);
            return true;
        } else {
            return false;
        }
    }

     
     
     
    function remove(LinkedList storage self, uint256 _node) internal returns (uint256) {
        if ((_node == NULL) || (!nodeExists(self,_node))) { return 0; }
        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        return _node;
    }

     
     
     
     
    function push(LinkedList storage self, uint256 _node, bool _direction) internal  {
        insert(self, HEAD, _node, _direction);
    }

     
     
     
    function pop(LinkedList storage self, bool _direction) internal returns (uint256) {
        bool exists;
        uint256 adj;

        (exists,adj) = getAdjacent(self, HEAD, _direction);

        return remove(self, adj);
    }
}

 

 
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

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

 
contract Whitelist is Ownable, RBAC {
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyWhitelisted() {
    checkRole(msg.sender, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address addr)
    onlyOwner
    public
  {
    addRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressAdded(addr);
  }

   
  function whitelist(address addr)
    public
    view
    returns (bool)
  {
    return hasRole(addr, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      addAddressToWhitelist(addrs[i]);
    }
  }

   
  function removeAddressFromWhitelist(address addr)
    onlyOwner
    public
  {
    removeRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressRemoved(addr);
  }

   
  function removeAddressesFromWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      removeAddressFromWhitelist(addrs[i]);
    }
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract QuantstampAuditData is Whitelist {
   
  enum AuditState {
    None,
    Queued,
    Assigned,
    Refunded,
    Completed,   
    Error,       
    Expired,
    Resolved
  }

   
  struct Audit {
    address requestor;
    string contractUri;
    uint256 price;
    uint256 requestBlockNumber;  
    QuantstampAuditData.AuditState state;
    address auditor;        
    uint256 assignBlockNumber;   
    string reportHash;      
    uint256 reportBlockNumber;   
    address registrar;   
  }

   
  mapping(uint256 => Audit) public audits;

   
   
  StandardToken public token;

   
   
  uint256 public auditTimeoutInBlocks = 50;

   
  uint256 public maxAssignedRequests = 10;

   
  mapping(address => uint256) public minAuditPrice;

   
  uint256 private requestCounter;

   
  constructor (address tokenAddress) public {
    require(tokenAddress != address(0));
    token = StandardToken(tokenAddress);
  }

  function addAuditRequest (address requestor, string contractUri, uint256 price) public onlyWhitelisted returns(uint256) {
     
    uint256 requestId = ++requestCounter;
     
    audits[requestId] = Audit(requestor, contractUri, price, block.number, AuditState.Queued, address(0), 0, "", 0, msg.sender);   
    return requestId;
  }

   
  function approveWhitelisted(uint256 amount) public onlyWhitelisted {
    token.approve(msg.sender, amount);
  }

  function getAuditContractUri(uint256 requestId) public view returns(string) {
    return audits[requestId].contractUri;
  }

  function getAuditRequestor(uint256 requestId) public view returns(address) {
    return audits[requestId].requestor;
  }

  function getAuditPrice (uint256 requestId) public view returns(uint256) {
    return audits[requestId].price;
  }

  function getAuditState (uint256 requestId) public view returns(AuditState) {
    return audits[requestId].state;
  }

  function getAuditRequestBlockNumber (uint256 requestId) public view returns(uint) {
    return audits[requestId].requestBlockNumber;
  }

  function setAuditState (uint256 requestId, AuditState state) public onlyWhitelisted {
    audits[requestId].state = state;
  }

  function getAuditAuditor (uint256 requestId) public view returns(address) {
    return audits[requestId].auditor;
  }

  function getAuditRegistrar (uint256 requestId) public view returns(address) {
    return audits[requestId].registrar;
  }

  function setAuditAuditor (uint256 requestId, address auditor) public onlyWhitelisted {
    audits[requestId].auditor = auditor;
  }

  function getAuditAssignBlockNumber (uint256 requestId) public view returns(uint256) {
    return audits[requestId].assignBlockNumber;
  }

  function getAuditReportBlockNumber (uint256 requestId) public view returns (uint256) {
    return audits[requestId].reportBlockNumber;
  }

  function setAuditAssignBlockNumber (uint256 requestId, uint256 assignBlockNumber) public onlyWhitelisted {
    audits[requestId].assignBlockNumber = assignBlockNumber;
  }

  function setAuditReportHash (uint256 requestId, string reportHash) public onlyWhitelisted {
    audits[requestId].reportHash = reportHash;
  }

  function setAuditReportBlockNumber (uint256 requestId, uint256 reportBlockNumber) public onlyWhitelisted {
    audits[requestId].reportBlockNumber = reportBlockNumber;
  }

  function setAuditRegistrar (uint256 requestId, address registrar) public onlyWhitelisted {
    audits[requestId].registrar = registrar;
  }

  function setAuditTimeout (uint256 timeoutInBlocks) public onlyOwner {
    auditTimeoutInBlocks = timeoutInBlocks;
  }

   
  function setMaxAssignedRequests (uint256 maxAssignments) public onlyOwner {
    maxAssignedRequests = maxAssignments;
  }

  function getMinAuditPrice (address auditor) public view returns(uint256) {
    return minAuditPrice[auditor];
  }

   
  function setMinAuditPrice(address auditor, uint256 price) public onlyWhitelisted {
    minAuditPrice[auditor] = price;
  }
}

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 

 

pragma solidity ^0.4.24;






 
contract TokenEscrow is Ownable, Whitelist {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  event Deposited(address indexed payee, uint256 tokenAmount);
  event Withdrawn(address indexed payee, uint256 tokenAmount);

  mapping(address => uint256) public deposits;

  ERC20 public token;

  constructor (ERC20 _token) public {
    require(_token != address(0));
    token = _token;
  }

  function depositsOf(address _payee) public view returns (uint256) {
    return deposits[_payee];
  }

   
  function deposit(address _payee, uint256 _amount) public onlyWhitelisted {
    deposits[_payee] = deposits[_payee].add(_amount);

    token.safeTransferFrom(msg.sender, address(this), _amount);

    emit Deposited(_payee, _amount);
  }

   
  function withdraw(address _payee) public onlyWhitelisted {
    uint256 payment = deposits[_payee];
    assert(token.balanceOf(address(this)) >= payment);

    deposits[_payee] = 0;

    token.safeTransfer(_payee, payment);

    emit Withdrawn(_payee, payment);
  }
}

 

 

pragma solidity ^0.4.24;



 
contract ConditionalTokenEscrow is TokenEscrow {
   
  function withdrawalAllowed(address _payee) public view returns (bool);

  function withdraw(address _payee) public {
    require(withdrawalAllowed(_payee));
    super.withdraw(_payee);
  }
}

 

contract QuantstampAuditTokenEscrow is ConditionalTokenEscrow {

   
  using LinkedListLib for LinkedListLib.LinkedList;

   
  uint256 constant internal NULL = 0;
  uint256 constant internal HEAD = 0;
  bool constant internal PREV = false;
  bool constant internal NEXT = true;

   
   
  uint256 public stakedNodesCount = 0;

   
  uint256 public minAuditStake = 10000 * (10 ** 18);

   
  mapping(address => bool) public lockedFunds;

   
   
  mapping(address => uint256) public unlockBlockNumber;

   
   
   
   
   
  LinkedListLib.LinkedList internal stakedNodesList;

  event Slashed(address addr, uint256 amount);
  event StakedNodeAdded(address addr);
  event StakedNodeRemoved(address addr);

   
  constructor(address tokenAddress) public TokenEscrow(ERC20(tokenAddress)) {}  

   
  function deposit(address _payee, uint256 _amount) public onlyWhitelisted {
    super.deposit(_payee, _amount);
    if (_amount > 0) {
       
      addNodeToStakedList(_payee);
    }
  }

  
  function withdraw(address _payee) public onlyWhitelisted {
    super.withdraw(_payee);
    removeNodeFromStakedList(_payee);
  }

   
  function setMinAuditStake(uint256 _value) public onlyOwner {
    require(_value > 0);
    minAuditStake = _value;
  }

   
  function hasEnoughStake(address addr) public view returns(bool) {
    return depositsOf(addr) >= minAuditStake;
  }

   
  function withdrawalAllowed(address _payee) public view returns (bool) {
    return !lockedFunds[_payee] || unlockBlockNumber[_payee] < block.number;
  }

   
  function lockFunds(address _payee, uint256 _unlockBlockNumber) public onlyWhitelisted returns (bool) {
    lockedFunds[_payee] = true;
    unlockBlockNumber[_payee] = _unlockBlockNumber;
    return true;
  }

     
  function slash(address addr, uint256 percentage) public onlyWhitelisted returns (uint256) {
    require(0 <= percentage && percentage <= 100);

    uint256 slashAmount = getSlashAmount(percentage);
    uint256 balance = depositsOf(addr);
    if (balance < slashAmount) {
      slashAmount = balance;
    }

     
    deposits[addr] = deposits[addr].sub(slashAmount);

    emit Slashed(addr, slashAmount);

     
    if (depositsOf(addr) == 0) {
      removeNodeFromStakedList(addr);
    }

     
    token.safeTransfer(msg.sender, slashAmount);

    return slashAmount;
  }

   
  function getSlashAmount(uint256 percentage) public view returns (uint256) {
    return (minAuditStake.mul(percentage)).div(100);
  }

   
  function getNextStakedNode(address addr) public view returns(address) {
    bool exists;
    uint256 next;
    (exists, next) = stakedNodesList.getAdjacent(uint256(addr), NEXT);
     
    while (exists && next != HEAD && !hasEnoughStake(address(next))) {
      (exists, next) = stakedNodesList.getAdjacent(next, NEXT);
    }
    return address(next);
  }

   
  function addNodeToStakedList(address addr) internal returns(bool success) {
    if (stakedNodesList.insert(HEAD, uint256(addr), PREV)) {
      stakedNodesCount++;
      emit StakedNodeAdded(addr);
      success = true;
    }
  }

   
  function removeNodeFromStakedList(address addr) internal returns(bool success) {
    if (stakedNodesList.remove(uint256(addr)) != 0) {
      stakedNodesCount--;
      emit StakedNodeRemoved(addr);
      success = true;
    }
  }
}

 

 
 
contract QuantstampAuditPolice is Whitelist {    

  using SafeMath for uint256;
  using LinkedListLib for LinkedListLib.LinkedList;

   
  uint256 constant internal NULL = 0;
  uint256 constant internal HEAD = 0;
  bool constant internal PREV = false;
  bool constant internal NEXT = true;

  enum PoliceReportState {
    UNVERIFIED,
    INVALID,
    VALID,
    EXPIRED
  }

   
  LinkedListLib.LinkedList internal policeList;

   
  uint256 public numPoliceNodes = 0;

   
  uint256 public policeNodesPerReport = 3;

   
  uint256 public policeTimeoutInBlocks = 100;

   
  uint256 public slashPercentage = 20;

     
  uint256 public reportProcessingFeePercentage = 5;

  event PoliceNodeAdded(address addr);
  event PoliceNodeRemoved(address addr);
   
  event PoliceNodeAssignedToReport(address policeNode, uint256 requestId);
  event PoliceSubmissionPeriodExceeded(uint256 requestId, uint256 timeoutBlock, uint256 currentBlock);
  event PoliceSlash(uint256 requestId, address policeNode, address auditNode, uint256 amount);
  event PoliceFeesClaimed(address policeNode, uint256 fee);
  event PoliceFeesCollected(uint256 requestId, uint256 fee);
  event PoliceAssignmentExpiredAndCleared(uint256 requestId);

   
  address private lastAssignedPoliceNode = address(HEAD);

   
  mapping(address => LinkedListLib.LinkedList) internal assignedReports;

   
  mapping(uint256 => LinkedListLib.LinkedList) internal assignedPolice;

   
  mapping(address => LinkedListLib.LinkedList) internal pendingPayments;

   
  mapping(uint256 => uint256) public policeTimeouts;

   
  mapping(uint256 => mapping(address => bytes)) public policeReports;

   
  mapping(uint256 => mapping(address => PoliceReportState)) public policeReportResults;

   
  mapping(uint256 => PoliceReportState) public verifiedReports;

   
  mapping(uint256 => bool) public rewardHasBeenClaimed;

   
  mapping(address => uint256) public totalReportsAssigned;

   
  mapping(address => uint256) public totalReportsChecked;

   
  mapping(uint256 => uint256) public collectedFees;

   
  QuantstampAuditData public auditData;

   
  QuantstampAuditTokenEscrow public tokenEscrow;

   
  constructor (address auditDataAddress, address escrowAddress) public {
    require(auditDataAddress != address(0));
    require(escrowAddress != address(0));
    auditData = QuantstampAuditData(auditDataAddress);
    tokenEscrow = QuantstampAuditTokenEscrow(escrowAddress);
  }

   
  function assignPoliceToReport(uint256 requestId) public onlyWhitelisted {
     
    require(policeTimeouts[requestId] == 0);
     
    policeTimeouts[requestId] = block.number + policeTimeoutInBlocks;
     
    uint256 numToAssign = policeNodesPerReport;
    if (numPoliceNodes < numToAssign) {
      numToAssign = numPoliceNodes;
    }
    while (numToAssign > 0) {
      lastAssignedPoliceNode = getNextPoliceNode(lastAssignedPoliceNode);
      if (lastAssignedPoliceNode != address(0)) {
         
        assignedReports[lastAssignedPoliceNode].push(requestId, PREV);
         
        assignedPolice[requestId].push(uint256(lastAssignedPoliceNode), PREV);
        emit PoliceNodeAssignedToReport(lastAssignedPoliceNode, requestId);
        totalReportsAssigned[lastAssignedPoliceNode] = totalReportsAssigned[lastAssignedPoliceNode].add(1);
        numToAssign = numToAssign.sub(1);
      }
    }
  }

   
  function clearExpiredAssignments (address policeNode, uint256 limit) public {
    removeExpiredAssignments(policeNode, 0, limit);
  }

   
  function collectFee(uint256 requestId) public onlyWhitelisted returns (uint256) {
    uint256 policeFee = getPoliceFee(auditData.getAuditPrice(requestId));
     
    collectedFees[requestId] = policeFee;
    emit PoliceFeesCollected(requestId, policeFee);
    return policeFee;
  }

   
  function splitPayment(uint256 amount) public onlyWhitelisted {
    require(numPoliceNodes != 0);
    address policeNode = getNextPoliceNode(address(HEAD));
    uint256 amountPerNode = amount.div(numPoliceNodes);
     
    uint256 largerAmount = amountPerNode.add(amount % numPoliceNodes);
    bool largerAmountClaimed = false;
    while (policeNode != address(HEAD)) {
       
       
       
       
      if (!largerAmountClaimed && (policeNode == lastAssignedPoliceNode || lastAssignedPoliceNode == address(HEAD))) {
        require(auditData.token().transfer(policeNode, largerAmount));
        emit PoliceFeesClaimed(policeNode, largerAmount);
        largerAmountClaimed = true;
      } else {
        require(auditData.token().transfer(policeNode, amountPerNode));
        emit PoliceFeesClaimed(policeNode, amountPerNode);
      }
      policeNode = getNextPoliceNode(address(policeNode));
    }
  }

   
  function addPendingPayment(address auditor, uint256 requestId) public onlyWhitelisted {
    pendingPayments[auditor].push(requestId, PREV);
  }

   
  function submitPoliceReport(
    address policeNode,
    address auditNode,
    uint256 requestId,
    bytes report,
    bool isVerified) public onlyWhitelisted returns (bool, bool, uint256) {
     
    bool hasRemovedCurrentId = removeExpiredAssignments(policeNode, requestId, 0);
     
    if (hasRemovedCurrentId) {
      emit PoliceSubmissionPeriodExceeded(requestId, policeTimeouts[requestId], block.number);
      return (false, false, 0);
    }
     
    require(isAssigned(requestId, policeNode));

     
    assignedReports[policeNode].remove(requestId);
     
    totalReportsChecked[policeNode] = totalReportsChecked[policeNode] + 1;
     
    policeReports[requestId][policeNode] = report;
     
    PoliceReportState state;
    if (isVerified) {
      state = PoliceReportState.VALID;
    } else {
      state = PoliceReportState.INVALID;
    }
    policeReportResults[requestId][policeNode] = state;

     
    if (verifiedReports[requestId] == PoliceReportState.INVALID) {
      return (true, false, 0);
    } else {
      verifiedReports[requestId] = state;
    }
    bool slashOccurred;
    uint256 slashAmount;
    if (!isVerified) {
      pendingPayments[auditNode].remove(requestId);
       
       
      slashAmount = tokenEscrow.slash(auditNode, slashPercentage);
      slashOccurred = true;
      emit PoliceSlash(requestId, policeNode, auditNode, slashAmount);
    }
    return (true, slashOccurred, slashAmount);
  }

   
  function canClaimAuditReward (address auditNode, uint256 requestId) public view returns (bool) {
     
    return
       
      pendingPayments[auditNode].nodeExists(requestId) &&
       
      policeTimeouts[requestId] < block.number &&
       
      verifiedReports[requestId] != PoliceReportState.INVALID &&
       
      !rewardHasBeenClaimed[requestId] &&
       
      requestId > 0;
  }

   
  function getNextAvailableReward (address auditNode, uint256 requestId) public view returns (bool, uint256) {
    bool exists;
    (exists, requestId) = pendingPayments[auditNode].getAdjacent(requestId, NEXT);
     
     
    while (exists && requestId != HEAD) {
      if (canClaimAuditReward(auditNode, requestId)) {
        return (true, requestId);
      }
      (exists, requestId) = pendingPayments[auditNode].getAdjacent(requestId, NEXT);
    }
    return (false, 0);
  }

   
  function setRewardClaimed (address auditNode, uint256 requestId) public onlyWhitelisted returns (bool) {
     
    rewardHasBeenClaimed[requestId] = true;
    pendingPayments[auditNode].remove(requestId);
     
    if (verifiedReports[requestId] == PoliceReportState.UNVERIFIED) {
      verifiedReports[requestId] = PoliceReportState.EXPIRED;
    }
    return true;
  }

   
  function claimNextReward (address auditNode, uint256 requestId) public onlyWhitelisted returns (bool, uint256) {
    bool exists;
    (exists, requestId) = pendingPayments[auditNode].getAdjacent(requestId, NEXT);
     
     
    while (exists && requestId != HEAD) {
      if (canClaimAuditReward(auditNode, requestId)) {
        setRewardClaimed(auditNode, requestId);
        return (true, requestId);
      }
      (exists, requestId) = pendingPayments[auditNode].getAdjacent(requestId, NEXT);
    }
    return (false, 0);
  }

   
  function getNextPoliceAssignment(address policeNode) public view returns (bool, uint256, uint256, string, uint256) {
    bool exists;
    uint256 requestId;
    (exists, requestId) = assignedReports[policeNode].getAdjacent(HEAD, NEXT);
     
    while (exists && requestId != HEAD) {
      if (policeTimeouts[requestId] < block.number) {
        (exists, requestId) = assignedReports[policeNode].getAdjacent(requestId, NEXT);
      } else {
        uint256 price = auditData.getAuditPrice(requestId);
        string memory uri = auditData.getAuditContractUri(requestId);
        uint256 policeAssignmentBlockNumber = auditData.getAuditReportBlockNumber(requestId);
        return (exists, requestId, price, uri, policeAssignmentBlockNumber);
      }
    }
    return (false, 0, 0, "", 0);
  }

   
  function getNextAssignedPolice(uint256 requestId, address policeNode) public view returns (bool, address) {
    bool exists;
    uint256 nextPoliceNode;
    (exists, nextPoliceNode) = assignedPolice[requestId].getAdjacent(uint256(policeNode), NEXT);
    if (nextPoliceNode == HEAD) {
      return (false, address(0));
    }
    return (exists, address(nextPoliceNode));
  }

   
  function setPoliceNodesPerReport(uint256 numPolice) public onlyOwner {
    policeNodesPerReport = numPolice;
  }

   
  function setPoliceTimeoutInBlocks(uint256 numBlocks) public onlyOwner {
    policeTimeoutInBlocks = numBlocks;
  }

   
  function setSlashPercentage(uint256 percentage) public onlyOwner {
    require(0 <= percentage && percentage <= 100);
    slashPercentage = percentage;
  }

   
  function setReportProcessingFeePercentage(uint256 percentage) public onlyOwner {
    require(percentage <= 100);
    reportProcessingFeePercentage = percentage;
  }

   
  function isPoliceNode(address node) public view returns (bool) {
    return policeList.nodeExists(uint256(node));
  }

   
  function addPoliceNode(address addr) public onlyOwner returns (bool success) {
    if (policeList.insert(HEAD, uint256(addr), PREV)) {
      numPoliceNodes = numPoliceNodes.add(1);
      emit PoliceNodeAdded(addr);
      success = true;
    }
  }

   
  function removePoliceNode(address addr) public onlyOwner returns (bool success) {
     
    bool exists;
    uint256 next;
    if (lastAssignedPoliceNode == addr) {
      (exists, next) = policeList.getAdjacent(uint256(addr), NEXT);
      lastAssignedPoliceNode = address(next);
    }

    if (policeList.remove(uint256(addr)) != NULL) {
      numPoliceNodes = numPoliceNodes.sub(1);
      emit PoliceNodeRemoved(addr);
      success = true;
    }
  }

   
  function getNextPoliceNode(address addr) public view returns (address) {
    bool exists;
    uint256 next;
    (exists, next) = policeList.getAdjacent(uint256(addr), NEXT);
    return address(next);
  }

   
  function getPoliceReportResult(uint256 requestId, address policeAddr) public view returns (PoliceReportState) {
    return policeReportResults[requestId][policeAddr];
  }

  function getPoliceReport(uint256 requestId, address policeAddr) public view returns (bytes) {
    return policeReports[requestId][policeAddr];
  }

  function getPoliceFee(uint256 auditPrice) public view returns (uint256) {
    return auditPrice.mul(reportProcessingFeePercentage).div(100);
  }

  function isAssigned(uint256 requestId, address policeAddr) public view returns (bool) {
    return assignedReports[policeAddr].nodeExists(requestId);
  }

   
  function removeExpiredAssignments (address policeNode, uint256 requestId, uint256 limit) internal returns (bool) {
    bool hasRemovedCurrentId = false;
    bool exists;
    uint256 potentialExpiredRequestId;
    uint256 nextExpiredRequestId;
    uint256 iterationsLeft = limit;
    (exists, nextExpiredRequestId) = assignedReports[policeNode].getAdjacent(HEAD, NEXT);
     
     
     
    while (exists && nextExpiredRequestId != HEAD && (limit == 0 || iterationsLeft > 0)) {
      potentialExpiredRequestId = nextExpiredRequestId;
      (exists, nextExpiredRequestId) = assignedReports[policeNode].getAdjacent(nextExpiredRequestId, NEXT);
      if (policeTimeouts[potentialExpiredRequestId] < block.number) {
        assignedReports[policeNode].remove(potentialExpiredRequestId);
        emit PoliceAssignmentExpiredAndCleared(potentialExpiredRequestId);
        if (potentialExpiredRequestId == requestId) {
          hasRemovedCurrentId = true;
        }
      } else {
        break;
      }
      iterationsLeft -= 1;
    }
    return hasRemovedCurrentId;
  }
}

 

contract QuantstampAuditReportData is Whitelist {

   
  mapping(uint256 => bytes) public reports;

  function setReport(uint256 requestId, bytes report) external onlyWhitelisted {
    reports[requestId] = report;
  }

  function getReport(uint256 requestId) external view returns(bytes) {
    return reports[requestId];
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

 

contract QuantstampAudit is Pausable {
  using SafeMath for uint256;
  using LinkedListLib for LinkedListLib.LinkedList;

   
  uint256 constant internal NULL = 0;
  uint256 constant internal HEAD = 0;
  bool constant internal PREV = false;
  bool constant internal NEXT = true;

   
  mapping(address => uint256) public assignedRequestCount;

   
  LinkedListLib.LinkedList internal priceList;
   
  mapping(uint256 => LinkedListLib.LinkedList) internal auditsByPrice;

   
  LinkedListLib.LinkedList internal assignedAudits;

   
  mapping(address => uint256) public mostRecentAssignedRequestIdsPerAuditor;

   
  QuantstampAuditData public auditData;

   
  QuantstampAuditReportData public reportData;

   
  QuantstampAuditPolice public police;

   
  QuantstampAuditTokenEscrow public tokenEscrow;

  event LogAuditFinished(
    uint256 requestId,
    address auditor,
    QuantstampAuditData.AuditState auditResult,
    bytes report
  );

  event LogPoliceAuditFinished(
    uint256 requestId,
    address policeNode,
    bytes report,
    bool isVerified
  );

  event LogAuditRequested(uint256 requestId,
    address requestor,
    string uri,
    uint256 price
  );

  event LogAuditAssigned(uint256 requestId,
    address auditor,
    address requestor,
    string uri,
    uint256 price,
    uint256 requestBlockNumber);

   
  event LogReportSubmissionError_InvalidAuditor(uint256 requestId, address auditor);
  event LogReportSubmissionError_InvalidState(uint256 requestId, address auditor, QuantstampAuditData.AuditState state);
  event LogReportSubmissionError_InvalidResult(uint256 requestId, address auditor, QuantstampAuditData.AuditState state);
  event LogReportSubmissionError_ExpiredAudit(uint256 requestId, address auditor, uint256 allowanceBlockNumber);
  event LogAuditAssignmentError_ExceededMaxAssignedRequests(address auditor);
  event LogAuditAssignmentError_Understaked(address auditor, uint256 stake);
  event LogAuditAssignmentUpdate_Expired(uint256 requestId, uint256 allowanceBlockNumber);
  event LogClaimRewardsReachedGasLimit(address auditor);

   

  event LogAuditQueueIsEmpty();

  event LogPayAuditor(uint256 requestId, address auditor, uint256 amount);
  event LogAuditNodePriceChanged(address auditor, uint256 amount);

  event LogRefund(uint256 requestId, address requestor, uint256 amount);
  event LogRefundInvalidRequestor(uint256 requestId, address requestor);
  event LogRefundInvalidState(uint256 requestId, QuantstampAuditData.AuditState state);
  event LogRefundInvalidFundsLocked(uint256 requestId, uint256 currentBlock, uint256 fundLockEndBlock);

   
   
  event LogAuditNodePriceHigherThanRequests(address auditor, uint256 amount);

  enum AuditAvailabilityState {
    Error,
    Ready,       
    Empty,       
    Exceeded,    
    Underpriced,  
    Understaked  
  }

   
  constructor (address auditDataAddress, address reportDataAddress, address escrowAddress, address policeAddress) public {
    require(auditDataAddress != address(0));
    require(reportDataAddress != address(0));
    require(escrowAddress != address(0));
    require(policeAddress != address(0));
    auditData = QuantstampAuditData(auditDataAddress);
    reportData = QuantstampAuditReportData(reportDataAddress);
    tokenEscrow = QuantstampAuditTokenEscrow(escrowAddress);
    police = QuantstampAuditPolice(policeAddress);
  }

   
  function stake(uint256 amount) external returns(bool) {
     
    require(auditData.token().transferFrom(msg.sender, address(this), amount));
     
    auditData.token().approve(address(tokenEscrow), amount);
     
    tokenEscrow.deposit(msg.sender, amount);
    return true;
  }

   
  function unstake() external returns(bool) {
     
    tokenEscrow.withdraw(msg.sender);
    return true;
  }

   
  function refund(uint256 requestId) external returns(bool) {
    QuantstampAuditData.AuditState state = auditData.getAuditState(requestId);
     
    if (state != QuantstampAuditData.AuditState.Queued &&
          state != QuantstampAuditData.AuditState.Assigned &&
            state != QuantstampAuditData.AuditState.Expired) {
      emit LogRefundInvalidState(requestId, state);
      return false;
    }
    address requestor = auditData.getAuditRequestor(requestId);
    if (requestor != msg.sender) {
      emit LogRefundInvalidRequestor(requestId, msg.sender);
      return;
    }
    uint256 refundBlockNumber = auditData.getAuditAssignBlockNumber(requestId).add(auditData.auditTimeoutInBlocks());
     
    if (state == QuantstampAuditData.AuditState.Assigned) {
      if (block.number <= refundBlockNumber) {
        emit LogRefundInvalidFundsLocked(requestId, block.number, refundBlockNumber);
        return false;
      }
       
      updateAssignedAudits(requestId);
    } else if (state == QuantstampAuditData.AuditState.Queued) {
       
       
      removeQueueElement(requestId);
    }

     
    auditData.setAuditState(requestId, QuantstampAuditData.AuditState.Refunded);

     
    uint256 price = auditData.getAuditPrice(requestId);
    emit LogRefund(requestId, requestor, price);
    safeTransferFromDataContract(requestor, price);
    return true;
  }

   
  function requestAudit(string contractUri, uint256 price) public returns(uint256) {
     
    return requestAuditWithPriceHint(contractUri, price, HEAD);
  }

   
  function requestAuditWithPriceHint(string contractUri, uint256 price, uint256 existingPrice) public whenNotPaused returns(uint256) {
    require(price > 0);
     
    require(auditData.token().transferFrom(msg.sender, address(auditData), price));
     
    uint256 requestId = auditData.addAuditRequest(msg.sender, contractUri, price);

    queueAuditRequest(requestId, existingPrice);

    emit LogAuditRequested(requestId, msg.sender, contractUri, price);  

    return requestId;
  }

   
  function submitReport(uint256 requestId, QuantstampAuditData.AuditState auditResult, bytes report) public {  
    if (QuantstampAuditData.AuditState.Completed != auditResult && QuantstampAuditData.AuditState.Error != auditResult) {
      emit LogReportSubmissionError_InvalidResult(requestId, msg.sender, auditResult);
      return;
    }

    QuantstampAuditData.AuditState auditState = auditData.getAuditState(requestId);
    if (auditState != QuantstampAuditData.AuditState.Assigned) {
      emit LogReportSubmissionError_InvalidState(requestId, msg.sender, auditState);
      return;
    }

     
    if (msg.sender != auditData.getAuditAuditor(requestId)) {
      emit LogReportSubmissionError_InvalidAuditor(requestId, msg.sender);
      return;
    }

     
    updateAssignedAudits(requestId);

     
    uint256 allowanceBlockNumber = auditData.getAuditAssignBlockNumber(requestId) + auditData.auditTimeoutInBlocks();
    if (allowanceBlockNumber < block.number) {
       
      auditData.setAuditState(requestId, QuantstampAuditData.AuditState.Expired);
      emit LogReportSubmissionError_ExpiredAudit(requestId, msg.sender, allowanceBlockNumber);
      return;
    }

     
    auditData.setAuditState(requestId, auditResult);
    auditData.setAuditReportBlockNumber(requestId, block.number);  

     
    require(isAuditFinished(requestId));

     
    reportData.setReport(requestId, report);

    emit LogAuditFinished(requestId, msg.sender, auditResult, report);

     
    police.assignPoliceToReport(requestId);
     
    police.addPendingPayment(msg.sender, requestId);
     
    if (police.reportProcessingFeePercentage() > 0 && police.numPoliceNodes() > 0) {
      uint256 policeFee = police.collectFee(requestId);
      safeTransferFromDataContract(address(police), policeFee);
      police.splitPayment(policeFee);
    }
  }

   
  function getReport(uint256 requestId) public view returns (bytes) {
    return reportData.getReport(requestId);
  }

   
  function isPoliceNode(address node) public view returns(bool) {
    return police.isPoliceNode(node);
  }

   
  function submitPoliceReport(
    uint256 requestId,
    bytes report,
    bool isVerified) public returns (bool) {
    require(police.isPoliceNode(msg.sender));
     
    address auditNode = auditData.getAuditAuditor(requestId);
    bool hasBeenSubmitted;
    bool slashOccurred;
    uint256 slashAmount;
     
    (hasBeenSubmitted, slashOccurred, slashAmount) = police.submitPoliceReport(msg.sender, auditNode, requestId, report, isVerified);
    if (hasBeenSubmitted) {
      emit LogPoliceAuditFinished(requestId, msg.sender, report, isVerified);
    }
    if (slashOccurred) {
       
      uint256 auditPoliceFee = police.collectedFees(requestId);
      uint256 adjustedPrice = auditData.getAuditPrice(requestId).sub(auditPoliceFee);
      safeTransferFromDataContract(address(police), adjustedPrice);

       
      police.splitPayment(adjustedPrice.add(slashAmount));
    }
    return hasBeenSubmitted;
  }

   
  function hasAvailableRewards () public view returns (bool) {
    bool exists;
    uint256 next;
    (exists, next) = police.getNextAvailableReward(msg.sender, HEAD);
    return exists;
  }

   
  function getNextAvailableReward (uint256 requestId) public view returns(bool, uint256) {
    return police.getNextAvailableReward(msg.sender, requestId);
  }

   
  function claimReward (uint256 requestId) public returns (bool) {
    require(police.canClaimAuditReward(msg.sender, requestId));
    police.setRewardClaimed(msg.sender, requestId);
    transferReward(requestId);
    return true;
  }

   
  function claimRewards () public returns (bool) {
     
    require(hasAvailableRewards());
    bool exists;
    uint256 requestId = HEAD;
    uint256 remainingGasBeforeCall;
    uint256 remainingGasAfterCall;
    bool loopExitedDueToGasLimit;
     
     
    while (true) {
      remainingGasBeforeCall = gasleft();
      (exists, requestId) = police.claimNextReward(msg.sender, HEAD);
      if (!exists) {
        break;
      }
      transferReward(requestId);
      remainingGasAfterCall = gasleft();
       
      if (remainingGasAfterCall < remainingGasBeforeCall.sub(remainingGasAfterCall).mul(2)) {
        loopExitedDueToGasLimit = true;
        emit LogClaimRewardsReachedGasLimit(msg.sender);
        break;
      }
    }
    return loopExitedDueToGasLimit;
  }

   
  function totalStakedFor(address addr) public view returns(uint256) {
    return tokenEscrow.depositsOf(addr);
  }

   
  function hasEnoughStake(address addr) public view returns(bool) {
    return tokenEscrow.hasEnoughStake(addr);
  }

   
  function getMinAuditStake() public view returns(uint256) {
    return tokenEscrow.minAuditStake();
  }

   
  function getAuditTimeoutInBlocks() public view returns(uint256) {
    return auditData.auditTimeoutInBlocks();
  }

   
  function getMinAuditPrice (address auditor) public view returns(uint256) {
    return auditData.getMinAuditPrice(auditor);
  }

   
  function getMaxAssignedRequests() public view returns(uint256) {
    return auditData.maxAssignedRequests();
  }

   
  function anyRequestAvailable() public view returns(AuditAvailabilityState) {
    uint256 requestId;

     
    if (!hasEnoughStake(msg.sender)) {
      return AuditAvailabilityState.Understaked;
    }

     
    if (!auditQueueExists()) {
      return AuditAvailabilityState.Empty;
    }

     
    if (assignedRequestCount[msg.sender] >= auditData.maxAssignedRequests()) {
      return AuditAvailabilityState.Exceeded;
    }

    requestId = anyAuditRequestMatchesPrice(auditData.getMinAuditPrice(msg.sender));
    if (requestId == 0) {
      return AuditAvailabilityState.Underpriced;
    }
    return AuditAvailabilityState.Ready;
  }

   
  function getNextPoliceAssignment() public view returns (bool, uint256, uint256, string, uint256) {
    return police.getNextPoliceAssignment(msg.sender);
  }

   
   
  function getNextAuditRequest() public {
     
    if (assignedAudits.listExists()) {
      bool exists;
      uint256 potentialExpiredRequestId;
      (exists, potentialExpiredRequestId) = assignedAudits.getAdjacent(HEAD, NEXT);
      uint256 allowanceBlockNumber = auditData.getAuditAssignBlockNumber(potentialExpiredRequestId) + auditData.auditTimeoutInBlocks();
      if (allowanceBlockNumber < block.number) {
        updateAssignedAudits(potentialExpiredRequestId);
        auditData.setAuditState(potentialExpiredRequestId, QuantstampAuditData.AuditState.Expired);
        emit LogAuditAssignmentUpdate_Expired(potentialExpiredRequestId, allowanceBlockNumber);
      }
    }

    AuditAvailabilityState isRequestAvailable = anyRequestAvailable();
     
    if (isRequestAvailable == AuditAvailabilityState.Empty) {
      emit LogAuditQueueIsEmpty();
      return;
    }

     
    if (isRequestAvailable == AuditAvailabilityState.Exceeded) {
      emit LogAuditAssignmentError_ExceededMaxAssignedRequests(msg.sender);
      return;
    }

    uint256 minPrice = auditData.getMinAuditPrice(msg.sender);

     
    if (isRequestAvailable == AuditAvailabilityState.Understaked) {
      emit LogAuditAssignmentError_Understaked(msg.sender, totalStakedFor(msg.sender));
      return;
    }

     
    uint256 requestId = dequeueAuditRequest(minPrice);
    if (requestId == 0) {
      emit LogAuditNodePriceHigherThanRequests(msg.sender, minPrice);
      return;
    }

    auditData.setAuditState(requestId, QuantstampAuditData.AuditState.Assigned);
    auditData.setAuditAuditor(requestId, msg.sender);
    auditData.setAuditAssignBlockNumber(requestId, block.number);
    assignedRequestCount[msg.sender]++;
     
    assignedAudits.push(requestId, PREV);

     
    tokenEscrow.lockFunds(msg.sender, block.number.add(auditData.auditTimeoutInBlocks()).add(police.policeTimeoutInBlocks()));

    mostRecentAssignedRequestIdsPerAuditor[msg.sender] = requestId;
    emit LogAuditAssigned(requestId,
      auditData.getAuditAuditor(requestId),
      auditData.getAuditRequestor(requestId),
      auditData.getAuditContractUri(requestId),
      auditData.getAuditPrice(requestId),
      auditData.getAuditRequestBlockNumber(requestId));
  }
   

   
  function setAuditNodePrice(uint256 price) public {
    require(price <= auditData.token().totalSupply());
    auditData.setMinAuditPrice(msg.sender, price);
    emit LogAuditNodePriceChanged(msg.sender, price);
  }

   
  function isAuditFinished(uint256 requestId) public view returns(bool) {
    QuantstampAuditData.AuditState state = auditData.getAuditState(requestId);
    return state == QuantstampAuditData.AuditState.Completed || state == QuantstampAuditData.AuditState.Error;
  }

   
  function getNextPrice(uint256 price) public view returns(uint256) {
    bool exists;
    uint256 next;
    (exists, next) = priceList.getAdjacent(price, NEXT);
    return next;
  }

   
  function getNextAssignedRequest(uint256 requestId) public view returns(uint256) {
    bool exists;
    uint256 next;
    (exists, next) = assignedAudits.getAdjacent(requestId, NEXT);
    return next;
  }

   
  function myMostRecentAssignedAudit() public view returns(
    uint256,  
    address,  
    string,   
    uint256,  
    uint256   
  ) {
    uint256 requestId = mostRecentAssignedRequestIdsPerAuditor[msg.sender];
    return (
      requestId,
      auditData.getAuditRequestor(requestId),
      auditData.getAuditContractUri(requestId),
      auditData.getAuditPrice(requestId),
      auditData.getAuditRequestBlockNumber(requestId)
    );
  }

   
  function getNextAuditByPrice(uint256 price, uint256 requestId) public view returns(uint256) {
    bool exists;
    uint256 next;
    (exists, next) = auditsByPrice[price].getAdjacent(requestId, NEXT);
    return next;
  }

   
  function findPrecedingPrice(uint256 price) public view returns(uint256) {
    return priceList.getSortedSpot(HEAD, price, NEXT);
  }

   
  function updateAssignedAudits(uint256 requestId) internal {
    assignedAudits.remove(requestId);
    assignedRequestCount[auditData.getAuditAuditor(requestId)] =
      assignedRequestCount[auditData.getAuditAuditor(requestId)].sub(1);
  }

   
  function auditQueueExists() internal view returns(bool) {
    return priceList.listExists();
  }

   
  function queueAuditRequest(uint256 requestId, uint256 existingPrice) internal {
    uint256 price = auditData.getAuditPrice(requestId);
    if (!priceList.nodeExists(price)) {
      uint256 priceHint = priceList.nodeExists(existingPrice) ? existingPrice : HEAD;
       
      priceList.insert(priceList.getSortedSpot(priceHint, price, NEXT), price, PREV);
    }
     
    auditsByPrice[price].push(requestId, PREV);
  }

   
  function anyAuditRequestMatchesPrice(uint256 minPrice) internal view returns(uint256) {
    bool priceExists;
    uint256 price;
    uint256 requestId;

     
    (priceExists, price) = priceList.getAdjacent(HEAD, PREV);
    if (price < minPrice) {
      return 0;
    }
    requestId = getNextAuditByPrice(price, HEAD);
    return requestId;
  }

   
  function dequeueAuditRequest(uint256 minPrice) internal returns(uint256) {

    uint256 requestId;
    uint256 price;

     
     
     
     
    requestId = anyAuditRequestMatchesPrice(minPrice);

    if (requestId > 0) {
      price = auditData.getAuditPrice(requestId);
      auditsByPrice[price].remove(requestId);
       
      if (!auditsByPrice[price].listExists()) {
        priceList.remove(price);
      }
      return requestId;
    }
    return 0;
  }

   
  function removeQueueElement(uint256 requestId) internal {
    uint256 price = auditData.getAuditPrice(requestId);

     
    require(priceList.nodeExists(price));
    require(auditsByPrice[price].nodeExists(requestId));

    auditsByPrice[price].remove(requestId);
    if (!auditsByPrice[price].listExists()) {
      priceList.remove(price);
    }
  }

   
  function transferReward (uint256 requestId) internal {
    uint256 auditPoliceFee = police.collectedFees(requestId);
    uint256 auditorPayment = auditData.getAuditPrice(requestId).sub(auditPoliceFee);
    safeTransferFromDataContract(msg.sender, auditorPayment);
    emit LogPayAuditor(requestId, msg.sender, auditorPayment);
  }

   
  function safeTransferFromDataContract(address _to, uint256 amount) internal {
    auditData.approveWhitelisted(amount);
    require(auditData.token().transferFrom(address(auditData), _to, amount));
  }
}