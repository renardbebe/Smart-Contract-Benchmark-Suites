 

 

 

  
  
  
  
  

 
pragma solidity ^0.4.23;

 
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


 
contract Superuser is Ownable, RBAC {
  string public constant ROLE_SUPERUSER = "superuser";

  constructor () public {
    addRole(msg.sender, ROLE_SUPERUSER);
  }

   
  modifier onlySuperuser() {
    checkRole(msg.sender, ROLE_SUPERUSER);
    _;
  }

  modifier onlyOwnerOrSuperuser() {
    require(msg.sender == owner || isSuperuser(msg.sender));
    _;
  }

   
  function isSuperuser(address _addr)
    public
    view
    returns (bool)
  {
    return hasRole(_addr, ROLE_SUPERUSER);
  }

   
  function transferSuperuser(address _newSuperuser) public onlyOwner {
    require(_newSuperuser != address(0));
    removeRole(msg.sender, ROLE_SUPERUSER);
    addRole(_newSuperuser, ROLE_SUPERUSER);
  }
}

 
contract MicroverseBase is Superuser {

    using SafeMath for uint256;

    event OpenWormhole();
    event CloseWormhole();
    event SystemChangePercentWeiDividend(uint256 oldValue, uint256 newValue);
    event SystemChangePercentWeiJackpot(uint256 oldValue, uint256 newValue);
    event SystemChangePercentWeiMC(uint256 oldValue, uint256 newValue);

    uint256 public previousWeiBalance;
    uint256 public nextSeedHashed;
    uint256 public percentWeiDividend = 40;  
    uint256 public percentWeiJackpot = 10;  
    uint256 public percentWeiMC = 10;  
    uint256 public FACTOR = 100;

     
    bool public wormholeIsOpen = true;

    modifier wormholeOpened() {
        require (wormholeIsOpen == true);
        _;
    }

     
    function openWormhole() external onlyOwner {
        wormholeIsOpen = true;
        emit OpenWormhole();
    }

     
    function closeWormhole() external onlyOwner {
        wormholeIsOpen = false;
        emit CloseWormhole();
    }

     
    function setNextSeedHash(uint256 seedHash)
        external
        onlyOwner {
        nextSeedHashed = seedHash;
    }

     
    function setPercentWeiDividend(uint256 _value)
        external
        onlyOwner {
        emit SystemChangePercentWeiDividend(percentWeiDividend, _value);
        percentWeiDividend = _value;
    }

     
    function setPercentWeiJackpot(uint256 _value)
        external
        onlyOwner {
        emit SystemChangePercentWeiJackpot(percentWeiJackpot, _value);
        percentWeiJackpot = _value;
    }

     
    function setPercentWeiMC(uint256 _value)
        external
        onlyOwner {
        emit SystemChangePercentWeiMC(percentWeiMC, _value);
        percentWeiMC = _value;
    }
}

 

 
contract GarageInterface {
     
    function getEvilMortyAddress() external view returns (address);

     
    function citadelBuy(uint256 weiAmount, address beneficiary) external returns (uint256);
}

 
contract PortalGunInterFace {

    uint256 public numTickets;

     
    function participate(address player, uint256 amount) external;

     
    function balanceOfMorty(address sender) external view returns (uint256);

     
    function balanceOfRick(address sender) external view returns (uint256);

     
    function balanceOfFlurbo(address sender) external view returns (uint256);

     
    function redeem(uint256 seed) external;

     
    function startRick() external returns (bool);

     
    function resetRick() external;

     
    function startPortalGun() external;

     
    function stopPortalGunAndRick() external;

     
    function getNumOfRickHolders() external view returns (uint256);
}

 
contract SpaceshipInterface {

     
    function startSpaceship() external returns (bool);
    
     
    function sendDividends() external;
    
     
    function getNumDividends() external view returns (uint256);
    
     
    function updateSpaceshipStatus() external;    
}


 
contract Microverse is MicroverseBase {

    event Refund(address indexed receiver, uint256 value);
    event Withdraw(address indexed receiver, uint256 value);

    GarageInterface internal garageInstance;
    PortalGunInterFace internal portalGunInstance;
    SpaceshipInterface internal spaceshipInstance;

    address internal EvilMortyAddress;
    address internal MCAddress;

    modifier isEvilMortyToken() {
        require(msg.sender == EvilMortyAddress);
        _;
    }

    constructor(
        address garageAddress,
        address portalGunAddress,
        address spaceshipAddress,
        address MutualConstructorAddress)
        public {

        garageInstance = GarageInterface(garageAddress);
        portalGunInstance = PortalGunInterFace(portalGunAddress);
        spaceshipInstance = SpaceshipInterface(spaceshipAddress);
        EvilMortyAddress = garageInstance.getEvilMortyAddress();
        MCAddress = MutualConstructorAddress;
    }

     
    function ()
        public
        payable {
        if (msg.sender == owner) {
            return;
        }
        buyMorty();
    }

     
    function tokenFallback(address _from, uint _value, bytes _data)
        public
        wormholeOpened
        isEvilMortyToken {
        if (_from == owner) {
            return;
        }
        portalGunInstance.participate(_from, _value);
    }

     
    function balanceOfMorty(address sender)
        external
        view
        returns (uint256) {
        return portalGunInstance.balanceOfMorty(sender);
    }

     
    function balanceOfRick(address sender)
        external
        view
        returns (uint256) {
        return portalGunInstance.balanceOfRick(sender);
    }

     
    function balanceOfFlurbo(address sender)
        external
        view
        returns (uint256) {
        return portalGunInstance.balanceOfFlurbo(sender);
    }

     
    function buyMorty()
        public
        wormholeOpened
        payable {

        uint256 weiReturn = garageInstance.citadelBuy(msg.value, msg.sender);

        if (weiReturn > 0) {
            msg.sender.transfer(weiReturn);
            emit Refund(msg.sender, weiReturn);
        }

        _addWeiAmount(address(this).balance.sub(previousWeiBalance));
    }

     
    function transferJackpot(address winner)
        external
        onlyOwner
        returns (bool) {
        uint256 weiJackpot = address(this).balance;
        emit Withdraw(winner, weiJackpot);
        winner.transfer(weiJackpot);
        previousWeiBalance = 0;
    }

     
    function redeemLottery(uint256 seed)
        external
        onlyOwnerOrSuperuser {
        return portalGunInstance.redeem(seed);
    }

     
    function getNumOfLotteryTickets()
        external
        view
        returns (uint256) {
        return portalGunInstance.numTickets();
    }

     
    function _addWeiAmount(uint256 weiAmount)
        internal
        returns (bool) {

        uint256 weiDividendPart = weiAmount.mul(percentWeiDividend).div(FACTOR);  
        uint256 weiJackpotPart = weiAmount.mul(percentWeiJackpot).div(FACTOR);  
        uint256 weiMCPart = weiAmount.mul(percentWeiMC).div(FACTOR);  
        uint256 weiEMFPart = weiAmount.sub(weiDividendPart).sub(weiJackpotPart).sub(weiMCPart);

        address(spaceshipInstance).transfer(weiDividendPart);
        MCAddress.transfer(weiMCPart);
        address(owner).transfer(weiEMFPart);

        previousWeiBalance = address(this).balance;

        return true;
    }

     
    function prepareDividends()
        external
        onlyOwnerOrSuperuser {

        spaceshipInstance.updateSpaceshipStatus();
        portalGunInstance.stopPortalGunAndRick();
    }

     
    function transferDividends()
        external
        onlyOwnerOrSuperuser {
        return spaceshipInstance.sendDividends();
    }

     
    function getNumDividends()
        external
        view
        returns (uint256) {
        return spaceshipInstance.getNumDividends();
    }

     
    function finishDividends()
        external
        onlyOwnerOrSuperuser {
        spaceshipInstance.startSpaceship();
        portalGunInstance.startPortalGun();
        portalGunInstance.startRick();
    }

     
    function resetDividends()
        external
        onlyOwnerOrSuperuser {
        return portalGunInstance.resetRick();
    }

     
    function getNumOfRickHolders()
        external
        view
        returns (uint256) {
        return portalGunInstance.getNumOfRickHolders();
    }

     
    function upgradeComponent(
        uint256 _componentIndex,
        address _address)
        external
        onlyOwner {

        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_address)
        }

        if (codeLength == 0) {
            return;
        }

        if (_componentIndex == 1) {
            garageInstance = GarageInterface(_address);
            return;
        }

        if (_componentIndex == 2) {
            portalGunInstance = PortalGunInterFace(_address);
            return;
        }

        if (_componentIndex == 3) {
            spaceshipInstance = SpaceshipInterface(_address);
            return;
        }

    }

     
    function upgradeEvilMorty()
        external
        onlyOwner {
        EvilMortyAddress = garageInstance.getEvilMortyAddress();
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