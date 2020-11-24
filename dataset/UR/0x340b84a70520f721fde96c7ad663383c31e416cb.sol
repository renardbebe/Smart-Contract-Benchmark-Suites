 

pragma solidity ^0.4.24;

 

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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

 

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
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

 

 
contract Claimable is Ownable {
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 

 
contract HasNoEther is Ownable {
     
    constructor() public payable {
        require(msg.value == 0);
    }

     
    function() external {
    }

     
    function reclaimEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}

 

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

 

 
contract CanReclaimToken is Ownable {
    using SafeERC20 for ERC20Basic;

     
    function reclaimToken(ERC20Basic token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.safeTransfer(owner, balance);
    }
}

 

 
contract HasNoTokens is CanReclaimToken {
     
    function tokenFallback(address _from, uint256 _value, bytes _data) external pure {
        _from;
        _value;
        _data;
        revert();
    }
}

 

contract AddressList is Claimable {
    string public name;
    mapping(address => bool) public onList;

    constructor(string _name, bool nullValue) public {
        name = _name;
        onList[0x0] = nullValue;
    }

    event ChangeWhiteList(address indexed to, bool onList);

     
     
    function changeList(address _to, bool _onList) onlyOwner public {
        require(_to != 0x0);
        if (onList[_to] != _onList) {
            onList[_to] = _onList;
            emit ChangeWhiteList(_to, _onList);
        }
    }
}

 

contract NamableAddressList is AddressList {
    constructor(string _name, bool nullValue)
    AddressList(_name, nullValue) public {}

    function changeName(string _name) onlyOwner public {
        name = _name;
    }
}

 

 
contract HasNoContracts is Ownable{
     
    function reclaimContract(address contractAddr) external onlyOwner {
        Ownable contractInst = Ownable(contractAddr);
        contractInst.transferOwnership(owner);
    }
}

 

 
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

 

 
contract BalanceSheet is Claimable {
    using SafeMath for uint256;

    mapping(address => uint256) public balanceOf;

    function addBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].add(_value);
    }

    function subBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].sub(_value);
    }

    function setBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = _value;
    }
}

 

 
contract BasicToken is ERC20Basic, Claimable {
    using SafeMath for uint256;

    BalanceSheet public balances;

    uint256 totalSupply_;

    function setBalanceSheet(address sheet) external onlyOwner {
        balances = BalanceSheet(sheet);
        balances.claimOwnership();
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        transferAllArgsNoAllowance(msg.sender, _to, _value);
        return true;
    }

    function transferAllArgsNoAllowance(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(_from != address(0));
        require(_value <= balances.balanceOf(_from));

         
        balances.subBalance(_from, _value);
        balances.addBalance(_to, _value);
        emit Transfer(_from, _to, _value);
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances.balanceOf(_owner);
    }
}

 

 
contract BurnableToken is BasicToken{
    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances.balanceOf(msg.sender));
         
         

        address burner = msg.sender;
        balances.subBalance(burner, _value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
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

 

 
contract AllowanceSheet is Claimable {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) public allowanceOf;

    function addAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].add(_value);
    }

    function subAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].sub(_value);
    }

    function setAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = _value;
    }
}

 

contract StandardToken is ERC20, BasicToken {
    AllowanceSheet public allowances;

    function setAllowanceSheet(address sheet) external onlyOwner {
        allowances = AllowanceSheet(sheet);
        allowances.claimOwnership();
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        transferAllArgsYesAllowance(_from, _to, _value, msg.sender);
        return true;
    }

    function transferAllArgsYesAllowance(address _from, address _to, uint256 _value, address spender) internal {
        require(_value <= allowances.allowanceOf(_from, spender));

        allowances.subAllowance(_from, spender, _value);
        transferAllArgsNoAllowance(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        approveAllArgs(_spender, _value, msg.sender);
        return true;
    }

    function approveAllArgs(address _spender, uint256 _value, address _tokenHolder) internal {
        allowances.setAllowance(_tokenHolder, _spender, _value);
        emit Approval(_tokenHolder, _spender, _value);
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances.allowanceOf(_owner, _spender);
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        increaseApprovalAllArgs(_spender, _addedValue, msg.sender);
        return true;
    }

    function increaseApprovalAllArgs(address _spender, uint _addedValue, address tokenHolder) internal {
        allowances.addAllowance(tokenHolder, _spender, _addedValue);
        emit Approval(tokenHolder, _spender, allowances.allowanceOf(tokenHolder, _spender));
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        decreaseApprovalAllArgs(_spender, _subtractedValue, msg.sender);
        return true;
    }

    function decreaseApprovalAllArgs(address _spender, uint _subtractedValue, address tokenHolder) internal {
        uint oldValue = allowances.allowanceOf(tokenHolder, _spender);
        if (_subtractedValue > oldValue) {
            allowances.setAllowance(tokenHolder, _spender, 0);
        } else {
            allowances.subAllowance(tokenHolder, _spender, _subtractedValue);
        }
        emit Approval(tokenHolder, _spender, allowances.allowanceOf(tokenHolder, _spender));
    }
}

 

 
contract PausableToken is StandardToken, Pausable{
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

 

contract DelegateERC20 {
    function delegateTotalSupply() public view returns (uint256);

    function delegateBalanceOf(address who) public view returns (uint256);

    function delegateTransfer(address to, uint256 value, address origSender) public returns (bool);

    function delegateAllowance(address owner, address spender) public view returns (uint256);

    function delegateTransferFrom(address from, address to, uint256 value, address origSender) public returns (bool);

    function delegateApprove(address spender, uint256 value, address origSender) public returns (bool);

    function delegateIncreaseApproval(address spender, uint addedValue, address origSender) public returns (bool);

    function delegateDecreaseApproval(address spender, uint subtractedValue, address origSender) public returns (bool);
}

 

contract CanDelegate is StandardToken {
     
     
    DelegateERC20 public delegate;

    event DelegateToNewContract(address indexed newContract);

     
    function delegateToNewContract(DelegateERC20 newContract) public onlyOwner {
        delegate = newContract;
        emit DelegateToNewContract(newContract);
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        if (delegate == address(0)) {
            return super.transfer(to, value);
        } else {
            return delegate.delegateTransfer(to, value, msg.sender);
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if (delegate == address(0)) {
            return super.transferFrom(from, to, value);
        } else {
            return delegate.delegateTransferFrom(from, to, value, msg.sender);
        }
    }

    function balanceOf(address who) public view returns (uint256) {
        if (delegate == address(0)) {
            return super.balanceOf(who);
        } else {
            return delegate.delegateBalanceOf(who);
        }
    }

    function approve(address spender, uint256 value) public returns (bool) {
        if (delegate == address(0)) {
            return super.approve(spender, value);
        } else {
            return delegate.delegateApprove(spender, value, msg.sender);
        }
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        if (delegate == address(0)) {
            return super.allowance(_owner, spender);
        } else {
            return delegate.delegateAllowance(_owner, spender);
        }
    }

    function totalSupply() public view returns (uint256) {
        if (delegate == address(0)) {
            return super.totalSupply();
        } else {
            return delegate.delegateTotalSupply();
        }
    }

    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        if (delegate == address(0)) {
            return super.increaseApproval(spender, addedValue);
        } else {
            return delegate.delegateIncreaseApproval(spender, addedValue, msg.sender);
        }
    }

    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        if (delegate == address(0)) {
            return super.decreaseApproval(spender, subtractedValue);
        } else {
            return delegate.delegateDecreaseApproval(spender, subtractedValue, msg.sender);
        }
    }
}

 

contract StandardDelegate is StandardToken, DelegateERC20 {
    address public delegatedFrom;

    modifier onlySender(address source) {
        require(msg.sender == source);
        _;
    }

    function setDelegatedFrom(address addr) onlyOwner public {
        delegatedFrom = addr;
    }

     
    function delegateTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    function delegateBalanceOf(address who) public view returns (uint256) {
        return balanceOf(who);
    }

    function delegateTransfer(address to, uint256 value, address origSender) onlySender(delegatedFrom) public returns (bool) {
        transferAllArgsNoAllowance(origSender, to, value);
        return true;
    }

    function delegateAllowance(address owner, address spender) public view returns (uint256) {
        return allowance(owner, spender);
    }

    function delegateTransferFrom(address from, address to, uint256 value, address origSender) onlySender(delegatedFrom) public returns (bool) {
        transferAllArgsYesAllowance(from, to, value, origSender);
        return true;
    }

    function delegateApprove(address spender, uint256 value, address origSender) onlySender(delegatedFrom) public returns (bool) {
        approveAllArgs(spender, value, origSender);
        return true;
    }

    function delegateIncreaseApproval(address spender, uint addedValue, address origSender) onlySender(delegatedFrom) public returns (bool) {
        increaseApprovalAllArgs(spender, addedValue, origSender);
        return true;
    }

    function delegateDecreaseApproval(address spender, uint subtractedValue, address origSender) onlySender(delegatedFrom) public returns (bool) {
        decreaseApprovalAllArgs(spender, subtractedValue, origSender);
        return true;
    }
}

 

contract TrueVND is NoOwner, BurnableToken, CanDelegate, StandardDelegate, PausableToken {
    string public name = "TrueVND";
    string public symbol = "TVND";
    uint8 public constant decimals = 18;

    AddressList public canReceiveMintWhiteList;
    AddressList public canBurnWhiteList;
    AddressList public blackList;
    AddressList public noFeesList;
    address public staker;

    uint256 public burnMin = 1000 * 10 ** uint256(decimals);
    uint256 public burnMax = 20000000 * 10 ** uint256(decimals);

    uint80 public transferFeeNumerator = 8;
    uint80 public transferFeeDenominator = 10000;
    uint80 public mintFeeNumerator = 0;
    uint80 public mintFeeDenominator = 10000;
    uint256 public mintFeeFlat = 0;
    uint80 public burnFeeNumerator = 0;
    uint80 public burnFeeDenominator = 10000;
    uint256 public burnFeeFlat = 0;

    event ChangeBurnBoundsEvent(uint256 newMin, uint256 newMax);
    event Mint(address indexed to, uint256 amount);
    event WipedAccount(address indexed account, uint256 balance);

    constructor() public {
        totalSupply_ = 0;
        staker = msg.sender;
    }

    function setLists(AddressList _canReceiveMintWhiteList, AddressList _canBurnWhiteList, AddressList _blackList, AddressList _noFeesList) onlyOwner public {
        canReceiveMintWhiteList = _canReceiveMintWhiteList;
        canBurnWhiteList = _canBurnWhiteList;
        blackList = _blackList;
        noFeesList = _noFeesList;
    }

    function changeName(string _name, string _symbol) onlyOwner public {
        name = _name;
        symbol = _symbol;
    }

     
     
    function burn(uint256 _value) public {
        require(canBurnWhiteList.onList(msg.sender));
        require(_value >= burnMin);
        require(_value <= burnMax);
        uint256 fee = payStakingFee(msg.sender, _value, burnFeeNumerator, burnFeeDenominator, burnFeeFlat, 0x0);
        uint256 remaining = _value.sub(fee);
        super.burn(remaining);
    }

     
     
    function mint(address _to, uint256 _amount) onlyOwner public {
        require(canReceiveMintWhiteList.onList(_to));
        totalSupply_ = totalSupply_.add(_amount);
        balances.addBalance(_to, _amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        payStakingFee(_to, _amount, mintFeeNumerator, mintFeeDenominator, mintFeeFlat, 0x0);
    }

     
     
     
     
     
     
    function changeBurnBounds(uint newMin, uint newMax) onlyOwner public {
        require(newMin <= newMax);
        burnMin = newMin;
        burnMax = newMax;
        emit ChangeBurnBoundsEvent(newMin, newMax);
    }

     
    function transferAllArgsYesAllowance(address _from, address _to, uint256 _value, address spender) internal {
        require(!blackList.onList(spender));
        super.transferAllArgsYesAllowance(_from, _to, _value, spender);
    }

     
     
    function transferAllArgsNoAllowance(address _from, address _to, uint256 _value) internal {
        require(!blackList.onList(_from));
        require(!blackList.onList(_to));
        super.transferAllArgsNoAllowance(_from, _to, _value);
        payStakingFee(_to, _value, transferFeeNumerator, transferFeeDenominator, burnFeeFlat, _from);
    }

    function wipeBlacklistedAccount(address account) public onlyOwner {
        require(blackList.onList(account));
        uint256 oldValue = balanceOf(account);
        balances.setBalance(account, 0);
        totalSupply_ = totalSupply_.sub(oldValue);
        emit WipedAccount(account, oldValue);
    }

    function payStakingFee(address payer, uint256 value, uint80 numerator, uint80 denominator, uint256 flatRate, address otherParticipant) private returns (uint256) {
        if (noFeesList.onList(payer) || noFeesList.onList(otherParticipant)) {
            return 0;
        }
        uint256 stakingFee = value.mul(numerator).div(denominator).add(flatRate);
        if (stakingFee > 0) {
            super.transferAllArgsNoAllowance(payer, staker, stakingFee);
        }
        return stakingFee;
    }

    function changeStakingFees(uint80 _transferFeeNumerator,
        uint80 _transferFeeDenominator,
        uint80 _mintFeeNumerator,
        uint80 _mintFeeDenominator,
        uint256 _mintFeeFlat,
        uint80 _burnFeeNumerator,
        uint80 _burnFeeDenominator,
        uint256 _burnFeeFlat) public onlyOwner {
        require(_transferFeeDenominator != 0);
        require(_mintFeeDenominator != 0);
        require(_burnFeeDenominator != 0);
        transferFeeNumerator = _transferFeeNumerator;
        transferFeeDenominator = _transferFeeDenominator;
        mintFeeNumerator = _mintFeeNumerator;
        mintFeeDenominator = _mintFeeDenominator;
        mintFeeFlat = _mintFeeFlat;
        burnFeeNumerator = _burnFeeNumerator;
        burnFeeDenominator = _burnFeeDenominator;
        burnFeeFlat = _burnFeeFlat;
    }

    function changeStaker(address newStaker) public onlyOwner {
        require(newStaker != address(0));
        staker = newStaker;
    }
}

 

 
 
 
 
 
 
 
 
 
 
contract TimeLockedController is HasNoEther, HasNoTokens, Claimable {
    using SafeMath for uint256;

    uint public constant blocksDelay = 24 * 60 * 60 / 15;  

    struct MintOperation {
        address to;
        uint256 amount;
        address admin;
        uint deferBlock;
    }

    address public admin;
    TrueVND public trueVND;
    MintOperation[] public mintOperations;

    modifier onlyAdminOrOwner() {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }

    event MintOperationEvent(address indexed _to, uint256 amount, uint deferBlock, uint opIndex);
    event TransferChildEvent(address indexed _child, address indexed _newOwner);
    event ReclaimEvent(address indexed other);
    event ChangeBurnBoundsEvent(uint newMin, uint newMax);
    event WipedAccount(address indexed account);
    event ChangeStakingFeesEvent(uint80 _transferFeeNumerator,
        uint80 _transferFeeDenominator,
        uint80 _mintFeeNumerator,
        uint80 _mintFeeDenominator,
        uint256 _mintFeeFlat,
        uint80 _burnFeeNumerator,
        uint80 _burnFeeDenominator,
        uint256 _burnFeeFlat);
    event ChangeStakerEvent(address newStaker);
    event DelegateEvent(DelegateERC20 delegate);
    event SetDelegatedFromEvent(address source);
    event ChangeTrueVNDEvent(TrueVND newContract);
    event ChangeNameEvent(string name, string symbol);
    event AdminshipTransferred(address indexed previousAdmin, address indexed newAdmin);

     
    function requestMint(address _to, uint256 _amount) public onlyAdminOrOwner {
        uint deferBlock = block.number;
        if (msg.sender != owner) {
            deferBlock = deferBlock.add(blocksDelay);
        }
        MintOperation memory op = MintOperation(_to, _amount, admin, deferBlock);
        emit MintOperationEvent(_to, _amount, deferBlock, mintOperations.length);
        mintOperations.push(op);
    }

     
     
    function finalizeMint(uint index) public onlyAdminOrOwner {
        MintOperation memory op = mintOperations[index];
        require(op.admin == admin);
         
        require(op.deferBlock <= block.number);
         
        address to = op.to;
        uint256 amount = op.amount;
        delete mintOperations[index];
        trueVND.mint(to, amount);
    }

     
     
    function transferChild(Ownable _child, address _newOwner) public onlyOwner {
        emit TransferChildEvent(_child, _newOwner);
        _child.transferOwnership(_newOwner);
    }

     
     
     
    function requestReclaim(Ownable other) public onlyOwner {
        emit ReclaimEvent(other);
        trueVND.reclaimContract(other);
    }

     
     
    function changeBurnBounds(uint newMin, uint newMax) public onlyOwner {
        emit ChangeBurnBoundsEvent(newMin, newMax);
        trueVND.changeBurnBounds(newMin, newMax);
    }

    function wipeBlacklistedAccount(address account) public onlyOwner {
        emit WipedAccount(account);
        trueVND.wipeBlacklistedAccount(account);
    }

     
    function changeStakingFees(uint80 _transferFeeNumerator,
        uint80 _transferFeeDenominator,
        uint80 _mintFeeNumerator,
        uint80 _mintFeeDenominator,
        uint256 _mintFeeFlat,
        uint80 _burnFeeNumerator,
        uint80 _burnFeeDenominator,
        uint256 _burnFeeFlat) public onlyOwner {
        emit ChangeStakingFeesEvent(_transferFeeNumerator,
            _transferFeeDenominator,
            _mintFeeNumerator,
            _mintFeeDenominator,
            _mintFeeFlat,
            _burnFeeNumerator,
            _burnFeeDenominator,
            _burnFeeFlat);
        trueVND.changeStakingFees(_transferFeeNumerator,
            _transferFeeDenominator,
            _mintFeeNumerator,
            _mintFeeDenominator,
            _mintFeeFlat,
            _burnFeeNumerator,
            _burnFeeDenominator,
            _burnFeeFlat);
    }

     
    function changeStaker(address newStaker) public onlyOwner {
        emit ChangeStakerEvent(newStaker);
        trueVND.changeStaker(newStaker);
    }

     
    function delegateToNewContract(DelegateERC20 delegate) public onlyOwner {
        emit DelegateEvent(delegate);
        trueVND.delegateToNewContract(delegate);
    }

     
    function setDelegatedFrom(address _source) public onlyOwner {
        emit SetDelegatedFromEvent(_source);
        trueVND.setDelegatedFrom(_source);
    }

     
     
    function setTrueVND(TrueVND newContract) public onlyOwner {
        emit ChangeTrueVNDEvent(newContract);
        trueVND = newContract;
    }

     
    function changeName(string name, string symbol) public onlyOwner {
        emit ChangeNameEvent(name, symbol);
        trueVND.changeName(name, symbol);
    }

     
    function transferAdminship(address newAdmin) public onlyOwner {
        emit AdminshipTransferred(admin, newAdmin);
        admin = newAdmin;
    }

     
    function setLists(AddressList _canReceiveMintWhiteList, AddressList _canBurnWhiteList, AddressList _blackList, AddressList _noFeesList) onlyOwner public {
        trueVND.setLists(_canReceiveMintWhiteList, _canBurnWhiteList, _blackList, _noFeesList);
    }

     
    function updateList(address list, address entry, bool flag) public onlyAdminOrOwner {
        AddressList(list).changeList(entry, flag);
    }

     
    function renameList(address list, string name) public onlyAdminOrOwner {
        NamableAddressList(list).changeName(name);
    }

     
    function issueClaimOwnership(address _other) public onlyAdminOrOwner {
        Claimable other = Claimable(_other);
        other.claimOwnership();
    }
}