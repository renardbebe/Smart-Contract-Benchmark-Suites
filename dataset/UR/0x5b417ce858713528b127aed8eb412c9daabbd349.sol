 

 

pragma solidity ^0.5.3;

 


contract ERC20Interface
{
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    


    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract WheelOfShuffle {
    using SafeMath for uint;

     

    modifier nonContract() {                 
        require(tx.origin == msg.sender);
        _;
    }

    modifier gameActive() {
        require(gamePaused == false);
        _;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }

     

    event onDeposit(
        address indexed customerAddress,
        uint256 tokensIn,
        uint256 contractBal,
        uint256 devFee,
        uint timestamp
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 tokensOut,
        uint256 contractBal,
        uint timestamp
    );

    event spinResult(
        address indexed customerAddress,
        uint256 wheelNumber,
        uint256 outcome,
        uint256 tokensSpent,
        uint256 tokensReturned,
        uint256 userBalance,
        uint timestamp
    );

    uint256 _seed;
    address admin;
    bool public gamePaused = false;
    uint256 minBet =1000000000000000000;
    uint256 maxBet = 500000000000000000000;
    uint256 devFeeBalance = 0;

    uint8[10] brackets = [1,3,6,12,24,40,56,68,76,80];

    struct playerSpin {
        uint256 betAmount;
        uint48 blockNum;
    }

    mapping(address => playerSpin) public playerSpins;
    mapping(address => uint256) internal personalFactorLedger_;
    mapping(address => uint256) internal balanceLedger_;

    uint256 internal globalFactor = 10e21;
    uint256 constant internal constantFactor = 10e21 * 10e21;
    address public tokenAddress = 0x3A9FfF453d50D4Ac52A6890647b823379ba36B9E;

    constructor()
        public
    {
        admin = msg.sender;
    }


    function getBalance()
        public
        view
        returns (uint)
    {
        return ERC20Interface(tokenAddress).balanceOf(tokenAddress);
    }


     
    function deposit(address _customerAddress, uint256 amount)
        public
        gameActive
    {
        require(tx.origin == _customerAddress);
        require(amount >= (minBet * 2));
        require(ERC20Interface(tokenAddress).transferFrom(_customerAddress, tokenAddress, amount), "token transfer failed");
         
        uint256 devFee = amount / 10;
        devFeeBalance = devFeeBalance.add(devFee);
         
        balanceLedger_[_customerAddress] = tokenBalanceOf(_customerAddress).add(amount).sub(devFee);
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

        emit onDeposit(_customerAddress, amount, getBalance(), devFee, now);
    }


    function receiveApproval(address receiveFrom, uint256 amount, uint256 data)
      public
    {

    }


     
    function withdraw(uint256 amount)
      public
    {
        address _customerAddress = msg.sender;
        require(amount <= tokenBalanceOf(_customerAddress));
        require(amount > 0);
        if(!ERC20Interface(tokenAddress).transfer(_customerAddress, amount))
            revert();
        balanceLedger_[_customerAddress] = tokenBalanceOf(_customerAddress).sub(amount);
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;
        emit onWithdraw(_customerAddress, amount, getBalance(), now);
    }


    function withdrawAll()
        public
    {
        address _customerAddress = msg.sender;
         
        uint256 amount = tokenBalanceOf(_customerAddress);
        require(amount > 0);
         
        if(!ERC20Interface(tokenAddress).transfer(_customerAddress, amount))
            revert();
        balanceLedger_[_customerAddress] = 0;
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;
        emit onWithdraw(_customerAddress, amount, getBalance(), now);
    }


    function tokenBalanceOf(address _customerAddress)
        public
        view
        returns (uint256)
    {
         
        return balanceLedger_[_customerAddress].mul(personalFactorLedger_[_customerAddress]).mul(globalFactor) / constantFactor;
    }


    function spinTokens(uint256 betAmount)
        public
        nonContract
        gameActive
    {
        address _customerAddress = msg.sender;
         
        require(tokenBalanceOf(_customerAddress) >= betAmount);
         
        require(betAmount >= minBet);
         
        if (betAmount > maxBet){
            betAmount = maxBet;
        }
         
        if (betAmount > betPool(_customerAddress)/10) {
            betAmount = betPool(_customerAddress)/10;
        }
         
        startSpin(betAmount, _customerAddress);
    }


    function spinAll()
        public
        nonContract
        gameActive
    {
        address _customerAddress = msg.sender;
         
        uint256 betAmount = tokenBalanceOf(_customerAddress);
         
        if (betAmount > betPool(_customerAddress)/10) {
            betAmount = betPool(_customerAddress)/10;
        }
         
        require(betAmount >= minBet);
         
        if (betAmount >= maxBet){
            betAmount = maxBet;
        }
         
        startSpin(betAmount, _customerAddress);
    }


     
    function depositAndSpin(address _customerAddress, uint256 betAmount)
        public
        gameActive
    {
        require(tx.origin == _customerAddress);
        require(betAmount >= (minBet * 2));
        require(ERC20Interface(tokenAddress).transferFrom(_customerAddress, tokenAddress, betAmount), "token transfer failed");
         
        uint256 devFee = betAmount / 10;
        devFeeBalance = devFeeBalance.add(devFee);
         
        balanceLedger_[_customerAddress] = tokenBalanceOf(_customerAddress).add(betAmount).sub(devFee);
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

        emit onDeposit(_customerAddress, betAmount, getBalance(), devFee, now);

        betAmount = betAmount.sub(devFee);
         
        if (betAmount >= maxBet){
            betAmount = maxBet;
        }
         
        if (betAmount > betPool(_customerAddress)/10) {
            betAmount = betPool(_customerAddress)/10;
        }
         
        startSpin(betAmount, _customerAddress);
    }


    function betPool(address _customerAddress)
        public
        view
        returns (uint256)
    {
         
        return getBalance().sub(tokenBalanceOf(_customerAddress)).sub(devFeeBalance);
    }

     

    function panicButton(bool newStatus)
        public
        onlyAdmin
    {
        gamePaused = newStatus;
    }


    function refundUser(address _customerAddress)
        public
        onlyAdmin
    {
        uint256 withdrawAmount = tokenBalanceOf(_customerAddress);
        if(!ERC20Interface(tokenAddress).transfer(_customerAddress, withdrawAmount))
            revert();
        balanceLedger_[_customerAddress] = 0;
	      personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;
        emit onWithdraw(_customerAddress, withdrawAmount, getBalance(), now);
    }


    function updateMinBet(uint256 newMin)
        public
        onlyAdmin
    {
        require(newMin > 0);
        minBet = newMin;
    }


    function updateMaxBet(uint256 newMax)
        public
        onlyAdmin
    {
        require(newMax > 0);
        maxBet = newMax;
    }


    function getDevBalance()
        public
        view
        returns (uint256)
    {
        return devFeeBalance;
    }


    function withdrawDevFees()
        public
    {
        address fund = 0xba111Ab673241d8f7C71029e8225529332D76735;
        uint256 initDevBal = devFeeBalance;
        if(!ERC20Interface(tokenAddress).transfer(fund, devFeeBalance/2))
          revert();
        devFeeBalance = devFeeBalance.sub(initDevBal/2);
  }


    function finishSpin(address _customerAddress)
        public
        returns (uint256)
    {
        return _finishSpin(_customerAddress);
    }


     


    function startSpin(uint256 betAmount, address _customerAddress)
        internal
    {
        playerSpin memory spin = playerSpins[_customerAddress];
        require(block.number != spin.blockNum);

        if (spin.blockNum != 0) {
            _finishSpin(_customerAddress);
        }
        lose(_customerAddress, betAmount);
        playerSpins[_customerAddress] = playerSpin(uint256(betAmount), uint48(block.number));
    }


    function _finishSpin(address _customerAddress)
        internal
        returns (uint256 resultNum)
    {
        playerSpin memory spin = playerSpins[_customerAddress];
        require(block.number != spin.blockNum);

        uint result;
        if (block.number - spin.blockNum > 255) {
            resultNum = 80;
            result = 9;  
            return resultNum;
        } else {
            resultNum = random(80, spin.blockNum, _customerAddress);
            result = determinePrize(resultNum);
        }

        uint256 betAmount = spin.betAmount;
        uint256 returnedAmount;

        if (result < 5)                                              
        {
            uint256 wonAmount;
            if (result == 0){                                        
                wonAmount = betAmount.mul(9) / 10;                   
            } else if (result == 1){                                 
                wonAmount = betAmount.mul(8) / 10;                   
            } else if (result == 2){                                 
                wonAmount = betAmount.mul(7) / 10;                   
            } else if (result == 3){                                 
                wonAmount = betAmount.mul(6) / 10;                   
            } else if (result == 4){                                 
                wonAmount = betAmount.mul(3) / 10;                   
            }
            returnedAmount = betAmount.add(wonAmount);
        } else if (result == 5){                                     
            returnedAmount = betAmount;
        } else {                                                     
            uint256 lostAmount;
            if (result == 6){                                	     
                lostAmount = betAmount / 10;                         
            } else if (result == 7){                                 
                lostAmount = betAmount / 4;                          
            } else if (result == 8){                                 
                lostAmount = betAmount / 2;                     	 
            } else if (result == 9){                                 
                lostAmount = betAmount;                              
            }
            returnedAmount = betAmount.sub(lostAmount);
        }
        if (returnedAmount > 0) {
            win(_customerAddress, returnedAmount);                   
        }
        uint256 newBal = tokenBalanceOf(_customerAddress);
        emit spinResult(_customerAddress, resultNum, result, betAmount, returnedAmount, newBal, now);

        playerSpins[_customerAddress] = playerSpin(uint256(0), uint48(0));

        return resultNum;
    }


    function maxRandom(uint blockn, address entropy)
        internal
        returns (uint256 randomNumber)
    {
        return uint256(keccak256(
            abi.encodePacked(
              blockhash(blockn),
              entropy)
        ));
    }


    function random(uint256 upper, uint256 blockn, address entropy)
        internal
        returns (uint256 randomNumber)
    {
        return maxRandom(blockn, entropy) % upper + 1;
    }


    function determinePrize(uint256 result)
        internal
        returns (uint256 resultNum)
    {
         
        for (uint8 i=0;i<=9;i++){
            if (result <= brackets[i]){
                return i;
            }
        }
    }


    function lose(address _customerAddress, uint256 lostAmount)
        internal
    {
        uint256 customerBal = tokenBalanceOf(_customerAddress);
         
        uint256 globalIncrease = globalFactor.mul(lostAmount) / betPool(_customerAddress);
        globalFactor = globalFactor.add(globalIncrease);
         
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;
         
        if (lostAmount > customerBal){
            lostAmount = customerBal;
        }
        balanceLedger_[_customerAddress] = customerBal.sub(lostAmount);
    }


    function win(address _customerAddress, uint256 wonAmount)
        internal
    {
        uint256 customerBal = tokenBalanceOf(_customerAddress);
         
        uint256 globalDecrease = globalFactor.mul(wonAmount) / betPool(_customerAddress);
        globalFactor = globalFactor.sub(globalDecrease);
         
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;
        balanceLedger_[_customerAddress] = customerBal.add(wonAmount);
    }
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal view returns (uint256 c) {
        if (a == 0) {
          return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal view returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal view returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal view returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}