 

pragma solidity ^0.5.3;

 
 
 
 

 
contract FixedAddress {
    address constant ProxyAddress = 0x1234567896326230a28ee368825D11fE6571Be4a;
    address constant TreasuryAddress = 0x12345678979f29eBc99E00bdc5693ddEa564cA80;
    address constant RegistryAddress = 0x12345678982cB986Dd291B50239295E3Cb10Cdf6;
}

 
interface RegistryInterface {
    function getOwner() external view returns (address);
    function getExchangeContract() external view returns (address);
    function contractApproved(address traderAddr) external view returns (bool);
    function contractApprovedBoth(address traderAddr1, address traderAddr2) external view returns (bool);
    function acceptNextExchangeContract() external;
}

 
contract Ownable {
    address public owner;
    address private nextOwner;

    event OwnershipTransfer(address newOwner, address previousOwner);

    modifier onlyOwner {
        require (msg.sender == owner, "onlyOwner methods called by non-owner.");
        _;
    }

    function approveNextOwner(address _nextOwner) external onlyOwner {
        require (_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() external {
        require (msg.sender == nextOwner, "Can only accept preapproved new owner.");
        emit OwnershipTransfer(nextOwner, owner);
        owner = nextOwner;
    }
}

contract Registry is FixedAddress, RegistryInterface, Ownable {

     

     
     
     
    address public exchangeContract;
    uint private exchangeContractVersion;

     
     
     
    address private nextExchangeContract;

     
     
     
    mapping (address => bool) private prevExchangeContracts;

     
     
     
     
     
     
    mapping (address => uint) private traderApprovals;

     

    event UpgradeExchangeContract(address exchangeContract, uint exchangeContractVersion);
    event TraderApproveContract(address traderAddr, uint exchangeContractVersion);

     

    constructor () public {
        owner = msg.sender;
         
    }

     

    function getOwner() external view returns (address) {
        return owner;
    }

    function getExchangeContract() external view returns (address) {
        return exchangeContract;
    }

     

    function approveNextExchangeContract(address _nextExchangeContract) external onlyOwner {
        require (_nextExchangeContract != exchangeContract, "Cannot approve current exchange contract.");
        require (!prevExchangeContracts[_nextExchangeContract], "Cannot approve previously used contract.");
        nextExchangeContract = _nextExchangeContract;
    }

    function acceptNextExchangeContract() external {
        require (msg.sender == nextExchangeContract, "Can only accept preapproved exchange contract.");
        exchangeContract = nextExchangeContract;
        prevExchangeContracts[nextExchangeContract] = true;
        exchangeContractVersion++;

        emit UpgradeExchangeContract(exchangeContract, exchangeContractVersion);
    }

     

    function traderApproveCurrentExchangeContract(uint _exchangeContractVersion) external {
        require (_exchangeContractVersion > 1, "First version doesn't need approval.");
        require (_exchangeContractVersion == exchangeContractVersion, "Can only approve the latest version.");
        traderApprovals[msg.sender] = _exchangeContractVersion;

        emit TraderApproveContract(msg.sender, _exchangeContractVersion);
    }

     

    function contractApproved(address traderAddr) external view returns (bool) {
        if (exchangeContractVersion > 1) {
            return exchangeContractVersion == traderApprovals[traderAddr];

        } else {
            return exchangeContractVersion == 1;
        }
    }

    function contractApprovedBoth(address traderAddr1, address traderAddr2) external view returns (bool) {
         
         
        if (exchangeContractVersion > 1) {
            return
              exchangeContractVersion == traderApprovals[traderAddr1] &&
              exchangeContractVersion == traderApprovals[traderAddr2];

        } else {
            return exchangeContractVersion == 1;
        }
    }

}