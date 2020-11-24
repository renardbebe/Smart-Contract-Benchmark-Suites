 

 


 

pragma solidity ^0.5.6;

 
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

 

pragma solidity ^0.5.6;

 
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

 

pragma solidity ^0.5.6;

 
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

 

pragma solidity ^0.5.6;

 
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

 

pragma solidity ^0.5.6;

 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

 

pragma solidity ^0.5.6;

 
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

 

pragma solidity ^0.5.6;

 
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

 

pragma solidity ^0.5.6;


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

 

pragma solidity ^0.5.6;

 
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

 

pragma solidity ^0.5.6;

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 

pragma solidity ^0.5.6;

 
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender));
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

 

pragma solidity ^0.5.6;

 
contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

 

pragma solidity ^0.5.6;

 
contract InvictusWhitelist is Ownable, WhitelistedRole {
    constructor ()
        WhitelistedRole() public {
    }

     
    function verifyParticipant(address participant) public onlyWhitelistAdmin {
        if (!isWhitelisted(participant)) {
            addWhitelisted(participant);
        }
    }

     
    function removeWhitelistAdmin(address account) public onlyOwner {
        require(account != msg.sender, "Use renounceWhitelistAdmin");
        _removeWhitelistAdmin(account);
    }
}

 

pragma solidity ^0.5.6;

 
contract C10Token is ERC20Detailed, ERC20Burnable, Ownable, Pausable, MinterRole {

     
    mapping(address => uint256) public pendingBuys;
     
    address[] public participantAddresses;

     
    mapping (address => uint256) public pendingWithdrawals;
    address payable[] public withdrawals;

    uint256 public minimumWei = 50 finney;
    uint256 public entryFee = 50;   
    uint256 public exitFee = 50;   
    uint256 public minTokenRedemption = 1 ether;
    uint256 public maxAllocationsPerTx = 50;
    uint256 public maxWithdrawalsPerTx = 50;
    Price public price;

    address public whitelistContract;

    struct Price {
        uint256 numerator;
        uint256 denominator;
    }

    event PriceUpdate(uint256 numerator, uint256 denominator);
    event AddLiquidity(uint256 value);
    event RemoveLiquidity(uint256 value);
    event DepositReceived(address indexed participant, uint256 value);
    event TokensIssued(address indexed participant, uint256 amountTokens, uint256 etherAmount);
    event WithdrawRequest(address indexed participant, uint256 amountTokens);
    event Withdraw(address indexed participant, uint256 amountTokens, uint256 etherAmount);
    event WithdrawInvalidAddress(address indexed participant, uint256 amountTokens);
    event WithdrawFailed(address indexed participant, uint256 amountTokens);
    event TokensClaimed(address indexed token, uint256 balance);

    constructor (uint256 priceNumeratorInput, address whitelistContractInput)
        ERC20Detailed("CRYPTO10 Hedged", "C10", 18)
        ERC20Burnable()
        Pausable() public {
            price = Price(priceNumeratorInput, 1000);
            require(priceNumeratorInput > 0, "Invalid price numerator");
            require(whitelistContractInput != address(0), "Invalid whitelist address");
            whitelistContract = whitelistContractInput;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buy() external payable {
        buyTokens(msg.sender);
    }

     
    function setMaxAllocationsPerTx(uint256 newMaxAllocationsPerTx) external onlyOwner {
        require(newMaxAllocationsPerTx > 0, "Must be greater than 0");
        maxAllocationsPerTx = newMaxAllocationsPerTx;
    }

     
    function setMaxWithdrawalsPerTx(uint256 newMaxWithdrawalsPerTx) external onlyOwner {
        require(newMaxWithdrawalsPerTx > 0, "Must be greater than 0");
        maxWithdrawalsPerTx = newMaxWithdrawalsPerTx;
    }

    function setEntryFee(uint256 newFee) external onlyOwner {
        require(newFee < 10000, "Must be less than 100 percent");
        entryFee = newFee;
    }

    function setExitFee(uint256 newFee) external onlyOwner {
        require(newFee < 10000, "Must be less than 100 percent");
        exitFee = newFee;
    }

     
    function setMinimumBuyValue(uint256 newMinimumWei) external onlyOwner {
        require(newMinimumWei > 0, "Minimum must be greater than 0");
        minimumWei = newMinimumWei;
    }

     
    function setMinimumTokenRedemption(uint256 newMinTokenRedemption) external onlyOwner {
        require(newMinTokenRedemption > 0, "Minimum must be greater than 0");
        minTokenRedemption = newMinTokenRedemption;
    }

     
    function updatePrice(uint256 newNumerator) external onlyMinter {
        require(newNumerator > 0, "Must be positive value");

        price.numerator = newNumerator;

        allocateTokens();
        processWithdrawals();
        emit PriceUpdate(price.numerator, price.denominator);
    }

     
    function updatePriceDenominator(uint256 newDenominator) external onlyMinter {
        require(newDenominator > 0, "Must be positive value");

        price.denominator = newDenominator;
    }

     
    function requestWithdrawal(uint256 amountTokensToWithdraw) external whenNotPaused 
        onlyWhitelisted {

        address payable participant = msg.sender;
        require(balanceOf(participant) >= amountTokensToWithdraw, 
            "Cannot withdraw more than balance held");
        require(amountTokensToWithdraw >= minTokenRedemption, "Too few tokens");

        burn(amountTokensToWithdraw);

        uint256 pendingAmount = pendingWithdrawals[participant];
        if (pendingAmount == 0) {
            withdrawals.push(participant);
        }
        pendingWithdrawals[participant] = pendingAmount.add(amountTokensToWithdraw);
        emit WithdrawRequest(participant, amountTokensToWithdraw);
    }

     
    function claimTokens(ERC20 token) external onlyOwner {
        require(address(token) != address(0), "Invalid address");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), token.balanceOf(address(this)));
        emit TokensClaimed(address(token), balance);
    }
    
     
    function burnForParticipant(address account, uint256 value) external onlyOwner {
        _burn(account, value);
    }


     
    function addLiquidity() external payable {
        require(msg.value > 0, "Must be positive value");
        emit AddLiquidity(msg.value);
    }

     
    function removeLiquidity(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");

        msg.sender.transfer(amount);
        emit RemoveLiquidity(amount);
    }

     
    function removeMinter(address account) external onlyOwner {
        require(account != msg.sender, "Use renounceMinter");
        _removeMinter(account);
    }

     
    function removePauser(address account) external onlyOwner {
        require(account != msg.sender, "Use renouncePauser");
        _removePauser(account);
    }

     
    function numberWithdrawalsPending() external view returns (uint256) {
        return withdrawals.length;
    }

     
    function numberBuysPending() external view returns (uint256) {
        return participantAddresses.length;
    }

     
    function mint(address to, uint256 value) public onlyMinter whenNotPaused returns (bool) {
        _mint(to, value);
        return true;
    }

     
    function buyTokens(address participant) internal whenNotPaused onlyWhitelisted {
        assert(participant != address(0));

         
        require(msg.value >= minimumWei, "Minimum wei not met");

        uint256 pendingAmount = pendingBuys[participant];
        if (pendingAmount == 0) {
            participantAddresses.push(participant);
        }

         
        pendingBuys[participant] = pendingAmount.add(msg.value);

        emit DepositReceived(participant, msg.value);
    }

     
    function allocateTokens() internal {
        uint256 numberOfAllocations = min(participantAddresses.length, maxAllocationsPerTx);
        uint256 startingIndex = participantAddresses.length;
        uint256 endingIndex = participantAddresses.length.sub(numberOfAllocations);

        for (uint256 i = startingIndex; i > endingIndex; i--) {
            handleAllocation(i - 1);
        }
    }

    function handleAllocation(uint256 index) internal {
        address participant = participantAddresses[index];
        uint256 deposit = pendingBuys[participant];
        uint256 feeAmount = deposit.mul(entryFee) / 10000;
        uint256 balance = deposit.sub(feeAmount);

        uint256 newTokens = balance.mul(price.numerator) / price.denominator;
        pendingBuys[participant] = 0;
        participantAddresses.pop();

        if (feeAmount > 0) {
            address(uint160(owner())).transfer(feeAmount);
        }

        mint(participant, newTokens);
        emit TokensIssued(participant, newTokens, balance);
    }

     
    function processWithdrawals() internal {
        uint256 numberOfWithdrawals = min(withdrawals.length, maxWithdrawalsPerTx);
        uint256 startingIndex = withdrawals.length;
        uint256 endingIndex = withdrawals.length.sub(numberOfWithdrawals);

        for (uint256 i = startingIndex; i > endingIndex; i--) {
            handleWithdrawal(i - 1);
        }
    }

    function handleWithdrawal(uint256 index) internal {
        address payable participant = withdrawals[index];
        uint256 tokens = pendingWithdrawals[participant];
        uint256 withdrawValue = tokens.mul(price.denominator) / price.numerator;
        pendingWithdrawals[participant] = 0;
        withdrawals.pop();

        if (address(this).balance < withdrawValue) {
            mint(participant, tokens);
            emit WithdrawFailed(participant, tokens);
            return;
        }

        uint256 feeAmount = withdrawValue.mul(exitFee) / 10000;
        uint256 balance = withdrawValue.sub(feeAmount);
        if (participant.send(balance)) {
            if (feeAmount > 0) {
                address(uint160(owner())).transfer(feeAmount);
            }
            emit Withdraw(participant, tokens, balance);
        } else {
            mint(participant, tokens);
            emit WithdrawInvalidAddress(participant, tokens);
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    modifier onlyWhitelisted() {
        require(InvictusWhitelist(whitelistContract).isWhitelisted(msg.sender), "Must be whitelisted");
        _;
    }
}