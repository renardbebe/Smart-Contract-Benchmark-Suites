 

pragma solidity >=0.4.21 <0.6.0;

library AddressArray{
  function exists(address[] storage self, address addr) public view returns(bool){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return true;
      }
    }
    return false;
  }

  function index_of(address[] storage self, address addr) public view returns(uint){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return i;
      }
    }
    require(false, "AddressArray:index_of, not exist");
  }

  function remove(address[] storage self, address addr) public returns(bool){
    uint index = index_of(self, addr);
    self[index] = self[self.length - 1];

    delete self[self.length-1];
    self.length--;
  }

  function replace(address[] storage self, address old_addr, address new_addr) public returns(bool){
    uint index = index_of(self, old_addr);
    self[index] = new_addr;
  }
}


pragma solidity >=0.4.21 <0.6.0;

contract MultiSigInterface{
  function update_and_check_reach_majority(uint64 id, string memory name, bytes32 hash, address sender) public returns (bool);
  function is_signer(address addr) public view returns(bool);
}

contract MultiSigTools{
  MultiSigInterface public multisig_contract;
  constructor(address _contract) public{
    require(_contract!= address(0x0));
    multisig_contract = MultiSigInterface(_contract);
  }

  modifier only_signer{
    require(multisig_contract.is_signer(msg.sender), "only a signer can call in MultiSigTools");
    _;
  }

  modifier is_majority_sig(uint64 id, string memory name) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sig, msg.data));
    if(multisig_contract.update_and_check_reach_majority(id, name, hash, msg.sender)){
      _;
    }
  }

  event TransferMultiSig(address _old, address _new);

  function transfer_multisig(uint64 id, address _contract) public only_signer
  is_majority_sig(id, "transfer_multisig"){
    require(_contract != address(0x0));
    address old = address(multisig_contract);
    multisig_contract = MultiSigInterface(_contract);
    emit TransferMultiSig(old, _contract);
  }
}


pragma solidity >=0.4.21 <0.6.0;



contract AddressList{
  using AddressArray for address[];
  mapping(address => bool) private address_status;
  address[] public addresses;

  constructor() public{}

  function get_all_addresses() public view returns(address[] memory){
    return addresses;
  }

  function get_address(uint i) public view returns(address){
    require(i < addresses.length, "AddressList:get_address, out of range");
    return addresses[i];
  }

  function get_address_num() public view returns(uint){
    return addresses.length;
  }

  function is_address_exist(address addr) public view returns(bool){
    return address_status[addr];
  }

  function _add_address(address addr) internal{
    if(address_status[addr]) return;
    address_status[addr] = true;
    addresses.push(addr);
  }

  function _remove_address(address addr) internal{
    if(!address_status[addr]) return;
    address_status[addr] = false;
    addresses.remove(addr);
  }

  function _reset() internal{
    for(uint i = 0; i < addresses.length; i++){
      address_status[addresses[i]] = false;
    }
    delete addresses;
  }
}

contract TrustList is AddressList, MultiSigTools{

  event AddTrust(address addr);
  event RemoveTrust(address addr);

  constructor(address[] memory _list, address _multisig) public MultiSigTools(_multisig){
    for(uint i = 0; i < _list.length; i++){
      _add_address(_list[i]);
    }
  }

  function is_trusted(address addr) public view returns(bool){
    return is_address_exist(addr);
  }

  function get_trusted(uint i) public view returns(address){
    return get_address(i);
  }

  function get_trusted_num() public view returns(uint){
    return get_address_num();
  }

  function add_trusted(uint64 id, address addr) public
    only_signer is_majority_sig(id, "add_trusted"){
    _add_address(addr);
    emit AddTrust(addr);
  }
  function add_multi_trusted(uint64 id, address[] memory _list) public
    only_signer is_majority_sig(id, "add_multi_trusted"){
    for(uint i = 0; i < _list.length; i++){
      _add_address(_list[i]);
      emit AddTrust(_list[i]);
    }
  }

  function remove_trusted(uint64 id, address addr) public
    only_signer is_majority_sig(id, "remove_trusted"){
    _remove_address(addr);
    emit RemoveTrust(addr);
  }

  function remove_multi_trusted(uint64 id, address[] memory _list) public
  only_signer is_majority_sig(id, "remove_multi_trusted"){
    for(uint i = 0; i < _list.length; i++){
      _remove_address(_list[i]);
      emit RemoveTrust(_list[i]);
    }
  }
}

contract TrustListFactory{
  event NewTrustList(address addr, address[] list, address multisig);

  function createTrustList(address[] memory _list, address _multisig) public returns(address){
    TrustList tl = new TrustList(_list, _multisig);
    emit NewTrustList(address(tl), _list, _multisig);
    return address(tl);
  }
}