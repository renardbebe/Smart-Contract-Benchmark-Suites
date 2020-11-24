 

pragma solidity ^0.4.24;

interface itoken {
    function freezeAccount(address _target, bool _freeze) external;
    function freezeAccountPartialy(address _target, uint256 _value) external;
    function balanceOf(address _owner) external view returns (uint256 balance);
     
     
    function allowance(address _owner, address _spender) external view returns (uint256);
    function initialCongress(address _congress) external;
    function mint(address _to, uint256 _amount) external returns (bool);
    function finishMinting() external returns (bool);
    function pause() external;
    function unpause() external;
}

library StringUtils {
   
   
   
  function compare(string _a, string _b) public pure returns (int) {
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);
    uint minLength = a.length;
    if (b.length < minLength) minLength = b.length;
     
    for (uint i = 0; i < minLength; i ++)
      if (a[i] < b[i])
        return -1;
      else if (a[i] > b[i])
        return 1;
    if (a.length < b.length)
      return -1;
    else if (a.length > b.length)
      return 1;
    else
      return 0;
  }
   
  function equal(string _a, string _b) public pure returns (bool) {
    return compare(_a, _b) == 0;
  }
   
  function indexOf(string _haystack, string _needle) public pure returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length))
      return -1;
    else if(h.length > (2**128 -1))  
      return -1;
    else {
      uint subindex = 0;
      for (uint i = 0; i < h.length; i ++) {
        if (h[i] == n[0]) {  
          subindex = 1;
          while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) { 
                subindex++;
          }
          if(subindex == n.length)
                return int(i);
        }
      }
      return -1;
    }
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

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract DelayedClaimable is Claimable {

  uint256 public end;
  uint256 public start;

   
  function setLimits(uint256 _start, uint256 _end) onlyOwner public {
    require(_start <= _end);
    end = _end;
    start = _start;
  }

   
  function claimOwnership() onlyPendingOwner public {
    require((block.number <= end) && (block.number >= start));
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
    end = 0;
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

contract MultiOwners is DelayedClaimable, RBAC {
  using SafeMath for uint256;
  using StringUtils for string;

  mapping (string => uint256) private authorizations;
  mapping (address => string) private ownerOfSides;
 
  mapping (string => uint256) private sideExist;
  mapping (string => mapping (string => address[])) private sideVoters;
  address[] public owners;
  string[] private authTypes;
 
  uint256 public multiOwnerSides;
  uint256 ownerSidesLimit = 5;
 
  bool initAdd = true;

  event OwnerAdded(address addr, string side);
  event OwnerRemoved(address addr);
  event InitialFinished();

  string public constant ROLE_MULTIOWNER = "multiOwner";
  string public constant AUTH_ADDOWNER = "addOwner";
  string public constant AUTH_REMOVEOWNER = "removeOwner";
 

   
  modifier onlyMultiOwners() {
    checkRole(msg.sender, ROLE_MULTIOWNER);
    _;
  }

   
  modifier canInitial() {
    require(initAdd);
    _;
  }

   
  function authorize(string _authType) onlyMultiOwners public {
    string memory side = ownerOfSides[msg.sender];
    address[] storage voters = sideVoters[side][_authType];

    if (voters.length == 0) {
       
      authorizations[_authType] = authorizations[_authType].add(1);
     
    }

     
    uint j = 0;
    for (; j < voters.length; j = j.add(1)) {
      if (voters[j] == msg.sender) {
        break;
      }
    }

    if (j >= voters.length) {
      voters.push(msg.sender);
    }

     
    uint i = 0;
    for (; i < authTypes.length; i = i.add(1)) {
      if (authTypes[i].equal(_authType)) {
        break;
      }
    }

    if (i >= authTypes.length) {
      authTypes.push(_authType);
    }
  }

   
  function deAuthorize(string _authType) onlyMultiOwners public {
    string memory side = ownerOfSides[msg.sender];
    address[] storage voters = sideVoters[side][_authType];

    for (uint j = 0; j < voters.length; j = j.add(1)) {
      if (voters[j] == msg.sender) {
        delete voters[j];
        break;
      }
    }

     
    if (j < voters.length) {
      for (uint jj = j; jj < voters.length.sub(1); jj = jj.add(1)) {
        voters[jj] = voters[jj.add(1)];
      }

      delete voters[voters.length.sub(1)];
      voters.length = voters.length.sub(1);

       
      if (voters.length == 0) {
        authorizations[_authType] = authorizations[_authType].sub(1);
       
      }

       
       
      if (authorizations[_authType] == 0) {
        for (uint i = 0; i < authTypes.length; i = i.add(1)) {
          if (authTypes[i].equal(_authType)) {
            delete authTypes[i];
            break;
          }
        }
        for (uint ii = i; ii < authTypes.length.sub(1); ii = ii.add(1)) {
          authTypes[ii] = authTypes[ii.add(1)];
        }

        delete authTypes[authTypes.length.sub(1)];
        authTypes.length = authTypes.length.sub(1);
      }
    }
  }

   
  function hasAuth(string _authType) public view returns (bool) {
    require(multiOwnerSides > 1);  

     
    return (authorizations[_authType] == multiOwnerSides);
  }

   
  function clearAuth(string _authType) internal {
    authorizations[_authType] = 0;  
    for (uint i = 0; i < owners.length; i = i.add(1)) {
      string memory side = ownerOfSides[owners[i]];
      address[] storage voters = sideVoters[side][_authType];
      for (uint j = 0; j < voters.length; j = j.add(1)) {
        delete voters[j];  
      }
      voters.length = 0;
    }

     
    for (uint k = 0; k < authTypes.length; k = k.add(1)) {
      if (authTypes[k].equal(_authType)) {
        delete authTypes[k];
        break;
      }
    }
    for (uint kk = k; kk < authTypes.length.sub(1); kk = kk.add(1)) {
      authTypes[kk] = authTypes[kk.add(1)];
    }

    delete authTypes[authTypes.length.sub(1)];
    authTypes.length = authTypes.length.sub(1);
  }

   
  function addAddress(address _addr, string _side) internal {
    require(multiOwnerSides < ownerSidesLimit);
    require(_addr != address(0));
    require(ownerOfSides[_addr].equal(""));  

     
     
     
     
     
     

     
    owners.push(_addr);  

    addRole(_addr, ROLE_MULTIOWNER);
    ownerOfSides[_addr] = _side;
     

    if (sideExist[_side] == 0) {
      multiOwnerSides = multiOwnerSides.add(1);
    }

    sideExist[_side] = sideExist[_side].add(1);
  }

   
  function initAddressAsMultiOwner(address _addr, string _side)
    onlyOwner
    canInitial
    public
  {
     
    addAddress(_addr, _side);

     
    emit OwnerAdded(_addr, _side);
  }

   
  function finishInitOwners() onlyOwner canInitial public {
    initAdd = false;
    emit InitialFinished();
  }

   
  function addAddressAsMultiOwner(address _addr, string _side)
    onlyMultiOwners
    public
  {
    require(hasAuth(AUTH_ADDOWNER));

    addAddress(_addr, _side);

    clearAuth(AUTH_ADDOWNER);
    emit OwnerAdded(_addr, _side);
  }

   
  function isMultiOwner(address _addr)
    public
    view
    returns (bool)
  {
    return hasRole(_addr, ROLE_MULTIOWNER);
  }

   
  function removeAddressFromOwners(address _addr)
    onlyMultiOwners
    public
  {
    require(hasAuth(AUTH_REMOVEOWNER));

    removeRole(_addr, ROLE_MULTIOWNER);

     
    uint j = 0;
    for (; j < owners.length; j = j.add(1)) {
      if (owners[j] == _addr) {
        delete owners[j];
        break;
      }
    }
    if (j < owners.length) {
      for (uint jj = j; jj < owners.length.sub(1); jj = jj.add(1)) {
        owners[jj] = owners[jj.add(1)];
      }

      delete owners[owners.length.sub(1)];
      owners.length = owners.length.sub(1);
    }

    string memory side = ownerOfSides[_addr];
     
    sideExist[side] = sideExist[side].sub(1);
    if (sideExist[side] == 0) {
      require(multiOwnerSides > 2);  
      multiOwnerSides = multiOwnerSides.sub(1);  
    }

     
    for (uint i = 0; i < authTypes.length; ) {
      address[] storage voters = sideVoters[side][authTypes[i]];
      for (uint m = 0; m < voters.length; m = m.add(1)) {
        if (voters[m] == _addr) {
          delete voters[m];
          break;
        }
      }
      if (m < voters.length) {
        for (uint n = m; n < voters.length.sub(1); n = n.add(1)) {
          voters[n] = voters[n.add(1)];
        }

        delete voters[voters.length.sub(1)];
        voters.length = voters.length.sub(1);

         
        if (voters.length == 0) {
          authorizations[authTypes[i]] = authorizations[authTypes[i]].sub(1);
        }

         
        if (authorizations[authTypes[i]] == 0) {
          delete authTypes[i];

          for (uint kk = i; kk < authTypes.length.sub(1); kk = kk.add(1)) {
            authTypes[kk] = authTypes[kk.add(1)];
          }

          delete authTypes[authTypes.length.sub(1)];
          authTypes.length = authTypes.length.sub(1);
        } else {
          i = i.add(1);
        }
      } else {
        i = i.add(1);
      }
    }
 

    delete ownerOfSides[_addr];

    clearAuth(AUTH_REMOVEOWNER);
    emit OwnerRemoved(_addr);
  }

}

contract MultiOwnerContract is MultiOwners {
    Claimable public ownedContract;
    address public pendingOwnedOwner;
     

    string public constant AUTH_CHANGEOWNEDOWNER = "transferOwnerOfOwnedContract";

     
     
     
     
     

     
    function bindContract(address _contract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        ownedContract = Claimable(_contract);
         

         
        ownedContract.claimOwnership();

        return true;
    }

     
     
     
     
     
     

     
    function changeOwnedOwnershipto(address _nextOwner) onlyMultiOwners public {
        require(ownedContract != address(0));
        require(hasAuth(AUTH_CHANGEOWNEDOWNER));

        if (ownedContract.owner() != pendingOwnedOwner) {
            ownedContract.transferOwnership(_nextOwner);
            pendingOwnedOwner = _nextOwner;
             
             
        } else {
             
            ownedContract = Claimable(address(0));
            pendingOwnedOwner = address(0);
        }

        clearAuth(AUTH_CHANGEOWNEDOWNER);
    }

    function ownedOwnershipTransferred() onlyOwner public returns (bool) {
        require(ownedContract != address(0));
        if (ownedContract.owner() == pendingOwnedOwner) {
             
            ownedContract = Claimable(address(0));
            pendingOwnedOwner = address(0);
            return true;
        } else {
            return false;
        }
    }

}

contract DRCTOwner is MultiOwnerContract {
    string public constant AUTH_INITCONGRESS = "initCongress";
    string public constant AUTH_CANMINT = "canMint";
    string public constant AUTH_SETMINTAMOUNT = "setMintAmount";
    string public constant AUTH_FREEZEACCOUNT = "freezeAccount";

    bool congressInit = false;
     
     
    uint256 onceMintAmount;


     
     
     

     
     
     

     
    function setOnceMintAmount(uint256 _value) onlyMultiOwners public {
        require(hasAuth(AUTH_SETMINTAMOUNT));
        require(_value > 0);
        onceMintAmount = _value;

        clearAuth(AUTH_SETMINTAMOUNT);
    }

     
    function initCongress(address _congress) onlyMultiOwners public {
        require(hasAuth(AUTH_INITCONGRESS));
        require(!congressInit);

        itoken tk = itoken(address(ownedContract));
        tk.initialCongress(_congress);

        clearAuth(AUTH_INITCONGRESS);
        congressInit = true;
    }

     
    function mint(address _to) onlyMultiOwners public returns (bool) {
        require(hasAuth(AUTH_CANMINT));

        itoken tk = itoken(address(ownedContract));
        bool res = tk.mint(_to, onceMintAmount);

        clearAuth(AUTH_CANMINT);
        return res;
    }

     
    function finishMinting() onlyMultiOwners public returns (bool) {
        require(hasAuth(AUTH_CANMINT));

        itoken tk = itoken(address(ownedContract));
        bool res = tk.finishMinting();

        clearAuth(AUTH_CANMINT);
        return res;
    }

     
    function freezeAccountDirect(address _target, bool _freeze) onlyMultiOwners public {
        require(hasAuth(AUTH_FREEZEACCOUNT));

        require(_target != address(0));
        itoken tk = itoken(address(ownedContract));
        tk.freezeAccount(_target, _freeze);

        clearAuth(AUTH_FREEZEACCOUNT);
    }

     
    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        require(_target != address(0));
        itoken tk = itoken(address(ownedContract));
        if (_freeze) {
            require(tk.allowance(_target, this) == tk.balanceOf(_target));
        }

        tk.freezeAccount(_target, _freeze);
    }

     
    function freezeAccountPartialy(address _target, uint256 _value) onlyOwner public {
        require(_target != address(0));
        itoken tk = itoken(address(ownedContract));
        require(tk.allowance(_target, this) == _value);

        tk.freezeAccountPartialy(_target, _value);
    }

     
    function pause() onlyOwner public {
        itoken tk = itoken(address(ownedContract));
        tk.pause();
    }

     
    function unpause() onlyOwner public {
        itoken tk = itoken(address(ownedContract));
        tk.unpause();
    }

}

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