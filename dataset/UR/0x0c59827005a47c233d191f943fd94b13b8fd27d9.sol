 

pragma solidity ^0.4.18;


 
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

 
contract OwnOracle is Ownable {
    event NewOraclizeQuery();
    event PriceTicker(uint256 rateAmount);
    event BankSet(address bank);
    event UpdaterSet(address updater);

    bytes32 public oracleName = "LibreOracle Omega";
    bytes16 public oracleType = "Libre ETHUSD";
    uint256 public updateTime;
    uint256 public callbackTime;
    address public bankAddress;
    uint256 public rate;
    uint256 public requestPrice = 0;
    bool public waitQuery = false;
    address public updaterAddress;

    modifier onlyBank() {
        require(msg.sender == bankAddress);
        _;
    }

     
    function setBank(address bank) public onlyOwner {
        bankAddress = bank;
        BankSet(bankAddress);
    }

     
    function setUpdaterAddress(address updater) public onlyOwner {
        updaterAddress = updater;
        UpdaterSet(updaterAddress);
    }

     
    function getPrice() view public returns (uint256) {
        return updaterAddress.balance < requestPrice ? requestPrice : 0;
    }

     
    function setPrice(uint256 _requestPriceWei) public onlyOwner {
        requestPrice = _requestPriceWei;
    }

     
    function updateRate() external onlyBank returns (bool) {
        NewOraclizeQuery();
        updateTime = now;
        waitQuery = true;
        return true;
    }


     
    function __callback(uint256 result) public {
        require(msg.sender == updaterAddress && waitQuery);
        rate = result;
        callbackTime = now;
        waitQuery = false;
        PriceTicker(result);
    }

         
    function () public payable {
        updaterAddress.transfer(msg.value);
    }

}