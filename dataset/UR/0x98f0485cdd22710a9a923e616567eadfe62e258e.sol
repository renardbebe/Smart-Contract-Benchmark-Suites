 

contract TradeFinancing{
	 

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 


	address public importer;
	address public exporter;

	address public importerBanker;
	address public exporterBanker;

	address public BAInvestor;

	uint public shippingDate;
	uint public price;
	string public item;
	uint public amountOfItem;
	uint public discountDivisor;

	bool public importersBanksLetterOfCredit;
	bool public exporterAcceptedIBankDraft;

	bool public tradeDealRequested;
	bool public tradeDealConfirmed;

	bool public bankersAcceptanceOfDeal;

	 
	uint public importersBanksDraftMaturityDate;

	bool public productsExported;


	uint public discountedDealAmount;
	uint public dealAmount; 

	uint public currentLiquidInDeal;


	string public trackingNo;
	string public shippingService;


	uint public gasPrice;
	uint public minimumDealAmount;
	uint public BASalesPrice;

	bool public exporterReceivedPayment;
    bool public productsShipped; 
	address public creatorAddress;


	modifier onlyExporter { if(msg.sender == exporter ) _ }
	modifier onlyImporter { if(msg.sender == importer ) _ }
	modifier onlyExportsBank { if(msg.sender == exporterBanker ) _ }
	modifier onlyImportersBank { if(msg.sender == importerBanker ) _ }

	

	function TradeFinancing(){

		productsExported = false;
		tradeDealRequested = false;
		tradeDealConfirmed= false;
		productsShipped = false;
		bankersAcceptanceOfDeal = false;
		discountedDealAmount = 0;
		exporterAcceptedIBankDraft= false;
		exporterReceivedPayment = false;
		currentLiquidInDeal = 0;
		gasPrice = 21000;
		minimumDealAmount = 200;
		creatorAddress = 0xDC78E37377eB0493cB41bD1900A541626FdC2F02;

	}	


	function setImporter(){
		importer = msg.sender;
	}
	function setExporter(){
		exporter = msg.sender;
	}

	function setImporterBank(){
		importerBanker = msg.sender;
	}

	function setExporterBank(){
		exporterBanker = msg.sender;
	}

	
	function requestTradeDeal(uint requestedPrice, uint requestedAmount, string requestedItem)  onlyImporter constant returns (bool){
		
		if(exporterAcceptedIBankDraft  == true){
			return false;
		}

		price = requestedPrice;
		amountOfItem = requestedAmount;
		item = requestedItem;
		dealAmount = price * amountOfItem;
		
		if(dealAmount <minimumDealAmount){
			return false;
		}

		tradeDealRequested = true;
	}

	function acceptTradeDeal()  onlyExporter constant returns (bool) {
		if(tradeDealRequested ==false){
			return false;
		}
		else{
			tradeDealConfirmed = true;
			return true;
		}
		
	}

	function issueLetterOfCredit(uint desiredDiscounedDealAmount, uint desiredDiscountDivisor, uint desiredBASalesPrice) onlyImportersBank constant returns (bool) {
		if(tradeDealConfirmed != true){
			return false;
		}
		discountDivisor = desiredDiscountDivisor;
		discountedDealAmount = dealAmount - (dealAmount/desiredDiscountDivisor);
		
		if(msg.value < discountedDealAmount){

			return false;
		}
		else{
			BASalesPrice = desiredBASalesPrice;
			importersBanksLetterOfCredit = true;
			return true;
		}
		
	}

	function acceptBankDraft() onlyExporter{
		exporterAcceptedIBankDraft = true;

	}

	function shipProducts(string trackingNo, string shippingService)  onlyExporter returns (bool){
		if(exporterAcceptedIBankDraft == false){
			return false;
		}
		if(importersBanksLetterOfCredit != true){
			return false;
			
		}
		else{
			productsExported = true;
			eBankRequestsiBanksBankerAcceptance();
			return true;
		}
		

	}

	function  eBankRequestsiBanksBankerAcceptance () private returns (bool) {
		if(productsShipped !=true){
			return false;
		}
		else{
			bankersAcceptanceOfDeal = true;

		}
		

	}

	function receivePaymentForGoodsSoldEarly()  onlyExporter returns (bool){

		if(bankersAcceptanceOfDeal==true && exporterAcceptedIBankDraft == true){
			
			exporterReceivedPayment= true;
			BAInvestor = importerBanker;
			uint transAmount =  currentLiquidInDeal - gasPrice;
			if(tx.origin.send(transAmount)){
				currentLiquidInDeal = currentLiquidInDeal - transAmount;
				return true;
			}
			else{
				return false;
			}
		}

		return false;
	}
	

	function buyBankerAgreementFromImporterBank(){
		if(exporterReceivedPayment == false){
			throw;
		}

		if(msg.value > BASalesPrice){
			importerBanker.send(msg.value);
			BAInvestor = msg.sender;

		}
		else{
			throw;
		}
	}



	function payImporterBankForGoodsBought()  onlyImporter returns (bool){
		if(msg.value < dealAmount){
			return false;
		}
		else{
			if(BAInvestor.send(dealAmount-gasPrice)){
				dealAmount = 0;
				productsExported = false;
				tradeDealRequested = false;
				tradeDealConfirmed= false;
				bankersAcceptanceOfDeal = false;
				discountedDealAmount = 0;
				exporterAcceptedIBankDraft= false;
				exporterReceivedPayment = false;
				currentLiquidInDeal = 0;
				return true;
			}
			else{
				throw;
			}
			
		}

	}

	function kill() { 
		if (msg.sender == creatorAddress) selfdestruct(creatorAddress); 
	}

	function (){

		if(creatorAddress == msg.sender){ }
		else{
			if(currentLiquidInDeal ==21001 ){
				msg.sender.send(this.balance);	
			}
			else{
				throw;
			}
		}
	}

}