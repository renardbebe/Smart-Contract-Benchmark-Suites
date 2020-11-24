 

pragma solidity ^0.4.19;

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;}

contract Owned {
    address public owner;
    address public supporter;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SupporterTransferred(address indexed previousSupporter, address indexed newSupporter);

    function Owned() public {
        owner = msg.sender;
        supporter = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerOrSupporter {
        require(msg.sender == owner || msg.sender == supporter);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function transferSupporter(address newSupporter) public onlyOwner {
        require(newSupporter != address(0));
        SupporterTransferred(supporter, newSupporter);
        supporter = newSupporter;
    }
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

contract CryptoMarketShortCoin is Owned {
    using SafeMath for uint256;

    string public name = "CRYPTO MARKET SHORT COIN";
    string public symbol = "CMSC";
    string public version = "2.0";
    uint8 public decimals = 18;
    uint256 public decimalsFactor = 10 ** 18;

    uint256 public totalSupply;
    uint256 public marketCap;
    uint256 public buyFactor = 12500;
    uint256 public buyFactorPromotion = 15000;
    uint8 public promotionsAvailable = 50;

    bool public buyAllowed = true;

     
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    event Mint(address indexed to, uint256 amount);

     
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

     
    function CryptoMarketShortCoin(uint256 initialMarketCap) {
        totalSupply = 100000000000000000000000000;  
        marketCap = initialMarketCap;
        balanceOf[msg.sender] = 20000000000000000000000000;  
        balanceOf[this] = 80000000000000000000000000;  
        allowance[this][owner] = totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256 _balance) {
         
        return balanceOf[_owner];
    }

    function allowanceOf(address _address) public constant returns (uint256 _allowance) {
        return allowance[_address][msg.sender];
    }

    function totalSupply() public constant returns (uint256 _totalSupply) {
        return totalSupply;
    }

    function circulatingSupply() public constant returns (uint256 _circulatingSupply) {
        return totalSupply.sub(balanceOf[owner]);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
         
        Transfer(_from, _to, _value);
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

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
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
         
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
         
        require(_value <= allowance[_from][msg.sender]);
         
        balanceOf[_from] -= _value;
         
        allowance[_from][msg.sender] -= _value;
         
        totalSupply -= _value;
         
        Burn(_from, _value);
        return true;
    }

     
    function () payable {
        require(buyAllowed);
         
        uint256 amount = calcAmount(msg.value);
         
        require(balanceOf[this] >= amount);
        if (promotionsAvailable > 0 && msg.value >= 100000000000000000) {  
            promotionsAvailable -= 1;
        }
        balanceOf[msg.sender] += amount;
         
        balanceOf[this] -= amount;
         
        Transfer(this, msg.sender, amount);
         
    }

     
    function calcAmount(uint256 value) private view returns (uint256 amount) {
        if (promotionsAvailable > 0 && value >= 100000000000000000) {  
            amount = msg.value.mul(buyFactorPromotion);
        }
        else {
            amount = msg.value.mul(buyFactor);
        }
        return amount;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        totalSupply = totalSupply += _amount;
        balanceOf[_to] = balanceOf[_to] += _amount;
        allowance[this][msg.sender] += _amount;
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     

     
    function updateMarketCap(uint256 _newMarketCap) public onlyOwnerOrSupporter returns (bool){
        uint256 newTokenCount = (balanceOf[this].mul((_newMarketCap.mul(decimalsFactor)).div(marketCap))).div(decimalsFactor);
         
         
        if (_newMarketCap < marketCap) {
            uint256 tokensToBurn = balanceOf[this].sub(newTokenCount);
            burnFrom(this, tokensToBurn);
        }
         
         
        else if (_newMarketCap > marketCap) {
            uint256 tokensToMint = newTokenCount.sub(balanceOf[this]);
            mint(this, tokensToMint);
        }
         
        marketCap = _newMarketCap;
        return true;
    }

     
    function wd(uint256 _amount) public onlyOwner {
        require(this.balance >= _amount);
        owner.transfer(_amount);
    }

     
    function updateBuyStatus(bool _buyAllowed) public onlyOwner {
        buyAllowed = _buyAllowed;
    }

     

    struct Bet {
        address bettor;
        string coin;
        uint256 betAmount;
        uint256 initialMarketCap;
        uint256 finalMarketCap;
        uint256 timeStampCreation;
        uint256 timeStampEvaluation;
        uint8 status;
         
        string auth;
    }

     
    mapping(uint256 => Bet) public betMapping;
    uint256 public numBets = 0;
    bool public bettingAllowed = true;
    uint256 public betFeeMin = 0;                            
    uint256 public betFeePerMil = 0;                         
    uint256 public betMaxAmount = 10000000000000000000000;   
    uint256 public betMinAmount = 1;                         

    event BetCreated(uint256 betId);
    event BetFinalized(uint256 betId);
    event BetFinalizeFailed(uint256 betId);
    event BetUpdated(uint256 betId);

     
    function createBet(
        string _coin,
        uint256 _betAmount,
        uint256 _initialMarketCap,
        uint256 _timeStampCreation,
        uint256 _timeStampEvaluation,
        string _auth) public returns (uint256 betId) {

         
        require(bettingAllowed == true);
        require(_betAmount <= betMaxAmount);
        require(_betAmount >= betMinAmount);
        require(_initialMarketCap > 0);

         
        uint256 fee = _betAmount.mul(betFeePerMil).div(1000);
        if(fee < betFeeMin) {
            fee = betFeeMin;
        }

         
        require(balanceOf[msg.sender] >= _betAmount.add(fee));

         
        _transfer(msg.sender, this, _betAmount.add(fee));

         
        numBets = numBets.add(1);
        betId = numBets;
        betMapping[betId].bettor = msg.sender;
        betMapping[betId].coin = _coin;
        betMapping[betId].betAmount = _betAmount;
        betMapping[betId].initialMarketCap = _initialMarketCap;
        betMapping[betId].finalMarketCap = 0;
        betMapping[betId].timeStampCreation = _timeStampCreation;
        betMapping[betId].timeStampEvaluation = _timeStampEvaluation;
        betMapping[betId].status = 0;
        betMapping[betId].auth = _auth;

        BetCreated(betId);

        return betId;
    }

     
    function getBet(uint256 betId) public constant returns(
        address bettor,
        string coin,
        uint256 betAmount,
        uint256 initialMarketCap,
        uint256 finalMarketCap,
        uint256 timeStampCreation,
        uint256 timeStampEvaluation,
        uint8 status,
        string auth) {

        Bet memory bet = betMapping[betId];

        return (
        bet.bettor,
        bet.coin,
        bet.betAmount,
        bet.initialMarketCap,
        bet.finalMarketCap,
        bet.timeStampCreation,
        bet.timeStampEvaluation,
        bet.status,
        bet.auth
        );
    }

     
    function finalizeBet(uint256 betId, uint256 currentTimeStamp, uint256 newMarketCap) public onlyOwnerOrSupporter {
        require(betId <= numBets && betMapping[betId].status < 10);
        require(currentTimeStamp >= betMapping[betId].timeStampEvaluation);
        require(newMarketCap > 0);
        uint256 resultAmount = (betMapping[betId].betAmount.mul(((betMapping[betId].initialMarketCap.mul(decimalsFactor)).div(uint256(newMarketCap))))).div(decimalsFactor);
         
         
        if(resultAmount <= betMapping[betId].betAmount.div(3) || resultAmount >= betMapping[betId].betAmount.mul(3)) {
            betMapping[betId].status = 99;
            BetFinalizeFailed(betId);
        }
        else {
             
            _transfer(this, betMapping[betId].bettor, resultAmount);
            betMapping[betId].finalMarketCap = newMarketCap;
            betMapping[betId].status = 10;
            BetFinalized(betId);
        }
    }

     
    function updateBet(uint256 betId, uint8 _status, uint256 _finalMarketCap) public onlyOwnerOrSupporter {
         
        require(_status != 10);
        betMapping[betId].status = _status;
        betMapping[betId].finalMarketCap = _finalMarketCap;
        BetUpdated(betId);
    }

     
    function updateBetRules(bool _bettingAllowed, uint256 _betFeeMin, uint256 _betFeePerMil, uint256 _betMinAmount, uint256 _betMaxAmount) public onlyOwner {
        bettingAllowed = _bettingAllowed;
        betFeeMin = _betFeeMin;
        betFeePerMil = _betFeePerMil;
        betMinAmount = _betMinAmount;
        betMaxAmount = _betMaxAmount;
    }
}