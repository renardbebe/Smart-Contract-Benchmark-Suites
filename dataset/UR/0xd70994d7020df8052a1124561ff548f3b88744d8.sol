 

 
 
 

pragma solidity ^0.4.1;

contract Owned {
  event NewOwner(address indexed old, address indexed current);

  modifier only_owner {
    if (msg.sender != owner) throw;
    _;
  }

  address public owner = msg.sender;

  function setOwner(address _new) only_owner {
    NewOwner(owner, _new);
    owner = _new;
  }
}

contract DappReg is Owned {
   
   
   
  struct Dapp {
    bytes32 id;
    address owner;
    mapping (bytes32 => bytes32) meta;
  }

  modifier when_fee_paid {
    if (msg.value < fee) throw;
    _;
  }

  modifier only_dapp_owner(bytes32 _id) {
    if (dapps[_id].owner != msg.sender) throw;
    _;
  }

  modifier either_owner(bytes32 _id) {
    if (dapps[_id].owner != msg.sender && owner != msg.sender) throw;
    _;
  }

  modifier when_id_free(bytes32 _id) {
    if (dapps[_id].id != 0) throw;
    _;
  }

  event MetaChanged(bytes32 indexed id, bytes32 indexed key, bytes32 value);
  event OwnerChanged(bytes32 indexed id, address indexed owner);
  event Registered(bytes32 indexed id, address indexed owner);
  event Unregistered(bytes32 indexed id);

  mapping (bytes32 => Dapp) dapps;
  bytes32[] ids;

  uint public fee = 1 ether;

   
  function count() constant returns (uint) {
    return ids.length;
  }

   
  function at(uint _index) constant returns (bytes32 id, address owner) {
    Dapp d = dapps[ids[_index]];
    id = d.id;
    owner = d.owner;
  }

   
  function get(bytes32 _id) constant returns (bytes32 id, address owner) {
    Dapp d = dapps[_id];
    id = d.id;
    owner = d.owner;
  }

   
  function register(bytes32 _id) payable when_fee_paid when_id_free(_id) {
    ids.push(_id);
    dapps[_id] = Dapp(_id, msg.sender);
    Registered(_id, msg.sender);
  }

   
  function unregister(bytes32 _id) either_owner(_id) {
    delete dapps[_id];
    Unregistered(_id);
  }

   
  function meta(bytes32 _id, bytes32 _key) constant returns (bytes32) {
    return dapps[_id].meta[_key];
  }

   
  function setMeta(bytes32 _id, bytes32 _key, bytes32 _value) only_dapp_owner(_id) {
    dapps[_id].meta[_key] = _value;
    MetaChanged(_id, _key, _value);
  }

   
  function setDappOwner(bytes32 _id, address _owner) only_dapp_owner(_id) {
    dapps[_id].owner = _owner;
    OwnerChanged(_id, _owner);
  }

   
  function setFee(uint _fee) only_owner {
    fee = _fee;
  }

   
  function drain() only_owner {
    if (!msg.sender.send(this.balance)) {
      throw;
    }
  }
}