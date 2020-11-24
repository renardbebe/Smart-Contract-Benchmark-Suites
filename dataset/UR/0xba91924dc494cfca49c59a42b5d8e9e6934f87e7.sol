 

pragma solidity ^0.5.2;


contract RoleManager {

    mapping(address => bool) private admins;
    mapping(address => bool) private controllers;

    modifier onlyAdmins {
        require(admins[msg.sender], 'only admins');
        _;
    }

    modifier onlyControllers {
        require(controllers[msg.sender], 'only controllers');
        _;
    } 

    constructor() public {
        admins[msg.sender] = true;
        controllers[msg.sender] = true;
    }

    function addController(address _newController) external onlyAdmins{
        controllers[_newController] = true;
    } 

    function addAdmin(address _newAdmin) external onlyAdmins{
        admins[_newAdmin] = true;
    } 

    function removeController(address _controller) external onlyAdmins{
        controllers[_controller] = false;
    } 
    
    function removeAdmin(address _admin) external onlyAdmins{
        require(_admin != msg.sender, 'unexecutable operation'); 
        admins[_admin] = false;
    } 

    function isAdmin(address addr) external view returns (bool) {
        return (admins[addr]);
    }

    function isController(address addr) external view returns (bool) {
        return (controllers[addr]);
    }

}

contract AccessController {

    address roleManagerAddr;

    modifier onlyAdmins {
        require(RoleManager(roleManagerAddr).isAdmin(msg.sender), 'only admins');
        _;
    }

    modifier onlyControllers {
        require(RoleManager(roleManagerAddr).isController(msg.sender), 'only controllers');
        _;
    }

    constructor (address _roleManagerAddr) public {
        require(_roleManagerAddr != address(0), '_roleManagerAddr: Invalid address (zero address)');
        roleManagerAddr = _roleManagerAddr;
    }

}

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

contract AidolProductionBilling is AccessController {
    using SafeMath for uint256;

    mapping( address => uint256 ) public expirationTime;
    uint256 public price;
    bool public isAvailable;
    address payable public adminWallet;
    event Payment(address payer, uint256 newExpirationTime);

    constructor (address _roleManagerAddr)
        public
        AccessController(_roleManagerAddr)
    {
        price = 100 finney;
        isAvailable = true;
        adminWallet = msg.sender;
    }

    function () external payable {
        require(msg.value == price, 'Invalid amount of ether');
        require(isAvailable, 'Not available');
        require(expirationTime[msg.sender] == 0 ||
           expirationTime[msg.sender] < now.add(5 days), 'Too early to update payment');

        if (expirationTime[msg.sender] < now) {
          expirationTime[msg.sender] = now.add(30 days);
        } else {
          expirationTime[msg.sender] = expirationTime[msg.sender].add(30 days);
        }

        adminWallet.transfer(address(this).balance);
        emit Payment(msg.sender, expirationTime[msg.sender]);
    }

    function setPrice (uint256 _price) external onlyAdmins {
        price = _price;
    }

    function setAvailability (bool _isAvailable) external onlyAdmins {
        isAvailable = _isAvailable;
    }

    function setAdminWallet (address payable _adminWallet) external onlyAdmins {
      adminWallet = _adminWallet;
    }
}