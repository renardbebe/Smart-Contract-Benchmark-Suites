 

 

pragma solidity 0.5.2;


 
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
pragma solidity ^0.5.0;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 


pragma solidity 0.5.2;

 
contract Proxy {
   
  function () external payable {
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

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 
contract UpgradeabilityProxy is Proxy {
   
  event Upgraded(address indexed implementation);

   
  bytes32 private constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;

   
  constructor(address _implementation, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == keccak256("org.zeppelinos.proxy.implementation"));
    _setImplementation(_implementation);
    if (_data.length > 0) {
      bool rv;
      (rv,) = _implementation.delegatecall(_data);
      require(rv);
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

   
  constructor(address _implementation, bytes memory _data) UpgradeabilityProxy(_implementation, _data) public payable {
    assert(ADMIN_SLOT == keccak256("org.zeppelinos.proxy.admin"));

    _setAdmin(msg.sender);
  }

   
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

   
  function implementation() external ifAdmin returns (address) {
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

   
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
    _upgradeTo(newImplementation);
    bool rv;
    (rv,) = newImplementation.delegatecall(data);
    require(rv);
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

 
contract AdminableProxy is AdminUpgradeabilityProxy {

   
  constructor(address _implementation, bytes memory _data) 
  AdminUpgradeabilityProxy(_implementation, _data) public payable {
  }

   
  function applyProposal(bytes calldata data) external ifAdmin returns (bool) {
    bool rv;
    (rv, ) = _implementation().delegatecall(data);
    return rv;
  }

}

contract MinGov is Ownable {
  
  uint256 public proposalTime;
  uint256 public first;
  uint256 public size;
  
  struct Proposal {
    address subject;
    uint32 created;
    bool canceled;
    bytes msgData;
  }
  
  mapping(uint256 => Proposal) public proposals;
  
  event NewProposal(uint256 indexed proposalId, address indexed subject, bytes msgData);
  event Execution(uint256 indexed proposalId, address indexed subject, bytes msgData);
  
  constructor(uint256 _proposalTime) public {
    proposalTime = _proposalTime;
    first = 1;
    size = 0;
  }

  function propose(address _subject, bytes memory _msgData) public onlyOwner {
    require(size < 5);
    proposals[first + size] = Proposal(
      _subject,
      uint32(now),
      false,
      _msgData
    );
    emit NewProposal(first + size, _subject, _msgData);
    size++;
  }
  
  function cancel(uint256 _proposalId) public onlyOwner() {
    Proposal storage prop = proposals[_proposalId];
    require(prop.created > 0);
    require(prop.canceled == false);
    prop.canceled = true;
  }

  function withdrawTax(address _token) public onlyOwner {
    IERC20 token = IERC20(_token);
    token.transfer(owner(), token.balanceOf(address(this)));
  }

  function finalize() public {
    for (uint256 i = first; i < first + size; i++) {
      Proposal memory prop = proposals[i];
      if (prop.created + proposalTime <= now) {
        if (!prop.canceled) {
          bool rv;
          bytes4 sig = getSig(prop.msgData);
           
           
            
          if (sig == 0x8f283970||sig == 0x3659cfe6||sig == 0x983b2d56) {
             
            (rv, ) = prop.subject.call(prop.msgData);
          } else {
             
            rv = AdminableProxy(address(uint160(prop.subject))).applyProposal(prop.msgData);
          }
          if (rv) {
            emit Execution(i, prop.subject, prop.msgData);
          }
        }
        delete proposals[i];
        first++;
        size--;
      }
    }
  }

   
  function setSlot(uint256 _slotId, address, bytes32) public onlyOwner {
     
    address payable subject = address(uint160(_slotId >> 96));
     
    bytes memory msgData = new bytes(100);
    assembly {
      calldatacopy(add(msgData, 32), 0, 4)
      calldatacopy(add(msgData, 56), 24, 76)
    }
     
    require(AdminableProxy(subject).applyProposal(msgData), "setSlot call failed");
  }

  function getSig(bytes memory _msgData) internal pure returns (bytes4) {
    return bytes4(_msgData[3]) >> 24 | bytes4(_msgData[2]) >> 16 | bytes4(_msgData[1]) >> 8 | bytes4(_msgData[0]);
  }

}