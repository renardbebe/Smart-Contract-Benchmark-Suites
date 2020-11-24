 

pragma solidity ^0.4.13;

contract Proxy {
   
  function () payable external {
    _fallback();
  }

   
  function _implementation() internal view returns (address);

   
  function _delegate(address implementation) internal {
    assembly {
       
       
       
      calldatacopy(0, 0, calldatasize)

       
       
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

       
      returndatacopy(0, 0, returndatasize)

      switch result
       
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

   
  function _willFallback() internal {
  }

   
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

contract UpgradeabilityProxy is Proxy {
   
  event Upgraded(address indexed implementation);

   
  bytes32 private constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;

   
  constructor(address _implementation, bytes _data) public payable {
    assert(IMPLEMENTATION_SLOT == keccak256("org.zeppelinos.proxy.implementation"));
    _setImplementation(_implementation);
    if(_data.length > 0) {
      require(_implementation.delegatecall(_data));
    }
  }

   
  function _implementation() internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

   
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

   
  function _setImplementation(address newImplementation) private {
    require(Address.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

contract AdminUpgradeabilityProxy is UpgradeabilityProxy {
   
  event AdminChanged(address previousAdmin, address newAdmin);

   
  bytes32 private constant ADMIN_SLOT = 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b;

   
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

   
  constructor(address _implementation, bytes _data) UpgradeabilityProxy(_implementation, _data) public payable {
    assert(ADMIN_SLOT == keccak256("org.zeppelinos.proxy.admin"));

    _setAdmin(msg.sender);
  }

   
  function admin() external view ifAdmin returns (address) {
    return _admin();
  }

   
  function implementation() external view ifAdmin returns (address) {
    return _implementation();
  }

   
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

   
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

   
  function upgradeToAndCall(address newImplementation, bytes data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    require(newImplementation.delegatecall(data));
  }

   
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

   
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

   
  function _willFallback() internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    super._willFallback();
  }
}

contract InvestProxy is AdminUpgradeabilityProxy {
    event InvestURLChanged(string newURL);
    event TradeProfileURLChanged(string newURL);
    
     
    function implementation() external view returns (address) {
        return _implementation();
    }

     
    bytes32 private constant INVEST_URL_SLOT = 0x0a0b238efce32441e32278a575c1da4e28f812259fba404833c15c29a6e13d46;

     
    bytes32 private constant TRADEPROFILE_URL_SLOT = 0x49c26932bb52cddb57467acf01e76b5c55163bbd941e1e3b8cbe216ad40359ae;
    
     
    function bincentive_invest_contract_url() external view returns (string) {
        bytes32 slot = INVEST_URL_SLOT;
        assembly {
            let slot_count := sload(slot)
            
            for { let i := 0} lt(i, slot_count) { i := add(i, 1) } { mstore(add(0xf0, mul(i, 32)), sload(add(add(slot, 1), i))) }
            
            return(0xf0, mul(slot_count, 32))
        }
    }

    function setInvestURL(string _newURL) external ifAdmin {
        bytes32 slot = INVEST_URL_SLOT;
        assembly {
            let slot_count := div(sub(calldatasize, 4), 32)
            sstore(slot, slot_count)
            
            calldatacopy(0xf0, 4, sub(calldatasize, 4))
            for { let i := 0 } lt(i, slot_count) { i := add(i, 1) } { sstore(add(add(slot, 1), i), mload(add(0xf0, mul(i, 32)))) }
        }
        emit InvestURLChanged(_newURL);
    }

     
    function trade_profile_contract_url() external returns (string) {
        bytes32 slot = TRADEPROFILE_URL_SLOT;
        assembly {
            let slot_count := sload(slot)
            
            for { let i := 0} lt(i, slot_count) { i := add(i, 1) } { mstore(add(0xf0, mul(i, 32)), sload(add(add(slot, 1), i))) }
            
            return(0xf0, mul(slot_count, 32))
        }
    }

    function setTradeProfileURL(string _newURL) external ifAdmin {
        bytes32 slot = TRADEPROFILE_URL_SLOT;
        assembly {
            let slot_count := div(sub(calldatasize, 4), 32)
            sstore(slot, slot_count)
            
            calldatacopy(0xf0, 4, sub(calldatasize, 4))
            for { let i := 0 } lt(i, slot_count) { i := add(i, 1) } { sstore(add(add(slot, 1), i), mload(add(0xf0, mul(i, 32)))) }
        }
        emit TradeProfileURLChanged(_newURL);
    }


    constructor(address _implementation, bytes _data) AdminUpgradeabilityProxy(_implementation, _data) public payable {
        assert(INVEST_URL_SLOT == keccak256("bincentive.url.invest"));
        assert(TRADEPROFILE_URL_SLOT == keccak256("bincentive.url.tradeprofile"));
    }
}

library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}