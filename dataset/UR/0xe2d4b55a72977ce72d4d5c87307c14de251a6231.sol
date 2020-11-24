 

pragma solidity ^0.4.16;

contract owned {
    address public owner;

    constructor () public {
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

contract Trabet_Coin is owned {
     
    string public name = "Trabet Coin";
    string public symbol = "TC";
    uint8 public decimals = 4;
    uint256 public totalSupply = 7000000 * 10 ** uint256(decimals);

    bool public released = false;

     
    address public crowdsaleAgent;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
   
     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
    
     
    event FrozenFunds(address target, bool frozen);

     
    constructor () public {
        balanceOf[owner] = totalSupply;
    }
    modifier canTransfer() {
        require(released);
       _;
     }

    modifier onlyCrowdsaleAgent() {
        require(msg.sender == crowdsaleAgent);
        _;
    }

    function releaseToken() public onlyOwner {
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
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool success) {
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

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyCrowdsaleAgent public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
     
    function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner public {
        crowdsaleAgent = _crowdsaleAgent;
    }
}

contract Killable is owned {
    function kill() onlyOwner public {
        selfdestruct(owner);
    }
}

contract Trabet_Coin_PreICO is owned, Killable {
     
    Trabet_Coin public token;

     
    address public beneficiary;

     
    uint public startsAt = 1521748800;

     
    uint public endsAt = 1532563200;

     
    uint256 public TokenPerETH = 1065;

     
    bool public finalized = false;

     
    uint public tokensSold = 0;

     
    uint public weiRaised = 0;

     
    uint public investorCount = 0;

     
    uint public weiRefunded = 0;

     
    bool public reFunding = false;

     
    mapping (address => uint256) public investedAmountOf;

     
    event Invested(address investor, uint weiAmount, uint tokenAmount);
     
    event StartsAtChanged(uint startsAt);
     
    event EndsAtChanged(uint endsAt);
     
    event RateChanged(uint oldValue, uint newValue);
     
    event Refund(address investor, uint weiAmount);

    constructor (address _token, address _beneficiary) public {
        token = Trabet_Coin(_token);
        beneficiary = _beneficiary;
    }

    function investInternal(address receiver, address refer) private {
        require(!finalized);
        require(startsAt <= now && endsAt > now);
        require(msg.value >= 100000000000000);

        if(investedAmountOf[receiver] == 0) {
             
            investorCount++;
        }

         
        uint tokensAmount = msg.value * TokenPerETH / 100000000000000;
        investedAmountOf[receiver] += msg.value;
         
        tokensSold += tokensAmount;
        weiRaised += msg.value;

         
        emit Invested(receiver, msg.value, tokensAmount);

        token.mintToken(receiver, tokensAmount);

        if (refer != 0x0) {
            refer.transfer(msg.value/10);
        }

         
        beneficiary.transfer(address(this).balance);

    }

    function buy(address refer) public payable {
        investInternal(msg.sender, refer);
    }
    
    function () public payable {
        investInternal(msg.sender, 0x0);
    }
    
    function payforRefund () public payable {
    }
    function setStartsAt(uint time) onlyOwner public {
        require(!finalized);
        startsAt = time;
        emit StartsAtChanged(startsAt);
    }
    function setEndsAt(uint time) onlyOwner public {
        require(!finalized);
        endsAt = time;
        emit EndsAtChanged(endsAt);
    }
    function setRate(uint value) onlyOwner public {
        require(!finalized);
        require(value > 0);
        emit RateChanged(TokenPerETH, value);
        TokenPerETH = value;
    }

    function finalize() public onlyOwner {
         
        finalized = true;
    }

    function EnableRefund() public onlyOwner {
         
        reFunding = true;
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
         
        beneficiary = _beneficiary;
    }

     
    function refund() public {
        require(reFunding);
        uint256 weiValue = investedAmountOf[msg.sender];
        investedAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded + weiValue;
        emit Refund(msg.sender, weiValue);
        msg.sender.transfer(weiValue);
    }
}