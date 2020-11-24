 

pragma solidity ^0.4.25;

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

   
  function name() public view returns(string) {
    return _name;
  }

   
  function symbol() public view returns(string) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
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

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
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

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
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

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

 

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

 

 
contract ERC20Mintable is ERC20, MinterRole {
   
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}

 

 
contract ERC20Capped is ERC20Mintable {

  uint256 private _cap;

  constructor(uint256 cap)
    public
  {
    require(cap > 0);
    _cap = cap;
  }

   
  function cap() public view returns(uint256) {
    return _cap;
  }

  function _mint(address account, uint256 value) internal {
    require(totalSupply().add(value) <= _cap);
    super._mint(account, value);
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

 

 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

 

 
library ERC165Checker {
   
  bytes4 private constant _InterfaceId_Invalid = 0xffffffff;

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  function _supportsERC165(address account)
    internal
    view
    returns (bool)
  {
     
     
    return _supportsERC165Interface(account, _InterfaceId_ERC165) &&
      !_supportsERC165Interface(account, _InterfaceId_Invalid);
  }

   
  function _supportsInterface(address account, bytes4 interfaceId)
    internal
    view
    returns (bool)
  {
     
    return _supportsERC165(account) &&
      _supportsERC165Interface(account, interfaceId);
  }

   
  function _supportsAllInterfaces(address account, bytes4[] interfaceIds)
    internal
    view
    returns (bool)
  {
     
    if (!_supportsERC165(account)) {
      return false;
    }

     
    for (uint256 i = 0; i < interfaceIds.length; i++) {
      if (!_supportsERC165Interface(account, interfaceIds[i])) {
        return false;
      }
    }

     
    return true;
  }

   
  function _supportsERC165Interface(address account, bytes4 interfaceId)
    private
    view
    returns (bool)
  {
     
     
    (bool success, bool result) = _callERC165SupportsInterface(
      account, interfaceId);

    return (success && result);
  }

   
  function _callERC165SupportsInterface(
    address account,
    bytes4 interfaceId
  )
    private
    view
    returns (bool success, bool result)
  {
    bytes memory encodedParams = abi.encodeWithSelector(
      _InterfaceId_ERC165,
      interfaceId
    );

     
    assembly {
      let encodedParams_data := add(0x20, encodedParams)
      let encodedParams_size := mload(encodedParams)

      let output := mload(0x40)   
      mstore(output, 0x0)

      success := staticcall(
        30000,                  
        account,               
        encodedParams_data,
        encodedParams_size,
        output,
        0x20                    
      )

      result := mload(output)   
    }
  }
}

 

 
interface IERC165 {

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

 

 
contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) private _supportedInterfaces;

   
  constructor()
    internal
  {
    _registerInterface(_InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

   
  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

 

 
contract IERC1363 is IERC20, ERC165 {
   

   

   
  function transferAndCall(address to, uint256 value) public returns (bool);

   
  function transferAndCall(address to, uint256 value, bytes data) public returns (bool);  

   
  function transferFromAndCall(address from, address to, uint256 value) public returns (bool);  


   
  function transferFromAndCall(address from, address to, uint256 value, bytes data) public returns (bool);  

   
  function approveAndCall(address spender, uint256 value) public returns (bool);  

   
  function approveAndCall(address spender, uint256 value, bytes data) public returns (bool);  
}

 

 
contract IERC1363Receiver {
   

   
  function onTransferReceived(address operator, address from, uint256 value, bytes data) external returns (bytes4);  
}

 

 
contract IERC1363Spender {
   

   
  function onApprovalReceived(address owner, uint256 value, bytes data) external returns (bytes4);  
}

 

 
contract ERC1363 is ERC20, IERC1363 {  
  using Address for address;

   
  bytes4 internal constant _InterfaceId_ERC1363Transfer = 0x4bbee2df;

   
  bytes4 internal constant _InterfaceId_ERC1363Approve = 0xfb9ec8ce;

   
   
  bytes4 private constant _ERC1363_RECEIVED = 0x88a7ca5c;

   
   
  bytes4 private constant _ERC1363_APPROVED = 0x7b04a2d0;

  constructor() public {
     
    _registerInterface(_InterfaceId_ERC1363Transfer);
    _registerInterface(_InterfaceId_ERC1363Approve);
  }

  function transferAndCall(
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    return transferAndCall(to, value, "");
  }

  function transferAndCall(
    address to,
    uint256 value,
    bytes data
  )
    public
    returns (bool)
  {
    require(transfer(to, value));
    require(
      _checkAndCallTransfer(
        msg.sender,
        to,
        value,
        data
      )
    );
    return true;
  }

  function transferFromAndCall(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
     
    return transferFromAndCall(from, to, value, "");
  }

  function transferFromAndCall(
    address from,
    address to,
    uint256 value,
    bytes data
  )
    public
    returns (bool)
  {
    require(transferFrom(from, to, value));
    require(
      _checkAndCallTransfer(
        from,
        to,
        value,
        data
      )
    );
    return true;
  }

  function approveAndCall(
    address spender,
    uint256 value
  )
    public
    returns (bool)
  {
    return approveAndCall(spender, value, "");
  }

  function approveAndCall(
    address spender,
    uint256 value,
    bytes data
  )
    public
    returns (bool)
  {
    approve(spender, value);
    require(
      _checkAndCallApprove(
        spender,
        value,
        data
      )
    );
    return true;
  }

   
  function _checkAndCallTransfer(
    address from,
    address to,
    uint256 value,
    bytes data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return false;
    }
    bytes4 retval = IERC1363Receiver(to).onTransferReceived(
      msg.sender, from, value, data
    );
    return (retval == _ERC1363_RECEIVED);
  }

   
  function _checkAndCallApprove(
    address spender,
    uint256 value,
    bytes data
  )
    internal
    returns (bool)
  {
    if (!spender.isContract()) {
      return false;
    }
    bytes4 retval = IERC1363Spender(spender).onApprovalReceived(
      msg.sender, value, data
    );
    return (retval == _ERC1363_APPROVED);
  }
}

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
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

 

 
contract TokenRecover is Ownable {

   
  function recoverERC20(
    address tokenAddress,
    uint256 tokenAmount
  )
    public
    onlyOwner
  {
    IERC20(tokenAddress).transfer(owner(), tokenAmount);
  }
}

 

contract OperatorRole {
  using Roles for Roles.Role;

  event OperatorAdded(address indexed account);
  event OperatorRemoved(address indexed account);

  Roles.Role private _operators;

  constructor() internal {
    _addOperator(msg.sender);
  }

  modifier onlyOperator() {
    require(isOperator(msg.sender));
    _;
  }

  function isOperator(address account) public view returns (bool) {
    return _operators.has(account);
  }

  function addOperator(address account) public onlyOperator {
    _addOperator(account);
  }

  function renounceOperator() public {
    _removeOperator(msg.sender);
  }

  function _addOperator(address account) internal {
    _operators.add(account);
    emit OperatorAdded(account);
  }

  function _removeOperator(address account) internal {
    _operators.remove(account);
    emit OperatorRemoved(account);
  }
}

 

 
contract BaseToken is ERC20Detailed, ERC20Capped, ERC20Burnable, ERC1363, OperatorRole, TokenRecover {

  event MintFinished();
  event TransferEnabled();

   
  bool private _mintingFinished = false;

   
  bool private _transferEnabled = false;

   
  modifier canMint() {
    require(!_mintingFinished);
    _;
  }

   
  modifier canTransfer(address from) {
    require(_transferEnabled || isOperator(from));
    _;
  }

   
  constructor(
    string name,
    string symbol,
    uint8 decimals,
    uint256 cap,
    uint256 initialSupply
  )
    ERC20Detailed(name, symbol, decimals)
    ERC20Capped(cap)
    public
  {
    if (initialSupply > 0) {
      _mint(owner(), initialSupply);
    }
  }

   
  function mintingFinished() public view returns (bool) {
    return _mintingFinished;
  }

   
  function transferEnabled() public view returns (bool) {
    return _transferEnabled;
  }

  function mint(address to, uint256 value) public canMint returns (bool) {
    return super.mint(to, value);
  }

  function transfer(address to, uint256 value) public canTransfer(msg.sender) returns (bool) {
    return super.transfer(to, value);
  }

  function transferFrom(address from, address to, uint256 value) public canTransfer(from) returns (bool) {
    return super.transferFrom(from, to, value);
  }

   
  function finishMinting() public onlyOwner canMint {
    _mintingFinished = true;
    _transferEnabled = true;

    emit MintFinished();
    emit TransferEnabled();
  }

   
  function enableTransfer() public onlyOwner {
    _transferEnabled = true;

    emit TransferEnabled();
  }

   
  function removeOperator(address account) public onlyOwner {
    _removeOperator(account);
  }

   
  function removeMinter(address account) public onlyOwner {
    _removeMinter(account);
  }
}

 

 
contract ShakaToken is BaseToken {

   
  constructor(
    string name,
    string symbol,
    uint8 decimals,
    uint256 cap,
    uint256 initialSupply
  )
    BaseToken(
      name,
      symbol,
      decimals,
      cap,
      initialSupply
    )
    public
  {}
}