 

pragma solidity ^0.4.18;

 
 

contract NewCratePreSale {
    
     
     
     
     
    mapping (address => uint[]) public userToRobots; 

    function _migrate(uint _index) external onlyOwner {
        bytes4 selector = bytes4(sha3("setData()"));
        address a = migrators[_index];
        require(a.delegatecall(selector));
    }
     
    address[6] migrators = [
        0x700febd9360ac0a0a72f371615427bec4e4454e5,  
        0x72cc898de0a4eac49c46ccb990379099461342f6,
        0xc3cc48da3b8168154e0f14bf0446c7a93613f0a7,
        0x4cc96f2ddf6844323ae0d8461d418a4d473b9ac3,
        0xa52bfcb5ff599e29ee2b9130f1575babaa27de0a,
        0xe503b42aabda22974e2a8b75fa87e010e1b13584
    ];
    
    function NewCratePreSale() public payable {
        
            owner = msg.sender;
         
         

         
        oldAppreciationRateWei = 100000000000000;
        appreciationRateWei = oldAppreciationRateWei;
  
         
        oldPrice = 232600000000000000;
        currentPrice = oldPrice;

         
        oldCratesSold = 1075;
        cratesSold = oldCratesSold;

         
         
         
         
         
         
         
         
         
    }

     
    uint256 constant public MAX_CRATES_TO_SELL = 3900;  
    uint256 constant public PRESALE_END_TIMESTAMP = 1518699600;  

    uint256 public appreciationRateWei;
    uint32 public cratesSold;
    uint256 public currentPrice;

     
    uint32 public oldCratesSold;
    uint256 public oldPrice;
    uint256 public oldAppreciationRateWei;
     
    

     
     
    mapping (address => uint[]) public addressToPurchasedBlocks;
     
     
     
    mapping (address => uint) public expiredCrates;
     



    function openAll() public {
        uint len = addressToPurchasedBlocks[msg.sender].length;
        require(len > 0);
        uint8 count = 0;
         
        for (uint i = len - 1; i >= 0 && len > i; i--) {
            uint crateBlock = addressToPurchasedBlocks[msg.sender][i];
            require(block.number > crateBlock);
             
            var hash = block.blockhash(crateBlock);
            if (uint(hash) != 0) {
                 
                 
                uint rand = uint(keccak256(hash, msg.sender, i)) % (10 ** 20);
                userToRobots[msg.sender].push(rand);
                count++;
            } else {
                 
                expiredCrates[msg.sender] += (i + 1);
                break;
            }
        }
        CratesOpened(msg.sender, count);
        delete addressToPurchasedBlocks[msg.sender];
    }

     
    event CratesPurchased(address indexed _from, uint8 _quantity);
    event CratesOpened(address indexed _from, uint8 _quantity);

     
    function getPrice() view public returns (uint256) {
        return currentPrice;
    }

    function getRobotCountForUser(address _user) external view returns(uint256) {
        return userToRobots[_user].length;
    }

    function getRobotForUserByIndex(address _user, uint _index) external view returns(uint) {
        return userToRobots[_user][_index];
    }

    function getRobotsForUser(address _user) view public returns (uint[]) {
        return userToRobots[_user];
    }

    function getPendingCratesForUser(address _user) external view returns(uint[]) {
        return addressToPurchasedBlocks[_user];
    }

    function getPendingCrateForUserByIndex(address _user, uint _index) external view returns(uint) {
        return addressToPurchasedBlocks[_user][_index];
    }

    function getExpiredCratesForUser(address _user) external view returns(uint) {
        return expiredCrates[_user];
    }

    function incrementPrice() private {
         
         
         
         
        if ( currentPrice == 100000000000000000 ) {
            appreciationRateWei = 200000000000000;
        } else if ( currentPrice == 200000000000000000) {
            appreciationRateWei = 100000000000000;
        } else if (currentPrice == 300000000000000000) {
            appreciationRateWei = 50000000000000;
        }
        currentPrice += appreciationRateWei;
    }

    function purchaseCrates(uint8 _cratesToBuy) public payable whenNotPaused {
        require(now < PRESALE_END_TIMESTAMP);  
        require(_cratesToBuy <= 10);  
        require(_cratesToBuy >= 1);  
        require(cratesSold + _cratesToBuy <= MAX_CRATES_TO_SELL);  
        uint256 priceToPay = _calculatePayment(_cratesToBuy);
         require(msg.value >= priceToPay);  
        if (msg.value > priceToPay) {  
            msg.sender.transfer(msg.value-priceToPay);
        }
         
        cratesSold += _cratesToBuy;
      for (uint8 i = 0; i < _cratesToBuy; i++) {
            incrementPrice();
            addressToPurchasedBlocks[msg.sender].push(block.number);
        }

        CratesPurchased(msg.sender, _cratesToBuy);
    } 

    function _calculatePayment (uint8 _cratesToBuy) private view returns (uint256) {
        
        uint256 tempPrice = currentPrice;

        for (uint8 i = 1; i < _cratesToBuy; i++) {
            tempPrice += (currentPrice + (appreciationRateWei * i));
        }  
           
           
        
        return tempPrice;
    }


     
    function withdraw() onlyOwner public {
        owner.transfer(this.balance);
    }

    function addFunds() onlyOwner external payable {

    }

  event SetPaused(bool paused);

   
  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() external onlyOwner whenNotPaused returns (bool) {
    paused = true;
    SetPaused(paused);
    return true;
  }

  function unpause() external onlyOwner whenPaused returns (bool) {
    paused = false;
    SetPaused(paused);
    return true;
  }


  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




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