 

pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(transfersEnabled);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(transfersEnabled);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
contract Ownable {
    address public owner;
    address public advisor;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        advisor = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == advisor);
        _;
    }


     
    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    function changeAdvisor(address newAdvisor) onlyOwner public {
        advisor = newAdvisor;
        OwnerChanged(advisor, newAdvisor);
    }

}

 

contract MintableToken is StandardToken, Ownable {
    string public constant name = "MCFit Token";
    string public constant symbol = "MCF";
    uint8 public constant decimals = 18;

    uint256 public totalAllocated = 0;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) canMint internal returns (bool) {

        require(!mintingFinished);
        totalAllocated = totalAllocated.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    function withDraw(address _investor) internal returns (bool) {

        require(mintingFinished);
        uint256 amount = balanceOf(_investor);
        require(amount <= totalAllocated);
        totalAllocated = totalAllocated.sub(amount);
        balances[_investor] = balances[_investor].sub(amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint internal returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

}

 
contract Crowdsale is Ownable {
    using SafeMath for uint256;

     
    uint256 public startTime;
    uint256 public endTime;
    bool public checkDate;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;
    uint256 public tokenRaised;
    bool public isFinalized = false;

    event Finalized();


    function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {

        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));

         
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        checkDate = false;
    }

     
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }

     
    function finalize() onlyOwner public {
        require(!isFinalized);
         

        finalization();
        Finalized();

        isFinalized = true;
    }

     
    function finalization() internal pure {
    }
}


contract MCFitCrowdsale is Ownable, Crowdsale, MintableToken {
    using SafeMath for uint256;

    enum State {Active, Closed}
    State public state;

    mapping(address => uint256) public deposited;
    uint256 public constant INITIAL_SUPPLY = 1 * (10**9) * (10 ** uint256(decimals));
    uint256 public fundReservCompany = 350 * (10**6) * (10 ** uint256(decimals));
    uint256 public fundTeamCompany = 300 * (10**6) * (10 ** uint256(decimals));
    uint256 public countInvestor;

    uint256 limit40Percent = 30*10**6*10**18;
    uint256 limit20Percent = 60*10**6*10**18;
    uint256 limit10Percent = 100*10**6*10**18;

    event Closed();
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);


    function MCFitCrowdsale(uint256 _startTime, uint256 _endTime,uint256 _rate, address _wallet) public
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        owner = _wallet;
         
        transfersEnabled = true;
        mintingFinished = false;
        state = State.Active;
        totalSupply = INITIAL_SUPPLY;
        bool resultMintFunds = mintToSpecialFund(owner);
        require(resultMintFunds);
    }

     
    function() payable public {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _investor) public payable returns (uint256){
        require(state == State.Active);
        require(_investor != address(0));
        if(checkDate){
            assert(now >= startTime && now < endTime);
        }
        uint256 weiAmount = msg.value;
         
        uint256 tokens = getTotalAmountOfTokens(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        mint(_investor, tokens);
        TokenPurchase(_investor, weiAmount, tokens);
        if(deposited[_investor] == 0){
            countInvestor = countInvestor.add(1);
        }
        deposit(_investor);
        wallet.transfer(weiAmount);
        return tokens;
    }

    function getTotalAmountOfTokens(uint256 _weiAmount) internal constant returns (uint256 amountOfTokens) {
        uint256 currentTokenRate = 0;
        uint256 currentDate = now;
         
        require(currentDate >= startTime);

        if (totalAllocated < limit40Percent && currentDate < endTime) {
            if(_weiAmount < 5 * 10**17){revert();}
            return currentTokenRate = _weiAmount.mul(rate*140);
        } else if (totalAllocated < limit20Percent && currentDate < endTime) {
            if(_weiAmount < 5 * 10**17){revert();}
            return currentTokenRate = _weiAmount.mul(rate*120);
        } else if (totalAllocated < limit10Percent && currentDate < endTime) {
            if(_weiAmount < 5 * 10**17){revert();}
            return currentTokenRate = _weiAmount.mul(rate*110);
        } else {
            return currentTokenRate = _weiAmount.mul(rate*100);
        }
    }

    function deposit(address investor) internal {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        if(checkDate){
            require(hasEnded());
        }
        state = State.Closed;
        transfersEnabled = false;
        finishMinting();
        Closed();
        finalize();
        wallet.transfer(this.balance);
    }

    function mintToSpecialFund(address _wallet) public onlyOwner returns (bool result) {
        result = false;
        require(_wallet != address(0));
        balances[_wallet] = balances[_wallet].add(fundReservCompany);
        balances[_wallet] = balances[_wallet].add(fundTeamCompany);
        result = true;
    }

    function changeRateUSD(uint256 _rate) onlyOwner public {
        require(state == State.Active);
        require(_rate > 0);
        rate = _rate;
    }

    function changeCheckDate(bool _state, uint256 _startTime, uint256 _endTime) onlyOwner public {
        require(state == State.Active);
        require(_startTime >= now);
        require(_endTime >= _startTime);

        checkDate = _state;
        startTime = _startTime;
        endTime = _endTime;
    }

    function getDeposited(address _investor) public view returns (uint256){
        return deposited[_investor];
    }

    function removeContract() public onlyOwner {
        selfdestruct(owner);
    }

}