 

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


 
contract RaidenToken is StandardToken {

     

     
    string constant public name = "Raiden Token";
    string constant public symbol = "RDN";
    uint8 constant public decimals = 18;
    uint constant multiplier = 10 ** uint(decimals);

    event Deployed(uint indexed _total_supply);
    event Burnt(
        address indexed _receiver,
        uint indexed _num,
        uint indexed _total_supply
    );

     
     
     
     
     
     
    function RaidenToken(
        address auction_address,
        address wallet_address,
        uint initial_supply)
        public
    {
         
        require(auction_address != 0x0);
        require(wallet_address != 0x0);

         
        require(initial_supply > multiplier);

         
        totalSupply = initial_supply;

        balances[auction_address] = initial_supply / 2;
        balances[wallet_address] = initial_supply / 2;

        Transfer(0x0, auction_address, balances[auction_address]);
        Transfer(0x0, wallet_address, balances[wallet_address]);

        Deployed(totalSupply);

        assert(totalSupply == balances[auction_address] + balances[wallet_address]);
    }

     
     
     
     
    function burn(uint num) public {
        require(num > 0);
        require(balances[msg.sender] >= num);
        require(totalSupply >= num);

        uint pre_balance = balances[msg.sender];

        balances[msg.sender] -= num;
        totalSupply -= num;
        Burnt(msg.sender, num, totalSupply);
        Transfer(msg.sender, 0x0, num);

        assert(balances[msg.sender] == pre_balance - num);
    }

}


 
 
 
contract DutchAuction {
     

     
    uint constant public token_claim_waiting_period = 5 minutes;

     
     
    uint constant public bid_threshold = 9 ether;

     

    RaidenToken public token;
    address public owner_address;
    address public wallet_address;

     

     
    uint public price_start;

     
    uint public price_constant;

     
    uint32 public price_exponent;

     
    uint public start_time;
    uint public end_time;
    uint public start_block;

     
    uint public received_wei;

     
    uint public funds_claimed;

    uint public token_multiplier;

     
    uint public num_tokens_auctioned;

     
    uint public final_price;

     
    mapping (address => uint) public bids;

     
    mapping (address => bool) public whitelist;

    Stages public stage;

     
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TokensDistributed
    }

     
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner_address);
        _;
    }

     

    event Deployed(
        uint indexed _price_start,
        uint indexed _price_constant,
        uint32 indexed _price_exponent
    );
    event Setup();
    event AuctionStarted(uint indexed _start_time, uint indexed _block_number);
    event BidSubmission(
        address indexed _sender,
        uint _amount,
        uint _missing_funds
    );
    event ClaimedTokens(address indexed _recipient, uint _sent_amount);
    event AuctionEnded(uint _final_price);
    event TokensDistributed();

     

     
     
     
     
     
     
    function DutchAuction(
        address _wallet_address,
        uint _price_start,
        uint _price_constant,
        uint32 _price_exponent)
        public
    {
        require(_wallet_address != 0x0);
        wallet_address = _wallet_address;

        owner_address = msg.sender;
        stage = Stages.AuctionDeployed;
        changeSettings(_price_start, _price_constant, _price_exponent);
        Deployed(_price_start, _price_constant, _price_exponent);
    }

     
    function () public payable atStage(Stages.AuctionStarted) {
        bid();
    }

     
     
     
    function setup(address _token_address) public isOwner atStage(Stages.AuctionDeployed) {
        require(_token_address != 0x0);
        token = RaidenToken(_token_address);

         
        num_tokens_auctioned = token.balanceOf(address(this));

         
        token_multiplier = 10 ** uint(token.decimals());

        stage = Stages.AuctionSetUp;
        Setup();
    }

     
     
     
     
     
     
    function changeSettings(
        uint _price_start,
        uint _price_constant,
        uint32 _price_exponent)
        internal
    {
        require(stage == Stages.AuctionDeployed || stage == Stages.AuctionSetUp);
        require(_price_start > 0);
        require(_price_constant > 0);

        price_start = _price_start;
        price_constant = _price_constant;
        price_exponent = _price_exponent;
    }

     
     
     
    function addToWhitelist(address[] _bidder_addresses) public isOwner {
        for (uint32 i = 0; i < _bidder_addresses.length; i++) {
            whitelist[_bidder_addresses[i]] = true;
        }
    }

     
     
     
    function removeFromWhitelist(address[] _bidder_addresses) public isOwner {
        for (uint32 i = 0; i < _bidder_addresses.length; i++) {
            whitelist[_bidder_addresses[i]] = false;
        }
    }

     
     
    function startAuction() public isOwner atStage(Stages.AuctionSetUp) {
        stage = Stages.AuctionStarted;
        start_time = now;
        start_block = block.number;
        AuctionStarted(start_time, start_block);
    }

     
     
     
    function finalizeAuction() public atStage(Stages.AuctionStarted)
    {
         
        uint missing_funds = missingFundsToEndAuction();
        require(missing_funds == 0);

         
         
        final_price = token_multiplier * received_wei / num_tokens_auctioned;

        end_time = now;
        stage = Stages.AuctionEnded;
        AuctionEnded(final_price);

        assert(final_price > 0);
    }

     


     
     
    function bid()
        public
        payable
        atStage(Stages.AuctionStarted)
    {
        require(msg.value > 0);
        require(bids[msg.sender] + msg.value <= bid_threshold || whitelist[msg.sender]);
        assert(bids[msg.sender] + msg.value >= msg.value);

         
        uint missing_funds = missingFundsToEndAuction();

         
         
        require(msg.value <= missing_funds);

        bids[msg.sender] += msg.value;
        received_wei += msg.value;

         
        wallet_address.transfer(msg.value);

        BidSubmission(msg.sender, msg.value, missing_funds);

        assert(received_wei >= msg.value);
    }

     
     
     
    function claimTokens() public atStage(Stages.AuctionEnded) returns (bool) {
        return proxyClaimTokens(msg.sender);
    }

     
     
     
    function proxyClaimTokens(address receiver_address)
        public
        atStage(Stages.AuctionEnded)
        returns (bool)
    {
         
         
         
        require(now > end_time + token_claim_waiting_period);
        require(receiver_address != 0x0);

        if (bids[receiver_address] == 0) {
            return false;
        }

         
        uint num = (token_multiplier * bids[receiver_address]) / final_price;

         
         
         
        uint auction_tokens_balance = token.balanceOf(address(this));
        if (num > auction_tokens_balance) {
            num = auction_tokens_balance;
        }

         
        funds_claimed += bids[receiver_address];

         
        bids[receiver_address] = 0;

        require(token.transfer(receiver_address, num));

        ClaimedTokens(receiver_address, num);

         
         
        if (funds_claimed == received_wei) {
            stage = Stages.TokensDistributed;
            TokensDistributed();
        }

        assert(token.balanceOf(receiver_address) >= num);
        assert(bids[receiver_address] == 0);
        return true;
    }

     
     
     
     
     
    function price() public constant returns (uint) {
        if (stage == Stages.AuctionEnded ||
            stage == Stages.TokensDistributed) {
            return 0;
        }
        return calcTokenPrice();
    }

     
     
     
     
    function missingFundsToEndAuction() constant public returns (uint) {

         
        uint required_wei_at_price = num_tokens_auctioned * price() / token_multiplier;
        if (required_wei_at_price <= received_wei) {
            return 0;
        }

         
        return required_wei_at_price - received_wei;
    }

     

     
     
     
     
     
     
     
     
    function calcTokenPrice() constant private returns (uint) {
        uint elapsed;
        if (stage == Stages.AuctionStarted) {
            elapsed = now - start_time;
        }

        uint decay_rate = elapsed ** price_exponent / price_constant;
        return price_start * (1 + elapsed) / (1 + elapsed + decay_rate);
    }
}