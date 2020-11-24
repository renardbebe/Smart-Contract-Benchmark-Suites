 

 

pragma solidity ^0.4.21;

contract Ownable {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Utils {
    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function lowerCase(bytes32 value) public pure returns (bytes32) {
        bytes32 result = value;
        for (uint i = 0; i < 32; i++) {
            if (uint(value[i]) >= 65 && uint(value[i]) <= 90) {
                result |= bytes32(0x20) << (31-i)*8;
            }
        }
        return result;
    }
    
    function validateCompanyName(bytes32 name) public pure returns (bool) {
        for (uint i = 0; i < 32; i++) {
            if (uint(name[i]) != 0 && (uint(name[i]) < 32 || uint(name[i]) > 126)) {
                return false;
            }
        }
        return true;
    }
}

contract CompanyCostInterface is Ownable {
    function getCreationCost() public view returns (uint256);  
    function getCompanyCount() public view returns (uint256);
    function getOffsaleCount() public view returns (uint256);
    function increaseCompanyCountByOne() public;
    function increaseOffsaleCountByOne() public;
    function decreaseOffsaleCountByOne() public;

    function calculateNextPrice(uint256 oldPrice) public view returns (uint256);
    function calculatePreviousPrice(uint256 newPrice) public view returns (uint256);
}

contract RandomGeneratorInterface {
    function rand(address sender) public returns (uint256);
}

contract TopCompanyFactoryInterface is Ownable {
    struct TopCompany {
        bytes32 name;
        uint256 performance;
        bytes32 logoUrl;
    }

    uint256 public startPrice;  
    int256 public startBlock;
    uint256 public initialAvailableCount;

     
    uint256 public blocksBetweenNewCompany;

    uint256 public companyCount;
    TopCompany[] public companies;
    mapping(bytes32 => uint256) public companiesIndex;
    function canBuyCompany(bytes32 nameLowercase) public view returns (bool);
    function getCompanyByName(bytes32 nameLowercase) public view returns (bytes32 name, uint256 performance, bytes32 logoUrl);
    function getCompany(uint256 index) public view returns (bytes32 name, uint256 performance, bytes32 logoUrl);
    function removeCompany(bytes32 nameLowercase) public returns (uint256);
}

contract ECOMTokenInterface is Ownable {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function ownerApprove(address _sender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Ethecom is Ownable {
    struct Company {
        bytes32 name;
        bytes32 logoUrl;
        uint performance;
        address owner;
        uint price;
        uint lastPrice;
        bool isOnsale;
    }

    event CompanyCreated(bytes32 name, bytes32 logoUrl,uint256 performance, uint256 price, address owner);
    event CompanyTransferred(bytes32 name, uint256 newPrice, address oldOwner, address owner);
    event CompanyLogoUpdated(bytes32 name, bytes32 logoUrl, address owner);
    event CompanySaleStatusChanged(bytes32 name, bool saleStatus, uint256 lastPrice, address owner);
    event SuperPrivilegeLuckyDrawResult(uint256 resultValue, bool status, address owner);

    ECOMTokenInterface public tokenContract;
    TopCompanyFactoryInterface public factoryContract;
    RandomGeneratorInterface public randContract;
    CompanyCostInterface public costContract;
    Utils private utils;
    uint ECOMDecimal = 100000000;

     
    uint256 public blocksPerDay = 5000;

     
    mapping(bytes32 => Company) public companies;

     
    mapping(address => uint256) public ownedPerformance;

     
    mapping(address => uint256) public lastTokenClaimedBlock;

     
    mapping (address => uint256) public superPrivilegeCount;

     
    uint256 public minRandomPrivilegeValue = 90;
    uint256 public superPrivilegeCost = 30;  

    uint256 public maxUserCreatedPerformance = 35; 
    uint256 public oldOwnerProfit = 80;
    uint256 public logoFee = 10;  
    uint256 public minCompanyValue = 1000000000000000;  
    uint256 public maxCompanyValue = 100000000000000000000;  

    constructor(address ECOMToken, address topCompanyFactory, address randomGenerator, address companyCost) public {
        factoryContract = TopCompanyFactoryInterface(topCompanyFactory);
        randContract = RandomGeneratorInterface(randomGenerator);
        costContract = CompanyCostInterface(companyCost);
        tokenContract = ECOMTokenInterface(ECOMToken);

        utils = new Utils();
    }

     

    function updateBlocksPerDay(uint256 value) public onlyOwner {
        blocksPerDay = value;
    }

    function updateSuperPrivilegeParams(uint256 minRandom, uint256 cost) public onlyOwner {
        minRandomPrivilegeValue = minRandom;
        superPrivilegeCost = cost;
    }

    function updateUserCreatedPerformance(uint256 max) public onlyOwner {
        maxUserCreatedPerformance = max;
    }

    function updateLogoFee(uint256 newFee) public onlyOwner {
        logoFee = newFee;
    }

    function updateOldOwnerProfit(uint256 newProfit) public onlyOwner {
        oldOwnerProfit = newProfit;
    }

    function updateMinCompanyValue(uint256 minValue) public onlyOwner {
        minCompanyValue = minValue;
    }

     

    function purchaseCompany(bytes32 nameFromUser, bool superPrivilege) public payable {
        bytes32 nameLowercase = utils.lowerCase(nameFromUser);
        Company storage c = companies[nameLowercase];
        require(c.owner != address(0));
        require(c.owner != msg.sender);
        require(c.price == msg.value);
        require(c.isOnsale == true);
        if (superPrivilege) {
            require(superPrivilegeCount[msg.sender] > 0);
        }

        address oldOwner = c.owner;
        uint256 profit = c.price - c.lastPrice;
        oldOwner.transfer(c.lastPrice + profit * 8/10);

        c.owner = msg.sender;
        c.lastPrice = c.price;
        c.price = costContract.calculateNextPrice(c.price);
        
        emit CompanyTransferred(c.name, c.price, oldOwner, msg.sender);

        claimToken(oldOwner);
        ownedPerformance[oldOwner] -= c.performance;

        claimToken(msg.sender);
        ownedPerformance[msg.sender] += c.performance;

        if (superPrivilege) {
            c.isOnsale = false;
            superPrivilegeCount[msg.sender]--;
            emit CompanySaleStatusChanged(c.name, c.isOnsale, c.price, msg.sender);
        }
    }

    function purchaseTopCompany(bytes32 nameFromUser, bool superPrivilege) public payable {
         
        uint256 startPrice = factoryContract.startPrice();
        require(msg.value == startPrice);

        bytes32 nameLowercase = utils.lowerCase(nameFromUser);
         

         
         
        require(companies[nameLowercase].owner == address(0));

         
        require(factoryContract.canBuyCompany(nameLowercase));
        if (superPrivilege) {
            require(superPrivilegeCount[msg.sender] > 0);
        }

        bytes32 name;
        uint256 performance;
        bytes32 logoUrl;
        (name, performance, logoUrl) = factoryContract.getCompanyByName(nameLowercase);
        uint256 price = costContract.calculateNextPrice(startPrice);
        Company memory c = Company(name, logoUrl, performance, msg.sender, price, startPrice, !superPrivilege);
        companies[nameLowercase] = c;

        claimToken(msg.sender);
        ownedPerformance[msg.sender] += performance;

        factoryContract.removeCompany(nameLowercase);
         
        emit CompanyTransferred(name, price, address(0), msg.sender);

        if (superPrivilege) {
            superPrivilegeCount[msg.sender]--;
            emit CompanySaleStatusChanged(c.name, c.isOnsale, c.price, msg.sender);
        }
    }

     
     
     
     
    function createCompany(bytes32 name, bytes32 logoUrl, uint256 value) public {
        require(value >= minCompanyValue);
        require(value <= maxCompanyValue);
        require(utils.validateCompanyName(name) == true);

        bytes32 nameLowercase = utils.lowerCase(name);

         
        require(factoryContract.companiesIndex(nameLowercase) == 0);
        require(companies[nameLowercase].owner == address(0));

        uint256 cost = costContract.getCreationCost() * ECOMDecimal;
        claimToken(msg.sender);
        transferECOMTokenToContract(cost);

        uint256 performance = generateRandomPerformance();
        Company memory c = Company(name, logoUrl, performance, msg.sender, value, costContract.calculatePreviousPrice(value), true);
        companies[nameLowercase] = c;

        ownedPerformance[msg.sender] += performance;

        costContract.increaseCompanyCountByOne();
        emit CompanyCreated(name, logoUrl, performance, value, msg.sender);
    }

     
    function permanentlyOwnMyCompany(bytes32 nameFromUser) public {
        bytes32 nameLowercase = utils.lowerCase(nameFromUser);
        Company storage c = companies[nameLowercase];
        require(superPrivilegeCount[msg.sender] > 0);
        require(c.owner != address(0));
        require(c.owner == msg.sender);
        require(c.isOnsale == true);
        
        c.isOnsale = false;
        superPrivilegeCount[msg.sender]--;

        emit CompanySaleStatusChanged(c.name, false, c.price, msg.sender);
    }

     
    function putCompanyOnsale(bytes32 nameFromUser, uint256 startPrice) public {
        require(startPrice >= minCompanyValue);
        require(startPrice <= maxCompanyValue);
        bytes32 nameLowercase = utils.lowerCase(nameFromUser);
        Company storage c = companies[nameLowercase];
        require(c.owner != address(0));
        require(c.owner == msg.sender);
        require(c.isOnsale == false);

        c.price = startPrice;
        c.lastPrice = costContract.calculatePreviousPrice(c.price);
        c.isOnsale = true;

        emit CompanySaleStatusChanged(c.name, c.isOnsale, c.price, msg.sender);
    }

     
    function runSuperPrivilegeLuckyDraw() public {
        claimToken(msg.sender);
        transferECOMTokenToContract(superPrivilegeCost*ECOMDecimal);
        uint256 rand = randContract.rand(msg.sender);
        rand = rand % 100;
        bool status = false;
        if (rand >= minRandomPrivilegeValue) {
            superPrivilegeCount[msg.sender] = superPrivilegeCount[msg.sender] + 1;
            status = true;
        }

        emit SuperPrivilegeLuckyDrawResult(rand, status, msg.sender);
    }

     
    function claimMyToken() public {
        require(ownedPerformance[msg.sender] > 0);

        claimToken(msg.sender);
    }

    function updateLogoUrl(bytes32 companyName, bytes32 logoUrl) public {
        bytes32 nameLowercase = utils.lowerCase(companyName);
        Company storage c = companies[nameLowercase];
        require(c.owner == msg.sender);
        claimToken(msg.sender);
        transferECOMTokenToContract(logoFee * ECOMDecimal);
        c.logoUrl = logoUrl;
        emit CompanyLogoUpdated(c.name, c.logoUrl, msg.sender);
    }

     

      

    function updateTokenContract(address addr) public onlyOwner {
        tokenContract = ECOMTokenInterface(addr);
    }

    function updateRandContract(address addr) public onlyOwner {
        randContract = RandomGeneratorInterface(addr);
    }

    function updateCostContract(address addr) public onlyOwner {
        costContract = CompanyCostInterface(addr);
    }

    function updateFactoryContract(address addr) public onlyOwner {
        factoryContract = TopCompanyFactoryInterface(addr);
    }

    function transferSubcontractsOwnership(address addr) public onlyOwner {
        tokenContract.transferOwnership(addr);
        costContract.transferOwnership(addr);
        factoryContract.transferOwnership(addr);

         
    }

     
    function withdraw(uint256 amount) public onlyOwner {
        if (amount == 0) {
            owner.transfer(address(this).balance);
        } else {
            owner.transfer(amount);
        }
    }

     

    function getTopCompanyStartPrice() public view returns (uint256) {
        return factoryContract.startPrice();
    }

    function getTopCompanyStartBlock() public view returns (int256) {
        return factoryContract.startBlock();
    }

    function getTopCompanyBlocksInBetween() public view returns (uint256) {
        return factoryContract.blocksBetweenNewCompany();
    }

    function getTopCompanyCount() public view returns (uint256) {
        return factoryContract.companyCount();
    }

    function getTopCompanyAtIndex(uint256 index) public view returns (bytes32 name, uint256 performance, bytes32 logoUrl) {
        return factoryContract.getCompany(index);
    }

    function getCompanyCreationCost() public view returns (uint256) {
        return costContract.getCreationCost();
    }

    function checkCompanyNameAvailability(bytes32 name) public view returns (uint256) {
        uint256 result = 1;
        bytes32 nameLowercase = utils.lowerCase(name);
        if (utils.validateCompanyName(name) != true) {
            result = 0;
        } else if (factoryContract.companiesIndex(nameLowercase) != 0) {
            result = 0;
        } else if (companies[nameLowercase].owner != address(0)) {
            result = 0;
        }
        return result;
    }

     
    function transferECOMTokenToContract(uint256 amount) private {
        require(tokenContract.balanceOf(msg.sender) >= amount);
        tokenContract.ownerApprove(msg.sender, amount);
        tokenContract.transferFrom(msg.sender, address(this), amount);
    }

    function generateRandomPerformance() private returns (uint256) {
        uint256 rand = randContract.rand(msg.sender);
        rand = rand % (maxUserCreatedPerformance * maxUserCreatedPerformance);
        rand = utils.sqrt(rand);
        return maxUserCreatedPerformance - rand;
    }

    function claimToken(address receiver) private {
        uint256 numBlock = block.number - lastTokenClaimedBlock[receiver];
        uint256 profitPerBlock = ownedPerformance[receiver] * ECOMDecimal / blocksPerDay;
        uint256 profit = numBlock * profitPerBlock;
        if (profit > 0) {
            tokenContract.transfer(receiver, profit);
        }
        lastTokenClaimedBlock[receiver] = block.number;
    }
}