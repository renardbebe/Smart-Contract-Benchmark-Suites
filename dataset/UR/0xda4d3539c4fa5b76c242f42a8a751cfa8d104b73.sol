 

pragma solidity 0.4.25;

 
library AddressUtils {

   
  function isContract(address addr) internal view returns(bool) {
    uint256 size;
    assembly {
      size: = extcodesize(addr)
    }
    return size > 0;
  }

}



 
library SafeCompare {
  function stringCompare(string str1, string str2) internal pure returns(bool) {
    return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
  }
}




library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns(uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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

 
contract UsdtERC20Basic {
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}



 
contract ERC20Basic {
  function totalSupply() public view returns(uint256);

  function balanceOf(address who) public view returns(uint256);

  function transfer(address to, uint256 value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
  internal {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
  internal {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
  internal
  view {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
  internal
  view
  returns(bool) {
    return _role.bearer[_addr];
  }
}





 
contract RBAC {
  using Roles
  for Roles.Role;

  mapping(string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
  public
  view {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
  public
  view
  returns(bool) {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
  internal {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
  internal {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role) {
    checkRole(msg.sender, _role);
    _;
  }

}








contract RBACOperator is Ownable, RBAC {

   
  string public constant ROLE_OPERATOR = "operator";

  address public partner;
   
  event SetPartner(address oldPartner, address newPartner);

   
  modifier onlyOwnerOrPartner() {
    require(msg.sender == owner || msg.sender == partner);
    _;
  }

   
  modifier onlyPartner() {
    require(msg.sender == partner);
    _;
  }


   
  function setPartner(address _partner) public onlyOwner {
    require(_partner != address(0));
    emit SetPartner(partner, _partner);
    partner = _partner;
  }


   
  function removePartner() public onlyOwner {
    delete partner;
  }

   
  modifier hasOperationPermission() {
    checkRole(msg.sender, ROLE_OPERATOR);
    _;
  }



   
  function addOperater(address _operator) public onlyOwnerOrPartner {
    addRole(_operator, ROLE_OPERATOR);
  }

   
  function removeOperater(address _operator) public onlyOwnerOrPartner {
    removeRole(_operator, ROLE_OPERATOR);
  }
}









 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns(uint256);

  function transferFrom(address from, address to, uint256 value) public returns(bool);

  function approve(address spender, uint256 value) public returns(bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract UsdtERC20 is UsdtERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}





contract PartnerAuthority is Ownable {


  address public partner;
   
  event SetPartner(address oldPartner, address newPartner);

   
  modifier onlyOwnerOrPartner() {
    require(msg.sender == owner || msg.sender == partner);
    _;
  }

   
  modifier onlyPartner() {
    require(msg.sender == partner);
    _;
  }


   
  function setPartner(address _partner) public onlyOwner {
    require(_partner != address(0));
    emit SetPartner(partner, _partner);
    partner = _partner;
  }



   
  function removePartner() public onlyOwner {
    delete partner;
  }


}









 
contract OrderManageContract is PartnerAuthority {
  using SafeMath for uint256;
  using SafeCompare for string;

   
  enum StatusChoices {
    NO_LOAN,
    REPAYMENT_WAITING,
    REPAYMENT_ALL,
    CLOSE_POSITION,
    OVERDUE_STOP
  }

  string internal constant TOKEN_ETH = "ETH";
  string internal constant TOKEN_USDT = "USDT";
  address public maker;
  address public taker;
  address internal token20;

  uint256 public toTime;
   
  uint256 public outLoanSum;
  uint256 public repaymentSum;
  uint256 public lastRepaymentSum;
  string public loanTokenName;
   
  StatusChoices internal status;

   
  mapping(address => uint256) public ethAmount;

   
  event TakerOrder(address indexed taker, uint256 outLoanSum);


   
  event ExecuteOrder(address indexed maker, uint256 lastRepaymentSum);

   
  event ForceCloseOrder(uint256 indexed toTime, uint256 transferSum);

   
  event WithdrawToken(address indexed taker, uint256 refundSum);



  function() external payable {
     
    ethAmount[msg.sender] = ethAmount[msg.sender].add(msg.value);
  }


   
  constructor(string _loanTokenName, address _loanTokenAddress, address _maker) public {
    require(bytes(_loanTokenName).length > 0 && _maker != address(0));
    if (!_loanTokenName.stringCompare(TOKEN_ETH)) {
      require(_loanTokenAddress != address(0));
      token20 = _loanTokenAddress;
    }
    toTime = now;
    maker = _maker;
    loanTokenName = _loanTokenName;
    status = StatusChoices.NO_LOAN;
  }

   
  function takerOrder(address _taker, uint32 _toTime, uint256 _repaymentSum) public onlyOwnerOrPartner {
    require(_taker != address(0) && _toTime > 0 && now <= _toTime && _repaymentSum > 0 && status == StatusChoices.NO_LOAN);
    taker = _taker;
    toTime = _toTime;
    repaymentSum = _repaymentSum;

     
    if (loanTokenName.stringCompare(TOKEN_ETH)) {
      require(ethAmount[_taker] > 0 && address(this).balance > 0);
      outLoanSum = address(this).balance;
      maker.transfer(outLoanSum);
    } else {
      require(token20 != address(0) && ERC20(token20).balanceOf(address(this)) > 0);
      outLoanSum = ERC20(token20).balanceOf(address(this));
      require(safeErc20Transfer(maker, outLoanSum));
    }

     
    status = StatusChoices.REPAYMENT_WAITING;

    emit TakerOrder(taker, outLoanSum);
  }






   
  function executeOrder() public onlyOwnerOrPartner {
    require(now <= toTime && status == StatusChoices.REPAYMENT_WAITING);
     
    if (loanTokenName.stringCompare(TOKEN_ETH)) {
      require(ethAmount[maker] >= repaymentSum && address(this).balance >= repaymentSum);
      lastRepaymentSum = address(this).balance;
      taker.transfer(repaymentSum);
    } else {
      require(ERC20(token20).balanceOf(address(this)) >= repaymentSum);
      lastRepaymentSum = ERC20(token20).balanceOf(address(this));
      require(safeErc20Transfer(taker, repaymentSum));
    }

    PledgeContract(owner)._conclude();
    status = StatusChoices.REPAYMENT_ALL;
    emit ExecuteOrder(maker, lastRepaymentSum);
  }



   
  function forceCloseOrder() public onlyOwnerOrPartner {
    require(status == StatusChoices.REPAYMENT_WAITING);
    uint256 transferSum = 0;

    if (now <= toTime) {
      status = StatusChoices.CLOSE_POSITION;
    } else {
      status = StatusChoices.OVERDUE_STOP;
    }

    if(loanTokenName.stringCompare(TOKEN_ETH)){
        if(ethAmount[maker] > 0 && address(this).balance > 0){
            transferSum = address(this).balance;
            maker.transfer(transferSum);
        }
    }else{
        if(ERC20(token20).balanceOf(address(this)) > 0){
            transferSum = ERC20(token20).balanceOf(address(this));
            require(safeErc20Transfer(maker, transferSum));
        }
    }

     
    PledgeContract(owner)._forceConclude(taker);
    emit ForceCloseOrder(toTime, transferSum);
  }



   
  function withdrawToken(address _taker, uint256 _refundSum) public onlyOwnerOrPartner {
    require(status == StatusChoices.NO_LOAN);
    require(_taker != address(0) && _refundSum > 0);
    if (loanTokenName.stringCompare(TOKEN_ETH)) {
      require(address(this).balance >= _refundSum && ethAmount[_taker] >= _refundSum);
      _taker.transfer(_refundSum);
      ethAmount[_taker] = ethAmount[_taker].sub(_refundSum);
    } else {
      require(ERC20(token20).balanceOf(address(this)) >= _refundSum);
      require(safeErc20Transfer(_taker, _refundSum));
    }
    emit WithdrawToken(_taker, _refundSum);
  }


   
  function safeErc20Transfer(address _toAddress,uint256 _transferSum) internal returns (bool) {
    if(loanTokenName.stringCompare(TOKEN_USDT)){
      UsdtERC20(token20).transfer(_toAddress, _transferSum);
    }else{
      require(ERC20(token20).transfer(_toAddress, _transferSum));
    }
    return true;
  }



   
  function getPledgeStatus() public view returns(string pledgeStatus) {
    if (status == StatusChoices.NO_LOAN) {
      pledgeStatus = "NO_LOAN";
    } else if (status == StatusChoices.REPAYMENT_WAITING) {
      pledgeStatus = "REPAYMENT_WAITING";
    } else if (status == StatusChoices.REPAYMENT_ALL) {
      pledgeStatus = "REPAYMENT_ALL";
    } else if (status == StatusChoices.CLOSE_POSITION) {
      pledgeStatus = "CLOSE_POSITION";
    } else {
      pledgeStatus = "OVERDUE_STOP";
    }
  }

}








 
contract PledgeFactory is RBACOperator {
  using AddressUtils for address;

   
  string internal constant INIT_TOKEN_NAME = "UNKNOWN";

  mapping(uint256 => EscrowPledge) internal pledgeEscrowById;
   
  mapping(uint256 => bool) internal isPledgeId;

   
  struct EscrowPledge {
    address pledgeContract;
    string tokenName;
  }

   
  event CreatePledgeContract(uint256 indexed pledgeId, address newPledgeAddress);


   
  function createPledgeContract(uint256 _pledgeId, address _escrowPartner) public onlyPartner returns(bool) {
    require(_pledgeId > 0 && !isPledgeId[_pledgeId] && _escrowPartner!=address(0));

     
    PledgeContract pledgeAddress = new PledgeContract(_pledgeId, address(this),partner);
    pledgeAddress.transferOwnership(_escrowPartner);
    addOperater(address(pledgeAddress));

     
    isPledgeId[_pledgeId] = true;
    pledgeEscrowById[_pledgeId] = EscrowPledge(pledgeAddress, INIT_TOKEN_NAME);

    emit CreatePledgeContract(_pledgeId, address(pledgeAddress));
    return true;
  }



   
  function batchCreatePledgeContract(uint256[] _pledgeIds, address _escrowPartner) public onlyPartner {
    require(_pledgeIds.length > 0 && _escrowPartner.isContract());
    for (uint i = 0; i < _pledgeIds.length; i++) {
      require(createPledgeContract(_pledgeIds[i],_escrowPartner));
    }
  }

   
  function getEscrowPledge(uint256 _pledgeId) public view returns(string tokenName, address pledgeContract) {
    require(_pledgeId > 0);
    tokenName = pledgeEscrowById[_pledgeId].tokenName;
    pledgeContract = pledgeEscrowById[_pledgeId].pledgeContract;
  }




   
   
   


   
  function tokenPoolOperater(address _tokenPool, address _pledge) public hasOperationPermission {
    require(_pledge != address(0) && address(msg.sender).isContract() && address(msg.sender) == _pledge);
    PledgePoolBase(_tokenPool).addOperater(_pledge);
  }


   
  function updatePledgeType(uint256 _pledgeId, string _tokenName) public hasOperationPermission {
    require(_pledgeId > 0 && bytes(_tokenName).length > 0 && address(msg.sender).isContract());
    pledgeEscrowById[_pledgeId].tokenName = _tokenName;
  }


}




 
contract EscrowMaintainContract is PartnerAuthority {
  address public pledgeFactory;

   
  mapping(string => address) internal nameByPool;
   
  mapping(string => address) internal nameByToken;



   
   
   

   
  function createPledgeContract(uint256 _pledgeId) public onlyPartner returns(bool) {
    require(_pledgeId > 0 && pledgeFactory!=address(0));
    require(PledgeFactory(pledgeFactory).createPledgeContract(_pledgeId,partner));
    return true;
  }


   
  function batchCreatePledgeContract(uint256[] _pledgeIds) public onlyPartner {
    require(_pledgeIds.length > 0);
    PledgeFactory(pledgeFactory).batchCreatePledgeContract(_pledgeIds,partner);
  }


   
  function getEscrowPledge(uint256 _pledgeId) public view returns(string tokenName, address pledgeContract) {
    require(_pledgeId > 0);
    (tokenName,pledgeContract) = PledgeFactory(pledgeFactory).getEscrowPledge(_pledgeId);
  }


   
  function setTokenPool(string _tokenName, address _address) public onlyOwner {
    require(_address != address(0) && bytes(_tokenName).length > 0);
    nameByPool[_tokenName] = _address;
  }

    
  function setToken(string _tokenName, address _address) public onlyOwner {
    require(_address != address(0) && bytes(_tokenName).length > 0);
    nameByToken[_tokenName] = _address;
  }


   
  function setPledgeFactory(address _factory) public onlyOwner {
    require(_factory != address(0));
    pledgeFactory = _factory;
  }

   
  function includeTokenPool(string _tokenName) view public returns(address) {
    require(bytes(_tokenName).length > 0);
    return nameByPool[_tokenName];
  }


   
  function includeToken(string _tokenName) view public returns(address) {
    require(bytes(_tokenName).length > 0);
    return nameByToken[_tokenName];
  }

}


 
contract PledgeContract is PartnerAuthority {

  using SafeMath for uint256;
  using SafeCompare for string;

   
  enum StatusChoices {
    NO_PLEDGE_INFO,
    PLEDGE_CREATE_MATCHING,
    PLEDGE_REFUND
  }

  string public pledgeTokenName;
  uint256 public pledgeId;
  address internal maker;
  address internal token20;
  address internal factory;
  address internal escrowContract;
  uint256 internal pledgeAccountSum;
   
  address internal orderContract;
  string internal loanTokenName;
  StatusChoices internal status;
  address internal tokenPoolAddress;
  string internal constant TOKEN_ETH = "ETH";
  string internal constant TOKEN_USDT = "USDT";
   
  mapping(address => uint256) internal verifyEthAccount;


   
  event CreateOrderContract(address newOrderContract);


   
  event WithdrawToken(address indexed maker, string pledgeTokenName, uint256 refundSum);


   
  event AppendEscrow(address indexed maker, uint256 appendSum);


   
  constructor(uint256 _pledgeId, address _factory , address _escrowContract) public {
    require(_pledgeId > 0 && _factory != address(0) && _escrowContract != address(0));
    pledgeId = _pledgeId;
    factory = _factory;
    status = StatusChoices.NO_PLEDGE_INFO;
    escrowContract = _escrowContract;
  }



   
   
   



  function() external payable {
    require(status != StatusChoices.PLEDGE_REFUND);
     
    if (maker != address(0)) {
      require(address(msg.sender) == maker);
    }
     
    verifyEthAccount[msg.sender] = verifyEthAccount[msg.sender].add(msg.value);
  }


   
  function addRecord(string _pledgeTokenName, address _maker, uint256 _pledgeSum, string _loanTokenName) public onlyOwner {
    require(_maker != address(0) && _pledgeSum > 0 && status != StatusChoices.PLEDGE_REFUND);
     
    if (status == StatusChoices.NO_PLEDGE_INFO) {
       
      maker = _maker;
      pledgeTokenName = _pledgeTokenName;
      tokenPoolAddress = checkedTokenPool(pledgeTokenName);
      PledgeFactory(factory).updatePledgeType(pledgeId, pledgeTokenName);
       
      PledgeFactory(factory).tokenPoolOperater(tokenPoolAddress, address(this));
       
      createOrderContract(_loanTokenName);
    }
     
    pledgeAccountSum = pledgeAccountSum.add(_pledgeSum);
    PledgePoolBase(tokenPoolAddress).addRecord(maker, pledgeAccountSum, pledgeId, pledgeTokenName);
     
    if (pledgeTokenName.stringCompare(TOKEN_ETH)) {
      require(verifyEthAccount[maker] >= _pledgeSum);
      tokenPoolAddress.transfer(_pledgeSum);
    } else {
      token20 = checkedToken(pledgeTokenName);
      require(ERC20(token20).balanceOf(address(this)) >= _pledgeSum);
      require(safeErc20Transfer(token20,tokenPoolAddress, _pledgeSum));
    }
  }

   
  function appendEscrow(uint256 _appendSum) public onlyOwner {
    require(status == StatusChoices.PLEDGE_CREATE_MATCHING);
    addRecord(pledgeTokenName, maker, _appendSum, loanTokenName);
    emit AppendEscrow(maker, _appendSum);
  }


   
  function withdrawToken(address _maker) public onlyOwner {
    require(status != StatusChoices.PLEDGE_REFUND);
    uint256 pledgeSum = 0;
     
    if (status == StatusChoices.NO_PLEDGE_INFO) {
      pledgeSum = classifySquareUp(_maker);
    } else {
      status = StatusChoices.PLEDGE_REFUND;
      require(PledgePoolBase(tokenPoolAddress).withdrawToken(pledgeId, maker, pledgeAccountSum));
      pledgeSum = pledgeAccountSum;
    }
    emit WithdrawToken(_maker, pledgeTokenName, pledgeSum);
  }


   
  function recycle(string _tokenName, uint256 _amount) public onlyOwner {
    require(status != StatusChoices.NO_PLEDGE_INFO && _amount>0);
    if (_tokenName.stringCompare(TOKEN_ETH)) {
      require(address(this).balance >= _amount);
      owner.transfer(_amount);
    } else {
      address token = checkedToken(_tokenName);
      require(ERC20(token).balanceOf(address(this)) >= _amount);
      require(safeErc20Transfer(token,owner, _amount));
    }
  }



   
  function safeErc20Transfer(address _token20,address _toAddress,uint256 _transferSum) internal returns (bool) {
    if(loanTokenName.stringCompare(TOKEN_USDT)){
      UsdtERC20(_token20).transfer(_toAddress, _transferSum);
    }else{
      require(ERC20(_token20).transfer(_toAddress, _transferSum));
    }
    return true;
  }



   
   
   



   
  function createOrderContract(string _loanTokenName) internal {
    require(bytes(_loanTokenName).length > 0);
    status = StatusChoices.PLEDGE_CREATE_MATCHING;
    address loanToken20 = checkedToken(_loanTokenName);
    OrderManageContract newOrder = new OrderManageContract(_loanTokenName, loanToken20, maker);
    setPartner(address(newOrder));
    newOrder.setPartner(owner);
     
    orderContract = newOrder;
    loanTokenName = _loanTokenName;
    emit CreateOrderContract(address(newOrder));
  }

   
  function classifySquareUp(address _maker) internal returns(uint256 sum) {
    if (pledgeTokenName.stringCompare(TOKEN_ETH)) {
      uint256 pledgeSum = verifyEthAccount[_maker];
      require(pledgeSum > 0 && address(this).balance >= pledgeSum);
      _maker.transfer(pledgeSum);
      verifyEthAccount[_maker] = 0;
      sum = pledgeSum;
    } else {
      uint256 balance = ERC20(token20).balanceOf(address(this));
      require(balance > 0);
      require(safeErc20Transfer(token20,_maker, balance));
      sum = balance;
    }
  }

   
  function checkedToken(string _tokenName) internal view returns(address) {
    address tokenAddress = EscrowMaintainContract(escrowContract).includeToken(_tokenName);
    require(tokenAddress != address(0));
    return tokenAddress;
  }

   
  function checkedTokenPool(string _tokenName) internal view returns(address) {
    address tokenPool = EscrowMaintainContract(escrowContract).includeTokenPool(_tokenName);
    require(tokenPool != address(0));
    return tokenPool;
  }



   
   
   
   



   
  function _conclude() public onlyPartner {
    require(status == StatusChoices.PLEDGE_CREATE_MATCHING);
    status = StatusChoices.PLEDGE_REFUND;
    require(PledgePoolBase(tokenPoolAddress).refundTokens(pledgeId, pledgeAccountSum, maker));
  }

   
  function _forceConclude(address _taker) public onlyPartner {
    require(_taker != address(0) && status == StatusChoices.PLEDGE_CREATE_MATCHING);
    status = StatusChoices.PLEDGE_REFUND;
    require(PledgePoolBase(tokenPoolAddress).refundTokens(pledgeId, pledgeAccountSum, _taker));
  }



   
   
   



   
  function getPledgeStatus() public view returns(string pledgeStatus) {
    if (status == StatusChoices.NO_PLEDGE_INFO) {
      pledgeStatus = "NO_PLEDGE_INFO";
    } else if (status == StatusChoices.PLEDGE_CREATE_MATCHING) {
      pledgeStatus = "PLEDGE_CREATE_MATCHING";
    } else {
      pledgeStatus = "PLEDGE_REFUND";
    }
  }

   
  function getOrderContract() public view returns(address) {
    return orderContract;
  }

   
  function getPledgeAccountSum() public view returns(uint256) {
    return pledgeAccountSum;
  }

   
  function getMakerAddress() public view returns(address) {
    return maker;
  }

   
  function getPledgeId() external view returns(uint256) {
    return pledgeId;
  }

}



 
contract PledgePoolBase is RBACOperator {
  using SafeMath for uint256;
  using AddressUtils for address;

   
  mapping(uint256 => Escrow) internal escrows;

   
  struct Escrow {
    uint256 pledgeSum;
    address payerAddress;
    string tokenName;
  }

   
   
   

   
  function addRecord(address _payerAddress, uint256 _pledgeSum, uint256 _pledgeId, string _tokenName) public hasOperationPermission returns(bool) {
    _preValidateAddRecord(_payerAddress, _pledgeSum, _pledgeId, _tokenName);
    _processAddRecord(_payerAddress, _pledgeSum, _pledgeId, _tokenName);
    return true;
  }


    
  function withdrawToken(uint256 _pledgeId, address _maker, uint256 _num) public hasOperationPermission returns(bool) {
    _preValidateWithdraw(_maker, _num, _pledgeId);
    _processWithdraw(_maker, _num, _pledgeId);
    return true;
  }


   
  function refundTokens(uint256 _pledgeId, uint256 _returnSum, address _targetAddress) public hasOperationPermission returns(bool) {
    _preValidateRefund(_returnSum, _targetAddress, _pledgeId);
    _processRefund(_returnSum, _targetAddress, _pledgeId);
    return true;
  }

   
  function getLedger(uint256 _pledgeId) public view returns(uint256 num, address payerAddress, string tokenName) {
    require(_pledgeId > 0);
    num = escrows[_pledgeId].pledgeSum;
    payerAddress = escrows[_pledgeId].payerAddress;
    tokenName = escrows[_pledgeId].tokenName;
  }



   
   
   



   
  function _preValidateAddRecord(address _payerAddress, uint256 _pledgeSum, uint256 _pledgeId, string _tokenName) view internal {
    require(_pledgeSum > 0 && _pledgeId > 0
      && _payerAddress != address(0)
      && bytes(_tokenName).length > 0
      && address(msg.sender).isContract()
      && PledgeContract(msg.sender).getPledgeId()==_pledgeId
    );
  }

   
  function _processAddRecord(address _payerAddress, uint256 _pledgeSum, uint256 _pledgeId, string _tokenName) internal {
    Escrow memory escrow = Escrow(_pledgeSum, _payerAddress, _tokenName);
    escrows[_pledgeId] = escrow;
  }



   
  function _preValidateRefund(uint256 _returnSum, address _targetAddress, uint256 _pledgeId) view internal {
    require(_returnSum > 0 && _pledgeId > 0
      && _targetAddress != address(0)
      && address(msg.sender).isContract()
      && _returnSum <= escrows[_pledgeId].pledgeSum
      && PledgeContract(msg.sender).getPledgeId()==_pledgeId
    );
  }


   
  function _processRefund(uint256 _returnSum, address _targetAddress, uint256 _pledgeId) internal {
    escrows[_pledgeId].pledgeSum = escrows[_pledgeId].pledgeSum.sub(_returnSum);
  }



   
  function _preValidateWithdraw(address _maker, uint256 _num, uint256 _pledgeId) view internal {
    require(_num > 0 && _pledgeId > 0
       && _maker != address(0)
       && address(msg.sender).isContract()
       && _num <= escrows[_pledgeId].pledgeSum
       && PledgeContract(msg.sender).getPledgeId()==_pledgeId
    );
  }


   
  function _processWithdraw(address _maker, uint256 _num, uint256 _pledgeId) internal {
    escrows[_pledgeId].pledgeSum = escrows[_pledgeId].pledgeSum.sub(_num);
  }

}



 
contract EthPledgePool is PledgePoolBase {
  using SafeMath for uint256;
  using AddressUtils for address;
   
   
   

   
  function() external payable {}


   
  function recycle(uint256 _amount,address _contract) public onlyOwner returns(bool) {
    require(_amount <= address(this).balance && _contract.isContract());
    _contract.transfer(_amount);
    return true;
  }


   
  function kills() public onlyOwner {
    selfdestruct(owner);
  }


   
   
   


   
  function _processRefund(uint256 _returnSum, address _targetAddress, uint256 _pledgeId) internal {
    super._processRefund(_returnSum, _targetAddress, _pledgeId);
    require(address(this).balance >= _returnSum);
    _targetAddress.transfer(_returnSum);
  }

   
  function _processWithdraw(address _maker, uint256 _num, uint256 _pledgeId) internal {
    super._processWithdraw(_maker, _num, _pledgeId);
    require(address(this).balance >= _num);
    _maker.transfer(_num);
  }

}