 

pragma solidity ^0.4.24;


 
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

interface SimpleDatabaseInterface {
  function set(string variable, address value) external returns (bool);
  function get(string variable) external view returns (address);
}

library QueryDB {
  function getAddress(address _db, string _name) internal view returns (address) {
    return SimpleDatabaseInterface(_db).get(_name);
  }
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

library ECDSA {
     
    function recover(bytes32 hash, bytes signature) internal pure returns (address) {
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

interface TokenInterface {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
}

contract Redeemer is Ownable {
  using SafeMath for uint256;
  using QueryDB for address;

   
  struct Code {
    address user;
    uint256 value;
    uint256 unlockTimestamp;
    uint256 entropy;
    bytes signature;
    bool deactivated;
    uint256 velocity;
  }

  address public DB;
  address[] public SIGNERS;

  mapping(bytes32 => Code) public codes;

  event AddSigner(address indexed owner, address signer);
  event RemoveSigner(address indexed owner, address signer);
  event RevokeAllToken(address indexed owner, address recipient, uint256 value);
  event SupportUser(address indexed owner, address indexed user, uint256 value, uint256 unlockTimestamp, uint256 entropy, bytes signature, uint256 velocity);
  event DeactivateCode(address indexed owner, address indexed user, uint256 value, uint256 unlockTimestamp, uint256 entropy, bytes signature);
  event Redeem(address indexed user, uint256 value, uint256 unlockTimestamp, uint256 entropy, bytes signature, uint256 velocity);

   
  constructor (address _db) public {
    DB = _db;
    SIGNERS = [msg.sender];
  }


   
  modifier isValidCode(Code _code) {
    bytes32 _hash = hash(_code);
    require(!codes[_hash].deactivated, "Deactivated code.");
    require(now >= _code.unlockTimestamp, "Lock time is not over.");
    require(validateSignature(_hash, _code.signature), "Invalid signer.");
    _;
  }

  modifier isValidCodeOwner(address _codeOwner) {
    require(_codeOwner != address(0), "Invalid sender.");
    require(msg.sender == _codeOwner, "Invalid sender.");
    _;
  }

  modifier isValidBalance(uint256 _value) {
    require(_value <= myBalance(), "Not enough balance.");
    _;
  }

  modifier isValidAddress(address _who) {
    require(_who != address(0), "Invalid address.");
    _;
  }


   
  
   
  function hash(Code _code) private pure returns (bytes32) {
    return keccak256(abi.encode(_code.user, _code.value, _code.unlockTimestamp, _code.entropy));
  }

   
  function validateSignature(bytes32 _hash, bytes _signature) private view returns (bool) {
    address _signer = ECDSA.recover(_hash, _signature);
    return signerExists(_signer);
  }

   
  function transferKAT(address _to, uint256 _value) private returns (bool) {
    bool ok = TokenInterface(DB.getAddress("TOKEN")).transfer(_to, _value);
    if(!ok) return false;
    return true;    
  }


   

   
  function myBalance() public view returns (uint256) {
     return TokenInterface(DB.getAddress("TOKEN")).balanceOf(address(this));
  }
  
   
  function signerExists(address _signer) public view returns (bool) {
    if(_signer == address(0)) return false;
    for(uint256 i = 0; i < SIGNERS.length; i++) {
      if(_signer == SIGNERS[i]) return true;
    }
    return false;
  }

   
  function addSigner(address _signer) public onlyOwner isValidAddress(_signer) returns (bool) {
    if(signerExists(_signer)) return true;
    SIGNERS.push(_signer);
    emit AddSigner(msg.sender, _signer);
    return true;
  }

   
  function removeSigner(address _signer) public onlyOwner isValidAddress(_signer) returns (bool) {
    for(uint256 i = 0; i < SIGNERS.length; i++) {
      if(_signer == SIGNERS[i]) {
        SIGNERS[i] = SIGNERS[SIGNERS.length - 1];
        delete SIGNERS[SIGNERS.length - 1];
        emit RemoveSigner(msg.sender, _signer);
        return true;
      }
    }
    return true;
  }

   
  function revokeAllToken(address _recipient) public onlyOwner returns (bool) {
    uint256 _value = myBalance();
    emit RevokeAllToken(msg.sender, _recipient, _value);
    return transferKAT(_recipient, _value);
  }

   
  function supportUser(
    address _user,
    uint256 _value,
    uint256 _unlockTimestamp,
    uint256 _entropy,
    bytes _signature
  )
    public
    onlyOwner
    isValidCode(Code(_user, _value, _unlockTimestamp, _entropy, _signature, false, 0))
    returns (bool)
  {
    uint256 _velocity = now - _unlockTimestamp;
    Code memory _code = Code(_user, _value, _unlockTimestamp, _entropy, _signature, true, _velocity);
    bytes32 _hash = hash(_code);
    codes[_hash] = _code;
    emit SupportUser(msg.sender, _code.user, _code.value, _code.unlockTimestamp, _code.entropy, _code.signature, _code.velocity);
    return transferKAT(_code.user, _code.value);
  }

   
  function deactivateCode(
    address _user,
    uint256 _value,
    uint256 _unlockTimestamp,
    uint256 _entropy,
    bytes _signature
  ) 
    public
    onlyOwner
    returns (bool)
  {
    Code memory _code = Code(_user, _value, _unlockTimestamp, _entropy, _signature, true, 0);
    bytes32 _hash = hash(_code);
    codes[_hash] = _code;
    emit DeactivateCode(msg.sender, _code.user, _code.value, _code.unlockTimestamp, _code.entropy, _code.signature);
    return true;
  }

   
  
   
  function redeem(
    address _user,
    uint256 _value,
    uint256 _unlockTimestamp,
    uint256 _entropy,
    bytes _signature
  )
    public
    isValidBalance(_value)
    isValidCodeOwner(_user)
    isValidCode(Code(_user, _value, _unlockTimestamp, _entropy, _signature, false, 0))
    returns (bool)
  {
    uint256 _velocity = now - _unlockTimestamp;
    Code memory _code = Code(_user, _value, _unlockTimestamp, _entropy, _signature, true, _velocity);
    bytes32 _hash = hash(_code);
    codes[_hash] = _code;
    emit Redeem(_code.user, _code.value, _code.unlockTimestamp, _code.entropy, _code.signature, _code.velocity);
    return transferKAT(_code.user, _code.value);
  }
}