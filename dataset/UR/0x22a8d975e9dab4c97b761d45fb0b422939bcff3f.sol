 

 

pragma solidity ^0.5.7;

 

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

 
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

 

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

 
contract Pausable is PauserRole {

    uint256 public selfDestructAt;
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause(uint256 selfDestructPeriod) public onlyPauser whenNotPaused {
        _paused = true;
        selfDestructAt = now + selfDestructPeriod;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 

contract PausableDestroyable is Pausable {

    function destroy() public whenPaused {
        require(selfDestructAt <= now);
         
        selfdestruct(address(0));
    }
}

 

 
 
 
contract UBIVault is Ownable, PausableDestroyable {

    using SafeMath for uint256;

    mapping(address => uint256) public rightFromPaymentCycle;
    mapping(bytes32 => bool) public useablePasswordHashes;
    mapping(bytes32 => bool) public usedPasswordHashes;
    uint8 public amountOfBasicIncomeCanBeIncreased;
    uint256 public amountOfBasicIncome;
    uint256 public amountOfCitizens;
    uint256 public euroCentInWei;
    uint256 public availableEther;
    address payable public maintenancePool;
    uint256 public minimumPeriod;
    uint256 public promisedEther;
    uint256 lastPayout;
    uint256[] public paymentsCycle;

    event LogUseablePasswordCreated(bytes32 passwordHash);
    event LogUBICreated(uint256 adjustedEuroCentInWei, uint256 totalamountOfBasicIncomeInWei, uint256 amountOfCitizens, uint8 amountOfBasicIncomeCanBeIncreased, uint256 paymentsCycle);
    event LogCitizenRegistered(address newCitizen);
    event LogPasswordUsed(bytes32 password, bytes32 passwordHash);
    event LogVaultSponsored(address payee, bytes32 message, uint256 amount);
    event LogUBIClaimed(address indexed caller, uint256 income, address indexed citizen);

     
    constructor(
        uint256 initialAB,
        uint256 initialMinimumPeriod,
        uint256 initialEuroCentInWei,
        address payable _maintenancePool
    ) public {
        minimumPeriod = initialMinimumPeriod;
        euroCentInWei = initialEuroCentInWei;
        amountOfBasicIncome = initialAB;
        maintenancePool = _maintenancePool;
        paymentsCycle.push(0);
    }

    function claimUBIOwner(address payable[] memory citizens, bool onlyOne) public onlyOwner returns(bool) {
        bool allRequestedCitizensGotPayout = true;
        for(uint256 i = 0; i < citizens.length; i++) {
            if(!claimUBI(citizens[i], onlyOne)) {
              allRequestedCitizensGotPayout = false;
            }
        }
        return allRequestedCitizensGotPayout;
    }

    function claimUBIPublic(bool onlyOne) public {
        require(claimUBI(msg.sender, onlyOne), "There is no claimable UBI available for your account");
    }

    function createUseablePasswords(bytes32[] memory _useablePasswordHashes) public onlyOwner {
        for(uint256 i = 0; i < _useablePasswordHashes.length; i++) {
            bytes32 usablePasswordHash = _useablePasswordHashes[i];
            require(!useablePasswordHashes[usablePasswordHash], "One of your useablePasswords was already registered");
            useablePasswordHashes[usablePasswordHash] = true;
            emit LogUseablePasswordCreated(usablePasswordHash);
        }
    }

     
     
    function createUBI(uint256 adjustedEuroCentInWei) public onlyOwner {
 
        uint256 totalamountOfBasicIncomeInWei = adjustedEuroCentInWei.mul(amountOfBasicIncome).mul(amountOfCitizens);
         
 
        require(lastPayout <= now - minimumPeriod, "You should wait the required time in between createUBI calls");
        require(availableEther.div(adjustedEuroCentInWei).div(amountOfCitizens) >= amountOfBasicIncome, "There are not enough funds in the UBI contract to sustain another UBI");
        euroCentInWei = adjustedEuroCentInWei;
        availableEther = availableEther.sub(totalamountOfBasicIncomeInWei);
        promisedEther = promisedEther.add(totalamountOfBasicIncomeInWei);

        paymentsCycle.push(adjustedEuroCentInWei.mul(amountOfBasicIncome));
        lastPayout = now;

         
        if(availableEther >= adjustedEuroCentInWei.mul(700).mul(amountOfCitizens)) {
             
            if(amountOfBasicIncomeCanBeIncreased == 2) {
                amountOfBasicIncomeCanBeIncreased = 0;
                amountOfBasicIncome = amountOfBasicIncome.add(700);
             
            } else {
                amountOfBasicIncomeCanBeIncreased++;
            }
         
        } else if(amountOfBasicIncomeCanBeIncreased != 0) {
            amountOfBasicIncomeCanBeIncreased == 0;
        }
        emit LogUBICreated(adjustedEuroCentInWei, totalamountOfBasicIncomeInWei, amountOfCitizens, amountOfBasicIncomeCanBeIncreased, paymentsCycle.length - 1);
    }

    function registerCitizenOwner(address newCitizen) public onlyOwner {
        require(newCitizen != address(0) , "NewCitizen cannot be the 0 address");
        registerCitizen(newCitizen);
    }

    function registerCitizenPublic(bytes32 password) public {
        bytes32 passwordHash = keccak256(abi.encodePacked(password));
        require(useablePasswordHashes[passwordHash] && !usedPasswordHashes[passwordHash], "Password is not known or already used");
        usedPasswordHashes[passwordHash] = true;
        registerCitizen(msg.sender);
        emit LogPasswordUsed(password, passwordHash);
    }

     
     
    function sponsorVault(bytes32 message) public payable whenNotPaused {
        moneyReceived(message);
    }

     
     
    function claimUBI(address payable citizen, bool onlyOne) internal returns(bool) {
        require(rightFromPaymentCycle[citizen] != 0, "Citizen not registered");
        uint256 incomeClaims = paymentsCycle.length - rightFromPaymentCycle[citizen];
        uint256 income;
        uint256 paymentsCycleLength = paymentsCycle.length;
        if(onlyOne && incomeClaims > 0) {
          income = paymentsCycle[paymentsCycleLength - incomeClaims];
        } else if(incomeClaims == 1) {
            income = paymentsCycle[paymentsCycleLength - 1];
        } else if(incomeClaims > 1) {
            for(uint256 index; index < incomeClaims; index++) {
                income = income.add(paymentsCycle[paymentsCycleLength - incomeClaims + index]);
            }
        } else {
            return false;
        }
        rightFromPaymentCycle[citizen] = paymentsCycleLength;
        promisedEther = promisedEther.sub(income);
        citizen.transfer(income);
        emit LogUBIClaimed(msg.sender, income, citizen);
        return true;

    }

    function moneyReceived(bytes32 message) internal {
      uint256 increaseInAvailableEther = msg.value.mul(95) / 100;
      availableEther = availableEther.add(increaseInAvailableEther);
      maintenancePool.transfer(msg.value - increaseInAvailableEther);
      emit LogVaultSponsored(msg.sender, message, msg.value);
    }

      
     
    function registerCitizen(address newCitizen) internal {
        require(rightFromPaymentCycle[newCitizen] == 0, "Citizen already registered");
        rightFromPaymentCycle[newCitizen] = paymentsCycle.length;
        amountOfCitizens++;
        emit LogCitizenRegistered(newCitizen);
    }

    function () external payable whenNotPaused {
        moneyReceived(bytes32(0));
    }
}