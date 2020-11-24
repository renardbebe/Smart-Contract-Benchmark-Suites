 

pragma solidity ^0.4.13;

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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

     
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, this, value));
        emit ReceivedTokens(from, value, token, extraData);
    }

     
    function () payable public {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

contract ProxyRegistry is Ownable {

     
    address public delegateProxyImplementation;

     
    mapping(address => OwnableDelegateProxy) public proxies;

     
    mapping(address => uint) public pending;

     
    mapping(address => bool) public contracts;

     
    uint public DELAY_PERIOD = 2 weeks;

     
    function startGrantAuthentication (address addr)
        public
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] == 0);
        pending[addr] = now;
    }

     
    function endGrantAuthentication (address addr)
        public
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] != 0 && ((pending[addr] + DELAY_PERIOD) < now));
        pending[addr] = 0;
        contracts[addr] = true;
    }

         
    function revokeAuthentication (address addr)
        public
        onlyOwner
    {
        contracts[addr] = false;
    }

     
    function registerProxy()
        public
        returns (OwnableDelegateProxy proxy)
    {
        require(proxies[msg.sender] == address(0));
        proxy = new OwnableDelegateProxy(msg.sender, delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", msg.sender, address(this)));
        proxies[msg.sender] = proxy;
        return proxy;
    }

}

contract WyvernProxyRegistry is ProxyRegistry {

    string public constant name = "Project Wyvern Proxy Registry";

     
    bool public initialAddressSet = false;

    constructor ()
        public
    {
        delegateProxyImplementation = new AuthenticatedProxy();
    }

     
    function grantInitialAuthentication (address authAddress)
        onlyOwner
        public
    {
        require(!initialAddressSet);
        initialAddressSet = true;
        contracts[authAddress] = true;
    }

}

contract OwnedUpgradeabilityStorage {

   
  address internal _implementation;

   
  address private _upgradeabilityOwner;

   
  function upgradeabilityOwner() public view returns (address) {
    return _upgradeabilityOwner;
  }

   
  function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
    _upgradeabilityOwner = newUpgradeabilityOwner;
  }

   
  function implementation() public view returns (address) {
    return _implementation;
  }

   
  function proxyType() public pure returns (uint256 proxyTypeId) {
    return 2;
  }
}

contract AuthenticatedProxy is TokenRecipient, OwnedUpgradeabilityStorage {

     
    bool initialized = false;

     
    address public user;

     
    ProxyRegistry public registry;

     
    bool public revoked;

     
    enum HowToCall { Call, DelegateCall }

     
    event Revoked(bool revoked);

     
    function initialize (address addrUser, ProxyRegistry addrRegistry)
        public
    {
        require(!initialized);
        initialized = true;
        user = addrUser;
        registry = addrRegistry;
    }

     
    function setRevoke(bool revoke)
        public
    {
        require(msg.sender == user);
        revoked = revoke;
        emit Revoked(revoke);
    }

     
    function proxy(address dest, HowToCall howToCall, bytes calldata)
        public
        returns (bool result)
    {
        require(msg.sender == user || (!revoked && registry.contracts(msg.sender)));
        if (howToCall == HowToCall.Call) {
            result = dest.call(calldata);
        } else if (howToCall == HowToCall.DelegateCall) {
            result = dest.delegatecall(calldata);
        }
        return result;
    }

     
    function proxyAssert(address dest, HowToCall howToCall, bytes calldata)
        public
    {
        require(proxy(dest, howToCall, calldata));
    }

}

contract Proxy {

   
  function implementation() public view returns (address);

   
  function proxyType() public pure returns (uint256 proxyTypeId);

   
  function () payable public {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}

contract OwnedUpgradeabilityProxy is Proxy, OwnedUpgradeabilityStorage {
   
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

   
  event Upgraded(address indexed implementation);

   
  function _upgradeTo(address implementation) internal {
    require(_implementation != implementation);
    _implementation = implementation;
    emit Upgraded(implementation);
  }

   
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

   
  function proxyOwner() public view returns (address) {
    return upgradeabilityOwner();
  }

   
  function transferProxyOwnership(address newOwner) public onlyProxyOwner {
    require(newOwner != address(0));
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradeabilityOwner(newOwner);
  }

   
  function upgradeTo(address implementation) public onlyProxyOwner {
    _upgradeTo(implementation);
  }

   
  function upgradeToAndCall(address implementation, bytes data) payable public onlyProxyOwner {
    upgradeTo(implementation);
    require(address(this).delegatecall(data));
  }
}

contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {

    constructor(address owner, address initialImplementation, bytes calldata)
        public
    {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        require(initialImplementation.delegatecall(calldata));
    }

}