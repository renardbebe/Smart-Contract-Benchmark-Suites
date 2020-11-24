 

pragma solidity ^0.4.24;

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

interface Token {
    function transfer(address to, uint256 value) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
    function approve(address spender, uint256 value) external returns (bool success);

     
    function totalSupply() external constant returns (uint256 supply);
    function balanceOf(address owner) external constant returns (uint256 balance);
    function allowance(address owner, address spender) external constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface PromissoryToken {

	function claim() payable external;
	function lastPrice() external returns(uint256);
}

contract DutchAuction {

     
    event BidSubmission(address indexed sender, uint256 amount);
    event logPayload(bytes _data, uint _lengt);

     
    uint constant public MAX_TOKENS_SOLD = 10000000 * 10**18;  
    uint constant public WAITING_PERIOD = 45 days;

     


    address public pWallet;
    Token public KittieFightToken;
    address public owner;
    PromissoryToken public PromissoryTokenIns; 
    address constant public promissoryAddr = 0x0348B55AbD6E1A99C6EBC972A6A4582Ec0bcEb5c;
    uint public ceiling;
    uint public priceFactor;
    uint public startBlock;
    uint public endTime;
    uint public totalReceived;
    uint public finalPrice;
    mapping (address => uint) public bids;
    Stages public stage;

     
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TradingStarted
    }

     
    modifier atStage(Stages _stage) {
        require(stage == _stage);
             
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner);
             
        _;
    }

    modifier isWallet() {
         require(msg.sender == address(pWallet));
             
        _;
    }

    modifier isValidPayload() {
        emit logPayload(msg.data, msg.data.length);
        require(msg.data.length == 4 || msg.data.length == 36, "No valid payload");
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stages.AuctionEnded && now > endTime + WAITING_PERIOD)
            stage = Stages.TradingStarted;
        _;
    }

     
     
     
     
     
    constructor(address _pWallet, uint _ceiling, uint _priceFactor)
        public
    {
        if (_pWallet == 0 || _ceiling == 0 || _priceFactor == 0)
             
            revert();
        owner = msg.sender;
        PromissoryTokenIns = PromissoryToken(promissoryAddr);
        pWallet = _pWallet;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        stage = Stages.AuctionDeployed;
    }

     
     
    function setup(address _kittieToken)
        public
        isOwner
        atStage(Stages.AuctionDeployed)
    {
        if (_kittieToken == 0)
             
            revert();
        KittieFightToken = Token(_kittieToken);
         
        if (KittieFightToken.balanceOf(this) != MAX_TOKENS_SOLD)
            revert();
        stage = Stages.AuctionSetUp;
    }

     
    function startAuction()
        public
        isOwner
        atStage(Stages.AuctionSetUp)
    {
        stage = Stages.AuctionStarted;
        startBlock = block.number;
    }

     
     
     
    function changeSettings(uint _ceiling, uint _priceFactor)
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        ceiling = _ceiling;
        priceFactor = _priceFactor;
    }

     
     
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint)
    {
        if (stage == Stages.AuctionEnded || stage == Stages.TradingStarted)
            return finalPrice;
        return calcTokenPrice();
    }

     
     
    function updateStage()
        public
        timedTransitions
        returns (Stages)
    {
        return stage;
    }

     
     
    function bid(address receiver)
        public
        payable
         
        timedTransitions
        atStage(Stages.AuctionStarted)
        returns (uint amount)
    {
         
        if (receiver == 0)
            receiver = msg.sender;
        amount = msg.value;
         
        uint maxWei = (MAX_TOKENS_SOLD / 10**18) * calcTokenPrice() - totalReceived;
        uint maxWeiBasedOnTotalReceived = ceiling - totalReceived;
        if (maxWeiBasedOnTotalReceived < maxWei)
            maxWei = maxWeiBasedOnTotalReceived;
         
        if (amount > maxWei) {
            amount = maxWei;
             
            if (!receiver.send(msg.value - amount))
                 
                revert();
        }
         
        if (amount == 0 || !address(pWallet).send(amount))
             
            revert();
        bids[receiver] += amount;
        totalReceived += amount;
        if (maxWei == amount)
             
            finalizeAuction();
        emit BidSubmission(receiver, amount);
    }

     
     
    function claimTokens(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stages.TradingStarted)
    {
        if (receiver == 0)
            receiver = msg.sender;
        uint tokenCount = bids[receiver] * 10**18 / finalPrice;
        bids[receiver] = 0;
        KittieFightToken.transfer(receiver, tokenCount);
    }

     
     
    function calcStopPrice()
        view
        public
        returns (uint)
    {
        return totalReceived * 10**18 / MAX_TOKENS_SOLD + 1;
    }

     
     
    function calcTokenPrice()
        view
        public
        returns (uint)
    {
        return priceFactor * 10**18 / (block.number - startBlock + 7500) + 1;
    }

     
    function finalizeAuction()
        private
    {
        stage = Stages.AuctionEnded;

        if (totalReceived == ceiling)
            finalPrice = calcTokenPrice();
        else
            finalPrice = calcStopPrice();

        endTime = now;
    }


}

contract Dutchwrapper is DutchAuction {


    uint constant public MAX_TOKEN_REFERRAL = 2000000 * 10**18;  

    uint public claimedTokenReferral = 0;  
    uint public totalEthEarnedByPartners = 0;  


     
    uint constant public TOTAL_BONUS_TOKEN = 2000000 * 10**18;

    uint public softCap;
    bool public softcapReached = false;


    uint constant public Partners = 1;  
    uint constant public Referrals = 2;  
    

    uint constant public ONE = 1;  

     
    uint constant public thirty = 30 * 10**18;  
    uint constant public twoHundred = 200 * 10**18;  
    uint constant public sixHundred = 600 * 10**18;  

    uint constant public oneHundred = 100 * 10**18;  
    uint constant public fiveHundred = 500 * 10**18;  
    uint constant public oneThousand = 1000 * 10**18;  
    uint public residualToken;  

    mapping (address => uint) public SuperDAOTokens;  
     

    struct PartnerForEth {
        bytes4 hash;  
        address addr;  
        uint totalReferrals;  
        uint totalContribution;  
        uint[] individualContribution;  
        uint percentage;  
        uint EthEarned;  
    }

	address [] public PartnersList;  

     
    struct tokenForReferral {
        bytes4 hash;  
        address addr;  
        uint totalReferrals;  
        uint totalTokensEarned;  
        mapping(uint => uint) tokenAmountPerReferred; 
    }

     address [] public TokenReferalList;  

     bytes4 [20] public topAddrHashes;  
     uint [20] public topReferredNum;  

    event topAddrHashesUpdate(bytes4 [20] topAddrHashes);  
    event topNumbersUpdate(uint[20] topNumArray);   
    bool public bidderBonus = true;  

    mapping(bytes4 => PartnerForEth )  public MarketingPartners;
    mapping(bytes4 => tokenForReferral)  public TokenReferrals;
    mapping(address => bool ) public Admins;

     
    struct bidder {
        address addr;
        uint amount;
    }

    bidder [] public CurrentBidders;  


    event PartnerReferral(bytes4 _partnerHash,address _addr, uint _amount); 
    event TokenReferral(bytes4 _campaignHash,address _addr, uint _amount); 
    event BidEvent(bytes4 _hash, address _addr, uint _amount);  
    event SetupReferal(uint _type);  
    event ReferalSignup(bytes4 _Hash, address _addr);  
    event ClaimtokenBonus(bytes4 _Hash, address _addr, bool success);  



     
    modifier tradingstarted(){
        require(stage == Stages.TradingStarted);
        _;
    }

     
     

     
    modifier ReferalCampaignLimit() {
        require (claimedTokenReferral < MAX_TOKEN_REFERRAL);
        _;
    }


    constructor  (address _pWallet, uint _ceiling, uint _priceFactor, uint _softCap)
        DutchAuction(_pWallet, _ceiling, _priceFactor)  public {

            softCap = _softCap;
    }

    function checksoftCAP() internal {
         
        if( totalReceived >= softCap ) {
            softcapReached = true;
        }
    }

     
     

    function setupReferal(address _addr, uint _percentage)
        public
        isOwner
        returns (string successmessage) 
    {

            bytes4 tempHash = bytes4(keccak256(abi.encodePacked(_addr, msg.sender)));

            MarketingPartners[tempHash].hash = tempHash;
            MarketingPartners[tempHash].addr = _addr;
            MarketingPartners[tempHash].percentage = _percentage;

            InternalReferalSignupByhash(tempHash, _addr);

    		emit SetupReferal(1);  
            return "partner signed up";
    }

     
     
    function InternalReferalSignup(address _addr) internal returns (bytes4 referalhash) {
        
        bytes4 tempHash = bytes4(keccak256(abi.encodePacked(_addr)));
        TokenReferrals[tempHash].addr = msg.sender;
        TokenReferrals[tempHash].hash = tempHash;
        referalhash = tempHash;
        emit ReferalSignup(tempHash, _addr);
    }

     
    function InternalReferalSignupByhash(bytes4 _hash, address _addr) internal returns (bytes4 referalhash) {
        TokenReferrals[_hash].addr = _addr;
        TokenReferrals[_hash].hash = _hash;
        referalhash = _hash;
        emit ReferalSignup(_hash, _addr);
    }


     
    function referralSignup() public ReferalCampaignLimit returns (bytes4 referalhash) {
        bytes4 tempHash = bytes4(keccak256(abi.encodePacked(msg.sender)));
        require (tempHash != TokenReferrals[tempHash].hash);  
        TokenReferrals[tempHash].addr = msg.sender;
        TokenReferrals[tempHash].hash = tempHash;
        referalhash = tempHash;
        emit ReferalSignup(tempHash, msg.sender);
    }


     
    function bidReferral(address _receiver, bytes4 _hash) public payable returns (uint) {

        uint bidAmount = msg.value;
        uint256 promissorytokenLastPrice = PromissoryTokenIns.lastPrice();


        if(bidAmount > ceiling - totalReceived) {
            bidAmount = ceiling - totalReceived;
        }

        require( bid(_receiver) == bidAmount );

		uint amount = msg.value;
		bidder memory _bidder;
		_bidder.addr = _receiver;
		_bidder.amount = amount;
        SuperDAOTokens[msg.sender] += amount/promissorytokenLastPrice;
		CurrentBidders.push(_bidder);
        checksoftCAP();

        emit BidEvent(_hash, msg.sender, amount);

        if (_hash == MarketingPartners[_hash].hash) {

            MarketingPartners[_hash].totalReferrals += ONE;
            MarketingPartners[_hash].totalContribution += amount;
            MarketingPartners[_hash].individualContribution.push(amount);
            MarketingPartners[_hash].EthEarned += referalPercentage(amount, MarketingPartners[_hash].percentage);

            totalEthEarnedByPartners += referalPercentage(amount, MarketingPartners[_hash].percentage);

            if( (msg.value >= 1 ether) && (msg.value <= 3 ether) && (bidderBonus == true)) {
             if(bonusChecker(oneHundred, thirty) == false){
                    discontinueBonus(oneHundred, thirty);
                    return;
                    }
              TokenReferrals[_hash].totalReferrals += ONE;
              orderTop20(TokenReferrals[_hash].totalReferrals, _hash);
              TokenReferrals[_hash].tokenAmountPerReferred[amount] = oneHundred;
              TokenReferrals[_hash].totalTokensEarned += oneHundred;
              bidderEarnings (thirty) == true ? claimedTokenReferral = oneHundred + thirty : claimedTokenReferral += oneHundred;
              emit TokenReferral(_hash ,msg.sender, amount);


              } else if ((msg.value > 3 ether)&&(msg.value <= 6 ether) && (bidderBonus == true)) {
                   if(bonusChecker(fiveHundred, twoHundred) == false){
                    discontinueBonus(fiveHundred, twoHundred);
                    return;
                    }
                  TokenReferrals[_hash].totalReferrals += ONE;
                  orderTop20(TokenReferrals[_hash].totalReferrals, _hash);
                  TokenReferrals[_hash].tokenAmountPerReferred[amount] = fiveHundred;
                  TokenReferrals[_hash].totalTokensEarned += fiveHundred;
                  bidderEarnings (twoHundred) == true ? claimedTokenReferral = fiveHundred + twoHundred : claimedTokenReferral += fiveHundred;
                  emit TokenReferral(_hash ,msg.sender, amount);


                  } else if ((msg.value > 6 ether) && (bidderBonus == true)) {
                    if(bonusChecker(oneThousand, sixHundred) == false){
                    discontinueBonus(oneThousand, sixHundred);
                    return;
                    }
                    TokenReferrals[_hash].totalReferrals += ONE;
                    orderTop20(TokenReferrals[_hash].totalReferrals, _hash);
                    TokenReferrals[_hash].tokenAmountPerReferred[amount] = oneThousand;
                    TokenReferrals[_hash].totalTokensEarned += oneThousand;
                    bidderEarnings (sixHundred) == true ? claimedTokenReferral = oneThousand + sixHundred : claimedTokenReferral += oneThousand;
                    emit TokenReferral(_hash, msg.sender, amount);

                  }

            emit PartnerReferral(_hash, MarketingPartners[_hash].addr, amount);

            return Partners;

          } else if (_hash == TokenReferrals[_hash].hash){

        			if( (msg.value >= 1 ether) && (msg.value <= 3 ether) && (bidderBonus == true) ) {
        			    if(bonusChecker(oneHundred, thirty) == false){
                            discontinueBonus(oneHundred, thirty);
                                return;
                            }
                            TokenReferrals[_hash].totalReferrals += ONE;
                            orderTop20(TokenReferrals[_hash].totalReferrals, _hash);
            				TokenReferrals[_hash].tokenAmountPerReferred[amount] = oneHundred;
            				TokenReferrals[_hash].totalTokensEarned += oneHundred;
                            bidderEarnings (thirty) == true ? claimedTokenReferral = oneHundred + thirty : claimedTokenReferral += oneHundred;
            				emit TokenReferral(_hash ,msg.sender, amount);
            				return Referrals;

        				} else if ((msg.value > 3 ether)&&(msg.value <= 6 ether) && (bidderBonus == true)) {
        				    if(bonusChecker(fiveHundred, twoHundred) == false){
                                discontinueBonus(fiveHundred, twoHundred);
                                return;
                                }
                                TokenReferrals[_hash].totalReferrals += ONE;
                                orderTop20(TokenReferrals[_hash].totalReferrals, _hash);
        						TokenReferrals[_hash].tokenAmountPerReferred[amount] = fiveHundred;
        						TokenReferrals[_hash].totalTokensEarned += fiveHundred;
                                bidderEarnings (twoHundred) == true ? claimedTokenReferral = fiveHundred + twoHundred : claimedTokenReferral += fiveHundred;
        						emit TokenReferral(_hash ,msg.sender, amount);
        						return Referrals;

        						} else if ((msg.value > 6 ether) && (bidderBonus == true)) {
        						    if(bonusChecker(oneThousand, sixHundred) == false){
                                     discontinueBonus(oneThousand, sixHundred);
                                     return;
                                    }
                                    TokenReferrals[_hash].totalReferrals += ONE;
                                    orderTop20(TokenReferrals[_hash].totalReferrals, _hash);
        							TokenReferrals[_hash].tokenAmountPerReferred[amount] = oneThousand;
        							TokenReferrals[_hash].totalTokensEarned += oneThousand;
        							bidderEarnings (sixHundred) == true ? claimedTokenReferral = oneThousand + sixHundred : claimedTokenReferral += oneThousand;
        							emit TokenReferral(_hash, msg.sender, amount);
        							return Referrals;
        						}
                        }
    
    }


	function referalPercentage(uint _amount, uint _percent)
	    internal
	    pure
	    returns (uint) {
            return SafeMath.mul( SafeMath.div( SafeMath.sub(_amount, _amount%100), 100 ), _percent );
	}


    function claimtokenBonus () public returns(bool success)  {

        bytes4 _personalHash = bytes4(keccak256(abi.encodePacked(msg.sender)));
        
        if ((_personalHash == TokenReferrals[_personalHash].hash) 
                && (TokenReferrals[_personalHash].totalTokensEarned > 0)) {

            uint TokensToTransfer1 = TokenReferrals[_personalHash].totalTokensEarned;
            TokenReferrals[_personalHash].totalTokensEarned = 0;
            KittieFightToken.transfer(TokenReferrals[_personalHash].addr , TokensToTransfer1);
            emit ClaimtokenBonus(_personalHash, msg.sender, true);
         
            return true;

        } else {

            return false;
       }
    }


    function claimCampaignTokenBonus(bytes4 _campaignHash) public returns(bool success)  {
        
        bytes4 _marketingCampaignHash = bytes4(keccak256(abi.encodePacked(msg.sender, owner)));

        if ((_marketingCampaignHash == TokenReferrals[_campaignHash].hash) 
                && (TokenReferrals[_campaignHash].totalTokensEarned > 0)) {

            uint TokensToTransfer1 = TokenReferrals[_campaignHash].totalTokensEarned;
            TokenReferrals[_campaignHash].totalTokensEarned = 0;
            KittieFightToken.transfer(TokenReferrals[_campaignHash].addr , TokensToTransfer1);
            emit ClaimtokenBonus(_campaignHash, msg.sender, true);
         
            return true;

        } else {

            return false;
       }
    }
    

     
    function transferUnsoldTokens(uint _unsoldTokens, address _addr)
        public
        isOwner

     {

        uint soldTokens = totalReceived * 10**18 / finalPrice;
        uint totalSold = (MAX_TOKENS_SOLD + claimedTokenReferral)  - soldTokens;

        require (_unsoldTokens < totalSold );
        KittieFightToken.transfer(_addr, _unsoldTokens);
    }


    function tokenAmountPerReferred(bytes4 _hash, uint _amount ) public view returns(uint tokenAmount) {
        tokenAmount = TokenReferrals[_hash].tokenAmountPerReferred[_amount];
    }

    function getCurrentBiddersCount () public view returns(uint biddersCount)  {
        biddersCount = CurrentBidders.length;
    }

     
    function calculatPersonalHash() public view returns (bytes4 _hash) {
        _hash = bytes4(keccak256(abi.encodePacked(msg.sender)));
    }

    function calculatPersonalHashByAddress(address _addr) public view returns (bytes4 _hash) {
        _hash = bytes4(keccak256(abi.encodePacked(_addr)));
    }

    function calculateCampaignHash(address _addr) public view returns (bytes4 _hash) {
        _hash = bytes4(keccak256(abi.encodePacked(_addr, msg.sender)));
    }

     
     
    function orderTop20(uint _value, bytes4 _hash) private {
        uint i = 0;
         
        for(i; i < topReferredNum.length; i++) {
            if(topReferredNum[i] < _value) {
                break;
            }
        }

        if(i < topReferredNum.length)
        {
            if(topAddrHashes[i]!=_hash)
            {
                 
                for(uint j = topReferredNum.length - 1; j > i; j--) {
                    (topReferredNum[j], topAddrHashes[j] ) = (topReferredNum[j - 1],topAddrHashes[j - 1]);
                }

            
            }
             
            (topReferredNum[i], topAddrHashes[i]) = (_value, _hash);
            emit topAddrHashesUpdate (topAddrHashes);
            emit topNumbersUpdate(topReferredNum);
        }



    }

     
    function getTop20Reffered() public view returns (uint [20]){
      return topReferredNum;
    }

     
    function getTop20Addr() public view returns (bytes4 [20]){
        return topAddrHashes;
     }

     
    function getAddress (bytes4 _hash) public view returns (address){
        return TokenReferrals[_hash].addr;
    }

     
     
     
    function bidderEarnings (uint _amountEarned) private returns (bool){

        bytes4 bidderTemphash = calculatPersonalHash();

        if ( bidderTemphash == TokenReferrals[bidderTemphash].hash){
            TokenReferrals[bidderTemphash].totalTokensEarned += _amountEarned;
            return true;
        }else{
            bytes4 newBidderHash = InternalReferalSignup(msg.sender);
            TokenReferrals[newBidderHash].totalTokensEarned = _amountEarned;
            return true;
        }
        return false;
    }

      
      
     function bonusChecker(uint _tokenRefferralBonus, uint _bidderBonusAmount) public view returns (bool){
      return _tokenRefferralBonus + _bidderBonusAmount + claimedTokenReferral <= MAX_TOKEN_REFERRAL ? true : false;
    }

     
     
    function discontinueBonus(uint _tokenRefferralBonus, uint _bidderBonusAmount) private returns (string) {
        residualToken = MAX_TOKEN_REFERRAL - (_tokenRefferralBonus + _bidderBonusAmount + claimedTokenReferral);
        return setBonustoFalse();
    }


     
     
     
    function setBonustoFalse() private returns (string) {
        require (bidderBonus == true,"no more bonuses");
        bidderBonus = false;
        return "tokens exhausted";
    }

}