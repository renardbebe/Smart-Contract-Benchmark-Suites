 

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
        
        uint public numSplitRateIteration = 11;
        
        mapping(address=>address[]) reservesPerTokenDest; 
    
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
    
        function getBestReservesEthToToken(ERC20 token, uint tradeSizeEth) internal view 
            returns(KyberReserveIf best, KyberReserveIf second, uint bestRate, uint secondRate, uint index) 
        {
            KyberReserveIf reserve;
            uint rate;
            index = 0;
         
            uint querySizeEth;
            
            if (tradeSizeEth < 50) {
                querySizeEth = tradeSizeEth;
            } else {
                querySizeEth = tradeSizeEth * 55 / 100;
            }
            
             
            for(index = 0; index < reservesPerTokenDest[address(token)].length; index++) {
            
                reserve = KyberReserveIf(reservesPerTokenDest[address(token)][index]);
                if (reserve == KyberReserveIf(address(0x0))) continue;
                rate = reserve.getConversionRate(ETH, token, querySizeEth * 10 ** 18, block.number);
                
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
            
            secondRate = second.getConversionRate(ETH, token, (tradeSizeEth - querySizeEth) * 10 ** 18, block.number);
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
    
        function getBestEthToDaiReserves100Eth() public view 
            returns(KyberReserveIf best, KyberReserveIf second, uint bestRate, uint secondRate, uint index) 
        {
            return getBestReservesEthToToken(dai, 100);
        }
        
        function getBestEthToUsdcReserves100Eth() public view 
            returns(KyberReserveIf best, KyberReserveIf second, uint bestRate, uint secondRate, uint index) 
        {
            return getBestReservesEthToToken(usdc, 100);
        }
        
        function getSplitValueEthToToken(ERC20 token, uint tradeSizeEth) internal view 
            returns(uint splitValueEth, KyberReserveIf best, KyberReserveIf second) 
        {
            uint numSplitCalls = numSplitRateIteration;
            
            (best, second, , , ) = getBestReservesEthToToken(token, tradeSizeEth);
             
             
            uint stepSizeWei = (tradeSizeEth * 10 ** 18) / 4;
             
            uint splitValueWei = (tradeSizeEth * 10 ** 18) / 2;
            (uint lastSplitRate, , ) = calcCombinedRate(token, best, second, splitValueWei, (tradeSizeEth * 10 ** 18));
            uint newSplitRate;
        
            while (numSplitCalls-- > 0) {
                (newSplitRate, , ) = calcCombinedRate(token, best, second, (splitValueWei + stepSizeWei), (tradeSizeEth * 10 ** 18));
                
                if (newSplitRate > lastSplitRate) {
                    lastSplitRate = newSplitRate;
                    splitValueWei += stepSizeWei;
                }
                stepSizeWei /= 2;
            }
            
            splitValueEth = splitValueWei / 10 ** 18;
         }
        
        function compareSplitTrade(ERC20 token, uint tradeValueEth) internal view 
            returns(uint rateSingleReserve, uint rateTwoReserves, uint amountSingleReserve, uint amountTwoRes, uint splitValueEth, 
                KyberReserveIf best, KyberReserveIf second, uint rate1OnSplit, uint rate2OnSplit) 
        {
            (splitValueEth, best, second) = getSplitValueEthToToken(token, tradeValueEth);
            
            rateSingleReserve = best.getConversionRate(ETH, token, tradeValueEth * 10 ** 18, block.number);
            (rateTwoReserves, rate1OnSplit, rate2OnSplit) = 
                calcCombinedRate(token, best, second, splitValueEth * 10 ** 18, tradeValueEth * 10 ** 18);
            
            amountSingleReserve = rateSingleReserve * tradeValueEth / 10 ** 18;
            amountTwoRes = rateTwoReserves * tradeValueEth / 10 ** 18;
        }
        
        function getDaiSplitTradeGas() public 
            returns(uint rateSingleReserve, uint rateTwoReserves, uint amountSingleReserve, uint amountTwoRes, uint splitValueEth, 
                KyberReserveIf best, KyberReserveIf second, uint rate1OnSplit, uint rate2OnSplit) 
        {
            return viewSplitTradeEthToDai(120);
        }
        
        function viewSplitTradeEthToDai(uint tradeValueEth) public view 
            returns(uint rateSingleReserve, uint rateTwoReserves, uint amountSingleReserve, uint amountTwoRes, uint splitValueEth, 
                KyberReserveIf best, KyberReserveIf second, uint rate1OnSplit, uint rate2OnSplit) 
        {
            return compareSplitTrade(dai, tradeValueEth);
        }
        
        function viewSplitTradeEthToUsdc(uint tradeValueEth) public view 
            returns(uint rateSingleReserve, uint rateTwoReserves, uint amountSingleReserve, uint amountTwoRes, uint splitValueEth, 
                KyberReserveIf best, KyberReserveIf second, uint rate1OnSplit, uint rate2OnSplit) 
        {
            return compareSplitTrade(usdc, tradeValueEth);
        }
        
        function calcCombinedRate(ERC20 token, KyberReserveIf best, KyberReserveIf second, uint splitValueWei, uint tradeValueWei)
            internal view returns(uint combinedRate, uint rate1OnSplit, uint rate2OnSplit)
        {
            rate1OnSplit = best.getConversionRate(ETH, token, splitValueWei, block.number);
            rate2OnSplit = second.getConversionRate(ETH, token, (tradeValueWei - splitValueWei), block.number);
            combinedRate = (rate1OnSplit * splitValueWei + rate2OnSplit * (tradeValueWei - splitValueWei)) / tradeValueWei;
        }
    }