 

pragma solidity ^0.4.13;

 
contract SafeMath {
     

    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }
}


 
interface Token {

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 
contract StandardToken is Token {

     
    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
             
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
             
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
}


 
contract PIXToken is StandardToken, SafeMath {

    string public name = "PIX Token";
    string public symbol = "PIX";

     
     
    address public founder = 0x0;

     
    address public deposit = 0x0;

     

    enum State { PreSale, Day1, Day2, Day3, Running, Halted }  
    State state;

     
    uint public capPreSale = 15 * 10**8;   
    uint public capDay1 = 20 * 10**8;   
    uint public capDay2 = 20 * 10**8;   
    uint public capDay3 = 20 * 10**8;   

     
    uint public weiPerEther = 10**18;
    uint public centsPerEth = 23000;
    uint public centsPerToken = 12;

     
    uint public raisePreSale = 0;   
    uint public raiseDay1 = 0;   
    uint public raiseDay2 = 0;   
    uint public raiseDay3 = 0;   

     
    uint public publicSaleStart = 1502280000;  
    uint public day2Start = 1502366400;  
    uint public day3Start = 1502452800;  
    uint public saleEnd = 1503144000;  
    uint public coinTradeStart = 1505822400;  
    uint public year1Unlock = 1534680000;  
    uint public year2Unlock = 1566216000;  
    uint public year3Unlock = 1597838400;  
    uint public year4Unlock = 1629374400;  

     
    bool public allocatedFounders = false;
    bool public allocated1Year = false;
    bool public allocated2Year = false;
    bool public allocated3Year = false;
    bool public allocated4Year = false;

     
    uint public totalTokensSale = 500000000;  
    uint public totalTokensReserve = 330000000;
    uint public totalTokensCompany = 220000000;

    bool public halted = false;  

    mapping(address => uint256) presaleWhitelist;  

    event Buy(address indexed sender, uint eth, uint fbt);
    event Withdraw(address indexed sender, address to, uint eth);
    event AllocateTokens(address indexed sender);

    function PIXToken(address depositAddress) {
         
        founder = msg.sender;   
        deposit = depositAddress;   
    }

    function setETHUSDRate(uint centsPerEthInput) public {
         
        require(msg.sender == founder);
        centsPerEth = centsPerEthInput;
    }

     
    function getCurrentState() constant public returns (State) {

        if(halted) return State.Halted;
        else if(block.timestamp < publicSaleStart) return State.PreSale;
        else if(block.timestamp > publicSaleStart && block.timestamp <= day2Start) return State.Day1;
        else if(block.timestamp > day2Start && block.timestamp <= day3Start) return State.Day2;
        else if(block.timestamp > day3Start && block.timestamp <= saleEnd) return State.Day3;
        else return State.Running;
    }

     
    function getCurrentBonusInPercent() constant public returns (uint) {
        State s = getCurrentState();
        if (s == State.Halted) revert();
        else if(s == State.PreSale) return 20;
        else if(s == State.Day1) return 15;
        else if(s == State.Day2) return 10;
        else if(s == State.Day3) return 5;
        else return 0;
    }

     
    function getTokenPriceInWEI() constant public returns (uint){
        uint weiPerCent = safeDiv(weiPerEther, centsPerEth);
        return safeMul(weiPerCent, centsPerToken);
    }

     
    function buy() payable public {
        buyRecipient(msg.sender);
    }

     
    function buyRecipient(address recipient) payable public {
        State current_state = getCurrentState();  
        uint usdCentsRaise = safeDiv(safeMul(msg.value, centsPerEth), weiPerEther);  

        if(current_state == State.PreSale)
        {
            require (presaleWhitelist[msg.sender] > 0);
            raisePreSale = safeAdd(raisePreSale, usdCentsRaise);  
            require(raisePreSale < capPreSale && usdCentsRaise < presaleWhitelist[msg.sender]);  
            presaleWhitelist[msg.sender] = presaleWhitelist[msg.sender] - usdCentsRaise;  
        }
        else if (current_state == State.Day1)
        {
            raiseDay1 = safeAdd(raiseDay1, usdCentsRaise);  
            require(raiseDay1 < (capDay1 - raisePreSale));  
        }
        else if (current_state == State.Day2)
        {
            raiseDay2 = safeAdd(raiseDay2, usdCentsRaise);  
            require(raiseDay2 < capDay2);  
        }
        else if (current_state == State.Day3)
        {
            raiseDay3 = safeAdd(raiseDay3, usdCentsRaise);  
            require(raiseDay3 < capDay3);  
        }
        else revert();

        uint tokens = safeDiv(msg.value, getTokenPriceInWEI());  
        uint bonus = safeDiv(safeMul(tokens, getCurrentBonusInPercent()), 100);  

        if (current_state == State.PreSale) {
             
            totalTokensCompany = safeSub(totalTokensCompany, safeDiv(bonus, 4));
        }

        uint totalTokens = safeAdd(tokens, bonus);

        balances[recipient] = safeAdd(balances[recipient], totalTokens);
        totalSupply = safeAdd(totalSupply, totalTokens);

        deposit.transfer(msg.value);  

        Buy(recipient, msg.value, totalTokens);
    }

     
    function allocateReserveAndFounderTokens() {
        require(msg.sender==founder);
        require(getCurrentState() == State.Running);
        uint tokens = 0;

        if(block.timestamp > saleEnd && !allocatedFounders)
        {
            allocatedFounders = true;
            tokens = totalTokensCompany;
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year1Unlock && !allocated1Year)
        {
            allocated1Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year2Unlock && !allocated2Year)
        {
            allocated2Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year3Unlock && !allocated3Year)
        {
            allocated3Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year4Unlock && !allocated4Year)
        {
            allocated4Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else revert();

        AllocateTokens(msg.sender);
    }

     
    function halt() {
        require(msg.sender==founder);
        halted = true;
    }

    function unhalt() {
        require(msg.sender==founder);
        halted = false;
    }

     
    function changeFounder(address newFounder) {
        require(msg.sender==founder);
        founder = newFounder;
    }

     
    function changeDeposit(address newDeposit) {
        require(msg.sender==founder);
        deposit = newDeposit;
    }

     
    function addPresaleWhitelist(address toWhitelist, uint256 amount){
        require(msg.sender==founder && amount > 0);
        presaleWhitelist[toWhitelist] = amount * 100;
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(block.timestamp > coinTradeStart);
        return super.transfer(_to, _value);
    }
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(block.timestamp > coinTradeStart);
        return super.transferFrom(_from, _to, _value);
    }

    function() payable {
        buyRecipient(msg.sender);
    }

}