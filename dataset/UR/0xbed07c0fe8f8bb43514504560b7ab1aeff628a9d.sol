 

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
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

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

 

pragma solidity 0.5.0;


 
library TaxLib
{
    using SafeMath for uint256;

     
    struct DynamicTax
    {
         
        uint256 amount;

         
        uint256 shift;
    }

     
    function applyTax(uint256 taxAmount, uint256 shift, uint256 value) internal pure returns (uint256)
    {
        uint256 temp = value.mul(taxAmount);

        return temp.div(shift);
    }

     
    function normalizeShiftAmount(uint256 shift) internal pure returns (uint256)
    {
        require(shift >= 0 && shift <= 2, "You can't set more than 2 decimal places");

        uint256 value = 100;

        return value.mul(10 ** shift);
    }
}

 

 

pragma solidity 0.5.0;



 
library VestingLib
{
    using SafeMath for uint256;

     
    uint256 private constant _timeShiftPeriod = 60 days;

    struct TeamMember
    {
         
        uint256 nextWithdrawal;

         
        uint256 totalRemainingAmount;

         
        uint256 firstTransferValue;

         
        uint256 eachTransferValue;

         
        bool active;
    }

     
    function _calculateMemberEarnings(uint256 tokenAmount) internal pure returns (uint256, uint256)
    {
         
        uint256 firstTransfer = TaxLib.applyTax(20, 100, tokenAmount);

         
        uint256 eachMonthTransfer = TaxLib.applyTax(10, 100, tokenAmount.sub(firstTransfer));

        return (firstTransfer, eachMonthTransfer);
    }

     
    function _updateNextWithdrawalTime(uint256 oldWithdrawal) internal view returns (uint256)
    {
        uint currentTimestamp = block.timestamp;

        require(oldWithdrawal <= currentTimestamp, "You need to wait the next withdrawal period");

         
        if (oldWithdrawal == 0)
        {
            return _timeShiftPeriod.add(currentTimestamp);
        }

         
        return oldWithdrawal.add(_timeShiftPeriod);
    }

     
    function _checkAmountForPay(TeamMember memory member) internal pure returns (uint256)
    {
         
        if (member.nextWithdrawal == 0)
        {
            return member.firstTransferValue;
        }

         
        return member.eachTransferValue >= member.totalRemainingAmount
            ? member.totalRemainingAmount
            : member.eachTransferValue;
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

pragma solidity ^0.5.0;


 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

 

pragma solidity ^0.5.0;

 
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
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 

pragma solidity 0.5.0;



 
contract Taxable is Ownable
{
     
    address internal _taxRecipientAddr;

     
    TaxLib.DynamicTax private _taxContainer;

    constructor(address taxRecipientAddr) public
    {
        _taxRecipientAddr = taxRecipientAddr;

         
        changeTax(9, 1);
    }

     
    function taxRecipientAddr() public view returns (address)
    {
        return _taxRecipientAddr;
    }

     
    function currentTaxAmount() public view returns (uint256)
    {
        return _taxContainer.amount;
    }

     
    function currentTaxShift() public view returns (uint256)
    {
        return _taxContainer.shift;
    }

     
    function changeTax(uint256 amount, uint256 shift) public onlyOwner
    {
        if (shift == 0)
        {
            require(amount <= 3, "You can't set a tax greater than 3%");
        }

        _taxContainer = TaxLib.DynamicTax(
            amount,

             
            TaxLib.normalizeShiftAmount(shift)
        );
    }

     
    function _applyTax(uint256 value) internal view returns (uint256)
    {
        return TaxLib.applyTax(
            _taxContainer.amount,
            _taxContainer.shift,
            value
        );
    }
}

 

 

pragma solidity 0.5.0;

 
contract BCHHandled
{
     
    address private _bchAddress;

     
    mapping (address => bool) private _bchAllowed;

     
    event BchApproval(address indexed to, bool state);

    constructor(address bchAddress) public
    {
        _bchAddress = bchAddress;
    }

     
    function isBchHandled(address wallet) public view returns (bool)
    {
        return _bchAllowed[wallet];
    }

     
    function bchAuthorize() public returns (bool)
    {
        return _changeState(true);
    }

     
    function bchRevoke() public returns (bool)
    {
        return _changeState(false);
    }

     
    function canBchHandle(address from) internal view returns (bool)
    {
        return isBchHandled(from) && msg.sender == _bchAddress;
    }

     
    function _changeState(bool state) private returns (bool)
    {
        emit BchApproval(msg.sender, _bchAllowed[msg.sender] = state);

        return true;
    }
}

 

 

pragma solidity 0.5.0;








 
contract WibxToken is ERC20Pausable, ERC20Burnable, ERC20Detailed, Taxable, BCHHandled
{
     
    uint256 public constant INITIAL_SUPPLY = 12000000000 * (10 ** 18);

    constructor(address bchAddress, address taxRecipientAddr) public ERC20Detailed("WiBX Utility Token", "WBX", 18)
                                                                     BCHHandled(bchAddress)
                                                                     Taxable(taxRecipientAddr)
    {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

     
    function transfer(address to, uint256 value) public returns (bool)
    {
        return _fullTransfer(msg.sender, to, value);
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool)
    {
        if (canBchHandle(from))
        {
            return _fullTransfer(from, to, value);
        }

         
        if (from == taxRecipientAddr() || to == taxRecipientAddr())
        {
            super.transferFrom(from, to, value);

            return true;
        }

        uint256 taxValue = _applyTax(value);

         
        super.transferFrom(from, taxRecipientAddr(), taxValue);

         
        super.transferFrom(from, to, value);

        return true;
    }

     
    function sendBatch(address[] memory recipients, uint256[] memory values, address from) public returns (bool)
    {
         
        uint maxTransactionCount = 100;
        uint transactionCount = recipients.length;

        require(transactionCount <= maxTransactionCount, "Max transaction count violated");
        require(transactionCount == values.length, "Wrong data");

        if (msg.sender == from)
        {
            return _sendBatchSelf(recipients, values, transactionCount);
        }

        return _sendBatchFrom(recipients, values, from, transactionCount);
    }

     
    function _sendBatchSelf(address[] memory recipients, uint256[] memory values, uint transactionCount) private returns (bool)
    {
        for (uint i = 0; i < transactionCount; i++)
        {
            _fullTransfer(msg.sender, recipients[i], values[i]);
        }

        return true;
    }

     
    function _sendBatchFrom(address[] memory recipients, uint256[] memory values, address from, uint transactionCount) private returns (bool)
    {
        for (uint i = 0; i < transactionCount; i++)
        {
            transferFrom(from, recipients[i], values[i]);
        }

        return true;
    }

     
    function _fullTransfer(address from, address to, uint256 value) private returns (bool)
    {
         
        if (from == taxRecipientAddr() || to == taxRecipientAddr())
        {
            _transfer(from, to, value);

            return true;
        }

        uint256 taxValue = _applyTax(value);

         
        _transfer(from, taxRecipientAddr(), taxValue);

         
        _transfer(from, to, value);

        return true;
    }
}

 

 

pragma solidity 0.5.0;





 
contract WibxTokenVesting is Ownable
{
    using SafeMath for uint256;

     
    WibxToken private _wibxToken;

     
    mapping (address => VestingLib.TeamMember) private _members;

     
    uint256 private _alocatedWibxVestingTokens = 0;

    constructor(address wibxTokenAddress) public
    {
        _wibxToken = WibxToken(wibxTokenAddress);
    }

     
    function addTeamMember(address wallet, uint256 tokenAmount) public onlyOwner returns (bool)
    {
        require(!_members[wallet].active, "Member already added");

        uint256 firstTransfer;
        uint256 eachMonthTransfer;

        _alocatedWibxVestingTokens = _alocatedWibxVestingTokens.add(tokenAmount);
        (firstTransfer, eachMonthTransfer) = VestingLib._calculateMemberEarnings(tokenAmount);

        _members[wallet] = VestingLib.TeamMember({
            totalRemainingAmount: tokenAmount,
            firstTransferValue: firstTransfer,
            eachTransferValue: eachMonthTransfer,
            nextWithdrawal: 0,
            active: true
        });

        return _members[wallet].active;
    }

     
    function withdrawal(address wallet) public returns (bool)
    {
        VestingLib.TeamMember storage member = _members[wallet];

        require(member.active, "The team member is not found");
        require(member.totalRemainingAmount > 0, "There is no more tokens to transfer to this wallet");

        uint256 amountToTransfer = VestingLib._checkAmountForPay(member);
        require(totalWibxVestingSupply() >= amountToTransfer, "The contract doesnt have founds to pay");

        uint256 nextWithdrawalTime = VestingLib._updateNextWithdrawalTime(member.nextWithdrawal);

        _wibxToken.transfer(wallet, amountToTransfer);

        member.nextWithdrawal = nextWithdrawalTime;
        member.totalRemainingAmount = member.totalRemainingAmount.sub(amountToTransfer);
        _alocatedWibxVestingTokens = _alocatedWibxVestingTokens.sub(amountToTransfer);

        return true;
    }

     
    function terminateTokenVesting() public onlyOwner
    {
        require(_alocatedWibxVestingTokens == 0, "All withdrawals have yet to take place");

        if (totalWibxVestingSupply() > 0)
        {
            _wibxToken.transfer(_wibxToken.taxRecipientAddr(), totalWibxVestingSupply());
        }

         
        selfdestruct(address(uint160(owner())));
    }

     
    function totalWibxVestingSupply() public view returns (uint256)
    {
        return _wibxToken.balanceOf(address(this));
    }

     
    function totalAlocatedWibxVestingTokens() public view returns (uint256)
    {
        return _alocatedWibxVestingTokens;
    }

     
    function remainingTokenAmount(address wallet) public view returns (uint256)
    {
        return _members[wallet].totalRemainingAmount;
    }

     
    function nextWithdrawalTime(address wallet) public view returns (uint256)
    {
        return _members[wallet].nextWithdrawal;
    }
}