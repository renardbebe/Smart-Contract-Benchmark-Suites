 

pragma solidity ^0.4.24;

 

contract DragonsETH {
    function createDragon(
        address _to, 
        uint256 _timeToBorn, 
        uint256 _parentOne, 
        uint256 _parentTwo, 
        uint256 _gen1, 
        uint240 _gen2
    ) 
        external;
}

library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
  }

}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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

contract RBACWithAdmin is RBAC {
   
  string public constant ROLE_ADMIN = "admin";
  string public constant ROLE_PAUSE_ADMIN = "pauseAdmin";

   
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }
  modifier onlyPauseAdmin()
  {
    checkRole(msg.sender, ROLE_PAUSE_ADMIN);
    _;
  }
   
  constructor()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
    addRole(msg.sender, ROLE_PAUSE_ADMIN);
  }

   
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

   
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }
}

contract Pausable is RBACWithAdmin {
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

   
  function pause() onlyPauseAdmin whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyPauseAdmin whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract ReentrancyGuard {

   
  bool private reentrancyLock = false;

   
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

contract CrowdSaleDragonETH is Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using AddressUtils for address;
    address private wallet;
    address public mainContract;
    uint256 public crowdSaleDragonPrice = 0.01 ether;
    uint256 public soldDragons;
    uint256 public priceChanger = 0.00002 ether;
    uint256 public timeToBorn = 5760;  
    uint256 public contRefer50x50;
    mapping(address => bool) public refer50x50;
    
    constructor(address _wallet, address _mainContract) public {
        wallet = _wallet;
        mainContract = _mainContract;
    }


    function() external payable whenNotPaused nonReentrant {
        require(soldDragons <= 100000);
        require(msg.value >= crowdSaleDragonPrice);
        require(!msg.sender.isContract());
        uint256 count_to_buy;
        uint256 return_value;
  
        count_to_buy = msg.value.div(crowdSaleDragonPrice);
        if (count_to_buy > 15) 
            count_to_buy = 15;
         
        return_value = msg.value - count_to_buy * crowdSaleDragonPrice;
        if (return_value > 0) 
            msg.sender.transfer(return_value);
            
        uint256 mainValue = msg.value - return_value;
        
        if (msg.data.length == 20) {
            address referer = bytesToAddress(bytes(msg.data));
            require(referer != msg.sender);
            if (referer == address(0))
                wallet.transfer(mainValue);
            else {
                if (refer50x50[referer]) {
                    referer.transfer(mainValue/2);
                    wallet.transfer(mainValue - mainValue/2);
                } else {
                    referer.transfer(mainValue*3/10);
                    wallet.transfer(mainValue - mainValue*3/10);
                }
            }
        } else 
            wallet.transfer(mainValue);

        for(uint256 i = 1; i <= count_to_buy; i += 1) {
            DragonsETH(mainContract).createDragon(msg.sender, block.number + timeToBorn, 0, 0, 0, 0);
            soldDragons++;
            crowdSaleDragonPrice = crowdSaleDragonPrice + priceChanger;
        }
        
    }

    function sendBonusEgg(address _to, uint256 _count) external onlyRole("BountyAgent") {
        for(uint256 i = 1; i <= _count; i += 1) {
            DragonsETH(mainContract).createDragon(_to, block.number + timeToBorn, 0, 0, 0, 0);
            soldDragons++;
            crowdSaleDragonPrice = crowdSaleDragonPrice + priceChanger;
        }
        
    }



    function changePrice(uint256 _price) external onlyAdmin {
        crowdSaleDragonPrice = _price;
    }

    function setPriceChanger(uint256 _priceChanger) external onlyAdmin {
        priceChanger = _priceChanger;
    }

    function changeWallet(address _wallet) external onlyAdmin {
        wallet = _wallet;
    }
    

    function setRefer50x50(address _refer) external onlyAdmin {
        require(contRefer50x50 < 50);
        require(refer50x50[_refer] == false);
        refer50x50[_refer] = true;
        contRefer50x50 += 1;
    }

    function setTimeToBorn(uint256 _timeToBorn) external onlyAdmin {
        timeToBorn = _timeToBorn;
        
    }

    function withdrawAllEther() external onlyAdmin {
        require(wallet != 0);
        wallet.transfer(address(this).balance);
    }
   
    function bytesToAddress(bytes _bytesData) internal pure returns(address _addressReferer) {
        assembly {
            _addressReferer := mload(add(_bytesData,0x14))
        }
        return _addressReferer;
    }
}