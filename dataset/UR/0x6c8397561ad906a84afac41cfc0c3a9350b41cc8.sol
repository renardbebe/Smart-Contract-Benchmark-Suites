 

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





 
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}




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





 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}






 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}








 
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





contract TokenWhitelist is Ownable {

    mapping(address => bool) private whitelist;

    event Whitelisted(address indexed wallet);
    event Dewhitelisted(address indexed wallet);

    function enableWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0), "Invalid wallet");
        whitelist[_wallet] = true;
        emit Whitelisted(_wallet);
    }
    
    function enableWalletBatch(address[] memory _wallets) public onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            enableWallet(_wallets[i]);
        }
    }


    function disableWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0), "Invalid wallet");
        whitelist[_wallet] = false;
        emit Dewhitelisted(_wallet);
    }

    
    function disableWalletBatch(address[] memory _wallets) public onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            disableWallet(_wallets[i]);
        }
    }
    
    function checkWhitelisted(address _wallet) public view returns (bool){
        return whitelist[_wallet];
    }
    
}
















contract TrustedRole is Ownable {
    using Roles for Roles.Role;

    event TrustedAdded(address indexed account);
    event TrustedRemoved(address indexed account);

    Roles.Role private trusted;

    constructor() internal {
        _addTrusted(msg.sender);
    }

    modifier onlyOwnerOrTrusted() {
        require(isOwner() || isTrusted(msg.sender), "Only owner or trusted allowed");
        _;
    }

    modifier onlyTrusted() {
        require(isTrusted(msg.sender), "Only trusted allowed");
        _;
    }

    function isTrusted(address account) public view returns (bool) {
        return trusted.has(account);
    }

    function addTrusted(address account) public onlyOwner {
        _addTrusted(account);
    }

    function removeTrusted(address account) public onlyOwner {
        _removeTrusted(account);
    }

    function _addTrusted(address account) internal {
        trusted.add(account);
        emit TrustedAdded(account);
    }

    function _removeTrusted(address account) internal {
        trusted.remove(account);
        emit TrustedRemoved(account);
    }
}


 
contract MultiTokenDividend is Ownable, TrustedRole {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    struct Account {
        address tokenAddress;
        uint256 amount;
        uint256 lastTotalDividendPoints;
    }
    mapping(address => Account) public accounts;

     
    struct Dividend {
        uint256 totalDividendPoints;
        uint256 unclaimedDividends;
        uint256 totalSupply;
    }
    mapping(address => Dividend) public tokenDividends;

     
    ERC20Detailed private _sharesToken;

     
    uint256 private X;

     
    event TransferFailure(address indexed beneficiary);

    constructor(ERC20Detailed token, uint256 const) public {
        _sharesToken = token;
        X = const;
    }

     
    modifier onlyToken() {
        require(msg.sender == address(_sharesToken), "Only the token allowed");
        _;
    }

     
    function() external payable {}
    function collect(address tokenAddress) public onlyOwner {
        if (tokenAddress == address(0)) {
            address(uint160(owner())).transfer(address(this).balance);
        }
        else {
            IERC20 token = IERC20(tokenAddress);
            token.safeTransfer(owner(), token.balanceOf(address(this)));
        }
    }

    function setPaymentMethod(address beneficiary, address tokenAddress) public onlyOwnerOrTrusted {
         
        updateAccount(beneficiary);
        require(accounts[beneficiary].amount == 0, "Withdraw the balance before changing payout token");

         
        address oldToken = accounts[beneficiary].tokenAddress;
        accounts[beneficiary].tokenAddress = tokenAddress;
        accounts[beneficiary].lastTotalDividendPoints = tokenDividends[tokenAddress].totalDividendPoints;
        
         
        uint256 beneficiaryShares = _sharesToken.balanceOf(beneficiary);
        tokenDividends[oldToken].totalSupply = tokenDividends[oldToken].totalSupply.sub(beneficiaryShares);
        tokenDividends[tokenAddress].totalSupply = tokenDividends[tokenAddress].totalSupply.add(beneficiaryShares);
    }

    function dividendsOwing(address beneficiary) internal view returns(uint256) {
        Account storage account = accounts[beneficiary];
        uint256 newDividendPoints = tokenDividends[account.tokenAddress].totalDividendPoints.sub(account.lastTotalDividendPoints);
        return _sharesToken.balanceOf(beneficiary).mul(newDividendPoints).div(X);
    }

    function updateAccount(address account) public onlyOwnerOrTrusted {
        _updateAccount(account);
    }

    function _updateAccount(address account) internal {
        uint256 owing = dividendsOwing(account);
        Dividend storage dividend = tokenDividends[accounts[account].tokenAddress];
        if (owing > 0) {
            dividend.unclaimedDividends = dividend.unclaimedDividends.sub(owing);
            accounts[account].amount = accounts[account].amount.add(owing);
        }
         
        if (accounts[account].lastTotalDividendPoints != dividend.totalDividendPoints) {
            accounts[account].lastTotalDividendPoints = dividend.totalDividendPoints;
        }
    }

     
    function addDividends(address[] memory tokens) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenAmount = 0;
            
             
            if (token == address(0)) {
                 
                tokenAmount = address(this).balance;
            }
            else {
                 
                tokenAmount = IERC20(token).balanceOf(address(this));
            }

            Dividend storage dividend = tokenDividends[token];

             
            if (tokenAmount > dividend.unclaimedDividends) {
                tokenAmount = tokenAmount - dividend.unclaimedDividends;
                dividend.totalDividendPoints = dividend.totalDividendPoints.add(
                    tokenAmount.mul(X).div(dividend.totalSupply)
                );
                dividend.unclaimedDividends = dividend.unclaimedDividends.add(tokenAmount);
            }
        }
    }

     
     
    function disburse(address payable[] calldata beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            address payable acc = beneficiaries[i];
            updateAccount(acc);

            bool success = _disburse(acc);
            if (!success) {
                emit TransferFailure(acc);
            }
        }
    }

    function withdraw() public {
        _updateAccount(msg.sender);
        require(_disburse(msg.sender), "Failed to transfer ETH");
    }

    function _disburse(address payable beneficiary) internal returns (bool) {
        Account storage account = accounts[beneficiary];
        uint256 amount = account.amount;
        if (amount == 0) return true;
        
         
        account.amount = 0;

        if (account.tokenAddress == address(0)) {
             
            bool success = beneficiary.send(amount);
            if (!success) {
                account.amount = amount;
            }
            return success;
        }
        else {
             
            IERC20 token = IERC20(account.tokenAddress);
            token.safeTransfer(beneficiary, amount);
            return true;
        }
    }

     
    function _registerBurn(address from, uint256 amount) public onlyToken {
        _updateAccount(from);
        Dividend storage tokenDividend = tokenDividends[accounts[from].tokenAddress];
        tokenDividend.totalSupply = tokenDividend.totalSupply.sub(amount);
    }
    function _registerMint(address to, uint256 amount) public onlyToken {
        _updateAccount(to);
        Dividend storage tokenDividend = tokenDividends[accounts[to].tokenAddress];
        tokenDividend.totalSupply = tokenDividend.totalSupply.add(amount);
    }
    function _registerTransfer(address from, address to, uint256 amount) public onlyToken {
        _updateAccount(from);
        _updateAccount(to);
        if (accounts[from].tokenAddress != accounts[to].tokenAddress) {
            Dividend storage fromDividend = tokenDividends[accounts[from].tokenAddress];
            fromDividend.totalSupply = fromDividend.totalSupply.sub(amount);
            
            Dividend storage toDividend = tokenDividends[accounts[to].tokenAddress];
            toDividend.totalSupply = toDividend.totalSupply.add(amount);
        }
    }
}


contract ERC20MultiDividend is Ownable, ERC20 {
    MultiTokenDividend internal _dividend;

    constructor() internal {}

    function setDividendContract(MultiTokenDividend dividend) external onlyOwner {
        _dividend = dividend;
    }

     
    function _burn(address account, uint256 value) internal {
        _dividend._registerBurn(account, value);
        super._burn(account, value);
    }
    function _mint(address account, uint256 value) internal {
        _dividend._registerMint(account, value);
        super._mint(account, value);
    }
    function _transfer(address from, address to, uint256 value) internal {
        _dividend._registerTransfer(from, to, value);
        super._transfer(from, to, value);
    }
}

contract ReitBZ is Ownable, ERC20MultiDividend, ERC20Burnable, ERC20Mintable, ERC20Pausable, ERC20Detailed {

    TokenWhitelist public whitelist;

    constructor() public
    ERC20Detailed("ReitBZ", "RBZ", 18) {
        whitelist = new TokenWhitelist();
    }

     
     
    function transferOwnership(address newOwner) public onlyOwner {
        super.transferOwnership(newOwner);
        _addMinter(newOwner);
        _removeMinter(msg.sender);
        _addPauser(newOwner);
        _removePauser(msg.sender);
    }

    function addToWhitelistBatch(address[] calldata wallets) external onlyOwner {
        whitelist.enableWalletBatch(wallets);
    }

    function addToWhitelist(address wallet) public onlyOwner {
        whitelist.enableWallet(wallet);
    }

    function removeFromWhitelist(address wallet) public onlyOwner {
        whitelist.disableWallet(wallet);
    }

    function removeFromWhitelistBatch(address[] calldata wallets) external onlyOwner {
        whitelist.disableWalletBatch(wallets);
    }

    function checkWhitelisted(address wallet) public view returns (bool) {
        return whitelist.checkWhitelisted(wallet);
    }

     

    function burn(uint256 value) public onlyOwner {
        super.burn(value);
    }

    function burnFrom(address from, uint256 value) public onlyOwner {
        _burn(from, value);
    }

     

    function mint(address to, uint256 value) public returns (bool) {
        require(whitelist.checkWhitelisted(to), "Receiver is not whitelisted.");
        return super.mint(to, value);
    }

     

    function transfer(address to, uint256 value) public returns (bool) {
        require(whitelist.checkWhitelisted(msg.sender), "Sender is not whitelisted.");
        require(whitelist.checkWhitelisted(to), "Receiver is not whitelisted.");
        return super.transfer(to, value);
    }

    function transferFrom(address from,address to, uint256 value) public returns (bool) {
        require(whitelist.checkWhitelisted(msg.sender), "Transaction sender is not whitelisted.");
        require(whitelist.checkWhitelisted(from), "Token sender is not whitelisted.");
        require(whitelist.checkWhitelisted(to), "Receiver is not whitelisted.");
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(whitelist.checkWhitelisted(msg.sender), "Sender is not whitelisted.");
        require(whitelist.checkWhitelisted(spender), "Spender is not whitelisted.");
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public returns (bool success) {
        require(whitelist.checkWhitelisted(msg.sender), "Sender is not whitelisted.");
        require(whitelist.checkWhitelisted(spender), "Spender is not whitelisted.");
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool success) {
        require(whitelist.checkWhitelisted(msg.sender), "Sender is not whitelisted.");
        require(whitelist.checkWhitelisted(spender), "Spender is not whitelisted.");
        return super.decreaseAllowance(spender, subtractedValue);
    }

}