 

 

pragma solidity ^0.4.24;

 
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

 

pragma solidity ^0.4.24;

 
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

 

pragma solidity ^0.4.24;



 
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

 

pragma solidity ^0.4.24;


 
contract ERC20Burnable is ERC20 {

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

 

pragma solidity ^0.4.24;

 
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

 

pragma solidity ^0.4.24;


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

 

pragma solidity ^0.4.24;



 
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

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.24;

 
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

 

pragma solidity 0.4.24;



contract ERC677 is ERC20 {
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    function transferAndCall(address, uint, bytes) external returns (bool);

}

 

pragma solidity 0.4.24;



contract IBurnableMintableERC677Token is ERC677 {
    function mint(address, uint256) public returns (bool);
    function burn(uint256 _value) public;
    function claimTokens(address _token, address _to) public;
}

 

pragma solidity 0.4.24;


contract ERC865 is ERC20 {
    mapping(bytes32 => bool) hashedTxs;

    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event TransferAndCallPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, bytes data, uint256 fee);

     
    function transferPreSigned(bytes _signature, address _to, uint256 _value, uint256 _fee, uint256 _timestamp) public returns (bool);

     
    function transferAndCallPreSigned(bytes _signature, address _to, uint256 _value, bytes _data, uint256 _fee, uint256 _timestamp) public returns (bool);

     
    function getTransferPreSignedHash(address _token, address _to, uint256 _value, uint256 _fee, uint256 _timestamp) public pure returns (bytes32);

     
    function getTransferAndCallPreSignedHash(address _token, address _to, uint256 _value, bytes _data, uint256 _fee, uint256 _timestamp) public pure returns (bytes32);
}

 

pragma solidity 0.4.24;


contract ERC677Receiver {
  function onTokenTransfer(address _from, uint _value, bytes _data) external returns(bool);
}

 

pragma solidity 0.4.24;

interface IBridgeValidators {
    function initialize(uint256 _requiredSignatures, address[] _initialValidators, address _owner) public returns(bool);
    function isValidator(address _validator) public view returns(bool);
    function requiredSignatures() public view returns(uint256);
    function owner() public view returns(address);
}

 

pragma solidity 0.4.24;

interface IForeignBridgeValidators {
    function isValidator(address _validator) public view returns(bool);
    function requiredSignatures() public view returns(uint256);
    function setValidators(address[] _validators) public returns(bool);
}

 

pragma solidity 0.4.24;




library Message {
    function addressArrayContains(address[] array, address value) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }
     
     
     
     
     
     

     
     
     
     
     
     
     
     
     
     
    function parseMessage(bytes message)
        internal
        pure
        returns(address recipient, uint256 amount, bytes32 txHash, address contractAddress)
    {
        require(isMessageValid(message));
        assembly {
            recipient := and(mload(add(message, 20)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            amount := mload(add(message, 52))
            txHash := mload(add(message, 84))
            contractAddress := mload(add(message, 104))
        }
    }

    function parseNewSetMessage(bytes message)
        internal
        returns(address[] memory newSet, bytes32 txHash, address contractAddress)
    {
        uint256 msgLength;
        uint256 position;
        address newSetMember;
        assembly {
            msgLength := mload(message)
            txHash := mload(add(message, 32))
            contractAddress := mload(add(message, 52))
            position := 72
        }
        uint256 newSetLength = (msgLength - position) / 20 + 1;
        newSet = new address[](newSetLength);
        uint256 i = 0;
        while (position <= msgLength) {
            assembly {
                newSetMember := mload(add(message, position))
            }
            newSet[i] = newSetMember;
            position += 20;
            i++;
        }
        return (newSet, txHash, contractAddress);
    }

    function isMessageValid(bytes _msg) internal pure returns(bool) {
        return _msg.length == requiredMessageLength();
    }

    function requiredMessageLength() internal pure returns(uint256) {
        return 104;
    }

    function recoverAddressFromSignedMessage(bytes signature, bytes message, bool knownLength) internal pure returns (address) {
        require(signature.length == 65);
        bytes32 r;
        bytes32 s;
        bytes1 v;
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := mload(add(signature, 0x60))
        }
        if (knownLength) {
            return ecrecover(hashMessage(message), uint8(v), r, s);
        } else {
            return ecrecover(hashMessageOfUnknownLength(message), uint8(v), r, s);
        }
    }

    function hashMessage(bytes message) internal pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
         
        string memory msgLength = "104";
        return keccak256(abi.encodePacked(prefix, msgLength, message));
    }

    function hashMessageOfUnknownLength(bytes message) internal pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        uint256 lengthOffset;
        uint256 length;
        assembly {
           
          length := mload(message)
           
          lengthOffset := add(prefix, 57)
        }
        uint256 lengthLength = 0;
         
        uint256 divisor = 100000;
         
        while (divisor != 0) {
           
          uint256 digit = length / divisor;
          if (digit == 0) {
             
            if (lengthLength == 0) {
              divisor /= 10;
              continue;
            }
          }
           
          lengthLength++;
           
          length -= digit * divisor;
           
          divisor /= 10;
           
          digit += 0x30;
           
          lengthOffset++;
          assembly {
            mstore8(lengthOffset, digit)
          }
        }
         
        if (lengthLength == 0) {
          lengthLength = 1 + 0x19 + 1;
        } else {
          lengthLength += 1 + 0x19;
        }
         
        assembly {
          mstore(prefix, lengthLength)
        }
        return keccak256(prefix, message);
    }

    function hasEnoughValidSignatures(
        bytes _message,
        uint8[] _vs,
        bytes32[] _rs,
        bytes32[] _ss,
        IBridgeValidators _validatorContract) internal view
    {
        uint256 requiredSignatures = _validatorContract.requiredSignatures();
        require(_vs.length >= requiredSignatures);
        bytes32 hash = hashMessage(_message);
        address[] memory encounteredAddresses = new address[](requiredSignatures);

        for (uint256 i = 0; i < requiredSignatures; i++) {
            address recoveredAddress = ecrecover(hash, _vs[i], _rs[i], _ss[i]);
            require(_validatorContract.isValidator(recoveredAddress));
            if (addressArrayContains(encounteredAddresses, recoveredAddress)) {
                revert();
            }
            encounteredAddresses[i] = recoveredAddress;
        }
    }

    function hasEnoughValidSignaturesForeignBridgeValidator(
        bytes _message,
        uint8[] _vs,
        bytes32[] _rs,
        bytes32[] _ss,
        IForeignBridgeValidators _validatorContract) internal view
    {
        uint256 requiredSignatures = _validatorContract.requiredSignatures();
        require(_vs.length >= requiredSignatures);
        bytes32 hash = hashMessage(_message);
        address[] memory encounteredAddresses = new address[](requiredSignatures);

        for (uint256 i = 0; i < requiredSignatures; i++) {
            address recoveredAddress = ecrecover(hash, _vs[i], _rs[i], _ss[i]);
            require(_validatorContract.isValidator(recoveredAddress));
            if (addressArrayContains(encounteredAddresses, recoveredAddress)) {
                revert();
            }
            encounteredAddresses[i] = recoveredAddress;
        }
    }

    function hasEnoughValidNewSetSignaturesForeignBridgeValidator(
        bytes _message,
        uint8[] _vs,
        bytes32[] _rs,
        bytes32[] _ss,
        IForeignBridgeValidators _validatorContract) internal view
    {
        uint256 requiredSignatures = _validatorContract.requiredSignatures();
        require(_vs.length >= requiredSignatures);
        bytes32 hash = hashMessageOfUnknownLength(_message);
        address[] memory encounteredAddresses = new address[](requiredSignatures);

        for (uint256 i = 0; i < requiredSignatures; i++) {
            address recoveredAddress = ecrecover(hash, _vs[i], _rs[i], _ss[i]);
            require(_validatorContract.isValidator(recoveredAddress));
            if (addressArrayContains(encounteredAddresses, recoveredAddress)) {
                revert();
            }
            encounteredAddresses[i] = recoveredAddress;
        }
    }

    function recover(bytes32 hash, bytes sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (sig.length != 65) {
          return (address(0));
        }

         
        assembly {
          r := mload(add(sig, 32))
          s := mload(add(sig, 64))
          v := byte(0, mload(add(sig, 96)))
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
}

 

pragma solidity ^0.4.24;

 
contract ITransferManager {
    function verifyTransfer(address _from, address _to, uint256 _amount) public view returns(bool);
}

 

pragma solidity 0.4.24;

interface IRestrictedToken {
    event TransferManagerSet(address transferManager);
    
    function setTransferManager(address _transferManager) external;
    function verifyTransfer(address _from, address _to, uint256 _value) external view;
}

 

pragma solidity 0.4.24;











contract ERC677BridgeToken is
    IBurnableMintableERC677Token,
    IRestrictedToken,
    ERC20Detailed,
    ERC20Burnable,
    ERC20Mintable,
    Ownable,
    ERC865 {

    address public bridgeContract;
    ITransferManager public transferManager;

    event ContractFallbackCallFailed(address from, address to, uint value);

    constructor(
        string _name,
        string _symbol,
        uint8 _decimals)
    public ERC20Detailed(_name, _symbol, _decimals) {}

    function setBridgeContract(address _bridgeContract) onlyMinter public {
        require(_bridgeContract != address(0) && isContract(_bridgeContract));
        bridgeContract = _bridgeContract;
    }

    function setTransferManager(address _transferManager) onlyOwner public {
        require(_transferManager != address(0) && isContract(_transferManager));
        transferManager = ITransferManager(_transferManager);

        emit TransferManagerSet(_transferManager);
    }

    modifier validRecipient(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this));
        _;
    }

    function verifyTransfer(address _from, address _to, uint256 _value) public view returns (bool) {
      if (transferManager != address(0)) {
        return transferManager.verifyTransfer(_from, _to, _value);
      } else {
        return true;
      }
    }

    function transferAndCall(address _to, uint _value, bytes _data)
        external validRecipient(_to) returns (bool)
    {
        require(superTransfer(_to, _value));
        emit Transfer(msg.sender, _to, _value, _data);

        if (isContract(_to)) {
            require(contractFallback(_to, _value, _data));
        }
        return true;
    }

    function getTokenInterfacesVersion() public pure returns(uint64 major, uint64 minor, uint64 patch) {
        return (3, 0, 0);
    }

    function superTransfer(address _to, uint256 _value) internal returns(bool)
    {
        require(verifyTransfer(msg.sender, _to, _value));
        return super.transfer(_to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool)
    {
        require(superTransfer(_to, _value));
        if (isContract(_to) && !contractFallback(_to, _value, new bytes(0))) {
            if (_to == bridgeContract) {
                revert();
            } else {
                emit ContractFallbackCallFailed(msg.sender, _to, _value);
            }
        }
        return true;
    }

    function contractFallback(address _to, uint _value, bytes _data)
        private
        returns(bool)
    {
        return _to.call(abi.encodeWithSignature("onTokenTransfer(address,uint256,bytes)",  msg.sender, _value, _data));
    }

    function isContract(address _addr)
        internal
        view
        returns (bool)
    {
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }

    function renounceOwnership() public onlyOwner {
        revert();
    }

     
    function claimTokens(address _token, address _to) public onlyOwner {
        require(_to != address(0));
        if (_token == address(0)) {
            _to.transfer(address(this).balance);
            return;
        }

        ERC20Detailed token = ERC20Detailed(_token);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(_to, balance));
    }

    function transferWithFee(address _sender, address _from, address _to, uint256 _value, uint256 _fee) internal returns(bool)
    {
        require(verifyTransfer(_from, _to, _value));
        require(verifyTransfer(_from, _sender, _fee));
        _transfer(_from, _to, _value);
        _transfer(_from, _sender, _fee);
        return true;
    }

    function contractFallbackFrom(address _from, address _to, uint _value, bytes _data) private returns(bool)
    {
        return _to.call(abi.encodeWithSignature("onTokenTransfer(address,uint256,bytes)",  _from, _value, _data));
    }

    function transferPreSigned(bytes _signature, address _to, uint256 _value, uint256 _fee, uint256 _timestamp) validRecipient(_to) public returns (bool) {
        bytes32 hashedParams = getTransferPreSignedHash(address(this), _to, _value, _fee, _timestamp);
        address from = Message.recover(hashedParams, _signature);
        require(from != address(0), "Invalid from address recovered");
        bytes32 hashedTx = keccak256(abi.encodePacked(from, hashedParams));
        require(hashedTxs[hashedTx] == false, "Transaction hash was already used");

        require(transferWithFee(msg.sender, from, _to, _value, _fee));
        hashedTxs[hashedTx] = true;
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);

        if (isContract(_to) && !contractFallbackFrom(from, _to, _value, new bytes(0))) {
            if (_to == bridgeContract) {
                revert();
            } else {
                emit ContractFallbackCallFailed(from, _to, _value);
            }
        }

        return true;
    }

    function getTransferPreSignedHash(address _token, address _to, uint256 _value, uint256 _fee, uint256 _timestamp) public pure returns (bytes32) {
         
        return keccak256(abi.encodePacked(bytes4(0x0d98dcb1), _token, _to, _value, _fee, _timestamp));
    }

    function transferAndCallPreSigned(bytes _signature, address _to, uint256 _value, bytes _data, uint256 _fee, uint256 _timestamp) validRecipient(_to) public returns (bool) {
        bytes32 hashedParams = getTransferAndCallPreSignedHash(address(this), _to, _value, _data, _fee, _timestamp);
        address from = Message.recover(hashedParams, _signature);
        require(from != address(0), "Invalid from address recovered");
        bytes32 hashedTx = keccak256(abi.encodePacked(from, hashedParams));
        require(hashedTxs[hashedTx] == false, "Transaction hash was already used");

        require(transferWithFee(msg.sender, from, _to, _value, _fee));
        hashedTxs[hashedTx] = true;
        emit TransferAndCallPreSigned(from, _to, msg.sender, _value, _data, _fee);

        if (isContract(_to)) {
            require(contractFallbackFrom(from, _to, _value, _data));
        }
        return true;
    }

    function getTransferAndCallPreSignedHash(address _token, address _to, uint256 _value, bytes _data, uint256 _fee, uint256 _timestamp) public pure returns (bytes32) {
         
        return keccak256(abi.encodePacked(bytes4(0xcabc0a10), _token, _to, _value, _data, _fee, _timestamp));
    }
}