 

pragma solidity ^0.4.25;

 

 
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

 

contract SignerRole {
  using Roles for Roles.Role;

  event SignerAdded(address indexed account);
  event SignerRemoved(address indexed account);

  Roles.Role private signers;

  constructor() internal {
    _addSigner(msg.sender);
  }

  modifier onlySigner() {
    require(isSigner(msg.sender));
    _;
  }

  function isSigner(address account) public view returns (bool) {
    return signers.has(account);
  }

  function addSigner(address account) public onlySigner {
    _addSigner(account);
  }

  function renounceSigner() public {
    _removeSigner(msg.sender);
  }

  function _addSigner(address account) internal {
    signers.add(account);
    emit SignerAdded(account);
  }

  function _removeSigner(address account) internal {
    signers.remove(account);
    emit SignerRemoved(account);
  }
}

 

 

library ECDSA {

   
  function recover(bytes32 hash, bytes signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (signature.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

 

 
contract SignatureBouncer is SignerRole {
  using ECDSA for bytes32;

   
   
  uint256 private constant _METHOD_ID_SIZE = 4;
   
  uint256 private constant _SIGNATURE_SIZE = 96;

  constructor() internal {}

   
  modifier onlyValidSignature(bytes signature)
  {
    require(_isValidSignature(msg.sender, signature));
    _;
  }

   
  modifier onlyValidSignatureAndMethod(bytes signature)
  {
    require(_isValidSignatureAndMethod(msg.sender, signature));
    _;
  }

   
  modifier onlyValidSignatureAndData(bytes signature)
  {
    require(_isValidSignatureAndData(msg.sender, signature));
    _;
  }

   
  function _isValidSignature(address account, bytes signature)
    internal
    view
    returns (bool)
  {
    return _isValidDataHash(
      keccak256(abi.encodePacked(address(this), account)),
      signature
    );
  }

   
  function _isValidSignatureAndMethod(address account, bytes signature)
    internal
    view
    returns (bool)
  {
    bytes memory data = new bytes(_METHOD_ID_SIZE);
    for (uint i = 0; i < data.length; i++) {
      data[i] = msg.data[i];
    }
    return _isValidDataHash(
      keccak256(abi.encodePacked(address(this), account, data)),
      signature
    );
  }

   
  function _isValidSignatureAndData(address account, bytes signature)
    internal
    view
    returns (bool)
  {
    require(msg.data.length > _SIGNATURE_SIZE);
    bytes memory data = new bytes(msg.data.length - _SIGNATURE_SIZE);
    for (uint i = 0; i < data.length; i++) {
      data[i] = msg.data[i];
    }
    return _isValidDataHash(
      keccak256(abi.encodePacked(address(this), account, data)),
      signature
    );
  }

   
  function _isValidDataHash(bytes32 hash, bytes signature)
    internal
    view
    returns (bool)
  {
    address signer = hash
      .toEthSignedMessageHash()
      .recover(signature);

    return signer != address(0) && isSigner(signer);
  }
}

 

 
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

 

 
contract ERC20Burnable is ERC20 {

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

 

 
library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
     
     
     
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
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

 

 
contract AbstractAmbix is Ownable {
    using SafeERC20 for ERC20Burnable;
    using SafeERC20 for ERC20;

    address[][] public A;
    uint256[][] public N;
    address[] public B;
    uint256[] public M;

     
    function appendSource(
        address[] _a,
        uint256[] _n
    ) external onlyOwner {
        uint256 i;

        require(_a.length == _n.length && _a.length > 0);

        for (i = 0; i < _a.length; ++i)
            require(_a[i] != 0);

        if (_n.length == 1 && _n[0] == 0) {
            require(B.length == 1);
        } else {
            for (i = 0; i < _n.length; ++i)
                require(_n[i] > 0);
        }

        A.push(_a);
        N.push(_n);
    }

     
    function setSink(
        address[] _b,
        uint256[] _m
    ) external onlyOwner{
        require(_b.length == _m.length);

        for (uint256 i = 0; i < _b.length; ++i)
            require(_b[i] != 0);

        B = _b;
        M = _m;
    }

    function _run(uint256 _ix) internal {
        require(_ix < A.length);
        uint256 i;

        if (N[_ix][0] > 0) {
             

             
            uint256 mux = ERC20(A[_ix][0]).allowance(msg.sender, this) / N[_ix][0];
            require(mux > 0);

             
            for (i = 0; i < A[_ix].length; ++i)
                ERC20Burnable(A[_ix][i]).burnFrom(msg.sender, mux * N[_ix][i]);

             
            for (i = 0; i < B.length; ++i)
                ERC20(B[i]).safeTransfer(msg.sender, M[i] * mux);

        } else {
             
             
             
             

             
            require(A[_ix].length == 1 && B.length == 1);

            ERC20Burnable source = ERC20Burnable(A[_ix][0]);
            ERC20 sink = ERC20(B[0]);

            uint256 scale = 10 ** 18 * sink.balanceOf(this) / source.totalSupply();

            uint256 allowance = source.allowance(msg.sender, this);
            require(allowance > 0);
            source.burnFrom(msg.sender, allowance);

            uint256 reward = scale * allowance / 10 ** 18;
            require(reward > 0);
            sink.safeTransfer(msg.sender, reward);
        }
    }
}

 

contract KycAmbix is AbstractAmbix, SignatureBouncer {
     
    function run(uint256 _ix, bytes _signature) external onlyValidSignature(_signature)
    { _run(_ix); }
}