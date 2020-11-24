 

pragma solidity ^0.4.19;

 
 
 

contract DistrictsCoreInterface {
   
  function isDopeRaiderDistrictsCore() public pure returns (bool);
  function increaseDistrictWeed(uint256 _district, uint256 _quantity) public;
  function increaseDistrictCoke(uint256 _district, uint256 _quantity) public;
  function distributeRevenue(uint256 _district , uint8 _splitW, uint8 _splitC) public payable;
  function getNarcoLocation(uint256 _narcoId) public view returns (uint8 location);
}

 
contract SaleClockAuction {
  function isSaleClockAuction() public pure returns (bool);
  function createAuction(uint256 _tokenId,  uint256 _startingPrice,uint256 _endingPrice,uint256 _duration,address _seller)public;
  function withdrawBalance() public;
  function averageGen0SalePrice() public view returns (uint256);

}


 
contract NarcoAccessControl {
     
    event ContractUpgrade(address newContract);

    address public ceoAddress;
    address public cooAddress;

     
    bool public paused = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress
        );
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    function withdrawBalance() external onlyCLevel {
        msg.sender.transfer(address(this).balance);
    }


     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() public onlyCLevel whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCLevel whenPaused {
         
        paused = false;
    }

     
    address public districtContractAddress;

    DistrictsCoreInterface public districtsCore;

    function setDistrictAddress(address _address) public onlyCLevel {
        _setDistrictAddresss(_address);
    }

    function _setDistrictAddresss(address _address) internal {
      DistrictsCoreInterface candidateContract = DistrictsCoreInterface(_address);
      require(candidateContract.isDopeRaiderDistrictsCore());
      districtsCore = candidateContract;
      districtContractAddress = _address;
    }


    modifier onlyDopeRaiderContract() {
        require(msg.sender == districtContractAddress);
        _;
    }




}

 
contract NarcoBase is NarcoAccessControl {
     

    event NarcoCreated(address indexed owner, uint256 narcoId, string genes);

     
     
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);


  

     
     


     
     
    struct Narco {
         
        string genes;  
        string narcoName;
         
        uint16 [9] stats;
         
        uint16 weedTotal;
        uint16 cokeTotal;
        uint8 [4] consumables;  
        uint16 [6] skills;    
        uint256 [6] cooldowns;  
        uint8 homeLocation;
    }

     

     
     
    Narco[] narcos;

     
     
    mapping (uint256 => address) public narcoIndexToOwner;

     
     
    mapping (address => uint256) ownershipTokenCount;

     
     
    mapping (uint256 => address) public  narcoIndexToApproved;

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
         
        ownershipTokenCount[_to]++;
        narcoIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete narcoIndexToApproved[_tokenId];
        }

        Transfer(_from, _to, _tokenId);
    }

     
    function _createNarco(
        string _genes,
        string _name,
        address _owner
    )
        internal
        returns (uint)
    {

        uint16[6] memory randomskills= [
            uint16(random(9)+1),
            uint16(random(9)+1),
            uint16(random(9)+1),
            uint16(random(9)+1),
            uint16(random(9)+1),
            uint16(random(9)+31)
        ];

        uint256[6] memory cools;
        uint16[9] memory nostats;

        Narco memory _narco = Narco({
            genes: _genes,
            narcoName: _name,
            cooldowns: cools,
            stats: nostats,
            weedTotal: 0,
            cokeTotal: 0,
            consumables: [4,6,2,1],
            skills: randomskills,
            homeLocation: uint8(random(6)+1)
        });

        uint256 newNarcoId = narcos.push(_narco) - 1;
        require(newNarcoId <= 4294967295);

         
        if (newNarcoId==0){
            narcos[0].homeLocation=7;  
            narcos[0].skills[4]=800;  
            narcos[0].skills[5]=65535;  
        }

        NarcoCreated(_owner, newNarcoId, _narco.genes);
        _transfer(0, _owner, newNarcoId);


        return newNarcoId;
    }

    function subToZero(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b <= a){
          return a - b;
        }else{
          return 0;
        }
      }

    function getRemainingCapacity(uint256 _narcoId) public view returns (uint16 capacity){
        uint256 usedCapacity = narcos[_narcoId].weedTotal + narcos[_narcoId].cokeTotal + narcos[_narcoId].consumables[0]+narcos[_narcoId].consumables[1]+narcos[_narcoId].consumables[2]+narcos[_narcoId].consumables[3];
        capacity = uint16(subToZero(uint256(narcos[_narcoId].skills[5]), usedCapacity));
    }

     
    function getLevel(uint256 _narcoId) public view returns (uint16 rank){

     

        rank =  (narcos[_narcoId].stats[0]/12)+
                 (narcos[_narcoId].stats[1]/4)+
                 (narcos[_narcoId].stats[2]/4)+
                 (narcos[_narcoId].stats[3]/6)+
                 (narcos[_narcoId].stats[4]/6)+
                 (narcos[_narcoId].stats[5]/1)+
                 (narcos[_narcoId].stats[7]/12)
                 ;
    }

     
    uint64 _seed = 0;
    function random(uint64 upper) private returns (uint64 randomNumber) {
       _seed = uint64(keccak256(keccak256(block.blockhash(block.number-1), _seed), now));
       return _seed % upper;
     }


     
     
    function narcosByOwner(address _owner) public view returns(uint256[] ownedNarcos) {
       uint256 tokenCount = ownershipTokenCount[_owner];
        uint256 totalNarcos = narcos.length - 1;
        uint256[] memory result = new uint256[](tokenCount);
        uint256 narcoId;
        uint256 resultIndex=0;
        for (narcoId = 0; narcoId <= totalNarcos; narcoId++) {
          if (narcoIndexToOwner[narcoId] == _owner) {
            result[resultIndex] = narcoId;
            resultIndex++;
          }
        }
        return result;
    }


}


 
contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

     
     
     
     
     
}

 
contract NarcoOwnership is NarcoBase, ERC721 {
    string public name = "DopeRaider";
    string public symbol = "DOPR";

    function implementsERC721() public pure returns (bool)
    {
        return true;
    }

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return narcoIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return narcoIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        narcoIndexToApproved[_tokenId] = _approved;
    }


     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
        public

    {
        require(_to != address(0));
        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
        public

    {
        require(_owns(msg.sender, _tokenId));

        _approve(_tokenId, _to);

        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public

    {
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        require(_to != address(0));

        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return narcos.length - 1;
    }

    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = narcoIndexToOwner[_tokenId];

        require(owner != address(0));
    }



}


 
 
 
contract NarcoUpdates is NarcoOwnership {

    function updateWeedTotal(uint256 _narcoId, bool _add, uint16 _total) public onlyDopeRaiderContract {
      if(_add==true){
        narcos[_narcoId].weedTotal+= _total;
      }else{
        narcos[_narcoId].weedTotal-= _total;
      }
    }

    function updateCokeTotal(uint256 _narcoId, bool _add, uint16 _total) public onlyDopeRaiderContract {
       if(_add==true){
        narcos[_narcoId].cokeTotal+= _total;
      }else{
        narcos[_narcoId].cokeTotal-= _total;
      }
    }

    function updateConsumable(uint256 _narcoId, uint256 _index, uint8 _new) public onlyDopeRaiderContract  {
      narcos[_narcoId].consumables[_index] = _new;
    }

    function updateSkill(uint256 _narcoId, uint256 _index, uint16 _new) public onlyDopeRaiderContract  {
      narcos[_narcoId].skills[_index] = _new;
    }

    function incrementStat(uint256 _narcoId , uint256 _index) public onlyDopeRaiderContract  {
      narcos[_narcoId].stats[_index]++;
    }

    function setCooldown(uint256 _narcoId , uint256 _index , uint256 _new) public onlyDopeRaiderContract  {
      narcos[_narcoId].cooldowns[_index]=_new;
    }

}

 
 
 
contract NarcoAuction is NarcoUpdates {
    SaleClockAuction public saleAuction;

    function setSaleAuctionAddress(address _address) public onlyCLevel {
        SaleClockAuction candidateContract = SaleClockAuction(_address);
        require(candidateContract.isSaleClockAuction());
        saleAuction = candidateContract;
    }

    function createSaleAuction(
        uint256 _narcoId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        public
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _narcoId));
        _approve(_narcoId, saleAuction);
         
         
        saleAuction.createAuction(
            _narcoId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
     
     
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
    }
}


 
contract NarcoMinting is NarcoAuction {

     
    uint256 public promoCreationLimit = 200;
    uint256 public gen0CreationLimit = 5000;

     
    uint256 public gen0StartingPrice = 1 ether;
    uint256 public gen0EndingPrice = 20 finney;
    uint256 public gen0AuctionDuration = 1 days;

     
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

     
    function createPromoNarco(
        string _genes,
        string _name,
        address _owner
    ) public onlyCLevel {
        if (_owner == address(0)) {
             _owner = cooAddress;
        }
        require(promoCreatedCount < promoCreationLimit);
        require(gen0CreatedCount < gen0CreationLimit);

        promoCreatedCount++;
        gen0CreatedCount++;

        _createNarco(_genes, _name, _owner);
    }

     
     
    function createGen0Auction(
       string _genes,
        string _name
    ) public onlyCLevel {
        require(gen0CreatedCount < gen0CreationLimit);

        uint256 narcoId = _createNarco(_genes,_name,address(this));

        _approve(narcoId, saleAuction);

        saleAuction.createAuction(
            narcoId,
            _computeNextGen0Price(),
            gen0EndingPrice,
            gen0AuctionDuration,
            address(this)
        );

        gen0CreatedCount++;
    }

     
     
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

         
        require(avePrice < 340282366920938463463374607431768211455);

        uint256 nextPrice = avePrice + (avePrice / 2);

         
        if (nextPrice < gen0StartingPrice) {
            nextPrice = gen0StartingPrice;
        }

        return nextPrice;
    }
}


 
 
contract DopeRaiderCore is NarcoMinting {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    address public newContractAddress;

    bool public gamePaused = true;

    modifier whenGameNotPaused() {
        require(!gamePaused);
        _;
    }

     
    modifier whenGamePaused {
        require(gamePaused);
        _;
    }

    function pause() public onlyCLevel whenGameNotPaused {
        gamePaused = true;
    }

    function unpause() public onlyCLevel whenGamePaused {
         
        gamePaused = false;
    }


     
    event GrowWeedCompleted(uint256 indexed narcoId, uint yield);
    event RefineCokeCompleted(uint256 indexed narcoId, uint yield);

    function DopeRaiderCore() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) public onlyCLevel whenPaused {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

     
     
     
    function() external payable {
        require(msg.sender == address(saleAuction));
    }

     

   function getNarco(uint256 _id)
        public
        view
        returns (
        string  narcoName,
        uint256 weedTotal,
        uint256 cokeTotal,
        uint16[6] skills,
        uint8[4] consumables,
        string genes,
        uint8 homeLocation,
        uint16 level,
        uint256[6] cooldowns,
        uint256 id,
        uint16 [9] stats
    ) {
        Narco storage narco = narcos[_id];
        narcoName = narco.narcoName;
        weedTotal = narco.weedTotal;
        cokeTotal = narco.cokeTotal;
        skills = narco.skills;
        consumables = narco.consumables;
        genes = narco.genes;
        homeLocation = narco.homeLocation;
        level = getLevel(_id);
        cooldowns = narco.cooldowns;
        id = _id;
        stats = narco.stats;
    }

    uint256 public changeIdentityNarcoRespect = 30;
    function setChangeIdentityNarcoRespect(uint256 _respect) public onlyCLevel {
      changeIdentityNarcoRespect=_respect;
    }

    uint256 public personalisationCost = 0.01 ether;  
    function setPersonalisationCost(uint256 _cost) public onlyCLevel {
      personalisationCost=_cost;
    }
    function updateNarco(uint256 _narcoId, string _genes, string _name) public payable whenGameNotPaused {
       require(getLevel(_narcoId)>=changeIdentityNarcoRespect);  
       require(msg.sender==narcoIndexToOwner[_narcoId]);  
       require(msg.value>=personalisationCost);
       narcos[_narcoId].genes = _genes;
       narcos[_narcoId].narcoName = _name;
    }

    uint256 public respectRequiredToRecruit = 150;

    function setRespectRequiredToRecruit(uint256 _respect) public onlyCLevel {
      respectRequiredToRecruit=_respect;
    }

    function recruitNarco(uint256 _narcoId, string _genes, string _name) public whenGameNotPaused {
       require(msg.sender==narcoIndexToOwner[_narcoId]);  
       require(getLevel(_narcoId)>=respectRequiredToRecruit);  
       require(narcos[_narcoId].stats[8]<getLevel(_narcoId)/respectRequiredToRecruit);  
      _createNarco(_genes,_name, msg.sender);
      narcos[_narcoId].stats[8]+=1;  
    }

    
    uint256 public growCost = 0.003 ether;
    function setGrowCost(uint256 _cost) public onlyCLevel{
      growCost=_cost;
    }

    function growWeed(uint256 _narcoId) public payable whenGameNotPaused{
         require(msg.sender==narcoIndexToOwner[_narcoId]);  
         require(msg.value>=growCost);
         require(now>narcos[_narcoId].cooldowns[1]);  
         uint16 growSkillLevel = narcos[_narcoId].skills[1];  
         uint16 maxYield = 9 + growSkillLevel;  
         uint yield = min(narcos[_narcoId].consumables[1],maxYield);
         require(yield>0);  

          
         uint8 district = districtsCore.getNarcoLocation(_narcoId);
         require(district==narcos[_narcoId].homeLocation);

          
         uint256 cooldown = now + ((910-(10*growSkillLevel))* 1 seconds);  

         narcos[_narcoId].cooldowns[1]=cooldown;
          
         narcos[_narcoId].consumables[1]=uint8(subToZero(uint256(narcos[_narcoId].consumables[1]),yield));
         narcos[_narcoId].weedTotal+=uint8(yield);

         narcos[_narcoId].stats[1]+=1;  
         districtsCore.increaseDistrictWeed(district , yield);
         districtsCore.distributeRevenue.value(growCost)(uint256(district),50,50);  
         GrowWeedCompleted(_narcoId, yield);  
    }


    uint256 public refineCost = 0.003 ether;
    function setRefineCost(uint256 _cost) public onlyCLevel{
      refineCost=_cost;
    }

    function refineCoke(uint256 _narcoId) public payable whenGameNotPaused{
         require(msg.sender==narcoIndexToOwner[_narcoId]);  
         require(msg.value>=refineCost);
         require(now>narcos[_narcoId].cooldowns[2]);  
         uint16 refineSkillLevel = narcos[_narcoId].skills[2];  
         uint16 maxYield = 3+(refineSkillLevel/3);  
         uint yield = min(narcos[_narcoId].consumables[2],maxYield);
         require(yield>0);  

          
         uint8 district = districtsCore.getNarcoLocation(_narcoId);
         require(district==narcos[_narcoId].homeLocation);

          
         
         uint256 cooldown = now + ((910-(10*refineSkillLevel))* 1 seconds);  

         narcos[_narcoId].cooldowns[2]=cooldown;
          
         narcos[_narcoId].consumables[2]=uint8(subToZero(uint256(narcos[_narcoId].consumables[2]),yield));
         narcos[_narcoId].cokeTotal+=uint8(yield);

         narcos[_narcoId].stats[2]+=1;
         districtsCore.increaseDistrictCoke(district, yield);
         districtsCore.distributeRevenue.value(refineCost)(uint256(district),50,50);  
         RefineCokeCompleted(_narcoId, yield);  

    }


    function min(uint a, uint b) private pure returns (uint) {
             return a < b ? a : b;
    }

}