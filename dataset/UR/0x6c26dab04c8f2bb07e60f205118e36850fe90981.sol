 

pragma solidity ^0.4.20;

 

contract PoWMLottery {
    using SafeMath for uint256;
    
     
    bool public isLotteryOpen = false;
    address POWM_address = address(0xA146240bF2C04005A743032DC0D241ec0bB2BA2B);
    POWM maths = POWM(POWM_address);
    address owner;
    
     
    mapping (uint256 => address) public gamblers;
    mapping (address => uint256) public token_buyins;
    mapping (address => uint256) public last_round_bought;
    
    uint256 public num_tickets_current_round = 0;
    uint256 public current_round = 0;
    uint256 public numTokensInLottery = 0;
    
    address masternode_referrer;
    
     
    uint256 public MAX_TOKEN_BUYIN = 25;
    
    function PoWMLottery() public {
        current_round = 1;
        owner = msg.sender;
        masternode_referrer = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function donateToLottery() public payable returns(uint256) {
        uint256 tokens_before = maths.myTokens();
        maths.buy.value(msg.value)(masternode_referrer);
        uint256 tokens_after = maths.myTokens();
        numTokensInLottery = maths.myTokens();
        return tokens_after - tokens_before;
    }

     
    function buyTickets() public payable {
        require(isLotteryOpen == true);
        require(last_round_bought[msg.sender] != current_round);
        
         
         
        uint256 tokens_before = maths.myTokens();
        maths.buy.value(msg.value)(masternode_referrer);
        uint256 tokens_after = maths.myTokens();
        uint256 tokens_bought = SafeMath.sub(tokens_after, tokens_before).div(1e18);
        require(tokens_bought >= 1 && tokens_bought <= MAX_TOKEN_BUYIN);
        numTokensInLottery = maths.myTokens();
        
         
         
        uint8 i = 0;
        while (i < tokens_bought) {
            i++;
            
            gamblers[num_tickets_current_round] = msg.sender;
            num_tickets_current_round++;
        }

        token_buyins[msg.sender] = tokens_bought;
        last_round_bought[msg.sender] = current_round;
    }
    
    function setMaxTokenBuyin(uint256 tokens) public onlyOwner {
        require(isLotteryOpen == false);
        require(tokens > 0);
        
        MAX_TOKEN_BUYIN = tokens;
    }
    
    function openLottery() onlyOwner public {
        require(isLotteryOpen == false);
        current_round++;
        isLotteryOpen = true;
        num_tickets_current_round = 0;
    }
    
     
     
    function () public payable {
        if(msg.sender != address(0xA146240bF2C04005A743032DC0D241ec0bB2BA2B)) {
            buyTickets();
        }
    }
    
    function closeLotteryAndPickWinner() onlyOwner public {
        require(isLotteryOpen == true);
        isLotteryOpen = false;
        
         
         
         
        uint256 winning_number = uint256(keccak256(block.blockhash(block.number - 1))) % num_tickets_current_round;
        address winner = gamblers[winning_number];
        masternode_referrer = winner;
        
         
        uint256 exact_tokens = maths.myTokens();
        maths.transfer(winner, exact_tokens);
        numTokensInLottery = 0;
        
         
        winner.transfer(address(this).balance);
    }
}

 
contract POWM {
    function buy(address _referredBy) public payable returns(uint256) {}
    function calculateTokensReceived(uint256 _ethereumToSpend) public view returns(uint256) {}
    function transfer(address _toAddress, uint256 _amountOfTokens) returns(bool) {}
    function myTokens() public view returns(uint256) {}
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}