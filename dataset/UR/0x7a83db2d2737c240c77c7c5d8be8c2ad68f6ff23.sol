 

pragma solidity ^0.4.11;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract Gubberment {
    address public gubberment;
    address public newGubberment;
    event GubbermentOverthrown(address indexed _from, address indexed _to);

    function Gubberment() {
        gubberment = msg.sender;
    }

    modifier onlyGubberment {
        if (msg.sender != gubberment) throw;
        _;
    }

    function coupDetat(address _newGubberment) onlyGubberment {
        newGubberment = _newGubberment;
    }
 
    function gubbermentOverthrown() {
        if (msg.sender == newGubberment) {
            GubbermentOverthrown(gubberment, newGubberment);
            gubberment = newGubberment;
        }
    }
}


 
contract ERC20Token {
     
     
     
    mapping(address => uint) balances;

     
     
     
    mapping(address => mapping (address => uint)) allowed;

     
     
     
    uint public totalSupply;

     
     
     
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

     
     
     
    function transfer(address _to, uint _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
    function approve(
        address _spender,
        uint _amount
    ) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
    function allowance(
        address _owner, 
        address _spender
    ) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender,
        uint _value);
}


contract UselessReserveBank is ERC20Token, Gubberment {

     
     
     
    string public constant symbol = "URB";
    string public constant name = "Useless Reserve Bank";
    uint8 public constant decimals = 18;
    
    uint public constant WELFARE_HANDOUT = 1000;
    uint public constant ONEPERCENT_TOKENS_PER_ETH = 100000;
    uint public constant LIQUIDATION_TOKENS_PER_ETH = 30000;

    address[] public treasuryOfficials;
    uint public constant TAXRATE = 20;
    uint public constant LIQUIDATION_RESERVE_RATIO = 75;

    uint public totalTaxed;
    uint public totalBribery;
    uint public totalPilfered;

    uint public constant SENDING_BLOCK = 3999998; 

    function UselessReserveBank() {
        treasuryOfficials.push(0xDe18789c4d65DC8ecE671A4145F32F1590c4D802);
        treasuryOfficials.push(0x8899822D031891371afC369767511164Ef21e55c);
    }

     
     
     
    function () payable {
        uint tokens = WELFARE_HANDOUT * 1 ether;
        totalSupply += tokens;
        balances[msg.sender] += tokens;
        WelfareHandout(msg.sender, tokens, totalSupply, msg.value, 
            this.balance);
        Transfer(0x0, msg.sender, tokens);
    }
    event WelfareHandout(address indexed recipient, uint tokens, 
        uint newTotalSupply, uint ethers, uint newEtherBalance);


     
     
     
    function philanthropise(string name) payable {
         
        require(msg.value > 0);

         
        uint tokens = msg.value * ONEPERCENT_TOKENS_PER_ETH;

         
        balances[msg.sender] += tokens;
        totalSupply += tokens;

         
        uint taxAmount = msg.value * TAXRATE / 100;
        if (taxAmount > 0) {
            totalTaxed += taxAmount;
            uint taxPerOfficial = taxAmount / treasuryOfficials.length;
            for (uint i = 0; i < treasuryOfficials.length; i++) {
                treasuryOfficials[i].transfer(taxPerOfficial);
            }
        }

        Philanthropy(msg.sender, name, tokens, totalSupply, msg.value, 
            this.balance, totalTaxed);
        Transfer(0x0, msg.sender, tokens);
    }
    event Philanthropy(address indexed buyer, string name, uint tokens, 
        uint newTotalSupply, uint ethers, uint newEtherBalance,
        uint totalTaxed);


     
     
     
    function liquidate(uint amountOfTokens) {
         
        require(amountOfTokens <= balances[msg.sender]);

         
        balances[msg.sender] -= amountOfTokens;
        totalSupply -= amountOfTokens;

         
        uint ethersToSend = amountOfTokens / LIQUIDATION_TOKENS_PER_ETH;

         
        require(ethersToSend > 0 && 
            ethersToSend <= (this.balance * (100 - LIQUIDATION_RESERVE_RATIO) / 100));

         
        Liquidate(msg.sender, amountOfTokens, totalSupply, 
            ethersToSend, this.balance - ethersToSend);
        Transfer(msg.sender, 0x0, amountOfTokens);

         
        msg.sender.transfer(ethersToSend);
    }
    event Liquidate(address indexed seller, 
        uint tokens, uint newTotalSupply, 
        uint ethers, uint newEtherBalance);


     
     
     
    function bribe() payable {
         
        require(msg.value > 0);

         
        totalBribery += msg.value;
        Bribed(msg.value, totalBribery);

        uint bribePerOfficial = msg.value / treasuryOfficials.length;
        for (uint i = 0; i < treasuryOfficials.length; i++) {
            treasuryOfficials[i].transfer(bribePerOfficial);
        }
    }
    event Bribed(uint amount, uint newTotalBribery);


     
     
     
    function pilfer(uint amount) onlyGubberment {
         
        require(amount > this.balance);

         
        totalPilfered += amount;
        Pilfered(amount, totalPilfered, this.balance - amount);

        uint amountPerOfficial = amount / treasuryOfficials.length;
        for (uint i = 0; i < treasuryOfficials.length; i++) {
            treasuryOfficials[i].transfer(amountPerOfficial);
        }
    }
    event Pilfered(uint amount, uint totalPilfered, 
        uint newEtherBalance);


     
     
     
    function acceptGiftTokens(address tokenAddress) 
      onlyGubberment returns (bool success) 
    {
        ERC20Token token = ERC20Token(tokenAddress);
        uint amount = token.balanceOf(this);
        return token.transfer(gubberment, amount);
    }


     
     
     
    function replaceOfficials(address[] newOfficials) onlyGubberment {
        treasuryOfficials = newOfficials;
    }


     
     
     
    function currentEtherBalance() constant returns (uint) {
        return this.balance;
    }

    function currentTokenBalance() constant returns (uint) {
        return totalSupply;
    }

    function numberOfTreasuryOfficials() constant returns (uint) {
        return treasuryOfficials.length;
    }
}