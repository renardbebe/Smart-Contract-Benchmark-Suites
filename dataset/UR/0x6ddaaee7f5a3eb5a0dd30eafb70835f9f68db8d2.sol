 

pragma solidity ^0.4.25;


 


 
 
 
 
 

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





 
 
 
 
 

 
 
 
 
 
 
 


 
 
 

contract SuperCountriesExternal {
  using SafeMath for uint256; 

	function ownerOf(uint256) public pure returns (address) {	}
	
	function priceOf(uint256) public pure returns (uint256) { }
}



 
 
 

contract SuperCountriesTrophyCardsExternal {
  using SafeMath for uint256;
  
	function countTrophyCards() public pure returns (uint256) {	}
	
	function getTrophyCardIdFromIndex(uint256) public pure returns (uint256) {	}
}






 
 
 
 
 

 
 
 
 
 
 
 

contract SuperCountriesWar {
  using SafeMath for uint256;

 
 
 
 
   
	constructor () public {
		owner = msg.sender;

		continentKing.length = 16;
		newOwner.length = 256;
		nukerAddress.length = 256;		
	}
	
	address public owner;  

	
	
	
	
	
 
 
 
	
   
	modifier onlyOwner() {
		require(owner == msg.sender);
		_;
	}

	
	
   
	modifier onlyRealAddress() {
		require(msg.sender != address(0));
		_;
	}
	
	
	
   	
	modifier onlyGameNOTPaused() {
		require(gameRunning == true);
		_;
	}

	

	 	
	modifier onlyGamePaused() {
		require(gameRunning == false);
		_;
	}
    
	
	
	


	
 
 
 

 
	function nextTrophyCardUpdateAndGetOwner() internal returns (address){
		uint256 cardsLength = getTrophyCount();
		address trophyCardOwner;
		
		if (nextTrophyCardToGetDivs < cardsLength){
				uint256 nextCard = getTrophyFromIndex(nextTrophyCardToGetDivs);
				trophyCardOwner = getCountryOwner(nextCard);	
		}
		
		 
		if (nextTrophyCardToGetDivs.add(1) < cardsLength){
				nextTrophyCardToGetDivs++;			
		}
			else nextTrophyCardToGetDivs = 0;
			
		return trophyCardOwner;			
	} 

	

 
	function getNextTrophyCardOwner() 
		public 
		view 
		returns (
			address nextTrophyCardOwner_,
			uint256 nextTrophyCardIndex_,
			uint256 nextTrophyCardId_
		)
	{
		uint256 cardsLength = getTrophyCount();
		address trophyCardOwner;
		
		if (nextTrophyCardToGetDivs < cardsLength){
				uint256 nextCard = getTrophyFromIndex(nextTrophyCardToGetDivs);
				trophyCardOwner = getCountryOwner(nextCard);
		}
			
		return (
			trophyCardOwner,
			nextTrophyCardToGetDivs,
			nextCard
		);
	}
	
	
	

	
	
 
 
 
	
 
	address private contractSC = 0xdf203118A954c918b967a94E51f3570a2FAbA4Ac;  
	address private contractTrophyCards = 0xEaf763328604e6e54159aba7bF1394f2FbcC016e;  
		
	SuperCountriesExternal SC = SuperCountriesExternal(contractSC);
	SuperCountriesTrophyCardsExternal SCTrophy = SuperCountriesTrophyCardsExternal(contractTrophyCards);
	
	


	
 
 
 
	
 
	function getCountryOwner(uint256 _countryId) public view returns (address){        
		return SC.ownerOf(_countryId);
    }
	
	
 
	function getPriceOfCountry(uint256 _countryId) public view returns (uint256){			
		return SC.priceOf(_countryId);
	}

	
 
	function getTrophyFromIndex(uint256 _index) public view returns (uint256){			
		return SCTrophy.getTrophyCardIdFromIndex(_index);
	}

	
 
	function getTrophyCount() public view returns (uint256){			
		return SCTrophy.countTrophyCards();
	}
	




	
 
 
 
	
 
	bool private gameRunning;
	uint256 private gameVersion = 1;  

	
 
	uint256 private jackpotTimestamp;  
	mapping(uint256 => bool) private thisJackpotIsPlayedAndNotWon;  

	
 
 
	mapping(uint256 => mapping(address => uint256)) private winnersJackpot; 
	mapping(uint256 => uint256) private winningCountry;  

	
 
	uint256 private startingPrice = 1e16;  
	mapping(uint256 => uint256) private nextPrice;  
	uint256 private kingPrice = 9e15;  

	
 
	uint256 private kCountry = 4;  
	uint256 private kCountryLimit = 5e17;  
	uint256 private kNext = 1037;  
	uint256 private maxFlips = 16;  
	uint256 private continentFlips;  
	uint256 private kKings = 101;  
	

 
	address[] private continentKing;

	
 
	address[] private nukerAddress;

	
 
	struct LoverStructure {
		mapping(uint256 => mapping(address => uint256)) loves;  
		mapping(uint256 => uint256) maxLoves;  
		address bestLover;  
		}

	mapping(uint256 => mapping(uint256 => LoverStructure)) private loversSTR;  
	uint256 private mostLovedCountry;  
	
	mapping(address => uint256) private firstLove;  
	mapping(address => uint256) private remainingLoves;  
	uint256 private freeRemainingLovesPerDay = 2;  

	
 
	uint256 private devCut = 280;  
	uint256 private playerCut = 20;  
	uint256 private potCutSuperCountries = 185;
	

 
	uint256 private lastNukerShare = 5000;
	uint256 private winningCountryShare = 4400;  
	uint256 private continentShare = 450;
	uint256 private freePlayerShare = 150;


 
	uint256 private lastNukerMin = 3e18;  
	uint256 private countryOwnerMin = 3e18;  
	uint256 private continentMin = 1e18;  
	uint256 private freePlayerMin = 1e18;  
	uint256 private withdrawMinOwner;  


 
	uint256 private nextTrophyCardToGetDivs;  
	
	
 
	uint256 private allCountriesLength = 256;  
	mapping(uint256 => mapping(uint256 => bool)) private eliminated;  
	uint256 private howManyEliminated;  
	uint256 private howManyNuked;  
	uint256 private howManyReactivated;  
	uint256 private lastNukedCountry;  
	mapping(uint256 => uint256) lastKnownCountryPrice;  
	address[] private newOwner;  

 
	mapping(uint256 => uint256) private countryToContinent;  

	
 
	uint256 public SLONG = 86400;  
	uint256 public DLONG = 172800;  
	uint256 public DSHORT = 14400;  
	
	
	

	
 
 
 

	 
	event PausedOrUnpaused(uint256 indexed blockTimestamp_, bool indexed gameRunning_);
	
	 
	event NewGameLaunched(uint256 indexed gameVersion_, uint256 indexed blockTimestamp_, address indexed msgSender_, uint256 jackpotTimestamp_);
	event ErrorCountry(uint256 indexed countryId_);
	
	 
	event CutsUpdated(uint256 indexed newDevcut_, uint256 newPlayercut_, uint256 newJackpotCountriescut_, uint256 indexed blockTimestamp_);	
	event ConstantsUpdated(uint256 indexed newStartPrice_, uint256 indexed newkKingPrice_, uint256 newKNext_, uint256 newKCountry_, uint256 newKLimit_, uint256 newkKings, uint256 newMaxFlips);
	event NewContractAddress(address indexed newAddress_);
	event NewValue(uint256 indexed code_, uint256 indexed newValue_, uint256 indexed blockTimestamp_);
	event NewCountryToContinent(uint256 indexed countryId_, uint256 indexed continentId_, uint256 indexed blockTimestamp_);		
	
	 
	event PlayerEvent(uint256 indexed eventCode_, uint256 indexed countryId_, address indexed player_, uint256 timestampNow_, uint256 customValue_, uint256 gameId_);
	event Nuked(address indexed player_, uint256 indexed lastNukedCountry_, uint256 priceToPay_, uint256 priceRaw_);	
	event Reactivation(uint256 indexed countryId_, uint256 indexed howManyReactivated_);
	event NewKingContinent(address indexed player_, uint256 indexed continentId_, uint256 priceToPay_);
	event newMostLovedCountry(uint256 indexed countryId_, uint256 indexed maxLovesBest_);
	event NewBestLover(address indexed lover_, uint256 indexed countryId_, uint256 maxLovesBest_);	
	event NewLove(address indexed lover_, uint256 indexed countryId_, uint256 playerLoves_, uint256 indexed gameId_, uint256 nukeCount_);
	event LastCountryStanding(uint256 indexed countryId_, address indexed player_, uint256 contractBalance_, uint256 indexed gameId_, uint256 jackpotTimestamp);
	event ThereIsANewOwner(address indexed newOwner_, uint256 indexed countryId_);
	
	 
	event CutsPaidInfos(uint256 indexed blockTimestamp_, uint256 indexed countryId_, address countryOwner_, address trophyCardOwner_, address bestLover_);
	event CutsPaidValue(uint256 indexed blockTimestamp_, uint256 indexed paidPrice_, uint256 thisBalance_, uint256 devCut_, uint256 playerCut_, uint256 indexed SuperCountriesCut_);
	event CutsPaidLight(uint256 indexed blockTimestamp_, uint256 indexed paidPrice_, uint256 thisBalance_, uint256 devCut_, uint256 playerCut_, address trophyCardOwner_, uint256 indexed SuperCountriesCut_);
	event NewKingPrice(uint256 indexed kingPrice_, uint256 indexed kKings_);
		
	 
	event NewJackpotTimestamp(uint256 indexed jackpotTimestamp_, uint256 indexed timestamp_);
	event WithdrawByDev(uint256 indexed blockTimestamp_, uint256 indexed withdrawn_, uint256 indexed withdrawMinOwner_, uint256 jackpot_);
	event WithdrawJackpot(address indexed winnerAddress_, uint256 indexed jackpotToTransfer_, uint256 indexed gameVersion_);	
	event JackpotDispatch(address indexed winner, uint256 indexed jackpotShare_, uint256 customValue_, bytes32 indexed customText_);
	event JackpotDispatchAll(uint256 indexed gameVersion_, uint256 indexed winningCountry_, uint256 indexed continentId_, uint256 timestampNow_, uint256 jackpotTimestamp_, uint256 pot_,uint256 potDispatched_, uint256 thisBalance);

	

	
	

 
 
 
	
 
 
 

 
	function canPlayTimestamp() public view returns (bool ok_){
		uint256 timestampNow = block.timestamp;
		uint256 jT = jackpotTimestamp;
		bool canPlayTimestamp_;
		
			if (timestampNow < jT || timestampNow > jT.add(DSHORT)){
				canPlayTimestamp_ = true;		
			}
		
		return canPlayTimestamp_;	
	}


	
	
 
	function isEliminated(uint256 _countryId) public view returns (bool isEliminated_){
		return eliminated[gameVersion][_countryId];
	}


	
	
 
	function canPlayerLove(address _player) public view returns (bool playerCanLove_){	
		if (firstLove[_player].add(SLONG) > block.timestamp && remainingLoves[_player] == 0){
			bool canLove = false;
		} else canLove = true;	

		return canLove;
	}

	
	
	
 
 
	function canPlayerReanimate(
		uint256 _countryId,
		address _player
	)
		public
		view
		returns (bool canReanimate_)
	{	
		if (
			(lastKnownCountryPrice[_countryId] < getPriceOfCountry(_countryId))	&&
			(isEliminated(_countryId) == true) &&
			(_countryId != lastNukedCountry) &&
			(block.timestamp.add(SLONG) < jackpotTimestamp || block.timestamp > jackpotTimestamp.add(DSHORT)) &&
			(allCountriesLength.sub(howManyEliminated) > 8) &&  
			((howManyReactivated.add(1)).mul(8) < howManyNuked) &&  
			(lastKnownCountryPrice[_countryId] > 0) &&
			(_player == getCountryOwner(_countryId))
			) {
				bool canReanima = true;				
			} else canReanima = false;		
		
		return canReanima;
	}	

	
	
	
 
	function constant_getGameVersion() public view returns (uint256 currentGameVersion_){
		return gameVersion;
	}


	
	
 
	function country_getInfoForCountry(uint256 _countryId) 
		public 
		view 
		returns (
			bool eliminatedBool_,
			uint256 whichContinent_,
			address currentBestLover_,
			uint256 maxLovesForTheBest_,
			address countryOwner_,
			uint256 lastKnownPrice_
		) 
	{		
		LoverStructure storage c = loversSTR[gameVersion][_countryId];
		if (eliminated[gameVersion][_countryId]){uint256 nukecount = howManyNuked.sub(1);} else nukecount = howManyNuked;
		
		return (
			eliminated[gameVersion][_countryId],
			countryToContinent[_countryId],
			c.bestLover,
			c.maxLoves[nukecount],
			newOwner[_countryId],
			lastKnownCountryPrice[_countryId]
		);
	}
	
	
	
	
 
	function loves_getLoves(uint256 _countryId, address _player) public view returns (uint256 loves_) {				
		LoverStructure storage c = loversSTR[gameVersion][_countryId];
		return c.loves[howManyNuked][_player];
	}

	
	
	
 
	function loves_getOldLoves(
		uint256 _countryId,
		address _player,
		uint256 _gameId,
		uint256 _oldHowManyNuked
	) 
		public 
		view 
		returns (uint256 loves_) 
	{		
		return loversSTR[_gameId][_countryId].loves[_oldHowManyNuked][_player];
	}

	
	
	
 
	function loves_getPlayerInfo(address _player) 
		public 
		view 
		returns (
			uint256 playerFirstLove_,
			uint256 playerRemainingLoves_,
			uint256 realRemainingLoves_
		) 
	{
		uint256 timestampNow = block.timestamp;
		uint256 firstLoveAdd24 = firstLove[_player].add(SLONG);
		uint256 firstLoveAdd48 = firstLove[_player].add(DLONG);
		uint256 remainStored = remainingLoves[_player];
		
		 
		if (firstLoveAdd24 > timestampNow && remainStored > 0){
			uint256 remainReal = remainStored;
		}
			 
			else if (firstLoveAdd24 < timestampNow && firstLoveAdd48 > timestampNow){
				remainReal = (howManyEliminated.div(4)).add(freeRemainingLovesPerDay).add(1);
			}		
				 
				else if (firstLoveAdd48 < timestampNow){
					remainReal = freeRemainingLovesPerDay.add(1);
				}		
					else remainReal = 0;
			
		return (
			firstLove[_player],
			remainStored,
			remainReal
		); 
	}

	
	

 
	function player_getPlayerJackpot(
		address _player,
		uint256 _gameId
	) 
		public 
		view 
		returns (
			uint256 playerNowPot_,
			uint256 playerOldPot_
		)
	{
		return (
			winnersJackpot[gameVersion][_player],
			winnersJackpot[_gameId][_player]
		);
	}	


	
	
 
	function country_getOldInfoForCountry(uint256 _countryId, uint256 _gameId)
		public
		view
		returns (
			bool oldEliminatedBool_,
			uint256 oldMaxLovesForTheBest_
		) 
	{	
		LoverStructure storage c = loversSTR[_gameId][_countryId];
		
		return (
			eliminated[_gameId][_countryId],
			c.maxLoves[howManyNuked]
			);
	}
	
	
	
	
 
	function loves_getOldNukesMaxLoves(
		uint256 _countryId,
		uint256 _gameId,
		uint256 _howManyNuked
	) 
		public view returns (uint256 oldMaxLovesForTheBest2_)
	{		
		return (loversSTR[_gameId][_countryId].maxLoves[_howManyNuked]);
	}	
	

	

 
	function country_getCountriesGeneralInfo()
		public
		view
		returns (
			uint256 lastNuked_,
			address lastNukerAddress_,
			uint256 allCountriesLength_,
			uint256 howManyEliminated_,
			uint256 howManyNuked_,
			uint256 howManyReactivated_,
			uint256 mostLovedNation_
		) 
	{		
		return (
			lastNukedCountry,
			nukerAddress[lastNukedCountry],
			allCountriesLength,			
			howManyEliminated,
			howManyNuked,
			howManyReactivated,
			mostLovedCountry
			);
	}


	
	
 
	function player_getKingOne(uint256 _continentId) public view returns (address king_) {		
		return continentKing[_continentId];
	}

	

	
 
	function player_getKingsAll() public view returns (address[] _kings) {	
		
		uint256 kingsLength = continentKing.length;
		address[] memory kings = new address[](kingsLength);
		uint256 kingsCounter = 0;
			
		for (uint256 i = 0; i < kingsLength; i++) {
			kings[kingsCounter] = continentKing[i];
			kingsCounter++;				
		}
		
		return kings;
	}
	

	

 
	function constant_getLength()
		public
		view
		returns (
			uint256 kingsLength_,
			uint256 newOwnerLength_,
			uint256 nukerLength_
		)
	{		
		return (
			continentKing.length,
			newOwner.length,
			nukerAddress.length
		);
	}

	
	

 
	function player_getNuker(uint256 _countryId) public view returns (address nuker_) {		
		return nukerAddress[_countryId];		
	}

	
	
	
 
 
	function player_howManyNuked(address _player) public view returns (uint256 nukeCount_) {		
		uint256 counter = 0;

		for (uint256 i = 0; i < nukerAddress.length; i++) {
			if (nukerAddress[i] == _player) {
				counter++;
			}
		}

		return counter;		
	}
	
	
	
	
 
	function player_getNukedCountries(address _player) public view returns (uint256[] myNukedCountriesIds_) {		
		
		uint256 howLong = player_howManyNuked(_player);
		uint256[] memory myNukedCountries = new uint256[](howLong);
		uint256 nukeCounter = 0;
		
		for (uint256 i = 0; i < allCountriesLength; i++) {
			if (nukerAddress[i] == _player){
				myNukedCountries[nukeCounter] = i;
				nukeCounter++;
			}

			if (nukeCounter == howLong){break;}
		}
		
		return myNukedCountries;
	}


	
	
 
	function constant_getPriZZZes() 
		public 
		view 
		returns (
			uint256 lastNukeShare_,
			uint256 countryOwnShare_,
			uint256 contintShare_,
			uint256 freePlayerShare_
		) 
	{
		return (
			lastNukerShare,
			winningCountryShare,
			continentShare,
			freePlayerShare
		);
	}

	
		
	
 
 
	function constant_getPriZZZesMini()
		public
		view
		returns (
			uint256 lastNukeMini_,
			uint256 countryOwnMini_,
			uint256 contintMini_,
			uint256 freePlayerMini_,
			uint256 withdrMinOwner_
		)
	{
		return (
			lastNukerMin,
			countryOwnerMin,
			continentMin,
			freePlayerMin,
			withdrawMinOwner
		);
	}

	
	

 
	function constant_getPrices()
		public 
		view 
		returns (
			uint256 nextPrice_,
			uint256 startingPrice_,
			uint256 kingPrice_,
			uint256 kNext_,
			uint256 kCountry_,
			uint256 kCountryLimit_,
			uint256 kKings_)
	{
		return (
			nextPrice[gameVersion],
			startingPrice,
			kingPrice,
			kNext,
			kCountry,
			kCountryLimit,
			kKings
		);
	}

	
	
	
 
	function constant_getSomeDetails()
		public
		view
		returns (
			bool gameRunng_,
			uint256 currentContractBalance_,
			uint256 jackptTimstmp_,
			uint256 maxFlip_,
			uint256 continentFlip_,
			bool jackpotNotWonYet_) 
	{
		return (
			gameRunning,
			address(this).balance,
			jackpotTimestamp,
			maxFlips,
			continentFlips,
			thisJackpotIsPlayedAndNotWon[gameVersion]
		);
	}

	
	

 
	function constant_getOldDetails(uint256 _gameId)
		public
		view
		returns (
			uint256 oldWinningCountry_,
			bool oldJackpotBool_,
			uint256 oldNextPrice_
		) 
	{
		return (
			winningCountry[_gameId],
			thisJackpotIsPlayedAndNotWon[_gameId],
			nextPrice[_gameId]
		);
	}
	
	
	
	
 
	function constant_getCuts()
		public
		view
		returns (
			uint256 playerCut_,
			uint256 potCutSC,
			uint256 developerCut_)
	{
		return (
			playerCut,
			potCutSuperCountries,
			devCut
		);
	}

	
	

 
	function constant_getContracts() public view returns (address SuperCountries_, address TrophyCards_) {
		return (contractSC, contractTrophyCards);
	}	


	
	
 
 
	function war_getNextNukePriceRaw() public view returns (uint256 price_) {
		
		if (nextPrice[gameVersion] != 0) {
			uint256 price = nextPrice[gameVersion];
		}
			else price = startingPrice;
		
		return price;		
	}

	
	
		
 
	function war_getNextNukePriceForCountry(uint256 _countryId) public view returns (uint256 priceOfThisCountry_) {

		uint256 priceRaw = war_getNextNukePriceRaw();
		uint256 k = lastKnownCountryPrice[_countryId].mul(kCountry).div(100);
		
		if (k > kCountryLimit){
			uint256 priceOfThisCountry = priceRaw.add(kCountryLimit);
		}
			else priceOfThisCountry = priceRaw.add(k);				
	
		return priceOfThisCountry;		
	}
	

	

 
	function country_getAllCountriesForContinent(uint256 _continentId) public view returns (uint256[] countries_) {					
		
		uint256 howManyCountries = country_countCountriesForContinent(_continentId);
		uint256[] memory countries = new uint256[](howManyCountries);
		uint256 countryCounter = 0;
				
		for (uint256 i = 0; i < allCountriesLength; i++) {
			if (countryToContinent[i] == _continentId){
				countries[countryCounter] = i;
				countryCounter++;						
			}	
				if (countryCounter == howManyCountries){break;}
		}

		return countries;
	}

	

	
 
	function country_countCountriesForContinent(uint256 _continentId) public view returns (uint256 howManyCountries_) {
		uint256 countryCounter = 0;
				
		for (uint256 i = 0; i < allCountriesLength; i++) {
			if (countryToContinent[i] == _continentId){
				countryCounter++;						
			}		
		}
		
		return countryCounter;
	}	


	
		
 
	function country_getAllStandingCountriesForContinent(
		uint256 _continentId,
		bool _standing
	) 
		public
		view
		returns (uint256[] countries_)
	{					
		uint256 howManyCountries = country_countStandingCountriesForContinent(_continentId, _standing);
		uint256[] memory countries = new uint256[](howManyCountries);
		uint256 countryCounter = 0;
		uint256 gameId = gameVersion;
				
		for (uint256 i = 0; i < allCountriesLength; i++) {
			if (countryToContinent[i] == _continentId && eliminated[gameId][i] != _standing){
				countries[countryCounter] = i;
				countryCounter++;						
			}	
				if (countryCounter == howManyCountries){break;}
		}

		return countries;
	}	

	


 
	function country_countStandingCountriesForContinent(
		uint256 _continentId,
		bool _standing
	)
		public
		view
		returns (uint256 howManyCountries_)
	{
		uint256 standingCountryCounter = 0;
		uint256 gameId = gameVersion;
				
		for (uint256 i = 0; i < allCountriesLength; i++) {
			if (countryToContinent[i] == _continentId && eliminated[gameId][i] != _standing){
				standingCountryCounter++;						
			}		
		}
		
		return standingCountryCounter;
	}


	
	
 
 
 
 
	function calculateJackpot()
		public
		view
		returns (
			uint256 nukerJackpot_,
			uint256 countryJackpot_,
			uint256 continentJackpot_,
			uint256 freeJackpot_,
			uint256 realJackpot_,
			uint256 expectedJackpot_
		)
	{
		 
		 
		if (thisJackpotIsPlayedAndNotWon[gameVersion] != true) {
			uint256 nukerJPT = 0;
			uint256 countryJPT = 0;
			uint256 continentJPT = 0;
			uint256 freeJPT = 0;
			uint256 realJackpotToShare = 0;
			uint256 expectedJackpotFromRates = 0;
		}
		
			else {
				uint256 devGift = lastNukerMin.add(countryOwnerMin).add(continentMin).add(freePlayerMin);
				expectedJackpotFromRates = ((address(this).balance).add(withdrawMinOwner).sub(devGift)).div(10000);
				
					uint256 temp_share = expectedJackpotFromRates.mul(lastNukerShare);
					if (temp_share > lastNukerMin){
						nukerJPT = temp_share;
					} else nukerJPT = lastNukerMin;
					
					temp_share = expectedJackpotFromRates.mul(winningCountryShare);
					if (temp_share > countryOwnerMin){
						countryJPT = temp_share;
					} else countryJPT = countryOwnerMin;

					temp_share = expectedJackpotFromRates.mul(continentShare);
					if (temp_share > continentMin){
						continentJPT = temp_share;
					} else continentJPT = continentMin;

					temp_share = expectedJackpotFromRates.mul(freePlayerShare);
					if (temp_share > freePlayerMin){
						freeJPT = temp_share;
					} else freeJPT = freePlayerMin;		
				
					realJackpotToShare = nukerJPT.add(countryJPT).add(continentJPT).add(freeJPT);
			}
		
		return (
			nukerJPT,
			countryJPT,
			continentJPT,
			freeJPT,
			realJackpotToShare,
			expectedJackpotFromRates.mul(10000)
		);	
	}


	

 
 
	function whatDevCanWithdraw() public view returns(uint256 toWithdrawByDev_){
		uint256 devGift = lastNukerMin.add(countryOwnerMin).add(continentMin).add(freePlayerMin);
		uint256 balance = address(this).balance;
		
		(,,,,uint256 jackpotToDispatch,) = calculateJackpot();
		uint256 leftToWithdraw = devGift.sub(withdrawMinOwner);
		uint256 leftInTheContract = balance.sub(jackpotToDispatch);
			
		if (leftToWithdraw > 0 && balance > jackpotToDispatch){
			 
			if (leftInTheContract > leftToWithdraw){
				uint256 devToWithdraw = leftToWithdraw;				
			} else devToWithdraw = leftInTheContract;			
		}
		
		return devToWithdraw;
	}




	
 
 
 
	
 
 
 

 
	function payCuts(
		uint256 _value,
		uint256 _balance,
		uint256 _countryId,
		uint256 _timestamp
	) 
		internal
	{
		require(_value <= _balance);
		require(_value != 0);
		
		 
		address nextTrophyOwner = nextTrophyCardUpdateAndGetOwner();
		
			if (nextTrophyOwner == 0) {
				nextTrophyOwner = owner;
			}
		
		
		 
		address countryOwner = newOwner[_countryId];
		
			if (countryOwner == 0) {
				countryOwner = owner;
			}		

			
		 
		address bestLoverToGetDivs = loversSTR[gameVersion][_countryId].bestLover;
		
			if (bestLoverToGetDivs == 0) {
				bestLoverToGetDivs = owner;
			}

			
		 
		uint256 devCutPay = _value.mul(devCut).div(1000);
		uint256 superCountriesPotCutPay = _value.mul(potCutSuperCountries).div(1000);
		uint256 trophyAndOwnerCutPay = _value.mul(playerCut).div(1000);
		
		
		 
		owner.transfer(devCutPay);
		contractSC.transfer(superCountriesPotCutPay);
		nextTrophyOwner.transfer(trophyAndOwnerCutPay);
		countryOwner.transfer(trophyAndOwnerCutPay);
		bestLoverToGetDivs.transfer(trophyAndOwnerCutPay);
		
		emit CutsPaidInfos(_timestamp, _countryId, countryOwner, nextTrophyOwner, bestLoverToGetDivs);
		emit CutsPaidValue(_timestamp, _value, address(this).balance, devCutPay, trophyAndOwnerCutPay, superCountriesPotCutPay);
		
		assert(_balance.sub(_value) <= address(this).balance); 
		assert((trophyAndOwnerCutPay.mul(3).add(devCutPay).add(superCountriesPotCutPay)) < _value);	
	}



 
	function payCutsLight(
		uint256 _value,
		uint256 _balance,
		uint256 _timestamp
	) 
		internal
	{
		require(_value <= _balance);
		require(_value != 0);		

		 
		address nextTrophyOwner = nextTrophyCardUpdateAndGetOwner();
		
			if (nextTrophyOwner == 0) {
				nextTrophyOwner = owner;
			}

		 
		address lastNuker = nukerAddress[lastNukedCountry];
		
			if (lastNuker == 0) {
				lastNuker = owner;
			}			
			
			
		 
		uint256 trophyCutPay = _value.mul(playerCut).div(1000);
		uint256 superCountriesPotCutPay = ((_value.mul(potCutSuperCountries).div(1000)).add(trophyCutPay)).div(2);  
		uint256 devCutPay = (_value.mul(devCut).div(1000)).add(trophyCutPay);			

		
		 
		owner.transfer(devCutPay);
		contractSC.transfer(superCountriesPotCutPay);
		lastNuker.transfer(superCountriesPotCutPay);
		nextTrophyOwner.transfer(trophyCutPay);
		
		emit CutsPaidLight(_timestamp, _value, address(this).balance, devCutPay, trophyCutPay, nextTrophyOwner, superCountriesPotCutPay);
		
		assert(_balance.sub(_value) <= address(this).balance); 
		assert((trophyCutPay.add(devCutPay).add(superCountriesPotCutPay)) < _value);
	}
	

	
 
	function excessRefund(
		address _payer,
		uint256 _priceToPay,
		uint256 paidPrice
	) 
		internal
	{		
		uint256 excess = paidPrice.sub(_priceToPay);
		
		if (excess > 0) {
			_payer.transfer(excess);
		}
	}		
	
	
	
 
	function updateJackpotTimestamp(uint256 _timestamp) internal {		

		jackpotTimestamp = _timestamp.add(604800);   
		
		emit NewJackpotTimestamp(jackpotTimestamp, _timestamp);			
	}



 
 
	function updateLovesForToday(address _player, uint256 _timestampNow) internal {		
		
		uint256 firstLoveAdd24 = firstLove[_player].add(SLONG);
		uint256 firstLoveAdd48 = firstLove[_player].add(DLONG);
		uint256 remainV = remainingLoves[_player];
		
		 
		if (firstLoveAdd24 > _timestampNow && remainV > 0){
			remainingLoves[_player] = remainV.sub(1);
		}
			 
			else if (firstLoveAdd24 < _timestampNow && firstLoveAdd48 > _timestampNow){
				remainingLoves[_player] = (howManyEliminated.div(4)).add(freeRemainingLovesPerDay);
				firstLove[_player] = _timestampNow;
			}
		
				 
				else if (firstLoveAdd48 < _timestampNow){
					remainingLoves[_player] = freeRemainingLovesPerDay;
					firstLove[_player] = _timestampNow;
				}	
					 
					else remainingLoves[_player] = 0;

	}

	
	
	
	
 
 
 
	
 
 
 

 
 
 
	function nuke(uint256 _countryId) payable public onlyGameNOTPaused{
		require(_countryId < allCountriesLength);
		require(msg.value >= war_getNextNukePriceForCountry(_countryId)); 
		require(war_getNextNukePriceForCountry(_countryId) > 0); 
		require(isEliminated(_countryId) == false);
		require(canPlayTimestamp());  
		require(loversSTR[gameVersion][_countryId].bestLover != msg.sender);  
		require(_countryId != mostLovedCountry || allCountriesLength.sub(howManyEliminated) < 5);  
				
		address player = msg.sender;
		uint256 timestampNow = block.timestamp;
		uint256 gameId = gameVersion;
		uint256 thisBalance = address(this).balance;		
		uint256 priceToPay = war_getNextNukePriceForCountry(_countryId);
		
		 
		nukerAddress[_countryId] = player;
		
		 
		uint256 lastPriceOld = lastKnownCountryPrice[_countryId];
		lastKnownCountryPrice[_countryId] = getPriceOfCountry(_countryId);
		
		 
		eliminated[gameId][_countryId] = true;
		howManyEliminated++;
		
		if (howManyEliminated.add(1) == allCountriesLength){
			jackpotTimestamp = block.timestamp;
			emit LastCountryStanding(_countryId, player, thisBalance, gameId, jackpotTimestamp);
		}	
			else {
				 
				uint priceRaw = war_getNextNukePriceRaw();			
				nextPrice[gameId] = priceRaw.mul(kNext).div(1000);
				
				 
				updateJackpotTimestamp(timestampNow);
			}
							
		lastNukedCountry = _countryId;		
		payCuts(priceToPay, thisBalance, _countryId, timestampNow);
		excessRefund(player, priceToPay, msg.value);
		howManyNuked++;
		
		 
		emit Nuked(player, _countryId, priceToPay, priceRaw);
		emit PlayerEvent(1, _countryId, player, timestampNow, howManyEliminated, gameId);

		assert(lastKnownCountryPrice[_countryId] >= lastPriceOld);
	}

	
	
 
 
 
	function reanimateCountry(uint256 _countryId) public onlyGameNOTPaused{
		require(canPlayerReanimate(_countryId, msg.sender) == true);
		
		address player = msg.sender;
		eliminated[gameVersion][_countryId] = false;
		
		newOwner[_countryId] = player;
		
		howManyEliminated = howManyEliminated.sub(1);
		howManyReactivated++;
		
		emit Reactivation(_countryId, howManyReactivated);
		emit PlayerEvent(2, _countryId, player, block.timestamp, howManyEliminated, gameVersion);		
	} 



 
 
 
	function becomeNewKing(uint256 _continentId) payable public onlyGameNOTPaused{
		require(msg.value >= kingPrice);
		require(canPlayTimestamp());  
				
		address player = msg.sender;
		uint256 timestampNow = block.timestamp;
		uint256 gameId = gameVersion;
		uint256 thisBalance = address(this).balance;
		uint256 priceToPay = kingPrice;
		
		continentKing[_continentId] = player;
		
		updateJackpotTimestamp(timestampNow);

		if (continentFlips >= maxFlips){
			kingPrice = priceToPay.mul(kKings).div(100);
			continentFlips = 0;
			emit NewKingPrice(kingPrice, kKings);
			} else continentFlips++;
		
		payCutsLight(priceToPay, thisBalance, timestampNow);
		
		excessRefund(player, priceToPay, msg.value);
		
		 
		emit NewKingContinent(player, _continentId, priceToPay);
		emit PlayerEvent(3, _continentId, player, timestampNow, continentFlips, gameId);		
	}	



 
 
 
 
	function upLove(uint256 _countryId) public onlyGameNOTPaused{
		require(canPlayerLove(msg.sender)); 
		require(_countryId < allCountriesLength);	
		require(!isEliminated(_countryId));  
		require(block.timestamp.add(DSHORT) < jackpotTimestamp || block.timestamp > jackpotTimestamp.add(DSHORT)); 
	
		address lover = msg.sender;
		address countryOwner = getCountryOwner(_countryId);
		uint256 gameId = gameVersion;
		
		LoverStructure storage c = loversSTR[gameId][_countryId];
		uint256 nukecount = howManyNuked;
		
		 
		c.loves[nukecount][lover]++;
		uint256 playerLoves = c.loves[nukecount][lover];
		uint256 maxLovesBest = c.maxLoves[nukecount];
				
		 
		if 	(playerLoves > maxLovesBest){
			c.maxLoves[nukecount]++;
			
			 
			if (_countryId != mostLovedCountry && playerLoves > loversSTR[gameId][mostLovedCountry].maxLoves[nukecount]){
				mostLovedCountry = _countryId;
				
				emit newMostLovedCountry(_countryId, playerLoves);
			}
			
			 
			if (c.bestLover != lover){
				c.bestLover = lover;
				
				 
				address ourKing = continentKing[countryToContinent[_countryId]];
				if (ourKing != lover && remainingLoves[ourKing] < 16){
				remainingLoves[ourKing]++;
				}
			}
			
			emit NewBestLover(lover, _countryId, playerLoves);
		}
		
		 
		if (newOwner[_countryId] != countryOwner){
			newOwner[_countryId] = countryOwner;
			emit ThereIsANewOwner(countryOwner, _countryId);
		}		
		
		 
		updateLovesForToday(lover, block.timestamp);
		
		 
		emit NewLove(lover, _countryId, playerLoves, gameId, nukecount);
	}
	
	
	


 
 
 
	
 
 
 

 
	function storePriceOfAllCountries(uint256 _limitDown, uint256 _limitUp) public onlyOwner {
		require (_limitDown < _limitUp);
		require (_limitUp <= allCountriesLength);
		
		uint256 getPrice;
		address getTheOwner;
		
		for (uint256 i = _limitDown; i < _limitUp; i++) {
			getPrice = getPriceOfCountry(i);
			getTheOwner = getCountryOwner(i);
			
			lastKnownCountryPrice[i] = getPrice;
			newOwner[i] = getTheOwner;
			
			if (getPrice == 0 || getTheOwner ==0){
				emit ErrorCountry(i);
			}
		}
	}

	
	

 
 
	function updateCuts(uint256 _newDevcut, uint256 _newPlayercut, uint256 _newSuperCountriesJackpotCut) public onlyOwner {
		require(_newPlayercut.mul(3).add(_newDevcut).add(_newSuperCountriesJackpotCut) <= 700);
		require(_newDevcut > 100);		
		
		devCut = _newDevcut;
		playerCut = _newPlayercut;
		potCutSuperCountries = _newSuperCountriesJackpotCut;

		emit CutsUpdated(_newDevcut, _newPlayercut, _newSuperCountriesJackpotCut, block.timestamp);
		
	}

	


 
	function updatePrices(
		uint256 _newStartingPrice,
		uint256 _newKingPrice,
		uint256 _newKNext,
		uint256 _newKCountry,
		uint256 _newKLimit,
		uint256 _newkKings,
		uint256 _newMaxFlips
	)
		public 
		onlyOwner
	{
		startingPrice = _newStartingPrice;
		kingPrice = _newKingPrice;
		kNext = _newKNext;
		kCountry = _newKCountry;
		kCountryLimit = _newKLimit;
		kKings = _newkKings;
		maxFlips = _newMaxFlips;

		emit ConstantsUpdated(_newStartingPrice, _newKingPrice, _newKNext, _newKCountry, _newKLimit, _newkKings, _newMaxFlips);		
	}


	

 
	function updateValue(uint256 _code, uint256 _newValue) public onlyOwner {					
		if (_code == 1 ){
			continentKing.length = _newValue;
		} 
			else if (_code == 2 ){
				allCountriesLength = _newValue;
			} 
				else if (_code == 3 ){
					freeRemainingLovesPerDay = _newValue;
					} 		
		
		emit NewValue(_code, _newValue, block.timestamp);		
	}




 
	function updateCountryToContinentMany(uint256[] _countryIds, uint256 _continentId) external onlyOwner {					
		for (uint256 i = 0; i < _countryIds.length; i++) {
			updateCountryToContinent(_countryIds[i], _continentId);
		}		
	}




 
	function updateCountryToContinent(uint256 _countryId, uint256 _continentId) public onlyOwner {					
		require(_countryId < allCountriesLength);
		require(_continentId < continentKing.length);
		
		countryToContinent[_countryId] = _continentId;
		
		emit NewCountryToContinent(_countryId, _continentId, block.timestamp);		
	}


	
	
 
	function updateTCContract(address _newAddress) public onlyOwner() {
		contractTrophyCards = _newAddress;
		SCTrophy = SuperCountriesTrophyCardsExternal(_newAddress);
		
		emit NewContractAddress(_newAddress);			
	}





 
 
 
	
 
 
 


	function jackpotShareDispatch(
		address _winner,
		uint256 _share,
		uint256 _customValue,
		bytes32 _customText
	) 
		internal
		returns (uint256 shareDispatched_)
	{
		if (_winner == 0){
			_winner = owner;
		}
		
		uint256 potDispatched = _share;								
		winnersJackpot[gameVersion][_winner] += _share;	
		
		emit JackpotDispatch(_winner, _share, _customValue, _customText);

		return potDispatched;
	}
	
	


 
	function jackpotCountryReward(uint256 _countryPot) internal returns (uint256 winningCountry_, uint256 dispatched_){
		
		 
		uint256 potDispatched;
		
		if (howManyStandingOrNot(true) == 1){
			
			 
			 
			uint256 winningCountryId = lastStanding();
			address tempWinner = newOwner[winningCountryId];
			potDispatched = jackpotShareDispatch(tempWinner, _countryPot, winningCountryId, "lastOwner");
		} 	
			else {
				 
				 
				winningCountryId = lastNukedCountry;
				uint256 continentId = countryToContinent[winningCountryId];
				
				uint256[] memory standingNations = country_getAllStandingCountriesForContinent(continentId, true);
				uint256 howManyCountries = standingNations.length;
				
				 
				if (howManyCountries > 0) {
				
					uint256 winningCounter;
					uint256 countryPotForOne = _countryPot.div(howManyCountries);
					
					for (uint256 i = 0; i < howManyCountries && potDispatched <= _countryPot; i++) {
						
						uint256 tempCountry = standingNations[i];
						 
						tempWinner = newOwner[tempCountry];
						potDispatched += jackpotShareDispatch(tempWinner, countryPotForOne, tempCountry, "anOwner");
						winningCounter++;
						
						if (winningCounter == howManyCountries || potDispatched.add(countryPotForOne) > _countryPot){
							break;
						}
					}
				}
					
					 
					else {
						tempWinner = newOwner[winningCountryId];
						potDispatched = jackpotShareDispatch(tempWinner, _countryPot, winningCountryId, "lastNukedOwner");
						
					}
				}	
			
		return (winningCountryId, potDispatched);
	}




	
 
 
	function jackpotWIN() public onlyGameNOTPaused {
		require(block.timestamp > jackpotTimestamp);  
		require(address(this).balance >= 1e11);
		require(thisJackpotIsPlayedAndNotWon[gameVersion]);  
		
		uint256 gameId = gameVersion;
		
		 
		gameRunning = false;

		
		 
		 
		 
		
		 
		(uint256 nukerPot, uint256 countryPot, uint256 continentPot, uint256 freePot, uint256 pot,) = calculateJackpot();
		
		 
		 
		thisJackpotIsPlayedAndNotWon[gameId] = false;		

				
		 
		 
		 

		 
		(uint256 winningCountryId, uint256 potDispatched) = jackpotCountryReward(countryPot);	
		winningCountry[gameId] = winningCountryId;
		uint256 continentId = countryToContinent[winningCountryId];

			
		 
		 
		 

		 
		potDispatched += jackpotShareDispatch(continentKing[continentId], continentPot, continentId, "continent");
		
		
		 
		potDispatched += jackpotShareDispatch(loversSTR[gameId][winningCountryId].bestLover, freePot, 0, "free");
		
		
		 
		potDispatched += jackpotShareDispatch(nukerAddress[winningCountryId], nukerPot, 0, "nuker");
			
				
		 
		emit JackpotDispatchAll(gameId, winningCountryId, continentId, block.timestamp, jackpotTimestamp, pot, potDispatched, address(this).balance);
		emit PausedOrUnpaused(block.timestamp, gameRunning);

		
		 
		assert(potDispatched <= address(this).balance);		
	}
			

			

 
	function withdrawWinners() public onlyRealAddress {
		require(winnersJackpot[gameVersion][msg.sender] > 0);
		
		address _winnerAddress = msg.sender;
        uint256 gameId = gameVersion;
		
         
		uint256 jackpotToTransfer = winnersJackpot[gameId][_winnerAddress];
		winnersJackpot[gameId][_winnerAddress] = 0;
		
         
        emit WithdrawJackpot(_winnerAddress, jackpotToTransfer, gameId);
		
		 
        _winnerAddress.transfer(jackpotToTransfer);
	}


	

	
 
 
 

 
 
 

 
 
 
	function restartNewGame() public onlyGamePaused{
		require((msg.sender == owner && block.timestamp > jackpotTimestamp.add(DSHORT)) || block.timestamp > jackpotTimestamp.add(2629000));
		
		uint256 timestampNow = block.timestamp;
		
		 
		if (nextPrice[gameVersion] !=0){
			gameVersion++;
			lastNukedCountry = 0;
			howManyNuked = 0;
			howManyReactivated = 0;
			howManyEliminated = 0;
			
			lastNukerMin = 0;
			countryOwnerMin = 0;
			continentMin = 0;
			freePlayerMin = 0;
			withdrawMinOwner = 0;

			kingPrice = 1e16;
			
			newOwner.length = 0;
			nukerAddress.length = 0;
			newOwner.length = allCountriesLength;
			nukerAddress.length = allCountriesLength;
		}
		
		 
		updateJackpotTimestamp(timestampNow);
		
		 
		gameRunning = true;	
		thisJackpotIsPlayedAndNotWon[gameVersion] = true;

         
        emit NewGameLaunched(gameVersion, timestampNow, msg.sender, jackpotTimestamp);
		emit PausedOrUnpaused(block.timestamp, gameRunning);		
	}

	



 
 
 
	
 
 
 

   
	function() payable public {    }	




	
 
	function withdraw() public onlyOwner {
		require(block.timestamp > jackpotTimestamp.add(DSHORT) || address(this).balance <= 1e11 || whatDevCanWithdraw() > 0);
		
		uint256 thisBalance = address(this).balance;
		
		if (block.timestamp > jackpotTimestamp.add(DSHORT) || thisBalance <= 1e11 ){
			uint256 toWithdraw = thisBalance;
		}
		
		else {
			
			toWithdraw = whatDevCanWithdraw();
			withdrawMinOwner += toWithdraw;
		}			
		
		emit WithdrawByDev(block.timestamp, toWithdraw, withdrawMinOwner, thisBalance);
		
		owner.transfer(toWithdraw);	
	}

	



 
 
 

 
 
 

	function trueStandingFalseEliminated(bool _standing) public view returns (uint256[] countries_) {
		uint256 howLong = howManyStandingOrNot(_standing);
		uint256[] memory countries = new uint256[](howLong);
		uint256 standingCounter = 0;
		uint256 gameId = gameVersion;
		
		for (uint256 i = 0; i < allCountriesLength; i++) {
			if (eliminated[gameId][i] != _standing){
				countries[standingCounter] = i;
				standingCounter++;
			}

			if (standingCounter == howLong){break;}
		}
		
		return countries;
	}	

	

	
	function howManyStandingOrNot(bool _standing) public view returns (uint256 howManyCountries_) {
		uint256 standingCounter = 0;
		uint256 gameId = gameVersion;
		
		for (uint256 i = 0; i < allCountriesLength; i++) {
			if (eliminated[gameId][i] != _standing){
				standingCounter++;
			}					
		}	
		
		return standingCounter;
	}

	

	
	function lastStanding() public view returns (uint256 lastStandingNation_) {
		require (howManyStandingOrNot(true) == 1);

		return trueStandingFalseEliminated(true)[0];
	}
	
}