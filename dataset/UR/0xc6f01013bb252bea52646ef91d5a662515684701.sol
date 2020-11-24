 

pragma solidity ^0.4.18;

 
 
 
 
 


 
 
 
 
 
 
 

contract SpermLabsReborn {

    uint256 public CELLS_TO_MAKE_1_SPERM = 86400;
    uint256 public STARTING_SPERM = 500;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public initialized = false;
    address public spermlordAddress;
    uint256 public spermlordReq = 500000;  
    mapping (address => uint256) public ballSperm;
    mapping (address => uint256) public claimedCells;
    mapping (address => uint256) public lastEvent;
    mapping (address => address) public referrals;
    uint256 public marketCells;

    function SpermLabsReborn() public {
        spermlordAddress = msg.sender;
    }

    function makeSperm(address ref) public {
        require(initialized);

        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }

        uint256 cellsUsed = getMyCells();
        uint256 newSperm = SafeMath.div(cellsUsed, CELLS_TO_MAKE_1_SPERM);
        ballSperm[msg.sender] = SafeMath.add(ballSperm[msg.sender], newSperm);
        claimedCells[msg.sender] = 0;
        lastEvent[msg.sender] = now;
        
         
        claimedCells[referrals[msg.sender]] = SafeMath.add(claimedCells[referrals[msg.sender]], SafeMath.div(cellsUsed, 5));  
        
         
        marketCells = SafeMath.add(marketCells, SafeMath.div(cellsUsed, 10));  
    }

    function sellCells() public {
        require(initialized);

        uint256 cellCount = getMyCells();
        uint256 cellValue = calculateCellSell(cellCount);
        uint256 fee = devFee(cellValue);
        
         
        ballSperm[msg.sender] = SafeMath.mul(SafeMath.div(ballSperm[msg.sender], 3), 2);  
        claimedCells[msg.sender] = 0;
        lastEvent[msg.sender] = now;

         
        marketCells = SafeMath.add(marketCells, cellCount);

         
        spermlordAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(cellValue, fee));
    }

    function buyCells() public payable {
        require(initialized);

        uint256 cellsBought = calculateCellBuy(msg.value, SafeMath.sub(this.balance, msg.value));
        cellsBought = SafeMath.sub(cellsBought, devFee(cellsBought));
        claimedCells[msg.sender] = SafeMath.add(claimedCells[msg.sender], cellsBought);

         
        spermlordAddress.transfer(devFee(msg.value));
    }

     
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
         
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

    function calculateCellSell(uint256 cells) public view returns(uint256) {
        return calculateTrade(cells, marketCells, this.balance);
    }

    function calculateCellBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketCells);
    }

    function calculateCellBuySimple(uint256 eth) public view returns(uint256) {
        return calculateCellBuy(eth, this.balance);
    }

    function devFee(uint256 amount) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 4), 100);  
    }

    function seedMarket(uint256 cells) public payable {
        require(marketCells == 0);

        initialized = true;
        marketCells = cells;
    }

    function getFreeSperm() public payable {
        require(initialized);
        require(msg.value == 0.001 ether);  
        spermlordAddress.transfer(msg.value);  

        require(ballSperm[msg.sender] == 0);
        lastEvent[msg.sender] = now;
        ballSperm[msg.sender] = STARTING_SPERM;
    }

    function getBalance() public view returns(uint256) {
        return this.balance;
    }

    function getMySperm() public view returns(uint256) {
        return ballSperm[msg.sender];
    }

    function becomeSpermlord() public {
        require(initialized);
        require(msg.sender != spermlordAddress);
        require(ballSperm[msg.sender] >= spermlordReq);

        ballSperm[msg.sender] = SafeMath.sub(ballSperm[msg.sender], spermlordReq);
        spermlordReq = ballSperm[msg.sender];  
        spermlordAddress = msg.sender;
    }

    function getSpermlordReq() public view returns(uint256) {
        return spermlordReq;
    }

    function getMyCells() public view returns(uint256) {
        return SafeMath.add(claimedCells[msg.sender], getCellsSinceLastEvent(msg.sender));
    }

    function getCellsSinceLastEvent(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(CELLS_TO_MAKE_1_SPERM, SafeMath.sub(now, lastEvent[adr]));
        return SafeMath.mul(secondsPassed, ballSperm[adr]);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
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