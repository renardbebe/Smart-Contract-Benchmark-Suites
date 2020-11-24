 

pragma solidity ^0.5.0;

 
library SafeMath {

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

 
contract RequestUid {

     
    uint256 public requestCount;

     
    constructor() public {
        requestCount = 0;
    }
    
     
    function generateRequestUid() internal returns (bytes32 uid) {
        return keccak256(abi.encodePacked(blockhash(block.number - uint256(1)), address(this), ++requestCount));
    }
}

 
contract AdminUpgradeable is RequestUid {
    
     
    event AdminChangeRequested(bytes32 _uid, address _msgSender, address _newAdmin);
    
     
    event AdminChangeConfirmed(bytes32 _uid, address _newAdmin);
    
     
    struct AdminChangeRequest {
        address newAdminAddress;
    }
    
     
    address public admin;
    
     
    mapping (bytes32 => AdminChangeRequest) public adminChangeReqs;
    
     
    modifier adminOperations {
        require(msg.sender == admin, "admin can call this method only");
        _;
    }
    
     
    constructor (address _admin) public RequestUid() {
        admin = _admin;
    }
    
     
    function requestAdminChange(address _newAdmin) public returns (bytes32 uid) {
        require(_newAdmin != address(0), "admin is not 0 address");

        uid = generateRequestUid();

        adminChangeReqs[uid] = AdminChangeRequest({
            newAdminAddress: _newAdmin
            });

        emit AdminChangeRequested(uid, msg.sender, _newAdmin);
    }
    
     
    function confirmAdminChange(bytes32 _uid) public adminOperations {
        admin = getAdminChangeReq(_uid);

        delete adminChangeReqs[_uid];

        emit AdminChangeConfirmed(_uid, admin);
    }
    
     
    function getAdminChangeReq(bytes32 _uid) private view returns (address _newAdminAddress) {
        AdminChangeRequest storage changeRequest = adminChangeReqs[_uid];

        require(changeRequest.newAdminAddress != address(0));

        return changeRequest.newAdminAddress;
    }
}

 
contract BICALogicUpgradeable is AdminUpgradeable  {

     
    event LogicChangeRequested(bytes32 _uid, address _msgSender, address _newLogic);

     
    event LogicChangeConfirmed(bytes32 _uid, address _newLogic);

     
    struct LogicChangeRequest {
        address newLogicAddress;
    }

     
    BICALogic public bicaLogic;

     
    mapping (bytes32 => LogicChangeRequest) public logicChangeReqs;

     
    modifier onlyLogic {
        require(msg.sender == address(bicaLogic), "only logic contract is authorized");
        _;
    }

     
    constructor (address _admin) public AdminUpgradeable(_admin) {
        bicaLogic = BICALogic(0x0);
    }

     
    function requestLogicChange(address _newLogic) public returns (bytes32 uid) {
        require(_newLogic != address(0), "new logic address can not be 0");

        uid = generateRequestUid();

        logicChangeReqs[uid] = LogicChangeRequest({
            newLogicAddress: _newLogic
            });

        emit LogicChangeRequested(uid, msg.sender, _newLogic);
    }

     
    function confirmLogicChange(bytes32 _uid) public adminOperations {
        bicaLogic = getLogicChangeReq(_uid);

        delete logicChangeReqs[_uid];

        emit LogicChangeConfirmed(_uid, address(bicaLogic));
    }

     
    function getLogicChangeReq(bytes32 _uid) private view returns (BICALogic _newLogicAddress) {
        LogicChangeRequest storage changeRequest = logicChangeReqs[_uid];

        require(changeRequest.newLogicAddress != address(0));

        return BICALogic(changeRequest.newLogicAddress);
    }
}

 
contract BICALogic is AdminUpgradeable {

    using SafeMath for uint256;

     
    event Requester(address _supplyAddress, address _receiver, uint256 _valueRequested);

     
    event PayMargin(address _supplyAddress, address _marginAddress, uint256 _marginValue);


     
    event PayInterest(address _supplyAddress, address _interestAddress, uint256 _interestValue);


     
    event PayMultiFee(address _supplyAddress, address _feeAddress, uint256 _feeValue);

     
    event AddressFrozenInLogic(address indexed addr);

     
    event AddressUnfrozenInLogic(address indexed addr);

     
    BICAProxy public bicaProxy;

     
    BICALedger public bicaLedger;

     
    modifier onlyProxy {
        require(msg.sender == address(bicaProxy), "only the proxy contract allowed only");
        _;
    }

     
    constructor (address _bicaProxy, address _bicaLedger, address _admin) public  AdminUpgradeable(_admin) {
        bicaProxy = BICAProxy(_bicaProxy);
        bicaLedger = BICALedger(_bicaLedger);
    }
    
     
    function approveWithSender(address _sender, address _spender, uint256 _value) public onlyProxy returns (bool success){
        require(_spender != address(0));

        bool senderFrozen = bicaLedger.getFrozenByAddress(_sender);
        require(!senderFrozen, "Sender is frozen");

        bool spenderFrozen = bicaLedger.getFrozenByAddress(_spender);
        require(!spenderFrozen, "Spender is frozen");

        bicaLedger.setAllowance(_sender, _spender, _value);
        bicaProxy.emitApproval(_sender, _spender, _value);
        return true;
    }

     
    function increaseApprovalWithSender(address _sender, address _spender, uint256 _addedValue) public onlyProxy returns (bool success) {
        require(_spender != address(0));

        bool senderFrozen = bicaLedger.getFrozenByAddress(_sender);
        require(!senderFrozen, "Sender is frozen");

        bool spenderFrozen = bicaLedger.getFrozenByAddress(_spender);
        require(!spenderFrozen, "Spender is frozen");

        uint256 currentAllowance = bicaLedger.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance.add(_addedValue);

        require(newAllowance >= currentAllowance);

        bicaLedger.setAllowance(_sender, _spender, newAllowance);
        bicaProxy.emitApproval(_sender, _spender, newAllowance);
        return true;
    }

     
    function decreaseApprovalWithSender(address _sender, address _spender, uint256 _subtractedValue) public onlyProxy returns (bool success) {
        require(_spender != address(0));

        bool senderFrozen = bicaLedger.getFrozenByAddress(_sender);
        require(!senderFrozen, "Sender is frozen");

        bool spenderFrozen = bicaLedger.getFrozenByAddress(_spender);
        require(!spenderFrozen, "Spender is frozen");
        
        uint256 currentAllowance = bicaLedger.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance.sub(_subtractedValue);

        require(newAllowance <= currentAllowance);

        bicaLedger.setAllowance(_sender, _spender, newAllowance);
        bicaProxy.emitApproval(_sender, _spender, newAllowance);
        return true;
    }


     
    function issue(address _requesterAccount, uint256 _requestValue,
        address _marginAccount, uint256 _marginValue,
        address _interestAccount, uint256 _interestValue,
        address _otherFeeAddress, uint256 _otherFeeValue) public adminOperations {

        require(_requesterAccount != address(0));
        require(_marginAccount != address(0));
        require(_interestAccount != address(0));
        require(_otherFeeAddress != address(0));

        require(!bicaLedger.getFrozenByAddress(_requesterAccount), "Requester is frozen");
        require(!bicaLedger.getFrozenByAddress(_marginAccount), "Margin account is frozen");
        require(!bicaLedger.getFrozenByAddress(_interestAccount), "Interest account is frozen");
        require(!bicaLedger.getFrozenByAddress(_otherFeeAddress), "Other fee account is frozen");

        uint256 requestTotalValue = _marginValue.add(_interestValue).add(_otherFeeValue).add(_requestValue);

        uint256 supply = bicaLedger.totalSupply();
        uint256 newSupply = supply.add(requestTotalValue);

        if (newSupply >= supply) {
            bicaLedger.setTotalSupply(newSupply);
            bicaLedger.addBalance(_marginAccount, _marginValue);
            bicaLedger.addBalance(_interestAccount, _interestValue);
            if ( _otherFeeValue > 0 ){
                bicaLedger.addBalance(_otherFeeAddress, _otherFeeValue);
            }
            bicaLedger.addBalance(_requesterAccount, _requestValue);

            emit Requester(msg.sender, _requesterAccount, _requestValue);
            emit PayMargin(msg.sender, _marginAccount, _marginValue);
            emit PayInterest(msg.sender, _interestAccount, _interestValue);
            emit PayMultiFee(msg.sender, _otherFeeAddress, _otherFeeValue);

            bicaProxy.emitTransfer(address(0), _marginAccount, _marginValue);
            bicaProxy.emitTransfer(address(0), _interestAccount, _interestValue);
            bicaProxy.emitTransfer(address(0), _otherFeeAddress, _otherFeeValue);
            bicaProxy.emitTransfer(address(0), _requesterAccount, _requestValue);
        }
    }

     
    function burn(uint256 _value) public adminOperations returns (bool success) {
        bool burnerFrozen = bicaLedger.getFrozenByAddress(msg.sender);
        require(!burnerFrozen, "Burner is frozen");

        uint256 balanceOfSender = bicaLedger.balances(msg.sender);
        require(_value <= balanceOfSender);

        bicaLedger.setBalance(msg.sender, balanceOfSender.sub(_value));
        bicaLedger.setTotalSupply(bicaLedger.totalSupply().sub(_value));

        bicaProxy.emitTransfer(msg.sender, address(0), _value);

        return true;
    }

     
    function freeze(address _user) public adminOperations {
        require(_user != address(0), "the address to be frozen cannot be 0");
        bicaLedger.freezeByAddress(_user);
        emit AddressFrozenInLogic(_user);
    }

     
    function unfreeze(address _user) public adminOperations {
        require(_user != address(0), "the address to be unfrozen cannot be 0");
        bicaLedger.unfreezeByAddress(_user);
        emit AddressUnfrozenInLogic(_user);
    }

     
    function transferFromWithSender(address _sender, address _from, address _to, uint256 _value) public onlyProxy returns (bool success){
        require(_to != address(0));

        bool senderFrozen = bicaLedger.getFrozenByAddress(_sender);
        require(!senderFrozen, "Sender is frozen");
        bool fromFrozen = bicaLedger.getFrozenByAddress(_from);
        require(!fromFrozen, "`from` is frozen");
        bool toFrozen = bicaLedger.getFrozenByAddress(_to);
        require(!toFrozen, "`to` is frozen");

        uint256 balanceOfFrom = bicaLedger.balances(_from);
        require(_value <= balanceOfFrom);

        uint256 senderAllowance = bicaLedger.allowed(_from, _sender);
        require(_value <= senderAllowance);

        bicaLedger.setBalance(_from, balanceOfFrom.sub(_value));

        bicaLedger.addBalance(_to, _value);

        bicaLedger.setAllowance(_from, _sender, senderAllowance.sub(_value));

        bicaProxy.emitTransfer(_from, _to, _value);

        return true;
    }

     
    function transferWithSender(address _sender, address _to, uint256 _value) public onlyProxy returns (bool success){
        require(_to != address(0));

        bool senderFrozen = bicaLedger.getFrozenByAddress(_sender);
        require(!senderFrozen, "sender is frozen");
        bool toFrozen = bicaLedger.getFrozenByAddress(_to);
        require(!toFrozen, "to is frozen");

        uint256 balanceOfSender = bicaLedger.balances(_sender);
        require(_value <= balanceOfSender);

        bicaLedger.setBalance(_sender, balanceOfSender.sub(_value));

        bicaLedger.addBalance(_to, _value);

        bicaProxy.emitTransfer(_sender, _to, _value);

        return true;
    }

     
    function totalSupply() public view returns (uint256) {
        return bicaLedger.totalSupply();
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return bicaLedger.balances(_owner);
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return bicaLedger.allowed(_owner, _spender);
    }
}

 
contract BICALedger is BICALogicUpgradeable {

    using SafeMath for uint256;

     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balances;

     
    mapping (address => mapping (address => uint256)) public allowed;

     
    mapping(address => bool) public frozen;

     
    event AddressFrozen(address indexed addr);

     
    event AddressUnfrozen(address indexed addr);

     
    constructor (address _admin) public BICALogicUpgradeable(_admin) {
        totalSupply = 0;
    }

     
    function getFrozenByAddress(address _user) public view onlyLogic returns (bool frozenOrNot) {
         
        return frozen[_user];
    }

     
    function freezeByAddress(address _user) public onlyLogic {
        require(!frozen[_user], "user already frozen");
        frozen[_user] = true;
        emit AddressFrozen(_user);
    }

     
    function unfreezeByAddress(address _user) public onlyLogic {
        require(frozen[_user], "address already unfrozen");
        frozen[_user] = false;
        emit AddressUnfrozen(_user);
    }


     
    function setTotalSupply(uint256 _newTotalSupply) public onlyLogic {
        totalSupply = _newTotalSupply;
    }

     
    function setAllowance(address _owner, address _spender, uint256 _value) public onlyLogic {
        allowed[_owner][_spender] = _value;
    }

     
    function setBalance(address _owner, uint256 _newBalance) public onlyLogic {
        balances[_owner] = _newBalance;
    }

     
    function addBalance(address _owner, uint256 _balanceIncrease) public onlyLogic {
        balances[_owner] = balances[_owner].add(_balanceIncrease);
    }
}

contract ERC20Interface {

    function totalSupply() public view returns (uint256);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract BICAProxy is ERC20Interface, BICALogicUpgradeable {

     
    string public name;

     
    string public symbol;

     
    uint public decimals;

     
    constructor (address _admin) public BICALogicUpgradeable(_admin){
        name = "BitCapital Coin";
        symbol = 'BICA';
        decimals = 2;
    }
    
     
    function totalSupply() public view returns (uint256) {
        return bicaLogic.totalSupply();
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return bicaLogic.balanceOf(_owner);
    }

     
    function emitTransfer(address _from, address _to, uint256 _value) public onlyLogic {
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        return bicaLogic.transferWithSender(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        return bicaLogic.transferFromWithSender(msg.sender, _from, _to, _value);
    }

     
    function emitApproval(address _owner, address _spender, uint256 _value) public onlyLogic {
        emit Approval(_owner, _spender, _value);
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        return bicaLogic.approveWithSender(msg.sender, _spender, _value);
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool success) {
        return bicaLogic.increaseApprovalWithSender(msg.sender, _spender, _addedValue);
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool success) {
        return bicaLogic.decreaseApprovalWithSender(msg.sender, _spender, _subtractedValue);
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return bicaLogic.allowance(_owner, _spender);
    }
}