 

pragma solidity ^0.4.18;

 
contract SafeMath {

     

    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        assert((z >= x));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        return x - y;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }

    function safeDiv(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x / y;
        return z;
    }

     
     
     
    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }

}
 

contract TrakToken {
    function TrakToken () public {}
    function transfer (address ,uint) public pure { }
    function burn (uint256) public pure { }
    function finalize() public pure { }
    function changeTokensWallet (address) public pure { }
}

contract CrowdSale is SafeMath {

     
    enum State { Fundraising,Paused,Successful,Closed }
    State public state = State.Fundraising;  
    string public version = "1.0";

     
    TrakToken public trakToken;
     
    address public creator;
     
    address public contractOwner;
     
    mapping (address => bool) public whitelistedContributors;

    uint256 public fundingStartBlock;  
    uint256 public firstChangeBlock;   
    uint256 public secondChangeBlock;  
    uint256 public thirdChangeBlock;   
    uint256 public fundingEndBlock;    
     
    uint256 public fundingDurationInHours;
    uint256 constant public fundingMaximumTargetInWei = 66685 ether;
     
    uint256 public totalRaisedInWei;
     
    uint256 constant public maxPriceInWeiFromUser = 1500 ether;
    uint256 public minPriceInWeiForPre = 1 ether;
    uint256 public minPriceInWeiForIco = 0.5 ether;
    uint8 constant public  decimals = 18;
     
    uint public tokensDistributed = 0;
     
    uint constant public tokensPerTranche = 11000000 * (uint256(10) ** decimals);
    uint256 public privateExchangeRate = 1420;  
    uint256 public firstExchangeRate   = 1289;  
    uint256 public secondExchangeRate  = 1193;   
    uint256 public thirdExchangeRate   = 1142;   
    uint256 public fourthExchangeRate  = 1118;   
    uint256 public fifthExchangeRate   = 1105;   

     
    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    modifier isIcoOpen() {
        require(block.number >= fundingStartBlock);
        require(block.number <= fundingEndBlock);
        require(totalRaisedInWei <= fundingMaximumTargetInWei);
        _;
    }


    modifier isMinimumPrice() {
        if (tokensDistributed < safeMult(3,tokensPerTranche) || block.number < thirdChangeBlock ) {
           require(msg.value >= minPriceInWeiForPre);
        }
        else if (tokensDistributed <= safeMult(6,tokensPerTranche)) {
           require(msg.value >= minPriceInWeiForIco);
        }

        require(msg.value <= maxPriceInWeiFromUser);

         _;
    }

    modifier isIcoFinished() {
        require(totalRaisedInWei >= fundingMaximumTargetInWei || (block.number > fundingEndBlock) || state == State.Successful );
        _;
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

     
    modifier atEndOfLifecycle() {
        require(totalRaisedInWei >= fundingMaximumTargetInWei || (block.number > fundingEndBlock + 40000));
        _;
    }

     
    function CrowdSale(
    address _fundsWallet,
    uint256 _fundingStartBlock,
    uint256 _firstInHours,
    uint256 _secondInHours,
    uint256 _thirdInHours,
    uint256 _fundingDurationInHours,
    TrakToken _tokenAddress
    ) public {

        require(safeAdd(_fundingStartBlock, safeMult(_fundingDurationInHours , 212)) > _fundingStartBlock);

        creator = msg.sender;

        if (_fundsWallet !=0) {
            contractOwner = _fundsWallet;
        }
        else {
            contractOwner = msg.sender;
        }

        fundingStartBlock = _fundingStartBlock;
        firstChangeBlock =  safeAdd(fundingStartBlock, safeMult(_firstInHours , 212));
        secondChangeBlock = safeAdd(fundingStartBlock, safeMult(_secondInHours , 212));
        thirdChangeBlock =  safeAdd(fundingStartBlock, safeMult(_thirdInHours , 212));
        fundingDurationInHours = _fundingDurationInHours;
        fundingEndBlock = safeAdd(fundingStartBlock, safeMult(_fundingDurationInHours , 212));
        trakToken = TrakToken(_tokenAddress);
    }


     
    function () external payable {
        buyTokens(msg.sender);
    }


    function buyTokens(address beneficiary) inState(State.Fundraising) isIcoOpen isMinimumPrice  public  payable  {
        require(beneficiary != 0x0);
         
        require(whitelistedContributors[beneficiary] == true );
        uint256 tokenAmount;
        uint256 checkedReceivedWei = safeAdd(totalRaisedInWei, msg.value);
         

        if (checkedReceivedWei > fundingMaximumTargetInWei ) {

             
            totalRaisedInWei = safeAdd(totalRaisedInWei,safeSubtract(fundingMaximumTargetInWei,totalRaisedInWei));
             
            var (rate, ) = getCurrentTokenPrice();
             
            tokenAmount = safeMult(safeSubtract(fundingMaximumTargetInWei,totalRaisedInWei), rate);
             
            beneficiary.transfer(safeSubtract(checkedReceivedWei,fundingMaximumTargetInWei));
        }
        else {
            totalRaisedInWei = safeAdd(totalRaisedInWei,msg.value);
            var (currentRate,trancheMaxTokensLeft) = getCurrentTokenPrice();
             
            tokenAmount = safeMult(msg.value, currentRate);
            if (tokenAmount > trancheMaxTokensLeft) {
                 
                tokensDistributed =  safeAdd(tokensDistributed,safeAdd(trancheMaxTokensLeft,safeDiv(1,10)));
                 
                var (nextCurrentRate,nextTrancheMaxTokensLeft) = getCurrentTokenPrice();

                if (nextTrancheMaxTokensLeft <= 0) {
                    tokenAmount = safeAdd(trancheMaxTokensLeft,safeDiv(1,10));
                    state =  State.Successful;
                     
                    beneficiary.transfer(safeDiv(safeSubtract(tokenAmount,trancheMaxTokensLeft),currentRate));
                } else {
                    uint256 nextTokenAmount = safeMult(safeSubtract(msg.value,safeMult(trancheMaxTokensLeft,safeDiv(1,currentRate))),nextCurrentRate);
                    tokensDistributed =  safeAdd(tokensDistributed,nextTokenAmount);
                    tokenAmount = safeAdd(nextTokenAmount,safeAdd(trancheMaxTokensLeft,safeDiv(1,10)));
                }
            }
            else {
                tokensDistributed =  safeAdd(tokensDistributed,tokenAmount);
            }
        }

        trakToken.transfer(beneficiary,tokenAmount);
         
        forwardFunds();
    }

    function forwardFunds() internal {
        contractOwner.transfer(msg.value);
    }

     
    function getCurrentTokenPrice() private constant returns (uint256 currentRate, uint256 maximumTokensLeft) {

        if (tokensDistributed < safeMult(1,tokensPerTranche) && (block.number < firstChangeBlock)) {
             
            return ( privateExchangeRate, safeSubtract(tokensPerTranche,tokensDistributed) );
        }
        else if (tokensDistributed < safeMult(2,tokensPerTranche) && (block.number < secondChangeBlock)) {
            return ( firstExchangeRate, safeSubtract(safeMult(2,tokensPerTranche),tokensDistributed) );
        }
        else if (tokensDistributed < safeMult(3,tokensPerTranche) && (block.number < thirdChangeBlock)) {
            return ( secondExchangeRate, safeSubtract(safeMult(3,tokensPerTranche),tokensDistributed) );
        }
        else if (tokensDistributed < safeMult(4,tokensPerTranche) && (block.number < fundingEndBlock)) {
            return  (thirdExchangeRate,safeSubtract(safeMult(4,tokensPerTranche),tokensDistributed)  );
        }
        else if (tokensDistributed < safeMult(5,tokensPerTranche) && (block.number < fundingEndBlock)) {
            return  (fourthExchangeRate,safeSubtract(safeMult(5,tokensPerTranche),tokensDistributed)  );
        }
        else if (tokensDistributed <= safeMult(6,tokensPerTranche)) {
            return  (fifthExchangeRate,safeSubtract(safeMult(6,tokensPerTranche),tokensDistributed)  );
        }
    }


    function authorizeKyc(address[] addrs) external onlyOwner returns (bool success) {

         
         
        uint arrayLength = addrs.length;

        for (uint x = 0; x < arrayLength; x++) {
            whitelistedContributors[addrs[x]] = true;
        }

        return true;
    }


    function withdrawWei () external onlyOwner {
         
        contractOwner.transfer(this.balance);
    }

    function updateFundingEndBlock(uint256 newFundingEndBlock)  external onlyOwner {
        require(newFundingEndBlock > fundingStartBlock);
         
        fundingEndBlock = newFundingEndBlock;
    }


     
    function burnRemainingToken(uint256 _value) external  onlyOwner isIcoFinished {
         
        require(_value > 0);
        trakToken.burn(_value);
    }

     
    function withdrawRemainingToken(uint256 _value,address trakTokenAdmin)  external onlyOwner isIcoFinished {
         
        require(trakTokenAdmin != 0x0);
        require(_value > 0);
        trakToken.transfer(trakTokenAdmin,_value);
    }


     
    function finalize() external  onlyOwner isIcoFinished  {
        state =  State.Closed;
        trakToken.finalize();
    }

     
    function changeTokensWallet(address newAddress) external  onlyOwner  {
        require(newAddress != address(0));
        trakToken.changeTokensWallet(newAddress);
    }


    function removeContract ()  external onlyOwner atEndOfLifecycle {
         
        selfdestruct(msg.sender);
    }

     
    function changeFundsWallet(address newAddress) external onlyOwner returns (bool)
    {
        require(newAddress != address(0));
        contractOwner = newAddress;
    }


     
    function pause() external onlyOwner inState(State.Fundraising) {
         
        state =  State.Paused;
    }


     
    function resume() external onlyOwner {
         
        state =  State.Fundraising;
    }

    function updateFirstChangeBlock(uint256 newFirstChangeBlock)  external onlyOwner {
        firstChangeBlock = newFirstChangeBlock;
    }

    function updateSecondChangeBlock(uint256 newSecondChangeBlock)  external onlyOwner {
        secondChangeBlock = newSecondChangeBlock;
    }  

    function updateThirdChangeBlock(uint256 newThirdChangeBlock)  external onlyOwner {
        thirdChangeBlock = newThirdChangeBlock;
    }      

    function updatePrivateExhangeRate(uint256 newPrivateExchangeRate)  external onlyOwner {
        privateExchangeRate = newPrivateExchangeRate;
    } 

    function updateFirstExhangeRate(uint256 newFirstExchangeRate)  external onlyOwner {
        firstExchangeRate = newFirstExchangeRate;
    }    

    function updateSecondExhangeRate(uint256 newSecondExchangeRate)  external onlyOwner {
        secondExchangeRate = newSecondExchangeRate;
    }

    function updateThirdExhangeRate(uint256 newThirdExchangeRate)  external onlyOwner {
        thirdExchangeRate = newThirdExchangeRate;
    }      

    function updateFourthExhangeRate(uint256 newFourthExchangeRate)  external onlyOwner {
        fourthExchangeRate = newFourthExchangeRate;
    }    

    function updateFifthExhangeRate(uint256 newFifthExchangeRate)  external onlyOwner {
        fifthExchangeRate = newFifthExchangeRate;
    }    
    
    function updateMinInvestmentForPreIco(uint256 newMinPriceInWeiForPre)  external onlyOwner {
        minPriceInWeiForPre = newMinPriceInWeiForPre;
    }
    function updateMinInvestmentForIco(uint256 newMinPriceInWeiForIco)  external onlyOwner {
        minPriceInWeiForIco = newMinPriceInWeiForIco;
    }

}