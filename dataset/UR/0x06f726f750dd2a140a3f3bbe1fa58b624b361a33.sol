 

pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract RajTest is owned {
     
    string public name = "RajTest";
    string public symbol = "RT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
    
    uint256 public sellPrice = 1045;
    uint256 public buyPrice = 1045;

    bool public released = false;
    
     
    address public crowdsaleAgent;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
   
     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event FrozenFunds(address target, bool frozen);

     
    function RajTest() public {
    }
    modifier canTransfer() {
        require(released);
       _;
     }

    modifier onlyCrowdsaleAgent() {
        require(msg.sender == crowdsaleAgent);
        _;
    }

    function releaseTokenTransfer() public onlyCrowdsaleAgent {
        released = true;
    }
     
    function _transfer(address _from, address _to, uint _value) canTransfer internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        require(!frozenAccount[_from]);
         
        require(!frozenAccount[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyCrowdsaleAgent public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     
    function buy() payable public {
        uint amount = msg.value / buyPrice;                
        _transfer(this, msg.sender, amount);               
    }

     
     
    function sell(uint256 amount) canTransfer public {
        require(this.balance >= amount * sellPrice);       
        _transfer(msg.sender, this, amount);               
        msg.sender.transfer(amount * sellPrice);           
    }

     
     
    function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner public {
        crowdsaleAgent = _crowdsaleAgent;
    }
}

contract Killable is owned {
    function kill() onlyOwner {
        selfdestruct(owner);
    }
}

contract RajTestICO is owned, Killable {
     
    RajTest public token;

     
    string public state = "Pre ICO";

     
    uint public startsAt = 1521721800;

     
    uint public endsAt = 1521723600;

     
    uint256 public TokenPerETH = 1045;

     
    bool public finalized = false;

     
    uint public tokensSold = 0;

     
    uint public weiRaised = 0;

     
    uint public investorCount = 0;

     
    mapping (address => uint256) public investedAmountOf;

     
    mapping (address => uint256) public tokenAmountOf;

     
    event Invested(address investor, uint weiAmount, uint tokenAmount);
     
    event EndsAtChanged(uint endsAt);
     
    event RateChanged(uint oldValue, uint newValue);

    function RajTestICO(address _token) {
        token = RajTest(_token);
    }

    function investInternal(address receiver) private {
        require(!finalized);
        require(startsAt <= now && endsAt > now);

        if(investedAmountOf[receiver] == 0) {
             
            investorCount++;
        }

         
        uint tokensAmount = msg.value * TokenPerETH;
        investedAmountOf[receiver] += msg.value;
        tokenAmountOf[receiver] += tokensAmount;
         
        tokensSold += tokensAmount;
        weiRaised += msg.value;

         
        Invested(receiver, msg.value, tokensAmount);

        token.mintToken(receiver, tokensAmount);
    }

    function buy() public payable {
        investInternal(msg.sender);
    }

    function() payable {
        buy();
    }

    function setEndsAt(uint time) onlyOwner {
        require(!finalized);
        endsAt = time;
        EndsAtChanged(endsAt);
    }
    function setRate(uint value) onlyOwner {
        require(!finalized);
        require(value > 0);
        RateChanged(TokenPerETH, value);
        TokenPerETH = value;
    }

    function finalize(address receiver) public onlyOwner {
        require(endsAt < now);
         
        finalized = true;
         
        token.releaseTokenTransfer();
         
        receiver.transfer(this.balance);
    }
}