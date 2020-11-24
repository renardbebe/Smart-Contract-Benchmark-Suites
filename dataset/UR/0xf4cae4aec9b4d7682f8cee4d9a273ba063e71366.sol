 

contract EtherTopDog {

	 
	uint private bailoutBalance = 0;


	 
	
	 
	uint constant private bailoutFundPercent = 70;

	 
	uint constant private topDogDividend = 15;

	 
	uint constant private topDogDecayPercent = 10;

	 
	uint constant private luckyDogDividend = 3;

	 
	uint constant private visionDogFeePercent = 2;

	 

	
	 
	uint constant private topDogMinMarkup = 125;

	 
	 
	 
	uint private topDogMinPrice = 1;

	 
	 
	uint constant private topDogBuyoutRange = 150;

	 
	uint constant private visionDogBuyPercent = 5;



	 
	 
	 
	uint private underDogMarkup = 150;

	 
	 
	 
	 
	uint private topDogPriceCeiling = 0;
	uint private topDogPriceFloor = 0;

	 
	uint private visionFees = 0;

	 
	address private topDog = 0x0;

	 
	struct Underdog {
		address addr;
		uint deposit;
		uint payout;
		uint bailouts;
	}
	Underdog[] private Underdogs;

	 
	mapping (address => string) dogNames;

	 
	 
	 
	uint private luckyDog = 0;

	 
	uint private payoutIndex = 0;

	 
	 
	uint private payoutCount = 0;

	 
	address private visionDog;

	function EtherTopDog() {
		visionDog = msg.sender;
	}


	 
	function underdogPayoutFund() public constant returns (uint balance) {
		balance = bailoutBalance;
	}

	function nextUnderdogPayout() public constant returns (uint) {
		if (Underdogs.length - payoutIndex >= 1) {
			return Underdogs[payoutIndex].payout;
		}
	}
	

	function underdogPayoutMarkup() public constant returns (uint) {
		return underDogMarkup;
	}

	function topDogInfo() public constant returns (string name, uint strength) {
		if (topDog != address(0x0)) {
			name = getDogName(topDog);
		} else {
			name = "[not set]";
		}
		strength = topDogMinPrice;
	}
	function luckyDogInfo() public constant returns (string name) {
		if (luckyDog > 0) {
			name = getDogName(Underdogs[luckyDog].addr);
		} else {
			name = "[nobody]";
		}
	}

	function underdogCount() constant returns (uint) {
		return Underdogs.length - payoutIndex;
	} 

	function underdogInfo(uint linePosition) constant returns (string name, address dogAddress, uint deposit, uint payout, uint scrapBonus) {
		if (linePosition > 0 && linePosition <= Underdogs.length - payoutIndex) {

			Underdog thedog = Underdogs[payoutIndex + (linePosition - 1)];
			name = getDogName(thedog.addr);
			dogAddress = thedog.addr;
			deposit = thedog.deposit;
			payout= thedog.payout;
			scrapBonus = thedog.bailouts;
		}
	}

	 



	 

	 
	function() {
		dogFight();
	}
	
	 
	function setName(string DogName) {
		if (bytes(DogName).length >= 2 && bytes(DogName).length <= 16)
			dogNames[msg.sender] = DogName;

		 
		if (msg.value > 0) {
			dogFight();
		}
		
	}

	function dogFight() public {
		 
		if (msg.value < 1 ether) {
			msg.sender.send(msg.value);
			return;
		}

		 
		if (topDog != address(0x0)) {

			 
			uint topDogPrice = topDogMinPrice + randInt( (topDogMinPrice * topDogBuyoutRange / 100) - topDogMinPrice, 4321);

			 
			if (msg.value >= topDogPrice) {
				 
				buyTopDog(topDogPrice, msg.value - topDogPrice);
			} else {
				 
				addUnderDog(msg.value);
			}
		} else {
			 
			 

			 
			topDog = msg.sender;

			topDogPriceFloor = topDogMinPrice;

			bailoutBalance += msg.value;
			topDogMinPrice = msg.value * topDogMinMarkup / 100;

			topDogPriceCeiling = topDogMinPrice;

		}
	}

	 



	 
	function addUnderDog(uint buyin) private {

		uint bailcount = 0;

		 
		uint payoutval = buyin * underDogMarkup / 100;

		 
		bailoutBalance += buyin * bailoutFundPercent / 100;

		 
		uint topdividend = buyin * topDogDividend / 100;
		uint luckydividend = buyin * luckyDogDividend / 100;

		 
		if (luckyDog != 0 && luckyDog >= payoutIndex) {
			 
			Underdogs[luckyDog].addr.send(luckydividend);
		} else {
			 
			topdividend += luckydividend;
		}

		 
		topDog.send(topdividend);


		 
		uint topdecay = (buyin * topDogDecayPercent / 100);
		topDogMinPrice -= topdecay;

		 

		 
		uint decayfactor = 0;

		 
		if (topDogMinPrice > topDogPriceFloor) {
			uint decayrange = (topDogPriceCeiling - topDogPriceFloor);
			decayfactor = 100000 * (topDogPriceCeiling - topDogMinPrice) / decayrange;
		} else {
			decayfactor = 100000;
		}
		 
		underDogMarkup = 150 - (decayfactor * 30 / 100000);



		 
		visionFees += (buyin * visionDogFeePercent / 100);
		

		 
		while (payoutIndex < Underdogs.length && bailoutBalance >= Underdogs[payoutIndex].payout ) {
			payoutCount -= Underdogs[payoutIndex].bailouts;
			bailoutBalance -= Underdogs[payoutIndex].payout;
			Underdogs[payoutIndex].addr.send(Underdogs[payoutIndex].payout);


			 
			if (payoutIndex == luckyDog && luckyDog != 0)
				luckyDog = Underdogs.length;

			payoutIndex++;
			bailcount++;
			payoutCount++;
		}

		
		 
		Underdogs.push(Underdog(msg.sender, buyin, payoutval, bailcount));

	}

	function buyTopDog(uint buyprice, uint surplus) private {

		 
		uint vfee = buyprice * visionDogBuyPercent / 100;

		uint dogpayoff = (buyprice - vfee);

		 
		topDog.send(dogpayoff);

		visionFees += vfee;

		 
		visionDog.send(visionFees);
		visionFees = 0;

		 
		 
		topDogPriceFloor = topDogMinPrice;

		 
		topDogMinPrice = msg.value * topDogMinMarkup / 100;

		 
		topDogPriceCeiling = topDogMinPrice;


		 
 
			 
 
 
			 
 
 
		

		 
		underDogMarkup = 150;

		 
		uint linelength = Underdogs.length - payoutIndex;

		 
		 


		 
		if (surplus > 0 && linelength > 0 ) {
			throwScraps(surplus);
		}


		 
		if (linelength > 0) {

			 

			 
			 
			 
			 
			 
			 

			 
			 
			 

			uint luckypickline = (linelength % 2 == 1) ?
				( linelength / 2 + 1 ) + (linelength + 1) * (linelength / 2) :   
				( (linelength + 1) * (linelength / 2)  );  

			uint luckypick = randInt(luckypickline, 69);
	
			uint pickpos = luckypickline - linelength;
			uint linepos = 1;

			while (pickpos >= luckypick && linepos < linelength) {
				pickpos -= (linelength - linepos);
				linepos++;
			}

			luckyDog = Underdogs.length - linepos;
		} else {
			 
			 
			luckyDog = 0;
		}
		

		 
		topDog = msg.sender;
	}

	function throwScraps(uint totalscrapvalue) private {

		 
		uint linelength = Underdogs.length - payoutIndex;

		 
		 
		uint skipstep = (linelength / 7) + 1;

		 
		uint pieces = linelength / skipstep;

		 
		uint startoffset = randInt(skipstep, 42) - 1;

		 
		uint scrapbasesize = totalscrapvalue / (pieces + payoutCount);

		 
		if (scrapbasesize < 500 finney) {
			scrapbasesize = 500 finney;
		}

		uint scrapsize;
		uint sptr = Underdogs.length - 1 - startoffset;

		uint scrapvalueleft = totalscrapvalue;

		while (pieces > 0 && scrapvalueleft > 0 && sptr >= payoutIndex) {
			 
			 
			scrapsize = scrapbasesize * (Underdogs[sptr].bailouts + 1);


			 
			if (scrapsize < scrapvalueleft) {
				scrapvalueleft -= scrapsize;
			} else {
				scrapsize = scrapvalueleft;
				scrapvalueleft = 0;
			}

			 
			Underdogs[sptr].addr.send(scrapsize);
			pieces--;
			sptr -= skipstep;
		}

		 
		if (scrapvalueleft > 0) {
			bailoutBalance += scrapvalueleft;
		}
	}

	function getDogName(address adr) private constant returns (string thename) {
		if (bytes(dogNames[adr]).length > 0)
			thename = dogNames[adr];
		else
			thename = 'Unnamed Mutt';
	}
	
	 
	function randInt(uint max, uint seedswitch) private constant returns (uint randomNumber) {
		return( uint(sha3(block.blockhash(block.number-1), block.timestamp + seedswitch) ) % max + 1 );
	}
}