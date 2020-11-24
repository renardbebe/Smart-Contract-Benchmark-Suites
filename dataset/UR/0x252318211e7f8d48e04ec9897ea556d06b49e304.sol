 

pragma solidity ^0.4.21;


library CampaignLibrary {

    struct Campaign {
        bytes32 bidId;
        uint price;
        uint budget;
        uint startDate;
        uint endDate;
        bool valid;
        address  owner;
    }

    function convertCountryIndexToBytes(uint[] countries) internal returns (uint,uint,uint){
        uint countries1 = 0;
        uint countries2 = 0;
        uint countries3 = 0;
        for(uint i = 0; i < countries.length; i++){
            uint index = countries[i];

            if(index<256){
                countries1 = countries1 | uint(1) << index;
            } else if (index<512) {
                countries2 = countries2 | uint(1) << (index - 256);
            } else {
                countries3 = countries3 | uint(1) << (index - 512);
            }
        }

        return (countries1,countries2,countries3);
    }

    
}


contract AdvertisementStorage {

    mapping (bytes32 => CampaignLibrary.Campaign) campaigns;
    mapping (address => bool) allowedAddresses;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAllowedAddress() {
        require(allowedAddresses[msg.sender]);
        _;
    }

    event CampaignCreated
        (
            bytes32 bidId,
            uint price,
            uint budget,
            uint startDate,
            uint endDate,
            bool valid,
            address owner
    );

    event CampaignUpdated
        (
            bytes32 bidId,
            uint price,
            uint budget,
            uint startDate,
            uint endDate,
            bool valid,
            address  owner
    );

    function AdvertisementStorage() public {
        owner = msg.sender;
        allowedAddresses[msg.sender] = true;
    }

    function setAllowedAddresses(address newAddress, bool isAllowed) public onlyOwner {
        allowedAddresses[newAddress] = isAllowed;
    }


    function getCampaign(bytes32 campaignId)
        public
        view
        returns (
            bytes32,
            uint,
            uint,
            uint,
            uint,
            bool,
            address
        ) {

        CampaignLibrary.Campaign storage campaign = campaigns[campaignId];

        return (
            campaign.bidId,
            campaign.price,
            campaign.budget,
            campaign.startDate,
            campaign.endDate,
            campaign.valid,
            campaign.owner
        );
    }


    function setCampaign (
        bytes32 bidId,
        uint price,
        uint budget,
        uint startDate,
        uint endDate,
        bool valid,
        address owner
    )
    public
    onlyAllowedAddress {

        CampaignLibrary.Campaign memory campaign = campaigns[campaign.bidId];

        campaign = CampaignLibrary.Campaign({
            bidId: bidId,
            price: price,
            budget: budget,
            startDate: startDate,
            endDate: endDate,
            valid: valid,
            owner: owner
        });

        emitEvent(campaign);

        campaigns[campaign.bidId] = campaign;
        
    }

    function getCampaignPriceById(bytes32 bidId)
        public
        view
        returns (uint) {
        return campaigns[bidId].price;
    }

    function setCampaignPriceById(bytes32 bidId, uint price)
        public
        onlyAllowedAddress
        {
        campaigns[bidId].price = price;
        emitEvent(campaigns[bidId]);
    }

    function getCampaignBudgetById(bytes32 bidId)
        public
        view
        returns (uint) {
        return campaigns[bidId].budget;
    }

    function setCampaignBudgetById(bytes32 bidId, uint newBudget)
        public
        onlyAllowedAddress
        {
        campaigns[bidId].budget = newBudget;
        emitEvent(campaigns[bidId]);
    }

    function getCampaignStartDateById(bytes32 bidId)
        public
        view
        returns (uint) {
        return campaigns[bidId].startDate;
    }

    function setCampaignStartDateById(bytes32 bidId, uint newStartDate)
        public
        onlyAllowedAddress
        {
        campaigns[bidId].startDate = newStartDate;
        emitEvent(campaigns[bidId]);
    }

    function getCampaignEndDateById(bytes32 bidId)
        public
        view
        returns (uint) {
        return campaigns[bidId].endDate;
    }

    function setCampaignEndDateById(bytes32 bidId, uint newEndDate)
        public
        onlyAllowedAddress
        {
        campaigns[bidId].endDate = newEndDate;
        emitEvent(campaigns[bidId]);
    }

    function getCampaignValidById(bytes32 bidId)
        public
        view
        returns (bool) {
        return campaigns[bidId].valid;
    }

    function setCampaignValidById(bytes32 bidId, bool isValid)
        public
        onlyAllowedAddress
        {
        campaigns[bidId].valid = isValid;
        emitEvent(campaigns[bidId]);
    }

    function getCampaignOwnerById(bytes32 bidId)
        public
        view
        returns (address) {
        return campaigns[bidId].owner;
    }

    function setCampaignOwnerById(bytes32 bidId, address newOwner)
        public
        onlyAllowedAddress
        {
        campaigns[bidId].owner = newOwner;
        emitEvent(campaigns[bidId]);
    }

    function emitEvent(CampaignLibrary.Campaign campaign) private {

        if (campaigns[campaign.bidId].owner == 0x0) {
            emit CampaignCreated(
                campaign.bidId,
                campaign.price,
                campaign.budget,
                campaign.startDate,
                campaign.endDate,
                campaign.valid,
                campaign.owner
            );
        } else {
            emit CampaignUpdated(
                campaign.bidId,
                campaign.price,
                campaign.budget,
                campaign.startDate,
                campaign.endDate,
                campaign.valid,
                campaign.owner
            );
        }
    }
}


contract AdvertisementFinance {

    mapping (address => uint256) balanceDevelopers;
    mapping (address => bool) developerExists;
    
    address[] developers;
    address owner;
    address advertisementContract;
    address advStorageContract;
    AppCoins appc;

    modifier onlyOwner() { 
        require(owner == msg.sender); 
        _; 
    }

    modifier onlyAds() { 
        require(advertisementContract == msg.sender); 
        _; 
    }

    modifier onlyOwnerOrAds() { 
        require(msg.sender == owner || msg.sender == advertisementContract); 
        _; 
    }	

    function AdvertisementFinance (address _addrAppc) 
        public {
        owner = msg.sender;
        appc = AppCoins(_addrAppc);
        advStorageContract = 0x0;
    }

    function setAdsStorageAddress (address _addrStorage) external onlyOwnerOrAds {
        reset();
        advStorageContract = _addrStorage;
    }

    function setAdsContractAddress (address _addrAdvert) external onlyOwner {
         
        if (advertisementContract != 0x0){
            Advertisement adsContract = Advertisement(advertisementContract);
            address adsStorage = adsContract.getAdvertisementStorageAddress();
            require (adsStorage == advStorageContract);
        }
        
         
        advertisementContract = _addrAdvert;
    }
    

    function increaseBalance(address _developer, uint256 _value) 
        public onlyAds{

        if(developerExists[_developer] == false){
            developers.push(_developer);
            developerExists[_developer] = true;
        }

        balanceDevelopers[_developer] += _value;
    }

    function pay(address _developer, address _destination, uint256 _value) 
        public onlyAds{

        appc.transfer( _destination, _value);
        balanceDevelopers[_developer] -= _value;
    }

    function withdraw(address _developer, uint256 _value) public onlyOwnerOrAds {

        require(balanceDevelopers[_developer] >= _value);
        
        appc.transfer(_developer, _value);
        balanceDevelopers[_developer] -= _value;    
    }

    function reset() public onlyOwnerOrAds {
        for(uint i = 0; i < developers.length; i++){
            withdraw(developers[i],balanceDevelopers[developers[i]]);
        }
    }
    

}	

contract ERC20Interface {
    function name() public view returns(bytes32);
    function symbol() public view returns(bytes32);
    function balanceOf (address _owner) public view returns(uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (uint);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


contract AppCoins is ERC20Interface{
     
    address public owner;
    bytes32 private token_name;
    bytes32 private token_symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function AppCoins() public {
        owner = msg.sender;
        token_name = "AppCoins";
        token_symbol = "APPC";
        uint256 _totalSupply = 1000000;
        totalSupply = _totalSupply * 10 ** uint256(decimals);   
        balances[owner] = totalSupply;                 
    }

    function name() public view returns(bytes32) {
        return token_name;
    }

    function symbol() public view returns(bytes32) {
        return token_symbol;
    }

    function balanceOf (address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }

     
    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint previousBalances = balances[_from] + balances[_to];
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }

     
     
     
     
     
     
     
     
     
     
     
    function transfer (address _to, uint256 _amount) public returns (bool success) {
        if( balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (uint) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return allowance[_from][msg.sender];
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balances[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}


 
contract Advertisement {

    struct ValidationRules {
        bool vercode;
        bool ipValidation;
        bool country;
        uint constipDailyConversions;
        uint walletDailyConversions;
    }

    uint constant expectedPoALength = 12;

    ValidationRules public rules;
    bytes32[] bidIdList;
    AppCoins appc;
    AdvertisementStorage advertisementStorage;
    AdvertisementFinance advertisementFinance;
    address public owner;
    mapping (address => mapping (bytes32 => bool)) userAttributions;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    event PoARegistered(bytes32 bidId, string packageName,uint64[] timestampList,uint64[] nonceList,string walletName, bytes2 countryCode);
    event Error(string func, string message);
    event CampaignInformation
        (
            bytes32 bidId,
            address  owner,
            string ipValidator,
            string packageName,
            uint[3] countries,
            uint[] vercodes
    );

     
    function Advertisement (address _addrAppc, address _addrAdverStorage, address _addrAdverFinance) public {
        rules = ValidationRules(false, true, true, 2, 1);
        owner = msg.sender;
        appc = AppCoins(_addrAppc);
        advertisementStorage = AdvertisementStorage(_addrAdverStorage);
        advertisementFinance = AdvertisementFinance(_addrAdverFinance);
    }

    struct Map {
        mapping (address => uint256) balance;
        address[] devs;
    }

    function upgradeFinance (address addrAdverFinance) public onlyOwner {
        AdvertisementFinance newAdvFinance = AdvertisementFinance(addrAdverFinance);
        Map storage devBalance;    

        for(uint i = 0; i < bidIdList.length; i++) {
            address dev = advertisementStorage.getCampaignOwnerById(bidIdList[i]);
            
            if(devBalance.balance[dev] == 0){
                devBalance.devs.push(dev);
            }
            
            devBalance.balance[dev] += advertisementStorage.getCampaignBudgetById(bidIdList[i]);
        }        

        for(i = 0; i < devBalance.devs.length; i++) {
            advertisementFinance.pay(devBalance.devs[i],address(newAdvFinance),devBalance.balance[devBalance.devs[i]]);
            newAdvFinance.increaseBalance(devBalance.devs[i],devBalance.balance[devBalance.devs[i]]);
        }

        uint256 oldBalance = appc.balances(address(advertisementFinance));

        require(oldBalance == 0);

        advertisementFinance = newAdvFinance;
    }

     

    function upgradeStorage (address addrAdverStorage) public onlyOwner {
        for(uint i = 0; i < bidIdList.length; i++) {
            cancelCampaign(bidIdList[i]);
        }
        delete bidIdList;
        advertisementFinance.reset();
        advertisementFinance.setAdsStorageAddress(addrAdverStorage);
        advertisementStorage = AdvertisementStorage(addrAdverStorage);
    }

     

    function getAdvertisementStorageAddress() public view returns(address _contract) {
        require (msg.sender == address(advertisementFinance));

        return address(advertisementStorage);
    }


     

    function createCampaign (
        string packageName,
        uint[3] countries,
        uint[] vercodes,
        uint price,
        uint budget,
        uint startDate,
        uint endDate)
        external {

        require(budget >= price);
        require(endDate >= startDate);

        CampaignLibrary.Campaign memory newCampaign;

        newCampaign.price = price;
        newCampaign.startDate = startDate;
        newCampaign.endDate = endDate;

         
        if(appc.allowance(msg.sender, address(this)) < budget){
            emit Error("createCampaign","Not enough allowance");
            return;
        }

        appc.transferFrom(msg.sender, address(advertisementFinance), budget);

        advertisementFinance.increaseBalance(msg.sender,budget);

        newCampaign.budget = budget;
        newCampaign.owner = msg.sender;
        newCampaign.valid = true;
        newCampaign.bidId = uintToBytes(bidIdList.length);
        addCampaign(newCampaign);

        emit CampaignInformation(
            newCampaign.bidId,
            newCampaign.owner,
            "",  
            packageName,
            countries,
            vercodes);
    }

    function addCampaign(CampaignLibrary.Campaign campaign) internal {

		 
        bidIdList.push(campaign.bidId);

		 
        advertisementStorage.setCampaign(
            campaign.bidId,
            campaign.price,
            campaign.budget,
            campaign.startDate,
            campaign.endDate,
            campaign.valid,
            campaign.owner
        );

    }

    function registerPoA (
        string packageName, bytes32 bidId,
        uint64[] timestampList, uint64[] nonces,
        address appstore, address oem,
        string walletName, bytes2 countryCode) external {

        if(!isCampaignValid(bidId)){
            emit Error(
                "registerPoA","Registering a Proof of attention to a invalid campaign");
            return;
        }

        if(timestampList.length != expectedPoALength){
            emit Error("registerPoA","Proof-of-attention should have exactly 12 proofs");
            return;
        }

        if(timestampList.length != nonces.length){
            emit Error(
                "registerPoA","Nounce list and timestamp list must have same length");
            return;
        }
         
        for (uint i = 0; i < timestampList.length - 1; i++) {
            uint timestampDiff = (timestampList[i+1]-timestampList[i]);
            if((timestampDiff / 1000) != 10){
                emit Error(
                    "registerPoA","Timestamps should be spaced exactly 10 secounds");
                return;
            }
        }

         

        if(userAttributions[msg.sender][bidId]){
            emit Error(
                "registerPoA","User already registered a proof of attention for this campaign");
            return;
        }
         
        userAttributions[msg.sender][bidId] = true;

        payFromCampaign(bidId, appstore, oem);

        emit PoARegistered(bidId, packageName, timestampList, nonces, walletName, countryCode);
    }

    function cancelCampaign (bytes32 bidId) public {
        address campaignOwner = getOwnerOfCampaign(bidId);

		 
        require(owner == msg.sender || campaignOwner == msg.sender);
        uint budget = getBudgetOfCampaign(bidId);

        advertisementFinance.withdraw(campaignOwner, budget);

        advertisementStorage.setCampaignBudgetById(bidId, 0);
        advertisementStorage.setCampaignValidById(bidId, false);
    }

    function getCampaignValidity(bytes32 bidId) public view returns(bool){
        return advertisementStorage.getCampaignValidById(bidId);
    }

    function getPriceOfCampaign (bytes32 bidId) public view returns(uint) {
        return advertisementStorage.getCampaignPriceById(bidId);
    }

    function getStartDateOfCampaign (bytes32 bidId) public view returns(uint) {
        return advertisementStorage.getCampaignStartDateById(bidId);
    }

    function getEndDateOfCampaign (bytes32 bidId) public view returns(uint) {
        return advertisementStorage.getCampaignEndDateById(bidId);
    }

    function getBudgetOfCampaign (bytes32 bidId) public view returns(uint) {
        return advertisementStorage.getCampaignBudgetById(bidId);
    }

    function getOwnerOfCampaign (bytes32 bidId) public view returns(address) {
        return advertisementStorage.getCampaignOwnerById(bidId);
    }

    function getBidIdList() public view returns(bytes32[]) {
        return bidIdList;
    }

    function isCampaignValid(bytes32 bidId) public view returns(bool) {
        uint startDate = advertisementStorage.getCampaignStartDateById(bidId);
        uint endDate = advertisementStorage.getCampaignEndDateById(bidId);
        bool valid = advertisementStorage.getCampaignValidById(bidId);

        uint nowInMilliseconds = now * 1000;
        return valid && startDate < nowInMilliseconds && endDate > nowInMilliseconds;
    }

    function payFromCampaign (bytes32 bidId, address appstore, address oem) internal {
        uint devShare = 85;
        uint appstoreShare = 10;
        uint oemShare = 5;

         
        uint price = advertisementStorage.getCampaignPriceById(bidId);
        uint budget = advertisementStorage.getCampaignBudgetById(bidId);
        address campaignOwner = advertisementStorage.getCampaignOwnerById(bidId);

        require(budget > 0);
        require(budget >= price);

         
        advertisementFinance.pay(campaignOwner,msg.sender,division(price * devShare, 100));
        advertisementFinance.pay(campaignOwner,appstore,division(price * appstoreShare, 100));
        advertisementFinance.pay(campaignOwner,oem,division(price * oemShare, 100));

         
        uint newBudget = budget - price;

        advertisementStorage.setCampaignBudgetById(bidId, newBudget);


        if (newBudget < price) {
            advertisementStorage.setCampaignValidById(bidId, false);
        }
    }

    function areNoncesValid (bytes packageName,uint64[] timestampList, uint64[] nonces) internal returns(bool) {

        for(uint i = 0; i < nonces.length; i++){
            bytes8 timestamp = bytes8(timestampList[i]);
            bytes8 nonce = bytes8(nonces[i]);
            bytes memory byteList = new bytes(packageName.length + timestamp.length);

            for(uint j = 0; j < packageName.length;j++){
                byteList[j] = packageName[j];
            }

            for(j = 0; j < timestamp.length; j++ ){
                byteList[j + packageName.length] = timestamp[j];
            }

            bytes32 result = sha256(byteList);

            bytes memory noncePlusHash = new bytes(result.length + nonce.length);

            for(j = 0; j < nonce.length; j++){
                noncePlusHash[j] = nonce[j];
            }

            for(j = 0; j < result.length; j++){
                noncePlusHash[j + nonce.length] = result[j];
            }

            result = sha256(noncePlusHash);

            bytes2[1] memory leadingBytes = [bytes2(0)];
            bytes2 comp = 0x0000;

            assembly{
            	mstore(leadingBytes,result)
            }

            if(comp != leadingBytes[0]){
                return false;
            }

        }
        return true;
    }


    function division(uint numerator, uint denominator) public view returns (uint) {
        uint _quotient = numerator / denominator;
        return _quotient;
    }

    function uintToBytes (uint256 i) public view returns(bytes32 b) {
        b = bytes32(i);
    }

}