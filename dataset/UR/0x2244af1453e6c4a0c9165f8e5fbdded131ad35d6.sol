 

pragma solidity ^0.4.18;

 

contract BoomerCoin
{
    string constant public name = "BoomerCoin";
    string constant public symbol = "SSN";
    uint8 constant public decimals = 5;
    
    mapping(address => uint) public initialBalance;
    mapping(address => uint) public boughtTime;
    
    uint constant public buyPrice = 12 szabo;  
    uint constant public sellPrice = 10 szabo;

    uint constant public Q = 35;  

    function BoomerCoin() public {
         
        initialBalance[msg.sender] = 1 ether / buyPrice;
        boughtTime[msg.sender] = now;
    }

     
     
    function fracExp(uint k, uint q, uint n, uint p) internal pure returns (uint) {
        uint s = 0;
        uint N = 1;
        uint B = 1;
        for (uint i = 0; i < p; ++i){
            s += k * N / B / (q**i);
            N  = N * (n-i);
            B  = B * (i+1);
        }
        return s;
    }

     
    function fund() payable public returns (uint) {
        require(msg.value > 0.000001 ether);
        require(msg.value < 200 ether);

        uint tokens = div(msg.value, buyPrice);
        initialBalance[msg.sender] = add(balanceOf(msg.sender), tokens);

         
        boughtTime[msg.sender] = now;

        return tokens;
    }

    function balanceOf(address addr) public constant returns (uint) {

        uint elapsedHours;

        if (boughtTime[addr] == 0) {
            elapsedHours = 0;
        }
        else {
            elapsedHours = sub(now, boughtTime[addr]) / 60 / 60;

             
            if (elapsedHours < 0) {
                elapsedHours = 0;
            }
            else if (elapsedHours > 1000) {
                 
                elapsedHours = 1000;
            }
        }

        uint amount = fracExp(initialBalance[addr], Q, elapsedHours, 8);

          
        if (amount < 0) amount = 0;

        return amount;
    }
    
    function epoch() public constant returns (uint) {
        return now;
    }

     
    function sell(uint tokens) public {

        uint tokensAvailable = balanceOf(msg.sender);

        require(tokens > 0);
        require(this.balance > 0);  
        require(tokensAvailable > 0);
        require(tokens <= tokensAvailable);

        uint weiRequested = mul(tokens, sellPrice);

        if (weiRequested > this.balance) {           

             
            uint insolventWei = sub(weiRequested, this.balance);
            uint remainingTokens = div(insolventWei, sellPrice);

             
            initialBalance[msg.sender] = remainingTokens;

             
            boughtTime[msg.sender] = now;

            msg.sender.transfer(this.balance);       
        }
        else {
             
            boughtTime[msg.sender] = now;

             
            initialBalance[msg.sender] = sub(tokensAvailable, tokens);
            msg.sender.transfer(weiRequested);
        }
    }

     
    function getMeOutOfHere() public {
        uint amount = balanceOf(msg.sender);
        sell(amount);
    }

     
    function() payable public {
        fund();
    }

     

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