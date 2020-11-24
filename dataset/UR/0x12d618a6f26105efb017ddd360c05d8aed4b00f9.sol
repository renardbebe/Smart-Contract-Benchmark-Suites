 

pragma solidity ^0.4.23;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
contract Ownable {
    address public owner;

     
     
    constructor()  public {
        owner = msg.sender;
    } 

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract RAcoinToken is Ownable, ERC20Interface {
    string public constant symbol = "RAC";
    string public constant name = "RAcoinToken";
    uint private _totalSupply;
    uint public constant decimals = 18;
    uint private unmintedTokens = 20000000000*uint(10)**decimals; 
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
     
    struct LockupRecord {
        uint amount;
        uint unlockTime;
    }
    
     
    mapping(address => uint) balances;
    
     
    mapping(address => mapping (address => uint)) allowed; 
    
     
    mapping(address => LockupRecord)balancesLockup;



     

     
    uint public reservingPercentage = 1;
    
     
     
    uint public jackpotMinimumAmount = 100000 * uint(10)**decimals; 
    
     
     
     
     
    uint public reservingStep = 10000 * uint(10)**decimals; 
    
     
     
    uint private seed = 1;  
    
     
     
    int public maxAllowedManualDistribution = 111; 

     
    bool public clearJackpotParticipantsAfterDistribution = false;

     
    uint private index = 0; 

     
    address[] private jackpotParticipants; 

    event SetReservingPercentage(uint _value);
    event SetReservingStep(uint _value);
    event SetJackpotMinimumAmount(uint _value);
    event AddAddressToJackpotParticipants(address indexed _sender, uint _times);
    
     
    function setReservingPercentage(uint _value) public onlyOwner returns (bool success) {
        assert(_value > 0 && _value < 100);
        
        reservingPercentage = _value;
        emit SetReservingPercentage(_value);
        return true;
    }
    
     
    function setReservingStep(uint _value) public onlyOwner returns (bool success) {
        assert(_value > 0);
        reservingStep = _value;
        emit SetReservingStep(_value);
        return true;
    }
    
     
    function setJackpotMinimumAmount(uint _value) public onlyOwner returns (bool success) {
        jackpotMinimumAmount = _value;
        emit SetJackpotMinimumAmount(_value);
        return true;
    }

     
    function setPoliticsForJackpotParticipantsList(bool _clearAfterDistribution) public onlyOwner returns (bool success) {
        clearJackpotParticipantsAfterDistribution = _clearAfterDistribution;
        return true;
    }
    
     
    function clearJackpotParticipants() public onlyOwner returns (bool success) {
        index = 0;
        return true;
    }
    
     
     
    function transferWithReserving(address _to, uint _totalTransfer) public returns (bool success) {
        uint netTransfer = _totalTransfer * (100 - reservingPercentage) / 100; 
        require(balances[msg.sender] >= _totalTransfer && (_totalTransfer > netTransfer));
        
        if (transferMain(msg.sender, _to, netTransfer) && (_totalTransfer >= reservingStep)) {
            processJackpotDeposit(_totalTransfer, netTransfer, msg.sender);
        }
        return true;
    }

     
     
    function transferWithReservingNet(address _to, uint _netTransfer) public returns (bool success) {
        uint totalTransfer = _netTransfer * (100 + reservingPercentage) / 100; 
        require(balances[msg.sender] >= totalTransfer && (totalTransfer > _netTransfer));
        
        if (transferMain(msg.sender, _to, _netTransfer) && (totalTransfer >= reservingStep)) {
            processJackpotDeposit(totalTransfer, _netTransfer, msg.sender);
        }
        return true;
    }

     
     
    function transferFromWithReserving(address _from, address _to, uint _totalTransfer) public returns (bool success) {
        uint netTransfer = _totalTransfer * (100 - reservingPercentage) / 100; 
        require(balances[_from] >= _totalTransfer && (_totalTransfer > netTransfer));
        
        if (transferFrom(_from, _to, netTransfer) && (_totalTransfer >= reservingStep)) {
            processJackpotDeposit(_totalTransfer, netTransfer, _from);
        }
        return true;
    }

     
     
    function transferFromWithReservingNet(address _from, address _to, uint _netTransfer) public returns (bool success) {
        uint totalTransfer = _netTransfer * (100 + reservingPercentage) / 100; 
        require(balances[_from] >= totalTransfer && (totalTransfer > _netTransfer));

        if (transferFrom(_from, _to, _netTransfer) && (totalTransfer >= reservingStep)) {
            processJackpotDeposit(totalTransfer, _netTransfer, _from);
        }
        return true;
    }

     
    function processJackpotDeposit(uint _totalTransfer, uint _netTransfer, address _participant) private returns (bool success) {
        addAddressToJackpotParticipants(_participant, _totalTransfer);

        uint jackpotDeposit = _totalTransfer - _netTransfer;
        balances[_participant] -= jackpotDeposit;
        balances[0] += jackpotDeposit;

        emit Transfer(_participant, 0, jackpotDeposit);
        return true;
    }

     
    function addAddressToJackpotParticipants(address _participant, uint _transactionAmount) private returns (bool success) {
        uint timesToAdd = _transactionAmount / reservingStep;
        
        for (uint i = 0; i < timesToAdd; i++){
            if(index == jackpotParticipants.length) {
                jackpotParticipants.length += 1;
            }
            jackpotParticipants[index++] = _participant;
        }

        emit AddAddressToJackpotParticipants(_participant, timesToAdd);
        return true;        
    }
    
     
     
     
    function distributeJackpot(uint _nextSeed) public onlyOwner returns (bool success) {
        assert(balances[0] >= jackpotMinimumAmount);
        assert(_nextSeed > 0);

        uint additionalSeed = uint(blockhash(block.number - 1));
        uint rnd = 0;
        
        while(rnd < index) {
            rnd += additionalSeed * seed;
        }
        
        uint winner = rnd % index;
        balances[jackpotParticipants[winner]] += balances[0];
        emit Transfer(0, jackpotParticipants[winner], balances[0]);
        balances[0] = 0;
        seed = _nextSeed;

        if (clearJackpotParticipantsAfterDistribution) {
            clearJackpotParticipants();
        }
        return true;
    }

     
    function distributeTokenSaleJackpot(uint _nextSeed, uint _amount) public onlyOwner returns (bool success) {
        require (maxAllowedManualDistribution > 0);
        if (mintTokens(0, _amount) && distributeJackpot(_nextSeed)) {
            maxAllowedManualDistribution--;
        }
        return true;
    }



     
    
     
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

     
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        return transferMain(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        if (transferMain(_from, _to, _value)){
            allowed[_from][msg.sender] -= _value;
            return true;
        } else {
            return false;
        }
    }

     
    function transferMain(address _from, address _to, uint _value) private returns (bool success) {
        require(_to != address(0));
        assert(balances[_to] + _value >= balances[_to]);
        
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    


     

    function unlockOwnFunds() public returns (bool success) {
        return unlockFunds(msg.sender);
    }

    function unlockSupervisedFunds(address _from) public onlyOwner returns (bool success) {
        return unlockFunds(_from);
    }
    
    function unlockFunds(address _owner) private returns (bool success) {
        require(balancesLockup[_owner].unlockTime < now && balancesLockup[_owner].amount > 0);

        balances[_owner] += balancesLockup[_owner].amount;
        emit Transfer(_owner, _owner, balancesLockup[_owner].amount);
        balancesLockup[_owner].amount = 0;

        return true;
    }

    function balanceOfLockup(address _owner) public view returns (uint balance, uint unlockTime) {
        return (balancesLockup[_owner].amount, balancesLockup[_owner].unlockTime);
    }



     

     
    function mintTokens(address _target, uint _mintedAmount) public onlyOwner returns (bool success) {
        require(_mintedAmount <= unmintedTokens);
        balances[_target] += _mintedAmount;
        unmintedTokens -= _mintedAmount;
        _totalSupply += _mintedAmount;
        
        emit Transfer(1, _target, _mintedAmount); 
        return true;
    }

     
     
    function mintLockupTokens(address _target, uint _mintedAmount, uint _unlockTime) public onlyOwner returns (bool success) {
        require(_mintedAmount <= unmintedTokens);

        balancesLockup[_target].amount += _mintedAmount;
        balancesLockup[_target].unlockTime = _unlockTime;
        unmintedTokens -= _mintedAmount;
        _totalSupply += _mintedAmount;
        
        emit Transfer(1, _target, _mintedAmount);  
        return true;
    }

     
     
    function mintTokensWithIncludingInJackpot(address _target, uint _mintedAmount) public onlyOwner returns (bool success) {
        require(maxAllowedManualDistribution > 0);
        if (mintTokens(_target, _mintedAmount)) {
            addAddressToJackpotParticipants(_target, _mintedAmount);
        }
        return true;
    }

     
     
    function mintTokensWithApproval(address _target, uint _mintedAmount, address _spender) public onlyOwner returns (bool success) {
        require(_mintedAmount <= unmintedTokens);
        balances[_target] += _mintedAmount;
        unmintedTokens -= _mintedAmount;
        _totalSupply += _mintedAmount;
        allowed[_target][_spender] += _mintedAmount;
        
        emit Transfer(1, _target, _mintedAmount);
        return true;
    }

     
    function stopTokenMinting() public onlyOwner returns (bool success) {
        unmintedTokens = 0;
        return true;
    }
}