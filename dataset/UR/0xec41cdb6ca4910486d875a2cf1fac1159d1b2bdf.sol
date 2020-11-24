 

pragma solidity ^0.4.17;

  

 
contract ERC223ReceivingContract {

     
     
     
     
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

 
contract Token {
     

     
    uint256 public totalSupply;

     
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
}

 
contract StandardToken is Token {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     
     
     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        Transfer(msg.sender, _to, _value);

        return true;
    }

     
     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _value,
        bytes _data)
        public
        returns (bool)
    {
        require(transfer(_to, _value));

        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        return true;
    }

     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);

        return true;
    }

     
     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != 0x0);

         
         
         
         
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
     
     
    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
     
     
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
}

 
contract xChaingeToken is StandardToken {

     

     
    string constant public name = "xChainge Token";
    string constant public symbol = "XCH";
    uint8 constant public decimals = 18;
    uint constant multiplier = 10 ** uint(decimals);

    event Deployed(uint indexed _totalSupply);
    event Burnt(address indexed _receiver, uint indexed _num, uint indexed _totalSupply);

     
     
     
     
     
    function xChaingeToken(address auctionAddress, address walletAddress) public
    {
         
        require(auctionAddress != 0x0);
        require(walletAddress != 0x0);

         
        totalSupply = 23529412000000000000000000;

        balances[auctionAddress] = 20000000000000000000000000;
        balances[walletAddress] = 3529412000000000000000000;

        Transfer(0x0, auctionAddress, balances[auctionAddress]);
        Transfer(0x0, walletAddress, balances[walletAddress]);

        Deployed(totalSupply);

        assert(totalSupply == balances[auctionAddress] + balances[walletAddress]);
    }

     
     
     
     
    function burn(uint num) public {
        require(num > 0);
        require(balances[msg.sender] >= num);
        require(totalSupply >= num);

        uint preBalance = balances[msg.sender];

        balances[msg.sender] -= num;
        totalSupply -= num;
        Burnt(msg.sender, num, totalSupply);
        Transfer(msg.sender, 0x0, num);

        assert(balances[msg.sender] == preBalance - num);
    }
}

 
 
 
contract DutchAuction {
     

     
    uint constant public tokenClaimWaitingPeriod = 10 days;

     

    xChaingeToken public token;
    address public ownerAddress;
    address public walletAddress;

     

     
    uint constant public priceStart = 50000000000000000;    
    uint constant public minPrice = 5000000000000000;
    uint constant public softCap = 10000000000000000000000;

     
    uint public startTime;
    uint public endTime;
    uint public startBlock;

     
    uint public receivedWei;

     
    uint public fundsClaimed;

    uint public tokenMultiplier;

     
    uint public numTokensAuctioned;

     
    uint public finalPrice;

     
    mapping (address => uint) public bids;

    Stages public stage;

     
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        AuctionCanceled,
        TokensDistributed
    }

     
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    modifier isOwner() {
        require(msg.sender == ownerAddress);
        _;
    }

     

    event Deployed();
    event Setup();
    event AuctionStarted(uint indexed _startTime, uint indexed _blockNumber);
    event BidSubmission(address indexed _sender, uint _amount, uint _missingFunds);
    event ClaimedTokens(address indexed _recipient, uint _sentAmount);
    event AuctionEnded(uint _finalPrice);
    event TokensDistributed();
    event AuctionCanceled();

     

     
     
     
    function DutchAuction(address _walletAddress) public
    {
        require(_walletAddress != 0x0);
        walletAddress = _walletAddress;

        ownerAddress = msg.sender;
        stage = Stages.AuctionDeployed;
        Deployed();
    }

     
    function () public payable atStage(Stages.AuctionStarted) {
        bid();
    }

     
     
     
    function setup(address _tokenAddress) public isOwner atStage(Stages.AuctionDeployed) {
        require(_tokenAddress != 0x0);
        token = xChaingeToken(_tokenAddress);

         
        numTokensAuctioned = token.balanceOf(address(this));

         
        tokenMultiplier = 10 ** uint(token.decimals());

        stage = Stages.AuctionSetUp;
        Setup();
    }

     
     
    function startAuction() public isOwner atStage(Stages.AuctionSetUp) {
        stage = Stages.AuctionStarted;
        startTime = now;
        startBlock = block.number;
        AuctionStarted(startTime, startBlock);
    }

     
     
     
    function finalizeAuction() public atStage(Stages.AuctionStarted)
    {
        require(price() == minPrice);

        endTime = now;

        if (receivedWei < softCap)
        {
            token.transfer(walletAddress, numTokensAuctioned);
            stage = Stages.AuctionCanceled;
            AuctionCanceled();
            return;
        }

         
        walletAddress.transfer(receivedWei);

        uint missingFunds = missingFundsToEndAuction();
        if (missingFunds > 0){
            uint soldTokens = tokenMultiplier * receivedWei / price();
            uint burnTokens = numTokensAuctioned - soldTokens;
            token.burn(burnTokens);
            numTokensAuctioned -= burnTokens;
        }

         
         
        finalPrice = tokenMultiplier * receivedWei / numTokensAuctioned;

        stage = Stages.AuctionEnded;
        AuctionEnded(finalPrice);

        assert(finalPrice > 0);
    }

     
    function CancelAuction() public isOwner atStage(Stages.AuctionStarted)
    {
        token.transfer(walletAddress, numTokensAuctioned);
        stage = Stages.AuctionCanceled;
        AuctionCanceled();
    }

     


     
     
    function bid() public payable atStage(Stages.AuctionStarted)
    {
        require(msg.value > 0);
        assert(bids[msg.sender] + msg.value >= msg.value);

         
        uint missingFunds = missingFundsToEndAuction();

         
         
        require(msg.value <= missingFunds);

        bids[msg.sender] += msg.value;
        receivedWei += msg.value;

        BidSubmission(msg.sender, msg.value, missingFunds);

        assert(receivedWei >= msg.value);
    }

     
     
     
    function claimTokens() public atStage(Stages.AuctionEnded) returns (bool) {
        return proxyClaimTokens(msg.sender);
    }

     
     
     
    function proxyClaimTokens(address receiverAddress) public atStage(Stages.AuctionEnded) returns (bool)
    {
         
         
         
        require(now > endTime + tokenClaimWaitingPeriod);
        require(receiverAddress != 0x0);

        if (bids[receiverAddress] == 0) {
            return false;
        }

         
        uint num = (tokenMultiplier * bids[receiverAddress]) / finalPrice;

         
         
         
        uint auctionTokensBalance = token.balanceOf(address(this));
        if (num > auctionTokensBalance) {
            num = auctionTokensBalance;
        }

         
        fundsClaimed += bids[receiverAddress];

         
        bids[receiverAddress] = 0;

        require(token.transfer(receiverAddress, num));

        ClaimedTokens(receiverAddress, num);

         
         
        if (fundsClaimed == receivedWei) {
            stage = Stages.TokensDistributed;
            TokensDistributed();
        }

        assert(token.balanceOf(receiverAddress) >= num);
        assert(bids[receiverAddress] == 0);
        return true;
    }

     
    function withdraw() public atStage(Stages.AuctionCanceled) returns (bool) {
        return proxyWithdraw(msg.sender);
    }

     
     
    function proxyWithdraw(address receiverAddress) public atStage(Stages.AuctionCanceled) returns (bool) {
        require(receiverAddress != 0x0);
        
        if (bids[receiverAddress] == 0) {
            return false;
        }

        uint amount = bids[receiverAddress];
        bids[receiverAddress] = 0;
        
        receiverAddress.transfer(amount);

        assert(bids[receiverAddress] == 0);
        return true;
    }

     
     
     
     
     
    function price() public constant returns (uint) {
        if (stage == Stages.AuctionEnded ||
            stage == Stages.AuctionCanceled ||
            stage == Stages.TokensDistributed) {
            return 0;
        }
        return calcTokenPrice();
    }

     
     
     
     
    function missingFundsToEndAuction() constant public returns (uint) {

         
        uint requiredWeiAtPrice = numTokensAuctioned * price() / tokenMultiplier;
        if (requiredWeiAtPrice <= receivedWei) {
            return 0;
        }

         
        return requiredWeiAtPrice - receivedWei;
    }

     

     
     
     
     
     
     
     
     
    function calcTokenPrice() constant private returns (uint) {
        uint elapsed;
        if (stage == Stages.AuctionStarted) {
            elapsed = now - startTime;
        }

        uint decayRate = elapsed ** 3 / 541000000000;
        uint currentPrice = priceStart * (1 + elapsed) / (1 + elapsed + decayRate);
        return minPrice > currentPrice ? minPrice : currentPrice;
    }
}