 

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
     
    uint256 c = a / b;
     
    return c;
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract Pausable is Ownable {
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract DeconetToken is StandardToken, Ownable, Pausable {
     
    string public constant symbol = "DCO";
    string public constant name = "Deconet Token";
    uint8 public constant decimals = 18;

     
    uint public constant version = 4;

     
     
     
    constructor() public {
         
        totalSupply_ = 1000000000 * 10**uint(decimals);

         
        balances[msg.sender] = totalSupply_;
        Transfer(address(0), msg.sender, totalSupply_);

         
        paused = true;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

     
     
     
     
    modifier whenOwnerOrNotPaused() {
        require(msg.sender == owner || !paused);
        _;
    }

     
     
     
    function transfer(address _to, uint256 _value) public whenOwnerOrNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public whenOwnerOrNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
     
     
    function approve(address _spender, uint256 _value) public whenOwnerOrNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

     
     
     
    function increaseApproval(address _spender, uint _addedValue) public whenOwnerOrNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

     
     
     
    function decreaseApproval(address _spender, uint _subtractedValue) public whenOwnerOrNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract Relay is Ownable {
    address public licenseSalesContractAddress;
    address public registryContractAddress;
    address public apiRegistryContractAddress;
    address public apiCallsContractAddress;
    uint public version;

     
     
     
    constructor() public {
        version = 4;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

     
     
     
    function setLicenseSalesContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        licenseSalesContractAddress = newAddress;
    }

     
     
     
    function setRegistryContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        registryContractAddress = newAddress;
    }

     
     
     
    function setApiRegistryContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        apiRegistryContractAddress = newAddress;
    }

     
     
     
    function setApiCallsContractAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0));
        apiCallsContractAddress = newAddress;
    }
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
contract LicenseSales is Ownable {
    using SafeMath for uint;

     
    uint public tokenReward;

     
    uint public saleFee;

     
    address public relayContractAddress;

     
    address public tokenContractAddress;

     
    uint public version;

     
    address private withdrawAddress;

    event LicenseSale(
        bytes32 moduleName,
        bytes32 sellerUsername,
        address indexed sellerAddress,
        address indexed buyerAddress,
        uint price,
        uint soldAt,
        uint rewardedTokens,
        uint networkFee,
        bytes4 licenseId
    );

     
     
     
    constructor() public {
        version = 1;

         
         
        tokenReward = 100 * 10**18;

         
        saleFee = 10;

         
        withdrawAddress = msg.sender;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

     
     
     
    function withdrawEther() public {
        require(msg.sender == withdrawAddress);
        withdrawAddress.transfer(this.balance);
    }

     
     
     
    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        require(_withdrawAddress != address(0));
        withdrawAddress = _withdrawAddress;
    }

     
     
     
    function setRelayContractAddress(address _relayContractAddress) public onlyOwner {
        require(_relayContractAddress != address(0));
        relayContractAddress = _relayContractAddress;
    }

     
     
     
    function setTokenContractAddress(address _tokenContractAddress) public onlyOwner {
        require(_tokenContractAddress != address(0));
        tokenContractAddress = _tokenContractAddress;
    }

     
     
     
    function setTokenReward(uint _tokenReward) public onlyOwner {
        tokenReward = _tokenReward;
    }

     
     
     
    function setSaleFee(uint _saleFee) public onlyOwner {
        saleFee = _saleFee;
    }

     
     
     
    function makeSale(uint moduleId) public payable {
        require(moduleId != 0);

         
        Relay relay = Relay(relayContractAddress);
        address registryAddress = relay.registryContractAddress();

         
        Registry registry = Registry(registryAddress);

        uint price;
        bytes32 sellerUsername;
        bytes32 moduleName;
        address sellerAddress;
        bytes4 licenseId;

        (price, sellerUsername, moduleName, sellerAddress, licenseId) = registry.getModuleById(moduleId);

         
        require(msg.value >= price);

         
        require(sellerUsername != "" && moduleName != "" && sellerAddress != address(0) && licenseId != "");

         
        uint fee = msg.value.mul(saleFee).div(100); 
        uint payout = msg.value.sub(fee);

         
        emit LicenseSale(
            moduleName,
            sellerUsername,
            sellerAddress,
            msg.sender,
            price,
            block.timestamp,
            tokenReward,
            fee,
            licenseId
        );

         
        rewardTokens(sellerAddress);
        
         
        sellerAddress.transfer(payout);
    }

     
     
     
    function rewardTokens(address toReward) private {
        DeconetToken token = DeconetToken(tokenContractAddress);
        address tokenOwner = token.owner();

         
        uint tokenOwnerBalance = token.balanceOf(tokenOwner);
        uint tokenOwnerAllowance = token.allowance(tokenOwner, address(this));
        if (tokenOwnerBalance >= tokenReward && tokenOwnerAllowance >= tokenReward) {
            token.transferFrom(tokenOwner, toReward, tokenReward);
        }
    }
}