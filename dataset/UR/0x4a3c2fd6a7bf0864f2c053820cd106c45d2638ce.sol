 

pragma solidity 0.4.24;
 
 
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Registry is Ownable {

    struct ModuleForSale {
        uint price;
        bytes32 sellerUsername;
        bytes32 moduleName;
        address sellerAddress;
        bytes4 licenseId;
    }

    mapping(string => uint) internal moduleIds;
    mapping(uint => ModuleForSale) public modules;

    uint public numModules;
    uint public version;

     
     
     
    constructor() public {
        numModules = 0;
        version = 1;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

     
     
     
    function listModule(uint price, bytes32 sellerUsername, bytes32 moduleName, string usernameAndProjectName, bytes4 licenseId) public {
         
        require(price != 0 && sellerUsername != "" && moduleName != "" && bytes(usernameAndProjectName).length != 0 && licenseId != 0);

         
        require(moduleIds[usernameAndProjectName] == 0);

        numModules += 1;
        moduleIds[usernameAndProjectName] = numModules;

        ModuleForSale storage module = modules[numModules];

        module.price = price;
        module.sellerUsername = sellerUsername;
        module.moduleName = moduleName;
        module.sellerAddress = msg.sender;
        module.licenseId = licenseId;
    }

     
     
     
    function getModuleId(string usernameAndProjectName) public view returns (uint) {
        return moduleIds[usernameAndProjectName];
    }

     
     
     
    function getModuleById(
        uint moduleId
    ) 
        public 
        view 
        returns (
            uint price, 
            bytes32 sellerUsername, 
            bytes32 moduleName, 
            address sellerAddress, 
            bytes4 licenseId
        ) 
    {
        ModuleForSale storage module = modules[moduleId];
        

        if (module.sellerAddress == address(0)) {
            return;
        }

        price = module.price;
        sellerUsername = module.sellerUsername;
        moduleName = module.moduleName;
        sellerAddress = module.sellerAddress;
        licenseId = module.licenseId;
    }

     
     
     
    function getModuleByName(
        string usernameAndProjectName
    ) 
        public 
        view
        returns (
            uint price, 
            bytes32 sellerUsername, 
            bytes32 moduleName, 
            address sellerAddress, 
            bytes4 licenseId
        ) 
    {
        uint moduleId = moduleIds[usernameAndProjectName];
        if (moduleId == 0) {
            return;
        }
        ModuleForSale storage module = modules[moduleId];

        price = module.price;
        sellerUsername = module.sellerUsername;
        moduleName = module.moduleName;
        sellerAddress = module.sellerAddress;
        licenseId = module.licenseId;
    }

     
     
     
    function editModule(uint moduleId, uint price, address sellerAddress, bytes4 licenseId) public {
         
        require(moduleId != 0 && price != 0 && sellerAddress != address(0) && licenseId != 0);

        ModuleForSale storage module = modules[moduleId];

         
        require(
            module.price != 0 && module.sellerUsername != "" && module.moduleName != "" && module.licenseId != 0 && module.sellerAddress != address(0)
        );

         
         
        require(msg.sender == module.sellerAddress || msg.sender == owner);

        module.price = price;
        module.sellerAddress = sellerAddress;
        module.licenseId = licenseId;
    }
}