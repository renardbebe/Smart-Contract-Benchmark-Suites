 

pragma solidity ^0.4.24;

 

 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
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

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
  }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

 

contract KMHTokenInterface {
  function checkRole(address addr, string roleName) public view;

  function mint(address _to, uint256 _amount) public returns (bool);
}

contract NameRegistryInterface {
  function registerName(address addr, string name) public;
  function finalizeName(address addr, string name) public;
}

 
contract Airdrop is Pausable {
  using SafeMath for uint;
  using ECRecovery for bytes32;

  event Distribution(address indexed to, uint256 amount);

  mapping(bytes32 => address) public users;
  mapping(bytes32 => uint) public unclaimedRewards;

  address public signer;

  KMHTokenInterface public token;
  NameRegistryInterface public nameRegistry;

  constructor(address _token, address _nameRegistry, address _signer) public {
    require(_token != address(0));
    require(_nameRegistry != address(0));
    require(_signer != address(0));

    token = KMHTokenInterface(_token);
    nameRegistry = NameRegistryInterface(_nameRegistry);
    signer = _signer;
  }

  function setSigner(address newSigner) public onlyOwner {
    require(newSigner != address(0));

    signer = newSigner;
  }

  function claim(
    address receiver,
    bytes32 id,
    string username,
    bool verified,
    uint256 amount,
    bytes32 inviterId,
    uint256 inviteReward,
    bytes sig
  ) public whenNotPaused {
    require(users[id] == address(0));

    bytes32 proveHash = getProveHash(receiver, id, username, verified, amount, inviterId, inviteReward);
    address proveSigner = getMsgSigner(proveHash, sig);
    require(proveSigner == signer);

    users[id] = receiver;

    uint256 unclaimedReward = unclaimedRewards[id];
    if (unclaimedReward > 0) {
      unclaimedRewards[id] = 0;
      _distribute(receiver, unclaimedReward.add(amount));
    } else {
      _distribute(receiver, amount);
    }

    if (verified) {
      nameRegistry.finalizeName(receiver, username);
    } else {
      nameRegistry.registerName(receiver, username);
    }

    if (inviterId == 0) {
      return;
    }

    if (users[inviterId] == address(0)) {
      unclaimedRewards[inviterId] = unclaimedRewards[inviterId].add(inviteReward);
    } else {
      _distribute(users[inviterId], inviteReward);
    }
  }

  function getAccountState(bytes32 id) public view returns (address addr, uint256 unclaimedReward) {
    addr = users[id];
    unclaimedReward = unclaimedRewards[id];
  }

  function getProveHash(
    address receiver, bytes32 id, string username, bool verified, uint256 amount, bytes32 inviterId, uint256 inviteReward
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(receiver, id, username, verified, amount, inviterId, inviteReward));
  }

  function getMsgSigner(bytes32 proveHash, bytes sig) public pure returns (address) {
    return proveHash.recover(sig);
  }

  function _distribute(address to, uint256 amount) internal {
    token.mint(to, amount);
    emit Distribution(to, amount);
  }
}