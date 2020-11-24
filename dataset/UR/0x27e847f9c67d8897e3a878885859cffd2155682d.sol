 

pragma solidity ^0.5.11;


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


interface KyberReserveIf {
    function getConversionRate(ERC20 src, ERC20 dest, uint srcQty, uint blockNumber) external view returns(uint);
}


contract KyberNetworkIf { 
    mapping(address=>address[]) public reservesPerTokenSrc;  
    mapping(address=>address[]) public reservesPerTokenDest; 
}


contract CheckReserveSplit {
    
    ERC20 constant ETH = ERC20(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
    KyberNetworkIf constant kyber = KyberNetworkIf(0x9ae49C0d7F8F9EF4B864e004FE86Ac8294E20950);
    ERC20 constant dai = ERC20(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
    ERC20 constant usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    uint constant minSplitValueEthDAI = 30;
    uint constant maxSplitValueEthDAI = 140;
    uint constant minSplitValueEthUsdc = 10;
    uint constant maxSplitValueEthUsdc = 70;
    
    uint public numSplitRateIteration = 7;
    
    mapping(address=>address[]) public reservesPerTokenDest; 

    constructor () public {
    }
    
    function setNumSplitRateCalls (uint num) public {
        numSplitRateIteration = num;
    }
    
    function copyReserves(ERC20 token) public {
        
        KyberReserveIf reserve;
        uint index;
        
        while(true) {
            reserve = KyberReserveIf(getReserveTokenDest(address(token), index));
            if (reserve == KyberReserveIf(address(0x0))) break;
            reservesPerTokenDest[address(token)].push(address(reserve));
            index++;
        }        
    }

     
        
     
        
     
     
     
     
     
     

    function getBestReservesEthToToken(ERC20 token) internal view 
        returns(KyberReserveIf best, KyberReserveIf second, uint bestRate, uint secondRate, uint index) 
    {
        
        KyberReserveIf reserve;
        uint rate;
        index = 0;
        
         
        for(uint i = 0; i < reservesPerTokenDest[address(token)].length; i++) {
        
            reserve = KyberReserveIf(reservesPerTokenDest[address(token)][i]);
            if (reserve == KyberReserveIf(address(0x0))) break;
            rate = reserve.getConversionRate(ETH, token, 1 ether, block.number);
            
            if(rate > bestRate) {
                
                if (bestRate > secondRate) {
                    secondRate = bestRate;
                    second = best;
                }
                
                bestRate = rate;
                best = reserve;
            } else if (rate > secondRate) {
                secondRate = rate;
                second = reserve;
            }
        }
    }

    function getReserveTokenDest (address token, uint index) 
        internal view returns (address reserve) 
    {

        (bool success, bytes memory returnData) = 
            address(kyber).staticcall(
                abi.encodePacked(  
                        kyber.reservesPerTokenDest.selector, 
                        abi.encode(token, index) 
                    )
                );
        
        if (success) {
            reserve = abi.decode(returnData, (address));
        } else {  
            reserve = address(0x0);
        }
    }

    function getBestEthToDaiReserves() public view 
        returns(KyberReserveIf best, KyberReserveIf second, uint bestRate, uint secondRate, uint index) 
    {
        return getBestReservesEthToToken(dai);
    }
    
    function getBestEthToUsdcReserves() public view 
        returns(KyberReserveIf best, KyberReserveIf second, uint bestRate, uint secondRate, uint index) 
    {
        return getBestReservesEthToToken(usdc);
    }
    
     
    function getSplitThresholdEthToToken(ERC20 token) internal view 
        returns(uint splitThresholdEth, KyberReserveIf best, KyberReserveIf second, uint rateBest, uint rate2nd) 
    {
        uint rate;
        
        (best, second, rateBest, rate2nd, )  = getBestReservesEthToToken(token);
        
        (uint stepSizeWei, uint splitThresholdEthWei) = getBasicStepSizes(token);
        
        uint numSplitCalls = numSplitRateIteration;

        while (numSplitCalls-- > 0) {
            rate = best.getConversionRate(ETH, token, splitThresholdEthWei, block.number);
            
            stepSizeWei /= 2;
            splitThresholdEthWei += rate < rate2nd ? (- stepSizeWei) : stepSizeWei;
        }
        
        if(rate == 0) {
            splitThresholdEthWei -= (stepSizeWei * 2);

            rate = best.getConversionRate(ETH, token, splitThresholdEthWei, block.number);
        }
        
        splitThresholdEth = splitThresholdEthWei / 10 ** 18;
    }
    
    function getSplitValueEthToToken(ERC20 token, uint tradeSizeEth) internal view 
        returns(uint splitValueEth, uint splitThresholdEth, KyberReserveIf best, KyberReserveIf second) 
    {
        
        (splitThresholdEth, best, second, , )  = getSplitThresholdEthToToken(token);
        
        if (tradeSizeEth < splitThresholdEth) return (0, splitThresholdEth, best, second);
        uint refRate = calcCombinedRate(token, best, second, splitThresholdEth, tradeSizeEth);
        
        uint stepSizeEth = (tradeSizeEth - splitThresholdEth) / 2;
        
        uint numSplitCalls = numSplitRateIteration;
        uint newRate;
        
        uint prevSplitValue = splitThresholdEth;
        splitValueEth = splitThresholdEth + stepSizeEth;

        while (numSplitCalls-- > 0) {
            newRate = calcCombinedRate(token, best, second, splitValueEth, tradeSizeEth);
        
            stepSizeEth /= 2;
            bool isCurrentSplitBigger = splitValueEth > prevSplitValue ? true : false;
            prevSplitValue = splitValueEth;
            
            if (newRate > refRate) {
                refRate = newRate;
                 
                splitValueEth += isCurrentSplitBigger ? stepSizeEth : (-stepSizeEth);
            } else {
                splitValueEth += isCurrentSplitBigger  ? (-stepSizeEth) : stepSizeEth;
            }
        }
    }
    
    function getBasicStepSizes (ERC20 token) internal pure returns(uint stepSizeWei, uint splitValueEthWei) {
        if(token == usdc) {
            stepSizeWei = (maxSplitValueEthUsdc - minSplitValueEthUsdc) * 10 ** 18 / 2;
            splitValueEthWei = minSplitValueEthUsdc * 10 ** 18 + stepSizeWei;
        } else {
            stepSizeWei = (maxSplitValueEthDAI - minSplitValueEthDAI) * 10 ** 18 / 2;
            splitValueEthWei = minSplitValueEthDAI * 10 ** 18 + stepSizeWei;            
        }
    }

    function getDaiSplitThreshold() public view returns (uint splitThresholdEth) {
        (splitThresholdEth, , , ,) = getSplitThresholdEthToToken(dai);
    }
   
    function getDaiSplitValues(uint tradeSizeEth) public view 
        returns (KyberReserveIf bestReserve, uint bestRate, KyberReserveIf secondBest, uint secondRate, uint splitThresholdEth, uint splitValueEth, uint rateBestAfterSplitValue) 
    {
        (splitValueEth, splitThresholdEth, bestReserve, secondBest) = getSplitValueEthToToken(dai, tradeSizeEth);
        bestRate = bestReserve.getConversionRate(ETH, dai, 1 ether, block.number);
        secondRate = secondBest.getConversionRate(ETH, dai, 1 ether, block.number);
        rateBestAfterSplitValue = bestReserve.getConversionRate(ETH, dai, (splitValueEth + 1) * 10 ** 18, block.number);
    }
    
    function getUsdcSplitThreshold() public view returns (uint splitThresholdEth) {
        (splitThresholdEth, , , ,) = getSplitThresholdEthToToken(usdc);
    }
    
    function getUsdcSplitValues(uint tradeSizeEth) public view 
        returns (KyberReserveIf bestReserve, uint rate1, KyberReserveIf secondBest, uint rate2, uint splitThresholdEth, uint splitValueEth, uint rateBestAfterSplitValue) 
    {
        (splitValueEth, splitThresholdEth, bestReserve, secondBest) = getSplitValueEthToToken(usdc, tradeSizeEth);
        rate1 = bestReserve.getConversionRate(ETH, usdc, 1 ether, block.number);
        rate2 = secondBest.getConversionRate(ETH, usdc, 1 ether, block.number);
        rateBestAfterSplitValue = bestReserve.getConversionRate(ETH, usdc, (splitValueEth + 1) *10 ** 18, block.number);
    }
    
    function compareSplitTrade(ERC20 token, uint tradeValueEth) internal view 
        returns(uint rateSingleReserve, uint rateTwoReserves, uint amountSingleReserve, uint amountTwoRes, uint splitValueEth, uint splitThresholdEth) 
    {
        KyberReserveIf reserveBest;
        KyberReserveIf reseve2nd;
        
        (splitValueEth, splitThresholdEth, reserveBest, reseve2nd) = getSplitValueEthToToken(token, tradeValueEth);
        if (splitValueEth > tradeValueEth) return(0, 0, 0, 0, splitValueEth, splitThresholdEth);
        
        rateSingleReserve = reserveBest.getConversionRate(ETH, token, splitValueEth * 10 ** 18, block.number);
        rateTwoReserves = calcCombinedRate(token, reserveBest, reseve2nd, splitValueEth, tradeValueEth);
        
        amountSingleReserve = (rateSingleReserve / 10 ** 18) * tradeValueEth;
        amountTwoRes = (rateTwoReserves / 10 ** 18) * tradeValueEth;
    }
    
    function getDaiSplitValueGas() public 
        returns (KyberReserveIf bestReserve, uint bestRate, KyberReserveIf secondBest, uint secondRate, uint splitThresholdEth, uint splitValueEth, uint rateBestAfterSplitValue) 
    {
        return getDaiSplitValues(120);
    }
    
    function viewSplitTradeEthToDai(uint tradeValueEth)
        public view 
        returns(uint rateSingleReserve, uint rateTwoReserves, uint amountSingleReserve, uint amountTwoRes, uint splitValueEth, uint splitThresholdEth) 
    {
        return compareSplitTrade(dai, tradeValueEth);
    }
    
    function viewSplitTradeEthToUsdc(uint tradeValueEth)
        public view 
        returns(uint rateSingleReserve, uint rateTwoReserves, uint amountSingleReserve, uint amountTwoRes, uint splitValueEth, uint splitThresholdEth) 
    {
        return compareSplitTrade(usdc, tradeValueEth);
    }
    
    function calcCombinedRate(ERC20 token, KyberReserveIf best, KyberReserveIf second, uint splitValueEth, uint tradeValueEth)
        internal view returns(uint rate)
    {
        uint rate1 = best.getConversionRate(ETH, token, splitValueEth * 10 ** 18, block.number);
        uint rate2 = second.getConversionRate(ETH, token, (tradeValueEth - splitValueEth) * 10 ** 18, block.number);
        rate = (rate1 * splitValueEth + rate2 * (tradeValueEth - splitValueEth)) / tradeValueEth;
    }
    
     
        
     
     
        
     
     
     
     
     
 
     
     
        
     
     
     
     
     
     
}