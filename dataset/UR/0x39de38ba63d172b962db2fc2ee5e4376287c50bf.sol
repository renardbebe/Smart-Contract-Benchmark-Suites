 

pragma solidity ^0.4.15;

 
contract SafeMath {
  function mul(uint256 a, uint256 b) constant internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) constant internal returns (uint256) {
    assert(b != 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
    return c;
  }

  function sub(uint256 a, uint256 b) constant internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) constant internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
  function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) internal returns (uint256) {
      return div(mul(number, numerator), denominator);
  }
}


 
 

contract AbstractToken {
     
    function totalSupply() constant returns (uint256) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}

contract StandardToken is AbstractToken {
     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
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

}


contract ImmlaToken is StandardToken, SafeMath {
     
    string public constant name = "IMMLA";
    string public constant symbol = "IML";
    uint public constant decimals = 18;
    uint public constant supplyLimit = 550688955000000000000000000;
    
    address public icoContract = 0x0;
     
    
    modifier onlyIcoContract() {
         
        require(msg.sender == icoContract);
        _;
    }
    
     
    
     
     
    function ImmlaToken(address _icoContract) {
        assert(_icoContract != 0x0);
        icoContract = _icoContract;
    }
    
     
     
     
    function burnTokens(address _from, uint _value) onlyIcoContract {
        assert(_from != 0x0);
        require(_value > 0);
        
        balances[_from] = sub(balances[_from], _value);
    }
    
     
     
     
    function emitTokens(address _to, uint _value) onlyIcoContract {
        assert(_to != 0x0);
        require(_value > 0);
        
        balances[_to] = add(balances[_to], _value);
    }
}


contract ImmlaIco is SafeMath {
     
    ImmlaToken public immlaToken;
    AbstractToken public preIcoToken;

     
    address public escrow;
     
    address public icoManager;
     
    address public tokenImporter = 0x0;
     
    address public founder1;
    address public founder2;
    address public founder3;
    address public team;
    address public bountyOwner;
    
     
    uint public constant teamsReward = 38548226701232220000000000;
     
    uint public constant bountyOwnersTokens = 9361712198870680000000000;
    
     
    uint constant BASE = 1000000000000000000;
    
     
    uint public constant defaultIcoStart = 1505422800;
     
    uint public icoStart = defaultIcoStart;
    
     
    uint public constant defaultIcoDeadline = 1508101200;
     
    uint public  icoDeadline = defaultIcoDeadline;
    
     
    uint public constant defaultFoundersRewardTime = 1521061200;
     
    uint public foundersRewardTime = defaultFoundersRewardTime;
    
     
    uint public constant minIcoTokenLimit = 18000000 * BASE;
     
    uint public constant maxIcoTokenLimit = 434477177 * BASE;
    
     
    uint public importedTokens = 0;
     
    uint public soldTokensOnIco = 0;
     
    uint public constant soldTokensOnPreIco = 13232941687168431951684000;
    
     
     
    uint tokenPrice1 = 3640;
    uint tokenSupply1 = 170053520 * BASE;
    
     
     
    uint tokenPrice2 = 3549;
    uint tokenSupply2 = 103725856 * BASE;
    
     
     
    uint tokenPrice3 = 3458;
    uint tokenSupply3 = 100319718 * BASE;
    
     
     
    uint tokenPrice4 = 3367;
    uint tokenSupply4 = 60378083 * BASE;
    
     
    uint[] public tokenPrices;
     
    uint[] public tokenSupplies;
    
     
    bool public initialized = false;
     
    bool public migrated = false;
     
    bool public sentTokensToFounders = false;
     
    bool public icoStoppedManually = false;
    
     
    mapping (address => uint) public balances;
    
     
    
    event BuyTokens(address buyer, uint value, uint amount);
    event WithdrawEther();
    event StopIcoManually();
    event SendTokensToFounders(uint founder1Reward, uint founder2Reward, uint founder3Reward);
    event ReturnFundsFor(address account);
    
     
    
    modifier whenInitialized() {
         
        require(initialized);
        _;
    } 
    
    modifier onlyManager() {
         
        require(msg.sender == icoManager);
        _;
    }
    
    modifier onIcoRunning() {
         
        require(!icoStoppedManually && now >= icoStart && now <= icoDeadline);
        _;
    }
    
    modifier onGoalAchievedOrDeadline() {
         
        require(soldTokensOnIco >= minIcoTokenLimit || now > icoDeadline || icoStoppedManually);
        _;
    }
    
    modifier onIcoStopped() {
         
        require(icoStoppedManually || now > icoDeadline);
        _;
    }
    
    modifier notMigrated() {
         
        require(!migrated);
        _;
    }
    
     
     
     
     
     
     
     
     
     
    function ImmlaIco(address _icoManager, address _preIcoToken, 
        uint _icoStart, uint _icoDeadline, uint _foundersRewardTime) {
        assert(_preIcoToken != 0x0);
        assert(_icoManager != 0x0);
        
        immlaToken = new ImmlaToken(this);
        icoManager = _icoManager;
        preIcoToken = AbstractToken(_preIcoToken);
        
        if (_icoStart != 0) {
            icoStart = _icoStart;
        }
        if (_icoDeadline != 0) {
            icoDeadline = _icoDeadline;
        }
        if (_foundersRewardTime != 0) {
            foundersRewardTime = _foundersRewardTime;
        }
        
         
        tokenPrices.push(tokenPrice1);
        tokenPrices.push(tokenPrice2);
        tokenPrices.push(tokenPrice3);
        tokenPrices.push(tokenPrice4);
        
        tokenSupplies.push(tokenSupply1);
        tokenSupplies.push(tokenSupply2);
        tokenSupplies.push(tokenSupply3);
        tokenSupplies.push(tokenSupply4);
    }
    
     
     
     
     
     
     
     
     
    function init(
        address _founder1, address _founder2, address _founder3, 
        address _team, address _bountyOwner, address _escrow) onlyManager {
        assert(!initialized);
        assert(_founder1 != 0x0);
        assert(_founder2 != 0x0);
        assert(_founder3 != 0x0);
        assert(_team != 0x0);
        assert(_bountyOwner != 0x0);
        assert(_escrow != 0x0);
        
        founder1 = _founder1;
        founder2 = _founder2;
        founder3 = _founder3;
        team = _team;
        bountyOwner = _bountyOwner;
        escrow = _escrow;
        
        immlaToken.emitTokens(team, teamsReward);
        immlaToken.emitTokens(bountyOwner, bountyOwnersTokens);
        
        initialized = true;
    }
    
     
     
    function setNewManager(address _newIcoManager) onlyManager {
        assert(_newIcoManager != 0x0);
        
        icoManager = _newIcoManager;
    }
    
     
     
    function setNewTokenImporter(address _newTokenImporter) onlyManager {
        tokenImporter = _newTokenImporter;
    } 
    
     
    mapping (address => bool) private importedFromPreIco;
     
     
    function importTokens(address _account) {
         
        require(msg.sender == tokenImporter || msg.sender == icoManager || msg.sender == _account);
        require(!importedFromPreIco[_account]);
        
        uint preIcoBalance = preIcoToken.balanceOf(_account);
        if (preIcoBalance > 0) {
            immlaToken.emitTokens(_account, preIcoBalance);
            importedTokens = add(importedTokens, preIcoBalance);
        }
        
        importedFromPreIco[_account] = true;
    }
    
     
    function stopIco() onlyManager   {
        icoStoppedManually = true;
        StopIcoManually();
    }
    
     
    function withdrawEther() onGoalAchievedOrDeadline {
        if (soldTokensOnIco >= minIcoTokenLimit) {
            assert(initialized);
            assert(this.balance > 0);
            assert(msg.sender == icoManager);
            
            escrow.transfer(this.balance);
            WithdrawEther();
        } 
        else {
            returnFundsFor(msg.sender);
        }
    }
    
     
     
    function returnFundsFor(address _account) onGoalAchievedOrDeadline {
        assert(msg.sender == address(this) || msg.sender == icoManager || msg.sender == _account);
        assert(soldTokensOnIco < minIcoTokenLimit);
        assert(balances[_account] > 0);
        
        _account.transfer(balances[_account]);
        balances[_account] = 0;
        
        ReturnFundsFor(_account);
    }
    
     
     
    function countTokens(uint _weis) private returns(uint) { 
        uint result = 0;
        uint stage;
        for (stage = 0; stage < 4; stage++) {
            if (_weis == 0) {
                break;
            }
            if (tokenSupplies[stage] == 0) {
                continue;
            }
            uint maxTokenAmount = tokenPrices[stage] * _weis;
            if (maxTokenAmount <= tokenSupplies[stage]) {
                result = add(result, maxTokenAmount);
                break;
            }
            result = add(result, tokenSupplies[stage]);
            _weis = sub(_weis, div(tokenSupplies[stage], tokenPrices[stage]));
        }
        
        if (stage == 4) {
            result = add(result, tokenPrices[3] * _weis);
        }
        
        return result;
    }
    
     
     
    function removeTokens(uint _amount) private {
        for (uint i = 0; i < 4; i++) {
            if (_amount == 0) {
                break;
            }
            if (tokenSupplies[i] > _amount) {
                tokenSupplies[i] = sub(tokenSupplies[i], _amount);
                break;
            }
            _amount = sub(_amount, tokenSupplies[i]);
            tokenSupplies[i] = 0;
        }
    }
    
     
     
    function buyTokens(address _buyer) private {
        assert(_buyer != 0x0);
        require(msg.value > 0);
        require(soldTokensOnIco < maxIcoTokenLimit);
        
        uint boughtTokens = countTokens(msg.value);
        assert(add(soldTokensOnIco, boughtTokens) <= maxIcoTokenLimit);
        
        removeTokens(boughtTokens);
        soldTokensOnIco = add(soldTokensOnIco, boughtTokens);
        immlaToken.emitTokens(_buyer, boughtTokens);
        
        balances[_buyer] = add(balances[_buyer], msg.value);
        
        BuyTokens(_buyer, msg.value, boughtTokens);
    }
    
     
    function () payable onIcoRunning {
        buyTokens(msg.sender);
    }
    
     
     
    function burnTokens(address _from, uint _value) onlyManager notMigrated {
        immlaToken.burnTokens(_from, _value);
    }
    
     
    function setStateMigrated() onlyManager {
        migrated = true;
    }
    
     
     
     
     
    function sendTokensToFounders() onlyManager whenInitialized {
        require(!sentTokensToFounders && now >= foundersRewardTime);
        
         
        uint totalCountOfTokens = mulByFraction(add(soldTokensOnIco, soldTokensOnPreIco), 1000, 813);
        uint totalRewardToFounders = mulByFraction(totalCountOfTokens, 1, 10);
        
        uint founder1Reward = mulByFraction(totalRewardToFounders, 43, 100);
        uint founder2Reward = mulByFraction(totalRewardToFounders, 43, 100);
        uint founder3Reward = mulByFraction(totalRewardToFounders, 14, 100);
        immlaToken.emitTokens(founder1, founder1Reward);
        immlaToken.emitTokens(founder2, founder2Reward);
        immlaToken.emitTokens(founder3, founder3Reward);
        SendTokensToFounders(founder1Reward, founder2Reward, founder3Reward);
        sentTokensToFounders = true;
    }
}