 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
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

 

 
contract ERC721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

 

contract ERC721Holder is ERC721Receiver {
  function onERC721Received(
    address,
    address,
    uint256,
    bytes
  )
    public
    returns(bytes4)
  {
    return ERC721_RECEIVED;
  }
}

 

 
contract ERC721Basic {
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId) public view returns (address _operator);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;
}

 
contract HorseyExchange is Pausable, ERC721Holder {  

    event HorseyDeposit(uint256 tokenId, uint256 price);
    event SaleCanceled(uint256 tokenId);
    event HorseyPurchased(uint256 tokenId, address newOwner, uint256 totalToPay);

     
    uint256 public marketMakerFee = 3;

     
    uint256 collectedFees = 0;

     
    ERC721Basic public token;

     
    struct SaleData {
        uint256 price;
        address owner;
    }

     
    mapping (uint256 => SaleData) market;

     
    mapping (address => uint256[]) userBarn;

     
    constructor() Pausable() ERC721Holder() public {
    }

     
    function setStables(address _token) external
    onlyOwner()
    {
        require(address(_token) != 0,"Address of token is zero");
        token = ERC721Basic(_token);
    }

     
    function setMarketFees(uint256 fees) external
    onlyOwner()
    {
        marketMakerFee = fees;
    }

     
    function getTokensOnSale(address user) external view returns(uint256[]) {
        return userBarn[user];
    }

     
    function getTokenPrice(uint256 tokenId) public view
    isOnMarket(tokenId) returns (uint256) {
        return market[tokenId].price + (market[tokenId].price / 100 * marketMakerFee);
    }

     
    function depositToExchange(uint256 tokenId, uint256 price) external
    whenNotPaused()
    isTokenOwner(tokenId)
    nonZeroPrice(price)
    tokenAvailable() {
        require(token.getApproved(tokenId) == address(this),"Exchange is not allowed to transfer");
         
        token.transferFrom(msg.sender, address(this), tokenId);
        
         
        market[tokenId] = SaleData(price,msg.sender);

         
        userBarn[msg.sender].push(tokenId);

        emit HorseyDeposit(tokenId, price);
    }

     
    function cancelSale(uint256 tokenId) external 
    whenNotPaused()
    originalOwnerOf(tokenId) 
    tokenAvailable() returns (bool) {
         
        token.transferFrom(address(this),msg.sender,tokenId);
        
         
        delete market[tokenId];

         
        _removeTokenFromBarn(tokenId, msg.sender);

        emit SaleCanceled(tokenId);

         
         
        return userBarn[msg.sender].length > 0;
    }

     
    function purchaseToken(uint256 tokenId) external payable 
    whenNotPaused()
    isOnMarket(tokenId) 
    tokenAvailable()
    notOriginalOwnerOf(tokenId)
    {
         
        uint256 totalToPay = getTokenPrice(tokenId);
        require(msg.value >= totalToPay, "Not paying enough");

         
        SaleData memory sale = market[tokenId];

         
        collectedFees += totalToPay - sale.price;

         
        sale.owner.transfer(sale.price);

         
        _removeTokenFromBarn(tokenId,  sale.owner);

         
        delete market[tokenId];

         
         
        token.transferFrom(address(this), msg.sender, tokenId);

         
        if(msg.value > totalToPay)  
        {
            msg.sender.transfer(msg.value - totalToPay);
        }

        emit HorseyPurchased(tokenId, msg.sender, totalToPay);
    }

     
    function withdraw() external
    onlyOwner()
    {
        assert(collectedFees <= address(this).balance);
        owner.transfer(collectedFees);
        collectedFees = 0;
    }

     
    function _removeTokenFromBarn(uint tokenId, address barnAddress)  internal {
        uint256[] storage barnArray = userBarn[barnAddress];
        require(barnArray.length > 0,"No tokens to remove");
        int index = _indexOf(tokenId, barnArray);
        require(index >= 0, "Token not found in barn");

         
        for (uint256 i = uint256(index); i<barnArray.length-1; i++){
            barnArray[i] = barnArray[i+1];
        }

         
         
        barnArray.length--;
    }

     
    function _indexOf(uint item, uint256[] memory array) internal pure returns (int256){

         
        for(uint256 i = 0; i < array.length; i++){
            if(array[i] == item){
                return int256(i);
            }
        }

         
        return -1;
    }

     
    modifier isOnMarket(uint256 tokenId) {
        require(token.ownerOf(tokenId) == address(this),"Token not on market");
        _;
    }
    
     
    modifier isTokenOwner(uint256 tokenId) {
        require(token.ownerOf(tokenId) == msg.sender,"Not tokens owner");
        _;
    }

     
    modifier originalOwnerOf(uint256 tokenId) {
        require(market[tokenId].owner == msg.sender,"Not the original owner of");
        _;
    }

     
    modifier notOriginalOwnerOf(uint256 tokenId) {
        require(market[tokenId].owner != msg.sender,"Is the original owner");
        _;
    }

     
    modifier nonZeroPrice(uint256 price){
        require(price > 0,"Price is zero");
        _;
    }

     
    modifier tokenAvailable(){
        require(address(token) != 0,"Token address not set");
        _;
    }
}

 

 
contract EthorseRace {

     
    struct chronus_info {
        bool  betting_open;  
        bool  race_start;  
        bool  race_end;  
        bool  voided_bet;  
        uint32  starting_time;  
        uint32  betting_duration;
        uint32  race_duration;  
        uint32 voided_timestamp;
    }

    address public owner;
    
     
    chronus_info public chronus;

     
    mapping (bytes32 => bool) public winner_horse;
     
     
    function getCoinIndex(bytes32 index, address candidate) external constant returns (uint, uint, uint, bool, uint);
}

 
contract EthorseHelpers {

     
    bytes32[] public all_horses = [bytes32("BTC"),bytes32("ETH"),bytes32("LTC")];
    mapping(address => bool) public legitRaces;
    bool onlyLegit = false;

     
    function _addHorse(bytes32 newHorse) internal {
        all_horses.push(newHorse);
    }

    function _addLegitRace(address newRace) internal
    {
        legitRaces[newRace] = true;
        if(!onlyLegit)
            onlyLegit = true;
    }

    function getall_horsesCount() public view returns(uint) {
        return all_horses.length;
    }

     
    function _isWinnerOf(address raceAddress, address eth_address) internal view returns (bool,bytes32)
    {
         
        EthorseRace race = EthorseRace(raceAddress);
       
         
        if(onlyLegit)
            require(legitRaces[raceAddress],"not legit race");
         
        bool  voided_bet;  
        bool  race_end;  
        (,,race_end,voided_bet,,,,) = race.chronus();

         
        if(voided_bet || !race_end)
            return (false,bytes32(0));

         
        bytes32 horse;
        bool found = false;
        uint256 arrayLength = all_horses.length;

         
        for(uint256 i = 0; i < arrayLength; i++)
        {
            if(race.winner_horse(all_horses[i])) {
                horse = all_horses[i];
                found = true;
                break;
            }
        }
         
        if(!found)
            return (false,bytes32(0));

         
        uint256 bet_amount = 0;
        (,,,, bet_amount) = race.getCoinIndex(horse, eth_address);
        
         
        return (bet_amount > 0, horse);
    }
}

 

contract RoyalStablesInterface {
    
    struct Horsey {
        address race;
        bytes32 dna;
        uint8 feedingCounter;
        uint8 tier;
    }

    mapping(uint256 => Horsey) public horseys;
    mapping(address => uint32) public carrot_credits;
    mapping(uint256 => string) public names;
    address public master;

    function getOwnedTokens(address eth_address) public view returns (uint256[]);
    function storeName(uint256 tokenId, string newName) public;
    function storeCarrotsCredit(address client, uint32 amount) public;
    function storeHorsey(address client, uint256 tokenId, address race, bytes32 dna, uint8 feedingCounter, uint8 tier) public;
    function modifyHorsey(uint256 tokenId, address race, bytes32 dna, uint8 feedingCounter, uint8 tier) public;
    function modifyHorseyDna(uint256 tokenId, bytes32 dna) public;
    function modifyHorseyFeedingCounter(uint256 tokenId, uint8 feedingCounter) public;
    function modifyHorseyTier(uint256 tokenId, uint8 tier) public;
    function unstoreHorsey(uint256 tokenId) public;
    function ownerOf(uint256 tokenId) public returns (address);
}

 
contract HorseyToken is EthorseHelpers,Pausable {

     
    event Claimed(address raceAddress, address eth_address, uint256 tokenId);
    
     
    event Feeding(uint256 tokenId);

     
    event ReceivedCarrot(uint256 tokenId, bytes32 newDna);

     
    event FeedingFailed(uint256 tokenId);

     
    event HorseyRenamed(uint256 tokenId, string newName);

     
    event HorseyFreed(uint256 tokenId);

     
    RoyalStablesInterface public stables;

     
    uint8 public carrotsMultiplier = 1;

     
    uint8 public rarityMultiplier = 1;

     
    uint256 public claimingFee = 0.000 ether;

     
    struct FeedingData {
        uint256 blockNumber;     
        uint256 horsey;          
    }

     
    mapping(address => FeedingData) public pendingFeedings;

     
    uint256 public renamingCostsPerChar = 0.001 ether;

     
    constructor(address stablesAddress) 
    EthorseHelpers() 
    Pausable() public {
        stables = RoyalStablesInterface(stablesAddress);
    }

     
    function setRarityMultiplier(uint8 newRarityMultiplier) external 
    onlyOwner()  {
        rarityMultiplier = newRarityMultiplier;
    }

     
    function setCarrotsMultiplier(uint8 newCarrotsMultiplier) external 
    onlyOwner()  {
        carrotsMultiplier = newCarrotsMultiplier;
    }

     
    function setRenamingCosts(uint256 newRenamingCost) external 
    onlyOwner()  {
        renamingCostsPerChar = newRenamingCost;
    }

     
    function setClaimingCosts(uint256 newClaimingFee) external
    onlyOwner()  {
        claimingFee = newClaimingFee;
    }

     
    function addLegitRaceAddress(address newAddress) external
    onlyOwner() {
        _addLegitRace(newAddress);
    }

     
    function withdraw() external 
    onlyOwner()  {
        owner.transfer(address(this).balance);  
    }

     
     
    function addHorseIndex(bytes32 newHorse) external
    onlyOwner() {
        _addHorse(newHorse);
    }

     
    function getOwnedTokens(address eth_address) public view returns (uint256[]) {
        return stables.getOwnedTokens(eth_address);
    }
    
     
    function can_claim(address raceAddress, address eth_address) public view returns (bool) {
        bool res;
        (res,) = _isWinnerOf(raceAddress, eth_address);
        return res;
    }

     
    function claim(address raceAddress) external payable
    costs(claimingFee)
    whenNotPaused()
    {
         
        bytes32 winner;
        bool res;
        (res,winner) = _isWinnerOf(raceAddress, msg.sender);
        require(winner != bytes32(0),"Winner is zero");
        require(res,"can_claim return false");
         
        uint256 id = _generate_special_horsey(raceAddress, msg.sender, winner);
        emit Claimed(raceAddress, msg.sender, id);
    }

     
    function renameHorsey(uint256 tokenId, string newName) external 
    whenNotPaused()
    onlyOwnerOf(tokenId) 
    costs(renamingCostsPerChar * bytes(newName).length)
    payable {
        uint256 renamingFee = renamingCostsPerChar * bytes(newName).length;
         
        if(msg.value > renamingFee)  
        {
            msg.sender.transfer(msg.value - renamingFee);
        }
         
        stables.storeName(tokenId,newName);
        emit HorseyRenamed(tokenId,newName);
    }

     
    function freeForCarrots(uint256 tokenId) external 
    whenNotPaused()
    onlyOwnerOf(tokenId) {
        require(pendingFeedings[msg.sender].horsey != tokenId,"");
         
        uint8 feedingCounter;
        (,,feedingCounter,) = stables.horseys(tokenId);
        stables.storeCarrotsCredit(msg.sender,stables.carrot_credits(msg.sender) + uint32(feedingCounter * carrotsMultiplier));
        stables.unstoreHorsey(tokenId);
        emit HorseyFreed(tokenId);
    }

     
    function getCarrotCredits() external view returns (uint32) {
        return stables.carrot_credits(msg.sender);
    }

     
    function getHorsey(uint256 tokenId) public view returns (address, bytes32, uint8, string) {
        RoyalStablesInterface.Horsey memory temp;
        (temp.race,temp.dna,temp.feedingCounter,temp.tier) = stables.horseys(tokenId);
        return (temp.race,temp.dna,temp.feedingCounter,stables.names(tokenId));
    }

     
    function feed(uint256 tokenId) external 
    whenNotPaused()
    onlyOwnerOf(tokenId) 
    carrotsMeetLevel(tokenId)
    noFeedingInProgress()
    {
        pendingFeedings[msg.sender] = FeedingData(block.number,tokenId);
        uint8 feedingCounter;
        (,,feedingCounter,) = stables.horseys(tokenId);
        stables.storeCarrotsCredit(msg.sender,stables.carrot_credits(msg.sender) - uint32(feedingCounter));
        emit Feeding(tokenId);
    }

     
    function stopFeeding() external
    feedingInProgress() returns (bool) {
        uint256 blockNumber = pendingFeedings[msg.sender].blockNumber;
        uint256 tokenId = pendingFeedings[msg.sender].horsey;
         
        require(block.number - blockNumber >= 1,"feeding and stop feeding are in same block");

        delete pendingFeedings[msg.sender];

         
         
        if(block.number - blockNumber > 255) {
             
             
            emit FeedingFailed(tokenId);
            return false; 
        }

         
        if(stables.ownerOf(tokenId) != msg.sender) {
             
             
            emit FeedingFailed(tokenId);
            return false; 
        }
        
         
        _feed(tokenId, blockhash(blockNumber));
        bytes32 dna;
        (,dna,,) = stables.horseys(tokenId);
        emit ReceivedCarrot(tokenId, dna);
        return true;
    }

     
    function() external payable {
        revert("Not accepting donations");
    }

     
    function _feed(uint256 tokenId, bytes32 blockHash) internal {
         
        uint8 tier;
        uint8 feedingCounter;
        (,,feedingCounter,tier) = stables.horseys(tokenId);
        uint256 probabilityByRarity = 10 ** uint256(tier + 1);
        uint256 randNum = uint256(keccak256(abi.encodePacked(tokenId, blockHash))) % probabilityByRarity;

         
        if(randNum <= (feedingCounter * rarityMultiplier)){
            _increaseRarity(tokenId, blockHash);
        }

         
         
        if(feedingCounter < 255) {
            stables.modifyHorseyFeedingCounter(tokenId,feedingCounter+1);
        }
    }

     
    function _makeSpecialId(address race, address sender, bytes32 coinIndex) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(race, sender, coinIndex)));
    }

     
    function _generate_special_horsey(address race, address eth_address, bytes32 coinIndex) internal returns (uint256) {
        uint256 id = _makeSpecialId(race, eth_address, coinIndex);
         
        bytes32 dna = _shiftRight(keccak256(abi.encodePacked(race, coinIndex)),16);
          
        stables.storeHorsey(eth_address,id,race,dna,1,0);
        return id;
    }
    
     
    function _increaseRarity(uint256 tokenId, bytes32 blockHash) private {
        uint8 tier;
        bytes32 dna;
        (,dna,,tier) = stables.horseys(tokenId);
        if(tier < 254)
            stables.modifyHorseyTier(tokenId,tier+1);
        uint256 random = uint256(keccak256(abi.encodePacked(tokenId, blockHash)));
         
        bytes32 rarityMask = _shiftLeft(bytes32(1), (random % 16 + 240));
        bytes32 newdna = dna | rarityMask;  
        stables.modifyHorseyDna(tokenId,newdna);
    }

     
    function _shiftLeft(bytes32 data, uint n) internal pure returns (bytes32) {
        return bytes32(uint256(data)*(2 ** n));
    }

     
    function _shiftRight(bytes32 data, uint n) internal pure returns (bytes32) {
        return bytes32(uint256(data)/(2 ** n));
    }

     
    modifier carrotsMeetLevel(uint256 tokenId){
        uint256 feedingCounter;
        (,,feedingCounter,) = stables.horseys(tokenId);
        require(feedingCounter <= stables.carrot_credits(msg.sender),"Not enough carrots");
        _;
    }

     
    modifier costs(uint256 amount) {
        require(msg.value >= amount,"Not enough funds");
        _;
    }

     
    modifier validAddress(address addr) {
        require(addr != address(0),"Address is zero");
        _;
    }

     
    modifier noFeedingInProgress() {
         
        require(pendingFeedings[msg.sender].blockNumber == 0,"Already feeding");
        _;
    }

     
    modifier feedingInProgress() {
         
        require(pendingFeedings[msg.sender].blockNumber != 0,"No pending feeding");
        _;
    }

     
    modifier onlyOwnerOf(uint256 tokenId) {
        require(stables.ownerOf(tokenId) == msg.sender, "Caller is not owner of this token");
        _;
    }
}

 

 

contract HorseyPilot {

     
    event NewProposal(uint8 methodId, uint parameter, address proposer);

     
    event ProposalPassed(uint8 methodId, uint parameter, address proposer);

     
     
    uint8 constant votingThreshold = 2;

     
     
    uint256 constant proposalLife = 7 days;

     
     
    uint256 constant proposalCooldown = 1 days;

     
    uint256 cooldownStart;

     
    address public jokerAddress;
    address public knightAddress;
    address public paladinAddress;

     
    address[3] public voters;

     
    uint8 constant public knightEquity = 40;
    uint8 constant public paladinEquity = 10;

     
    address public exchangeAddress;
    address public tokenAddress;

     
    mapping(address => uint) internal _cBalance;

     
    struct Proposal{
        address proposer;            
        uint256 timestamp;           
        uint256 parameter;           
        uint8   methodId;            
        address[] yay;               
        address[] nay;               
    }

     
    Proposal public currentProposal;

     
    bool public proposalInProgress = false;

     
    uint256 public toBeDistributed;

     
    bool deployed = false;

     
    constructor(
    address _jokerAddress,
    address _knightAddress,
    address _paladinAddress,
    address[3] _voters
    ) public {
        jokerAddress = _jokerAddress;
        knightAddress = _knightAddress;
        paladinAddress = _paladinAddress;

        for(uint i = 0; i < 3; i++) {
            voters[i] = _voters[i];
        }

         
        cooldownStart = block.timestamp - proposalCooldown;
    }

     
    function deployChildren(address stablesAddress) external {
        require(!deployed,"already deployed");
         
        exchangeAddress = new HorseyExchange();
        tokenAddress = new HorseyToken(stablesAddress);

         
        HorseyExchange(exchangeAddress).setStables(stablesAddress);

        deployed = true;
    }

     
    function transferJokerOwnership(address newJoker) external 
    validAddress(newJoker) {
        require(jokerAddress == msg.sender,"Not right role");
        _moveBalance(newJoker);
        jokerAddress = newJoker;
    }

     
    function transferKnightOwnership(address newKnight) external 
    validAddress(newKnight) {
        require(knightAddress == msg.sender,"Not right role");
        _moveBalance(newKnight);
        knightAddress = newKnight;
    }

     
    function transferPaladinOwnership(address newPaladin) external 
    validAddress(newPaladin) {
        require(paladinAddress == msg.sender,"Not right role");
        _moveBalance(newPaladin);
        paladinAddress = newPaladin;
    }

     
    function withdrawCeo(address destination) external 
    onlyCLevelAccess()
    validAddress(destination) {
         
         
        if(toBeDistributed > 0){
            _updateDistribution();
        }
        
         
        uint256 balance = _cBalance[msg.sender];
        
         
        if(balance > 0 && (address(this).balance >= balance)) {
            destination.transfer(balance);  
            _cBalance[msg.sender] = 0;
        }
    }

     
    function syncFunds() external {
        uint256 prevBalance = address(this).balance;
        HorseyToken(tokenAddress).withdraw();
        HorseyExchange(exchangeAddress).withdraw();
        uint256 newBalance = address(this).balance;
         
        toBeDistributed = toBeDistributed + (newBalance - prevBalance);
    }

     
    function getNobleBalance() external view
    onlyCLevelAccess() returns (uint256) {
        return _cBalance[msg.sender];
    }

     
    function makeProposal( uint8 methodId, uint256 parameter ) external
    onlyCLevelAccess()
    proposalAvailable()
    cooledDown()
    {
        currentProposal.timestamp = block.timestamp;
        currentProposal.parameter = parameter;
        currentProposal.methodId = methodId;
        currentProposal.proposer = msg.sender;
        delete currentProposal.yay;
        delete currentProposal.nay;
        proposalInProgress = true;
        
        emit NewProposal(methodId,parameter,msg.sender);
    }

     
    function voteOnProposal(bool voteFor) external 
    proposalPending()
    onlyVoters()
    notVoted() {
         
        require((block.timestamp - currentProposal.timestamp) <= proposalLife);
        if(voteFor)
        {
            currentProposal.yay.push(msg.sender);
             
            if( currentProposal.yay.length >= votingThreshold )
            {
                _doProposal();
                proposalInProgress = false;
                 
                return;
            }

        } else {
            currentProposal.nay.push(msg.sender);
             
            if( currentProposal.nay.length >= votingThreshold )
            {
                proposalInProgress = false;
                cooldownStart = block.timestamp;
                return;
            }
        }
    }

     
    function _moveBalance(address newAddress) internal
    validAddress(newAddress) {
        require(newAddress != msg.sender);  
        _cBalance[newAddress] = _cBalance[msg.sender];
        _cBalance[msg.sender] = 0;
    }

     
    function _updateDistribution() internal {
        require(toBeDistributed != 0,"nothing to distribute");
        uint256 knightPayday = toBeDistributed / 100 * knightEquity;
        uint256 paladinPayday = toBeDistributed / 100 * paladinEquity;

         
        uint256 jokerPayday = toBeDistributed - knightPayday - paladinPayday;

        _cBalance[jokerAddress] = _cBalance[jokerAddress] + jokerPayday;
        _cBalance[knightAddress] = _cBalance[knightAddress] + knightPayday;
        _cBalance[paladinAddress] = _cBalance[paladinAddress] + paladinPayday;
         
        toBeDistributed = 0;
    }

     
    function _doProposal() internal {
         
        if( currentProposal.methodId == 0 ) HorseyToken(tokenAddress).setRenamingCosts(currentProposal.parameter);
        
         
        if( currentProposal.methodId == 1 ) HorseyExchange(exchangeAddress).setMarketFees(currentProposal.parameter);

         
        if( currentProposal.methodId == 2 ) HorseyToken(tokenAddress).addLegitRaceAddress(address(currentProposal.parameter));

         
        if( currentProposal.methodId == 3 ) HorseyToken(tokenAddress).addHorseIndex(bytes32(currentProposal.parameter));

         
        if( currentProposal.methodId == 4 ) {
            if(currentProposal.parameter == 0) {
                HorseyExchange(exchangeAddress).unpause();
                HorseyToken(tokenAddress).unpause();
            } else {
                HorseyExchange(exchangeAddress).pause();
                HorseyToken(tokenAddress).pause();
            }
        }

         
        if( currentProposal.methodId == 5 ) HorseyToken(tokenAddress).setClaimingCosts(currentProposal.parameter);

         
        if( currentProposal.methodId == 8 ){
            HorseyToken(tokenAddress).setCarrotsMultiplier(uint8(currentProposal.parameter));
        }

         
        if( currentProposal.methodId == 9 ){
            HorseyToken(tokenAddress).setRarityMultiplier(uint8(currentProposal.parameter));
        }

        emit ProposalPassed(currentProposal.methodId,currentProposal.parameter,currentProposal.proposer);
    }

     
    modifier validAddress(address addr) {
        require(addr != address(0),"Address is zero");
        _;
    }

     
    modifier onlyCLevelAccess() {
        require((jokerAddress == msg.sender) || (knightAddress == msg.sender) || (paladinAddress == msg.sender),"not c level");
        _;
    }

     
     
    modifier proposalAvailable(){
        require(((!proposalInProgress) || ((block.timestamp - currentProposal.timestamp) > proposalLife)),"proposal already pending");
        _;
    }

     
     
    modifier cooledDown( ){
        if(msg.sender == currentProposal.proposer && (block.timestamp - cooldownStart < 1 days)){
            revert("Cool down period not passed yet");
        }
        _;
    }

     
    modifier proposalPending() {
        require(proposalInProgress,"no proposal pending");
        _;
    }

     
    modifier notVoted() {
        uint256 length = currentProposal.yay.length;
        for(uint i = 0; i < length; i++) {
            if(currentProposal.yay[i] == msg.sender) {
                revert("Already voted");
            }
        }

        length = currentProposal.nay.length;
        for(i = 0; i < length; i++) {
            if(currentProposal.nay[i] == msg.sender) {
                revert("Already voted");
            }
        }
        _;
    }

     
    modifier onlyVoters() {
        bool found = false;
        uint256 length = voters.length;
        for(uint i = 0; i < length; i++) {
            if(voters[i] == msg.sender) {
                found = true;
                break;
            }
        }
        if(!found) {
            revert("not a voter");
        }
        _;
    }
}