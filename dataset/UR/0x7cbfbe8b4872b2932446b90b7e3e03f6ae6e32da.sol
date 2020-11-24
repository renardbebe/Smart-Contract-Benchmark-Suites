 

pragma solidity ^0.4.2;

  
contract ERC721 {
    event Transfer(address _from, address _to, uint256 _tokenId);
    event Approval(address _owner, address _approved, uint256 _tokenId);
    
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function transfer(address _to, uint256 _tokenId) public;
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    function totalSupply() constant returns (uint256 totalSupply);
    
    function tokenMetadata(uint256 _tokenId) constant returns (string infoUrl);
    
    function name() constant returns (string name);
    function symbol() constant returns (string symbol);
}

  
contract Ownable {
  address public owner;

event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

  
contract Config is Ownable {
    event Setup(uint8 _patchVersion, uint256 _cardPrice, uint8 _percentage1, uint8 _percentage2);
    event Gift(uint256 _count, address _from, address _to);
    uint256 internal randomNonce = 0;
    uint256 internal cardPrice = 0;
    uint256 internal patchTimestamp;
    uint8   internal patchVersion = 0;
    uint8   internal level = 1;
    uint32  internal constantTime = (6048 * 100) + 1;  
    uint8   internal percentage1 = 60;
    uint8   internal percentage2 = 80;
    uint8   internal auctionMarge = 5;
    uint128  internal levelUp = 8 * 10 ** 15;  
    uint128 internal levelUpVIP =4 * 10 **15;  
	uint128 internal VIPCost = 99 * 10 ** 16;  
	string internal URL = "https://www.etherchicks.com/card/";
    

   struct User{
        uint256 gifts;
        bool vip;
        bool exists;
    }
    mapping (address => User) userProfile;
    
    function giftFor(address _from, address _target, uint256 _count) internal{
        uint256 giftCount = _count;
        if(userProfile[_target].exists)
        {
            if(userProfile[_target].vip)
            {
                giftCount += 1;
            }
            userProfile[_target].gifts += giftCount;
            Gift(giftCount, _from, _target);
        }
    }
    
    function setUser(address _id, address _target, bool _vip) internal
    {
        if(!userProfile[_id].exists){
            giftFor(_id, _target, 1);
            
            User memory user = User(
               0,
               _vip,
               true
            );
            userProfile[_id] = user;
        }
        else if(_vip == true){
           userProfile[_id].vip = _vip; 
        }
        
        
    }
    
    function getUser(address _id) external view returns (uint256 Gifts, bool VIP, bool Exists)
    {
        return (userProfile[_id].gifts, userProfile[_id].vip, userProfile[_id].exists);
    }
    
    mapping (address => uint8) participant;
    mapping (uint8 => address) participantIndex;
    uint8 internal numberOfParticipants = 0;
    
    function setPatch(uint256 _cardPrice, uint8 _percentage1, uint8 _percentage2) public onlyOwner {
        patchVersion++;
        cardPrice = _cardPrice;
        patchTimestamp = now;
        
        if(_percentage1 != 0 && _percentage2 != 0){
            percentage1 = _percentage1;
            percentage2 = _percentage2;
        }
        
        Setup(patchVersion, cardPrice, percentage1, percentage2);
    }
    
      function percentage(uint256 cost, uint8 _percentage) internal pure returns(uint256)
      {
          require(_percentage < 100);
          return (cost * _percentage) / 100;
      }
      
      function setACmarge(uint8 _auctionMarge) external onlyOwner {
          auctionMarge = _auctionMarge;
      }
      function setUrl(string _url) external onlyOwner {
          URL = _url;
      }
    
    function addParticipant(address _participant, uint8 _portion) external onlyOwner {
        participantIndex[numberOfParticipants] = _participant;
        participant[_participant] = _portion;
        numberOfParticipants++;
    }
    function removeParticipant(uint8 _index) external onlyOwner
    {
        delete participant[participantIndex[_index]];
        delete participantIndex[_index];
        numberOfParticipants--;
    }
    function getAllParticipants() external view onlyOwner returns(address[], uint8[]) {
        address[] memory addresses = new address[](numberOfParticipants);
        uint8[] memory portions   = new uint8[](numberOfParticipants);
        for(uint8 i=0; i<numberOfParticipants; i++)
        {
            addresses[i] =participantIndex[i];
            portions[i] = participant[participantIndex[i]];
        }
        return (addresses, portions);
    }
    
    
}

 
contract CardCore is Config {

    event Birth(address userAddress, uint256 cardId, uint256 code, uint8 level, uint8 patch);
    event Update(address userAddress, uint256 cardId, uint8 level);
    event VIP(address userAddress);

     
    struct Card{
        uint256 code;
        uint8 level;
        uint8 patch;
    }

    Card[] public cards;

     
    mapping (uint256 => address) cardToOwner;
    mapping (address => uint256) ownerCardCount;

    modifier cardOwner(uint256 _cardId) {
        require(msg.sender == cardToOwner[_cardId]);
        _;
    }
    

    function _generateCode(address _userAddress, uint256 _blockNr) internal returns (uint256){
        randomNonce++;
        uint256 newCode = uint256(keccak256(_userAddress, _blockNr, randomNonce));
        return newCode;
    }
    
    function _updateCard(address _userAddress, uint256 _cardId) internal{
        require(_owns(_userAddress, _cardId));
        Card storage storedCard = cards[_cardId];
        if(storedCard.level < 9)
        {
            storedCard.level++;
             
            Update(_userAddress, _cardId, storedCard.level);
        }
    }
    
    function _beingVIP(address _userAddress) internal{
        setUser(msg.sender, address(0), true);
        VIP(_userAddress);
    }
    
    function _owns(address _userAddress, uint256 _cardId) internal view returns (bool) {
        return cardToOwner[_cardId] == _userAddress;
    }
    
    function _getCards(uint8 numberOfCards, address _userAddress) internal{
         
        require(numberOfCards > 0);
        require(numberOfCards < 11);
         
        uint256 cardId;
        uint256 cardCode;
        Card memory c;
        uint256 _blockNr = uint256(keccak256(block.blockhash(block.number-1)));
        for(uint8 i = 0; i < numberOfCards; i++)
        {
            cardCode = _generateCode(_userAddress, _blockNr);
            c = Card(cardCode, level, patchVersion);
            cardId = cards.push(c) - 1;
            
             
            cardToOwner[cardId] = _userAddress;
            ownerCardCount[_userAddress]++;
             
            Birth(_userAddress, cardId, cardCode, level, patchVersion);
        }
    }


}


 
 
contract CardOwnership is CardCore, ERC721 {

     

    mapping (uint256 => address) cardApprovals;
	 

    
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownerCardCount[_to]++;
         
        cardToOwner[_tokenId] = _to;

        ownerCardCount[_from]--;
         
        
        delete cardApprovals[_tokenId];
       
         
        Transfer(_from, _to, _tokenId);
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownerCardCount[_owner];
    }

    function transfer(address _to, uint256 _tokenId) public cardOwner(_tokenId)
    {
         
        require(_to != address(0));
        require(_to != address(this));
        require(cardApprovals[_tokenId] == address(0));

         
        _transfer(msg.sender, _to, _tokenId);
    }
      function name() constant returns (string name){
        return "Etherchicks";
      }
       function symbol() constant returns (string symbol){
        return "ETCS";
      }
      
  
     
    function approve(address _to, uint256 _tokenId) public cardOwner(_tokenId) 
    {
         
        cardApprovals[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }


     
    function totalSupply() public view returns (uint) {
        return cards.length - 1;
    }

    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address _owner)
    {
        return cardToOwner[_tokenId];
    }
    
      function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
    {       
        require(_to != address(0));
        require(_to != address(this));
        require(cardApprovals[_tokenId] == address(this));

         
        _transfer(_from, _to, _tokenId);
    }

     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCards = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 tokId;

            for (tokId = 1; tokId <= totalCards ; tokId++) {
                if (cardToOwner[tokId] == _owner) {
                    result[resultIndex] = tokId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
    function appendUintToString(string inStr, uint256 v) constant internal returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i + 1);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j <= i; j++) {
            s[j + inStrb.length] = reversed[i - j];
        }
        str = string(s);
        return str;
    }
    
    function tokenMetadata(uint256 _tokenId) constant returns (string infoUrl) 
    {
        return appendUintToString(URL, _tokenId);
    }
    

}

 
contract AuctionHouse is CardOwnership {
    
    event AuctionStarted(uint256 tokenId, uint128 startPrice, uint128 finalPrice, uint256 timestamp);
    event AuctionEnded(address winner, uint256 tokenId);
    struct Auction {
        address seller;
        uint128 startPrice;
        uint128 finalPrice;
        uint256 timestamp;
    }
    mapping (uint256 => Auction) public tokenIdToAuction;
	 
      
    function _isAuctionAble(uint256 _timestamp) internal view returns(bool)
    {
       return (_timestamp + constantTime >= now);
    }
  
    function createAuction(
        uint256 _tokenId,
        uint128 _startPrice,
        uint128 _finalPrice
    ) external cardOwner(_tokenId){
	    require(!_isAuctionAble(tokenIdToAuction[_tokenId].timestamp));
         
        approve( this, _tokenId);
         
        Auction memory auction = Auction(
            msg.sender,
            _startPrice,
            _finalPrice,
            now
        );
        
        tokenIdToAuction[_tokenId] = auction;
        AuctionStarted(_tokenId, _startPrice, _finalPrice, now);
    }
	
    function buyout(uint256 _tokenId) external payable {
        Auction storage auction = tokenIdToAuction[_tokenId];
        
        require(_isAuctionAble(auction.timestamp));
        
        uint256 price = _currentPrice(auction);
        
        require(msg.value >= price);
        
        address seller = tokenIdToAuction[_tokenId].seller;
        
        uint256 auctionCost = percentage(msg.value, auctionMarge); 
        
        _removeAuction(_tokenId);
         
         seller.transfer(msg.value - auctionCost);
          
        transferFrom(seller, msg.sender, _tokenId);
        AuctionEnded(msg.sender, _tokenId);

    }
    
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        if (now > _auction.timestamp) {
            secondsPassed = now - _auction.timestamp;
        }

        return _computeCurrentPrice(
            _auction.startPrice,
            _auction.finalPrice,
            secondsPassed,
            constantTime
        );
    }
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _secondsPassed,
        uint32 _sevenDays
    )
        internal
        pure
        returns (uint256)
    {
    
        if (_secondsPassed >= _sevenDays) {
            return _endingPrice;
        } 
        else 
        {
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_sevenDays);
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }


	function cancelAuction(uint256 _tokenId)
        external cardOwner(_tokenId)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(auction.timestamp > 0);
        require(msg.sender == auction.seller);
        
        _removeAuction(_tokenId);
        delete cardApprovals[_tokenId];
        AuctionEnded(address(0), _tokenId);
    }

    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isAuctionAble(auction.timestamp));
        return _currentPrice(auction);
    }


}


 
contract Etherchicks is AuctionHouse {
      
    function Etherchicks() public {
         
       setPatch(3 * 10 ** 16,  0, 0 );
       _beingVIP(msg.sender);
    }

    function getCard(uint256 _id)
        external
        view
        returns (
        uint256 code,
        uint8  level,
        uint8   patch
    ) {               
        Card storage card = cards[_id];
        code = uint256(card.code);
        level = uint8(card.level);
        patch = uint8(card.patch);
        
    }
    function _calculateDiscount(uint8 _nr, address _user) internal view returns (uint256){       
      uint256 _cardPrice = cardPrice * _nr;      
      if(uint256(constantTime + patchTimestamp) >= now)
      {
          _cardPrice = percentage(_cardPrice, percentage1);
      }
      else if(uint256((constantTime * 2) + patchTimestamp) >= now)
      {
          _cardPrice = percentage(_cardPrice, percentage2);
      }    
      
      if(userProfile[_user].exists && userProfile[_user].vip)
      {
          _cardPrice = percentage(_cardPrice, 50);
      }
      return _cardPrice;
  }
     
    function getMarketPrice(uint8 _nr) external view returns(uint256){
        return _calculateDiscount(_nr, msg.sender);
    }  
  function buyCardsAndSendGift(uint8 _nr, address _referral) external payable{
      require(_calculateDiscount(_nr, msg.sender) <= msg.value);
        _getCards(_nr, msg.sender);
        setUser(msg.sender, _referral, false);
  }
  
  function buyCards(uint8 _nr) external payable
  {
      require(_calculateDiscount(_nr, msg.sender) <= msg.value);
        _getCards(_nr, msg.sender);
        setUser(msg.sender, address(0), false);
  }
  function sendGift(address _targetAddress, uint256 _count) external onlyOwner
  {
      giftFor(address(0), _targetAddress, _count);
  }
  function withdrawGift() external{
      if(userProfile[msg.sender].gifts > 0)
      {
        _getCards(1, msg.sender);
        userProfile[msg.sender].gifts--;
      }
  }
  
  function beingVIP() external payable{
      require(VIPCost <= msg.value);
      _beingVIP(msg.sender);
  }
    
    function updateCard(uint256 _cardId) external payable{        
         
        require(cardApprovals[_cardId] == address(0));
        uint128 cost = getLevelUpCost(msg.sender); 
        require(cost <= msg.value);
        _updateCard(msg.sender, _cardId);
  }
  
  function getLevelUpCost(address _address) public view returns (uint128){
        uint128 cost = levelUp;  
        if(userProfile[_address].vip)
        {
            cost = levelUpVIP;
        }
        return cost;
  }
  
     
    function withdrawBalance(uint256 _amount) external onlyOwner  {
        uint256 amount = this.balance;
		if(_amount <= amount)
		{
		    amount = participantsFirst(_amount);
			owner.transfer(_amount);
		}
		else
		{
		    amount = participantsFirst(amount);
		    owner.transfer(amount);
		}
    }
    
    function participantsFirst(uint256 _amount) internal returns(uint256){
        uint256 provision;
        uint256 amount = _amount;
        for(uint8 i=0; i < numberOfParticipants; i++)
        {
            provision = percentage(_amount, participant[participantIndex[i]]);
            amount = amount - provision;
            participantIndex[i].transfer(provision);
        }
        return amount;
    }
}