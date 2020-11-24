 

pragma solidity ^0.5.9;


interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract OtcInterface {
    function getOffer(uint id) external view returns (uint, ERC20, uint, ERC20);
    function getBestOffer(ERC20 sellGem, ERC20 buyGem) external view returns(uint);
    function getWorseOffer(uint id) external view returns(uint);
    function take(bytes32 id, uint128 maxTakeAmount) external;
}


contract WethInterface is ERC20 {
    function deposit() public payable;
    function withdraw(uint) public;
}


contract TradeEth2DAI {
    
    address public admin;
    uint constant INVALID_ID = uint(-1);
    uint constant internal COMMON_DECIMALS = 18;
    OtcInterface public otc = OtcInterface(0x39755357759cE0d7f32dC8dC45414CCa409AE24e);
    WethInterface public wethToken = WethInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ERC20 DAIToken = ERC20(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
    
    constructor() public {
        require(wethToken.decimals() == COMMON_DECIMALS);
    
        admin = msg.sender;

        require(DAIToken.approve(address(otc), 2**255));
        require(wethToken.approve(address(otc), 2**255));
    }

    function() external payable {
        
    }
    
    event TradeExecute(
        address indexed sender,
        bool isEthToDai,
        uint srcAmount,
        uint destAmount,
        address destAddress
    );

    function tradeEthVsDAI(
        uint numTakeOrders,
        uint numTraverseOrders,
        bool isEthToDai,
        uint srcAmount
    )
        public
        payable
    {
        address payable dstAddress = msg.sender;
        uint userTotalDestAmount;
        
        if (isEthToDai) {
            require(msg.value == srcAmount);
            wethToken.deposit.value(msg.value)();
            userTotalDestAmount = takeOrders(wethToken, DAIToken, srcAmount, numTakeOrders, numTraverseOrders);
            require(DAIToken.transfer(dstAddress, userTotalDestAmount));
        } else {
             
            require(DAIToken.transferFrom(msg.sender, address(this), srcAmount));
            userTotalDestAmount = takeOrders(DAIToken, wethToken, srcAmount, numTakeOrders, numTraverseOrders);
            wethToken.withdraw(userTotalDestAmount);    
            dstAddress.transfer(userTotalDestAmount);
        }

        emit TradeExecute(msg.sender, isEthToDai, srcAmount, userTotalDestAmount, dstAddress);
    }

    function getNextOffer(uint prevOfferId, bool isEthToDai) public view
        returns(uint offerId, uint offerPayAmount, uint offerBuyAmount) 
    {
        uint prevId = prevOfferId == 0 ? INVALID_ID : prevOfferId;       
        
        if(isEthToDai) {
             
            return(getNextBestOffer(DAIToken, wethToken, 1, prevId));
        }
        
         
        return(getNextBestOffer(wethToken, DAIToken, 1, prevId));
    }
    
    function takeOrders(ERC20 srcToken, ERC20 dstToken, uint srcAmount, uint numTakeOrders, uint numTraverseOrders) 
        internal 
        returns(uint userTotalDestAmount)
    {
        uint remainingAmount = srcAmount;
        uint destAmount;
        uint offerId = INVALID_ID;
        uint i;
        
        for (i = numTraverseOrders; i > 0; i--) {
            
            (offerId, , ) = getNextBestOffer(dstToken, srcToken, remainingAmount / i, offerId);
            
            require(offerId > 0);
        }
        
        for (i = numTakeOrders; i > 0; i--) {
            
             
            (offerId, , ) = getNextBestOffer(dstToken, srcToken, remainingAmount / i, offerId);
            
            require(offerId > 0);
            
            destAmount = takeMatchingOffer(remainingAmount / i, offerId);
            userTotalDestAmount += destAmount;
            remainingAmount -= (remainingAmount / i);
        }
    }
    
    function getNextBestOffer(
        ERC20 offerSellGem,
        ERC20 offerBuyGem,
        uint payAmount,
        uint prevOfferId
    )
        internal
        view
        returns(
            uint offerId,
            uint offerPayAmount,
            uint offerBuyAmount
        )
    {
        if (prevOfferId == INVALID_ID) {
            offerId = otc.getBestOffer(offerSellGem, offerBuyGem);
        } else {
            offerId = otc.getWorseOffer(prevOfferId);
        }

        (offerPayAmount, , offerBuyAmount, ) = otc.getOffer(offerId);

        while (payAmount > offerBuyAmount) {
            offerId = otc.getWorseOffer(offerId);  
            if (offerId == 0) {
                offerId = 0;
                offerPayAmount = 0;
                offerBuyAmount = 0;
                break;
            }
            (offerPayAmount, , offerBuyAmount, ) = otc.getOffer(offerId);
        }
    }
    
    function takeMatchingOffer(
        uint srcAmount, 
        uint offerId
    )
        internal
        returns(uint actualDestAmount)
    {
        uint offerPayAmt;
        uint offerBuyAmt;

         
        (offerPayAmt, , offerBuyAmt, ) = otc.getOffer(offerId);
        
        actualDestAmount = srcAmount * offerPayAmt / offerBuyAmt;

        require(uint128(actualDestAmount) == actualDestAmount);
        otc.take(bytes32(offerId), uint128(actualDestAmount));   
        return(actualDestAmount);
    }
    
    function getEthToDaiOrders(uint numOrders) public view
        returns(uint [] memory ethPayAmtTokens, uint [] memory daiBuyAmtTokens, uint [] memory rate10KFactor) 
    {
        uint offerId = INVALID_ID;
        ethPayAmtTokens = new uint[](numOrders);
        daiBuyAmtTokens = new uint[](numOrders);    
        rate10KFactor = new uint[](numOrders);
        
        uint offerBuyAmt;
        uint offerPayAmt;
        
        for (uint i = 0; i < numOrders; i++) {
            
            (offerId, offerPayAmt, offerBuyAmt) = getNextBestOffer(DAIToken, wethToken, 1, offerId);
            
            ethPayAmtTokens[i] = offerBuyAmt / 10 ** 18;
            daiBuyAmtTokens[i] = offerPayAmt / 10 ** 18;
            rate10KFactor[i] = offerBuyAmt * 10000 / offerPayAmt;
            
            if(offerId == 0) break;
        }
        
        return(daiBuyAmtTokens, ethPayAmtTokens, rate10KFactor);
    }
    
    function getDaiToEthOrders(uint numOrders) public view
        returns(uint [] memory daiPayAmtTokens, uint [] memory ethBuyAmtTokens, uint [] memory rate10KFactor)
    {
        uint offerId = INVALID_ID;
        daiPayAmtTokens = new uint[](numOrders);
        ethBuyAmtTokens = new uint[](numOrders);
        rate10KFactor = new uint[](numOrders);

        uint offerBuyAmt;
        uint offerPayAmt;

        for (uint i = 0; i < numOrders; i++) {

            (offerId, offerPayAmt, offerBuyAmt) = getNextBestOffer(DAIToken, wethToken, 1, offerId);

            daiPayAmtTokens[i] = offerBuyAmt / 10 ** 18;
            ethBuyAmtTokens[i] = offerPayAmt / 10 ** 18;
            rate10KFactor[i] = offerBuyAmt * 10000 / offerPayAmt;

            if(offerId == 0) break;
        }

        return(ethBuyAmtTokens, daiPayAmtTokens, rate10KFactor);
    }

}