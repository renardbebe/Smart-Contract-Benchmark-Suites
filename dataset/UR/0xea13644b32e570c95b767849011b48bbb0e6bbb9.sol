 

pragma solidity 0.4.18;

contract CrowdsaleParameters {
     
    address internal constant presalePoolAddress        = 0xF373BfD05C8035bE6dcB44CABd17557e49D5364C;
    address internal constant foundersAddress           = 0x0ED375dd94c878703147580F044B6B1CE6a7F053;
    address internal constant incentiveReserveAddress   = 0xD34121E853af290e61a0F0313B99abb24D4Dc6ea;
    address internal constant generalSaleAddress        = 0xC107EC2077BA7d65944267B64F005471A6c05692;
    address internal constant lotteryAddress            = 0x98631b688Bcf78D233C48E464fCfe6dC7aBd32A7;
    address internal constant marketingAddress          = 0x2C1C916a4aC3d0f2442Fe0A9b9e570eB656582d8;

     
    uint256 internal constant presaleStartDate      = 1512121500;  
    uint256 internal constant presaleEndDate        = 1513382430;  
    uint256 internal constant generalSaleStartDate  = 1515319200;  
    uint256 internal constant generalSaleEndDate    = 1518602400;  
}

contract TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != owner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract SeedToken is Owned, CrowdsaleParameters {
    uint8 public decimals;

    function totalSupply() public  returns (uint256 result);

    function balanceOf(address _address) public returns (uint256 balance);

    function allowance(address _owner, address _spender) public returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function accountBalance(address _address) public returns (uint256 balance);
}

contract LiveTreeCrowdsale is Owned, CrowdsaleParameters {
    uint[] public ICOStagePeriod;

    bool public icoClosedManually = false;

    bool public allowRefunds = false;

    uint public totalCollected = 0;

    address private saleWalletAddress;

    address private presaleWalletAddress;

    uint private tokenMultiplier = 10;

    SeedToken private tokenReward;

    uint private reasonableCostsPercentage;

    mapping (address => uint256) private investmentRecords;

    event FundTransfer(address indexed _from, address indexed _to, uint _value);

    event TokenTransfer(address indexed baker, uint tokenAmount, uint pricePerToken);

    event Refund(address indexed backer, uint amount);

    enum Stage { PreSale, GeneralSale, Inactive }

     
    function LiveTreeCrowdsale(address _tokenAddress) public {
        tokenReward = SeedToken(_tokenAddress);
        tokenMultiplier = tokenMultiplier ** tokenReward.decimals();
        saleWalletAddress = CrowdsaleParameters.generalSaleAddress;
        presaleWalletAddress = CrowdsaleParameters.presalePoolAddress;

        ICOStagePeriod.push(CrowdsaleParameters.presaleStartDate);
        ICOStagePeriod.push(CrowdsaleParameters.presaleEndDate);
        ICOStagePeriod.push(CrowdsaleParameters.generalSaleStartDate);
        ICOStagePeriod.push(CrowdsaleParameters.generalSaleEndDate);
    }

     
    function getActiveStage() internal constant returns (Stage) {
        if (ICOStagePeriod[0] <= now && now < ICOStagePeriod[1])
            return Stage.PreSale;

        if (ICOStagePeriod[2] <= now && now < ICOStagePeriod[3])
            return Stage.GeneralSale;

        return Stage.Inactive;
    }

     
    function processPayment(address bakerAddress, uint amount) internal {
         
        Stage currentStage = getActiveStage();
        require(currentStage != Stage.Inactive);

         
        require(!icoClosedManually);

         
         
        assert(amount > 0 finney);

         
        require(amount < 1e27);

         
        FundTransfer(bakerAddress, address(this), amount);

         
        uint tokensPerEth = 1130;

        if (amount < 1.5 ether)
            tokensPerEth = 1000;
        else if (amount < 3 ether)
            tokensPerEth = 1005;
        else if (amount < 5 ether)
            tokensPerEth = 1010;
        else if (amount < 7 ether)
            tokensPerEth = 1015;
        else if (amount < 10 ether)
            tokensPerEth = 1020;
        else if (amount < 15 ether)
            tokensPerEth = 1025;
        else if (amount < 20 ether)
            tokensPerEth = 1030;
        else if (amount < 30 ether)
            tokensPerEth = 1035;
        else if (amount < 50 ether)
            tokensPerEth = 1040;
        else if (amount < 75 ether)
            tokensPerEth = 1045;
        else if (amount < 100 ether)
            tokensPerEth = 1050;
        else if (amount < 150 ether)
            tokensPerEth = 1055;
        else if (amount < 250 ether)
            tokensPerEth = 1060;
        else if (amount < 350 ether)
            tokensPerEth = 1070;
        else if (amount < 500 ether)
            tokensPerEth = 1075;
        else if (amount < 750 ether)
            tokensPerEth = 1080;
        else if (amount < 1000 ether)
            tokensPerEth = 1090;
        else if (amount < 1500 ether)
            tokensPerEth = 1100;
        else if (amount < 2000 ether)
            tokensPerEth = 1110;
        else if (amount < 3500 ether)
            tokensPerEth = 1120;

        if (currentStage == Stage.PreSale)
            tokensPerEth = tokensPerEth * 2;

         
         
        uint weiPerEth = 1e18;
        uint tokenAmount = amount * tokensPerEth * tokenMultiplier / weiPerEth;

         
         
        address tokenSaleWallet = currentStage == Stage.PreSale ? presaleWalletAddress : saleWalletAddress;
        uint remainingTokenBalance = tokenReward.accountBalance(tokenSaleWallet);
        if (remainingTokenBalance < tokenAmount) {
            tokenAmount = remainingTokenBalance;
        }

         
         
        uint acceptedAmount = tokenAmount * weiPerEth / (tokensPerEth * tokenMultiplier);

         
        tokenReward.transferFrom(tokenSaleWallet, bakerAddress, tokenAmount);

        TokenTransfer(bakerAddress, tokenAmount, tokensPerEth);

        uint change = amount - acceptedAmount;
        if (change > 0) {
            if (bakerAddress.send(change)) {
                FundTransfer(address(this), bakerAddress, change);
            }
            else
                revert();
        }

         
        investmentRecords[bakerAddress] += acceptedAmount;
        totalCollected += acceptedAmount;
    }

     
    function changePresaleEndDate(uint256 endDate) external onlyOwner {
        require(ICOStagePeriod[0] < endDate);
        require(ICOStagePeriod[2] >= endDate);

        ICOStagePeriod[1] = endDate;
    }

     
    function changeGeneralSaleStartDate(uint256 startDate) external onlyOwner {
        require(now < startDate);
        require(ICOStagePeriod[1] <= startDate);

        ICOStagePeriod[2] = startDate;
    }

     
    function changeGeneralSaleEndDate(uint256 endDate) external onlyOwner {
        require(ICOStagePeriod[2] < endDate);

        ICOStagePeriod[3] = endDate;
    }

     
    function pauseICO() external onlyOwner {
        require(!icoClosedManually);

        icoClosedManually = true;
    }

     
    function unpauseICO() external onlyOwner {
        require(icoClosedManually);

        icoClosedManually = false;
    }

     
    function closeMainSaleICO() external onlyOwner {
        var amountToDestroy = tokenReward.balanceOf(CrowdsaleParameters.generalSaleAddress);
        tokenReward.transferFrom(CrowdsaleParameters.generalSaleAddress, 0, amountToDestroy);
        ICOStagePeriod[3] = now;
        TokenTransfer(0, amountToDestroy, 0);
    }

     
    function closePreICO() external onlyOwner {
        var amountToTransfer = tokenReward.balanceOf(CrowdsaleParameters.presalePoolAddress);
        ICOStagePeriod[1] = now;
        tokenReward.transferFrom(CrowdsaleParameters.presalePoolAddress, CrowdsaleParameters.generalSaleAddress, amountToTransfer);
    }


     
    function setAllowRefunds(bool value, uint _reasonableCostsPercentage) external onlyOwner {
        require(isICOClosed());
        require(_reasonableCostsPercentage >= 1 && _reasonableCostsPercentage <= 999);

        allowRefunds = value;
        reasonableCostsPercentage = _reasonableCostsPercentage;
    }

     
    function safeWithdrawal(uint amount) external onlyOwner {
        require(this.balance >= amount);

        if (owner.send(amount))
            FundTransfer(address(this), owner, amount);
    }

     
    function isICOClosed() public constant returns (bool closed) {
        Stage currentStage = getActiveStage();
        return icoClosedManually || currentStage == Stage.Inactive;
    }

     
    function () external payable {
        processPayment(msg.sender, msg.value);
    }

     
    function kill() external onlyOwner {
        require(isICOClosed());

        selfdestruct(owner);
    }

     
    function refund() external {
        require(isICOClosed() && allowRefunds && investmentRecords[msg.sender] > 0);

        var amountToReturn = investmentRecords[msg.sender] * (1000 - reasonableCostsPercentage) / 1000;

        require(this.balance >= amountToReturn);

        investmentRecords[msg.sender] = 0;
        msg.sender.transfer(amountToReturn);
        Refund(msg.sender, amountToReturn);
    }
}