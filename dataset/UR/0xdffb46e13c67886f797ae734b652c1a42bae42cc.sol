 

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
    
        function getres1ReservesEthToToken(ERC20 token, uint tradeSizeEth) internal view 
            returns(KyberReserveIf res1, KyberReserveIf res2, uint res1Rate, uint res2Rate, uint index) 
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
                
                if(rate > res1Rate) {
                    
                    if (res1Rate > res2Rate) {
                        res2Rate = res1Rate;
                        res2 = res1;
                    }
                    
                    res1Rate = rate;
                    res1 = reserve;
                } else if (rate > res2Rate) {
                    res2Rate = rate;
                    res2 = reserve;
                }
            }
            
            res2Rate = res2.getConversionRate(ETH, token, (tradeSizeEth - querySizeEth) * 10 ** 18, block.number);
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
    
        function getres1EthToDaiReserves100Eth() public view 
            returns(KyberReserveIf res1, KyberReserveIf res2, uint res1Rate, uint res2Rate, uint index) 
        {
            return getres1ReservesEthToToken(dai, 100);
        }
        
        function getres1EthToUsdcReserves100Eth() public view 
            returns(KyberReserveIf res1, KyberReserveIf res2, uint res1Rate, uint res2Rate, uint index) 
        {
            return getres1ReservesEthToToken(usdc, 100);
        }
        
        function getSplitValueEthToToken(ERC20 token, uint tradeSizeEth) internal view 
            returns(uint splitValueEth, KyberReserveIf res1, KyberReserveIf res2) 
        {
            uint numSplitCalls = numSplitRateIteration;
            
            (res1, res2, , , ) = getres1ReservesEthToToken(token, tradeSizeEth);
             
             
            uint stepSizeWei = (tradeSizeEth * 10 ** 18) / 4;
             
            uint splitValueWei = (tradeSizeEth * 10 ** 18) / 2;
            (uint lastSplitRate, , ) = calcCombinedRate(token, res1, res2, splitValueWei, (tradeSizeEth * 10 ** 18));
            uint newSplitRate;
        
            while (numSplitCalls-- > 0) {
                (newSplitRate, , ) = calcCombinedRate(token, res1, res2, (splitValueWei + stepSizeWei), (tradeSizeEth * 10 ** 18));
                
                if (newSplitRate > lastSplitRate) {
                    lastSplitRate = newSplitRate;
                    splitValueWei += stepSizeWei;
                }
                stepSizeWei /= 2;
            }
            
            splitValueEth = splitValueWei / 10 ** 18;
         }
        
        function compareSplitTrade(ERC20 token, uint tradeValueEth) internal view 
            returns(uint rateReserve1, uint rateReserve1and2, uint amountReserve1, uint amountRes1and2, uint splitValueEth, 
                KyberReserveIf res1, KyberReserveIf res2, uint rate1OnSplit, uint rate2OnSplit) 
        {
            (splitValueEth, res1, res2) = getSplitValueEthToToken(token, tradeValueEth);
            
            rateReserve1 = res1.getConversionRate(ETH, token, tradeValueEth * 10 ** 18, block.number);
            (rateReserve1and2, rate1OnSplit, rate2OnSplit) = 
                calcCombinedRate(token, res1, res2, splitValueEth * 10 ** 18, tradeValueEth * 10 ** 18);
            
            amountReserve1 = rateReserve1 * tradeValueEth / 10 ** 18;
            amountRes1and2 = rateReserve1and2 * tradeValueEth / 10 ** 18;
        }
        
        function getDaiSplitTradeGas() public 
            returns(uint rateReserve1, uint rateReserve1and2, uint amountReserve1, uint amountRes1and2, uint splitValueEth, 
                KyberReserveIf res1, KyberReserveIf res2, uint rate1OnSplit, uint rate2OnSplit) 
        {
            return viewSplitTradeEthToDai(120);
        }
        
        function viewSplitTradeEthToDai(uint tradeValueEth) public view 
            returns(uint rateReserve1, uint rateReserve1and2, uint amountReserve1, uint amountRes1and2, uint splitValueEth, 
                KyberReserveIf res1, KyberReserveIf res2, uint rate1OnSplit, uint rate2OnSplit) 
        {
            return compareSplitTrade(dai, tradeValueEth);
        }
        
        function viewSplitTradeEthToUsdc(uint tradeValueEth) public view 
            returns(uint rateReserve1, uint rateReserve1and2, uint amountReserve1, uint amountRes1and2, uint splitValueEth, 
                KyberReserveIf res1, KyberReserveIf res2, uint rate1OnSplit, uint rate2OnSplit) 
        {
            return compareSplitTrade(usdc, tradeValueEth);
        }
        
        function calcCombinedRate(ERC20 token, KyberReserveIf res1, KyberReserveIf res2, uint splitValueWei, uint tradeValueWei)
            internal view returns(uint combinedRate, uint rate1OnSplit, uint rate2OnSplit)
        {
            rate1OnSplit = res1.getConversionRate(ETH, token, splitValueWei, block.number);
            rate2OnSplit = res2.getConversionRate(ETH, token, (tradeValueWei - splitValueWei), block.number);
            combinedRate = (rate1OnSplit * splitValueWei + rate2OnSplit * (tradeValueWei - splitValueWei)) / tradeValueWei;
        }
    }