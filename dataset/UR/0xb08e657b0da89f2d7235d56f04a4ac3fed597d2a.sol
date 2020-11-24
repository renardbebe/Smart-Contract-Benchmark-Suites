 

pragma solidity ^0.4.24;
 
 
 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
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

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

contract Whitelist is Ownable, RBAC {
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyWhitelisted() {
    checkRole(msg.sender, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address addr)
    onlyOwner
    public
  {
    addRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressAdded(addr);
  }

   
  function whitelist(address addr)
    public
    view
    returns (bool)
  {
    return hasRole(addr, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      addAddressToWhitelist(addrs[i]);
    }
  }

   
  function removeAddressFromWhitelist(address addr)
    onlyOwner
    public
  {
    removeRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressRemoved(addr);
  }

   
  function removeAddressesFromWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      removeAddressFromWhitelist(addrs[i]);
    }
  }

}

contract StartersProxy is Whitelist{
    using SafeMath for uint256;

    uint256 public TX_PER_SIGNER_LIMIT = 5;           
    uint256 public META_BET = 1 finney;               
    uint256 public DEBT_INCREASING_FACTOR = 3;        

    struct Record {
        uint256 nonce;
        uint256 debt;
    }
    mapping(address => Record) signersBacklog;
    event Received (address indexed sender, uint value);
    event Forwarded (address signer, address destination, uint value, bytes data);

    function() public payable {
        emit Received(msg.sender, msg.value);
    }

    constructor(address[] _senders) public {
        addAddressToWhitelist(msg.sender);
        addAddressesToWhitelist(_senders);
    }

    function forwardPlay(address signer, address destination, bytes data, bytes32 hash, bytes signature) onlyWhitelisted public {
        require(signersBacklog[signer].nonce < TX_PER_SIGNER_LIMIT, "Signer has reached the tx limit");

        signersBacklog[signer].nonce++;
         
         
        uint256 debtIncrease = META_BET.mul(DEBT_INCREASING_FACTOR);
        signersBacklog[signer].debt = signersBacklog[signer].debt.add(debtIncrease);

        forward(signer, destination, META_BET, data, hash, signature);
    }

    function forwardWin(address signer, address destination, bytes data, bytes32 hash, bytes signature) onlyWhitelisted public {
        require(signersBacklog[signer].nonce > 0, 'Hm, no meta plays for this signer');

        forward(signer, destination, 0, data, hash, signature);
    }

    function forward(address signer, address destination,  uint256 value, bytes data, bytes32 hash, bytes signature) internal {
        require(recoverSigner(hash, signature) == signer);

         
        require(executeCall(destination, value, data));
        emit Forwarded(signer, destination, value, data);
    }

     
     
    function recoverSigner(bytes32 _hash, bytes _signature) onlyWhitelisted public view returns (address){
        bytes32 r;
        bytes32 s;
        uint8 v;
         
        require (_signature.length == 65);
         
         
         
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
         
        if (v < 27) {
            v += 27;
        }
         
        require(v == 27 || v == 28);
        return ecrecover(keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            ), v, r, s);
    }

     
     
    function executeCall(address to, uint256 value, bytes data) internal returns (bool success) {
        assembly {
            success := call(gas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function payDebt(address signer) public payable{
        require(signersBacklog[signer].nonce > 0, "Provided address has no debt");
        require(signersBacklog[signer].debt >= msg.value, "Address's debt is less than payed amount");

        signersBacklog[signer].debt = signersBacklog[signer].debt.sub(msg.value);
    }

    function debt(address signer) public view returns (uint256) {
        return signersBacklog[signer].debt;
    }

    function gamesLeft(address signer) public view returns (uint256) {
        return TX_PER_SIGNER_LIMIT.sub(signersBacklog[signer].nonce);
    }

    function withdraw(uint256 amountWei) onlyWhitelisted public {
        msg.sender.transfer(amountWei);
    }

    function setMetaBet(uint256 _newMetaBet) onlyWhitelisted public {
        META_BET = _newMetaBet;
    }

    function setTxLimit(uint256 _newTxLimit) onlyWhitelisted public {
        TX_PER_SIGNER_LIMIT = _newTxLimit;
    }

    function setDebtIncreasingFactor(uint256 _newFactor) onlyWhitelisted public {
        DEBT_INCREASING_FACTOR = _newFactor;
    }


}