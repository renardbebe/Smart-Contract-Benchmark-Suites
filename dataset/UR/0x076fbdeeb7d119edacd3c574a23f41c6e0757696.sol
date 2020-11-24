 

pragma solidity ^0.4.24;

 


contract TreasureHunt {
    using SafeMath for uint;


    event Winner(
        address customerAddress,
        uint256 amount
    );

    event Bet(
        address customerAddress,
        uint256 number
    );

     event Restart(
        uint256 number
    );
    
    mapping (uint8 => address[]) playersByNumber ;
    mapping (bytes32 => bool) gameNumbers;
    mapping (bytes32 => bool) prizeNumbers;
    mapping (uint8 => bool) Prizes;
    mapping (uint8 => bool) PrizeLocations;
    mapping (uint8 => bool) usedNumbers;


    uint8[] public numbers;
    uint8[] public PrizeNums;
    bytes32[] public prizeList;
    uint public lastNumber;

    bytes32[101] bytesArray;

    uint public gameCount = 1;

    uint public minBet = 0.1 ether;
    uint public jackpot = 0;
    uint8 public prizeCount = 0;

    uint8 public prizeMax = 10;

    uint public houseRate = 40;   
    uint public referralRate = 100;  

    uint8 public numberCount = 0;
    uint maxNum = 100;

    uint8 maxPrizeNum = 5;

    
    address owner;
    
    constructor() public {
        owner = msg.sender;

        prizeCount = 0;
        gameCount = gameCount + 1;
        numberCount = 0;
        for (uint8 i = 1; i<maxNum+1; i++) {
            bytesArray[i] = 0x0;
            usedNumbers[i] = false;
        }
       
    }


    function contains(uint8 number) public view returns (bool){
        return usedNumbers[number];
    }

    function enterNumber(uint8 number, address _referrer) payable public {
         

        require(!contains(number));
        require(msg.value >= minBet);
        require(number <= maxNum+1);

        numberCount += 1;
        

        uint betAmount = msg.value;

        uint houseFee = SafeMath.div(SafeMath.mul(betAmount, houseRate),1000);

        owner.transfer(houseFee);

        betAmount = SafeMath.sub(betAmount,houseFee);


        if(
         
            _referrer != 0x0000000000000000000000000000000000000000 &&
            _referrer != msg.sender)
            {
                uint refFee = SafeMath.div(SafeMath.mul(betAmount, referralRate),1000);
                
                _referrer.transfer(refFee);
                betAmount = SafeMath.sub(betAmount,refFee);
            }

        uint8 checkPrize = random();
        jackpot = address(this).balance;
        if (number == checkPrize||number == checkPrize+10||number == checkPrize+20||number == checkPrize+30||number == checkPrize+40||number == checkPrize+50||number == checkPrize+60||number == checkPrize+70||number == checkPrize+80||number == checkPrize+90) {
        
                prizeCount = prizeCount + 1;
                payout(prizeCount);
                bytesArray[number] = 0x2;
  
        } else {
            bytesArray[number] = 0x1;
        }

         
        numbers.push(number);
        usedNumbers[number] = true;
         

        emit Bet(msg.sender, number);

        if (numberCount >= maxNum-1) {
            restartGame();
        }
        
    }

    function payout(uint8 prizeNum)  {

        uint winAmount = 0;
        jackpot = address(this).balance;
         
         
         

        uint prizelevel = randomPrize();
        
        if (prizelevel == 1){    

            winAmount = SafeMath.div(SafeMath.mul(jackpot,10),100);
            msg.sender.transfer(winAmount);

        } else if (prizelevel == 2) {

            winAmount = SafeMath.div(SafeMath.mul(jackpot,20),100);
            msg.sender.transfer(winAmount);

        } else if (prizelevel == 3) {

            winAmount = SafeMath.div(SafeMath.mul(jackpot,30),100);
            msg.sender.transfer(winAmount);

        } else if (prizelevel == 4) {

            winAmount = SafeMath.div(SafeMath.mul(jackpot,40),100);
            msg.sender.transfer(winAmount);

        } else if (prizelevel >= 5) {

            winAmount = SafeMath.div(SafeMath.mul(jackpot,70),100);
            msg.sender.transfer(winAmount);
            

        }

         
         
         

        emit Winner(msg.sender,winAmount);
        
    }

    function restartGame() internal {
         
        prizeCount = 0;
        delete numbers;
        delete PrizeNums;
        delete bytesArray;
         
        gameCount = gameCount + 1;
        numberCount = 0;
        for (uint8 i = 0; i<101; i++) {
             
            usedNumbers[i] = false;
        }
        emit Restart(gameCount);
    }


  function restartRemote() public {
         
        require(msg.sender == owner);
        prizeCount = 0;
        delete numbers;
        delete PrizeNums;
        delete bytesArray;
         
        gameCount = gameCount + 1;
        numberCount = 0;
        for (uint8 i = 0; i<101; i++) {
             
            usedNumbers[i] = false;
        }
        emit Restart(gameCount);
    }

    function random() private view returns (uint8) {



        uint8 prize = uint8(uint256(keccak256(block.timestamp, block.difficulty)) % prizeMax) + 1;

        PrizeNums.push(prize);

        return(prize);

 
    }

    function randomPrize() private view returns (uint8) {



        uint8 prizeLevel = uint8(uint256(keccak256(block.timestamp, block.difficulty)) % 5) + 1;

        return(prizeLevel);

 
    }

    function jackpotDeposit() public payable 
    {

    }

    function prizeContains(uint8 number) returns (uint8){
        return PrizeNums[number];
    }

    function getArray() constant returns (bytes32[101])
    {
        return bytesArray;
    }

    function getValue(uint8 x) constant returns (bytes32)
    {
        return bytesArray[x];
    }

    function setMaxPrizeNum(uint8 maxNum) public
    {
        require(msg.sender == owner);
        maxPrizeNum = maxNum;
    }



    function getPrize(uint8 x) constant returns (uint8)
        {
            return PrizeNums[x];
        }

    function getPrizeNumber(bytes32 x) constant returns (bool)
        {
            return prizeNumbers[x];
        }

    function getEthValue() public view returns (uint)
    {
        return address(this).balance;
    } 
    
}


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}