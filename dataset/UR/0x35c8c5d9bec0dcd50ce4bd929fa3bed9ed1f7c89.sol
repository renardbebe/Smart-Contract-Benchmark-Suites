 

 

pragma solidity ^0.5.2;


 
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
        require(isOwner(), "Not Owner!");
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
        require(newOwner != address(0),"Address 0 could not be owner");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


interface IERC20Seed {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IAdminTools {
    function setFFPAddresses(address, address) external;
    function setMinterAddress(address) external returns(address);
    function getMinterAddress() external view returns(address);
    function getWalletOnTopAddress() external view returns (address);
    function setWalletOnTopAddress(address) external returns(address);

    function addWLManagers(address) external;
    function removeWLManagers(address) external;
    function isWLManager(address) external view returns (bool);
    function addWLOperators(address) external;
    function removeWLOperators(address) external;
    function renounceWLManager() external;
    function isWLOperator(address) external view returns (bool);
    function renounceWLOperators() external;

    function addFundingManagers(address) external;
    function removeFundingManagers(address) external;
    function isFundingManager(address) external view returns (bool);
    function addFundingOperators(address) external;
    function removeFundingOperators(address) external;
    function renounceFundingManager() external;
    function isFundingOperator(address) external view returns (bool);
    function renounceFundingOperators() external;

    function addFundsUnlockerManagers(address) external;
    function removeFundsUnlockerManagers(address) external;
    function isFundsUnlockerManager(address) external view returns (bool);
    function addFundsUnlockerOperators(address) external;
    function removeFundsUnlockerOperators(address) external;
    function renounceFundsUnlockerManager() external;
    function isFundsUnlockerOperator(address) external view returns (bool);
    function renounceFundsUnlockerOperators() external;

    function isWhitelisted(address) external view returns(bool);
    function getWLThresholdBalance() external view returns (uint256);
    function getMaxWLAmount(address) external view returns(uint256);
    function getWLLength() external view returns(uint256);
    function setNewThreshold(uint256) external;
    function changeMaxWLAmount(address, uint256) external;
    function addToWhitelist(address, uint256) external;
    function addToWhitelistMassive(address[] calldata, uint256[] calldata) external returns (bool);
    function removeFromWhitelist(address, uint256) external;
}


interface IATDeployer {
    function newAdminTools(uint256) external returns(address);
    function setFactoryAddress(address) external;
    function getFactoryAddress() external view returns(address);
}


interface ITDeployer {
    function newToken(address, string calldata, string calldata, address) external returns(address);
    function setFactoryAddress(address) external;
    function getFactoryAddress() external view returns(address);
}


interface IFPDeployer {
    function newFundingPanel(address, string calldata, bytes32, uint256, uint256,
                            address, uint256, address, address, uint) external returns(address);
    function setFactoryAddress(address) external;
    function getFactoryAddress() external view returns(address);
}


contract Factory is Ownable {
    using SafeMath for uint256;

    address[] public deployerList;
    uint public deployerLength;
    address[] public ATContractsList;
    address[] public TContractsList;
    address[] public FPContractsList;

    mapping(address => bool) public deployers;
    mapping(address => bool) public ATContracts;
    mapping(address => bool) public TContracts;
    mapping(address => bool) public FPContracts;

    IERC20Seed private seedContract;
    address private seedAddress;
    IATDeployer private deployerAT;
    address private ATDAddress;
    ITDeployer private deployerT;
    address private TDAddress;
    IFPDeployer private deployerFP;
    address private FPDAddress;

    address private internalDEXAddress;

    uint private factoryDeployBlock;

    event NewPanelCreated(address, address, address, address, uint);
    event ATFactoryAddressChanged();
    event TFactoryAddressChanged();
    event FPFactoryAddressChanged();
    event InternalDEXAddressChanged();

    constructor (address _seedAddress, address _ATDAddress, address _TDAddress, address _FPDAddress) public {
        seedAddress = _seedAddress;
        seedContract = IERC20Seed(seedAddress);
        ATDAddress = _ATDAddress;
        deployerAT = IATDeployer(ATDAddress);
        TDAddress = _TDAddress;
        deployerT = ITDeployer(_TDAddress);
        FPDAddress = _FPDAddress;
        deployerFP = IFPDeployer(_FPDAddress);
        factoryDeployBlock = block.number;
    }

     
    function changeATFactoryAddress(address _newATD) external onlyOwner {
        require(block.number < 8850000, "Time expired!");
        require(_newATD != address(0), "Address not suitable!");
        require(_newATD != ATDAddress, "AT factory address not changed!");
        ATDAddress = _newATD;
        deployerAT = IATDeployer(ATDAddress);
        emit ATFactoryAddressChanged();
    }

     
    function changeTDeployerAddress(address _newTD) external onlyOwner {
        require(block.number < 8850000, "Time expired!");
        require(_newTD != address(0), "Address not suitable!");
        require(_newTD != TDAddress, "AT factory address not changed!");
        TDAddress = _newTD;
        deployerT = ITDeployer(TDAddress);
        emit TFactoryAddressChanged();
    }

     
    function changeFPDeployerAddress(address _newFPD) external onlyOwner {
        require(block.number < 8850000, "Time expired!");
        require(_newFPD != address(0), "Address not suitable!");
        require(_newFPD != ATDAddress, "AT factory address not changed!");
        FPDAddress = _newFPD;
        deployerFP = IFPDeployer(FPDAddress);
        emit FPFactoryAddressChanged();
    }

     
    function setInternalDEXAddress(address _dexAddress) external onlyOwner {
        require(block.number < 8850000, "Time expired!");
        require(_dexAddress != address(0), "Address not suitable!");
        require(_dexAddress != internalDEXAddress, "AT factory address not changed!");
        internalDEXAddress = _dexAddress;
        emit InternalDEXAddressChanged();
    }

     
    function deployPanelContracts(string memory _name, string memory _symbol, string memory _setDocURL, bytes32 _setDocHash,
                            uint256 _exchRateSeed, uint256 _exchRateOnTop, uint256 _seedMaxSupply, uint256 _WLAnonymThr) public {
        address sender = msg.sender;

        require(sender != address(0), "Sender Address is zero");
        require(internalDEXAddress != address(0), "Internal DEX Address is zero");

        deployers[sender] = true;
        deployerList.push(sender);
        deployerLength = deployerList.length;

        address newAT = deployerAT.newAdminTools(_WLAnonymThr);
        ATContracts[newAT] = true;
        ATContractsList.push(newAT);
        address newT = deployerT.newToken(sender, _name, _symbol, newAT);
        TContracts[newT] = true;
        TContractsList.push(newT);
        address newFP = deployerFP.newFundingPanel(sender, _setDocURL, _setDocHash, _exchRateSeed, _exchRateOnTop,
                                            seedAddress, _seedMaxSupply, newT, newAT, (deployerLength-1));
        FPContracts[newFP] = true;
        FPContractsList.push(newFP);

        IAdminTools ATBrandNew = IAdminTools(newAT);
        ATBrandNew.setFFPAddresses(address(this), newFP);
        ATBrandNew.setMinterAddress(newFP);
        ATBrandNew.addWLManagers(address(this));
        ATBrandNew.addWLManagers(sender);
        ATBrandNew.addFundingManagers(sender);
        ATBrandNew.addFundsUnlockerManagers(sender);
        ATBrandNew.setWalletOnTopAddress(sender);

        uint256 dexMaxAmnt = _exchRateSeed.mul(300000000);   
        ATBrandNew.addToWhitelist(internalDEXAddress, dexMaxAmnt);

        uint256 onTopMaxAmnt = _seedMaxSupply.mul(_exchRateSeed).div(10**18);
        ATBrandNew.addToWhitelist(sender, onTopMaxAmnt);

        ATBrandNew.removeWLManagers(address(this));

        Ownable customOwnable = Ownable(newAT);
        customOwnable.transferOwnership(sender);

        emit NewPanelCreated(sender, newAT, newT, newFP, deployerLength);
    }

     
    function getTotalDeployer() external view returns(uint256) {
        return deployerList.length;
    }

     
    function getTotalATContracts() external view returns(uint256) {
        return ATContractsList.length;
    }

     
    function getTotalTContracts() external view returns(uint256) {
        return TContractsList.length;
    }

     
    function getTotalFPContracts() external view returns(uint256) {
        return FPContractsList.length;
    }

     
    function isFactoryDeployer(address _addr) external view returns(bool) {
        return deployers[_addr];
    }

     
    function isFactoryATGenerated(address _addr) external view returns(bool) {
        return ATContracts[_addr];
    }

     
    function isFactoryTGenerated(address _addr) external view returns(bool) {
        return TContracts[_addr];
    }

     
    function isFactoryFPGenerated(address _addr) external view returns(bool) {
        return FPContracts[_addr];
    }

     
    function getContractsByIndex(uint256 _index) external view returns (address, address, address, address) {
        return(deployerList[_index], ATContractsList[_index], TContractsList[_index], FPContractsList[_index]);
    }

     
    function getFPAddressByIndex(uint256 _index) external view returns (address) {
        return FPContractsList[_index];
    }

     
    function getFactoryContext() external view returns (address, address, uint) {
        return (seedAddress, internalDEXAddress, factoryDeployBlock);
    }

}