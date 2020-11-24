 

pragma solidity ^0.4.23;

 

contract WheelOfEther {
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

     

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 ethereumIn,
        uint256 contractBal,
        uint timestamp
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 ethereumOut,
        uint256 contractBal,
        uint timestamp
    );

    event spinResult(
        address indexed customerAddress,
        uint256 wheelNumber,
        uint256 outcome,
        uint256 ethSpent,
        uint256 ethReturned,
        uint256 devFee,
        uint timestamp
    );

    uint256 _seed;
    address admin;
    bool public gamePaused = false;
    uint256 minBet = 0.01 ether;
    uint256 devFeeBalance = 0;

    uint8[10] brackets = [1,3,6,12,24,40,56,68,76,80];

    uint256 internal globalFactor = 1000000000000000000000;
    uint256 constant internal constantFactor = globalFactor * globalFactor;
    mapping(address => uint256) internal personalFactorLedger_;
    mapping(address => uint256) internal balanceLedger_;


    constructor()
        public
    {
        admin = msg.sender;
    }


    function getBalance()
        public
        view
        returns (uint256)
    {
        return this.balance;
    }


    function buyTokens()
        public
        payable
        nonContract
        gameActive
    {
        address _customerAddress = msg.sender;
         
        require(msg.value >= minBet);
         
        balanceLedger_[_customerAddress] = ethBalanceOf(_customerAddress).add(msg.value);
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

        onTokenPurchase(_customerAddress, msg.value, this.balance, now);
    }


    function sell(uint256 sellEth)
        public
        nonContract
    {
        address _customerAddress = msg.sender;
         
        require(sellEth <= ethBalanceOf(_customerAddress));
        require(sellEth > 0);
         
        _customerAddress.transfer(sellEth);
        balanceLedger_[_customerAddress] = ethBalanceOf(_customerAddress).sub(sellEth);
		personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

        onTokenSell(_customerAddress, sellEth, this.balance, now);
    }


    function ethBalanceOf(address _customerAddress)
        public
        view
        returns (uint256)
    {
         
        return balanceLedger_[_customerAddress].mul(personalFactorLedger_[_customerAddress]).mul(globalFactor) / constantFactor;
    }


    function tokenSpin(uint256 betEth)
        public
        nonContract
        gameActive
        returns (uint256 resultNum)
    {
        address _customerAddress = msg.sender;
         
        require(ethBalanceOf(_customerAddress) >= betEth);
         
        if (betEth > betPool(_customerAddress)) {
            betEth = betPool(_customerAddress);
        }
         
        require(betEth >= minBet);
         
        resultNum = bet(betEth, _customerAddress);
    }


    function etherSpin()
        public
        payable
        nonContract
        gameActive
        returns (uint256 resultNum)
    {
        address _customerAddress = msg.sender;
        uint256 betEth = msg.value;
         
         
        if (betEth > betPool(_customerAddress)) {
            betEth = betPool(_customerAddress);
        }
         
        require(betEth >= minBet);
         
        balanceLedger_[_customerAddress] = ethBalanceOf(_customerAddress).add(msg.value);
		personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;
         
        resultNum = bet(betEth, _customerAddress);
    }


    function betPool(address _customerAddress)
        public
        view
        returns (uint256)
    {
         
        return this.balance.sub(ethBalanceOf(_customerAddress)).sub(devFeeBalance);
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
        uint256 sellEth = ethBalanceOf(_customerAddress);
        _customerAddress.transfer(sellEth);
        balanceLedger_[_customerAddress] = 0;
		personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;
        onTokenSell(_customerAddress, sellEth, this.balance, now);
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
        onlyAdmin
    {
        admin.transfer(devFeeBalance);
        devFeeBalance = 0;
    }


     


    function bet(uint256 initEth, address _customerAddress)
        internal
        returns (uint256 resultNum)
    {
         
        resultNum = random(80);
         
        uint result = determinePrize(resultNum);

         
        uint256 devFee = initEth / 50;
        devFeeBalance = devFeeBalance.add(devFee);
        balanceLedger_[_customerAddress] = ethBalanceOf(_customerAddress).sub(devFee);
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;

         
        uint256 betEth = initEth - devFee;

        uint256 returnedEth;
        uint256 prizePool = betPool(_customerAddress);

		if (result < 5)                                              
		{
			uint256 wonEth;
			if (result == 0){                                        
				wonEth = grandJackpot(betEth, prizePool);
			} else if (result == 1){                                 
				wonEth = jackpot(betEth, prizePool);
			} else if (result == 2){                                 
				wonEth = betEth / 2;                                 
			} else if (result == 3){                                 
				wonEth = betEth / 4;                                 
			} else if (result == 4){                                 
				wonEth = betEth / 10;                                
			}
			winEth(_customerAddress, wonEth);                        
            returnedEth = betEth.add(wonEth);
        } else if (result == 5){                                     
            returnedEth = betEth;
		}
		else {                                                       
			uint256 lostEth;
			if (result == 6){                                		 
				lostEth = betEth / 4;                    		     
			} else if (result == 7){                                 
				lostEth = betEth / 2;                     			 
			} else if (result == 8){                                 
				lostEth = betEth.mul(3) / 4;                     	 
			} else if (result == 9){                                 
				lostEth = betEth;                                    
			}
			loseEth(_customerAddress, lostEth);                      
            returnedEth = betEth.sub(lostEth);
		}
        spinResult(_customerAddress, resultNum, result, betEth, returnedEth, devFee, now);
        return resultNum;
    }

    function grandJackpot(uint256 betEth, uint256 prizePool)
        internal
        returns (uint256 wonEth)
    {
        wonEth = betEth / 2;                                         
        uint256 max = minBet * 100 * betEth / prizePool;             
		for (uint256 i=0;i<max; i+= minBet) {			  	         
            wonEth = wonEth.add((prizePool.sub(wonEth)) / 50);       
		}
    }

    function jackpot(uint256 betEth, uint256 prizePool)
        internal
        returns (uint256 wonEth)
    {
        wonEth = betEth / 2;                                         
        uint256 max = minBet * 100 * betEth / prizePool;             
		for (uint256 i=0;i<max; i+= minBet) {                        
            wonEth = wonEth.add((prizePool.sub(wonEth)) / 100);      
		}
    }

    function maxRandom()
        internal
        returns (uint256 randomNumber)
    {
        _seed = uint256(keccak256(
            abi.encodePacked(_seed,
                blockhash(block.number - 1),
                block.coinbase,
                block.difficulty)
        ));
        return _seed;
    }


    function random(uint256 upper)
        internal
        returns (uint256 randomNumber)
    {
        return maxRandom() % upper + 1;
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


    function loseEth(address _customerAddress, uint256 lostEth)
        internal
    {
        uint256 customerEth = ethBalanceOf(_customerAddress);
         
        uint256 globalIncrease = globalFactor.mul(lostEth) / betPool(_customerAddress);
        globalFactor = globalFactor.add(globalIncrease);
         
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;
        balanceLedger_[_customerAddress] = customerEth.sub(lostEth);
    }


    function winEth(address _customerAddress, uint256 wonEth)
        internal
    {
        uint256 customerEth = ethBalanceOf(_customerAddress);
         
        uint256 globalDecrease = globalFactor.mul(wonEth) / betPool(_customerAddress);
        globalFactor = globalFactor.sub(globalDecrease);
         
        personalFactorLedger_[_customerAddress] = constantFactor / globalFactor;
        balanceLedger_[_customerAddress] = customerEth.add(wonEth);
    }
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
          return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}