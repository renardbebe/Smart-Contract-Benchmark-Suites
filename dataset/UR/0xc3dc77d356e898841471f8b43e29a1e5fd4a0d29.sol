 

pragma solidity 0.5.11;
 

 
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

    function removeWhitelistAdmin(address account) public onlyWhitelistAdmin{
        _removeWhitelistAdmin(account);
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

contract BlackListedRole is WhitelistAdminRole{
    using Roles for Roles.Role;
    
    event BlacklistedAdded(address indexed account);
    event BlacklistedRemoved(address indexed account);

    Roles.Role private _blacklisteds;

    modifier onlyNotBlacklisted() {
        require(!isBlackListed(msg.sender),'You are Blacklisted');
        _;
    }
    
    modifier onlyBlackListed(address account){
        require(isBlackListed(account), 'Account is not Blacklisted');
        _;
    }
    function isBlackListed(address account) public view returns(bool) {
        return _blacklisteds.has(account);
    }

    function addBlacklisted(address account) public onlyWhitelistAdmin{
        _addBlacklisted(account);
    }

    function removeBlacklisted(address account) public onlyWhitelistAdmin{
        _removeBlacklisted(account);
    }

    function _addBlacklisted(address account) internal {
        _blacklisteds.add(account);
        emit BlacklistedAdded(account);
    }

    function _removeBlacklisted(address account) internal{
        _blacklisteds.remove(account);
        emit BlacklistedRemoved(account);
    }
}

contract Pausable is WhitelistAdminRole {
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
        require(!_paused,'Contract is Paused');
        _;
    }

     
    modifier whenPaused() {
        require(_paused,'Contract is not Paused');
        _;
    }

     
    function pause() public onlyWhitelistAdmin whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyWhitelistAdmin whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}




interface IERC20 {
  function totalSupply() external view returns (uint256);  
  function balanceOf(address account) external view returns (uint256);  
  function transfer(address recipient, uint256 amount) external returns (bool); 
  function allowance(address owner, address spender) external view returns (uint256); 
  function approve(address spender, uint256 amount) external returns (bool); 
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); 
  event Transfer(address indexed from, address indexed to, uint256 value); 
  event Approval(address indexed owner, address indexed spender, uint256 value); 
}
 
contract ERC20 is IERC20, WhitelistAdminRole,BlackListedRole,Pausable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;
    uint public _basisPointsRate = 0;
    uint public _maximumFee = 0;
    address internal _feeWallet;
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
     
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public onlyNotBlacklisted onlyPayloadSize(2 * 32) returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public onlyNotBlacklisted returns (bool) {
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

     
    function _transfer(address from, address to, uint256 value) internal  {
        require(to != address(0));
        uint256 fee = (value.mul(_basisPointsRate)).div(1000);
        if (fee > _maximumFee){
            fee = _maximumFee;
        }
        uint256 sendAmount = value.sub(fee);

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(sendAmount);
        if (fee > 0 ){
             _balances[_feeWallet] = _balances[_feeWallet].add(fee);
            emit Transfer(from, _feeWallet, fee);
        }
        emit Transfer(from, to, sendAmount);
    }


     
    function _mint(address account, uint256 value) internal onlyWhitelistAdmin whenNotPaused{
        require(account != address(0));
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal onlyBlackListed(account) onlyWhitelistAdmin {
        require(account != address(0));
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
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

contract BRLSToken is ERC20, ERC20Detailed {
    event FeeParams(uint256 feeBasisPoints, uint256 maxFee);

    uint8 public constant DECIMALS = 2;
    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(DECIMALS));

     
    constructor () public ERC20Detailed("Brazilian Real Stable", "BRLS", DECIMALS) {
        
    }

    function mint(address account, uint256 value) public{
        _mint(account,value);
    }

    function burn(address account, uint256 value) public{
        _burn(account, value);
    }

    function setFeeParams(uint newBasisPoints, uint newMaxFee) public onlyWhitelistAdmin{
      require(newBasisPoints < 20,"Exceeded Max BasisPoint");
      require(newMaxFee < 50,"Exceeded MaxFee");
      _basisPointsRate = newBasisPoints;
      _maximumFee = newMaxFee.mul(10 ** uint256(DECIMALS));
      emit FeeParams(_basisPointsRate, _maximumFee);
    }

    function setFeeWallet(address account) public onlyWhitelistAdmin{
        _feeWallet = account;
    }
}