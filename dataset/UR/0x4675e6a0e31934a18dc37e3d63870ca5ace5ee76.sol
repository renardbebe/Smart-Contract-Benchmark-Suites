 

pragma solidity >=0.4.22 <0.6.0;

contract Ownable {
    address payable public owner;
    address payable public developer;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
         
        owner = msg.sender;
        developer = 0x67264cB47c717838Ae684F22E686d6f35dA90981;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner Can Do This");
        _;
    }

    modifier onlyDeveloper() {
        require(msg.sender == developer, "Only Developer Can Do This");
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function renounceDevelopership() public onlyDeveloper {
         
        developer = address(0);
    }

     
    function transferOwnership(address payable _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function transferDevelopership(address payable _newDeveloper) public onlyDeveloper {
        require(_newDeveloper != address(0), "New Developer's Address is Required");
         
        developer = _newDeveloper;
    }

     
    function _transferOwnership(address payable _newOwner) internal {
        require(_newOwner != address(0), "New Owner's Address is Required");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
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

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Fishbowl is Ownable ,Pausable{

    using SafeMath for uint;

    uint[9] fishBowlSize = [0,2000,3000,4000,7000,9000,10000,14000,17000];  
    uint[9] fishBowlLevelByAmount = [0,1,5,10,30,50,100,150,200];  
    address private playerBookAddress;

    event setPlayerBookAddrEvent(address _newPlayerBookAddr, uint _time);

    constructor(address _playerBookAddress) public{
        playerBookAddress = _playerBookAddress;
    }

     
    modifier onlyForPlayerBook(){
         
        _;
    }

     
    function fishBowl(uint _totalFishPrice, uint _fishAmount)
    public view onlyForPlayerBook returns(uint fishbowlLevel, uint fishbowlSize, uint admissionPrice, uint amountToSale)
    {
        uint _fishbowlLevel = getFishBowlLevel(_fishAmount);
        uint _fishbowlSize = getFishbowlSize(_fishbowlLevel);
        uint _admissionPrice = getAdmissionPrice(_totalFishPrice);
        uint _amountToSale = getAmountToSale(_fishbowlLevel, _admissionPrice);

        return (_fishbowlLevel, _fishbowlSize, _admissionPrice, _amountToSale);
    }

     
    function multipleBuy(uint _totalFishPrice, uint _oldAdmissionPrice, uint _oldAmountToSale)
    public view onlyForPlayerBook returns(uint newAdmissionPrice, uint newAmountToSale)
    {
        uint _admissionPrice = getAdmissionPrice(_totalFishPrice);
        uint _newAdmissionPrice = _admissionPrice.add(_oldAdmissionPrice);
        uint _newAmountToSale = getAmountToSale(8, _admissionPrice).add(_oldAmountToSale);

        return (_newAdmissionPrice, _newAmountToSale);
    }

     
    function getFishBowlLevel(uint _fishAmount) public view onlyForPlayerBook returns(uint fishbowlLevel){
        for(uint i = 0; i < 9; i++){
            if( _fishAmount == fishBowlLevelByAmount[i]){
                return i;
            }
        }
    }

     
    function getFodderFee(uint _fishPrice, uint _fishAmount) public pure onlyForPlayerBook returns(uint fodderFee){
        return _fishPrice.mul(_fishAmount);
    }

     
    function getFishbowlSize(uint _fishbowlLevel) public view onlyForPlayerBook returns(uint fishbowlSize){
        return fishBowlSize[_fishbowlLevel];
    }

     
    function getAdmissionPrice(uint _totalFishPrice) public pure onlyForPlayerBook returns(uint admissionPrice){
        return _totalFishPrice.mul(2);
    }

     
    function getAmountToSale(uint _fishbowlLevel, uint _admissionPrice)
    public view onlyForPlayerBook returns(uint amountToSale)
    {
        return _admissionPrice.mul(getFishbowlSize(_fishbowlLevel));
    }

     
    function setPlayerBookAddr(address _newPlayerBookAddr) public onlyOwner{
        playerBookAddress = _newPlayerBookAddr;

        emit setPlayerBookAddrEvent(_newPlayerBookAddr, now);
    }

     
    function getPlayerBookAddr() public view returns(address _playerBookAddress){
        return playerBookAddress;
    }

}

contract TransactionSystem is Ownable{
	using SafeMath for uint;
	using SafeMath for int;

	struct GlobalData {
		uint fishAmount;  
		uint fishPrice;
		uint systemTotalFishAmount;  
		uint selledAmount;  
		uint[7] priceInterval;
	}

	struct PlayerSellOrderData {
		address payable owner;
		uint fishAmount;
		uint fishPrice;
		uint round;
	}

	struct Queue{
		uint[] idList;
		uint front;
	}

	 
	uint constant public INIT_FISHAMOUNT = 10000;
	uint constant public INIT_FISHPRICE = 50 finney;  
	 
	
	 
	GlobalData globalData;

	 
	PlayerBook playerBook = PlayerBook(0x0);
	address payable public playerBookAddress;

	 
	mapping(uint => uint) private priceTotalFishAmount;  
	mapping(uint => Queue) public sellOrderSequence;  

	 
	mapping(address => uint) private personSellOrders;  

	 
	PlayerSellOrderData[] private sellOrders;  

	 
	mapping(uint => uint) systemFishAmount;  
	uint systemFishPriceCumulativeCount;

	 
	bool public isFleshUp;  
	uint public fleshUpCount;  
	bool public haveFish;  

	 
	uint[] private reproductionBlockNumbers;

	event changePriceEvent(address indexed _contract, uint indexed _price, uint _timestamp);
	event orderEvent(address indexed _from, uint _amount, uint _timestamp);
	event fleshUpEvent(uint _price, uint fleshUpCount, uint _timestamp);

	 
	constructor() public {
		globalData = GlobalData({
			fishAmount: INIT_FISHAMOUNT,
			fishPrice: INIT_FISHPRICE,
			systemTotalFishAmount: 0,
			selledAmount: 0,
			priceInterval: [uint256(50 finney), uint256(51 finney), uint256(52 finney), uint256(53 finney), uint256(54 finney), uint256(55 finney), uint256(56 finney)]
			 
		});
		isFleshUp = false;
		 
		 
		globalData.systemTotalFishAmount = INIT_FISHAMOUNT;
		 
		for (uint orderPrice = INIT_FISHPRICE; orderPrice < INIT_FISHPRICE.add(7 finney); orderPrice = orderPrice.add(1 finney)) {
			systemFishAmount[orderPrice] = 200;
		} 
		reproductionBlockNumbers.push(0);
		systemFishPriceCumulativeCount = 56 finney;  
		 
	}

	 
	modifier onlyPlayerBook() {
		require(msg.sender == playerBookAddress);
		_;
	}

	 
	function() payable external{
		playerBookAddress.transfer(msg.value);
	}

	
	 
	 
	function addNewBuyOrder(address payable _buyer, uint _fishAmount, uint _balance, bool _isRebuy)
		public
		onlyPlayerBook()
	{
		 
		 

		 
		 
		 
		uint totalCost = 0;  
		uint _addFishAmount = 0;  
		uint _tempRound = playerBook.reproductionRound();

		Queue storage Q = sellOrderSequence[globalData.fishPrice];
		while(_fishAmount > 0){ 
			 
			if(systemFishAmount[globalData.fishPrice] > 0){ 
				 
				if(_fishAmount <= systemFishAmount[globalData.fishPrice]){
					 
					_addFishAmount = _addFishAmount.add(_fishAmount);
					 
					_balance = _balance.sub(_fishAmount.mul(globalData.fishPrice));
					totalCost = totalCost.add(_fishAmount.mul(globalData.fishPrice));
						
					 
					playerBook.addFishAmount(_buyer, _addFishAmount, totalCost, true);
					 
					globalData.selledAmount = globalData.selledAmount.add(_fishAmount);
					 
					playerBook.sellerProcessProfit(playerBookAddress, _fishAmount.mul(globalData.fishPrice));
					 
					systemFishAmount[globalData.fishPrice] = systemFishAmount[globalData.fishPrice].sub(_fishAmount);
					globalData.systemTotalFishAmount = globalData.systemTotalFishAmount.sub(_fishAmount);
					 
					_fishAmount = 0;

					 
					if(_balance > 0 && _isRebuy == false){ 
						uint temp = _balance;
						_balance = 0;
						playerBook.buyOrderRefund(_buyer, temp);
					}

					if( priceTotalFishAmount[globalData.fishPrice] == 0 && systemFishAmount[globalData.fishPrice] == 0 ){
						changePriceInterval();
						Q = sellOrderSequence[globalData.fishPrice];  
					}
					break;
				}else{
					 
					_addFishAmount = _addFishAmount.add(systemFishAmount[globalData.fishPrice]);
					 
					_fishAmount = _fishAmount.sub(systemFishAmount[globalData.fishPrice]);
					 
					_balance = _balance.sub(systemFishAmount[globalData.fishPrice].mul(globalData.fishPrice));
					totalCost = totalCost.add(systemFishAmount[globalData.fishPrice].mul(globalData.fishPrice));
					 
					 
					globalData.selledAmount = globalData.selledAmount.add(systemFishAmount[globalData.fishPrice]);
					 
					playerBook.sellerProcessProfit(playerBookAddress, systemFishAmount[globalData.fishPrice].mul(globalData.fishPrice));
					 
					globalData.systemTotalFishAmount = globalData.systemTotalFishAmount.sub(systemFishAmount[globalData.fishPrice]);
					systemFishAmount[globalData.fishPrice] = 0;
				}
			}

			 
			
			 
			if( priceTotalFishAmount[globalData.fishPrice] == 0 ){
				changePriceInterval();
				Q = sellOrderSequence[globalData.fishPrice];  
				if ( playerBook.reproductionRound() > _tempRound ) {
					_addFishAmount = _addFishAmount.mul(2);
					_tempRound = playerBook.reproductionRound();
				}
				continue;  
			}

			 
			if(sellOrders[ Q.idList[Q.front] ].fishAmount <= 0){
				Q.front++;
				continue;
			}

			 
			uint realAmount = sellOrders[ Q.idList[Q.front] ].fishAmount.mul( 2 **(playerBook.reproductionRound().sub(sellOrders[ Q.idList[Q.front] ].round)) );
			 

			if(_fishAmount >= realAmount){
				 

				 
				_addFishAmount = _addFishAmount.add(realAmount);
				 
				_fishAmount = _fishAmount.sub(realAmount);
				 
				_balance = _balance.sub(realAmount.mul(globalData.fishPrice));
				totalCost = totalCost.add(realAmount.mul(globalData.fishPrice));

				 
				 
				globalData.selledAmount = globalData.selledAmount.add(realAmount);
				 
				playerBook.sellerProcessProfit(sellOrders[ Q.idList[Q.front] ].owner, realAmount.mul(globalData.fishPrice));
				delete sellOrders[ Q.idList[Q.front] ];  
				delete Q.idList[Q.front];  
				 
				priceTotalFishAmount[globalData.fishPrice] = priceTotalFishAmount[globalData.fishPrice].sub(realAmount);
				 
				Q.front++;
			}else{ 
				 
				 
				 

				 
				_addFishAmount = _addFishAmount.add(_fishAmount);
					
				 
				_balance = _balance.sub(_fishAmount.mul(globalData.fishPrice));
				totalCost = totalCost.add(_fishAmount.mul(globalData.fishPrice));
					
				 
				playerBook.addFishAmount(_buyer, _addFishAmount, totalCost, true);
				 
				globalData.selledAmount = globalData.selledAmount.add(_fishAmount);
				 
				playerBook.sellerProcessProfit(sellOrders[ Q.idList[Q.front] ].owner, _fishAmount.mul(globalData.fishPrice));
				 
				sellOrders[ Q.idList[Q.front] ].fishAmount = realAmount.sub(_fishAmount);
				sellOrders[ Q.idList[Q.front] ].round = playerBook.reproductionRound();

				 
				priceTotalFishAmount[globalData.fishPrice] = priceTotalFishAmount[globalData.fishPrice].sub(_fishAmount);
					
				 
				_fishAmount = 0;

				 
				if(_balance > 0 && _isRebuy == false){ 
					uint temp = _balance;
					_balance = 0;
					playerBook.buyOrderRefund(_buyer, temp);
				}
				break;
			}
		}
		
		emit orderEvent(_buyer, _addFishAmount, now);
	}

	function getEstimateFishPrice(uint _fishAmount) external view returns(uint){
		uint tempBalance = 0;
		uint tempFishPrice = globalData.fishPrice;
		uint tempFishAmount = _fishAmount;
		bool tempJumpPrice = isFleshUp;
		uint tempfleshUpCount = fleshUpCount;
		while(tempFishAmount > 0){
			 
			 
			if(systemFishAmount[tempFishPrice] >= tempFishAmount || tempFishPrice > globalData.priceInterval[6]){ 
				 
				tempBalance = tempBalance.add(tempFishAmount.mul(tempFishPrice));
				tempFishAmount = 0;
				break;		
			}else{
				tempFishAmount = tempFishAmount.sub(systemFishAmount[tempFishPrice]); 
				tempBalance = tempBalance.add(systemFishAmount[tempFishPrice].mul(tempFishPrice)); 
				if(priceTotalFishAmount[tempFishPrice] > tempFishAmount){
					tempBalance = tempBalance.add(tempFishAmount.mul(tempFishPrice));
					tempFishAmount = 0;
					break;	
				}else{
					tempFishAmount = tempFishAmount.sub(priceTotalFishAmount[tempFishPrice]);
					tempBalance = tempBalance.add(priceTotalFishAmount[tempFishPrice].mul(tempFishPrice));
				}	
			}

			 
			if(tempJumpPrice == false){ 
				 
				tempFishPrice = tempFishPrice.add(1 finney);
				for(uint i = tempFishPrice; i < 100 finney; i = i.add(1 finney)){
					if(priceTotalFishAmount[i] > 0 || systemFishAmount[i] > 0){
						tempFishPrice = i; 
						break;
					}
				}

			}else if(tempFishPrice == globalData.priceInterval[6]){  
				 
				tempJumpPrice = false;
				 
				 
				 
				if(tempFishPrice == 99 finney){ 
					tempFishPrice = 100 finney;
				}else{
					tempFishPrice = tempFishPrice.add( tempfleshUpCount.mul(100).div(globalData.fishAmount).mul(1 finney) );  
					if(tempfleshUpCount.mul(100) % globalData.fishAmount > 0){  
						tempFishPrice = tempFishPrice.add(1 finney);
					}
					if(tempFishPrice > 99 finney){  
						tempFishPrice = 101 finney;
					}
				}
			}else if(tempJumpPrice == true || globalData.selledAmount.add(_fishAmount - tempFishAmount).mul(50) >= globalData.fishAmount){  
				if(tempJumpPrice == false){
					tempfleshUpCount = 0;  
				}

				for(uint i = globalData.priceInterval[0]; i <= globalData.priceInterval[6] && tempJumpPrice == false; i += 1 finney){
					 
					tempfleshUpCount += priceTotalFishAmount[i];
					tempfleshUpCount += systemFishAmount[i];
				}
				tempJumpPrice = true;  
				tempFishPrice = tempFishPrice.add(1 finney);
				 
			}
		} 
		tempBalance = tempBalance.mul(110);
		tempBalance = tempBalance.div(100);
		return tempBalance;
	}

	 
	function addNewSellOrder(address payable _seller, uint _fishAmount, uint _fishPrice) 
		public 
		onlyPlayerBook()
	{
		 
		 
		require(isFleshUp == false, "isFleshUp");

		 
		if(_fishPrice == globalData.fishPrice
			|| _fishPrice < globalData.priceInterval[0] 
			|| (_fishPrice > globalData.priceInterval[6] && _fishPrice != 100 finney)
		){
			revert("out of range");
		}

		 
		 
		if(globalData.fishPrice < 99 finney && _fishPrice > 99 finney){
			revert("out of range");
		}
		 
		if(globalData.fishPrice >= 99 finney && _fishPrice != 100 finney){
			revert("0.099 only allowed 0.1 eth");
		}

		 
		if( priceTotalFishAmount[_fishPrice].add(systemFishAmount[_fishPrice]).add(_fishAmount).mul(50) > globalData.fishAmount ){
			revert("no more than 2% total fishAmount");
		}
		if(globalData.fishPrice == 99 finney && priceTotalFishAmount[50 finney].add(systemFishAmount[50 finney]).add(_fishAmount).mul(25) > globalData.fishAmount ){
			revert("no more than 2% total fishAmount");
		}

		require(_fishAmount > 0, "no zero fish");  

		require(_fishPrice % (1 finney) == 0, "illegal price");

		 
		require(sellOrders.length == 0 || sellOrders[ personSellOrders[_seller] ].owner != _seller, "already exist");

		 
		playerBook.minusFishAmount(_seller, _fishAmount);
		
		 
		uint sellOrdersCount = sellOrders.length;
		if(_fishPrice == 100 finney){  
			_fishAmount = _fishAmount.mul(2);
			_fishPrice = 50 finney;
			sellOrders.push( PlayerSellOrderData({
				owner: _seller,
				fishAmount: _fishAmount,
				fishPrice: _fishPrice,
				 
				round: playerBook.reproductionRound().add(1)
			}) );
		}else{
			sellOrders.push( PlayerSellOrderData({
				owner: _seller,
				fishAmount: _fishAmount,
				fishPrice: _fishPrice,
				 
				round: playerBook.reproductionRound()
			}) );
		}

		 
		priceTotalFishAmount[_fishPrice] = priceTotalFishAmount[_fishPrice].add(_fishAmount);
		 
		personSellOrders[_seller] = sellOrdersCount;  
		sellOrderSequence[_fishPrice].idList.push(sellOrdersCount);  

		emit orderEvent(_seller, _fishAmount, now);
	}


	 
	function cancelSellOrder(address payable _caller, uint _orderId)
		public
		onlyPlayerBook()
	{
		if(sellOrders.length <= _orderId){
			revert("id error");
		}

		if(sellOrders[_orderId].owner != _caller){  
			revert("only owner");
		}

		if(globalData.fishPrice == 99 finney && sellOrders[_orderId].fishPrice == 50 finney){  
			revert("0.099 not allowed cancel 0.1 eth order");
		}

		require(isFleshUp == false, "isFleshUp");

		 
		uint tempFishAmount = sellOrders[_orderId].fishAmount.mul(2 **(playerBook.reproductionRound().sub(sellOrders[_orderId].round)) );
        uint _fishPrice = sellOrders[_orderId].fishPrice;
		delete sellOrders[_orderId];

		 
		playerBook.addFishAmount(_caller, tempFishAmount, 0, false);

		 
		priceTotalFishAmount[_fishPrice] = priceTotalFishAmount[_fishPrice].sub(tempFishAmount);

		personSellOrders[_caller] = 0;  

		emit orderEvent(_caller, tempFishAmount, now);
	}


	 
	function reproductionStage()
		private
	{
		 
		globalData.fishAmount = globalData.fishAmount.mul(2);
		globalData.systemTotalFishAmount = globalData.systemTotalFishAmount.mul(2);
		globalData.fishPrice = 50 finney;
		globalData.selledAmount = 0;
		systemFishPriceCumulativeCount = 56 finney;
		isFleshUp = false;

		 
		uint _addSystemFishAmount = globalData.systemTotalFishAmount.div(50);
		uint j=1;
		globalData.priceInterval[0] = 50 finney;  
		for(uint i = 51 finney; i <= 98 finney; i += 1 finney){  
			priceTotalFishAmount[i] = priceTotalFishAmount[i].mul(2);  
			systemFishAmount[i] = systemFishAmount[i].mul(2);  
			 
			if(i <= 56 finney){
				globalData.priceInterval[j] = i;
				j++;
				systemFishAmount[i] = systemFishAmount[i].add(_addSystemFishAmount);
			}
		}

		 
		playerBook.addReproductionRound();
		reproductionBlockNumbers.push(block.number);
	}


	function changePriceInterval() 
		private
	{
		 
		
		
		if( isFleshUp == true || globalData.selledAmount.mul(50) >= globalData.fishAmount ){ 
			if(isFleshUp == false){
				fleshUpCount = 0;  
			}

			haveFish = false; 
			for(uint i = globalData.priceInterval[0]; i <= globalData.priceInterval[6]; i += 1 finney){
				if(haveFish == false &&(priceTotalFishAmount[i] > 0 || systemFishAmount[i] > 0)){
					globalData.fishPrice = i;
					haveFish = true;
				}
				if(isFleshUp == false){  
					fleshUpCount += priceTotalFishAmount[i];
					fleshUpCount += systemFishAmount[i];
				}
			}
			isFleshUp = true;  
			 
			 
			globalData.selledAmount = 0;

			if(fleshUpCount == 0){  
				 
				 
				for(uint i = globalData.priceInterval[0]; i < 100 finney; i = i.add(1 finney)){
					if(priceTotalFishAmount[i] > 0 || systemFishAmount[i] > 0){
						globalData.fishPrice = i;  
						break;
					}  
				}
				isFleshUp = false;
			}else if(haveFish == false){ 
				 
				isFleshUp = false;
				 
				globalData.selledAmount = 0;
				 
				if(globalData.fishPrice == 99 finney){ 
					globalData.fishPrice = 100 finney;
				}else{
					globalData.fishPrice = globalData.fishPrice.add( fleshUpCount.mul(100).div(globalData.fishAmount).mul(1 finney) );  
					if(fleshUpCount.mul(100) % globalData.fishAmount > 0){  
						globalData.fishPrice = globalData.fishPrice.add(1 finney);
					}
					if(globalData.fishPrice > 99 finney){
						globalData.fishPrice = 99 finney;
					}
				}
				 
			}

			emit fleshUpEvent(globalData.fishPrice, fleshUpCount, now);
		}else{
			 
			if(globalData.fishPrice == 99 finney){ 
				globalData.fishPrice = 100 finney;
			}else{
				 
				for(uint i = globalData.priceInterval[0]; i < 100 finney; i = i.add(1 finney)){
					if(priceTotalFishAmount[i] > 0 || systemFishAmount[i] > 0){
						globalData.fishPrice = i;  
						break;
					}  
				}
			}
		}

		 
		if(globalData.fishPrice > 99 finney){
			reproductionStage();
			return;
		}
		
		 
		 
		 
		if(globalData.fishPrice.add(3 finney) > systemFishPriceCumulativeCount && systemFishPriceCumulativeCount < 99 finney && isFleshUp == false){ 
			 
			uint _addSystemFishAmount = globalData.systemTotalFishAmount.div(50);
			uint newPrice = globalData.fishPrice.add(3 finney); 
			if(newPrice > 99 finney){
				newPrice = 99 finney;
			}
			 
			for(uint i = globalData.fishPrice; i <= newPrice; i = i.add(1 finney)){  
				if(systemFishAmount[i] == 0){  
					systemFishAmount[i] = systemFishAmount[i].add(_addSystemFishAmount);
				}
			}
			systemFishPriceCumulativeCount = newPrice;
			 
			 
			 
			 
			globalData.priceInterval[0] = newPrice.sub(6 finney);
			globalData.priceInterval[1] = newPrice.sub(5 finney);
			globalData.priceInterval[2] = newPrice.sub(4 finney);
			globalData.priceInterval[3] = newPrice.sub(3 finney);
			globalData.priceInterval[4] = newPrice.sub(2 finney);
			globalData.priceInterval[5] = newPrice.sub(1 finney);
			globalData.priceInterval[6] = newPrice;
		}else if(globalData.fishPrice < 96 finney && globalData.fishPrice.sub(3 finney) >= 50 finney && isFleshUp == false){  
			 
			 
			globalData.priceInterval[0] = globalData.fishPrice.sub(3 finney);
			globalData.priceInterval[1] = globalData.fishPrice.sub(2 finney);
			globalData.priceInterval[2] = globalData.fishPrice.sub(1 finney);
			globalData.priceInterval[3] = globalData.fishPrice;
			globalData.priceInterval[4] = globalData.fishPrice.add(1 finney);
			globalData.priceInterval[5] = globalData.fishPrice.add(2 finney);
			globalData.priceInterval[6] = globalData.fishPrice.add(3 finney);
		}

		if(priceTotalFishAmount[globalData.fishPrice] == 0 && systemFishAmount[globalData.fishPrice] == 0){ 
			for(uint i = globalData.priceInterval[0]; i < 100 finney; i = i.add(1 finney)){
				if(priceTotalFishAmount[i] > 0 || systemFishAmount[i] > 0){
					globalData.fishPrice = i;  
					break;
				}  
			}
		}

		if(globalData.fishPrice == 99 finney){  
			priceTotalFishAmount[50 finney] = priceTotalFishAmount[50 finney].mul(2);  
			uint _addSystemFishAmount = globalData.systemTotalFishAmount.div(50);  
			systemFishAmount[50 finney] = systemFishAmount[50 finney].add(_addSystemFishAmount).mul(2);

			 
			uint newPrice = 100 finney;
			globalData.priceInterval[0] = newPrice.sub(6 finney);
			globalData.priceInterval[1] = newPrice.sub(5 finney);
			globalData.priceInterval[2] = newPrice.sub(4 finney);
			globalData.priceInterval[3] = newPrice.sub(3 finney);
			globalData.priceInterval[4] = newPrice.sub(2 finney);
			globalData.priceInterval[5] = newPrice.sub(1 finney);
			globalData.priceInterval[6] = newPrice;
		}

		emit changePriceEvent(address(this), globalData.fishPrice, now);
	}

	 
	function deadFish(uint _fishAmount) 
		external
		onlyPlayerBook
	{
		globalData.fishAmount = globalData.fishAmount.sub(_fishAmount);
	}


	function setPlayerBookAddress(address payable _PBaddress) 
		external
		onlyOwner
	{
		playerBookAddress = _PBaddress;
		playerBook = PlayerBook(_PBaddress);
	}



	function getPersonSellOrders()
		external
		view
		returns(uint)
	{
		return(personSellOrders[msg.sender]);
	}


	function getSellOrderData(uint _orderId)
		external
		view
		returns(address, uint, uint)
	{
		return(sellOrders[_orderId].owner, sellOrders[_orderId].fishAmount, sellOrders[_orderId].fishPrice);
	}


	function showGlobalData() 
		public
		view
		returns( uint _fishAmount, uint _fishPrice, uint _selledAmount )
	{
		return( 
			globalData.fishAmount,
			globalData.fishPrice,
			globalData.selledAmount
		);
	}


	function showAvaliablePriceInterval() 
		public 
		view
		returns (uint256 [7] memory) 
	{
		return globalData.priceInterval;
	}


	function showPriceIntervalFishAmount()
		public 
		view
		returns (uint256 [7] memory) 
	{
		uint[7] memory temp;
		for(uint i = 0; i < 7; i++){
			uint tempPrice = globalData.priceInterval[i];
			if(tempPrice == 100 finney){
				temp[i] += priceTotalFishAmount[50 finney];
				temp[i] += systemFishAmount[50 finney];
				temp[i] /= 2;
			}else{
				temp[i] += priceTotalFishAmount[tempPrice];
				temp[i] += systemFishAmount[tempPrice];
			}
		}
		return temp;
	}

	function showFish()
		public 
		view
		returns (uint256) 
	{
		return globalData.systemTotalFishAmount;
	}

	function getRepoBlockNumbers() 
		external
		view
		returns(uint[] memory)
	{
		return reproductionBlockNumbers;
	}
}

contract Commission is Ownable ,Pausable{
    using SafeMath for uint;

     
    uint[9] levelToCommission = [100,400,400,500,500,600,600,700,700];  
     
    uint[9] fishbowlGrow = [0,0,0,0,0,0,0,0,1000];  
    address private playerBookAddress;


     
    struct Generation{
           
         

         
        address[] ancestorList;  

         
        address[] inviteesList;  
    }
    mapping (address => Generation) generations;  



    constructor(address _playerBookAddress) public{
        playerBookAddress = _playerBookAddress;
    }

    event firstGenerationJoinGameEvent(address _newUser, uint _time);
    event joinGameEvent(address _newUser, address invitedBy, uint _time);
    event distributeCommissionEvent(uint[] _commission, uint _bonusPool, uint _ghostComission, uint _time);
    event setPlayerBookAddrEvent(address _newPlayerBookAddr, uint _time);


     
    modifier onlyForPlayerBook(){
        require(msg.sender == playerBookAddress, "Only for palyerBook contract!");
        _;
    }

     
    function firstGenerationJoinGame(address _newUser) public onlyForPlayerBook{
         

        emit firstGenerationJoinGameEvent(_newUser, now);
    }

     
    function joinGame(address _newUser, address _inviter) public onlyForPlayerBook{

        if(generations[_inviter].ancestorList.length == 10){
            generations[_newUser].ancestorList.push(_inviter);
            for (uint i = 0; i < 9; i++) {
                generations[_newUser].ancestorList.push(generations[_inviter].ancestorList[i]);
            }
             
        }
        else if(generations[_inviter].ancestorList.length == 0){
            generations[_newUser].ancestorList.push(_inviter);
        }
        else{
            generations[_newUser].ancestorList.push(_inviter);
            for (uint j = 0; j < generations[_inviter].ancestorList.length; j++) {
                generations[_newUser].ancestorList.push(generations[_inviter].ancestorList[j]);
            }
             
        }

        emit joinGameEvent(_newUser, _inviter, now);
    }

     
 
     
    function inviteNewUser(address _inviter, uint _inviterFishBowlSize, address _invitee, uint _inviteeFishbowlLevel)
    public onlyForPlayerBook returns(uint newFishbowlSize)
    {
        generations[_inviter].inviteesList.push(_invitee);
        uint _newFishbowlSize = _inviterFishBowlSize.add(fishbowlGrow[_inviteeFishbowlLevel]);

        return _newFishbowlSize;
    }

     
    function getAncestorList(address _user) public view returns(address[] memory ancestorList){
        require(generations[_user].ancestorList.length != 0, "你是第一代");

        address[] memory _ancestorList = new address[](generations[_user].ancestorList.length);
        for(uint i = 0; i < generations[_user].ancestorList.length; i++){
            _ancestorList[i] = generations[_user].ancestorList[i];
        }

        return _ancestorList;
    }

     
    function getMotherGeneration(address _user) public view returns(address motherGeneration){
        require(generations[_user].ancestorList.length != 0, "你是第一代");

        return generations[_user].ancestorList[0];
    }

     
    function getInviteesList(address _user) public view returns(address[] memory inviteesList){
        require(generations[_user].inviteesList.length != 0, "你沒有下線");

        address[] memory _inviteesList = new address[](generations[_user].inviteesList.length);
        for(uint i = 0; i < generations[_user].inviteesList.length; i++){
            _inviteesList[i] = generations[_user].inviteesList[i];
        }

        return _inviteesList;
    }

     
    function getInviteesCount(address _user) public view returns(uint inviteesCount){
         

        return generations[_user].inviteesList.length;
    }

     
    function setPlayerBookAddr(address _newPlayerBookAddr) public onlyOwner{
        playerBookAddress = _newPlayerBookAddr;

        emit setPlayerBookAddrEvent(_newPlayerBookAddr, now);
    }

     
    function getPlayerBookAddr() public view returns(address _playerBookAddress){
        return playerBookAddress;
    }
}

contract PlayerBook is Ownable, Pausable {

    using SafeMath for uint;

    uint public reproductionRound;
    uint public weekRound;

    uint constant public BONUS_TIMEOUT_NO_USER = 33200;
    uint constant public BONUS_TIMEOUT_WEEK = 46500;

    uint private _ghostProfit;

    uint[9] public avaliableFishAmountList = [0,1,5,10,30,50,100,150,200];

    event LogBuyOrderRefund( address indexed _refunder, uint _refundValue, uint _now);
    event LogSellerProcessProfit( address indexed _seller, uint _totalValue, uint _now);
    event LogAddNewSellOrder( address indexed _player, uint _fishAmount, uint _cPrice, uint _now);
    event LogAddFishAmount( address indexed _buyer, uint _successBuyFishAmount, uint _totalCost, bool _isBuy, uint _now ); 
    event LogDistributeCommission( address indexed _user, uint _fodderFee, address[] _ancestorList, uint bonusPool, uint _now);
    event LogFirstGenerationJoinGame( address indexed _user, uint _initFishAmount, uint _value, uint _now);
    event LogJoinGame( address indexed _newUser, uint _initFishAmount, uint _value, address _inviter, uint _now);

    event LogIncreseFishbowlSize( address indexed _newUser, uint _initFishAmount, uint _value, uint _now);
    event LogWithdrawProfit( address indexed _user, uint _profit, uint _recomandBonus, uint _now);
    event LogWithdrawRecommandBonus( address indexed _user, uint _recommandBonus, uint _now);

    event LogGetWeekBonusPool( address indexed _user, uint _bonus, uint _now);
    event LogGetBonusPool( address indexed _user, uint _bonus, uint _now);

    event LogWithdrawOwnerProfit( address indexed _owner, uint _profit );

     
    struct Player {
         
        uint admissionPrice;
        uint accumulatedSellPrice;
        uint amountToSale;
        uint recomandBonus;
        uint profit; 
        uint rebuy;
         
        uint fishbowlLevel;
        uint fishbowlSize;
        uint fishAmount;
         
        PlayerStatus status;
         
        uint round;
         
        uint playerWeekRound;
        uint playerWeekCount;
         
        bool isFirstGeneration;
         
        uint joinRound;
    }

     
     
     
     
     
     

    address payable[3] private weekData;  

     

    struct BonusPool {
        uint totalAmount;
        uint bonusWeekBlock;
        address weekBonusUser;
        uint bonusWeekBlockWithoutUser;
        address lastBonusUser;
    }

    BonusPool bonusPool;
     

     
    TransactionSystem transactionSystem;
    Fishbowl fishbowl;
    Commission commission; 

     
    enum PlayerStatus { NOT_JOINED, NORMAL, EXCEEDED }
    
    address payable public TransactionSystemAddress;
    address payable public FishbowlAddress;
    address payable public CommissionAddress;
    
     
    mapping (address=>Player) playerBook;
    mapping (address=>uint) internal playerLastTotalCost;

    mapping (address=>bool) whiteList;
    

     
    modifier PlayerIsAlive() {
        require(playerBook[msg.sender].status == PlayerStatus.NORMAL, "Exceed or not Join");
        _;
    }

     
    modifier OnlyForTxContract() {
        require( msg.sender == TransactionSystemAddress, "Only for tx contract!");
        _; 
    }

     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "Addresses not owned by human are forbidden");
        _;
    }

     
    modifier isValidFishAmount (uint _fishAmount) {
        require(
            _fishAmount == avaliableFishAmountList[0] ||
            _fishAmount == avaliableFishAmountList[1] ||
            _fishAmount == avaliableFishAmountList[2] ||
            _fishAmount == avaliableFishAmountList[3] ||
            _fishAmount == avaliableFishAmountList[4] ||
            _fishAmount == avaliableFishAmountList[5] ||
            _fishAmount == avaliableFishAmountList[6] ||
            _fishAmount == avaliableFishAmountList[7] ||
            _fishAmount == avaliableFishAmountList[8] ,
            "Invalid fish amount!"
        );
        _;
    }

    constructor() public payable {

        reproductionRound = 1;
        weekRound = 1;
        
        bonusPool = BonusPool(0, block.number, address(0), block.number, address(0));
         

        _ghostProfit = 0;
        whiteList[owner] = true;
        whiteList[0x83b73144939e81236C8d5561509CC50e7A30D0F7] = true; 
    }

     
    function firstGenerationJoinGame(uint _initFishAmount) public payable isHuman() isValidFishAmount(_initFishAmount) {      
        address payable _user = msg.sender;
        uint _value = msg.value;

        require(whiteList[_user], "Invalid user");
        require(playerBook[_user].status == PlayerStatus.NOT_JOINED, "Player has joined!");

        playerBook[_user].isFirstGeneration = true;
        emit LogFirstGenerationJoinGame( _user, _initFishAmount, _value, now);

         
         
        commission.firstGenerationJoinGame(_user);
         
        initFishData(_user, _initFishAmount);
         
        transactionSystem.addNewBuyOrder(_user, _initFishAmount, _value, false);
        initPriceData(_user, playerLastTotalCost[_user]);
    }

     
    function joinGame (uint _initFishAmount, address payable _inviter) public payable isHuman() isValidFishAmount(_initFishAmount) {    
        address payable _newUser = msg.sender;
        uint _value = msg.value;

        require(_inviter != address(0x0) && playerBook[_inviter].status > PlayerStatus.NOT_JOINED, "No such inviter!");
        require(playerBook[_newUser].status == PlayerStatus.NOT_JOINED, "Player has joined!");

        playerBook[_newUser].isFirstGeneration = false;
        emit LogJoinGame (_newUser, _initFishAmount, _value, _inviter,  now);

        uint _balance = _value.div(2);
         

         
         
        commission.joinGame(_newUser, _inviter);
         
        initFishData(_newUser, _initFishAmount);
         
        playerBook[_inviter].fishbowlSize = commission.inviteNewUser(_inviter, playerBook[_inviter].fishbowlSize, _newUser, playerBook[_newUser].fishbowlLevel);
        playerBook[_inviter].amountToSale = playerBook[_inviter].fishbowlSize.mul(playerBook[_inviter].admissionPrice);
         
         
        if (playerBook[_inviter].playerWeekRound != weekRound) {
            playerBook[_inviter].playerWeekRound = weekRound;
            playerBook[_inviter].playerWeekCount = 0;
        }

         
        playerBook[_inviter].playerWeekCount = playerBook[_inviter].playerWeekCount.add(_initFishAmount);
         
        bool tempJudge = false;
        int index = -1;
        for(uint i = 0; i < 3; i++){
            if(playerBook[_inviter].playerWeekCount > playerBook[ weekData[i] ].playerWeekCount){
                index = int(i);  
                if(tempJudge){  
                    address payable temp = weekData[i];
                    weekData[i] = _inviter;
                    weekData[i-1] = temp;
                }
            }
            if (_inviter == weekData[i]) {  
                tempJudge = true;
            }
        }
        if(tempJudge == false){  
            for(uint i = 0; int(i) <= index; i++){
                address payable temp = weekData[i];
                weekData[i] = _inviter;
                if(i != 0){
                    weekData[i-1] = temp;
                }
            }
        }
         
         
        transactionSystem.addNewBuyOrder(_newUser, _initFishAmount, _balance, false);
        initPriceData(_newUser, playerLastTotalCost[_newUser]);
         
         
    }


      
    function increseFishbowlSizeByMoney (uint _fishAmount) public payable isHuman() PlayerIsAlive() isValidFishAmount(_fishAmount){   
        address payable _player = msg.sender;
        uint _value = msg.value;
        require (playerBook[_player].fishbowlLevel <= 8 && playerBook[_player].fishbowlLevel >= 0, "Invalid fish level!");
        require (fishbowl.getFishBowlLevel(_fishAmount) >= playerBook[_player].fishbowlLevel, "Should buy more fish to upgrade!");
        
         
         

        uint _balance = playerBook[_player].isFirstGeneration ? _value : _value.div(2);
        
         
        uint _beforeFishbowlSize = playerBook[_player].fishbowlSize;

        if (playerBook[_player].fishbowlLevel < 8 && playerBook[_player].fishbowlLevel != 0) {
            transactionSystem.addNewBuyOrder(_player, _fishAmount, _balance, false);
            (playerBook[_player].fishbowlLevel, playerBook[_player].fishbowlSize, playerBook[_player].admissionPrice, playerBook[_player].amountToSale) = fishbowl.fishBowl(playerLastTotalCost[_player], _fishAmount);
        
        } else if (playerBook[_player].fishbowlLevel == 8 && playerBook[_player].joinRound == reproductionRound) {
            transactionSystem.addNewBuyOrder(_player, _fishAmount, _balance, false);
            (playerBook[_player].admissionPrice, playerBook[_player].amountToSale) = fishbowl.multipleBuy(playerLastTotalCost[_player], playerBook[_player].admissionPrice, playerBook[_player].amountToSale);
            
            if(playerBook[_player].isFirstGeneration == false){  
                address temp = commission.getMotherGeneration(_player);
                address payable _inviter = address(uint160(temp));
                if (playerBook[_inviter].playerWeekRound != weekRound) {
                    playerBook[_inviter].playerWeekRound = weekRound;
                    playerBook[_inviter].playerWeekCount = 0;
                }

                playerBook[_inviter].playerWeekCount = playerBook[_inviter].playerWeekCount.add(_fishAmount);
                 
                bool tempJudge = false;
                int index = -1;
                for(uint i = 0; i < 3; i++){
                    if(playerBook[_inviter].playerWeekCount > playerBook[ weekData[i] ].playerWeekCount){
                        index = int(i);  
                        if(tempJudge){  
                            address payable _temp = weekData[i];
                            weekData[i] = _inviter;
                            weekData[i-1] = _temp;
                        }
                    }
                    if (_inviter == weekData[i]) {  
                        tempJudge = true;
                    }
                }
                if(tempJudge == false){  
                    for(uint i = 0; int(i) <= index; i++){
                        address payable _temp = weekData[i];
                        weekData[i] = _inviter;
                        if(i != 0){
                            weekData[i-1] = _temp;
                        }
                    }
                }
            }

        } else{
            revert("out of join round");
        }

        if ( playerBook[_player].fishbowlSize <= _beforeFishbowlSize) {
            playerBook[_player].fishbowlSize = _beforeFishbowlSize;
            playerBook[_player].amountToSale = playerBook[_player].admissionPrice.mul(playerBook[_player].fishbowlSize);
        }

        
        emit LogIncreseFishbowlSize( _player, _fishAmount, _value, now);

    }


     
    function rebuyAddNewBuyOrder(uint _fishAmount, uint _rebuy) public isHuman() PlayerIsAlive() {
        address payable _player = msg.sender;
         
        require(playerBook[_player].rebuy >= _rebuy, "Invalid rebuy value!");

         
         
       
        uint _balance = playerBook[_player].isFirstGeneration ? _rebuy : _rebuy.div(2);
         
        transactionSystem.addNewBuyOrder(_player, _fishAmount, _balance, true);
        uint _actualRebuy = playerBook[_player].isFirstGeneration ? playerLastTotalCost[_player] : playerLastTotalCost[_player].mul(2);
        playerBook[_player].rebuy = (playerBook[_player].rebuy).sub(_actualRebuy);
    }


     
    function initFishData(address _newUser, uint _initFishAmount) internal {
         
        playerBook[_newUser].fishbowlLevel = fishbowl.getFishBowlLevel(_initFishAmount); 
        playerBook[_newUser].fishbowlSize = fishbowl.getFishbowlSize(playerBook[_newUser].fishbowlLevel);
        playerBook[_newUser].status = PlayerStatus.NORMAL;
        playerBook[_newUser].round = reproductionRound;
         
        playerBook[_newUser].playerWeekRound = weekRound;
        playerBook[_newUser].playerWeekCount = 0;
        playerBook[_newUser].joinRound = reproductionRound;
    }

     
    function initPriceData(address _newUser, uint _totalFishPrice) internal {    
        playerBook[_newUser].accumulatedSellPrice = 0;
        playerBook[_newUser].admissionPrice = fishbowl.getAdmissionPrice(_totalFishPrice);
        playerBook[_newUser].amountToSale = fishbowl.getAmountToSale(playerBook[_newUser].fishbowlLevel, playerBook[_newUser].admissionPrice);
        playerBook[_newUser].recomandBonus = 0;
        playerBook[_newUser].profit = 0;
        playerBook[_newUser].rebuy = 0;
    }

     
    function addNewSellOrder(uint _fishAmount, uint _fishPrice)  public isHuman() PlayerIsAlive() {
        require(_fishAmount != 0, "not allowd zero fish amount");
        address payable _player = msg.sender;
         
        normalizeFishAmount(_player);
        (uint _quo, uint _rem) = getDivided(playerBook[msg.sender].fishAmount, 10);
        if ( _rem != 0 ) {
            _quo = _quo.add(1);
        }

        require(
            playerBook[msg.sender].fishAmount >= _fishAmount &&
            _fishAmount <= _quo,
            "Unmatched avaliable sell fish amount!"
        );

        uint accumulated = playerBook[_player].accumulatedSellPrice;
        accumulated = accumulated.add(_fishAmount * _fishPrice);
        require( playerBook[_player].amountToSale.div(1000) >= accumulated , "exceed amount to sale");
            
         
        transactionSystem.addNewSellOrder(_player, _fishAmount, _fishPrice);

        emit LogAddNewSellOrder( _player, _fishAmount, _fishPrice, now);
    }


     
    function cancelSellOrder(uint _orderId) public payable isHuman()  PlayerIsAlive() {
         
        transactionSystem.cancelSellOrder(msg.sender, _orderId);
    }

     
    function addFishAmount (address payable _buyer, uint _successBuyFishAmount, uint _totalCost, bool _isBuy ) external OnlyForTxContract() {
        
         
        normalizeFishAmount(_buyer);
        
        playerBook[_buyer].fishAmount = (playerBook[_buyer].fishAmount).add(_successBuyFishAmount);
        playerLastTotalCost[_buyer] = _totalCost;
        emit LogAddFishAmount( _buyer, _successBuyFishAmount, _totalCost, _isBuy, now);
        
        
         
        if (_isBuy && !playerBook[_buyer].isFirstGeneration) {
             
            distributeCommission(_buyer, _totalCost);
        }
    }


      
    function sellerProcessProfit (address _seller, uint _totalRevenue) external OnlyForTxContract() {
        emit LogSellerProcessProfit( _seller, _totalRevenue, now);

        if (_seller != address(this) ) {
            addAccumulatedValue (_seller, _totalRevenue);

            uint _profit = _totalRevenue.mul(60).div(100);
            playerBook[_seller].profit = (playerBook[_seller].profit).add(_profit);

            uint _rebuy = _totalRevenue.mul(40).div(100);
            if (playerBook[_seller].status == PlayerStatus.EXCEEDED) {
                _ghostProfit = _ghostProfit.add(_rebuy);
            } else {
                playerBook[_seller].rebuy = (playerBook[_seller].rebuy).add(_rebuy); 
            }
        } else {
            _ghostProfit = _ghostProfit.add(_totalRevenue);
        }
    }


      
    function buyOrderRefund (address payable _refunder, uint _refundValue) external OnlyForTxContract() {   
        uint _tmpRefundValue = _refundValue;
        if ( !playerBook[_refunder].isFirstGeneration) 
            _tmpRefundValue = _tmpRefundValue.mul(2);

        emit LogBuyOrderRefund( _refunder, _refundValue, now);

        _refunder.transfer(_tmpRefundValue);
    }


     
    function minusFishAmount (address _seller, uint _fishAmount) external OnlyForTxContract() {
        playerBook[_seller].fishAmount = (playerBook[_seller].fishAmount).sub(_fishAmount);
    }


     
    function addReproductionRound () external OnlyForTxContract() {
        reproductionRound = reproductionRound.add(1);
    }
    

     
    function addAccumulatedValue (address _player, uint _profit) internal {
        playerBook[_player].accumulatedSellPrice = (playerBook[_player].accumulatedSellPrice).add(_profit);
        if ( (playerBook[_player].amountToSale.div(1000) < playerBook[_player].accumulatedSellPrice) && (playerBook[_player].status != PlayerStatus.EXCEEDED) ) {
            playerBook[_player].status = PlayerStatus.EXCEEDED;
            transactionSystem.deadFish(playerBook[_player].fishAmount);

            uint _tempRebuy = playerBook[_player].rebuy;
            playerBook[_player].rebuy = 0;

            _ghostProfit = _ghostProfit.add(_tempRebuy);
        }
    }

     
    function normalizeFishAmount (address _player) internal {
        if( reproductionRound != playerBook[_player].round ) {
            playerBook[_player].fishAmount = playerBook[_player].fishAmount.mul( 2 **  (reproductionRound.sub(playerBook[_player].round)) );
            playerBook[_player].round = reproductionRound;
        }
    }
     
    function checkBonusPoolBlockNoUser () internal returns(bool) {
        uint lastBonusBlock = bonusPool.bonusWeekBlockWithoutUser;
        bonusPool.bonusWeekBlockWithoutUser = block.number;

        if (bonusPool.bonusWeekBlockWithoutUser.sub(lastBonusBlock) > BONUS_TIMEOUT_NO_USER) 
            return true;
        
        return false;
    }
     
    function checkBonusPoolBlockWeek () internal returns(bool) {
        uint lastBonusBlock = bonusPool.bonusWeekBlock;
        uint _nowBlock = block.number;

        if (_nowBlock.sub(lastBonusBlock) > BONUS_TIMEOUT_WEEK)  {
            bonusPool.bonusWeekBlock = _nowBlock;
            return true;
        }
        return false;
    }

    function resetWeekData() internal {
         
         
        weekRound = weekRound.add(1);

        delete weekData;

         
    }


     
    uint[9] levelToCommission = [100,400,400,500,500,600,600,700,700];  
    function distributeCommission(address payable _user, uint _fodderFee) internal {
        uint _ghostCommission;
        uint _bonusPool;
        address[] memory _ancestorList = commission.getAncestorList(_user);
        uint[] memory _commissionList = new uint[](_ancestorList.length);

        _ghostCommission = _fodderFee;
        for(uint i = 0; i < _ancestorList.length; i++){
            if(i==0){
                _commissionList[i] = _fodderFee.mul(levelToCommission[playerBook[_ancestorList[i]].fishbowlLevel]).div(1000);
                _ghostCommission = _ghostCommission.sub(_commissionList[i]);
            }else if(playerBook[_ancestorList[i]].fishbowlLevel != 0){
                _commissionList[i] = _fodderFee.mul(20).div(1000);  
                _ghostCommission = _ghostCommission.sub(_commissionList[i]);
            }
        }
        _bonusPool = _fodderFee.mul(20).div(1000);
        _ghostCommission = _ghostCommission.sub(_bonusPool);

        require(_commissionList.length == _ancestorList.length, "Unmatched commission length!");
         
        _ghostProfit = _ghostProfit.add(_ghostCommission);
         
         
        bonusPool.totalAmount = bonusPool.totalAmount.add(_bonusPool);
         
        if( checkBonusPoolBlockWeek() ) {
            uint _weekBonus = bonusPool.totalAmount.div(10);
            bonusPool.totalAmount = bonusPool.totalAmount.sub(_weekBonus);
            bonusPool.weekBonusUser = weekData[2];
             

            weekData[2].transfer(_weekBonus);
             
            resetWeekData();
            emit LogGetWeekBonusPool(bonusPool.weekBonusUser, _weekBonus, now);
        }

        if( checkBonusPoolBlockNoUser() ) {
            uint _finalBonus = bonusPool.totalAmount;
            bonusPool.totalAmount = 0;
            bonusPool.lastBonusUser = _user;
            _user.transfer(_finalBonus);
            emit LogGetBonusPool(_user, _finalBonus, now);
        }

        emit LogDistributeCommission(_user, _fodderFee, _ancestorList, bonusPool.totalAmount, now);

        for (uint i = 0; i < _ancestorList.length; i++) {
             
             
            addAccumulatedValue(_ancestorList[i], _commissionList[i]);
             
            uint _rBonus = _commissionList[i].mul(60).div(100);
            playerBook[_ancestorList[i]].recomandBonus = (playerBook[_ancestorList[i]].recomandBonus).add(_rBonus);
             
            uint _rebuy = _commissionList[i].mul(40).div(100);
            if (playerBook[_ancestorList[i]].status == PlayerStatus.EXCEEDED) {
                _ghostProfit = _ghostProfit.add(_rebuy);
            } else {
                playerBook[_ancestorList[i]].rebuy = (playerBook[_ancestorList[i]].rebuy).add(_rebuy);
            }
        }
    }


     
    function getPlayerStatusAndExceeded () public view returns (PlayerStatus, bool) {
        return (playerBook[msg.sender].status, playerBook[msg.sender].status == PlayerStatus.EXCEEDED);
    }

     
    function getPlayerWeekCount () public view returns (uint) {
        return (playerBook[msg.sender].playerWeekCount);
    }


     
    function setTransactionSystemAddr(address payable _newAddr) public onlyOwner() {
        TransactionSystemAddress = _newAddr;
        transactionSystem = TransactionSystem(_newAddr);
    }


     
    function setFishbowlAddr(address payable _newAddr) public onlyOwner() {
        FishbowlAddress = _newAddr;
        fishbowl = Fishbowl(_newAddr);
    }


     
    function setCommissionAddr(address payable _newAddr) public onlyOwner() {
        CommissionAddress = _newAddr;
        commission = Commission(_newAddr);
    }


     
    function getDivided(uint numerator, uint denominator) internal pure returns(uint quotient, uint remainder) {
        quotient  = numerator / denominator;
        remainder = numerator - denominator * quotient;
    }
     
    function getPlayerData() 
        public 
        view  
    returns (uint _admission, uint _accumulatedSellPrice, uint _amountToSale, uint _fishbowlLevel, uint _fishbowlSize, uint _fishAmount, uint _recomandBonus, uint _profit, uint _rebuy, uint _playerWeekRound, uint _playerWeekCount, uint _reproductionRound, uint _joinRound) 
    {   
        address _user = msg.sender;
        _admission = playerBook[_user].admissionPrice;
        _accumulatedSellPrice = playerBook[_user].accumulatedSellPrice;
        _amountToSale = playerBook[_user].amountToSale;
        _fishbowlLevel = playerBook[_user].fishbowlLevel;
        _fishbowlSize = playerBook[_user].fishbowlSize;
        _fishAmount = playerBook[_user].fishAmount.mul(2 ** (reproductionRound.sub(playerBook[_user].round)));
        _recomandBonus = playerBook[_user].recomandBonus;
        _profit = playerBook[_user].profit;
        _rebuy = playerBook[_user].rebuy;
        _playerWeekRound = playerBook[_user].playerWeekRound;
        _playerWeekCount = playerBook[_user].playerWeekCount;
        _reproductionRound = playerBook[_user].round;
        _joinRound = playerBook[_user].joinRound;
    }
     
    function getBonusPool () public view returns (uint _totalAmount, uint _bonusWeekBlock, address _weekUser, address _lastUser, int _blockCountDown, int _lastCountDown) {
        _totalAmount = bonusPool.totalAmount;
        _bonusWeekBlock = bonusPool.bonusWeekBlock;
        _weekUser = bonusPool.weekBonusUser;
        _lastUser = bonusPool.lastBonusUser;
         
        _blockCountDown = int256(bonusPool.bonusWeekBlock) + int256(BONUS_TIMEOUT_WEEK) - int256(block.number);
        _lastCountDown = int256(bonusPool.bonusWeekBlockWithoutUser) + int256(BONUS_TIMEOUT_NO_USER) - int256(block.number);
    }
     
     
    function getWeekData() public view returns (address[] memory, uint[] memory ) {
         
         
         
        address[] memory _playerList = new address[](3);
        uint[] memory _playerCount = new uint[](3);

         
        for (uint i = 0; i < 3; i++) {
            
            _playerList[i] = weekData[2 - i];
            _playerCount[i] = playerBook[_playerList[i]].playerWeekCount;
        }

        return (_playerList, _playerCount);
    }

     
    function withdrawProfit() public {
        address payable _user = msg.sender;

        uint tempProfit = playerBook[_user].profit;
        playerBook[_user].profit = 0;
        uint tempRecommandBonus = playerBook[_user].recomandBonus;
        playerBook[_user].recomandBonus = 0;

        _user.transfer(tempProfit);
        _user.transfer(tempRecommandBonus);

        emit LogWithdrawProfit (_user, tempProfit, tempRecommandBonus, now);
    }



    function setWhiteList (address _user, bool _val) external onlyOwner() {
        whiteList[_user] = _val;
    }

    function getWhiteList() external view returns (bool) {
        return whiteList[msg.sender];
    }

    function getOwnerProfit() external view returns (uint) {
         
        require(msg.sender == 0xa977c1A3AFBDCe730B337921965C2e8146a115Ec || msg.sender == owner, "not client!");
        return _ghostProfit;
    }

    function withdrawOwnerProfit() external {

         
        require(msg.sender == 0xa977c1A3AFBDCe730B337921965C2e8146a115Ec, "not client!");

        uint _tmpProfit = _ghostProfit;
        _ghostProfit = 0;
         
        developer.transfer(_tmpProfit.mul(120).div(1000)); 

        0x53B29e5946EF1dC0Eb3874f6c2937352C9C6860B.transfer(_tmpProfit.mul(35).div(1000));
        0x21ef21b77d2E707D695E7147CFCee3D10f828B99.transfer(_tmpProfit.mul(20).div(1000));
        0xa977c1A3AFBDCe730B337921965C2e8146a115Ec.transfer(_tmpProfit.mul(7).div(1000));
        0xD8e8fc1Fba7B4e265b1B8C01c4B8C59c91CBFE7f.transfer(_tmpProfit.mul(7).div(1000));
        0x428155a346C333EB902874c2eD5c14BC83deca6e.transfer(_tmpProfit.mul(138).div(1000));
        0xf9a749aD0379F00d33d3EAAAE1b9af9F1C163A8b.transfer(_tmpProfit.mul(138).div(1000));

        0x2C66893DdbEc0f1a1c3FE4722f75Bd522635c1b1.transfer(_tmpProfit.mul(42).div(1000));
        0x0093De1e58FE074df7eFCbf02b70a5442758f7E4.transfer(_tmpProfit.mul(28).div(1000));
        0x0e887B5428677A18016594d7C08C9Ff4D0Cea68C.transfer(_tmpProfit.mul(21).div(1000));
        0xe25A30c3b0D27110B8A6Bab1bc0892520188044d.transfer(_tmpProfit.mul(14).div(1000));
        0x6F1A7E003A2196791141458Cf268b36789e6402c.transfer(_tmpProfit.mul(7).div(1000));
        0xD2FcB5d457486cfb91F54183F423238264556297.transfer(_tmpProfit.mul(7).div(1000));
        
        0x56421540046f15e01F28a1b9BB57868Fb69E8cb5.transfer(_tmpProfit.mul(14).div(1000));
        0x7032D5d8C152e92588CA7B1Cf960f8689A2A29c5.transfer(_tmpProfit.mul(7).div(1000));
        0x1b51C606fb38961525F45C4b7d09D30c5099bE2B.transfer(_tmpProfit.mul(7).div(1000));
        0x66419f617614e4d09173aA58Cf1D5A14A620866D.transfer(_tmpProfit.mul(7).div(1000));
        0x7c6e7BB22AAC6D1b1536bbD12f151800Bc81058b.transfer(_tmpProfit.mul(21).div(1000));
        0x4eEd6897Bf36dF119E091346171402F6dC3b718D.transfer(_tmpProfit.mul(20).div(1000));
        0x5198D696091160942817e4a9D882BF9316F9d550.transfer(_tmpProfit.mul(70).div(1000));
        0xAEB6a7c1aBa40cd82e4E1A0F856E8183392F9345.transfer(_tmpProfit.mul(21).div(1000));
        0x3B8e84621fd452275D187129E4A3b0a586f8522C.transfer(_tmpProfit.mul(175).div(10000)); 

        0x2EEB261D9efE5450A16ee5ee766F700EB7422338.transfer(_tmpProfit.mul(21).div(1000));
        0xeA1D5877d4fBBbf296253beCd0c7BCd810D562ad.transfer(_tmpProfit.mul(7).div(1000));
        0x22E4DD2D289143e76ac75C4e8d932a81c2Afd1A7.transfer(_tmpProfit.mul(7).div(1000));
        0x8C46F2554035fab7c15a8bb21eaAc84B51F4A1ea.transfer(_tmpProfit.mul(14).div(1000));
        0xA89a904D80F7b4E10194c6D412D8b03E5c7076c8.transfer(_tmpProfit.mul(7).div(1000));
        0xd462EbD49749e36c1Ca71cded0cE90beC5046530.transfer(_tmpProfit.mul(7).div(1000));
        0xaD5019575E66010199Ae53E221693Ac938Fb4C23.transfer(_tmpProfit.mul(7).div(1000));
        0x58a54afE966e2D30C4fb8242173a2c6D68B53b7C.transfer(_tmpProfit.mul(7).div(1000));
        0xd77e1941E6FC1936096BD755bf15C77bcd9a3979.transfer(_tmpProfit.mul(14).div(1000));
        0x9f7404d8Daf4Ecb28a65251489d94f75AFC9B5d6.transfer(_tmpProfit.mul(14).div(1000));
        0x425B1314d3E85e5Cfc1cAF4839AaB8ad578cc5D2.transfer(_tmpProfit.mul(14).div(1000));
        0x9BB9FA17ee5c4d4943794deAF7bA033Abb64863F.transfer(_tmpProfit.mul(14).div(1000));
        0x80169b7782EAe698D3049cE791a69de7A547d0f8.transfer(_tmpProfit.mul(7).div(1000));
        0x904fedEcd2cdbE7B609aD33695d9e9eB55025537.transfer(_tmpProfit.mul(7).div(1000));
        0x7959872789e5d52A3775C52B29D6F48fF8405331.transfer(_tmpProfit.mul(7).div(1000));
        0xC4fd6b055E281e43a2efDF5DfbB654B64939068d.transfer(_tmpProfit.mul(7).div(1000));
        0x5788e3bdd1FE961a354B9640a87594F6dd013930.transfer(_tmpProfit.mul(10).div(1000));
        0x83129ca07f4c5df17C609559D70F63A8E8AC4E00.transfer(_tmpProfit.mul(35).div(10000)); 
        0x452929C2E67865cd81fCbe1B8fB63CE169d47d27.transfer(_tmpProfit.mul(7).div(1000));
        0xd1E0206242A382bE0FaE34fe9787fcfa45bc7ea5.transfer(_tmpProfit.mul(25).div(1000));
        0xdF7e30bBCA56D83F019B067bE48953991Ae1C4F8.transfer(_tmpProfit.mul(25).div(1000));

        emit LogWithdrawOwnerProfit(owner, _tmpProfit);
    }

    function () external payable  { owner.transfer(msg.value); }
}