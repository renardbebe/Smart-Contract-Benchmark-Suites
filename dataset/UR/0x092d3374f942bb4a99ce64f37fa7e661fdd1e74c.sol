 

pragma solidity ^0.4.17;

 

library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
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
}


contract Ownable {
    
    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public  returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BasicToken is ERC20Basic, Ownable {

    using SafeMath for uint256;

    mapping (address => uint256) balances;

    modifier onlyPayloadSize(uint size) {
        if (msg.data.length < size + 4) {
        revert();
        }
        _;
    }

     
    function transfer(address _to, uint256 _amount) public onlyPayloadSize(2 * 32) returns (bool) {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

     
    function balanceOf(address _addr) public constant returns (uint256) {
        return balances[_addr];
    }
}


contract AdvancedToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint256)) allowances;

     
    function transferFrom(address _from, address _to, uint256 _amount) public onlyPayloadSize(3 * 32) returns (bool) {
        require(allowances[_from][msg.sender] >= _amount && balances[_from] >= _amount);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_amount);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

     
    function approve(address _spender, uint256 _amount) public returns (bool) {
        require((_amount == 0) || (allowances[msg.sender][_spender] == 0));
        allowances[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }


     
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowances[_owner][_spender];
    }
}


contract MintableToken is AdvancedToken {

    bool public mintingFinished;

    event TokensMinted(address indexed to, uint256 amount);
    event MintingFinished();

     
    function mint(address _to, uint256 _amount) external onlyOwner onlyPayloadSize(2 * 32) returns (bool) {
        require(_to != 0x0 && _amount > 0 && !mintingFinished);
        balances[_to] = balances[_to].add(_amount);
        totalSupply = totalSupply.add(_amount);
        Transfer(0x0, _to, _amount);
        TokensMinted(_to, _amount);
        return true;
    }

     
    function finishMinting() external onlyOwner {
        require(!mintingFinished);
        mintingFinished = true;
        MintingFinished();
    }
    
     
    function mintingFinished() public constant returns (bool) {
        return mintingFinished;
    }
}


contract ACO is MintableToken {

    uint8 public decimals;
    string public name;
    string public symbol;

    function ACO() public {
        totalSupply = 0;
        decimals = 18;
        name = "ACO";
        symbol = "ACO";
    }
}


contract MultiOwnable {
    
    address[2] public owners;

    event OwnershipTransferred(address from, address to);
    event OwnershipGranted(address to);

    function MultiOwnable() public {
        owners[0] = 0x1d554c421182a94E2f4cBD833f24682BBe1eeFe8;  
        owners[1] = 0x0D7a2716466332Fc5a256FF0d20555A44c099453;  
    }

      
    modifier onlyOwners {
        require(msg.sender == owners[0] || msg.sender == owners[1]);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwners {
        require(_newOwner != 0x0 && _newOwner != owners[0] && _newOwner != owners[1]);
        if (msg.sender == owners[0]) {
            OwnershipTransferred(owners[0], _newOwner);
            owners[0] = _newOwner;
        } else {
            OwnershipTransferred(owners[1], _newOwner);
            owners[1] = _newOwner;
        }
    }
}


contract Crowdsale is MultiOwnable {

    using SafeMath for uint256;

    ACO public ACO_Token;

    address public constant MULTI_SIG = 0x3Ee28dA5eFe653402C5192054064F12a42EA709e;

    bool public success;
    uint256 public rate;
    uint256 public rateWithBonus;
    uint256 public tokensSold;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public minimumGoal;
    uint256 public cap;
    uint256[4] private bonusStages;

    mapping (address => uint256) investments;
    mapping (address => bool) hasAuthorizedWithdrawal;

    event TokensPurchased(address indexed by, uint256 amount);
    event RefundIssued(address indexed by, uint256 amount);
    event FundsWithdrawn(address indexed by, uint256 amount);
    event IcoSuccess();
    event CapReached();

    function Crowdsale() public {
        ACO_Token = new ACO();
        minimumGoal = 3000 ether;
        cap = 87500 ether;
        rate = 4000;
        startTime = now.add(3 days);
        endTime = startTime.add(90 days);
        bonusStages[0] = startTime.add(14 days);

        for (uint i = 1; i < bonusStages.length; i++) {
            bonusStages[i] = bonusStages[i - 1].add(14 days);
        }
    }

     
    function() public payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != 0x0 && validPurchase() && weiRaised().sub(msg.value) < cap);
        if (this.balance >= minimumGoal && !success) {
            success = true;
            IcoSuccess();
        }
        uint256 weiAmount = msg.value;
        if (this.balance > cap) {
            CapReached();
            uint256 toRefund = this.balance.sub(cap);
            msg.sender.transfer(toRefund);
            weiAmount = weiAmount.sub(toRefund);
        }
        uint256 tokens = weiAmount.mul(getCurrentRateWithBonus());
        ACO_Token.mint(_beneficiary, tokens);
        tokensSold = tokensSold.add(tokens);
        investments[_beneficiary] = investments[_beneficiary].add(weiAmount);
        TokensPurchased(_beneficiary, tokens);
    }

     
    function getCurrentRateWithBonus() public returns (uint256) {
        rateWithBonus = (rate.mul(getBonusPercentage()).div(100)).add(rate);
        return rateWithBonus;
    }

     
    function getBonusPercentage() internal view returns (uint256 bonusPercentage) {
        uint256 timeStamp = now;
        if (timeStamp > bonusStages[3]) {
            bonusPercentage = 0;
        } else { 
            bonusPercentage = 25;
            for (uint i = 0; i < bonusStages.length; i++) {
                if (timeStamp <= bonusStages[i]) {
                    break;
                } else {
                    bonusPercentage = bonusPercentage.sub(5);
                }
            }
        }
        return bonusPercentage;
    }

     
    function currentRate() public constant returns (uint256) {
        return rateWithBonus;
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }
    
     
    function getRefund(address _addr) public {
        if (_addr == 0x0) {
            _addr = msg.sender;
        }
        require(!isSuccess() && hasEnded() && investments[_addr] > 0);
        uint256 toRefund = investments[_addr];
        investments[_addr] = 0;
        _addr.transfer(toRefund);
        RefundIssued(_addr, toRefund);
    }

     
    function authorizeWithdrawal() public onlyOwners {
        require(hasEnded() && isSuccess() && !hasAuthorizedWithdrawal[msg.sender]);
        hasAuthorizedWithdrawal[msg.sender] = true;
        if (hasAuthorizedWithdrawal[owners[0]] && hasAuthorizedWithdrawal[owners[1]]) {
            FundsWithdrawn(owners[0], this.balance);
            MULTI_SIG.transfer(this.balance);
        }
    }
    
     
    function issueBounty(address _to, uint256 _amount) public onlyOwners {
        require(_to != 0x0 && _amount > 0);
        ACO_Token.mint(_to, _amount);
    }
    
     
    function finishMinting() public onlyOwners {
        require(hasEnded());
        ACO_Token.finishMinting();
    }

     
    function minimumGoal() public constant returns (uint256) {
        return minimumGoal;
    }

     
    function cap() public constant returns (uint256) {
        return cap;
    }

     
    function endTime() public constant returns (uint256) {
        return endTime;
    }

     
    function investmentOf(address _addr) public constant returns (uint256) {
        return investments[_addr];
    }

     
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }

     
    function isSuccess() public constant returns (bool) {
        return success;
    }

     
    function weiRaised() public constant returns (uint256) {
        return this.balance;
    }
}