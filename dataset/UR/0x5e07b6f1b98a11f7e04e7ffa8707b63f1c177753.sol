 

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

library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
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

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
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

contract MCHDailyActionV3 is Ownable, Pausable {

  address public validator;
  mapping(address => int64) public lastActionDate;

  event Action(
               address indexed user,
               int64 at
               );

  constructor(address _varidator) public {
    validator = _varidator;
  }

  function setValidater(address _varidator) external onlyOwner() {
    validator = _varidator;
  }

  function requestDailyActionReward(bytes calldata _signature, int64 _time) external whenNotPaused() {
    require(validateSig(msg.sender, _time, _signature), "invalid signature");
    int64 day = _time / 86400;
    require(lastActionDate[msg.sender] < day);
    lastActionDate[msg.sender] = day;
    emit Action(
                msg.sender,
                _time
                );
  }

  function validateSig(address _from, int64 _time, bytes memory _signature) public view returns (bool) {
    require(validator != address(0));
    address signer = recover(ethSignedMessageHash(encodeData(_from, _time)), _signature);
    return (signer == validator);
  }

  function encodeData(address _from, int64 _time) public pure returns (bytes32) {
    return keccak256(abi.encode(
                                _from,
                                _time
                                )
                     );
  }

  function ethSignedMessageHash(bytes32 _data) public pure returns (bytes32) {
    return ECDSA.toEthSignedMessageHash(_data);
  }

  function recover(bytes32 _data, bytes memory _signature) public pure returns (address) {
    return ECDSA.recover(_data, _signature);
  }
}