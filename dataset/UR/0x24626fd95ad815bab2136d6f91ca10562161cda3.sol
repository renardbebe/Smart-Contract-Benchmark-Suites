 

pragma solidity ^0.4.25;

 
 
contract ACOwned {

  address public owner;
  address public new_owner;
  bool is_ac_owned_init;

   
  modifier if_owner() {
    require(is_owner());
    _;
  }

  function init_ac_owned()
           internal
           returns (bool _success)
  {
    if (is_ac_owned_init == false) {
      owner = msg.sender;
      is_ac_owned_init = true;
    }
    _success = true;
  }

  function is_owner()
           private
           constant
           returns (bool _is_owner)
  {
    _is_owner = (msg.sender == owner);
  }

  function change_owner(address _new_owner)
           if_owner()
           public
           returns (bool _success)
  {
    new_owner = _new_owner;
    _success = true;
  }

  function claim_ownership()
           public
           returns (bool _success)
  {
    require(msg.sender == new_owner);
    owner = new_owner;
    _success = true;
  }
}

 
 
contract Constants {
  address constant NULL_ADDRESS = address(0x0);
  uint256 constant ZERO = uint256(0);
  bytes32 constant EMPTY = bytes32(0x0);
}

 
 
contract ContractResolver is ACOwned, Constants {

  mapping (bytes32 => address) contracts;
  bool public locked_forever;

  modifier unless_registered(bytes32 _key) {
    require(contracts[_key] == NULL_ADDRESS);
    _;
  }

  modifier if_owner_origin() {
    require(tx.origin == owner);
    _;
  }

   
   
  modifier if_sender_is(bytes32 _contract) {
    require(msg.sender == get_contract(_contract));
    _;
  }

  modifier if_not_locked() {
    require(locked_forever == false);
    _;
  }

   
  constructor() public
  {
    require(init_ac_owned());
    locked_forever = false;
  }

   
   
   
   
  function init_register_contract(bytes32 _key, address _contract_address)
           if_owner_origin()
           if_not_locked()
           unless_registered(_key)
           public
           returns (bool _success)
  {
    require(_contract_address != NULL_ADDRESS);
    contracts[_key] = _contract_address;
    _success = true;
  }

   
   
  function lock_resolver_forever()
           if_owner
           public
           returns (bool _success)
  {
    locked_forever = true;
    _success = true;
  }

   
   
   
  function get_contract(bytes32 _key)
           public
           view
           returns (address _contract)
  {
    require(contracts[_key] != NULL_ADDRESS);
    _contract = contracts[_key];
  }
}

 
 
contract ResolverClient {

   
  address public resolver;
  bytes32 public key;

   
  address public CONTRACT_ADDRESS;

   
   
  modifier if_sender_is(bytes32 _contract) {
    require(sender_is(_contract));
    _;
  }

  function sender_is(bytes32 _contract) internal view returns (bool _isFrom) {
    _isFrom = msg.sender == ContractResolver(resolver).get_contract(_contract);
  }

  modifier if_sender_is_from(bytes32[3] _contracts) {
    require(sender_is_from(_contracts));
    _;
  }

  function sender_is_from(bytes32[3] _contracts) internal view returns (bool _isFrom) {
    uint256 _n = _contracts.length;
    for (uint256 i = 0; i < _n; i++) {
      if (_contracts[i] == bytes32(0x0)) continue;
      if (msg.sender == ContractResolver(resolver).get_contract(_contracts[i])) {
        _isFrom = true;
        break;
      }
    }
  }

   
  modifier unless_resolver_is_locked() {
    require(is_locked() == false);
    _;
  }

   
   
   
  function init(bytes32 _key, address _resolver)
           internal
           returns (bool _success)
  {
    bool _is_locked = ContractResolver(_resolver).locked_forever();
    if (_is_locked == false) {
      CONTRACT_ADDRESS = address(this);
      resolver = _resolver;
      key = _key;
      require(ContractResolver(resolver).init_register_contract(key, CONTRACT_ADDRESS));
      _success = true;
    }  else {
      _success = false;
    }
  }

   
   
  function is_locked()
           private
           view
           returns (bool _locked)
  {
    _locked = ContractResolver(resolver).locked_forever();
  }

   
   
   
  function get_contract(bytes32 _key)
           public
           view
           returns (address _contract)
  {
    _contract = ContractResolver(resolver).get_contract(_key);
  }
}

 
contract BytesIteratorInteractive {

   
  function list_bytesarray(uint256 _count,
                                 function () external constant returns (bytes32) _function_first,
                                 function () external constant returns (bytes32) _function_last,
                                 function (bytes32) external constant returns (bytes32) _function_next,
                                 function (bytes32) external constant returns (bytes32) _function_previous,
                                 bool _from_start)
           internal
           constant
           returns (bytes32[] _bytes_items)
  {
    if (_from_start) {
      _bytes_items = private_list_bytes_from_bytes(_function_first(), _count, true, _function_last, _function_next);
    } else {
      _bytes_items = private_list_bytes_from_bytes(_function_last(), _count, true, _function_first, _function_previous);
    }
  }

   
  function list_bytesarray_from(bytes32 _current_item, uint256 _count,
                                function () external constant returns (bytes32) _function_first,
                                function () external constant returns (bytes32) _function_last,
                                function (bytes32) external constant returns (bytes32) _function_next,
                                function (bytes32) external constant returns (bytes32) _function_previous,
                                bool _from_start)
           internal
           constant
           returns (bytes32[] _bytes_items)
  {
    if (_from_start) {
      _bytes_items = private_list_bytes_from_bytes(_current_item, _count, false, _function_last, _function_next);
    } else {
      _bytes_items = private_list_bytes_from_bytes(_current_item, _count, false, _function_first, _function_previous);
    }
  }

   
  function private_list_bytes_from_bytes(bytes32 _current_item, uint256 _count, bool _including_current,
                                 function () external constant returns (bytes32) _function_last,
                                 function (bytes32) external constant returns (bytes32) _function_next)
           private
           constant
           returns (bytes32[] _bytes32_items)
  {
    uint256 _i;
    uint256 _real_count = 0;
    bytes32 _last_item;

    _last_item = _function_last();
    if (_count == 0 || _last_item == bytes32(0x0)) {
      _bytes32_items = new bytes32[](0);
    } else {
      bytes32[] memory _items_temp = new bytes32[](_count);
      bytes32 _this_item;
      if (_including_current == true) {
        _items_temp[0] = _current_item;
        _real_count = 1;
      }
      _this_item = _current_item;
      for (_i = _real_count; (_i < _count) && (_this_item != _last_item);_i++) {
        _this_item = _function_next(_this_item);
        if (_this_item != bytes32(0x0)) {
          _real_count++;
          _items_temp[_i] = _this_item;
        }
      }

      _bytes32_items = new bytes32[](_real_count);
      for(_i = 0;_i < _real_count;_i++) {
        _bytes32_items[_i] = _items_temp[_i];
      }
    }
  }




   

   
   

   
   
}

 
contract AddressIteratorInteractive {

   
  function list_addresses(uint256 _count,
                                 function () external constant returns (address) _function_first,
                                 function () external constant returns (address) _function_last,
                                 function (address) external constant returns (address) _function_next,
                                 function (address) external constant returns (address) _function_previous,
                                 bool _from_start)
           internal
           constant
           returns (address[] _address_items)
  {
    if (_from_start) {
      _address_items = private_list_addresses_from_address(_function_first(), _count, true, _function_last, _function_next);
    } else {
      _address_items = private_list_addresses_from_address(_function_last(), _count, true, _function_first, _function_previous);
    }
  }



   
  function list_addresses_from(address _current_item, uint256 _count,
                                function () external constant returns (address) _function_first,
                                function () external constant returns (address) _function_last,
                                function (address) external constant returns (address) _function_next,
                                function (address) external constant returns (address) _function_previous,
                                bool _from_start)
           internal
           constant
           returns (address[] _address_items)
  {
    if (_from_start) {
      _address_items = private_list_addresses_from_address(_current_item, _count, false, _function_last, _function_next);
    } else {
      _address_items = private_list_addresses_from_address(_current_item, _count, false, _function_first, _function_previous);
    }
  }


   
  function private_list_addresses_from_address(address _current_item, uint256 _count, bool _including_current,
                                 function () external constant returns (address) _function_last,
                                 function (address) external constant returns (address) _function_next)
           private
           constant
           returns (address[] _address_items)
  {
    uint256 _i;
    uint256 _real_count = 0;
    address _last_item;

    _last_item = _function_last();
    if (_count == 0 || _last_item == address(0x0)) {
      _address_items = new address[](0);
    } else {
      address[] memory _items_temp = new address[](_count);
      address _this_item;
      if (_including_current == true) {
        _items_temp[0] = _current_item;
        _real_count = 1;
      }
      _this_item = _current_item;
      for (_i = _real_count; (_i < _count) && (_this_item != _last_item);_i++) {
        _this_item = _function_next(_this_item);
        if (_this_item != address(0x0)) {
          _real_count++;
          _items_temp[_i] = _this_item;
        }
      }

      _address_items = new address[](_real_count);
      for(_i = 0;_i < _real_count;_i++) {
        _address_items[_i] = _items_temp[_i];
      }
    }
  }


   
   

   
   
}

 
contract IndexedBytesIteratorInteractive {

   
  function list_indexed_bytesarray(bytes32 _collection_index, uint256 _count,
                              function (bytes32) external constant returns (bytes32) _function_first,
                              function (bytes32) external constant returns (bytes32) _function_last,
                              function (bytes32, bytes32) external constant returns (bytes32) _function_next,
                              function (bytes32, bytes32) external constant returns (bytes32) _function_previous,
                              bool _from_start)
           internal
           constant
           returns (bytes32[] _indexed_bytes_items)
  {
    if (_from_start) {
      _indexed_bytes_items = private_list_indexed_bytes_from_bytes(_collection_index, _function_first(_collection_index), _count, true, _function_last, _function_next);
    } else {
      _indexed_bytes_items = private_list_indexed_bytes_from_bytes(_collection_index, _function_last(_collection_index), _count, true, _function_first, _function_previous);
    }
  }

   
  function list_indexed_bytesarray_from(bytes32 _collection_index, bytes32 _current_item, uint256 _count,
                                function (bytes32) external constant returns (bytes32) _function_first,
                                function (bytes32) external constant returns (bytes32) _function_last,
                                function (bytes32, bytes32) external constant returns (bytes32) _function_next,
                                function (bytes32, bytes32) external constant returns (bytes32) _function_previous,
                                bool _from_start)
           internal
           constant
           returns (bytes32[] _indexed_bytes_items)
  {
    if (_from_start) {
      _indexed_bytes_items = private_list_indexed_bytes_from_bytes(_collection_index, _current_item, _count, false, _function_last, _function_next);
    } else {
      _indexed_bytes_items = private_list_indexed_bytes_from_bytes(_collection_index, _current_item, _count, false, _function_first, _function_previous);
    }
  }

   
  function private_list_indexed_bytes_from_bytes(bytes32 _collection_index, bytes32 _current_item, uint256 _count, bool _including_current,
                                         function (bytes32) external constant returns (bytes32) _function_last,
                                         function (bytes32, bytes32) external constant returns (bytes32) _function_next)
           private
           constant
           returns (bytes32[] _indexed_bytes_items)
  {
    uint256 _i;
    uint256 _real_count = 0;
    bytes32 _last_item;

    _last_item = _function_last(_collection_index);
    if (_count == 0 || _last_item == bytes32(0x0)) {   
      _indexed_bytes_items = new bytes32[](0);
    } else {
      bytes32[] memory _items_temp = new bytes32[](_count);
      bytes32 _this_item;
      if (_including_current) {
        _items_temp[0] = _current_item;
        _real_count = 1;
      }
      _this_item = _current_item;
      for (_i = _real_count; (_i < _count) && (_this_item != _last_item);_i++) {
        _this_item = _function_next(_collection_index, _this_item);
        if (_this_item != bytes32(0x0)) {
          _real_count++;
          _items_temp[_i] = _this_item;
        }
      }

      _indexed_bytes_items = new bytes32[](_real_count);
      for(_i = 0;_i < _real_count;_i++) {
        _indexed_bytes_items[_i] = _items_temp[_i];
      }
    }
  }


   
   
}

library DoublyLinkedList {

  struct Item {
    bytes32 item;
    uint256 previous_index;
    uint256 next_index;
  }

  struct Data {
    uint256 first_index;
    uint256 last_index;
    uint256 count;
    mapping(bytes32 => uint256) item_index;
    mapping(uint256 => bool) valid_indexes;
    Item[] collection;
  }

  struct IndexedUint {
    mapping(bytes32 => Data) data;
  }

  struct IndexedAddress {
    mapping(bytes32 => Data) data;
  }

  struct IndexedBytes {
    mapping(bytes32 => Data) data;
  }

  struct Address {
    Data data;
  }

  struct Bytes {
    Data data;
  }

  struct Uint {
    Data data;
  }

  uint256 constant NONE = uint256(0);
  bytes32 constant EMPTY_BYTES = bytes32(0x0);
  address constant NULL_ADDRESS = address(0x0);

  function find(Data storage self, bytes32 _item)
           public
           constant
           returns (uint256 _item_index)
  {
    if ((self.item_index[_item] == NONE) && (self.count == NONE)) {
      _item_index = NONE;
    } else {
      _item_index = self.item_index[_item];
    }
  }

  function get(Data storage self, uint256 _item_index)
           public
           constant
           returns (bytes32 _item)
  {
    if (self.valid_indexes[_item_index] == true) {
      _item = self.collection[_item_index - 1].item;
    } else {
      _item = EMPTY_BYTES;
    }
  }

  function append(Data storage self, bytes32 _data)
           internal
           returns (bool _success)
  {
    if (find(self, _data) != NONE || _data == bytes32("")) {  
      _success = false;
    } else {
      uint256 _index = uint256(self.collection.push(Item({item: _data, previous_index: self.last_index, next_index: NONE})));
      if (self.last_index == NONE) {
        if ((self.first_index != NONE) || (self.count != NONE)) {
          revert();
        } else {
          self.first_index = self.last_index = _index;
          self.count = 1;
        }
      } else {
        self.collection[self.last_index - 1].next_index = _index;
        self.last_index = _index;
        self.count++;
      }
      self.valid_indexes[_index] = true;
      self.item_index[_data] = _index;
      _success = true;
    }
  }

  function remove(Data storage self, uint256 _index)
           internal
           returns (bool _success)
  {
    if (self.valid_indexes[_index] == true) {
      Item memory item = self.collection[_index - 1];
      if (item.previous_index == NONE) {
        self.first_index = item.next_index;
      } else {
        self.collection[item.previous_index - 1].next_index = item.next_index;
      }

      if (item.next_index == NONE) {
        self.last_index = item.previous_index;
      } else {
        self.collection[item.next_index - 1].previous_index = item.previous_index;
      }
      delete self.collection[_index - 1];
      self.valid_indexes[_index] = false;
      delete self.item_index[item.item];
      self.count--;
      _success = true;
    } else {
      _success = false;
    }
  }

  function remove_item(Data storage self, bytes32 _item)
           internal
           returns (bool _success)
  {
    uint256 _item_index = find(self, _item);
    if (_item_index != NONE) {
      require(remove(self, _item_index));
      _success = true;
    } else {
      _success = false;
    }
    return _success;
  }

  function total(Data storage self)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = self.count;
  }

  function start(Data storage self)
           public
           constant
           returns (uint256 _item_index)
  {
    _item_index = self.first_index;
    return _item_index;
  }

  function start_item(Data storage self)
           public
           constant
           returns (bytes32 _item)
  {
    uint256 _item_index = start(self);
    if (_item_index != NONE) {
      _item = get(self, _item_index);
    } else {
      _item = EMPTY_BYTES;
    }
  }

  function end(Data storage self)
           public
           constant
           returns (uint256 _item_index)
  {
    _item_index = self.last_index;
    return _item_index;
  }

  function end_item(Data storage self)
           public
           constant
           returns (bytes32 _item)
  {
    uint256 _item_index = end(self);
    if (_item_index != NONE) {
      _item = get(self, _item_index);
    } else {
      _item = EMPTY_BYTES;
    }
  }

  function valid(Data storage self, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = self.valid_indexes[_item_index];
     
  }

  function valid_item(Data storage self, bytes32 _item)
           public
           constant
           returns (bool _yes)
  {
    uint256 _item_index = self.item_index[_item];
    _yes = self.valid_indexes[_item_index];
  }

  function previous(Data storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    if (self.valid_indexes[_current_index] == true) {
      _previous_index = self.collection[_current_index - 1].previous_index;
    } else {
      _previous_index = NONE;
    }
  }

  function previous_item(Data storage self, bytes32 _current_item)
           public
           constant
           returns (bytes32 _previous_item)
  {
    uint256 _current_index = find(self, _current_item);
    if (_current_index != NONE) {
      uint256 _previous_index = previous(self, _current_index);
      _previous_item = get(self, _previous_index);
    } else {
      _previous_item = EMPTY_BYTES;
    }
  }

  function next(Data storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    if (self.valid_indexes[_current_index] == true) {
      _next_index = self.collection[_current_index - 1].next_index;
    } else {
      _next_index = NONE;
    }
  }

  function next_item(Data storage self, bytes32 _current_item)
           public
           constant
           returns (bytes32 _next_item)
  {
    uint256 _current_index = find(self, _current_item);
    if (_current_index != NONE) {
      uint256 _next_index = next(self, _current_index);
      _next_item = get(self, _next_index);
    } else {
      _next_item = EMPTY_BYTES;
    }
  }

  function find(Uint storage self, uint256 _item)
           public
           constant
           returns (uint256 _item_index)
  {
    _item_index = find(self.data, bytes32(_item));
  }

  function get(Uint storage self, uint256 _item_index)
           public
           constant
           returns (uint256 _item)
  {
    _item = uint256(get(self.data, _item_index));
  }


  function append(Uint storage self, uint256 _data)
           public
           returns (bool _success)
  {
    _success = append(self.data, bytes32(_data));
  }

  function remove(Uint storage self, uint256 _index)
           internal
           returns (bool _success)
  {
    _success = remove(self.data, _index);
  }

  function remove_item(Uint storage self, uint256 _item)
           public
           returns (bool _success)
  {
    _success = remove_item(self.data, bytes32(_item));
  }

  function total(Uint storage self)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = total(self.data);
  }

  function start(Uint storage self)
           public
           constant
           returns (uint256 _index)
  {
    _index = start(self.data);
  }

  function start_item(Uint storage self)
           public
           constant
           returns (uint256 _start_item)
  {
    _start_item = uint256(start_item(self.data));
  }


  function end(Uint storage self)
           public
           constant
           returns (uint256 _index)
  {
    _index = end(self.data);
  }

  function end_item(Uint storage self)
           public
           constant
           returns (uint256 _end_item)
  {
    _end_item = uint256(end_item(self.data));
  }

  function valid(Uint storage self, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid(self.data, _item_index);
  }

  function valid_item(Uint storage self, uint256 _item)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid_item(self.data, bytes32(_item));
  }

  function previous(Uint storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    _previous_index = previous(self.data, _current_index);
  }

  function previous_item(Uint storage self, uint256 _current_item)
           public
           constant
           returns (uint256 _previous_item)
  {
    _previous_item = uint256(previous_item(self.data, bytes32(_current_item)));
  }

  function next(Uint storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    _next_index = next(self.data, _current_index);
  }

  function next_item(Uint storage self, uint256 _current_item)
           public
           constant
           returns (uint256 _next_item)
  {
    _next_item = uint256(next_item(self.data, bytes32(_current_item)));
  }

  function find(Address storage self, address _item)
           public
           constant
           returns (uint256 _item_index)
  {
    _item_index = find(self.data, bytes32(_item));
  }

  function get(Address storage self, uint256 _item_index)
           public
           constant
           returns (address _item)
  {
    _item = address(get(self.data, _item_index));
  }


  function find(IndexedUint storage self, bytes32 _collection_index, uint256 _item)
           public
           constant
           returns (uint256 _item_index)
  {
    _item_index = find(self.data[_collection_index], bytes32(_item));
  }

  function get(IndexedUint storage self, bytes32 _collection_index, uint256 _item_index)
           public
           constant
           returns (uint256 _item)
  {
    _item = uint256(get(self.data[_collection_index], _item_index));
  }


  function append(IndexedUint storage self, bytes32 _collection_index, uint256 _data)
           public
           returns (bool _success)
  {
    _success = append(self.data[_collection_index], bytes32(_data));
  }

  function remove(IndexedUint storage self, bytes32 _collection_index, uint256 _index)
           internal
           returns (bool _success)
  {
    _success = remove(self.data[_collection_index], _index);
  }

  function remove_item(IndexedUint storage self, bytes32 _collection_index, uint256 _item)
           public
           returns (bool _success)
  {
    _success = remove_item(self.data[_collection_index], bytes32(_item));
  }

  function total(IndexedUint storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = total(self.data[_collection_index]);
  }

  function start(IndexedUint storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _index)
  {
    _index = start(self.data[_collection_index]);
  }

  function start_item(IndexedUint storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _start_item)
  {
    _start_item = uint256(start_item(self.data[_collection_index]));
  }


  function end(IndexedUint storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _index)
  {
    _index = end(self.data[_collection_index]);
  }

  function end_item(IndexedUint storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _end_item)
  {
    _end_item = uint256(end_item(self.data[_collection_index]));
  }

  function valid(IndexedUint storage self, bytes32 _collection_index, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid(self.data[_collection_index], _item_index);
  }

  function valid_item(IndexedUint storage self, bytes32 _collection_index, uint256 _item)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid_item(self.data[_collection_index], bytes32(_item));
  }

  function previous(IndexedUint storage self, bytes32 _collection_index, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    _previous_index = previous(self.data[_collection_index], _current_index);
  }

  function previous_item(IndexedUint storage self, bytes32 _collection_index, uint256 _current_item)
           public
           constant
           returns (uint256 _previous_item)
  {
    _previous_item = uint256(previous_item(self.data[_collection_index], bytes32(_current_item)));
  }

  function next(IndexedUint storage self, bytes32 _collection_index, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    _next_index = next(self.data[_collection_index], _current_index);
  }

  function next_item(IndexedUint storage self, bytes32 _collection_index, uint256 _current_item)
           public
           constant
           returns (uint256 _next_item)
  {
    _next_item = uint256(next_item(self.data[_collection_index], bytes32(_current_item)));
  }

  function append(Address storage self, address _data)
           public
           returns (bool _success)
  {
    _success = append(self.data, bytes32(_data));
  }

  function remove(Address storage self, uint256 _index)
           internal
           returns (bool _success)
  {
    _success = remove(self.data, _index);
  }


  function remove_item(Address storage self, address _item)
           public
           returns (bool _success)
  {
    _success = remove_item(self.data, bytes32(_item));
  }

  function total(Address storage self)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = total(self.data);
  }

  function start(Address storage self)
           public
           constant
           returns (uint256 _index)
  {
    _index = start(self.data);
  }

  function start_item(Address storage self)
           public
           constant
           returns (address _start_item)
  {
    _start_item = address(start_item(self.data));
  }


  function end(Address storage self)
           public
           constant
           returns (uint256 _index)
  {
    _index = end(self.data);
  }

  function end_item(Address storage self)
           public
           constant
           returns (address _end_item)
  {
    _end_item = address(end_item(self.data));
  }

  function valid(Address storage self, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid(self.data, _item_index);
  }

  function valid_item(Address storage self, address _item)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid_item(self.data, bytes32(_item));
  }

  function previous(Address storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    _previous_index = previous(self.data, _current_index);
  }

  function previous_item(Address storage self, address _current_item)
           public
           constant
           returns (address _previous_item)
  {
    _previous_item = address(previous_item(self.data, bytes32(_current_item)));
  }

  function next(Address storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    _next_index = next(self.data, _current_index);
  }

  function next_item(Address storage self, address _current_item)
           public
           constant
           returns (address _next_item)
  {
    _next_item = address(next_item(self.data, bytes32(_current_item)));
  }

  function append(IndexedAddress storage self, bytes32 _collection_index, address _data)
           public
           returns (bool _success)
  {
    _success = append(self.data[_collection_index], bytes32(_data));
  }

  function remove(IndexedAddress storage self, bytes32 _collection_index, uint256 _index)
           internal
           returns (bool _success)
  {
    _success = remove(self.data[_collection_index], _index);
  }


  function remove_item(IndexedAddress storage self, bytes32 _collection_index, address _item)
           public
           returns (bool _success)
  {
    _success = remove_item(self.data[_collection_index], bytes32(_item));
  }

  function total(IndexedAddress storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = total(self.data[_collection_index]);
  }

  function start(IndexedAddress storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _index)
  {
    _index = start(self.data[_collection_index]);
  }

  function start_item(IndexedAddress storage self, bytes32 _collection_index)
           public
           constant
           returns (address _start_item)
  {
    _start_item = address(start_item(self.data[_collection_index]));
  }


  function end(IndexedAddress storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _index)
  {
    _index = end(self.data[_collection_index]);
  }

  function end_item(IndexedAddress storage self, bytes32 _collection_index)
           public
           constant
           returns (address _end_item)
  {
    _end_item = address(end_item(self.data[_collection_index]));
  }

  function valid(IndexedAddress storage self, bytes32 _collection_index, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid(self.data[_collection_index], _item_index);
  }

  function valid_item(IndexedAddress storage self, bytes32 _collection_index, address _item)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid_item(self.data[_collection_index], bytes32(_item));
  }

  function previous(IndexedAddress storage self, bytes32 _collection_index, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    _previous_index = previous(self.data[_collection_index], _current_index);
  }

  function previous_item(IndexedAddress storage self, bytes32 _collection_index, address _current_item)
           public
           constant
           returns (address _previous_item)
  {
    _previous_item = address(previous_item(self.data[_collection_index], bytes32(_current_item)));
  }

  function next(IndexedAddress storage self, bytes32 _collection_index, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    _next_index = next(self.data[_collection_index], _current_index);
  }

  function next_item(IndexedAddress storage self, bytes32 _collection_index, address _current_item)
           public
           constant
           returns (address _next_item)
  {
    _next_item = address(next_item(self.data[_collection_index], bytes32(_current_item)));
  }


  function find(Bytes storage self, bytes32 _item)
           public
           constant
           returns (uint256 _item_index)
  {
    _item_index = find(self.data, _item);
  }

  function get(Bytes storage self, uint256 _item_index)
           public
           constant
           returns (bytes32 _item)
  {
    _item = get(self.data, _item_index);
  }


  function append(Bytes storage self, bytes32 _data)
           public
           returns (bool _success)
  {
    _success = append(self.data, _data);
  }

  function remove(Bytes storage self, uint256 _index)
           internal
           returns (bool _success)
  {
    _success = remove(self.data, _index);
  }


  function remove_item(Bytes storage self, bytes32 _item)
           public
           returns (bool _success)
  {
    _success = remove_item(self.data, _item);
  }

  function total(Bytes storage self)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = total(self.data);
  }

  function start(Bytes storage self)
           public
           constant
           returns (uint256 _index)
  {
    _index = start(self.data);
  }

  function start_item(Bytes storage self)
           public
           constant
           returns (bytes32 _start_item)
  {
    _start_item = start_item(self.data);
  }


  function end(Bytes storage self)
           public
           constant
           returns (uint256 _index)
  {
    _index = end(self.data);
  }

  function end_item(Bytes storage self)
           public
           constant
           returns (bytes32 _end_item)
  {
    _end_item = end_item(self.data);
  }

  function valid(Bytes storage self, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid(self.data, _item_index);
  }

  function valid_item(Bytes storage self, bytes32 _item)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid_item(self.data, _item);
  }

  function previous(Bytes storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    _previous_index = previous(self.data, _current_index);
  }

  function previous_item(Bytes storage self, bytes32 _current_item)
           public
           constant
           returns (bytes32 _previous_item)
  {
    _previous_item = previous_item(self.data, _current_item);
  }

  function next(Bytes storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    _next_index = next(self.data, _current_index);
  }

  function next_item(Bytes storage self, bytes32 _current_item)
           public
           constant
           returns (bytes32 _next_item)
  {
    _next_item = next_item(self.data, _current_item);
  }

  function append(IndexedBytes storage self, bytes32 _collection_index, bytes32 _data)
           public
           returns (bool _success)
  {
    _success = append(self.data[_collection_index], bytes32(_data));
  }

  function remove(IndexedBytes storage self, bytes32 _collection_index, uint256 _index)
           internal
           returns (bool _success)
  {
    _success = remove(self.data[_collection_index], _index);
  }


  function remove_item(IndexedBytes storage self, bytes32 _collection_index, bytes32 _item)
           public
           returns (bool _success)
  {
    _success = remove_item(self.data[_collection_index], bytes32(_item));
  }

  function total(IndexedBytes storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = total(self.data[_collection_index]);
  }

  function start(IndexedBytes storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _index)
  {
    _index = start(self.data[_collection_index]);
  }

  function start_item(IndexedBytes storage self, bytes32 _collection_index)
           public
           constant
           returns (bytes32 _start_item)
  {
    _start_item = bytes32(start_item(self.data[_collection_index]));
  }


  function end(IndexedBytes storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _index)
  {
    _index = end(self.data[_collection_index]);
  }

  function end_item(IndexedBytes storage self, bytes32 _collection_index)
           public
           constant
           returns (bytes32 _end_item)
  {
    _end_item = bytes32(end_item(self.data[_collection_index]));
  }

  function valid(IndexedBytes storage self, bytes32 _collection_index, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid(self.data[_collection_index], _item_index);
  }

  function valid_item(IndexedBytes storage self, bytes32 _collection_index, bytes32 _item)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid_item(self.data[_collection_index], bytes32(_item));
  }

  function previous(IndexedBytes storage self, bytes32 _collection_index, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    _previous_index = previous(self.data[_collection_index], _current_index);
  }

  function previous_item(IndexedBytes storage self, bytes32 _collection_index, bytes32 _current_item)
           public
           constant
           returns (bytes32 _previous_item)
  {
    _previous_item = bytes32(previous_item(self.data[_collection_index], bytes32(_current_item)));
  }

  function next(IndexedBytes storage self, bytes32 _collection_index, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    _next_index = next(self.data[_collection_index], _current_index);
  }

  function next_item(IndexedBytes storage self, bytes32 _collection_index, bytes32 _current_item)
           public
           constant
           returns (bytes32 _next_item)
  {
    _next_item = bytes32(next_item(self.data[_collection_index], bytes32(_current_item)));
  }
}

 
contract BytesIteratorStorage {

   
  using DoublyLinkedList for DoublyLinkedList.Bytes;

   
  function read_first_from_bytesarray(DoublyLinkedList.Bytes storage _list)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _list.start_item();
  }

   
  function read_last_from_bytesarray(DoublyLinkedList.Bytes storage _list)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _list.end_item();
  }

   
  function read_next_from_bytesarray(DoublyLinkedList.Bytes storage _list, bytes32 _current_item)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _list.next_item(_current_item);
  }

   
  function read_previous_from_bytesarray(DoublyLinkedList.Bytes storage _list, bytes32 _current_item)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _list.previous_item(_current_item);
  }

   
  function read_total_bytesarray(DoublyLinkedList.Bytes storage _list)
           internal
           constant
           returns (uint256 _count)
  {
    _count = _list.total();
  }
}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract DaoConstants {
    using SafeMath for uint256;
    bytes32 EMPTY_BYTES = bytes32(0x0);
    address EMPTY_ADDRESS = address(0x0);


    bytes32 PROPOSAL_STATE_PREPROPOSAL = "proposal_state_preproposal";
    bytes32 PROPOSAL_STATE_DRAFT = "proposal_state_draft";
    bytes32 PROPOSAL_STATE_MODERATED = "proposal_state_moderated";
    bytes32 PROPOSAL_STATE_ONGOING = "proposal_state_ongoing";
    bytes32 PROPOSAL_STATE_CLOSED = "proposal_state_closed";
    bytes32 PROPOSAL_STATE_ARCHIVED = "proposal_state_archived";

    uint256 PRL_ACTION_STOP = 1;
    uint256 PRL_ACTION_PAUSE = 2;
    uint256 PRL_ACTION_UNPAUSE = 3;

    uint256 COLLATERAL_STATUS_UNLOCKED = 1;
    uint256 COLLATERAL_STATUS_LOCKED = 2;
    uint256 COLLATERAL_STATUS_CLAIMED = 3;

    bytes32 INTERMEDIATE_DGD_IDENTIFIER = "inter_dgd_id";
    bytes32 INTERMEDIATE_MODERATOR_DGD_IDENTIFIER = "inter_mod_dgd_id";
    bytes32 INTERMEDIATE_BONUS_CALCULATION_IDENTIFIER = "inter_bonus_calculation_id";

     
    bytes32 CONTRACT_DAO = "dao";
    bytes32 CONTRACT_DAO_SPECIAL_PROPOSAL = "dao:special:proposal";
    bytes32 CONTRACT_DAO_STAKE_LOCKING = "dao:stake-locking";
    bytes32 CONTRACT_DAO_VOTING = "dao:voting";
    bytes32 CONTRACT_DAO_VOTING_CLAIMS = "dao:voting:claims";
    bytes32 CONTRACT_DAO_SPECIAL_VOTING_CLAIMS = "dao:svoting:claims";
    bytes32 CONTRACT_DAO_IDENTITY = "dao:identity";
    bytes32 CONTRACT_DAO_REWARDS_MANAGER = "dao:rewards-manager";
    bytes32 CONTRACT_DAO_REWARDS_MANAGER_EXTRAS = "dao:rewards-extras";
    bytes32 CONTRACT_DAO_ROLES = "dao:roles";
    bytes32 CONTRACT_DAO_FUNDING_MANAGER = "dao:funding-manager";
    bytes32 CONTRACT_DAO_WHITELISTING = "dao:whitelisting";
    bytes32 CONTRACT_DAO_INFORMATION = "dao:information";

     
    bytes32 CONTRACT_SERVICE_ROLE = "service:role";
    bytes32 CONTRACT_SERVICE_DAO_INFO = "service:dao:info";
    bytes32 CONTRACT_SERVICE_DAO_LISTING = "service:dao:listing";
    bytes32 CONTRACT_SERVICE_DAO_CALCULATOR = "service:dao:calculator";

     
    bytes32 CONTRACT_STORAGE_DAO = "storage:dao";
    bytes32 CONTRACT_STORAGE_DAO_COUNTER = "storage:dao:counter";
    bytes32 CONTRACT_STORAGE_DAO_UPGRADE = "storage:dao:upgrade";
    bytes32 CONTRACT_STORAGE_DAO_IDENTITY = "storage:dao:identity";
    bytes32 CONTRACT_STORAGE_DAO_POINTS = "storage:dao:points";
    bytes32 CONTRACT_STORAGE_DAO_SPECIAL = "storage:dao:special";
    bytes32 CONTRACT_STORAGE_DAO_CONFIG = "storage:dao:config";
    bytes32 CONTRACT_STORAGE_DAO_STAKE = "storage:dao:stake";
    bytes32 CONTRACT_STORAGE_DAO_REWARDS = "storage:dao:rewards";
    bytes32 CONTRACT_STORAGE_DAO_WHITELISTING = "storage:dao:whitelisting";
    bytes32 CONTRACT_STORAGE_INTERMEDIATE_RESULTS = "storage:intermediate:results";

    bytes32 CONTRACT_DGD_TOKEN = "t:dgd";
    bytes32 CONTRACT_DGX_TOKEN = "t:dgx";
    bytes32 CONTRACT_BADGE_TOKEN = "t:badge";

    uint8 ROLES_ROOT = 1;
    uint8 ROLES_FOUNDERS = 2;
    uint8 ROLES_PRLS = 3;
    uint8 ROLES_KYC_ADMINS = 4;

    uint256 QUARTER_DURATION = 90 days;

    bytes32 CONFIG_MINIMUM_LOCKED_DGD = "min_dgd_participant";
    bytes32 CONFIG_MINIMUM_DGD_FOR_MODERATOR = "min_dgd_moderator";
    bytes32 CONFIG_MINIMUM_REPUTATION_FOR_MODERATOR = "min_reputation_moderator";

    bytes32 CONFIG_LOCKING_PHASE_DURATION = "locking_phase_duration";
    bytes32 CONFIG_QUARTER_DURATION = "quarter_duration";
    bytes32 CONFIG_VOTING_COMMIT_PHASE = "voting_commit_phase";
    bytes32 CONFIG_VOTING_PHASE_TOTAL = "voting_phase_total";
    bytes32 CONFIG_INTERIM_COMMIT_PHASE = "interim_voting_commit_phase";
    bytes32 CONFIG_INTERIM_PHASE_TOTAL = "interim_voting_phase_total";

    bytes32 CONFIG_DRAFT_QUORUM_FIXED_PORTION_NUMERATOR = "draft_quorum_fixed_numerator";
    bytes32 CONFIG_DRAFT_QUORUM_FIXED_PORTION_DENOMINATOR = "draft_quorum_fixed_denominator";
    bytes32 CONFIG_DRAFT_QUORUM_SCALING_FACTOR_NUMERATOR = "draft_quorum_sfactor_numerator";
    bytes32 CONFIG_DRAFT_QUORUM_SCALING_FACTOR_DENOMINATOR = "draft_quorum_sfactor_denominator";
    bytes32 CONFIG_VOTING_QUORUM_FIXED_PORTION_NUMERATOR = "vote_quorum_fixed_numerator";
    bytes32 CONFIG_VOTING_QUORUM_FIXED_PORTION_DENOMINATOR = "vote_quorum_fixed_denominator";
    bytes32 CONFIG_VOTING_QUORUM_SCALING_FACTOR_NUMERATOR = "vote_quorum_sfactor_numerator";
    bytes32 CONFIG_VOTING_QUORUM_SCALING_FACTOR_DENOMINATOR = "vote_quorum_sfactor_denominator";
    bytes32 CONFIG_FINAL_REWARD_SCALING_FACTOR_NUMERATOR = "final_reward_sfactor_numerator";
    bytes32 CONFIG_FINAL_REWARD_SCALING_FACTOR_DENOMINATOR = "final_reward_sfactor_denominator";

    bytes32 CONFIG_DRAFT_QUOTA_NUMERATOR = "draft_quota_numerator";
    bytes32 CONFIG_DRAFT_QUOTA_DENOMINATOR = "draft_quota_denominator";
    bytes32 CONFIG_VOTING_QUOTA_NUMERATOR = "voting_quota_numerator";
    bytes32 CONFIG_VOTING_QUOTA_DENOMINATOR = "voting_quota_denominator";

    bytes32 CONFIG_MINIMAL_QUARTER_POINT = "minimal_qp";
    bytes32 CONFIG_QUARTER_POINT_SCALING_FACTOR = "quarter_point_scaling_factor";
    bytes32 CONFIG_REPUTATION_POINT_SCALING_FACTOR = "rep_point_scaling_factor";

    bytes32 CONFIG_MODERATOR_MINIMAL_QUARTER_POINT = "minimal_mod_qp";
    bytes32 CONFIG_MODERATOR_QUARTER_POINT_SCALING_FACTOR = "mod_qp_scaling_factor";
    bytes32 CONFIG_MODERATOR_REPUTATION_POINT_SCALING_FACTOR = "mod_rep_point_scaling_factor";

    bytes32 CONFIG_QUARTER_POINT_DRAFT_VOTE = "quarter_point_draft_vote";
    bytes32 CONFIG_QUARTER_POINT_VOTE = "quarter_point_vote";
    bytes32 CONFIG_QUARTER_POINT_INTERIM_VOTE = "quarter_point_interim_vote";

     
    bytes32 CONFIG_QUARTER_POINT_MILESTONE_COMPLETION_PER_10000ETH = "q_p_milestone_completion";

    bytes32 CONFIG_BONUS_REPUTATION_NUMERATOR = "bonus_reputation_numerator";
    bytes32 CONFIG_BONUS_REPUTATION_DENOMINATOR = "bonus_reputation_denominator";

    bytes32 CONFIG_SPECIAL_PROPOSAL_COMMIT_PHASE = "special_proposal_commit_phase";
    bytes32 CONFIG_SPECIAL_PROPOSAL_PHASE_TOTAL = "special_proposal_phase_total";

    bytes32 CONFIG_SPECIAL_QUOTA_NUMERATOR = "config_special_quota_numerator";
    bytes32 CONFIG_SPECIAL_QUOTA_DENOMINATOR = "config_special_quota_denominator";

    bytes32 CONFIG_SPECIAL_PROPOSAL_QUORUM_NUMERATOR = "special_quorum_numerator";
    bytes32 CONFIG_SPECIAL_PROPOSAL_QUORUM_DENOMINATOR = "special_quorum_denominator";

    bytes32 CONFIG_MAXIMUM_REPUTATION_DEDUCTION = "config_max_reputation_deduction";
    bytes32 CONFIG_PUNISHMENT_FOR_NOT_LOCKING = "config_punishment_not_locking";

    bytes32 CONFIG_REPUTATION_PER_EXTRA_QP_NUM = "config_rep_per_extra_qp_num";
    bytes32 CONFIG_REPUTATION_PER_EXTRA_QP_DEN = "config_rep_per_extra_qp_den";

    bytes32 CONFIG_MAXIMUM_MODERATOR_REPUTATION_DEDUCTION = "config_max_m_rp_deduction";
    bytes32 CONFIG_REPUTATION_PER_EXTRA_MODERATOR_QP_NUM = "config_rep_per_extra_m_qp_num";
    bytes32 CONFIG_REPUTATION_PER_EXTRA_MODERATOR_QP_DEN = "config_rep_per_extra_m_qp_den";

    bytes32 CONFIG_PORTION_TO_MODERATORS_NUM = "config_mod_portion_num";
    bytes32 CONFIG_PORTION_TO_MODERATORS_DEN = "config_mod_portion_den";

    bytes32 CONFIG_DRAFT_VOTING_PHASE = "config_draft_voting_phase";

    bytes32 CONFIG_REPUTATION_POINT_BOOST_FOR_BADGE = "config_rp_boost_per_badge";

    bytes32 CONFIG_VOTE_CLAIMING_DEADLINE = "config_claiming_deadline";

    bytes32 CONFIG_PREPROPOSAL_COLLATERAL = "config_preproposal_collateral";

    bytes32 CONFIG_MAX_FUNDING_FOR_NON_DIGIX = "config_max_funding_nonDigix";
    bytes32 CONFIG_MAX_MILESTONES_FOR_NON_DIGIX = "config_max_milestones_nonDigix";
    bytes32 CONFIG_NON_DIGIX_PROPOSAL_CAP_PER_QUARTER = "config_nonDigix_proposal_cap";

    bytes32 CONFIG_PROPOSAL_DEAD_DURATION = "config_dead_duration";
    bytes32 CONFIG_CARBON_VOTE_REPUTATION_BONUS = "config_cv_reputation";
}

 
 
contract DaoWhitelistingStorage is ResolverClient, DaoConstants {

     
     
     
     
    mapping (address => bool) public whitelist;

    constructor(address _resolver)
        public
    {
        require(init(CONTRACT_STORAGE_DAO_WHITELISTING, _resolver));
    }

    function setWhitelisted(address _contractAddress, bool _senderIsAllowedToRead)
        public
    {
        require(sender_is(CONTRACT_DAO_WHITELISTING));
        whitelist[_contractAddress] = _senderIsAllowedToRead;
    }
}

contract DaoWhitelistingCommon is ResolverClient, DaoConstants {

    function daoWhitelistingStorage()
        internal
        view
        returns (DaoWhitelistingStorage _contract)
    {
        _contract = DaoWhitelistingStorage(get_contract(CONTRACT_STORAGE_DAO_WHITELISTING));
    }

     
    function senderIsAllowedToRead()
        internal
        view
        returns (bool _senderIsAllowedToRead)
    {
         
        _senderIsAllowedToRead = (msg.sender == tx.origin) || daoWhitelistingStorage().whitelist(msg.sender);
    }
}

library DaoStructs {
    using DoublyLinkedList for DoublyLinkedList.Bytes;
    using SafeMath for uint256;
    bytes32 constant EMPTY_BYTES = bytes32(0x0);

    struct PrlAction {
         
        uint256 at;

         
        bytes32 doc;

         
         
        uint256 actionId;
    }

    struct Voting {
         
        uint256 startTime;

         
        mapping (bytes32 => bool) usedCommits;

         
         
         
         
        mapping (address => bytes32) commits;

         
         
         
         
        mapping (address => uint256) yesVotes;

         
         
         
         
        mapping (address => uint256) noVotes;

         
        bool passed;

         
         
        bool claimed;

         
         
        bool funded;
    }

    struct ProposalVersion {
         
        bytes32 docIpfsHash;

         
        uint256 created;

         
        uint256 milestoneCount;

         
        uint256 finalReward;

         
         
        uint256[] milestoneFundings;

         
         
         
        bytes32[] moreDocs;
    }

    struct Proposal {
         
        bytes32 proposalId;

         
         
        bytes32 currentState;

         
        uint256 timeCreated;

         
        DoublyLinkedList.Bytes proposalVersionDocs;

         
        mapping (bytes32 => ProposalVersion) proposalVersions;

         
        Voting draftVoting;

         
         
         
        mapping (uint256 => Voting) votingRounds;

         
         
         
         
        uint256 collateralStatus;
        uint256 collateralAmount;

         
         
         
        bytes32 finalVersion;

         
         
        PrlAction[] prlActions;

         
        address proposer;

         
        address endorser;

         
        bool isPausedOrStopped;

         
        bool isDigix;
    }

    function countVotes(Voting storage _voting, address[] _allUsers)
        external
        view
        returns (uint256 _for, uint256 _against)
    {
        uint256 _n = _allUsers.length;
        for (uint256 i = 0; i < _n; i++) {
            if (_voting.yesVotes[_allUsers[i]] > 0) {
                _for = _for.add(_voting.yesVotes[_allUsers[i]]);
            } else if (_voting.noVotes[_allUsers[i]] > 0) {
                _against = _against.add(_voting.noVotes[_allUsers[i]]);
            }
        }
    }

     
    function listVotes(Voting storage _voting, address[] _allUsers, bool _vote)
        external
        view
        returns (address[] memory _voters, uint256 _length)
    {
        uint256 _n = _allUsers.length;
        uint256 i;
        _length = 0;
        _voters = new address[](_n);
        if (_vote == true) {
            for (i = 0; i < _n; i++) {
                if (_voting.yesVotes[_allUsers[i]] > 0) {
                    _voters[_length] = _allUsers[i];
                    _length++;
                }
            }
        } else {
            for (i = 0; i < _n; i++) {
                if (_voting.noVotes[_allUsers[i]] > 0) {
                    _voters[_length] = _allUsers[i];
                    _length++;
                }
            }
        }
    }

    function readVote(Voting storage _voting, address _voter)
        public
        view
        returns (bool _vote, uint256 _weight)
    {
        if (_voting.yesVotes[_voter] > 0) {
            _weight = _voting.yesVotes[_voter];
            _vote = true;
        } else {
            _weight = _voting.noVotes[_voter];  
            _vote = false;
        }
    }

    function revealVote(
        Voting storage _voting,
        address _voter,
        bool _vote,
        uint256 _weight
    )
        public
    {
        if (_vote) {
            _voting.yesVotes[_voter] = _weight;
        } else {
            _voting.noVotes[_voter] = _weight;
        }
    }

    function readVersion(ProposalVersion storage _version)
        public
        view
        returns (
            bytes32 _doc,
            uint256 _created,
            uint256[] _milestoneFundings,
            uint256 _finalReward
        )
    {
        _doc = _version.docIpfsHash;
        _created = _version.created;
        _milestoneFundings = _version.milestoneFundings;
        _finalReward = _version.finalReward;
    }

     
     
    function readProposalMilestone(Proposal storage _proposal, uint256 _milestoneIndex)
        public
        view
        returns (uint256 _funding)
    {
        bytes32 _finalVersion = _proposal.finalVersion;
        uint256 _milestoneCount = _proposal.proposalVersions[_finalVersion].milestoneFundings.length;
        require(_milestoneIndex <= _milestoneCount);
        require(_finalVersion != EMPTY_BYTES);  

        if (_milestoneIndex < _milestoneCount) {
            _funding = _proposal.proposalVersions[_finalVersion].milestoneFundings[_milestoneIndex];
        } else {
            _funding = _proposal.proposalVersions[_finalVersion].finalReward;
        }
    }

    function addProposalVersion(
        Proposal storage _proposal,
        bytes32 _newDoc,
        uint256[] _newMilestoneFundings,
        uint256 _finalReward
    )
        public
    {
        _proposal.proposalVersionDocs.append(_newDoc);
        _proposal.proposalVersions[_newDoc].docIpfsHash = _newDoc;
        _proposal.proposalVersions[_newDoc].created = now;
        _proposal.proposalVersions[_newDoc].milestoneCount = _newMilestoneFundings.length;
        _proposal.proposalVersions[_newDoc].milestoneFundings = _newMilestoneFundings;
        _proposal.proposalVersions[_newDoc].finalReward = _finalReward;
    }

    struct SpecialProposal {
         
         
        bytes32 proposalId;

         
        uint256 timeCreated;

         
        Voting voting;

         
        uint256[] uintConfigs;

         
        address[] addressConfigs;

         
        bytes32[] bytesConfigs;

         
         
         
        address proposer;
    }

     
     
    struct DaoQuarterInfo {
         
         
        uint256 minimalParticipationPoint;

         
        uint256 quarterPointScalingFactor;

         
        uint256 reputationPointScalingFactor;

         
         
         
         
         
         
        uint256 totalEffectiveDGDPreviousQuarter;

         
         
        uint256 moderatorMinimalParticipationPoint;

         
        uint256 moderatorQuarterPointScalingFactor;

         
        uint256 moderatorReputationPointScalingFactor;

         
        uint256 totalEffectiveModeratorDGDLastQuarter;

         
        uint256 dgxDistributionDay;

         
         
         
        uint256 dgxRewardsPoolLastQuarter;

         
        uint256 sumRewardsFromBeginning;
    }

     
     
     
     
    struct IntermediateResults {
         
        uint256 currentForCount;

         
        uint256 currentAgainstCount;

         
        uint256 currentSumOfEffectiveBalance;

         
        address countedUntil;
    }
}

contract DaoStorage is DaoWhitelistingCommon, BytesIteratorStorage {
    using DoublyLinkedList for DoublyLinkedList.Bytes;
    using DaoStructs for DaoStructs.Voting;
    using DaoStructs for DaoStructs.Proposal;
    using DaoStructs for DaoStructs.ProposalVersion;

     
    DoublyLinkedList.Bytes allProposals;

     
     
    mapping (bytes32 => DaoStructs.Proposal) proposalsById;

     
     
     
    mapping (bytes32 => DoublyLinkedList.Bytes) proposalsByState;

    constructor(address _resolver) public {
        require(init(CONTRACT_STORAGE_DAO, _resolver));
    }

     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function readProposal(bytes32 _proposalId)
        public
        view
        returns (
            bytes32 _doc,
            address _proposer,
            address _endorser,
            bytes32 _state,
            uint256 _timeCreated,
            uint256 _nVersions,
            bytes32 _latestVersionDoc,
            bytes32 _finalVersion,
            bool _pausedOrStopped,
            bool _isDigixProposal
        )
    {
        require(senderIsAllowedToRead());
        DaoStructs.Proposal storage _proposal = proposalsById[_proposalId];
        _doc = _proposal.proposalId;
        _proposer = _proposal.proposer;
        _endorser = _proposal.endorser;
        _state = _proposal.currentState;
        _timeCreated = _proposal.timeCreated;
        _nVersions = read_total_bytesarray(_proposal.proposalVersionDocs);
        _latestVersionDoc = read_last_from_bytesarray(_proposal.proposalVersionDocs);
        _finalVersion = _proposal.finalVersion;
        _pausedOrStopped = _proposal.isPausedOrStopped;
        _isDigixProposal = _proposal.isDigix;
    }

    function readProposalProposer(bytes32 _proposalId)
        public
        view
        returns (address _proposer)
    {
        _proposer = proposalsById[_proposalId].proposer;
    }

    function readTotalPrlActions(bytes32 _proposalId)
        public
        view
        returns (uint256 _length)
    {
        _length = proposalsById[_proposalId].prlActions.length;
    }

    function readPrlAction(bytes32 _proposalId, uint256 _index)
        public
        view
        returns (uint256 _actionId, uint256 _time, bytes32 _doc)
    {
        DaoStructs.PrlAction[] memory _actions = proposalsById[_proposalId].prlActions;
        require(_index < _actions.length);
        _actionId = _actions[_index].actionId;
        _time = _actions[_index].at;
        _doc = _actions[_index].doc;
    }

    function readProposalDraftVotingResult(bytes32 _proposalId)
        public
        view
        returns (bool _result)
    {
        require(senderIsAllowedToRead());
        _result = proposalsById[_proposalId].draftVoting.passed;
    }

    function readProposalVotingResult(bytes32 _proposalId, uint256 _index)
        public
        view
        returns (bool _result)
    {
        require(senderIsAllowedToRead());
        _result = proposalsById[_proposalId].votingRounds[_index].passed;
    }

    function readProposalDraftVotingTime(bytes32 _proposalId)
        public
        view
        returns (uint256 _start)
    {
        require(senderIsAllowedToRead());
        _start = proposalsById[_proposalId].draftVoting.startTime;
    }

    function readProposalVotingTime(bytes32 _proposalId, uint256 _index)
        public
        view
        returns (uint256 _start)
    {
        require(senderIsAllowedToRead());
        _start = proposalsById[_proposalId].votingRounds[_index].startTime;
    }

    function readDraftVotingCount(bytes32 _proposalId, address[] _allUsers)
        external
        view
        returns (uint256 _for, uint256 _against)
    {
        require(senderIsAllowedToRead());
        return proposalsById[_proposalId].draftVoting.countVotes(_allUsers);
    }

    function readVotingCount(bytes32 _proposalId, uint256 _index, address[] _allUsers)
        external
        view
        returns (uint256 _for, uint256 _against)
    {
        require(senderIsAllowedToRead());
        return proposalsById[_proposalId].votingRounds[_index].countVotes(_allUsers);
    }

    function readVotingRoundVotes(bytes32 _proposalId, uint256 _index, address[] _allUsers, bool _vote)
        external
        view
        returns (address[] memory _voters, uint256 _length)
    {
        require(senderIsAllowedToRead());
        return proposalsById[_proposalId].votingRounds[_index].listVotes(_allUsers, _vote);
    }

    function readDraftVote(bytes32 _proposalId, address _voter)
        public
        view
        returns (bool _vote, uint256 _weight)
    {
        require(senderIsAllowedToRead());
        return proposalsById[_proposalId].draftVoting.readVote(_voter);
    }

     
     
     
     
     
     
    function readComittedVote(bytes32 _proposalId, uint256 _index, address _voter)
        public
        view
        returns (bytes32 _commitHash)
    {
        require(senderIsAllowedToRead());
        _commitHash = proposalsById[_proposalId].votingRounds[_index].commits[_voter];
    }

    function readVote(bytes32 _proposalId, uint256 _index, address _voter)
        public
        view
        returns (bool _vote, uint256 _weight)
    {
        require(senderIsAllowedToRead());
        return proposalsById[_proposalId].votingRounds[_index].readVote(_voter);
    }

     
     
     
     
    function getFirstProposal()
        public
        view
        returns (bytes32 _id)
    {
        _id = read_first_from_bytesarray(allProposals);
    }

     
     
     
     
    function getLastProposal()
        public
        view
        returns (bytes32 _id)
    {
        _id = read_last_from_bytesarray(allProposals);
    }

     
     
     
     
     
    function getNextProposal(bytes32 _proposalId)
        public
        view
        returns (bytes32 _id)
    {
        _id = read_next_from_bytesarray(
            allProposals,
            _proposalId
        );
    }

     
     
     
     
     
    function getPreviousProposal(bytes32 _proposalId)
        public
        view
        returns (bytes32 _id)
    {
        _id = read_previous_from_bytesarray(
            allProposals,
            _proposalId
        );
    }

     
     
     
     
     
    function getFirstProposalInState(bytes32 _stateId)
        public
        view
        returns (bytes32 _id)
    {
        require(senderIsAllowedToRead());
        _id = read_first_from_bytesarray(proposalsByState[_stateId]);
    }

     
     
     
     
     
    function getLastProposalInState(bytes32 _stateId)
        public
        view
        returns (bytes32 _id)
    {
        require(senderIsAllowedToRead());
        _id = read_last_from_bytesarray(proposalsByState[_stateId]);
    }

     
     
     
     
     
    function getNextProposalInState(bytes32 _stateId, bytes32 _proposalId)
        public
        view
        returns (bytes32 _id)
    {
        require(senderIsAllowedToRead());
        _id = read_next_from_bytesarray(
            proposalsByState[_stateId],
            _proposalId
        );
    }

     
     
     
     
     
    function getPreviousProposalInState(bytes32 _stateId, bytes32 _proposalId)
        public
        view
        returns (bytes32 _id)
    {
        require(senderIsAllowedToRead());
        _id = read_previous_from_bytesarray(
            proposalsByState[_stateId],
            _proposalId
        );
    }

     
     
     
     
     
     
     
     
    function readProposalVersion(bytes32 _proposalId, bytes32 _version)
        public
        view
        returns (
            bytes32 _doc,
            uint256 _created,
            uint256[] _milestoneFundings,
            uint256 _finalReward
        )
    {
        return proposalsById[_proposalId].proposalVersions[_version].readVersion();
    }

     
    function readProposalFunding(bytes32 _proposalId)
        public
        view
        returns (uint256[] memory _fundings, uint256 _finalReward)
    {
        require(senderIsAllowedToRead());
        bytes32 _finalVersion = proposalsById[_proposalId].finalVersion;
        require(_finalVersion != EMPTY_BYTES);
        _fundings = proposalsById[_proposalId].proposalVersions[_finalVersion].milestoneFundings;
        _finalReward = proposalsById[_proposalId].proposalVersions[_finalVersion].finalReward;
    }

    function readProposalMilestone(bytes32 _proposalId, uint256 _index)
        public
        view
        returns (uint256 _funding)
    {
        require(senderIsAllowedToRead());
        _funding = proposalsById[_proposalId].readProposalMilestone(_index);
    }

     
     
     
     
     
    function getFirstProposalVersion(bytes32 _proposalId)
        public
        view
        returns (bytes32 _version)
    {
        DaoStructs.Proposal storage _proposal = proposalsById[_proposalId];
        _version = read_first_from_bytesarray(_proposal.proposalVersionDocs);
    }

     
     
     
     
     
    function getLastProposalVersion(bytes32 _proposalId)
        public
        view
        returns (bytes32 _version)
    {
        DaoStructs.Proposal storage _proposal = proposalsById[_proposalId];
        _version = read_last_from_bytesarray(_proposal.proposalVersionDocs);
    }

     
     
     
     
     
     
    function getNextProposalVersion(bytes32 _proposalId, bytes32 _version)
        public
        view
        returns (bytes32 _nextVersion)
    {
        DaoStructs.Proposal storage _proposal = proposalsById[_proposalId];
        _nextVersion = read_next_from_bytesarray(
            _proposal.proposalVersionDocs,
            _version
        );
    }

     
     
     
     
     
     
    function getPreviousProposalVersion(bytes32 _proposalId, bytes32 _version)
        public
        view
        returns (bytes32 _previousVersion)
    {
        DaoStructs.Proposal storage _proposal = proposalsById[_proposalId];
        _previousVersion = read_previous_from_bytesarray(
            _proposal.proposalVersionDocs,
            _version
        );
    }

    function isDraftClaimed(bytes32 _proposalId)
        public
        view
        returns (bool _claimed)
    {
        _claimed = proposalsById[_proposalId].draftVoting.claimed;
    }

    function isClaimed(bytes32 _proposalId, uint256 _index)
        public
        view
        returns (bool _claimed)
    {
        _claimed = proposalsById[_proposalId].votingRounds[_index].claimed;
    }

    function readProposalCollateralStatus(bytes32 _proposalId)
        public
        view
        returns (uint256 _status)
    {
        require(senderIsAllowedToRead());
        _status = proposalsById[_proposalId].collateralStatus;
    }

    function readProposalCollateralAmount(bytes32 _proposalId)
        public
        view
        returns (uint256 _amount)
    {
        _amount = proposalsById[_proposalId].collateralAmount;
    }

     
     
    function readProposalDocs(bytes32 _proposalId)
        public
        view
        returns (bytes32[] _moreDocs)
    {
        bytes32 _finalVersion = proposalsById[_proposalId].finalVersion;
        require(_finalVersion != EMPTY_BYTES);
        _moreDocs = proposalsById[_proposalId].proposalVersions[_finalVersion].moreDocs;
    }

    function readIfMilestoneFunded(bytes32 _proposalId, uint256 _milestoneId)
        public
        view
        returns (bool _funded)
    {
        require(senderIsAllowedToRead());
        _funded = proposalsById[_proposalId].votingRounds[_milestoneId].funded;
    }

     

    function addProposal(
        bytes32 _doc,
        address _proposer,
        uint256[] _milestoneFundings,
        uint256 _finalReward,
        bool _isFounder
    )
        external
    {
        require(sender_is(CONTRACT_DAO));
        require(
          (proposalsById[_doc].proposalId == EMPTY_BYTES) &&
          (_doc != EMPTY_BYTES)
        );

        allProposals.append(_doc);
        proposalsByState[PROPOSAL_STATE_PREPROPOSAL].append(_doc);
        proposalsById[_doc].proposalId = _doc;
        proposalsById[_doc].proposer = _proposer;
        proposalsById[_doc].currentState = PROPOSAL_STATE_PREPROPOSAL;
        proposalsById[_doc].timeCreated = now;
        proposalsById[_doc].isDigix = _isFounder;
        proposalsById[_doc].addProposalVersion(_doc, _milestoneFundings, _finalReward);
    }

    function editProposal(
        bytes32 _proposalId,
        bytes32 _newDoc,
        uint256[] _newMilestoneFundings,
        uint256 _finalReward
    )
        external
    {
        require(sender_is(CONTRACT_DAO));

        proposalsById[_proposalId].addProposalVersion(_newDoc, _newMilestoneFundings, _finalReward);
    }

     
     
    function changeFundings(bytes32 _proposalId, uint256[] _newMilestoneFundings, uint256 _finalReward)
        external
    {
        require(sender_is(CONTRACT_DAO));

        bytes32 _finalVersion = proposalsById[_proposalId].finalVersion;
        require(_finalVersion != EMPTY_BYTES);
        proposalsById[_proposalId].proposalVersions[_finalVersion].milestoneFundings = _newMilestoneFundings;
        proposalsById[_proposalId].proposalVersions[_finalVersion].finalReward = _finalReward;
    }

     
    function addProposalDoc(bytes32 _proposalId, bytes32 _newDoc)
        public
    {
        require(sender_is(CONTRACT_DAO));

        bytes32 _finalVersion = proposalsById[_proposalId].finalVersion;
        require(_finalVersion != EMPTY_BYTES);  
        proposalsById[_proposalId].proposalVersions[_finalVersion].moreDocs.push(_newDoc);
    }

    function finalizeProposal(bytes32 _proposalId)
        public
    {
        require(sender_is(CONTRACT_DAO));

        proposalsById[_proposalId].finalVersion = getLastProposalVersion(_proposalId);
    }

    function updateProposalEndorse(
        bytes32 _proposalId,
        address _endorser
    )
        public
    {
        require(sender_is(CONTRACT_DAO));

        DaoStructs.Proposal storage _proposal = proposalsById[_proposalId];
        _proposal.endorser = _endorser;
        _proposal.currentState = PROPOSAL_STATE_DRAFT;
        proposalsByState[PROPOSAL_STATE_PREPROPOSAL].remove_item(_proposalId);
        proposalsByState[PROPOSAL_STATE_DRAFT].append(_proposalId);
    }

    function setProposalDraftPass(bytes32 _proposalId, bool _result)
        public
    {
        require(sender_is(CONTRACT_DAO_VOTING_CLAIMS));

        proposalsById[_proposalId].draftVoting.passed = _result;
        if (_result) {
            proposalsByState[PROPOSAL_STATE_DRAFT].remove_item(_proposalId);
            proposalsByState[PROPOSAL_STATE_MODERATED].append(_proposalId);
            proposalsById[_proposalId].currentState = PROPOSAL_STATE_MODERATED;
        } else {
            closeProposalInternal(_proposalId);
        }
    }

    function setProposalPass(bytes32 _proposalId, uint256 _index, bool _result)
        public
    {
        require(sender_is(CONTRACT_DAO_VOTING_CLAIMS));

        if (!_result) {
            closeProposalInternal(_proposalId);
        } else if (_index == 0) {
            proposalsByState[PROPOSAL_STATE_MODERATED].remove_item(_proposalId);
            proposalsByState[PROPOSAL_STATE_ONGOING].append(_proposalId);
            proposalsById[_proposalId].currentState = PROPOSAL_STATE_ONGOING;
        }
        proposalsById[_proposalId].votingRounds[_index].passed = _result;
    }

    function setProposalDraftVotingTime(
        bytes32 _proposalId,
        uint256 _time
    )
        public
    {
        require(sender_is(CONTRACT_DAO));

        proposalsById[_proposalId].draftVoting.startTime = _time;
    }

    function setProposalVotingTime(
        bytes32 _proposalId,
        uint256 _index,
        uint256 _time
    )
        public
    {
        require(sender_is_from([CONTRACT_DAO, CONTRACT_DAO_VOTING_CLAIMS, EMPTY_BYTES]));

        proposalsById[_proposalId].votingRounds[_index].startTime = _time;
    }

    function setDraftVotingClaim(bytes32 _proposalId, bool _claimed)
        public
    {
        require(sender_is(CONTRACT_DAO_VOTING_CLAIMS));
        proposalsById[_proposalId].draftVoting.claimed = _claimed;
    }

    function setVotingClaim(bytes32 _proposalId, uint256 _index, bool _claimed)
        public
    {
        require(sender_is(CONTRACT_DAO_VOTING_CLAIMS));
        proposalsById[_proposalId].votingRounds[_index].claimed = _claimed;
    }

    function setProposalCollateralStatus(bytes32 _proposalId, uint256 _status)
        public
    {
        require(sender_is_from([CONTRACT_DAO_VOTING_CLAIMS, CONTRACT_DAO_FUNDING_MANAGER, CONTRACT_DAO]));
        proposalsById[_proposalId].collateralStatus = _status;
    }

    function setProposalCollateralAmount(bytes32 _proposalId, uint256 _amount)
        public
    {
        require(sender_is(CONTRACT_DAO));
        proposalsById[_proposalId].collateralAmount = _amount;
    }

    function updateProposalPRL(
        bytes32 _proposalId,
        uint256 _action,
        bytes32 _doc,
        uint256 _time
    )
        public
    {
        require(sender_is(CONTRACT_DAO));
        require(proposalsById[_proposalId].currentState != PROPOSAL_STATE_CLOSED);

        DaoStructs.PrlAction memory prlAction;
        prlAction.at = _time;
        prlAction.doc = _doc;
        prlAction.actionId = _action;
        proposalsById[_proposalId].prlActions.push(prlAction);

        if (_action == PRL_ACTION_PAUSE) {
          proposalsById[_proposalId].isPausedOrStopped = true;
        } else if (_action == PRL_ACTION_UNPAUSE) {
          proposalsById[_proposalId].isPausedOrStopped = false;
        } else {  
          proposalsById[_proposalId].isPausedOrStopped = true;
          closeProposalInternal(_proposalId);
        }
    }

    function closeProposalInternal(bytes32 _proposalId)
        internal
    {
        bytes32 _currentState = proposalsById[_proposalId].currentState;
        proposalsByState[_currentState].remove_item(_proposalId);
        proposalsByState[PROPOSAL_STATE_CLOSED].append(_proposalId);
        proposalsById[_proposalId].currentState = PROPOSAL_STATE_CLOSED;
    }

    function addDraftVote(
        bytes32 _proposalId,
        address _voter,
        bool _vote,
        uint256 _weight
    )
        public
    {
        require(sender_is(CONTRACT_DAO_VOTING));

        DaoStructs.Proposal storage _proposal = proposalsById[_proposalId];
        if (_vote) {
            _proposal.draftVoting.yesVotes[_voter] = _weight;
            if (_proposal.draftVoting.noVotes[_voter] > 0) {  
                _proposal.draftVoting.noVotes[_voter] = 0;
            }
        } else {
            _proposal.draftVoting.noVotes[_voter] = _weight;
            if (_proposal.draftVoting.yesVotes[_voter] > 0) {
                _proposal.draftVoting.yesVotes[_voter] = 0;
            }
        }
    }

    function commitVote(
        bytes32 _proposalId,
        bytes32 _hash,
        address _voter,
        uint256 _index
    )
        public
    {
        require(sender_is(CONTRACT_DAO_VOTING));

        proposalsById[_proposalId].votingRounds[_index].commits[_voter] = _hash;
    }

    function revealVote(
        bytes32 _proposalId,
        address _voter,
        bool _vote,
        uint256 _weight,
        uint256 _index
    )
        public
    {
        require(sender_is(CONTRACT_DAO_VOTING));

        proposalsById[_proposalId].votingRounds[_index].revealVote(_voter, _vote, _weight);
    }

    function closeProposal(bytes32 _proposalId)
        public
    {
        require(sender_is(CONTRACT_DAO));
        closeProposalInternal(_proposalId);
    }

    function archiveProposal(bytes32 _proposalId)
        public
    {
        require(sender_is(CONTRACT_DAO_VOTING_CLAIMS));
        bytes32 _currentState = proposalsById[_proposalId].currentState;
        proposalsByState[_currentState].remove_item(_proposalId);
        proposalsByState[PROPOSAL_STATE_ARCHIVED].append(_proposalId);
        proposalsById[_proposalId].currentState = PROPOSAL_STATE_ARCHIVED;
    }

    function setMilestoneFunded(bytes32 _proposalId, uint256 _milestoneId)
        public
    {
        require(sender_is(CONTRACT_DAO_FUNDING_MANAGER));
        proposalsById[_proposalId].votingRounds[_milestoneId].funded = true;
    }
}

 
contract AddressIteratorStorage {

   
  using DoublyLinkedList for DoublyLinkedList.Address;

   
  function read_first_from_addresses(DoublyLinkedList.Address storage _list)
           internal
           constant
           returns (address _item)
  {
    _item = _list.start_item();
  }


   
  function read_last_from_addresses(DoublyLinkedList.Address storage _list)
           internal
           constant
           returns (address _item)
  {
    _item = _list.end_item();
  }

   
  function read_next_from_addresses(DoublyLinkedList.Address storage _list, address _current_item)
           internal
           constant
           returns (address _item)
  {
    _item = _list.next_item(_current_item);
  }

   
  function read_previous_from_addresses(DoublyLinkedList.Address storage _list, address _current_item)
           internal
           constant
           returns (address _item)
  {
    _item = _list.previous_item(_current_item);
  }

   
  function read_total_addresses(DoublyLinkedList.Address storage _list)
           internal
           constant
           returns (uint256 _count)
  {
    _count = _list.total();
  }
}

contract DaoStakeStorage is ResolverClient, DaoConstants, AddressIteratorStorage {
    using DoublyLinkedList for DoublyLinkedList.Address;

     
    mapping (address => uint256) public lockedDGDStake;

     
     
     
    mapping (address => uint256) public actualLockedDGD;

     
    uint256 public totalLockedDGDStake;

     
    uint256 public totalModeratorLockedDGDStake;

     
     
    DoublyLinkedList.Address allParticipants;

     
     
    DoublyLinkedList.Address allModerators;

     
     
    mapping (address => bool) public redeemedBadge;

     
     
    mapping (address => bool) public carbonVoteBonusClaimed;

    constructor(address _resolver) public {
        require(init(CONTRACT_STORAGE_DAO_STAKE, _resolver));
    }

    function redeemBadge(address _user)
        public
    {
        require(sender_is(CONTRACT_DAO_STAKE_LOCKING));
        redeemedBadge[_user] = true;
    }

    function setCarbonVoteBonusClaimed(address _user)
        public
    {
        require(sender_is(CONTRACT_DAO_STAKE_LOCKING));
        carbonVoteBonusClaimed[_user] = true;
    }

    function updateTotalLockedDGDStake(uint256 _totalLockedDGDStake)
        public
    {
        require(sender_is_from([CONTRACT_DAO_STAKE_LOCKING, CONTRACT_DAO_REWARDS_MANAGER, EMPTY_BYTES]));
        totalLockedDGDStake = _totalLockedDGDStake;
    }

    function updateTotalModeratorLockedDGDs(uint256 _totalLockedDGDStake)
        public
    {
        require(sender_is_from([CONTRACT_DAO_STAKE_LOCKING, CONTRACT_DAO_REWARDS_MANAGER, EMPTY_BYTES]));
        totalModeratorLockedDGDStake = _totalLockedDGDStake;
    }

    function updateUserDGDStake(address _user, uint256 _actualLockedDGD, uint256 _lockedDGDStake)
        public
    {
        require(sender_is(CONTRACT_DAO_STAKE_LOCKING));
        actualLockedDGD[_user] = _actualLockedDGD;
        lockedDGDStake[_user] = _lockedDGDStake;
    }

    function readUserDGDStake(address _user)
        public
        view
        returns (
            uint256 _actualLockedDGD,
            uint256 _lockedDGDStake
        )
    {
        _actualLockedDGD = actualLockedDGD[_user];
        _lockedDGDStake = lockedDGDStake[_user];
    }

    function addToParticipantList(address _user)
        public
        returns (bool _success)
    {
        require(sender_is(CONTRACT_DAO_STAKE_LOCKING));
        _success = allParticipants.append(_user);
    }

    function removeFromParticipantList(address _user)
        public
        returns (bool _success)
    {
        require(sender_is(CONTRACT_DAO_STAKE_LOCKING));
        _success = allParticipants.remove_item(_user);
    }

    function addToModeratorList(address _user)
        public
        returns (bool _success)
    {
        require(sender_is(CONTRACT_DAO_STAKE_LOCKING));
        _success = allModerators.append(_user);
    }

    function removeFromModeratorList(address _user)
        public
        returns (bool _success)
    {
        require(sender_is(CONTRACT_DAO_STAKE_LOCKING));
        _success = allModerators.remove_item(_user);
    }

    function isInParticipantList(address _user)
        public
        view
        returns (bool _is)
    {
        _is = allParticipants.find(_user) != 0;
    }

    function isInModeratorsList(address _user)
        public
        view
        returns (bool _is)
    {
        _is = allModerators.find(_user) != 0;
    }

    function readFirstModerator()
        public
        view
        returns (address _item)
    {
        _item = read_first_from_addresses(allModerators);
    }

    function readLastModerator()
        public
        view
        returns (address _item)
    {
        _item = read_last_from_addresses(allModerators);
    }

    function readNextModerator(address _current_item)
        public
        view
        returns (address _item)
    {
        _item = read_next_from_addresses(allModerators, _current_item);
    }

    function readPreviousModerator(address _current_item)
        public
        view
        returns (address _item)
    {
        _item = read_previous_from_addresses(allModerators, _current_item);
    }

    function readTotalModerators()
        public
        view
        returns (uint256 _total_count)
    {
        _total_count = read_total_addresses(allModerators);
    }

    function readFirstParticipant()
        public
        view
        returns (address _item)
    {
        _item = read_first_from_addresses(allParticipants);
    }

    function readLastParticipant()
        public
        view
        returns (address _item)
    {
        _item = read_last_from_addresses(allParticipants);
    }

    function readNextParticipant(address _current_item)
        public
        view
        returns (address _item)
    {
        _item = read_next_from_addresses(allParticipants, _current_item);
    }

    function readPreviousParticipant(address _current_item)
        public
        view
        returns (address _item)
    {
        _item = read_previous_from_addresses(allParticipants, _current_item);
    }

    function readTotalParticipant()
        public
        view
        returns (uint256 _total_count)
    {
        _total_count = read_total_addresses(allParticipants);
    }
}

 
contract DaoListingService is
    AddressIteratorInteractive,
    BytesIteratorInteractive,
    IndexedBytesIteratorInteractive,
    DaoWhitelistingCommon
{

     
    constructor(address _resolver) public {
        require(init(CONTRACT_SERVICE_DAO_LISTING, _resolver));
    }

    function daoStakeStorage()
        internal
        view
        returns (DaoStakeStorage _contract)
    {
        _contract = DaoStakeStorage(get_contract(CONTRACT_STORAGE_DAO_STAKE));
    }

    function daoStorage()
        internal
        view
        returns (DaoStorage _contract)
    {
        _contract = DaoStorage(get_contract(CONTRACT_STORAGE_DAO));
    }

     
    function listModerators(uint256 _count, bool _from_start)
        public
        view
        returns (address[] _moderators)
    {
        _moderators = list_addresses(
            _count,
            daoStakeStorage().readFirstModerator,
            daoStakeStorage().readLastModerator,
            daoStakeStorage().readNextModerator,
            daoStakeStorage().readPreviousModerator,
            _from_start
        );
    }

     
    function listModeratorsFrom(
        address _currentModerator,
        uint256 _count,
        bool _from_start
    )
        public
        view
        returns (address[] _moderators)
    {
        _moderators = list_addresses_from(
            _currentModerator,
            _count,
            daoStakeStorage().readFirstModerator,
            daoStakeStorage().readLastModerator,
            daoStakeStorage().readNextModerator,
            daoStakeStorage().readPreviousModerator,
            _from_start
        );
    }

     
    function listParticipants(uint256 _count, bool _from_start)
        public
        view
        returns (address[] _participants)
    {
        _participants = list_addresses(
            _count,
            daoStakeStorage().readFirstParticipant,
            daoStakeStorage().readLastParticipant,
            daoStakeStorage().readNextParticipant,
            daoStakeStorage().readPreviousParticipant,
            _from_start
        );
    }

     
    function listParticipantsFrom(
        address _currentParticipant,
        uint256 _count,
        bool _from_start
    )
        public
        view
        returns (address[] _participants)
    {
        _participants = list_addresses_from(
            _currentParticipant,
            _count,
            daoStakeStorage().readFirstParticipant,
            daoStakeStorage().readLastParticipant,
            daoStakeStorage().readNextParticipant,
            daoStakeStorage().readPreviousParticipant,
            _from_start
        );
    }

     
    function listProposals(
        uint256 _count,
        bool _from_start
    )
        public
        view
        returns (bytes32[] _proposals)
    {
        _proposals = list_bytesarray(
            _count,
            daoStorage().getFirstProposal,
            daoStorage().getLastProposal,
            daoStorage().getNextProposal,
            daoStorage().getPreviousProposal,
            _from_start
        );
    }

     
    function listProposalsFrom(
        bytes32 _currentProposal,
        uint256 _count,
        bool _from_start
    )
        public
        view
        returns (bytes32[] _proposals)
    {
        _proposals = list_bytesarray_from(
            _currentProposal,
            _count,
            daoStorage().getFirstProposal,
            daoStorage().getLastProposal,
            daoStorage().getNextProposal,
            daoStorage().getPreviousProposal,
            _from_start
        );
    }

     
    function listProposalsInState(
        bytes32 _stateId,
        uint256 _count,
        bool _from_start
    )
        public
        view
        returns (bytes32[] _proposals)
    {
        require(senderIsAllowedToRead());
        _proposals = list_indexed_bytesarray(
            _stateId,
            _count,
            daoStorage().getFirstProposalInState,
            daoStorage().getLastProposalInState,
            daoStorage().getNextProposalInState,
            daoStorage().getPreviousProposalInState,
            _from_start
        );
    }

     
    function listProposalsInStateFrom(
        bytes32 _stateId,
        bytes32 _currentProposal,
        uint256 _count,
        bool _from_start
    )
        public
        view
        returns (bytes32[] _proposals)
    {
        require(senderIsAllowedToRead());
        _proposals = list_indexed_bytesarray_from(
            _stateId,
            _currentProposal,
            _count,
            daoStorage().getFirstProposalInState,
            daoStorage().getLastProposalInState,
            daoStorage().getNextProposalInState,
            daoStorage().getPreviousProposalInState,
            _from_start
        );
    }

     
    function listProposalVersions(
        bytes32 _proposalId,
        uint256 _count,
        bool _from_start
    )
        public
        view
        returns (bytes32[] _versions)
    {
        _versions = list_indexed_bytesarray(
            _proposalId,
            _count,
            daoStorage().getFirstProposalVersion,
            daoStorage().getLastProposalVersion,
            daoStorage().getNextProposalVersion,
            daoStorage().getPreviousProposalVersion,
            _from_start
        );
    }

     
    function listProposalVersionsFrom(
        bytes32 _proposalId,
        bytes32 _currentVersion,
        uint256 _count,
        bool _from_start
    )
        public
        view
        returns (bytes32[] _versions)
    {
        _versions = list_indexed_bytesarray_from(
            _proposalId,
            _currentVersion,
            _count,
            daoStorage().getFirstProposalVersion,
            daoStorage().getLastProposalVersion,
            daoStorage().getNextProposalVersion,
            daoStorage().getPreviousProposalVersion,
            _from_start
        );
    }
}

 
contract IndexedAddressIteratorStorage {

  using DoublyLinkedList for DoublyLinkedList.IndexedAddress;
   
  function read_first_from_indexed_addresses(DoublyLinkedList.IndexedAddress storage _list, bytes32 _collection_index)
           internal
           constant
           returns (address _item)
  {
    _item = _list.start_item(_collection_index);
  }

   
  function read_last_from_indexed_addresses(DoublyLinkedList.IndexedAddress storage _list, bytes32 _collection_index)
           internal
           constant
           returns (address _item)
  {
    _item = _list.end_item(_collection_index);
  }

   
  function read_next_from_indexed_addresses(DoublyLinkedList.IndexedAddress storage _list, bytes32 _collection_index, address _current_item)
           internal
           constant
           returns (address _item)
  {
    _item = _list.next_item(_collection_index, _current_item);
  }

   
  function read_previous_from_indexed_addresses(DoublyLinkedList.IndexedAddress storage _list, bytes32 _collection_index, address _current_item)
           internal
           constant
           returns (address _item)
  {
    _item = _list.previous_item(_collection_index, _current_item);
  }


   
  function read_total_indexed_addresses(DoublyLinkedList.IndexedAddress storage _list, bytes32 _collection_index)
           internal
           constant
           returns (uint256 _count)
  {
    _count = _list.total(_collection_index);
  }
}

 
contract UintIteratorStorage {

  using DoublyLinkedList for DoublyLinkedList.Uint;

   
  function read_first_from_uints(DoublyLinkedList.Uint storage _list)
           internal
           constant
           returns (uint256 _item)
  {
    _item = _list.start_item();
  }

   
  function read_last_from_uints(DoublyLinkedList.Uint storage _list)
           internal
           constant
           returns (uint256 _item)
  {
    _item = _list.end_item();
  }

   
  function read_next_from_uints(DoublyLinkedList.Uint storage _list, uint256 _current_item)
           internal
           constant
           returns (uint256 _item)
  {
    _item = _list.next_item(_current_item);
  }

   
  function read_previous_from_uints(DoublyLinkedList.Uint storage _list, uint256 _current_item)
           internal
           constant
           returns (uint256 _item)
  {
    _item = _list.previous_item(_current_item);
  }

   
  function read_total_uints(DoublyLinkedList.Uint storage _list)
           internal
           constant
           returns (uint256 _count)
  {
    _count = _list.total();
  }
}

 
contract DirectoryStorage is IndexedAddressIteratorStorage, UintIteratorStorage {

  using DoublyLinkedList for DoublyLinkedList.IndexedAddress;
  using DoublyLinkedList for DoublyLinkedList.Uint;

  struct User {
    bytes32 document;
    bool active;
  }

  struct Group {
    bytes32 name;
    bytes32 document;
    uint256 role_id;
    mapping(address => User) members_by_address;
  }

  struct System {
    DoublyLinkedList.Uint groups;
    DoublyLinkedList.IndexedAddress groups_collection;
    mapping (uint256 => Group) groups_by_id;
    mapping (address => uint256) group_ids_by_address;
    mapping (uint256 => bytes32) roles_by_id;
    bool initialized;
    uint256 total_groups;
  }

  System system;

   
  function initialize_directory()
           internal
           returns (bool _success)
  {
    require(system.initialized == false);
    system.total_groups = 0;
    system.initialized = true;
    internal_create_role(1, "root");
    internal_create_group(1, "root", "");
    _success = internal_update_add_user_to_group(1, tx.origin, "");
  }

   
  function internal_create_role(uint256 _role_id, bytes32 _name)
           internal
           returns (bool _success)
  {
    require(_role_id > 0);
    require(_name != bytes32(0x0));
    system.roles_by_id[_role_id] = _name;
    _success = true;
  }

   
  function read_role(uint256 _role_id)
           public
           constant
           returns (bytes32 _name)
  {
    _name = system.roles_by_id[_role_id];
  }

   
  function internal_create_group(uint256 _role_id, bytes32 _name, bytes32 _document)
           internal
           returns (bool _success, uint256 _group_id)
  {
    require(_role_id > 0);
    require(read_role(_role_id) != bytes32(0x0));
    _group_id = ++system.total_groups;
    system.groups.append(_group_id);
    system.groups_by_id[_group_id].role_id = _role_id;
    system.groups_by_id[_group_id].name = _name;
    system.groups_by_id[_group_id].document = _document;
    _success = true;
  }

   
  function read_group(uint256 _group_id)
           public
           constant
           returns (uint256 _role_id, bytes32 _name, bytes32 _document, uint256 _members_count)
  {
    if (system.groups.valid_item(_group_id)) {
      _role_id = system.groups_by_id[_group_id].role_id;
      _name = system.groups_by_id[_group_id].name;
      _document = system.groups_by_id[_group_id].document;
      _members_count = read_total_indexed_addresses(system.groups_collection, bytes32(_group_id));
    } else {
      _role_id = 0;
      _name = "invalid";
      _document = "";
      _members_count = 0;
    }
  }

   
  function internal_update_add_user_to_group(uint256 _group_id, address _user, bytes32 _document)
           internal
           returns (bool _success)
  {
    if (system.groups_by_id[_group_id].members_by_address[_user].active == false && system.group_ids_by_address[_user] == 0 && system.groups_by_id[_group_id].role_id != 0) {

      system.groups_by_id[_group_id].members_by_address[_user].active = true;
      system.group_ids_by_address[_user] = _group_id;
      system.groups_collection.append(bytes32(_group_id), _user);
      system.groups_by_id[_group_id].members_by_address[_user].document = _document;
      _success = true;
    } else {
      _success = false;
    }
  }

   
  function internal_destroy_group_user(address _user)
           internal
           returns (bool _success)
  {
    uint256 _group_id = system.group_ids_by_address[_user];
    if ((_group_id == 1) && (system.groups_collection.total(bytes32(_group_id)) == 1)) {
      _success = false;
    } else {
      system.groups_by_id[_group_id].members_by_address[_user].active = false;
      system.group_ids_by_address[_user] = 0;
      delete system.groups_by_id[_group_id].members_by_address[_user];
      _success = system.groups_collection.remove_item(bytes32(_group_id), _user);
    }
  }

   
  function read_user_role_id(address _user)
           constant
           public
           returns (uint256 _role_id)
  {
    uint256 _group_id = system.group_ids_by_address[_user];
    _role_id = system.groups_by_id[_group_id].role_id;
  }

   
  function read_user(address _user)
           public
           constant
           returns (uint256 _group_id, uint256 _role_id, bytes32 _document)
  {
    _group_id = system.group_ids_by_address[_user];
    _role_id = system.groups_by_id[_group_id].role_id;
    _document = system.groups_by_id[_group_id].members_by_address[_user].document;
  }

   
  function read_first_group()
           view
           external
           returns (uint256 _group_id)
  {
    _group_id = read_first_from_uints(system.groups);
  }

   
  function read_last_group()
           view
           external
           returns (uint256 _group_id)
  {
    _group_id = read_last_from_uints(system.groups);
  }

   
  function read_previous_group_from_group(uint256 _current_group_id)
           view
           external
           returns (uint256 _group_id)
  {
    _group_id = read_previous_from_uints(system.groups, _current_group_id);
  }

   
  function read_next_group_from_group(uint256 _current_group_id)
           view
           external
           returns (uint256 _group_id)
  {
    _group_id = read_next_from_uints(system.groups, _current_group_id);
  }

   
  function read_total_groups()
           view
           external
           returns (uint256 _total_groups)
  {
    _total_groups = read_total_uints(system.groups);
  }

   
  function read_first_user_in_group(bytes32 _group_id)
           view
           external
           returns (address _user)
  {
    _user = read_first_from_indexed_addresses(system.groups_collection, bytes32(_group_id));
  }

   
  function read_last_user_in_group(bytes32 _group_id)
           view
           external
           returns (address _user)
  {
    _user = read_last_from_indexed_addresses(system.groups_collection, bytes32(_group_id));
  }

   
  function read_next_user_in_group(bytes32 _group_id, address _current_user)
           view
           external
           returns (address _user)
  {
    _user = read_next_from_indexed_addresses(system.groups_collection, bytes32(_group_id), _current_user);
  }

   
  function read_previous_user_in_group(bytes32 _group_id, address _current_user)
           view
           external
           returns (address _user)
  {
    _user = read_previous_from_indexed_addresses(system.groups_collection, bytes32(_group_id), _current_user);
  }

   
  function read_total_users_in_group(bytes32 _group_id)
           view
           external
           returns (uint256 _total_users)
  {
    _total_users = read_total_indexed_addresses(system.groups_collection, bytes32(_group_id));
  }
}

contract DaoIdentityStorage is ResolverClient, DaoConstants, DirectoryStorage {

     
     
     
     
     
    struct KycDetails {
        bytes32 doc;
        uint256 id_expiration;
    }

     
    mapping (address => KycDetails) kycInfo;

    constructor(address _resolver)
        public
    {
        require(init(CONTRACT_STORAGE_DAO_IDENTITY, _resolver));
        require(initialize_directory());
    }

    function create_group(uint256 _role_id, bytes32 _name, bytes32 _document)
        public
        returns (bool _success, uint256 _group_id)
    {
        require(sender_is(CONTRACT_DAO_IDENTITY));
        (_success, _group_id) = internal_create_group(_role_id, _name, _document);
        require(_success);
    }

    function create_role(uint256 _role_id, bytes32 _name)
        public
        returns (bool _success)
    {
        require(sender_is(CONTRACT_DAO_IDENTITY));
        _success = internal_create_role(_role_id, _name);
        require(_success);
    }

    function update_add_user_to_group(uint256 _group_id, address _user, bytes32 _document)
        public
        returns (bool _success)
    {
        require(sender_is(CONTRACT_DAO_IDENTITY));
        _success = internal_update_add_user_to_group(_group_id, _user, _document);
        require(_success);
    }

    function update_remove_group_user(address _user)
        public
        returns (bool _success)
    {
        require(sender_is(CONTRACT_DAO_IDENTITY));
        _success = internal_destroy_group_user(_user);
        require(_success);
    }

    function update_kyc(address _user, bytes32 _doc, uint256 _id_expiration)
        public
    {
        require(sender_is(CONTRACT_DAO_IDENTITY));
        kycInfo[_user].doc = _doc;
        kycInfo[_user].id_expiration = _id_expiration;
    }

    function read_kyc_info(address _user)
        public
        view
        returns (bytes32 _doc, uint256 _id_expiration)
    {
        _doc = kycInfo[_user].doc;
        _id_expiration = kycInfo[_user].id_expiration;
    }

    function is_kyc_approved(address _user)
        public
        view
        returns (bool _approved)
    {
        uint256 _id_expiration;
        (,_id_expiration) = read_kyc_info(_user);
        _approved = _id_expiration > now;
    }
}

contract IdentityCommon is DaoWhitelistingCommon {

    modifier if_root() {
        require(identity_storage().read_user_role_id(msg.sender) == ROLES_ROOT);
        _;
    }

    modifier if_founder() {
        require(is_founder());
        _;
    }

    function is_founder()
        internal
        view
        returns (bool _isFounder)
    {
        _isFounder = identity_storage().read_user_role_id(msg.sender) == ROLES_FOUNDERS;
    }

    modifier if_prl() {
        require(identity_storage().read_user_role_id(msg.sender) == ROLES_PRLS);
        _;
    }

    modifier if_kyc_admin() {
        require(identity_storage().read_user_role_id(msg.sender) == ROLES_KYC_ADMINS);
        _;
    }

    function identity_storage()
        internal
        view
        returns (DaoIdentityStorage _contract)
    {
        _contract = DaoIdentityStorage(get_contract(CONTRACT_STORAGE_DAO_IDENTITY));
    }
}

contract DaoConfigsStorage is ResolverClient, DaoConstants {

     
     
    mapping (bytes32 => uint256) public uintConfigs;

     
     
    mapping (bytes32 => address) public addressConfigs;

     
     
    mapping (bytes32 => bytes32) public bytesConfigs;

    uint256 ONE_BILLION = 1000000000;
    uint256 ONE_MILLION = 1000000;

    constructor(address _resolver)
        public
    {
        require(init(CONTRACT_STORAGE_DAO_CONFIG, _resolver));

        uintConfigs[CONFIG_LOCKING_PHASE_DURATION] = 10 days;
        uintConfigs[CONFIG_QUARTER_DURATION] = QUARTER_DURATION;
        uintConfigs[CONFIG_VOTING_COMMIT_PHASE] = 14 days;
        uintConfigs[CONFIG_VOTING_PHASE_TOTAL] = 21 days;
        uintConfigs[CONFIG_INTERIM_COMMIT_PHASE] = 7 days;
        uintConfigs[CONFIG_INTERIM_PHASE_TOTAL] = 14 days;



        uintConfigs[CONFIG_DRAFT_QUORUM_FIXED_PORTION_NUMERATOR] = 5;  
        uintConfigs[CONFIG_DRAFT_QUORUM_FIXED_PORTION_DENOMINATOR] = 100;  
        uintConfigs[CONFIG_DRAFT_QUORUM_SCALING_FACTOR_NUMERATOR] = 35;  
        uintConfigs[CONFIG_DRAFT_QUORUM_SCALING_FACTOR_DENOMINATOR] = 100;  


        uintConfigs[CONFIG_VOTING_QUORUM_FIXED_PORTION_NUMERATOR] = 5;  
        uintConfigs[CONFIG_VOTING_QUORUM_FIXED_PORTION_DENOMINATOR] = 100;  
        uintConfigs[CONFIG_VOTING_QUORUM_SCALING_FACTOR_NUMERATOR] = 25;  
        uintConfigs[CONFIG_VOTING_QUORUM_SCALING_FACTOR_DENOMINATOR] = 100;  

        uintConfigs[CONFIG_DRAFT_QUOTA_NUMERATOR] = 1;  
        uintConfigs[CONFIG_DRAFT_QUOTA_DENOMINATOR] = 2;  
        uintConfigs[CONFIG_VOTING_QUOTA_NUMERATOR] = 1;  
        uintConfigs[CONFIG_VOTING_QUOTA_DENOMINATOR] = 2;  


        uintConfigs[CONFIG_QUARTER_POINT_DRAFT_VOTE] = ONE_BILLION;
        uintConfigs[CONFIG_QUARTER_POINT_VOTE] = ONE_BILLION;
        uintConfigs[CONFIG_QUARTER_POINT_INTERIM_VOTE] = ONE_BILLION;

        uintConfigs[CONFIG_QUARTER_POINT_MILESTONE_COMPLETION_PER_10000ETH] = 20000 * ONE_BILLION;

        uintConfigs[CONFIG_BONUS_REPUTATION_NUMERATOR] = 15;  
        uintConfigs[CONFIG_BONUS_REPUTATION_DENOMINATOR] = 100;  

        uintConfigs[CONFIG_SPECIAL_PROPOSAL_COMMIT_PHASE] = 28 days;
        uintConfigs[CONFIG_SPECIAL_PROPOSAL_PHASE_TOTAL] = 35 days;



        uintConfigs[CONFIG_SPECIAL_QUOTA_NUMERATOR] = 1;  
        uintConfigs[CONFIG_SPECIAL_QUOTA_DENOMINATOR] = 2;  

        uintConfigs[CONFIG_SPECIAL_PROPOSAL_QUORUM_NUMERATOR] = 40;  
        uintConfigs[CONFIG_SPECIAL_PROPOSAL_QUORUM_DENOMINATOR] = 100;  

        uintConfigs[CONFIG_MAXIMUM_REPUTATION_DEDUCTION] = 8334 * ONE_MILLION;

        uintConfigs[CONFIG_PUNISHMENT_FOR_NOT_LOCKING] = 1666 * ONE_MILLION;
        uintConfigs[CONFIG_REPUTATION_PER_EXTRA_QP_NUM] = 1;  
        uintConfigs[CONFIG_REPUTATION_PER_EXTRA_QP_DEN] = 1;


        uintConfigs[CONFIG_MINIMAL_QUARTER_POINT] = 2 * ONE_BILLION;
        uintConfigs[CONFIG_QUARTER_POINT_SCALING_FACTOR] = 400 * ONE_BILLION;
        uintConfigs[CONFIG_REPUTATION_POINT_SCALING_FACTOR] = 2000 * ONE_BILLION;

        uintConfigs[CONFIG_MODERATOR_MINIMAL_QUARTER_POINT] = 4 * ONE_BILLION;
        uintConfigs[CONFIG_MODERATOR_QUARTER_POINT_SCALING_FACTOR] = 400 * ONE_BILLION;
        uintConfigs[CONFIG_MODERATOR_REPUTATION_POINT_SCALING_FACTOR] = 2000 * ONE_BILLION;

        uintConfigs[CONFIG_PORTION_TO_MODERATORS_NUM] = 42;  
        uintConfigs[CONFIG_PORTION_TO_MODERATORS_DEN] = 1000;

        uintConfigs[CONFIG_DRAFT_VOTING_PHASE] = 7 days;

        uintConfigs[CONFIG_REPUTATION_POINT_BOOST_FOR_BADGE] = 412500 * ONE_MILLION;

        uintConfigs[CONFIG_FINAL_REWARD_SCALING_FACTOR_NUMERATOR] = 7;  
        uintConfigs[CONFIG_FINAL_REWARD_SCALING_FACTOR_DENOMINATOR] = 100;  

        uintConfigs[CONFIG_MAXIMUM_MODERATOR_REPUTATION_DEDUCTION] = 12500 * ONE_MILLION;
        uintConfigs[CONFIG_REPUTATION_PER_EXTRA_MODERATOR_QP_NUM] = 1;
        uintConfigs[CONFIG_REPUTATION_PER_EXTRA_MODERATOR_QP_DEN] = 1;

        uintConfigs[CONFIG_VOTE_CLAIMING_DEADLINE] = 10 days;

        uintConfigs[CONFIG_MINIMUM_LOCKED_DGD] = 10 * ONE_BILLION;
        uintConfigs[CONFIG_MINIMUM_DGD_FOR_MODERATOR] = 842 * ONE_BILLION;
        uintConfigs[CONFIG_MINIMUM_REPUTATION_FOR_MODERATOR] = 400 * ONE_BILLION;

        uintConfigs[CONFIG_PREPROPOSAL_COLLATERAL] = 2 ether;

        uintConfigs[CONFIG_MAX_FUNDING_FOR_NON_DIGIX] = 100 ether;
        uintConfigs[CONFIG_MAX_MILESTONES_FOR_NON_DIGIX] = 5;
        uintConfigs[CONFIG_NON_DIGIX_PROPOSAL_CAP_PER_QUARTER] = 80;

        uintConfigs[CONFIG_PROPOSAL_DEAD_DURATION] = 90 days;
        uintConfigs[CONFIG_CARBON_VOTE_REPUTATION_BONUS] = 10 * ONE_BILLION;
    }

    function updateUintConfigs(uint256[] _uintConfigs)
        external
    {
        require(sender_is(CONTRACT_DAO_SPECIAL_VOTING_CLAIMS));
        uintConfigs[CONFIG_LOCKING_PHASE_DURATION] = _uintConfigs[0];
         
        uintConfigs[CONFIG_VOTING_COMMIT_PHASE] = _uintConfigs[2];
        uintConfigs[CONFIG_VOTING_PHASE_TOTAL] = _uintConfigs[3];
        uintConfigs[CONFIG_INTERIM_COMMIT_PHASE] = _uintConfigs[4];
        uintConfigs[CONFIG_INTERIM_PHASE_TOTAL] = _uintConfigs[5];
        uintConfigs[CONFIG_DRAFT_QUORUM_FIXED_PORTION_NUMERATOR] = _uintConfigs[6];
        uintConfigs[CONFIG_DRAFT_QUORUM_FIXED_PORTION_DENOMINATOR] = _uintConfigs[7];
        uintConfigs[CONFIG_DRAFT_QUORUM_SCALING_FACTOR_NUMERATOR] = _uintConfigs[8];
        uintConfigs[CONFIG_DRAFT_QUORUM_SCALING_FACTOR_DENOMINATOR] = _uintConfigs[9];
        uintConfigs[CONFIG_VOTING_QUORUM_FIXED_PORTION_NUMERATOR] = _uintConfigs[10];
        uintConfigs[CONFIG_VOTING_QUORUM_FIXED_PORTION_DENOMINATOR] = _uintConfigs[11];
        uintConfigs[CONFIG_VOTING_QUORUM_SCALING_FACTOR_NUMERATOR] = _uintConfigs[12];
        uintConfigs[CONFIG_VOTING_QUORUM_SCALING_FACTOR_DENOMINATOR] = _uintConfigs[13];
        uintConfigs[CONFIG_DRAFT_QUOTA_NUMERATOR] = _uintConfigs[14];
        uintConfigs[CONFIG_DRAFT_QUOTA_DENOMINATOR] = _uintConfigs[15];
        uintConfigs[CONFIG_VOTING_QUOTA_NUMERATOR] = _uintConfigs[16];
        uintConfigs[CONFIG_VOTING_QUOTA_DENOMINATOR] = _uintConfigs[17];
        uintConfigs[CONFIG_QUARTER_POINT_DRAFT_VOTE] = _uintConfigs[18];
        uintConfigs[CONFIG_QUARTER_POINT_VOTE] = _uintConfigs[19];
        uintConfigs[CONFIG_QUARTER_POINT_INTERIM_VOTE] = _uintConfigs[20];
        uintConfigs[CONFIG_MINIMAL_QUARTER_POINT] = _uintConfigs[21];
        uintConfigs[CONFIG_QUARTER_POINT_MILESTONE_COMPLETION_PER_10000ETH] = _uintConfigs[22];
        uintConfigs[CONFIG_BONUS_REPUTATION_NUMERATOR] = _uintConfigs[23];
        uintConfigs[CONFIG_BONUS_REPUTATION_DENOMINATOR] = _uintConfigs[24];
        uintConfigs[CONFIG_SPECIAL_PROPOSAL_COMMIT_PHASE] = _uintConfigs[25];
        uintConfigs[CONFIG_SPECIAL_PROPOSAL_PHASE_TOTAL] = _uintConfigs[26];
        uintConfigs[CONFIG_SPECIAL_QUOTA_NUMERATOR] = _uintConfigs[27];
        uintConfigs[CONFIG_SPECIAL_QUOTA_DENOMINATOR] = _uintConfigs[28];
        uintConfigs[CONFIG_SPECIAL_PROPOSAL_QUORUM_NUMERATOR] = _uintConfigs[29];
        uintConfigs[CONFIG_SPECIAL_PROPOSAL_QUORUM_DENOMINATOR] = _uintConfigs[30];
        uintConfigs[CONFIG_MAXIMUM_REPUTATION_DEDUCTION] = _uintConfigs[31];
        uintConfigs[CONFIG_PUNISHMENT_FOR_NOT_LOCKING] = _uintConfigs[32];
        uintConfigs[CONFIG_REPUTATION_PER_EXTRA_QP_NUM] = _uintConfigs[33];
        uintConfigs[CONFIG_REPUTATION_PER_EXTRA_QP_DEN] = _uintConfigs[34];
        uintConfigs[CONFIG_QUARTER_POINT_SCALING_FACTOR] = _uintConfigs[35];
        uintConfigs[CONFIG_REPUTATION_POINT_SCALING_FACTOR] = _uintConfigs[36];
        uintConfigs[CONFIG_MODERATOR_MINIMAL_QUARTER_POINT] = _uintConfigs[37];
        uintConfigs[CONFIG_MODERATOR_QUARTER_POINT_SCALING_FACTOR] = _uintConfigs[38];
        uintConfigs[CONFIG_MODERATOR_REPUTATION_POINT_SCALING_FACTOR] = _uintConfigs[39];
        uintConfigs[CONFIG_PORTION_TO_MODERATORS_NUM] = _uintConfigs[40];
        uintConfigs[CONFIG_PORTION_TO_MODERATORS_DEN] = _uintConfigs[41];
        uintConfigs[CONFIG_DRAFT_VOTING_PHASE] = _uintConfigs[42];
        uintConfigs[CONFIG_REPUTATION_POINT_BOOST_FOR_BADGE] = _uintConfigs[43];
        uintConfigs[CONFIG_FINAL_REWARD_SCALING_FACTOR_NUMERATOR] = _uintConfigs[44];
        uintConfigs[CONFIG_FINAL_REWARD_SCALING_FACTOR_DENOMINATOR] = _uintConfigs[45];
        uintConfigs[CONFIG_MAXIMUM_MODERATOR_REPUTATION_DEDUCTION] = _uintConfigs[46];
        uintConfigs[CONFIG_REPUTATION_PER_EXTRA_MODERATOR_QP_NUM] = _uintConfigs[47];
        uintConfigs[CONFIG_REPUTATION_PER_EXTRA_MODERATOR_QP_DEN] = _uintConfigs[48];
        uintConfigs[CONFIG_VOTE_CLAIMING_DEADLINE] = _uintConfigs[49];
        uintConfigs[CONFIG_MINIMUM_LOCKED_DGD] = _uintConfigs[50];
        uintConfigs[CONFIG_MINIMUM_DGD_FOR_MODERATOR] = _uintConfigs[51];
        uintConfigs[CONFIG_MINIMUM_REPUTATION_FOR_MODERATOR] = _uintConfigs[52];
        uintConfigs[CONFIG_PREPROPOSAL_COLLATERAL] = _uintConfigs[53];
        uintConfigs[CONFIG_MAX_FUNDING_FOR_NON_DIGIX] = _uintConfigs[54];
        uintConfigs[CONFIG_MAX_MILESTONES_FOR_NON_DIGIX] = _uintConfigs[55];
        uintConfigs[CONFIG_NON_DIGIX_PROPOSAL_CAP_PER_QUARTER] = _uintConfigs[56];
        uintConfigs[CONFIG_PROPOSAL_DEAD_DURATION] = _uintConfigs[57];
        uintConfigs[CONFIG_CARBON_VOTE_REPUTATION_BONUS] = _uintConfigs[58];
    }

    function readUintConfigs()
        public
        view
        returns (uint256[])
    {
        uint256[] memory _uintConfigs = new uint256[](59);
        _uintConfigs[0] = uintConfigs[CONFIG_LOCKING_PHASE_DURATION];
        _uintConfigs[1] = uintConfigs[CONFIG_QUARTER_DURATION];
        _uintConfigs[2] = uintConfigs[CONFIG_VOTING_COMMIT_PHASE];
        _uintConfigs[3] = uintConfigs[CONFIG_VOTING_PHASE_TOTAL];
        _uintConfigs[4] = uintConfigs[CONFIG_INTERIM_COMMIT_PHASE];
        _uintConfigs[5] = uintConfigs[CONFIG_INTERIM_PHASE_TOTAL];
        _uintConfigs[6] = uintConfigs[CONFIG_DRAFT_QUORUM_FIXED_PORTION_NUMERATOR];
        _uintConfigs[7] = uintConfigs[CONFIG_DRAFT_QUORUM_FIXED_PORTION_DENOMINATOR];
        _uintConfigs[8] = uintConfigs[CONFIG_DRAFT_QUORUM_SCALING_FACTOR_NUMERATOR];
        _uintConfigs[9] = uintConfigs[CONFIG_DRAFT_QUORUM_SCALING_FACTOR_DENOMINATOR];
        _uintConfigs[10] = uintConfigs[CONFIG_VOTING_QUORUM_FIXED_PORTION_NUMERATOR];
        _uintConfigs[11] = uintConfigs[CONFIG_VOTING_QUORUM_FIXED_PORTION_DENOMINATOR];
        _uintConfigs[12] = uintConfigs[CONFIG_VOTING_QUORUM_SCALING_FACTOR_NUMERATOR];
        _uintConfigs[13] = uintConfigs[CONFIG_VOTING_QUORUM_SCALING_FACTOR_DENOMINATOR];
        _uintConfigs[14] = uintConfigs[CONFIG_DRAFT_QUOTA_NUMERATOR];
        _uintConfigs[15] = uintConfigs[CONFIG_DRAFT_QUOTA_DENOMINATOR];
        _uintConfigs[16] = uintConfigs[CONFIG_VOTING_QUOTA_NUMERATOR];
        _uintConfigs[17] = uintConfigs[CONFIG_VOTING_QUOTA_DENOMINATOR];
        _uintConfigs[18] = uintConfigs[CONFIG_QUARTER_POINT_DRAFT_VOTE];
        _uintConfigs[19] = uintConfigs[CONFIG_QUARTER_POINT_VOTE];
        _uintConfigs[20] = uintConfigs[CONFIG_QUARTER_POINT_INTERIM_VOTE];
        _uintConfigs[21] = uintConfigs[CONFIG_MINIMAL_QUARTER_POINT];
        _uintConfigs[22] = uintConfigs[CONFIG_QUARTER_POINT_MILESTONE_COMPLETION_PER_10000ETH];
        _uintConfigs[23] = uintConfigs[CONFIG_BONUS_REPUTATION_NUMERATOR];
        _uintConfigs[24] = uintConfigs[CONFIG_BONUS_REPUTATION_DENOMINATOR];
        _uintConfigs[25] = uintConfigs[CONFIG_SPECIAL_PROPOSAL_COMMIT_PHASE];
        _uintConfigs[26] = uintConfigs[CONFIG_SPECIAL_PROPOSAL_PHASE_TOTAL];
        _uintConfigs[27] = uintConfigs[CONFIG_SPECIAL_QUOTA_NUMERATOR];
        _uintConfigs[28] = uintConfigs[CONFIG_SPECIAL_QUOTA_DENOMINATOR];
        _uintConfigs[29] = uintConfigs[CONFIG_SPECIAL_PROPOSAL_QUORUM_NUMERATOR];
        _uintConfigs[30] = uintConfigs[CONFIG_SPECIAL_PROPOSAL_QUORUM_DENOMINATOR];
        _uintConfigs[31] = uintConfigs[CONFIG_MAXIMUM_REPUTATION_DEDUCTION];
        _uintConfigs[32] = uintConfigs[CONFIG_PUNISHMENT_FOR_NOT_LOCKING];
        _uintConfigs[33] = uintConfigs[CONFIG_REPUTATION_PER_EXTRA_QP_NUM];
        _uintConfigs[34] = uintConfigs[CONFIG_REPUTATION_PER_EXTRA_QP_DEN];
        _uintConfigs[35] = uintConfigs[CONFIG_QUARTER_POINT_SCALING_FACTOR];
        _uintConfigs[36] = uintConfigs[CONFIG_REPUTATION_POINT_SCALING_FACTOR];
        _uintConfigs[37] = uintConfigs[CONFIG_MODERATOR_MINIMAL_QUARTER_POINT];
        _uintConfigs[38] = uintConfigs[CONFIG_MODERATOR_QUARTER_POINT_SCALING_FACTOR];
        _uintConfigs[39] = uintConfigs[CONFIG_MODERATOR_REPUTATION_POINT_SCALING_FACTOR];
        _uintConfigs[40] = uintConfigs[CONFIG_PORTION_TO_MODERATORS_NUM];
        _uintConfigs[41] = uintConfigs[CONFIG_PORTION_TO_MODERATORS_DEN];
        _uintConfigs[42] = uintConfigs[CONFIG_DRAFT_VOTING_PHASE];
        _uintConfigs[43] = uintConfigs[CONFIG_REPUTATION_POINT_BOOST_FOR_BADGE];
        _uintConfigs[44] = uintConfigs[CONFIG_FINAL_REWARD_SCALING_FACTOR_NUMERATOR];
        _uintConfigs[45] = uintConfigs[CONFIG_FINAL_REWARD_SCALING_FACTOR_DENOMINATOR];
        _uintConfigs[46] = uintConfigs[CONFIG_MAXIMUM_MODERATOR_REPUTATION_DEDUCTION];
        _uintConfigs[47] = uintConfigs[CONFIG_REPUTATION_PER_EXTRA_MODERATOR_QP_NUM];
        _uintConfigs[48] = uintConfigs[CONFIG_REPUTATION_PER_EXTRA_MODERATOR_QP_DEN];
        _uintConfigs[49] = uintConfigs[CONFIG_VOTE_CLAIMING_DEADLINE];
        _uintConfigs[50] = uintConfigs[CONFIG_MINIMUM_LOCKED_DGD];
        _uintConfigs[51] = uintConfigs[CONFIG_MINIMUM_DGD_FOR_MODERATOR];
        _uintConfigs[52] = uintConfigs[CONFIG_MINIMUM_REPUTATION_FOR_MODERATOR];
        _uintConfigs[53] = uintConfigs[CONFIG_PREPROPOSAL_COLLATERAL];
        _uintConfigs[54] = uintConfigs[CONFIG_MAX_FUNDING_FOR_NON_DIGIX];
        _uintConfigs[55] = uintConfigs[CONFIG_MAX_MILESTONES_FOR_NON_DIGIX];
        _uintConfigs[56] = uintConfigs[CONFIG_NON_DIGIX_PROPOSAL_CAP_PER_QUARTER];
        _uintConfigs[57] = uintConfigs[CONFIG_PROPOSAL_DEAD_DURATION];
        _uintConfigs[58] = uintConfigs[CONFIG_CARBON_VOTE_REPUTATION_BONUS];
        return _uintConfigs;
    }
}

contract DaoProposalCounterStorage is ResolverClient, DaoConstants {

    constructor(address _resolver) public {
        require(init(CONTRACT_STORAGE_DAO_COUNTER, _resolver));
    }

     
     
    mapping (uint256 => uint256) public proposalCountByQuarter;

    function addNonDigixProposalCountInQuarter(uint256 _quarterNumber)
        public
    {
        require(sender_is(CONTRACT_DAO_VOTING_CLAIMS));
        proposalCountByQuarter[_quarterNumber] = proposalCountByQuarter[_quarterNumber].add(1);
    }
}

contract DaoUpgradeStorage is ResolverClient, DaoConstants {

     
     
     
    uint256 public startOfFirstQuarter;

     
     
     
     
     
     
    bool public isReplacedByNewDao;

     
    address public newDaoContract;

     
     
     
    address public newDaoFundingManager;

     
     
     
    address public newDaoRewardsManager;

    constructor(address _resolver) public {
        require(init(CONTRACT_STORAGE_DAO_UPGRADE, _resolver));
    }

    function setStartOfFirstQuarter(uint256 _start)
        public
    {
        require(sender_is(CONTRACT_DAO));
        startOfFirstQuarter = _start;
    }


    function setNewContractAddresses(
        address _newDaoContract,
        address _newDaoFundingManager,
        address _newDaoRewardsManager
    )
        public
    {
        require(sender_is(CONTRACT_DAO));
        newDaoContract = _newDaoContract;
        newDaoFundingManager = _newDaoFundingManager;
        newDaoRewardsManager = _newDaoRewardsManager;
    }


    function updateForDaoMigration()
        public
    {
        require(sender_is(CONTRACT_DAO));
        isReplacedByNewDao = true;
    }
}

contract DaoSpecialStorage is DaoWhitelistingCommon {
    using DoublyLinkedList for DoublyLinkedList.Bytes;
    using DaoStructs for DaoStructs.SpecialProposal;
    using DaoStructs for DaoStructs.Voting;

     
    DoublyLinkedList.Bytes proposals;

     
     
    mapping (bytes32 => DaoStructs.SpecialProposal) proposalsById;

    constructor(address _resolver) public {
        require(init(CONTRACT_STORAGE_DAO_SPECIAL, _resolver));
    }

    function addSpecialProposal(
        bytes32 _proposalId,
        address _proposer,
        uint256[] _uintConfigs,
        address[] _addressConfigs,
        bytes32[] _bytesConfigs
    )
        public
    {
        require(sender_is(CONTRACT_DAO_SPECIAL_PROPOSAL));
        require(
          (proposalsById[_proposalId].proposalId == EMPTY_BYTES) &&
          (_proposalId != EMPTY_BYTES)
        );
        proposals.append(_proposalId);
        proposalsById[_proposalId].proposalId = _proposalId;
        proposalsById[_proposalId].proposer = _proposer;
        proposalsById[_proposalId].timeCreated = now;
        proposalsById[_proposalId].uintConfigs = _uintConfigs;
        proposalsById[_proposalId].addressConfigs = _addressConfigs;
        proposalsById[_proposalId].bytesConfigs = _bytesConfigs;
    }

    function readProposal(bytes32 _proposalId)
        public
        view
        returns (
            bytes32 _id,
            address _proposer,
            uint256 _timeCreated,
            uint256 _timeVotingStarted
        )
    {
        _id = proposalsById[_proposalId].proposalId;
        _proposer = proposalsById[_proposalId].proposer;
        _timeCreated = proposalsById[_proposalId].timeCreated;
        _timeVotingStarted = proposalsById[_proposalId].voting.startTime;
    }

    function readProposalProposer(bytes32 _proposalId)
        public
        view
        returns (address _proposer)
    {
        _proposer = proposalsById[_proposalId].proposer;
    }

    function readConfigs(bytes32 _proposalId)
        public
        view
        returns (
            uint256[] memory _uintConfigs,
            address[] memory _addressConfigs,
            bytes32[] memory _bytesConfigs
        )
    {
        _uintConfigs = proposalsById[_proposalId].uintConfigs;
        _addressConfigs = proposalsById[_proposalId].addressConfigs;
        _bytesConfigs = proposalsById[_proposalId].bytesConfigs;
    }

    function readVotingCount(bytes32 _proposalId, address[] _allUsers)
        external
        view
        returns (uint256 _for, uint256 _against)
    {
        require(senderIsAllowedToRead());
        return proposalsById[_proposalId].voting.countVotes(_allUsers);
    }

    function readVotingTime(bytes32 _proposalId)
        public
        view
        returns (uint256 _start)
    {
        require(senderIsAllowedToRead());
        _start = proposalsById[_proposalId].voting.startTime;
    }

    function commitVote(
        bytes32 _proposalId,
        bytes32 _hash,
        address _voter
    )
        public
    {
        require(sender_is(CONTRACT_DAO_VOTING));
        proposalsById[_proposalId].voting.commits[_voter] = _hash;
    }

    function readComittedVote(bytes32 _proposalId, address _voter)
        public
        view
        returns (bytes32 _commitHash)
    {
        require(senderIsAllowedToRead());
        _commitHash = proposalsById[_proposalId].voting.commits[_voter];
    }

    function setVotingTime(bytes32 _proposalId, uint256 _time)
        public
    {
        require(sender_is(CONTRACT_DAO_SPECIAL_PROPOSAL));
        proposalsById[_proposalId].voting.startTime = _time;
    }

    function readVotingResult(bytes32 _proposalId)
        public
        view
        returns (bool _result)
    {
        require(senderIsAllowedToRead());
        _result = proposalsById[_proposalId].voting.passed;
    }

    function setPass(bytes32 _proposalId, bool _result)
        public
    {
        require(sender_is(CONTRACT_DAO_SPECIAL_VOTING_CLAIMS));
        proposalsById[_proposalId].voting.passed = _result;
    }

    function setVotingClaim(bytes32 _proposalId, bool _claimed)
        public
    {
        require(sender_is(CONTRACT_DAO_SPECIAL_VOTING_CLAIMS));
        DaoStructs.SpecialProposal storage _proposal = proposalsById[_proposalId];
        _proposal.voting.claimed = _claimed;
    }

    function isClaimed(bytes32 _proposalId)
        public
        view
        returns (bool _claimed)
    {
        require(senderIsAllowedToRead());
        _claimed = proposalsById[_proposalId].voting.claimed;
    }

    function readVote(bytes32 _proposalId, address _voter)
        public
        view
        returns (bool _vote, uint256 _weight)
    {
        require(senderIsAllowedToRead());
        return proposalsById[_proposalId].voting.readVote(_voter);
    }

    function revealVote(
        bytes32 _proposalId,
        address _voter,
        bool _vote,
        uint256 _weight
    )
        public
    {
        require(sender_is(CONTRACT_DAO_VOTING));
        proposalsById[_proposalId].voting.revealVote(_voter, _vote, _weight);
    }
}

contract DaoPointsStorage is ResolverClient, DaoConstants {

     
    struct Token {
        uint256 totalSupply;
        mapping (address => uint256) balance;
    }

     
     
    Token reputationPoint;

     
     
    mapping (uint256 => Token) quarterPoint;

     
     
    mapping (uint256 => Token) quarterModeratorPoint;

    constructor(address _resolver)
        public
    {
        require(init(CONTRACT_STORAGE_DAO_POINTS, _resolver));
    }

     
    function addQuarterPoint(address _participant, uint256 _point, uint256 _quarterNumber)
        public
        returns (uint256 _newPoint, uint256 _newTotalPoint)
    {
        require(sender_is_from([CONTRACT_DAO_VOTING, CONTRACT_DAO_VOTING_CLAIMS, EMPTY_BYTES]));
        quarterPoint[_quarterNumber].totalSupply = quarterPoint[_quarterNumber].totalSupply.add(_point);
        quarterPoint[_quarterNumber].balance[_participant] = quarterPoint[_quarterNumber].balance[_participant].add(_point);

        _newPoint = quarterPoint[_quarterNumber].balance[_participant];
        _newTotalPoint = quarterPoint[_quarterNumber].totalSupply;
    }

    function addModeratorQuarterPoint(address _participant, uint256 _point, uint256 _quarterNumber)
        public
        returns (uint256 _newPoint, uint256 _newTotalPoint)
    {
        require(sender_is_from([CONTRACT_DAO_VOTING, CONTRACT_DAO_VOTING_CLAIMS, EMPTY_BYTES]));
        quarterModeratorPoint[_quarterNumber].totalSupply = quarterModeratorPoint[_quarterNumber].totalSupply.add(_point);
        quarterModeratorPoint[_quarterNumber].balance[_participant] = quarterModeratorPoint[_quarterNumber].balance[_participant].add(_point);

        _newPoint = quarterModeratorPoint[_quarterNumber].balance[_participant];
        _newTotalPoint = quarterModeratorPoint[_quarterNumber].totalSupply;
    }

     
    function getQuarterPoint(address _participant, uint256 _quarterNumber)
        public
        view
        returns (uint256 _point)
    {
        _point = quarterPoint[_quarterNumber].balance[_participant];
    }

    function getQuarterModeratorPoint(address _participant, uint256 _quarterNumber)
        public
        view
        returns (uint256 _point)
    {
        _point = quarterModeratorPoint[_quarterNumber].balance[_participant];
    }

     
    function getTotalQuarterPoint(uint256 _quarterNumber)
        public
        view
        returns (uint256 _totalPoint)
    {
        _totalPoint = quarterPoint[_quarterNumber].totalSupply;
    }

    function getTotalQuarterModeratorPoint(uint256 _quarterNumber)
        public
        view
        returns (uint256 _totalPoint)
    {
        _totalPoint = quarterModeratorPoint[_quarterNumber].totalSupply;
    }

     
    function increaseReputation(address _participant, uint256 _point)
        public
        returns (uint256 _newPoint, uint256 _totalPoint)
    {
        require(sender_is_from([CONTRACT_DAO_VOTING_CLAIMS, CONTRACT_DAO_REWARDS_MANAGER, CONTRACT_DAO_STAKE_LOCKING]));
        reputationPoint.totalSupply = reputationPoint.totalSupply.add(_point);
        reputationPoint.balance[_participant] = reputationPoint.balance[_participant].add(_point);

        _newPoint = reputationPoint.balance[_participant];
        _totalPoint = reputationPoint.totalSupply;
    }

     
    function reduceReputation(address _participant, uint256 _point)
        public
        returns (uint256 _newPoint, uint256 _totalPoint)
    {
        require(sender_is_from([CONTRACT_DAO_VOTING_CLAIMS, CONTRACT_DAO_REWARDS_MANAGER, EMPTY_BYTES]));
        uint256 _toDeduct = _point;
        if (reputationPoint.balance[_participant] > _point) {
            reputationPoint.balance[_participant] = reputationPoint.balance[_participant].sub(_point);
        } else {
            _toDeduct = reputationPoint.balance[_participant];
            reputationPoint.balance[_participant] = 0;
        }

        reputationPoint.totalSupply = reputationPoint.totalSupply.sub(_toDeduct);

        _newPoint = reputationPoint.balance[_participant];
        _totalPoint = reputationPoint.totalSupply;
    }

   
  function getReputation(address _participant)
      public
      view
      returns (uint256 _point)
  {
      _point = reputationPoint.balance[_participant];
  }

   
  function getTotalReputation()
      public
      view
      returns (uint256 _totalPoint)
  {
      _totalPoint = reputationPoint.totalSupply;
  }
}

 
contract DaoRewardsStorage is ResolverClient, DaoConstants {
    using DaoStructs for DaoStructs.DaoQuarterInfo;

     
     
     
    mapping(uint256 => DaoStructs.DaoQuarterInfo) public allQuartersInfo;

     
     
    mapping(address => uint256) public claimableDGXs;

     
     
     
     
     
    uint256 public totalDGXsClaimed;

     
     
     
     
     
    mapping (address => uint256) public lastParticipatedQuarter;

     
     
     
    mapping (address => uint256) public previousLastParticipatedQuarter;

     
     
     
     
    mapping (address => uint256) public lastQuarterThatRewardsWasUpdated;

     
     
     
     
    mapping (address => uint256) public lastQuarterThatReputationWasUpdated;

    constructor(address _resolver)
           public
    {
        require(init(CONTRACT_STORAGE_DAO_REWARDS, _resolver));
    }

    function updateQuarterInfo(
        uint256 _quarterNumber,
        uint256 _minimalParticipationPoint,
        uint256 _quarterPointScalingFactor,
        uint256 _reputationPointScalingFactor,
        uint256 _totalEffectiveDGDPreviousQuarter,

        uint256 _moderatorMinimalQuarterPoint,
        uint256 _moderatorQuarterPointScalingFactor,
        uint256 _moderatorReputationPointScalingFactor,
        uint256 _totalEffectiveModeratorDGDLastQuarter,

        uint256 _dgxDistributionDay,
        uint256 _dgxRewardsPoolLastQuarter,
        uint256 _sumRewardsFromBeginning
    )
        public
    {
        require(sender_is(CONTRACT_DAO_REWARDS_MANAGER));
        allQuartersInfo[_quarterNumber].minimalParticipationPoint = _minimalParticipationPoint;
        allQuartersInfo[_quarterNumber].quarterPointScalingFactor = _quarterPointScalingFactor;
        allQuartersInfo[_quarterNumber].reputationPointScalingFactor = _reputationPointScalingFactor;
        allQuartersInfo[_quarterNumber].totalEffectiveDGDPreviousQuarter = _totalEffectiveDGDPreviousQuarter;

        allQuartersInfo[_quarterNumber].moderatorMinimalParticipationPoint = _moderatorMinimalQuarterPoint;
        allQuartersInfo[_quarterNumber].moderatorQuarterPointScalingFactor = _moderatorQuarterPointScalingFactor;
        allQuartersInfo[_quarterNumber].moderatorReputationPointScalingFactor = _moderatorReputationPointScalingFactor;
        allQuartersInfo[_quarterNumber].totalEffectiveModeratorDGDLastQuarter = _totalEffectiveModeratorDGDLastQuarter;

        allQuartersInfo[_quarterNumber].dgxDistributionDay = _dgxDistributionDay;
        allQuartersInfo[_quarterNumber].dgxRewardsPoolLastQuarter = _dgxRewardsPoolLastQuarter;
        allQuartersInfo[_quarterNumber].sumRewardsFromBeginning = _sumRewardsFromBeginning;
    }

    function updateClaimableDGX(address _user, uint256 _newClaimableDGX)
        public
    {
        require(sender_is(CONTRACT_DAO_REWARDS_MANAGER));
        claimableDGXs[_user] = _newClaimableDGX;
    }

    function updateLastParticipatedQuarter(address _user, uint256 _lastQuarter)
        public
    {
        require(sender_is(CONTRACT_DAO_STAKE_LOCKING));
        lastParticipatedQuarter[_user] = _lastQuarter;
    }

    function updatePreviousLastParticipatedQuarter(address _user, uint256 _lastQuarter)
        public
    {
        require(sender_is(CONTRACT_DAO_STAKE_LOCKING));
        previousLastParticipatedQuarter[_user] = _lastQuarter;
    }

    function updateLastQuarterThatRewardsWasUpdated(address _user, uint256 _lastQuarter)
        public
    {
        require(sender_is_from([CONTRACT_DAO_REWARDS_MANAGER, CONTRACT_DAO_STAKE_LOCKING, EMPTY_BYTES]));
        lastQuarterThatRewardsWasUpdated[_user] = _lastQuarter;
    }

    function updateLastQuarterThatReputationWasUpdated(address _user, uint256 _lastQuarter)
        public
    {
        require(sender_is_from([CONTRACT_DAO_REWARDS_MANAGER, CONTRACT_DAO_STAKE_LOCKING, EMPTY_BYTES]));
        lastQuarterThatReputationWasUpdated[_user] = _lastQuarter;
    }

    function addToTotalDgxClaimed(uint256 _dgxClaimed)
        public
    {
        require(sender_is(CONTRACT_DAO_REWARDS_MANAGER));
        totalDGXsClaimed = totalDGXsClaimed.add(_dgxClaimed);
    }

    function readQuarterInfo(uint256 _quarterNumber)
        public
        view
        returns (
            uint256 _minimalParticipationPoint,
            uint256 _quarterPointScalingFactor,
            uint256 _reputationPointScalingFactor,
            uint256 _totalEffectiveDGDPreviousQuarter,

            uint256 _moderatorMinimalQuarterPoint,
            uint256 _moderatorQuarterPointScalingFactor,
            uint256 _moderatorReputationPointScalingFactor,
            uint256 _totalEffectiveModeratorDGDLastQuarter,

            uint256 _dgxDistributionDay,
            uint256 _dgxRewardsPoolLastQuarter,
            uint256 _sumRewardsFromBeginning
        )
    {
        _minimalParticipationPoint = allQuartersInfo[_quarterNumber].minimalParticipationPoint;
        _quarterPointScalingFactor = allQuartersInfo[_quarterNumber].quarterPointScalingFactor;
        _reputationPointScalingFactor = allQuartersInfo[_quarterNumber].reputationPointScalingFactor;
        _totalEffectiveDGDPreviousQuarter = allQuartersInfo[_quarterNumber].totalEffectiveDGDPreviousQuarter;
        _moderatorMinimalQuarterPoint = allQuartersInfo[_quarterNumber].moderatorMinimalParticipationPoint;
        _moderatorQuarterPointScalingFactor = allQuartersInfo[_quarterNumber].moderatorQuarterPointScalingFactor;
        _moderatorReputationPointScalingFactor = allQuartersInfo[_quarterNumber].moderatorReputationPointScalingFactor;
        _totalEffectiveModeratorDGDLastQuarter = allQuartersInfo[_quarterNumber].totalEffectiveModeratorDGDLastQuarter;
        _dgxDistributionDay = allQuartersInfo[_quarterNumber].dgxDistributionDay;
        _dgxRewardsPoolLastQuarter = allQuartersInfo[_quarterNumber].dgxRewardsPoolLastQuarter;
        _sumRewardsFromBeginning = allQuartersInfo[_quarterNumber].sumRewardsFromBeginning;
    }

    function readQuarterGeneralInfo(uint256 _quarterNumber)
        public
        view
        returns (
            uint256 _dgxDistributionDay,
            uint256 _dgxRewardsPoolLastQuarter,
            uint256 _sumRewardsFromBeginning
        )
    {
        _dgxDistributionDay = allQuartersInfo[_quarterNumber].dgxDistributionDay;
        _dgxRewardsPoolLastQuarter = allQuartersInfo[_quarterNumber].dgxRewardsPoolLastQuarter;
        _sumRewardsFromBeginning = allQuartersInfo[_quarterNumber].sumRewardsFromBeginning;
    }

    function readQuarterModeratorInfo(uint256 _quarterNumber)
        public
        view
        returns (
            uint256 _moderatorMinimalQuarterPoint,
            uint256 _moderatorQuarterPointScalingFactor,
            uint256 _moderatorReputationPointScalingFactor,
            uint256 _totalEffectiveModeratorDGDLastQuarter
        )
    {
        _moderatorMinimalQuarterPoint = allQuartersInfo[_quarterNumber].moderatorMinimalParticipationPoint;
        _moderatorQuarterPointScalingFactor = allQuartersInfo[_quarterNumber].moderatorQuarterPointScalingFactor;
        _moderatorReputationPointScalingFactor = allQuartersInfo[_quarterNumber].moderatorReputationPointScalingFactor;
        _totalEffectiveModeratorDGDLastQuarter = allQuartersInfo[_quarterNumber].totalEffectiveModeratorDGDLastQuarter;
    }

    function readQuarterParticipantInfo(uint256 _quarterNumber)
        public
        view
        returns (
            uint256 _minimalParticipationPoint,
            uint256 _quarterPointScalingFactor,
            uint256 _reputationPointScalingFactor,
            uint256 _totalEffectiveDGDPreviousQuarter
        )
    {
        _minimalParticipationPoint = allQuartersInfo[_quarterNumber].minimalParticipationPoint;
        _quarterPointScalingFactor = allQuartersInfo[_quarterNumber].quarterPointScalingFactor;
        _reputationPointScalingFactor = allQuartersInfo[_quarterNumber].reputationPointScalingFactor;
        _totalEffectiveDGDPreviousQuarter = allQuartersInfo[_quarterNumber].totalEffectiveDGDPreviousQuarter;
    }

    function readDgxDistributionDay(uint256 _quarterNumber)
        public
        view
        returns (uint256 _distributionDay)
    {
        _distributionDay = allQuartersInfo[_quarterNumber].dgxDistributionDay;
    }

    function readTotalEffectiveDGDLastQuarter(uint256 _quarterNumber)
        public
        view
        returns (uint256 _totalEffectiveDGDPreviousQuarter)
    {
        _totalEffectiveDGDPreviousQuarter = allQuartersInfo[_quarterNumber].totalEffectiveDGDPreviousQuarter;
    }

    function readTotalEffectiveModeratorDGDLastQuarter(uint256 _quarterNumber)
        public
        view
        returns (uint256 _totalEffectiveModeratorDGDLastQuarter)
    {
        _totalEffectiveModeratorDGDLastQuarter = allQuartersInfo[_quarterNumber].totalEffectiveModeratorDGDLastQuarter;
    }

    function readRewardsPoolOfLastQuarter(uint256 _quarterNumber)
        public
        view
        returns (uint256 _rewardsPool)
    {
        _rewardsPool = allQuartersInfo[_quarterNumber].dgxRewardsPoolLastQuarter;
    }
}

contract IntermediateResultsStorage is ResolverClient, DaoConstants {
    using DaoStructs for DaoStructs.IntermediateResults;

    constructor(address _resolver) public {
        require(init(CONTRACT_STORAGE_INTERMEDIATE_RESULTS, _resolver));
    }

     
     
     
     
     
     
     
    mapping (bytes32 => DaoStructs.IntermediateResults) allIntermediateResults;

    function getIntermediateResults(bytes32 _key)
        public
        view
        returns (
            address _countedUntil,
            uint256 _currentForCount,
            uint256 _currentAgainstCount,
            uint256 _currentSumOfEffectiveBalance
        )
    {
        _countedUntil = allIntermediateResults[_key].countedUntil;
        _currentForCount = allIntermediateResults[_key].currentForCount;
        _currentAgainstCount = allIntermediateResults[_key].currentAgainstCount;
        _currentSumOfEffectiveBalance = allIntermediateResults[_key].currentSumOfEffectiveBalance;
    }

    function resetIntermediateResults(bytes32 _key)
        public
    {
        require(sender_is_from([CONTRACT_DAO_REWARDS_MANAGER, CONTRACT_DAO_VOTING_CLAIMS, CONTRACT_DAO_SPECIAL_VOTING_CLAIMS]));
        allIntermediateResults[_key].countedUntil = address(0x0);
    }

    function setIntermediateResults(
        bytes32 _key,
        address _countedUntil,
        uint256 _currentForCount,
        uint256 _currentAgainstCount,
        uint256 _currentSumOfEffectiveBalance
    )
        public
    {
        require(sender_is_from([CONTRACT_DAO_REWARDS_MANAGER, CONTRACT_DAO_VOTING_CLAIMS, CONTRACT_DAO_SPECIAL_VOTING_CLAIMS]));
        allIntermediateResults[_key].countedUntil = _countedUntil;
        allIntermediateResults[_key].currentForCount = _currentForCount;
        allIntermediateResults[_key].currentAgainstCount = _currentAgainstCount;
        allIntermediateResults[_key].currentSumOfEffectiveBalance = _currentSumOfEffectiveBalance;
    }
}

library MathHelper {

  using SafeMath for uint256;

  function max(uint256 a, uint256 b) internal pure returns (uint256 _max){
      _max = b;
      if (a > b) {
          _max = a;
      }
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256 _min){
      _min = b;
      if (a < b) {
          _min = a;
      }
  }

  function sumNumbers(uint256[] _numbers) internal pure returns (uint256 _sum) {
      for (uint256 i=0;i<_numbers.length;i++) {
          _sum = _sum.add(_numbers[i]);
      }
  }
}

contract DaoCommonMini is IdentityCommon {

    using MathHelper for MathHelper;

     
    function isDaoNotReplaced()
        public
        view
        returns (bool _isNotReplaced)
    {
        _isNotReplaced = !daoUpgradeStorage().isReplacedByNewDao();
    }

     
    function isLockingPhase()
        public
        view
        returns (bool _isLockingPhase)
    {
        _isLockingPhase = currentTimeInQuarter() < getUintConfig(CONFIG_LOCKING_PHASE_DURATION);
    }

     
    function isMainPhase()
        public
        view
        returns (bool _isMainPhase)
    {
        _isMainPhase =
            isDaoNotReplaced() &&
            currentTimeInQuarter() >= getUintConfig(CONFIG_LOCKING_PHASE_DURATION);
    }

     
    modifier ifGlobalRewardsSet(uint256 _quarterNumber) {
        if (_quarterNumber > 1) {
            require(daoRewardsStorage().readDgxDistributionDay(_quarterNumber) > 0);
        }
        _;
    }

     
    function requireInPhase(uint256 _startingPoint, uint256 _relativePhaseStart, uint256 _relativePhaseEnd)
        internal
        view
    {
        require(_startingPoint > 0);
        require(now < _startingPoint.add(_relativePhaseEnd));
        require(now >= _startingPoint.add(_relativePhaseStart));
    }

     
    function currentQuarterNumber()
        public
        view
        returns(uint256 _quarterNumber)
    {
        _quarterNumber = getQuarterNumber(now);
    }

     
    function getQuarterNumber(uint256 _time)
        internal
        view
        returns (uint256 _index)
    {
        require(startOfFirstQuarterIsSet());
        _index =
            _time.sub(daoUpgradeStorage().startOfFirstQuarter())
            .div(getUintConfig(CONFIG_QUARTER_DURATION))
            .add(1);
    }

     
    function timeInQuarter(uint256 _time)
        internal
        view
        returns (uint256 _timeInQuarter)
    {
        require(startOfFirstQuarterIsSet());  
        _timeInQuarter =
            _time.sub(daoUpgradeStorage().startOfFirstQuarter())
            % getUintConfig(CONFIG_QUARTER_DURATION);
    }

     
    function startOfFirstQuarterIsSet()
        internal
        view
        returns (bool _isSet)
    {
        _isSet = daoUpgradeStorage().startOfFirstQuarter() != 0;
    }

     
    function currentTimeInQuarter()
        public
        view
        returns (uint256 _currentT)
    {
        _currentT = timeInQuarter(now);
    }

     
    function getTimeLeftInQuarter(uint256 _time)
        internal
        view
        returns (uint256 _timeLeftInQuarter)
    {
        _timeLeftInQuarter = getUintConfig(CONFIG_QUARTER_DURATION).sub(timeInQuarter(_time));
    }

    function daoListingService()
        internal
        view
        returns (DaoListingService _contract)
    {
        _contract = DaoListingService(get_contract(CONTRACT_SERVICE_DAO_LISTING));
    }

    function daoConfigsStorage()
        internal
        view
        returns (DaoConfigsStorage _contract)
    {
        _contract = DaoConfigsStorage(get_contract(CONTRACT_STORAGE_DAO_CONFIG));
    }

    function daoStakeStorage()
        internal
        view
        returns (DaoStakeStorage _contract)
    {
        _contract = DaoStakeStorage(get_contract(CONTRACT_STORAGE_DAO_STAKE));
    }

    function daoStorage()
        internal
        view
        returns (DaoStorage _contract)
    {
        _contract = DaoStorage(get_contract(CONTRACT_STORAGE_DAO));
    }

    function daoProposalCounterStorage()
        internal
        view
        returns (DaoProposalCounterStorage _contract)
    {
        _contract = DaoProposalCounterStorage(get_contract(CONTRACT_STORAGE_DAO_COUNTER));
    }

    function daoUpgradeStorage()
        internal
        view
        returns (DaoUpgradeStorage _contract)
    {
        _contract = DaoUpgradeStorage(get_contract(CONTRACT_STORAGE_DAO_UPGRADE));
    }

    function daoSpecialStorage()
        internal
        view
        returns (DaoSpecialStorage _contract)
    {
        _contract = DaoSpecialStorage(get_contract(CONTRACT_STORAGE_DAO_SPECIAL));
    }

    function daoPointsStorage()
        internal
        view
        returns (DaoPointsStorage _contract)
    {
        _contract = DaoPointsStorage(get_contract(CONTRACT_STORAGE_DAO_POINTS));
    }

    function daoRewardsStorage()
        internal
        view
        returns (DaoRewardsStorage _contract)
    {
        _contract = DaoRewardsStorage(get_contract(CONTRACT_STORAGE_DAO_REWARDS));
    }

    function intermediateResultsStorage()
        internal
        view
        returns (IntermediateResultsStorage _contract)
    {
        _contract = IntermediateResultsStorage(get_contract(CONTRACT_STORAGE_INTERMEDIATE_RESULTS));
    }

    function getUintConfig(bytes32 _configKey)
        public
        view
        returns (uint256 _configValue)
    {
        _configValue = daoConfigsStorage().uintConfigs(_configKey);
    }
}

contract DaoCommon is DaoCommonMini {

    using MathHelper for MathHelper;

     
    function isFromProposer(bytes32 _proposalId)
        internal
        view
        returns (bool _isFromProposer)
    {
        _isFromProposer = msg.sender == daoStorage().readProposalProposer(_proposalId);
    }

     
    function isEditable(bytes32 _proposalId)
        internal
        view
        returns (bool _isEditable)
    {
        bytes32 _finalVersion;
        (,,,,,,,_finalVersion,,) = daoStorage().readProposal(_proposalId);
        _isEditable = _finalVersion == EMPTY_BYTES;
    }

     
    function weiInDao()
        internal
        view
        returns (uint256 _wei)
    {
        _wei = get_contract(CONTRACT_DAO_FUNDING_MANAGER).balance;
    }

     
    modifier ifAfterDraftVotingPhase(bytes32 _proposalId) {
        uint256 _start = daoStorage().readProposalDraftVotingTime(_proposalId);
        require(_start > 0);  
        require(now >= _start.add(getUintConfig(CONFIG_DRAFT_VOTING_PHASE)));
        _;
    }

    modifier ifCommitPhase(bytes32 _proposalId, uint8 _index) {
        requireInPhase(
            daoStorage().readProposalVotingTime(_proposalId, _index),
            0,
            getUintConfig(_index == 0 ? CONFIG_VOTING_COMMIT_PHASE : CONFIG_INTERIM_COMMIT_PHASE)
        );
        _;
    }

    modifier ifRevealPhase(bytes32 _proposalId, uint256 _index) {
      requireInPhase(
          daoStorage().readProposalVotingTime(_proposalId, _index),
          getUintConfig(_index == 0 ? CONFIG_VOTING_COMMIT_PHASE : CONFIG_INTERIM_COMMIT_PHASE),
          getUintConfig(_index == 0 ? CONFIG_VOTING_PHASE_TOTAL : CONFIG_INTERIM_PHASE_TOTAL)
      );
      _;
    }

    modifier ifAfterProposalRevealPhase(bytes32 _proposalId, uint256 _index) {
      uint256 _start = daoStorage().readProposalVotingTime(_proposalId, _index);
      require(_start > 0);
      require(now >= _start.add(getUintConfig(_index == 0 ? CONFIG_VOTING_PHASE_TOTAL : CONFIG_INTERIM_PHASE_TOTAL)));
      _;
    }

    modifier ifDraftVotingPhase(bytes32 _proposalId) {
        requireInPhase(
            daoStorage().readProposalDraftVotingTime(_proposalId),
            0,
            getUintConfig(CONFIG_DRAFT_VOTING_PHASE)
        );
        _;
    }

    modifier isProposalState(bytes32 _proposalId, bytes32 _STATE) {
        bytes32 _currentState;
        (,,,_currentState,,,,,,) = daoStorage().readProposal(_proposalId);
        require(_currentState == _STATE);
        _;
    }

     
    modifier ifFundingPossible(uint256[] _fundings, uint256 _finalReward) {
        require(MathHelper.sumNumbers(_fundings).add(_finalReward) <= weiInDao());
        _;
    }

    modifier ifDraftNotClaimed(bytes32 _proposalId) {
        require(daoStorage().isDraftClaimed(_proposalId) == false);
        _;
    }

    modifier ifNotClaimed(bytes32 _proposalId, uint256 _index) {
        require(daoStorage().isClaimed(_proposalId, _index) == false);
        _;
    }

    modifier ifNotClaimedSpecial(bytes32 _proposalId) {
        require(daoSpecialStorage().isClaimed(_proposalId) == false);
        _;
    }

    modifier hasNotRevealed(bytes32 _proposalId, uint256 _index) {
        uint256 _voteWeight;
        (, _voteWeight) = daoStorage().readVote(_proposalId, _index, msg.sender);
        require(_voteWeight == uint(0));
        _;
    }

    modifier hasNotRevealedSpecial(bytes32 _proposalId) {
        uint256 _weight;
        (,_weight) = daoSpecialStorage().readVote(_proposalId, msg.sender);
        require(_weight == uint256(0));
        _;
    }

    modifier ifAfterRevealPhaseSpecial(bytes32 _proposalId) {
      uint256 _start = daoSpecialStorage().readVotingTime(_proposalId);
      require(_start > 0);
      require(now.sub(_start) >= getUintConfig(CONFIG_SPECIAL_PROPOSAL_PHASE_TOTAL));
      _;
    }

    modifier ifCommitPhaseSpecial(bytes32 _proposalId) {
        requireInPhase(
            daoSpecialStorage().readVotingTime(_proposalId),
            0,
            getUintConfig(CONFIG_SPECIAL_PROPOSAL_COMMIT_PHASE)
        );
        _;
    }

    modifier ifRevealPhaseSpecial(bytes32 _proposalId) {
        requireInPhase(
            daoSpecialStorage().readVotingTime(_proposalId),
            getUintConfig(CONFIG_SPECIAL_PROPOSAL_COMMIT_PHASE),
            getUintConfig(CONFIG_SPECIAL_PROPOSAL_PHASE_TOTAL)
        );
        _;
    }

    function daoWhitelistingStorage()
        internal
        view
        returns (DaoWhitelistingStorage _contract)
    {
        _contract = DaoWhitelistingStorage(get_contract(CONTRACT_STORAGE_DAO_WHITELISTING));
    }

    function getAddressConfig(bytes32 _configKey)
        public
        view
        returns (address _configValue)
    {
        _configValue = daoConfigsStorage().addressConfigs(_configKey);
    }

    function getBytesConfig(bytes32 _configKey)
        public
        view
        returns (bytes32 _configValue)
    {
        _configValue = daoConfigsStorage().bytesConfigs(_configKey);
    }

     
    function isParticipant(address _user)
        public
        view
        returns (bool _is)
    {
        _is =
            (daoRewardsStorage().lastParticipatedQuarter(_user) == currentQuarterNumber())
            && (daoStakeStorage().lockedDGDStake(_user) >= getUintConfig(CONFIG_MINIMUM_LOCKED_DGD));
    }

     
    function isModerator(address _user)
        public
        view
        returns (bool _is)
    {
        _is =
            (daoRewardsStorage().lastParticipatedQuarter(_user) == currentQuarterNumber())
            && (daoStakeStorage().lockedDGDStake(_user) >= getUintConfig(CONFIG_MINIMUM_DGD_FOR_MODERATOR))
            && (daoPointsStorage().getReputation(_user) >= getUintConfig(CONFIG_MINIMUM_REPUTATION_FOR_MODERATOR));
    }

     
    function startOfMilestone(bytes32 _proposalId, uint256 _milestoneIndex)
        internal
        view
        returns (uint256 _milestoneStart)
    {
        uint256 _startOfPrecedingVotingRound = daoStorage().readProposalVotingTime(_proposalId, _milestoneIndex);
        require(_startOfPrecedingVotingRound > 0);
         

        if (_milestoneIndex == 0) {  
            _milestoneStart =
                _startOfPrecedingVotingRound
                .add(getUintConfig(CONFIG_VOTING_PHASE_TOTAL));
        } else {  
            _milestoneStart =
                _startOfPrecedingVotingRound
                .add(getUintConfig(CONFIG_INTERIM_PHASE_TOTAL));
        }
    }

     
    function getTimelineForNextVote(
        uint256 _index,
        uint256 _tentativeVotingStart
    )
        internal
        view
        returns (uint256 _actualVotingStart)
    {
        uint256 _timeLeftInQuarter = getTimeLeftInQuarter(_tentativeVotingStart);
        uint256 _votingDuration = getUintConfig(_index == 0 ? CONFIG_VOTING_PHASE_TOTAL : CONFIG_INTERIM_PHASE_TOTAL);
        _actualVotingStart = _tentativeVotingStart;
        if (timeInQuarter(_tentativeVotingStart) < getUintConfig(CONFIG_LOCKING_PHASE_DURATION)) {  
            _actualVotingStart = _tentativeVotingStart.add(
                getUintConfig(CONFIG_LOCKING_PHASE_DURATION).sub(timeInQuarter(_tentativeVotingStart))
            );
        } else if (_timeLeftInQuarter < _votingDuration.add(getUintConfig(CONFIG_VOTE_CLAIMING_DEADLINE))) {  
            _actualVotingStart = _tentativeVotingStart.add(
                _timeLeftInQuarter.add(getUintConfig(CONFIG_LOCKING_PHASE_DURATION)).add(1)
            );
        }
    }

     
    function checkNonDigixProposalLimit(bytes32 _proposalId)
        internal
        view
    {
        require(isNonDigixProposalsWithinLimit(_proposalId));
    }

    function isNonDigixProposalsWithinLimit(bytes32 _proposalId)
        internal
        view
        returns (bool _withinLimit)
    {
        bool _isDigixProposal;
        (,,,,,,,,,_isDigixProposal) = daoStorage().readProposal(_proposalId);
        _withinLimit = true;
        if (!_isDigixProposal) {
            _withinLimit = daoProposalCounterStorage().proposalCountByQuarter(currentQuarterNumber()) < getUintConfig(CONFIG_NON_DIGIX_PROPOSAL_CAP_PER_QUARTER);
        }
    }

     
    function checkNonDigixFundings(uint256[] _milestonesFundings, uint256 _finalReward)
        internal
        view
    {
        if (!is_founder()) {
            require(_milestonesFundings.length <= getUintConfig(CONFIG_MAX_MILESTONES_FOR_NON_DIGIX));
            require(MathHelper.sumNumbers(_milestonesFundings).add(_finalReward) <= getUintConfig(CONFIG_MAX_FUNDING_FOR_NON_DIGIX));
        }
    }

     
    function senderCanDoProposerOperations()
        internal
        view
    {
        require(isMainPhase());
        require(isParticipant(msg.sender));
        require(identity_storage().is_kyc_approved(msg.sender));
    }
}

 
 
 
contract DgxDemurrageCalculator {
    function calculateDemurrage(uint256 _initial_balance, uint256 _days_elapsed)
        public
        view
        returns (uint256 _demurrage_fees, bool _no_demurrage_fees);
}

contract DaoCalculatorService is DaoCommon {

    address public dgxDemurrageCalculatorAddress;

    using MathHelper for MathHelper;

    constructor(address _resolver, address _dgxDemurrageCalculatorAddress)
        public
    {
        require(init(CONTRACT_SERVICE_DAO_CALCULATOR, _resolver));
        dgxDemurrageCalculatorAddress = _dgxDemurrageCalculatorAddress;
    }


     
    function calculateAdditionalLockedDGDStake(uint256 _additionalDgd)
        public
        view
        returns (uint256 _additionalLockedDGDStake)
    {
        _additionalLockedDGDStake =
            _additionalDgd.mul(
                getUintConfig(CONFIG_QUARTER_DURATION)
                .sub(
                    MathHelper.max(
                        currentTimeInQuarter(),
                        getUintConfig(CONFIG_LOCKING_PHASE_DURATION)
                    )
                )
            )
            .div(
                getUintConfig(CONFIG_QUARTER_DURATION)
                .sub(getUintConfig(CONFIG_LOCKING_PHASE_DURATION))
            );
    }


     
    function minimumDraftQuorum(bytes32 _proposalId)
        public
        view
        returns (uint256 _minQuorum)
    {
        uint256[] memory _fundings;

        (_fundings,) = daoStorage().readProposalFunding(_proposalId);
        _minQuorum = calculateMinQuorum(
            daoStakeStorage().totalModeratorLockedDGDStake(),
            getUintConfig(CONFIG_DRAFT_QUORUM_FIXED_PORTION_NUMERATOR),
            getUintConfig(CONFIG_DRAFT_QUORUM_FIXED_PORTION_DENOMINATOR),
            getUintConfig(CONFIG_DRAFT_QUORUM_SCALING_FACTOR_NUMERATOR),
            getUintConfig(CONFIG_DRAFT_QUORUM_SCALING_FACTOR_DENOMINATOR),
            _fundings[0]
        );
    }


    function draftQuotaPass(uint256 _for, uint256 _against)
        public
        view
        returns (bool _passed)
    {
        _passed = _for.mul(getUintConfig(CONFIG_DRAFT_QUOTA_DENOMINATOR))
                > getUintConfig(CONFIG_DRAFT_QUOTA_NUMERATOR).mul(_for.add(_against));
    }


     
    function minimumVotingQuorum(bytes32 _proposalId, uint256 _milestone_id)
        public
        view
        returns (uint256 _minQuorum)
    {
        require(senderIsAllowedToRead());
        uint256[] memory _weiAskedPerMilestone;
        uint256 _finalReward;
        (_weiAskedPerMilestone,_finalReward) = daoStorage().readProposalFunding(_proposalId);
        require(_milestone_id <= _weiAskedPerMilestone.length);
        if (_milestone_id == _weiAskedPerMilestone.length) {
             
            _minQuorum = calculateMinQuorum(
                daoStakeStorage().totalLockedDGDStake(),
                getUintConfig(CONFIG_VOTING_QUORUM_FIXED_PORTION_NUMERATOR),
                getUintConfig(CONFIG_VOTING_QUORUM_FIXED_PORTION_DENOMINATOR),
                getUintConfig(CONFIG_FINAL_REWARD_SCALING_FACTOR_NUMERATOR),
                getUintConfig(CONFIG_FINAL_REWARD_SCALING_FACTOR_DENOMINATOR),
                _finalReward
            );
        } else {
             
            _minQuorum = calculateMinQuorum(
                daoStakeStorage().totalLockedDGDStake(),
                getUintConfig(CONFIG_VOTING_QUORUM_FIXED_PORTION_NUMERATOR),
                getUintConfig(CONFIG_VOTING_QUORUM_FIXED_PORTION_DENOMINATOR),
                getUintConfig(CONFIG_VOTING_QUORUM_SCALING_FACTOR_NUMERATOR),
                getUintConfig(CONFIG_VOTING_QUORUM_SCALING_FACTOR_DENOMINATOR),
                _weiAskedPerMilestone[_milestone_id]
            );
        }
    }


     
    function minimumVotingQuorumForSpecial()
        public
        view
        returns (uint256 _minQuorum)
    {
      _minQuorum = getUintConfig(CONFIG_SPECIAL_PROPOSAL_QUORUM_NUMERATOR).mul(
                       daoStakeStorage().totalLockedDGDStake()
                   ).div(
                       getUintConfig(CONFIG_SPECIAL_PROPOSAL_QUORUM_DENOMINATOR)
                   );
    }


    function votingQuotaPass(uint256 _for, uint256 _against)
        public
        view
        returns (bool _passed)
    {
        _passed = _for.mul(getUintConfig(CONFIG_VOTING_QUOTA_DENOMINATOR))
                > getUintConfig(CONFIG_VOTING_QUOTA_NUMERATOR).mul(_for.add(_against));
    }


    function votingQuotaForSpecialPass(uint256 _for, uint256 _against)
        public
        view
        returns (bool _passed)
    {
        _passed =_for.mul(getUintConfig(CONFIG_SPECIAL_QUOTA_DENOMINATOR))
                > getUintConfig(CONFIG_SPECIAL_QUOTA_NUMERATOR).mul(_for.add(_against));
    }


    function calculateMinQuorum(
        uint256 _totalStake,
        uint256 _fixedQuorumPortionNumerator,
        uint256 _fixedQuorumPortionDenominator,
        uint256 _scalingFactorNumerator,
        uint256 _scalingFactorDenominator,
        uint256 _weiAsked
    )
        internal
        view
        returns (uint256 _minimumQuorum)
    {
        uint256 _weiInDao = weiInDao();
         
        _minimumQuorum = (_totalStake.mul(_fixedQuorumPortionNumerator)).div(_fixedQuorumPortionDenominator);

         
        _minimumQuorum = _minimumQuorum.add(_totalStake.mul(_weiAsked.mul(_scalingFactorNumerator)).div(_weiInDao.mul(_scalingFactorDenominator)));
    }


    function calculateUserEffectiveBalance(
        uint256 _minimalParticipationPoint,
        uint256 _quarterPointScalingFactor,
        uint256 _reputationPointScalingFactor,
        uint256 _quarterPoint,
        uint256 _reputationPoint,
        uint256 _lockedDGDStake
    )
        public
        pure
        returns (uint256 _effectiveDGDBalance)
    {
        uint256 _baseDGDBalance = MathHelper.min(_quarterPoint, _minimalParticipationPoint).mul(_lockedDGDStake).div(_minimalParticipationPoint);
        _effectiveDGDBalance =
            _baseDGDBalance
            .mul(_quarterPointScalingFactor.add(_quarterPoint).sub(_minimalParticipationPoint))
            .mul(_reputationPointScalingFactor.add(_reputationPoint))
            .div(_quarterPointScalingFactor.mul(_reputationPointScalingFactor));
    }


    function calculateDemurrage(uint256 _balance, uint256 _daysElapsed)
        public
        view
        returns (uint256 _demurrageFees)
    {
        (_demurrageFees,) = DgxDemurrageCalculator(dgxDemurrageCalculatorAddress).calculateDemurrage(_balance, _daysElapsed);
    }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library DaoIntermediateStructs {

     
     
     
    struct VotingCount {
         
        uint256 forCount;
         
        uint256 againstCount;
    }

     
    struct Users {
         
        uint256 usersLength;
         
        address[] users;
    }
}

contract DaoRewardsManagerCommon is DaoCommonMini {

    using DaoStructs for DaoStructs.DaoQuarterInfo;

     
     
    struct UserRewards {
        uint256 lastParticipatedQuarter;
        uint256 lastQuarterThatRewardsWasUpdated;
        uint256 effectiveDGDBalance;
        uint256 effectiveModeratorDGDBalance;
        DaoStructs.DaoQuarterInfo qInfo;
    }

     
    struct QuarterRewardsInfo {
        uint256 previousQuarter;
        uint256 totalEffectiveDGDPreviousQuarter;
        uint256 totalEffectiveModeratorDGDLastQuarter;
        uint256 dgxRewardsPoolLastQuarter;
        uint256 userCount;
        uint256 i;
        DaoStructs.DaoQuarterInfo qInfo;
        address currentUser;
        address[] users;
        bool doneCalculatingEffectiveBalance;
        bool doneCalculatingModeratorEffectiveBalance;
    }

     
    function getUserRewardsStruct(address _user)
        internal
        view
        returns (UserRewards memory _data)
    {
        _data.lastParticipatedQuarter = daoRewardsStorage().lastParticipatedQuarter(_user);
        _data.lastQuarterThatRewardsWasUpdated = daoRewardsStorage().lastQuarterThatRewardsWasUpdated(_user);
        _data.qInfo = readQuarterInfo(_data.lastParticipatedQuarter);
    }

     
    function readQuarterInfo(uint256 _quarterNumber)
        internal
        view
        returns (DaoStructs.DaoQuarterInfo _qInfo)
    {
        (
            _qInfo.minimalParticipationPoint,
            _qInfo.quarterPointScalingFactor,
            _qInfo.reputationPointScalingFactor,
            _qInfo.totalEffectiveDGDPreviousQuarter
        ) = daoRewardsStorage().readQuarterParticipantInfo(_quarterNumber);
        (
            _qInfo.moderatorMinimalParticipationPoint,
            _qInfo.moderatorQuarterPointScalingFactor,
            _qInfo.moderatorReputationPointScalingFactor,
            _qInfo.totalEffectiveModeratorDGDLastQuarter
        ) = daoRewardsStorage().readQuarterModeratorInfo(_quarterNumber);
        (
            _qInfo.dgxDistributionDay,
            _qInfo.dgxRewardsPoolLastQuarter,
            _qInfo.sumRewardsFromBeginning
        ) = daoRewardsStorage().readQuarterGeneralInfo(_quarterNumber);
    }
}

contract DaoRewardsManagerExtras is DaoRewardsManagerCommon {

    constructor(address _resolver) public {
        require(init(CONTRACT_DAO_REWARDS_MANAGER_EXTRAS, _resolver));
    }

    function daoCalculatorService()
        internal
        view
        returns (DaoCalculatorService _contract)
    {
        _contract = DaoCalculatorService(get_contract(CONTRACT_SERVICE_DAO_CALCULATOR));
    }

     
     
     
    function calculateUserRewardsForLastParticipatingQuarter(address _user)
        public
        view
        returns (uint256 _dgxRewardsAsParticipant, uint256 _dgxRewardsAsModerator)
    {
        UserRewards memory data = getUserRewardsStruct(_user);

        data.effectiveDGDBalance = daoCalculatorService().calculateUserEffectiveBalance(
            data.qInfo.minimalParticipationPoint,
            data.qInfo.quarterPointScalingFactor,
            data.qInfo.reputationPointScalingFactor,
            daoPointsStorage().getQuarterPoint(_user, data.lastParticipatedQuarter),

             
             
            daoPointsStorage().getReputation(_user),

             
             
             
            daoStakeStorage().lockedDGDStake(_user)
        );

        data.effectiveModeratorDGDBalance = daoCalculatorService().calculateUserEffectiveBalance(
            data.qInfo.moderatorMinimalParticipationPoint,
            data.qInfo.moderatorQuarterPointScalingFactor,
            data.qInfo.moderatorReputationPointScalingFactor,
            daoPointsStorage().getQuarterModeratorPoint(_user, data.lastParticipatedQuarter),

             
             
            daoPointsStorage().getReputation(_user),

             
             
             
            daoStakeStorage().lockedDGDStake(_user)
        );

         
        if (daoRewardsStorage().readTotalEffectiveDGDLastQuarter(data.lastParticipatedQuarter.add(1)) > 0) {
            _dgxRewardsAsParticipant =
                data.effectiveDGDBalance
                .mul(daoRewardsStorage().readRewardsPoolOfLastQuarter(
                    data.lastParticipatedQuarter.add(1)
                ))
                .mul(
                    getUintConfig(CONFIG_PORTION_TO_MODERATORS_DEN)
                    .sub(getUintConfig(CONFIG_PORTION_TO_MODERATORS_NUM))
                )
                .div(daoRewardsStorage().readTotalEffectiveDGDLastQuarter(
                    data.lastParticipatedQuarter.add(1)
                ))
                .div(getUintConfig(CONFIG_PORTION_TO_MODERATORS_DEN));
        }

         
        if (daoRewardsStorage().readTotalEffectiveModeratorDGDLastQuarter(data.lastParticipatedQuarter.add(1)) > 0) {
            _dgxRewardsAsModerator =
                data.effectiveModeratorDGDBalance
                .mul(daoRewardsStorage().readRewardsPoolOfLastQuarter(
                    data.lastParticipatedQuarter.add(1)
                ))
                .mul(
                     getUintConfig(CONFIG_PORTION_TO_MODERATORS_NUM)
                )
                .div(daoRewardsStorage().readTotalEffectiveModeratorDGDLastQuarter(
                    data.lastParticipatedQuarter.add(1)
                ))
                .div(getUintConfig(CONFIG_PORTION_TO_MODERATORS_DEN));
        }
    }
}

 
contract DaoRewardsManager is DaoRewardsManagerCommon {
    using MathHelper for MathHelper;
    using DaoStructs for DaoStructs.DaoQuarterInfo;
    using DaoStructs for DaoStructs.IntermediateResults;

     
     
    event StartNewQuarter(uint256 indexed _quarterNumber);

    address public ADDRESS_DGX_TOKEN;

    function daoCalculatorService()
        internal
        view
        returns (DaoCalculatorService _contract)
    {
        _contract = DaoCalculatorService(get_contract(CONTRACT_SERVICE_DAO_CALCULATOR));
    }

    function daoRewardsManagerExtras()
        internal
        view
        returns (DaoRewardsManagerExtras _contract)
    {
        _contract = DaoRewardsManagerExtras(get_contract(CONTRACT_DAO_REWARDS_MANAGER_EXTRAS));
    }

     
    constructor(address _resolver, address _dgxAddress)
        public
    {
        require(init(CONTRACT_DAO_REWARDS_MANAGER, _resolver));
        ADDRESS_DGX_TOKEN = _dgxAddress;

         
        daoRewardsStorage().updateQuarterInfo(
            1,
            getUintConfig(CONFIG_MINIMAL_QUARTER_POINT),
            getUintConfig(CONFIG_QUARTER_POINT_SCALING_FACTOR),
            getUintConfig(CONFIG_REPUTATION_POINT_SCALING_FACTOR),
            0,  
            getUintConfig(CONFIG_MODERATOR_MINIMAL_QUARTER_POINT),
            getUintConfig(CONFIG_MODERATOR_QUARTER_POINT_SCALING_FACTOR),
            getUintConfig(CONFIG_MODERATOR_REPUTATION_POINT_SCALING_FACTOR),
            0,  

             
             
             
            now,

            0,  
            0  
        );
    }


     
    function moveDGXsToNewDao(address _newDaoRewardsManager)
        public
    {
        require(sender_is(CONTRACT_DAO));
        uint256 _dgxBalance = ERC20(ADDRESS_DGX_TOKEN).balanceOf(address(this));
        ERC20(ADDRESS_DGX_TOKEN).transfer(_newDaoRewardsManager, _dgxBalance);
    }


     
    function claimRewards()
        public
        ifGlobalRewardsSet(currentQuarterNumber())
    {
        require(isDaoNotReplaced());

        address _user = msg.sender;
        uint256 _claimableDGX;

         
        (, _claimableDGX) = updateUserRewardsForLastParticipatingQuarter(_user);

         
         
         
         
        uint256 _days_elapsed = now
            .sub(
                daoRewardsStorage().readDgxDistributionDay(
                    daoRewardsStorage().lastQuarterThatRewardsWasUpdated(_user).add(1)  
                )
            )
            .div(1 days);

          
          
        daoRewardsStorage().addToTotalDgxClaimed(_claimableDGX);

        _claimableDGX = _claimableDGX.sub(
            daoCalculatorService().calculateDemurrage(
                _claimableDGX,
                _days_elapsed
            ));

        daoRewardsStorage().updateClaimableDGX(_user, 0);
        ERC20(ADDRESS_DGX_TOKEN).transfer(_user, _claimableDGX);
         
    }


     
    function updateRewardsAndReputationBeforeNewQuarter(address _user)
        public
    {
        require(sender_is(CONTRACT_DAO_STAKE_LOCKING));

        updateUserRewardsForLastParticipatingQuarter(_user);
        updateUserReputationUntilPreviousQuarter(_user);
    }


     
     
     
     
     
     
     
    function updateUserReputationUntilPreviousQuarter (address _user)
        private
    {
        uint256 _lastParticipatedQuarter = daoRewardsStorage().lastParticipatedQuarter(_user);
        uint256 _lastQuarterThatReputationWasUpdated = daoRewardsStorage().lastQuarterThatReputationWasUpdated(_user);
        uint256 _reputationDeduction;

         
         
        if (
            _lastQuarterThatReputationWasUpdated.add(1) >= currentQuarterNumber()
        ) {
            return;
        }

         
         
        if (
            (_lastQuarterThatReputationWasUpdated.add(1) == _lastParticipatedQuarter)
        ) {
            updateRPfromQP(
                _user,
                daoPointsStorage().getQuarterPoint(_user, _lastParticipatedQuarter),
                getUintConfig(CONFIG_MINIMAL_QUARTER_POINT),
                getUintConfig(CONFIG_MAXIMUM_REPUTATION_DEDUCTION),
                getUintConfig(CONFIG_REPUTATION_PER_EXTRA_QP_NUM),
                getUintConfig(CONFIG_REPUTATION_PER_EXTRA_QP_DEN)
            );

             
             
             
             
            if (daoStakeStorage().isInModeratorsList(_user)) {
                updateRPfromQP(
                    _user,
                    daoPointsStorage().getQuarterModeratorPoint(_user, _lastParticipatedQuarter),
                    getUintConfig(CONFIG_MODERATOR_MINIMAL_QUARTER_POINT),
                    getUintConfig(CONFIG_MAXIMUM_MODERATOR_REPUTATION_DEDUCTION),
                    getUintConfig(CONFIG_REPUTATION_PER_EXTRA_MODERATOR_QP_NUM),
                    getUintConfig(CONFIG_REPUTATION_PER_EXTRA_MODERATOR_QP_DEN)
                );
            }
            _lastQuarterThatReputationWasUpdated = _lastParticipatedQuarter;
        }

         
         
         

         
         

        _reputationDeduction =
            (currentQuarterNumber().sub(1).sub(_lastQuarterThatReputationWasUpdated))
            .mul(
                getUintConfig(CONFIG_MAXIMUM_REPUTATION_DEDUCTION)
                .add(getUintConfig(CONFIG_PUNISHMENT_FOR_NOT_LOCKING))
            );

        if (_reputationDeduction > 0) daoPointsStorage().reduceReputation(_user, _reputationDeduction);
        daoRewardsStorage().updateLastQuarterThatReputationWasUpdated(_user, currentQuarterNumber().sub(1));
    }


     
    function updateRPfromQP (
        address _user,
        uint256 _userQP,
        uint256 _minimalQP,
        uint256 _maxRPDeduction,
        uint256 _rpPerExtraQP_num,
        uint256 _rpPerExtraQP_den
    ) internal {
        uint256 _reputationDeduction;
        uint256 _reputationAddition;
        if (_userQP < _minimalQP) {
            _reputationDeduction =
                _minimalQP.sub(_userQP)
                .mul(_maxRPDeduction)
                .div(_minimalQP);

            daoPointsStorage().reduceReputation(_user, _reputationDeduction);
        } else {
            _reputationAddition =
                _userQP.sub(_minimalQP)
                .mul(_rpPerExtraQP_num)
                .div(_rpPerExtraQP_den);

            daoPointsStorage().increaseReputation(_user, _reputationAddition);
        }
    }

     
    function updateUserRewardsForLastParticipatingQuarter(address _user)
        internal
        returns (bool _valid, uint256 _userClaimableDgx)
    {
        UserRewards memory data = getUserRewardsStruct(_user);
        _userClaimableDgx = daoRewardsStorage().claimableDGXs(_user);

         
         
         
         
         
         
        if (
            (currentQuarterNumber() == data.lastParticipatedQuarter) ||
            (data.lastParticipatedQuarter <= data.lastQuarterThatRewardsWasUpdated)
        ) {
            return (false, _userClaimableDgx);
        }

         

         
         
         
        uint256 _days_elapsed = daoRewardsStorage().readDgxDistributionDay(data.lastParticipatedQuarter.add(1))
            .sub(daoRewardsStorage().readDgxDistributionDay(data.lastQuarterThatRewardsWasUpdated.add(1)))
            .div(1 days);
        uint256 _demurrageFees = daoCalculatorService().calculateDemurrage(
            _userClaimableDgx,
            _days_elapsed
        );
        _userClaimableDgx = _userClaimableDgx.sub(_demurrageFees);
         

         
         
         
         
         
        daoRewardsStorage().addToTotalDgxClaimed(_demurrageFees);

        uint256 _dgxRewardsAsParticipant;
        uint256 _dgxRewardsAsModerator;
        (_dgxRewardsAsParticipant, _dgxRewardsAsModerator) = daoRewardsManagerExtras().calculateUserRewardsForLastParticipatingQuarter(_user);
        _userClaimableDgx = _userClaimableDgx.add(_dgxRewardsAsParticipant).add(_dgxRewardsAsModerator);

         
         
        daoRewardsStorage().updateClaimableDGX(_user, _userClaimableDgx);

         
        daoRewardsStorage().updateLastQuarterThatRewardsWasUpdated(_user, data.lastParticipatedQuarter);
        _valid = true;
    }

     
    function calculateGlobalRewardsBeforeNewQuarter(uint256 _operations)
        public
        if_founder()
        returns (bool _done)
    {
        require(isDaoNotReplaced());
        require(daoUpgradeStorage().startOfFirstQuarter() != 0);  
        require(isLockingPhase());
        require(daoRewardsStorage().readDgxDistributionDay(currentQuarterNumber()) == 0);  

        QuarterRewardsInfo memory info;
        info.previousQuarter = currentQuarterNumber().sub(1);
        require(info.previousQuarter > 0);  
        info.qInfo = readQuarterInfo(info.previousQuarter);

        DaoStructs.IntermediateResults memory interResults;
        (
            interResults.countedUntil,,,
            info.totalEffectiveDGDPreviousQuarter
        ) = intermediateResultsStorage().getIntermediateResults(
            getIntermediateResultsIdForGlobalRewards(info.previousQuarter, false)
        );

        uint256 _operationsLeft = sumEffectiveBalance(info, false, _operations, interResults);
         
         

         
        if (!info.doneCalculatingEffectiveBalance) { return false; }

        (
            interResults.countedUntil,,,
            info.totalEffectiveModeratorDGDLastQuarter
        ) = intermediateResultsStorage().getIntermediateResults(
            getIntermediateResultsIdForGlobalRewards(info.previousQuarter, true)
        );

        sumEffectiveBalance(info, true, _operationsLeft, interResults);

         
        if (!info.doneCalculatingModeratorEffectiveBalance) { return false; }

         
        processGlobalRewardsUpdate(info);
        _done = true;

        emit StartNewQuarter(currentQuarterNumber());
    }


     
    function getIntermediateResultsIdForGlobalRewards(uint256 _quarterNumber, bool _forModerator) internal view returns (bytes32 _id) {
        _id = keccak256(abi.encodePacked(
            _forModerator ? INTERMEDIATE_MODERATOR_DGD_IDENTIFIER : INTERMEDIATE_DGD_IDENTIFIER,
            _quarterNumber
        ));
    }


     
    function processGlobalRewardsUpdate(QuarterRewardsInfo memory info) internal {
         
        info.dgxRewardsPoolLastQuarter =
            ERC20(ADDRESS_DGX_TOKEN).balanceOf(address(this))
            .add(daoRewardsStorage().totalDGXsClaimed())
            .sub(info.qInfo.sumRewardsFromBeginning);

         
        daoStakeStorage().updateTotalLockedDGDStake(0);
        daoStakeStorage().updateTotalModeratorLockedDGDs(0);

        daoRewardsStorage().updateQuarterInfo(
            info.previousQuarter.add(1),
            getUintConfig(CONFIG_MINIMAL_QUARTER_POINT),
            getUintConfig(CONFIG_QUARTER_POINT_SCALING_FACTOR),
            getUintConfig(CONFIG_REPUTATION_POINT_SCALING_FACTOR),
            info.totalEffectiveDGDPreviousQuarter,

            getUintConfig(CONFIG_MODERATOR_MINIMAL_QUARTER_POINT),
            getUintConfig(CONFIG_MODERATOR_QUARTER_POINT_SCALING_FACTOR),
            getUintConfig(CONFIG_MODERATOR_REPUTATION_POINT_SCALING_FACTOR),
            info.totalEffectiveModeratorDGDLastQuarter,

            now,
            info.dgxRewardsPoolLastQuarter,
            info.qInfo.sumRewardsFromBeginning.add(info.dgxRewardsPoolLastQuarter)
        );
    }


     
    function sumEffectiveBalance (
        QuarterRewardsInfo memory info,
        bool _badgeCalculation,  
        uint256 _operations,
        DaoStructs.IntermediateResults memory _interResults
    )
        internal
        returns (uint _operationsLeft)
    {
        if (_operations == 0) return _operations;  

        if (_interResults.countedUntil == EMPTY_ADDRESS) {
             
             
            info.users = _badgeCalculation ?
                daoListingService().listModerators(_operations, true)
                : daoListingService().listParticipants(_operations, true);
        } else {
            info.users = _badgeCalculation ?
                daoListingService().listModeratorsFrom(_interResults.countedUntil, _operations, true)
                : daoListingService().listParticipantsFrom(_interResults.countedUntil, _operations, true);

             
            if (info.users.length == 0) {
                info.doneCalculatingEffectiveBalance = true;
                return _operations;
            }
        }

        address _lastAddress;
        _lastAddress = info.users[info.users.length - 1];

        info.userCount = info.users.length;
        for (info.i=0;info.i<info.userCount;info.i++) {
            info.currentUser = info.users[info.i];
             
            if (daoRewardsStorage().lastParticipatedQuarter(info.currentUser) != info.previousQuarter) {
                continue;
            }
            if (_badgeCalculation) {
                info.totalEffectiveModeratorDGDLastQuarter = info.totalEffectiveModeratorDGDLastQuarter.add(daoCalculatorService().calculateUserEffectiveBalance(
                    info.qInfo.moderatorMinimalParticipationPoint,
                    info.qInfo.moderatorQuarterPointScalingFactor,
                    info.qInfo.moderatorReputationPointScalingFactor,
                    daoPointsStorage().getQuarterModeratorPoint(info.currentUser, info.previousQuarter),
                    daoPointsStorage().getReputation(info.currentUser),
                    daoStakeStorage().lockedDGDStake(info.currentUser)
                ));
            } else {
                info.totalEffectiveDGDPreviousQuarter = info.totalEffectiveDGDPreviousQuarter.add(daoCalculatorService().calculateUserEffectiveBalance(
                    info.qInfo.minimalParticipationPoint,
                    info.qInfo.quarterPointScalingFactor,
                    info.qInfo.reputationPointScalingFactor,
                    daoPointsStorage().getQuarterPoint(info.currentUser, info.previousQuarter),
                    daoPointsStorage().getReputation(info.currentUser),
                    daoStakeStorage().lockedDGDStake(info.currentUser)
                ));
            }
        }

         
        if (_lastAddress == daoStakeStorage().readLastModerator() && _badgeCalculation) {
            info.doneCalculatingModeratorEffectiveBalance = true;
        }
        if (_lastAddress == daoStakeStorage().readLastParticipant() && !_badgeCalculation) {
            info.doneCalculatingEffectiveBalance = true;
        }
         
        intermediateResultsStorage().setIntermediateResults(
            getIntermediateResultsIdForGlobalRewards(info.previousQuarter, _badgeCalculation),
            _lastAddress,
            0,0,
            _badgeCalculation ? info.totalEffectiveModeratorDGDLastQuarter : info.totalEffectiveDGDPreviousQuarter
        );

        _operationsLeft = _operations.sub(info.userCount);
    }
}

 
contract DaoVotingClaims is DaoCommon {
    using DaoIntermediateStructs for DaoIntermediateStructs.VotingCount;
    using DaoIntermediateStructs for DaoIntermediateStructs.Users;
    using DaoStructs for DaoStructs.IntermediateResults;

    function daoCalculatorService()
        internal
        view
        returns (DaoCalculatorService _contract)
    {
        _contract = DaoCalculatorService(get_contract(CONTRACT_SERVICE_DAO_CALCULATOR));
    }

    function daoFundingManager()
        internal
        view
        returns (DaoFundingManager _contract)
    {
        _contract = DaoFundingManager(get_contract(CONTRACT_DAO_FUNDING_MANAGER));
    }

    function daoRewardsManager()
        internal
        view
        returns (DaoRewardsManager _contract)
    {
        _contract = DaoRewardsManager(get_contract(CONTRACT_DAO_REWARDS_MANAGER));
    }

    constructor(address _resolver) public {
        require(init(CONTRACT_DAO_VOTING_CLAIMS, _resolver));
    }


     
    function claimDraftVotingResult(
        bytes32 _proposalId,
        uint256 _operations
    )
        public
        ifDraftNotClaimed(_proposalId)
        ifAfterDraftVotingPhase(_proposalId)
        returns (bool _passed, bool _done)
    {
         
        if (now > daoStorage().readProposalDraftVotingTime(_proposalId)
                    .add(getUintConfig(CONFIG_DRAFT_VOTING_PHASE))
                    .add(getUintConfig(CONFIG_VOTE_CLAIMING_DEADLINE))
            || !isNonDigixProposalsWithinLimit(_proposalId))
        {
            daoStorage().setProposalDraftPass(_proposalId, false);
            daoStorage().setDraftVotingClaim(_proposalId, true);
            processCollateralRefund(_proposalId);
            return (false, true);
        }
        require(isFromProposer(_proposalId));
        senderCanDoProposerOperations();

         
        DaoStructs.IntermediateResults memory _currentResults;
        (
            _currentResults.countedUntil,
            _currentResults.currentForCount,
            _currentResults.currentAgainstCount,
        ) = intermediateResultsStorage().getIntermediateResults(_proposalId);

         
        address[] memory _moderators;
        if (_currentResults.countedUntil == EMPTY_ADDRESS) {
            _moderators = daoListingService().listModerators(
                _operations,
                true
            );
        } else {
            _moderators = daoListingService().listModeratorsFrom(
               _currentResults.countedUntil,
               _operations,
               true
           );
        }

         
        DaoIntermediateStructs.VotingCount memory _voteCount;
        (_voteCount.forCount, _voteCount.againstCount) = daoStorage().readDraftVotingCount(_proposalId, _moderators);

        _currentResults.countedUntil = _moderators[_moderators.length-1];
        _currentResults.currentForCount = _currentResults.currentForCount.add(_voteCount.forCount);
        _currentResults.currentAgainstCount = _currentResults.currentAgainstCount.add(_voteCount.againstCount);

        if (_moderators[_moderators.length-1] == daoStakeStorage().readLastModerator()) {
             
            _passed = processDraftVotingClaim(_proposalId, _currentResults);
            _done = true;

             
            intermediateResultsStorage().resetIntermediateResults(_proposalId);
        } else {
             
            intermediateResultsStorage().setIntermediateResults(
                _proposalId,
                _currentResults.countedUntil,
                _currentResults.currentForCount,
                _currentResults.currentAgainstCount,
                0
            );
        }
    }


    function processDraftVotingClaim(bytes32 _proposalId, DaoStructs.IntermediateResults _currentResults)
        internal
        returns (bool _passed)
    {
        if (
            (_currentResults.currentForCount.add(_currentResults.currentAgainstCount) > daoCalculatorService().minimumDraftQuorum(_proposalId)) &&
            (daoCalculatorService().draftQuotaPass(_currentResults.currentForCount, _currentResults.currentAgainstCount))
        ) {
            daoStorage().setProposalDraftPass(_proposalId, true);

             
             
            uint256 _idealStartTime = daoStorage().readProposalDraftVotingTime(_proposalId).add(getUintConfig(CONFIG_DRAFT_VOTING_PHASE));
            daoStorage().setProposalVotingTime(
                _proposalId,
                0,
                getTimelineForNextVote(0, _idealStartTime)
            );
            _passed = true;
        } else {
            daoStorage().setProposalDraftPass(_proposalId, false);
            processCollateralRefund(_proposalId);
        }

        daoStorage().setDraftVotingClaim(_proposalId, true);
    }

     


     
    function claimProposalVotingResult(bytes32 _proposalId, uint256 _index, uint256 _operations)
        public
        ifNotClaimed(_proposalId, _index)
        ifAfterProposalRevealPhase(_proposalId, _index)
        returns (bool _passed, bool _done)
    {
        require(isMainPhase());

         
         
         
        _done = true;
        _passed = false;  
        uint256 _operationsLeft = _operations;
         
        if (now < startOfMilestone(_proposalId, _index)
                    .add(getUintConfig(CONFIG_VOTE_CLAIMING_DEADLINE)))
        {
            (_operationsLeft, _passed, _done) = countProposalVote(_proposalId, _index, _operations);
             
            if (!_done) return (_passed, false);  
        }

         
         
        _done = false;

        if (_index > 0) {  
            _done = calculateVoterBonus(_proposalId, _index, _operationsLeft, _passed);
            if (!_done) return (_passed, false);  
        } else {
             

            _passed = _passed && isNonDigixProposalsWithinLimit(_proposalId);  
            if (_passed) {
                daoStorage().setProposalCollateralStatus(
                    _proposalId,
                    COLLATERAL_STATUS_LOCKED
                );

            } else {
                processCollateralRefund(_proposalId);
            }
        }

        if (_passed) {
            processSuccessfulVotingClaim(_proposalId, _index);
        }
        daoStorage().setVotingClaim(_proposalId, _index, true);
        daoStorage().setProposalPass(_proposalId, _index, _passed);
        _done = true;
    }


     
    function processSuccessfulVotingClaim(bytes32 _proposalId, uint256 _index)
        internal
    {
         
        intermediateResultsStorage().resetIntermediateResults(_proposalId);

         
        uint256[] memory _milestoneFundings;
        (_milestoneFundings,) = daoStorage().readProposalFunding(_proposalId);
        if (_index == _milestoneFundings.length) {
            processCollateralRefund(_proposalId);
            daoStorage().archiveProposal(_proposalId);
        }

         
        bool _isDigixProposal;
        (,,,,,,,,,_isDigixProposal) = daoStorage().readProposal(_proposalId);
        if (_index == 0 && !_isDigixProposal) {
            daoProposalCounterStorage().addNonDigixProposalCountInQuarter(currentQuarterNumber());
        }

         
        uint256 _funding = daoStorage().readProposalMilestone(_proposalId, _index);
        daoPointsStorage().addQuarterPoint(
            daoStorage().readProposalProposer(_proposalId),
            getUintConfig(CONFIG_QUARTER_POINT_MILESTONE_COMPLETION_PER_10000ETH).mul(_funding).div(10000 ether),
            currentQuarterNumber()
        );
    }


    function getInterResultKeyForBonusCalculation(bytes32 _proposalId) public view returns (bytes32 _key) {
        _key = keccak256(abi.encodePacked(
            _proposalId,
            INTERMEDIATE_BONUS_CALCULATION_IDENTIFIER
        ));
    }


     
    function calculateVoterBonus(bytes32 _proposalId, uint256 _index, uint256 _operations, bool _passed)
        internal
        returns (bool _done)
    {
        if (_operations == 0) return false;
        address _countedUntil;
        (_countedUntil,,,) = intermediateResultsStorage().getIntermediateResults(
            getInterResultKeyForBonusCalculation(_proposalId)
        );

        address[] memory _voterBatch;
        if (_countedUntil == EMPTY_ADDRESS) {
            _voterBatch = daoListingService().listParticipants(
                _operations,
                true
            );
        } else {
            _voterBatch = daoListingService().listParticipantsFrom(
                _countedUntil,
                _operations,
                true
            );
        }
        address _lastVoter = _voterBatch[_voterBatch.length - 1];  

        DaoIntermediateStructs.Users memory _bonusVoters;
        if (_passed) {

             
             
            (_bonusVoters.users, _bonusVoters.usersLength) = daoStorage().readVotingRoundVotes(_proposalId, _index.sub(1), _voterBatch, true);
        } else {
             
             
            (_bonusVoters.users, _bonusVoters.usersLength) = daoStorage().readVotingRoundVotes(_proposalId, _index.sub(1), _voterBatch, false);
        }

        if (_bonusVoters.usersLength > 0) addBonusReputation(_bonusVoters.users, _bonusVoters.usersLength);

        if (_lastVoter == daoStakeStorage().readLastParticipant()) {
             

            intermediateResultsStorage().resetIntermediateResults(
                getInterResultKeyForBonusCalculation(_proposalId)
            );
            _done = true;
        } else {
             
            intermediateResultsStorage().setIntermediateResults(
                getInterResultKeyForBonusCalculation(_proposalId),
                _lastVoter, 0, 0, 0
            );
        }
    }


     
     
     
     
     
    function countProposalVote(bytes32 _proposalId, uint256 _index, uint256 _operations)
        internal
        returns (uint256 _operationsLeft, bool _passed, bool _done)
    {
        senderCanDoProposerOperations();
        require(isFromProposer(_proposalId));

        DaoStructs.IntermediateResults memory _currentResults;
        (
            _currentResults.countedUntil,
            _currentResults.currentForCount,
            _currentResults.currentAgainstCount,
        ) = intermediateResultsStorage().getIntermediateResults(_proposalId);
        address[] memory _voters;
        if (_currentResults.countedUntil == EMPTY_ADDRESS) {  
            _voters = daoListingService().listParticipants(
                _operations,
                true
            );
        } else {
            _voters = daoListingService().listParticipantsFrom(
                _currentResults.countedUntil,
                _operations,
                true
            );

             
             
            if (_voters.length == 0) {
                return (
                    _operations,
                    isVoteCountPassed(_currentResults, _proposalId, _index),
                    true
                );
            }
        }

        address _lastVoter = _voters[_voters.length - 1];

        DaoIntermediateStructs.VotingCount memory _count;
        (_count.forCount, _count.againstCount) = daoStorage().readVotingCount(_proposalId, _index, _voters);

        _currentResults.currentForCount = _currentResults.currentForCount.add(_count.forCount);
        _currentResults.currentAgainstCount = _currentResults.currentAgainstCount.add(_count.againstCount);
        intermediateResultsStorage().setIntermediateResults(
            _proposalId,
            _lastVoter,
            _currentResults.currentForCount,
            _currentResults.currentAgainstCount,
            0
        );

        if (_lastVoter != daoStakeStorage().readLastParticipant()) {
            return (0, false, false);  
        }

         
         
         

        _operationsLeft = _operations.sub(_voters.length);
        _done = true;

        _passed = isVoteCountPassed(_currentResults, _proposalId, _index);
    }


    function isVoteCountPassed(DaoStructs.IntermediateResults _currentResults, bytes32 _proposalId, uint256 _index)
        internal
        view
        returns (bool _passed)
    {
        _passed = (_currentResults.currentForCount.add(_currentResults.currentAgainstCount) > daoCalculatorService().minimumVotingQuorum(_proposalId, _index))
                && (daoCalculatorService().votingQuotaPass(_currentResults.currentForCount, _currentResults.currentAgainstCount));
    }


    function processCollateralRefund(bytes32 _proposalId)
        internal
    {
        daoStorage().setProposalCollateralStatus(_proposalId, COLLATERAL_STATUS_CLAIMED);
        require(daoFundingManager().refundCollateral(daoStorage().readProposalProposer(_proposalId), _proposalId));
    }


     
    function addBonusReputation(address[] _voters, uint256 _n)
        private
    {
        uint256 _qp = getUintConfig(CONFIG_QUARTER_POINT_VOTE);
        uint256 _rate = getUintConfig(CONFIG_BONUS_REPUTATION_NUMERATOR);
        uint256 _base = getUintConfig(CONFIG_BONUS_REPUTATION_DENOMINATOR);

        uint256 _bonus = _qp.mul(_rate).mul(getUintConfig(CONFIG_REPUTATION_PER_EXTRA_QP_NUM))
            .div(
                _base.mul(getUintConfig(CONFIG_REPUTATION_PER_EXTRA_QP_DEN))
            );

        for (uint256 i = 0; i < _n; i++) {
            if (isParticipant(_voters[i])) {  
                daoPointsStorage().increaseReputation(_voters[i], _bonus);
            }
        }
    }
}

 
contract Dao is DaoCommon {

    event NewProposal(bytes32 indexed _proposalId, address _proposer);
    event ModifyProposal(bytes32 indexed _proposalId, bytes32 _newDoc);
    event ChangeProposalFunding(bytes32 indexed _proposalId);
    event FinalizeProposal(bytes32 indexed _proposalId);
    event FinishMilestone(bytes32 indexed _proposalId, uint256 indexed _milestoneIndex);
    event AddProposalDoc(bytes32 indexed _proposalId, bytes32 _newDoc);
    event PRLAction(bytes32 indexed _proposalId, uint256 _actionId, bytes32 _doc);
    event CloseProposal(bytes32 indexed _proposalId);

    constructor(address _resolver) public {
        require(init(CONTRACT_DAO, _resolver));
    }

    function daoFundingManager()
        internal
        view
        returns (DaoFundingManager _contract)
    {
        _contract = DaoFundingManager(get_contract(CONTRACT_DAO_FUNDING_MANAGER));
    }

    function daoRewardsManager()
        internal
        view
        returns (DaoRewardsManager _contract)
    {
        _contract = DaoRewardsManager(get_contract(CONTRACT_DAO_REWARDS_MANAGER));
    }

    function daoVotingClaims()
        internal
        view
        returns (DaoVotingClaims _contract)
    {
        _contract = DaoVotingClaims(get_contract(CONTRACT_DAO_VOTING_CLAIMS));
    }

     
    function setNewDaoContracts(
        address _newDaoContract,
        address _newDaoFundingManager,
        address _newDaoRewardsManager
    )
        public
        if_root()
    {
        require(daoUpgradeStorage().isReplacedByNewDao() == false);
        daoUpgradeStorage().setNewContractAddresses(
            _newDaoContract,
            _newDaoFundingManager,
            _newDaoRewardsManager
        );
    }

     
    function migrateToNewDao(
        address _newDaoContract,
        address _newDaoFundingManager,
        address _newDaoRewardsManager
    )
        public
        if_root()
        ifGlobalRewardsSet(currentQuarterNumber())
    {
        require(isLockingPhase());
        require(daoUpgradeStorage().isReplacedByNewDao() == false);
        require(
          (daoUpgradeStorage().newDaoContract() == _newDaoContract) &&
          (daoUpgradeStorage().newDaoFundingManager() == _newDaoFundingManager) &&
          (daoUpgradeStorage().newDaoRewardsManager() == _newDaoRewardsManager)
        );
        daoUpgradeStorage().updateForDaoMigration();
        daoFundingManager().moveFundsToNewDao(_newDaoFundingManager);
        daoRewardsManager().moveDGXsToNewDao(_newDaoRewardsManager);
    }

     
    function setStartOfFirstQuarter(uint256 _start) public if_founder() {
        require(daoUpgradeStorage().startOfFirstQuarter() == 0);
        require(_start > 0);
        daoUpgradeStorage().setStartOfFirstQuarter(_start);
    }

     
    function submitPreproposal(
        bytes32 _docIpfsHash,
        uint256[] _milestonesFundings,
        uint256 _finalReward
    )
        external
        payable
        ifFundingPossible(_milestonesFundings, _finalReward)
    {
        senderCanDoProposerOperations();
        bool _isFounder = is_founder();

        require(msg.value == getUintConfig(CONFIG_PREPROPOSAL_COLLATERAL));
        require(address(daoFundingManager()).call.gas(25000).value(msg.value)());

        checkNonDigixFundings(_milestonesFundings, _finalReward);

        daoStorage().addProposal(_docIpfsHash, msg.sender, _milestonesFundings, _finalReward, _isFounder);
        daoStorage().setProposalCollateralStatus(_docIpfsHash, COLLATERAL_STATUS_UNLOCKED);
        daoStorage().setProposalCollateralAmount(_docIpfsHash, msg.value);

        emit NewProposal(_docIpfsHash, msg.sender);
    }

     
    function modifyProposal(
        bytes32 _proposalId,
        bytes32 _docIpfsHash,
        uint256[] _milestonesFundings,
        uint256 _finalReward
    )
        external
    {
        senderCanDoProposerOperations();
        require(isFromProposer(_proposalId));

        require(isEditable(_proposalId));
        bytes32 _currentState;
        (,,,_currentState,,,,,,) = daoStorage().readProposal(_proposalId);
        require(_currentState == PROPOSAL_STATE_PREPROPOSAL ||
          _currentState == PROPOSAL_STATE_DRAFT);

        checkNonDigixFundings(_milestonesFundings, _finalReward);

        daoStorage().editProposal(_proposalId, _docIpfsHash, _milestonesFundings, _finalReward);

        emit ModifyProposal(_proposalId, _docIpfsHash);
    }

     
    function changeFundings(
        bytes32 _proposalId,
        uint256[] _milestonesFundings,
        uint256 _finalReward,
        uint256 _currentMilestone
    )
        external
    {
        senderCanDoProposerOperations();
        require(isFromProposer(_proposalId));

        checkNonDigixFundings(_milestonesFundings, _finalReward);

        uint256[] memory _currentFundings;
        (_currentFundings,) = daoStorage().readProposalFunding(_proposalId);

         
         
         
        require(_currentMilestone < _currentFundings.length);

        uint256 _startOfCurrentMilestone = startOfMilestone(_proposalId, _currentMilestone);

         
        require(now > _startOfCurrentMilestone);
        require(daoStorage().readProposalVotingTime(_proposalId, _currentMilestone.add(1)) == 0);

         
         
        for (uint256 i=0;i<=_currentMilestone;i++) {
            require(_milestonesFundings[i] == _currentFundings[i]);
        }

        daoStorage().changeFundings(_proposalId, _milestonesFundings, _finalReward);

        emit ChangeProposalFunding(_proposalId);
    }

     
    function finalizeProposal(bytes32 _proposalId)
        public
    {
        senderCanDoProposerOperations();
        require(isFromProposer(_proposalId));
        require(isEditable(_proposalId));
        checkNonDigixProposalLimit(_proposalId);

         
         
        require(getTimeLeftInQuarter(now) > getUintConfig(CONFIG_DRAFT_VOTING_PHASE).add(getUintConfig(CONFIG_VOTE_CLAIMING_DEADLINE)));
        address _endorser;
        (,,_endorser,,,,,,,) = daoStorage().readProposal(_proposalId);
        require(_endorser != EMPTY_ADDRESS);
        daoStorage().finalizeProposal(_proposalId);
        daoStorage().setProposalDraftVotingTime(_proposalId, now);

        emit FinalizeProposal(_proposalId);
    }

     
    function finishMilestone(bytes32 _proposalId, uint256 _milestoneIndex)
        public
    {
        senderCanDoProposerOperations();
        require(isFromProposer(_proposalId));

        uint256[] memory _currentFundings;
        (_currentFundings,) = daoStorage().readProposalFunding(_proposalId);

         
         
         
        require(_milestoneIndex < _currentFundings.length);

         
        uint256 _startOfCurrentMilestone = startOfMilestone(_proposalId, _milestoneIndex);
        require(now > _startOfCurrentMilestone);
        require(daoStorage().readProposalVotingTime(_proposalId, _milestoneIndex.add(1)) == 0);

        daoStorage().setProposalVotingTime(
            _proposalId,
            _milestoneIndex.add(1),
            getTimelineForNextVote(_milestoneIndex.add(1), now)
        );  

        emit FinishMilestone(_proposalId, _milestoneIndex);
    }

     
    function addProposalDoc(bytes32 _proposalId, bytes32 _newDoc)
        public
    {
        senderCanDoProposerOperations();
        require(isFromProposer(_proposalId));
        bytes32 _finalVersion;
        (,,,,,,,_finalVersion,,) = daoStorage().readProposal(_proposalId);
        require(_finalVersion != EMPTY_BYTES);
        daoStorage().addProposalDoc(_proposalId, _newDoc);

        emit AddProposalDoc(_proposalId, _newDoc);
    }

     
    function endorseProposal(bytes32 _proposalId)
        public
        isProposalState(_proposalId, PROPOSAL_STATE_PREPROPOSAL)
    {
        require(isMainPhase());
        require(isModerator(msg.sender));
        daoStorage().updateProposalEndorse(_proposalId, msg.sender);
    }

     
    function updatePRL(
        bytes32 _proposalId,
        uint256 _action,
        bytes32 _doc
    )
        public
        if_prl()
    {
        require(_action == PRL_ACTION_STOP || _action == PRL_ACTION_PAUSE || _action == PRL_ACTION_UNPAUSE);
        daoStorage().updateProposalPRL(_proposalId, _action, _doc, now);

        emit PRLAction(_proposalId, _action, _doc);
    }

     
    function closeProposal(bytes32 _proposalId)
        public
    {
        senderCanDoProposerOperations();
        require(isFromProposer(_proposalId));
        bytes32 _finalVersion;
        bytes32 _status;
        (,,,_status,,,,_finalVersion,,) = daoStorage().readProposal(_proposalId);
        require(_finalVersion == EMPTY_BYTES);
        require(_status != PROPOSAL_STATE_CLOSED);
        require(daoStorage().readProposalCollateralStatus(_proposalId) == COLLATERAL_STATUS_UNLOCKED);

        daoStorage().closeProposal(_proposalId);
        daoStorage().setProposalCollateralStatus(_proposalId, COLLATERAL_STATUS_CLAIMED);
        emit CloseProposal(_proposalId);
        require(daoFundingManager().refundCollateral(msg.sender, _proposalId));
    }

     
    function founderCloseProposals(bytes32[] _proposalIds)
        external
        if_founder()
    {
        uint256 _length = _proposalIds.length;
        uint256 _timeCreated;
        bytes32 _finalVersion;
        bytes32 _currentState;
        for (uint256 _i = 0; _i < _length; _i++) {
            (,,,_currentState,_timeCreated,,,_finalVersion,,) = daoStorage().readProposal(_proposalIds[_i]);
            require(_finalVersion == EMPTY_BYTES);
            require(
                (_currentState == PROPOSAL_STATE_PREPROPOSAL) ||
                (_currentState == PROPOSAL_STATE_DRAFT)
            );
            require(now > _timeCreated.add(getUintConfig(CONFIG_PROPOSAL_DEAD_DURATION)));
            emit CloseProposal(_proposalIds[_i]);
            daoStorage().closeProposal(_proposalIds[_i]);
        }
    }
}

 
contract DaoFundingManager is DaoCommon {

    address public FUNDING_SOURCE;

    event ClaimFunding(bytes32 indexed _proposalId, uint256 indexed _votingRound, uint256 _funding);

    constructor(address _resolver, address _fundingSource) public {
        require(init(CONTRACT_DAO_FUNDING_MANAGER, _resolver));
        FUNDING_SOURCE = _fundingSource;
    }

    function dao()
        internal
        view
        returns (Dao _contract)
    {
        _contract = Dao(get_contract(CONTRACT_DAO));
    }

     
    function isProposalPaused(bytes32 _proposalId)
        public
        view
        returns (bool _isPausedOrStopped)
    {
        (,,,,,,,,_isPausedOrStopped,) = daoStorage().readProposal(_proposalId);
    }

     
    function setFundingSource(address _fundingSource)
        public
        if_root()
    {
        FUNDING_SOURCE = _fundingSource;
    }

     
    function claimFunding(bytes32 _proposalId, uint256 _index)
        public
    {
        require(identity_storage().is_kyc_approved(msg.sender));
        require(isFromProposer(_proposalId));

         
        require(!isProposalPaused(_proposalId));

        require(!daoStorage().readIfMilestoneFunded(_proposalId, _index));

        require(daoStorage().readProposalVotingResult(_proposalId, _index));
        require(daoStorage().isClaimed(_proposalId, _index));

        uint256 _funding = daoStorage().readProposalMilestone(_proposalId, _index);

        daoStorage().setMilestoneFunded(_proposalId, _index);

        msg.sender.transfer(_funding);

        emit ClaimFunding(_proposalId, _index, _funding);
    }

     
    function refundCollateral(address _receiver, bytes32 _proposalId)
        public
        returns (bool _success)
    {
        require(sender_is_from([CONTRACT_DAO, CONTRACT_DAO_VOTING_CLAIMS, EMPTY_BYTES]));
        refundCollateralInternal(_receiver, _proposalId);
        _success = true;
    }

    function refundCollateralInternal(address _receiver, bytes32 _proposalId)
        internal
    {
        uint256 _collateralAmount = daoStorage().readProposalCollateralAmount(_proposalId);
        _receiver.transfer(_collateralAmount);
    }

     
    function moveFundsToNewDao(address _destinationForDaoFunds)
        public
    {
        require(sender_is(CONTRACT_DAO));
        uint256 _remainingBalance = address(this).balance;
        _destinationForDaoFunds.transfer(_remainingBalance);
    }

     
    function () external payable {
        require(
            (msg.sender == FUNDING_SOURCE) ||
            (msg.sender == get_contract(CONTRACT_DAO))
        );
    }
}