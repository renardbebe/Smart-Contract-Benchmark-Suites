 

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


contract KyberProxy {
    address public kyberNetworkContract;
}


contract CheckReserveSplit {
    
    ERC20 constant ETH = ERC20(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
    KyberNetworkIf public constant kyber = KyberNetworkIf(0x9ae49C0d7F8F9EF4B864e004FE86Ac8294E20950);
    ERC20 public constant dai = ERC20(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
    ERC20 public constant usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    uint constant minSplitValueEthDAI = 30;
    uint constant maxSplitValueEthDAI = 140;
    uint constant minSplitValueEthUsdc = 10;
    uint constant maxSplitValueEthUsdc = 70;
    
    uint numSplitRateCalls = 4;
    
    mapping(address=>address[]) public reservesPerTokenDest; 
    mapping(address=>address[]) public reservesPerTokenDestBest; 

    constructor () public {
    }
    
    function setNumSplitRateCalls (uint num) public {
        
        numSplitRateCalls = num;
    }
    
    function copyReserves(ERC20 token) public {
    
        KyberReserveIf reserve;
        uint index = 0;
        
         
        while (true) {   
            
            reserve = KyberReserveIf(getReserveTokenDest(address(token), index++));
            if (reserve == KyberReserveIf(address(0x0))) break;
            reservesPerTokenDest[address(token)].push(address(reserve));
        }
    }
    
    function copyBestReserves(ERC20 token, uint[] memory reserveIds) public {
        
        for (uint i = 0; i < reserveIds.length; i++) {
            reservesPerTokenDestBest[address(token)].push(reservesPerTokenDest[address(token)][reserveIds[i]]);
        }        
    }

    function getBestReservesEthToToken(ERC20 token) public view 
        returns(KyberReserveIf best, KyberReserveIf second, uint bestRate, uint secondRate, uint index) 
    {
        
        KyberReserveIf reserve;
        uint rate;
        index = 0;
        
         
        for(uint i = 0; i < reservesPerTokenDestBest[address(token)].length; i++) {
        
            reserve = KyberReserveIf(reservesPerTokenDestBest[address(token)][i]);
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
    
    function getReserveTokenDest (address token, uint index) internal view returns (address reserve) {

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
    
     
    function getSplitThreshold(ERC20 token) public view 
        returns(uint splitThresholdEth, KyberReserveIf best, KyberReserveIf second) 
    {
        uint[] memory rates = new uint[](3);
        
        (best, second, rates[0], rates[1], )  = getBestReservesEthToToken(token);
        
        (uint stepSizeWei, uint splitValueEthWei) = getBasicStepSizes(token);
        
        uint numSplitCalls = numSplitRateCalls;

        while (numSplitCalls-- > 0) {
            rates[2] = best.getConversionRate(ETH, token, splitValueEthWei, block.number);
            
            stepSizeWei /= 2;
            splitValueEthWei += rates[2] < rates[1] ? (- stepSizeWei) : stepSizeWei;
        }
        
        if(rates[2] == 0) {
            splitValueEthWei -= (stepSizeWei * 2);

            rates[2] = best.getConversionRate(ETH, token, splitValueEthWei, block.number);
        }
        
        splitThresholdEth = splitValueEthWei / 10 ** 18;
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
        (splitThresholdEth, , ) = getSplitThreshold(dai);
    }
   
    function getDaiSplitValues() public view 
        returns (KyberReserveIf bestReserve, uint bestRate, KyberReserveIf secondBest, uint secondRate, uint splitThresholdEth, uint rateBestAfterSplitValue) 
    {
        (splitThresholdEth, bestReserve, secondBest) = getSplitThreshold(dai);
        bestRate = bestReserve.getConversionRate(ETH, dai, 1 ether, block.number);
        secondRate = secondBest.getConversionRate(ETH, dai, 1 ether, block.number);
        rateBestAfterSplitValue = bestReserve.getConversionRate(ETH, dai, (splitThresholdEth + 1) * 10 ** 18, block.number);
    }
    
    function getUsdcSplitThreshold() public view returns (uint splitThresholdEth) {
        (splitThresholdEth, , ) = getSplitThreshold(usdc);
    }
    
    function getUsdcSplitValues() public view 
        returns (KyberReserveIf bestReserve, uint rate1, KyberReserveIf secondBest, uint rate2, uint splitThresholdEth, uint rateBestAfterSplitValue) 
    {
        (splitThresholdEth, bestReserve, secondBest) = getSplitThreshold(usdc);
        rate1 = bestReserve.getConversionRate(ETH, usdc, 1 ether, block.number);
        rate2 = secondBest.getConversionRate(ETH, usdc, 1 ether, block.number);
        rateBestAfterSplitValue = bestReserve.getConversionRate(ETH, usdc, (splitThresholdEth + 1) *10 ** 18, block.number);
    }
    
    function compareSplitTrade(ERC20 token, uint tradeValueEth) public view 
        returns(uint rateSingleReserve, uint rateTwoReserves, uint daiAmountSingleReserve, uint daiAmountTwoRes) 
    {
        KyberReserveIf reserveBest;
        KyberReserveIf reseve2nd;
        uint splitThresholdEth;
        uint[] memory rates = new uint[](2);
        
        (splitThresholdEth, reserveBest, reseve2nd) = getSplitThreshold(token);
        if (splitThresholdEth > tradeValueEth) return (0, 0, splitThresholdEth, 0);
        if (splitThresholdEth < tradeValueEth * 2 / 3) {
            splitThresholdEth = tradeValueEth * 2 / 3;
        }
        
        rateSingleReserve = reserveBest.getConversionRate(ETH, token, tradeValueEth * 10 ** 18, block.number);
        rates[0] = reserveBest.getConversionRate(ETH, token, splitThresholdEth * 10 ** 18, block.number);
        rates[1] = reseve2nd.getConversionRate(ETH, token, (tradeValueEth - splitThresholdEth) * 10 ** 18, block.number);
        rateTwoReserves = (rates[0] * splitThresholdEth + rates[1] * (tradeValueEth - splitThresholdEth)) / tradeValueEth;
        
        daiAmountSingleReserve = (rateSingleReserve / 10 ** 18) * tradeValueEth;
        daiAmountTwoRes = (rateTwoReserves / 10 ** 18) * tradeValueEth;
    }
    
    function getDaiSplitThresholdGas() public returns (uint splitThresholdEth) {
        return getDaiSplitThreshold();
    }
    
    function viewSplitTradeEthToDai(uint tradeValueEth)
        public view 
        returns(uint rateSingleRes, uint rateTwoReserves, uint daiReceivedSingle, uint daiReceivedTwo) 
    {
        return compareSplitTrade(dai, tradeValueEth);
    }
    
    function viewSplitTradeEthToUsdc(uint tradeValueEth)
        public view 
        returns(uint rateSingleRes, uint rateTwoReserves, uint daiReceivedSingle, uint daiReceivedTwo) 
    {
        return compareSplitTrade(usdc, tradeValueEth);
    }
    
    function getAllReserves (ERC20 token) public view returns (KyberReserveIf [] memory reserves, uint [] memory rates) {
        
        reserves = new KyberReserveIf[](reservesPerTokenDest[address(token)].length);
        rates = new uint[](reservesPerTokenDest[address(token)].length);
        
         
        for(uint i = 0; i < reservesPerTokenDest[address(token)].length; i++) {
        
            reserves[i] = KyberReserveIf(reservesPerTokenDest[address(token)][i]);
            rates[i] = reserves[i].getConversionRate(ETH, token, 1 ether, block.number);
        }
    }
}