 

pragma solidity ^0.4.19;

library itMaps {
     
    struct entryAddressUint {
     
    uint keyIndex;
    uint value;
    }

    struct itMapAddressUint {
    mapping(address => entryAddressUint) data;
    address[] keys;
    }

    function insert(itMapAddressUint storage self, address key, uint value) internal returns (bool replaced) {
        entryAddressUint storage e = self.data[key];
        e.value = value;
        if (e.keyIndex > 0) {
            return true;
        } else {
            e.keyIndex = ++self.keys.length;
            self.keys[e.keyIndex - 1] = key;
            return false;
        }
    }

    function remove(itMapAddressUint storage self, address key) internal returns (bool success) {
        entryAddressUint storage e = self.data[key];
        if (e.keyIndex == 0)
        return false;

        if (e.keyIndex <= self.keys.length) {
             
            self.data[self.keys[self.keys.length - 1]].keyIndex = e.keyIndex;
            self.keys[e.keyIndex - 1] = self.keys[self.keys.length - 1];
            self.keys.length -= 1;
            delete self.data[key];
            return true;
        }
    }

    function destroy(itMapAddressUint storage self) internal  {
        for (uint i; i<self.keys.length; i++) {
            delete self.data[ self.keys[i]];
        }
        delete self.keys;
        return ;
    }

    function contains(itMapAddressUint storage self, address key) internal constant returns (bool exists) {
        return self.data[key].keyIndex > 0;
    }

    function size(itMapAddressUint storage self) internal constant returns (uint) {
        return self.keys.length;
    }

    function get(itMapAddressUint storage self, address key) internal constant returns (uint) {
        return self.data[key].value;
    }

    function getKeyByIndex(itMapAddressUint storage self, uint idx) internal constant returns (address) {
        return self.keys[idx];
    }

    function getValueByIndex(itMapAddressUint storage self, uint idx) internal constant returns (uint) {
        return self.data[self.keys[idx]].value;
    }
}

contract ERC20 {
    function totalSupply() public constant returns (uint256 supply);
    function balanceOf(address who) public constant returns (uint value);
    function allowance(address owner, address spender) public constant returns (uint _allowance);

    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract TakeMyEther is ERC20{
    using itMaps for itMaps.itMapAddressUint;

    uint private initialSupply = 2800000;
    uint public soldTokens = 0;  
    string public constant name = "TakeMyEther";
    string public constant symbol = "TMEther";
    address public TakeMyEtherTeamAddress;

    itMaps.itMapAddressUint tokenBalances;  
    mapping (address => uint256) weiBalances;  
    mapping (address => uint256) weiBalancesReturned;

    uint public percentsOfProjectComplete = 0;
    uint public lastStageSubmitted;
    uint public lastTimeWithdrawal;

    uint public constant softCapTokensAmount = 500000;
    uint public constant hardCapTokensAmount = 2250000;

    uint public constant lockDownPeriod = 1 weeks;
    uint public constant minimumStageDuration = 2 weeks;

    bool public isICOfinalized = false;
    bool public projectCompleted = false;

    modifier onlyTeam {
        if (msg.sender == TakeMyEtherTeamAddress) {
            _;
        }
    }

    mapping (address => mapping (address => uint256)) allowed;

    event StageSubmitted(uint last);
    event etherPassedToTheTeam(uint weiAmount, uint when);
    event etherWithdrawFromTheContract(address tokenHolder, uint numberOfTokensSoldBack, uint weiValue);
    event Burned(address indexed from, uint amount);
    event DividendsTransfered(address to, uint tokensAmount, uint weiAmount);

     

    function totalSupply() public constant returns (uint256) {
        return initialSupply;
    }

    function balanceOf(address tokenHolder) public view returns (uint256 balance) {
        return tokenBalances.get(tokenHolder);
    }

    function allowance(address owner, address spender) public constant returns (uint256) {
        return allowed[owner][spender];
    }

    function transfer(address to, uint value) public returns (bool success) {
        if (tokenBalances.get(msg.sender) >= value && value > 0) {
            if (to == address(this)) {  
                returnAllAvailableFunds();
                return true;
            }
            else {
                return transferTokensAndEtherValue(msg.sender, to, value, getAverageTokenPrice(msg.sender) * value);
            }
        } else return false;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        if (tokenBalances.get(from)>=value && allowed[from][to] >= value && value > 0) {
            if (transferTokensAndEtherValue(from, to, value, getAverageTokenPrice(from) * value)) {
                allowed[from][to] -= value;
                return true;
            }
            return false;
        }
        return false;
    }

    function approve(address spender, uint value) public returns (bool success) {
        if ((value != 0) && (tokenBalances.get(msg.sender) >= value)){
            allowed[msg.sender][spender] = value;
            emit Approval(msg.sender, spender, value);
            return true;
        } else{
            return false;
        }
    }

     

    function TakeMyEther() public {
        TakeMyEtherTeamAddress = msg.sender;
        tokenBalances.insert(address(this), initialSupply);
        lastStageSubmitted = now;
    }  

    function () public payable {
        require (!projectCompleted);
        uint weiToSpend = msg.value;  
        uint currentPrice = getCurrentSellPrice();  
        uint valueInWei = 0;
        uint valueToPass = 0;

        if (weiToSpend < currentPrice) { 
            return;
        }

        if (!tokenBalances.contains(msg.sender))
        tokenBalances.insert(msg.sender, 0);

        if (soldTokens < softCapTokensAmount) {
            uint valueLeftForSoftCap = softCapTokensAmount - soldTokens;
            valueToPass = weiToSpend / currentPrice;

            if (valueToPass > valueLeftForSoftCap)
            valueToPass = valueLeftForSoftCap;

            valueInWei = valueToPass * currentPrice;
            weiToSpend -= valueInWei;
            soldTokens += valueToPass;
            weiBalances[address(this)] += valueInWei;
            transferTokensAndEtherValue(address(this), msg.sender, valueToPass, valueInWei);
        }

        currentPrice = getCurrentSellPrice();  

        if (weiToSpend < currentPrice) {
            return;
        }

        if (soldTokens < hardCapTokensAmount && soldTokens >= softCapTokensAmount) {
            uint valueLeftForHardCap = hardCapTokensAmount - soldTokens;
            valueToPass = weiToSpend / currentPrice;

            if (valueToPass > valueLeftForHardCap)
            valueToPass = valueLeftForHardCap;

            valueInWei = valueToPass * currentPrice;
            weiToSpend -= valueInWei;
            soldTokens += valueToPass;
            weiBalances[address(this)] += valueInWei;
            transferTokensAndEtherValue(address(this), msg.sender, valueToPass, valueInWei);
        }

        if (weiToSpend / 10**17 > 1) {  
            msg.sender.transfer(weiToSpend);
        }
    }

    function returnAllAvailableFunds() public {
        require (tokenBalances.contains(msg.sender));  
        require (!projectCompleted);  

        uint avPrice = getAverageTokenPrice(msg.sender);
        weiBalances[msg.sender] = getWeiAvailableToReturn(msg.sender);  

        uint amountOfTokensToReturn = weiBalances[msg.sender] / avPrice;

        require (amountOfTokensToReturn>0);

        uint valueInWei = weiBalances[msg.sender];

        transferTokensAndEtherValue(msg.sender, address(this), amountOfTokensToReturn, valueInWei);
        emit etherWithdrawFromTheContract(msg.sender, amountOfTokensToReturn, valueInWei);
        weiBalances[address(this)] -= valueInWei;
        soldTokens -= amountOfTokensToReturn;
        msg.sender.transfer(valueInWei);
    }

     

    function getWeiBalance(address a) public view returns (uint) {
        return weiBalances[a];
    }

    function getWeiAvailableToReturn(address holder) public view returns (uint amount) {
        if (!isICOfinalized) return weiBalances[holder];
        uint percentsBlocked = 0;
        if (percentsOfProjectComplete > 10 && lastStageSubmitted + lockDownPeriod > now)
        percentsBlocked = percentsOfProjectComplete - 10;
        else
        percentsBlocked = percentsOfProjectComplete;
        return ((weiBalances[holder]  / 100) * (100 - percentsOfProjectComplete));
    }

    function getAverageTokenPrice(address holder) public view returns (uint avPriceInWei) {
        return weiBalances[holder] / tokenBalances.get(holder);
    }

    function getNumberOfTokensForTheTeam() public view returns (uint amount) {
        if (soldTokens == softCapTokensAmount) return soldTokens * 4;  
        if (soldTokens == hardCapTokensAmount) return soldTokens/4;  
        uint teamPercents = (80 - ((soldTokens - softCapTokensAmount) / ((hardCapTokensAmount - softCapTokensAmount)/60)));
        return ((soldTokens / (100 - teamPercents)) * teamPercents);  
    }

    function getCurrentSellPrice() public view returns (uint priceInWei) {
        if (!isICOfinalized) {
            if (soldTokens < softCapTokensAmount) return 10**14 * 5 ;  
            else return 10**15;  
        }
        else {  
            if (!projectCompleted)  
            return (1 * 10**15 + 5 * (percentsOfProjectComplete * 10**13)) ;  
            else return 0;  
        }
    }

    function getAvailableFundsForTheTeam() public view returns (uint amount) {
        if (percentsOfProjectComplete == 100) return address(this).balance;  
        return (address(this).balance /(100 - (percentsOfProjectComplete - 10))) * 10;  
         
    }

     

    function finalizeICO() public onlyTeam {
        require(!isICOfinalized);  
        if (soldTokens < hardCapTokensAmount)
        require (lastStageSubmitted + minimumStageDuration < now);  
        require(soldTokens >= softCapTokensAmount);  
        uint tokensToPass = passTokensToTheTeam();  
        burnUndistributedTokens(tokensToPass); 
        lastStageSubmitted = now;
        emit StageSubmitted(lastStageSubmitted);
        increaseProjectCompleteLevel();  
        passFundsToTheTeam();
        isICOfinalized = true;
    }

    function submitNextStage() public onlyTeam returns (bool success) {
        if (lastStageSubmitted + minimumStageDuration > now) return false;  
        lastStageSubmitted = now;
        emit StageSubmitted(lastStageSubmitted);
        increaseProjectCompleteLevel();
        return true;
    }

    function unlockFundsAndPassEther() public onlyTeam returns (bool success) {
        require (lastTimeWithdrawal<=lastStageSubmitted);
        if (lastStageSubmitted + lockDownPeriod > now) return false;  
        if (percentsOfProjectComplete == 100 && !projectCompleted) {
            projectCompleted = true;
            if (tokenBalances.get(address(this))>0) {
                uint toTransferAmount = tokenBalances.get(address(this));
                tokenBalances.insert(TakeMyEtherTeamAddress, tokenBalances.get(address(this)) + tokenBalances.get(TakeMyEtherTeamAddress));
                tokenBalances.insert(address(this), 0);
                emit Transfer(address(this), TakeMyEtherTeamAddress, toTransferAmount);
            }
        }
        passFundsToTheTeam();
        return true;
    }

     

    function topUpWithEtherAndTokensForHolders(address tokensContractAddress, uint tokensAmount) public payable {
        uint weiPerToken = msg.value / initialSupply;
        uint tokensPerToken = 100 * tokensAmount / initialSupply;  
        uint weiAmountForHolder = 0;
        uint tokensForHolder = 0;

        for (uint i = 0; i< tokenBalances.size(); i += 1) {
            address tokenHolder = tokenBalances.getKeyByIndex(i);
            if (tokenBalances.get(tokenHolder)>0) {
                weiAmountForHolder = tokenBalances.get(tokenHolder)*weiPerToken;
                tokensForHolder = tokenBalances.get(tokenHolder) * tokensPerToken / 100;  
                tokenHolder.transfer(weiAmountForHolder);  
                if (tokensContractAddress.call(bytes4(keccak256("authorizedTransfer(address,address,uint256)")), msg.sender, tokenHolder, tokensForHolder))  
                emit DividendsTransfered(tokenHolder, tokensForHolder, weiAmountForHolder);
            }
        }
    }

    function passUndistributedEther() public {
        require (projectCompleted);
        uint weiPerToken = (address(this).balance * 100) / initialSupply;

        for (uint i = 0; i< tokenBalances.size(); i += 1) {
            address tokenHolder = tokenBalances.getKeyByIndex(i);
            if (tokenBalances.get(tokenHolder)>0) {
                uint weiAmountForHolder = (tokenBalances.get(tokenHolder)*weiPerToken)/100;
                tokenHolder.transfer(weiAmountForHolder);  
                emit DividendsTransfered(tokenHolder, 0, weiAmountForHolder);
            }
        }
    }  

     

    function transferTokensAndEtherValue(address from, address to, uint value, uint weiValue) internal returns (bool success){
        if (tokenBalances.contains(from) && tokenBalances.get(from) >= value) {
            tokenBalances.insert(to, tokenBalances.get(to) + value);
            tokenBalances.insert(from, tokenBalances.get(from) - value);

            weiBalances[from] -= weiValue;
            weiBalances[to] += weiValue;

            emit Transfer(from, to, value);
            return true;
        }
        return false;
    }

    function passFundsToTheTeam() internal {
        uint weiAmount = getAvailableFundsForTheTeam();
        TakeMyEtherTeamAddress.transfer(weiAmount);
        emit etherPassedToTheTeam(weiAmount, now);
        lastTimeWithdrawal = now;
    }

    function passTokensToTheTeam() internal returns (uint tokenAmount) {  
        uint tokensToPass = getNumberOfTokensForTheTeam();
        tokenBalances.insert(TakeMyEtherTeamAddress, tokensToPass);
        weiBalances[TakeMyEtherTeamAddress] = 0;  
        emit Transfer(address(this), TakeMyEtherTeamAddress, tokensToPass);
        return tokensToPass;
    }

    function increaseProjectCompleteLevel() internal {
        if (percentsOfProjectComplete<60)
        percentsOfProjectComplete += 10;
        else
        percentsOfProjectComplete = 100;
    }

    function burnUndistributedTokens(uint tokensToPassToTheTeam) internal {
        uint toBurn = initialSupply - (tokensToPassToTheTeam + soldTokens);
        initialSupply -=  toBurn;
        tokenBalances.insert(address(this), 0);
        emit Burned(address(this), toBurn);
    }
}