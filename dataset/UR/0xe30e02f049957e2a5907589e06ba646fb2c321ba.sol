 

pragma solidity ^0.4.15;

 
contract InputValidator {

     
    modifier safe_arguments(uint _numArgs) {
        assert(msg.data.length == _numArgs * 32 + 4);
        _;
    }
}


 
contract IMultiOwned {

     
    function isOwner(address _account) constant returns (bool);


     
    function getOwnerCount() constant returns (uint);


     
    function getOwnerAt(uint _index) constant returns (address);


      
    function addOwner(address _account);


     
    function removeOwner(address _account);
}


 
contract MultiOwned is IMultiOwned {

     
    mapping (address => uint) private owners;
    address[] private ownersIndex;


      
    modifier only_owner() {
        require(isOwner(msg.sender));
        _;
    }


     
    function MultiOwned() {
        ownersIndex.push(msg.sender);
        owners[msg.sender] = 0;
    }


     
    function isOwner(address _account) public constant returns (bool) {
        return owners[_account] < ownersIndex.length && _account == ownersIndex[owners[_account]];
    }


     
    function getOwnerCount() public constant returns (uint) {
        return ownersIndex.length;
    }


     
    function getOwnerAt(uint _index) public constant returns (address) {
        return ownersIndex[_index];
    }


     
    function addOwner(address _account) public only_owner {
        if (!isOwner(_account)) {
            owners[_account] = ownersIndex.push(_account) - 1;
        }
    }


     
    function removeOwner(address _account) public only_owner {
        if (isOwner(_account)) {
            uint indexToDelete = owners[_account];
            address keyToMove = ownersIndex[ownersIndex.length - 1];
            ownersIndex[indexToDelete] = keyToMove;
            owners[keyToMove] = indexToDelete; 
            ownersIndex.length--;
        }
    }
}


 
contract ITokenRetriever {

     
    function retrieveTokens(address _tokenContract);
}


 
contract TokenRetriever is ITokenRetriever {

     
    function retrieveTokens(address _tokenContract) public {
        IToken tokenInstance = IToken(_tokenContract);
        uint tokenBalance = tokenInstance.balanceOf(this);
        if (tokenBalance > 0) {
            tokenInstance.transfer(msg.sender, tokenBalance);
        }
    }
}


 
contract IObservable {

     
    function isObserver(address _account) constant returns (bool);


     
    function getObserverCount() constant returns (uint);


     
    function getObserverAtIndex(uint _index) constant returns (address);


     
    function registerObserver(address _observer);


     
    function unregisterObserver(address _observer);
}


 
contract Observable is IObservable {

     
    mapping(address => uint) private observers;
    address[] private observerIndex;


     
    function isObserver(address _account) public constant returns (bool) {
        return observers[_account] < observerIndex.length && _account == observerIndex[observers[_account]];
    }


     
    function getObserverCount() public constant returns (uint) {
        return observerIndex.length;
    }


     
    function getObserverAtIndex(uint _index) public constant returns (address) {
        return observerIndex[_index];
    }


     
    function registerObserver(address _observer) public {
        require(canRegisterObserver(_observer));
        if (!isObserver(_observer)) {
            observers[_observer] = observerIndex.push(_observer) - 1;
        }
    }


     
    function unregisterObserver(address _observer) public {
        require(canUnregisterObserver(_observer));
        if (isObserver(_observer)) {
            uint indexToDelete = observers[_observer];
            address keyToMove = observerIndex[observerIndex.length - 1];
            observerIndex[indexToDelete] = keyToMove;
            observers[keyToMove] = indexToDelete;
            observerIndex.length--;
        }
    }


     
    function canRegisterObserver(address _observer) internal constant returns (bool);


     
    function canUnregisterObserver(address _observer) internal constant returns (bool);
}


 
contract ITokenObserver {

     
    function notifyTokensReceived(address _from, uint _value);
}


 
contract IToken { 

     
    function totalSupply() constant returns (uint);


     
    function balanceOf(address _owner) constant returns (uint);


     
    function transfer(address _to, uint _value) returns (bool);


     
    function transferFrom(address _from, address _to, uint _value) returns (bool);


     
    function approve(address _spender, uint _value) returns (bool);


     
    function allowance(address _owner, address _spender) constant returns (uint);
}


 
contract Token is IToken, InputValidator {

     
    string public standard = "Token 0.3";
    string public name;        
    string public symbol;
    uint8 public decimals;

     
    uint internal totalTokenSupply;

     
    mapping (address => uint) internal balances;

     
    mapping (address => mapping (address => uint)) internal allowed;


     
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

     
    function Token(string _name, string _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[msg.sender] = 0;
        totalTokenSupply = 0;
    }


     
    function totalSupply() public constant returns (uint) {
        return totalTokenSupply;
    }


     
    function balanceOf(address _owner) public constant returns (uint) {
        return balances[_owner];
    }


     
    function transfer(address _to, uint _value) public safe_arguments(2) returns (bool) {

         
        require(balances[msg.sender] >= _value);   

         
        require(balances[_to] + _value >= balances[_to]);

         
        balances[msg.sender] -= _value;
        balances[_to] += _value;

         
        Transfer(msg.sender, _to, _value);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint _value) public safe_arguments(3) returns (bool) {

         
        require(balances[_from] >= _value);

         
        require(balances[_to] + _value >= balances[_to]);

         
        require(_value <= allowed[_from][msg.sender]);

         
        balances[_to] += _value;
        balances[_from] -= _value;

         
        allowed[_from][msg.sender] -= _value;

         
        Transfer(_from, _to, _value);
        return true;
    }


     
    function approve(address _spender, uint _value) public safe_arguments(2) returns (bool) {

         
        allowed[msg.sender][_spender] = _value;

         
        Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function allowance(address _owner, address _spender) public constant returns (uint) {
      return allowed[_owner][_spender];
    }
}


 
contract IManagedToken is IToken { 

     
    function isLocked() constant returns (bool);


     
    function lock() returns (bool);


     
    function unlock() returns (bool);


     
    function issue(address _to, uint _value) returns (bool);


     
    function burn(address _from, uint _value) returns (bool);
}


 
contract ManagedToken is IManagedToken, Token, MultiOwned {

     
    bool internal locked;


     
    modifier only_when_unlocked() {
        require(!locked);
        _;
    }


     
    function ManagedToken(string _name, string _symbol, uint8 _decimals, bool _locked) 
        Token(_name, _symbol, _decimals) {
        locked = _locked;
    }


     
    function transfer(address _to, uint _value) public only_when_unlocked returns (bool) {
        return super.transfer(_to, _value);
    }


     
    function transferFrom(address _from, address _to, uint _value) public only_when_unlocked returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }


     
    function approve(address _spender, uint _value) public returns (bool) {
        return super.approve(_spender, _value);
    }


     
    function isLocked() public constant returns (bool) {
        return locked;
    }


     
    function lock() public only_owner returns (bool)  {
        locked = true;
        return locked;
    }


     
    function unlock() public only_owner returns (bool)  {
        locked = false;
        return !locked;
    }


     
    function issue(address _to, uint _value) public only_owner safe_arguments(2) returns (bool) {
        
         
        require(balances[_to] + _value >= balances[_to]);

         
        balances[_to] += _value;
        totalTokenSupply += _value;

         
        Transfer(0, this, _value);
        Transfer(this, _to, _value);
        return true;
    }


     
    function burn(address _from, uint _value) public only_owner safe_arguments(2) returns (bool) {

         
        require(balances[_from] >= _value);

         
        require(balances[_from] - _value <= balances[_from]);

         
        balances[_from] -= _value;
        totalTokenSupply -= _value;

         
        Transfer(_from, 0, _value);
        return true;
    }
}


 
contract DRPUToken is ManagedToken, Observable, TokenRetriever {

     
    function DRPUToken() ManagedToken("DRP Utility", "DRPU", 8, false) {}


     
    function canRegisterObserver(address _observer) internal constant returns (bool) {
        return _observer != address(this) && isOwner(msg.sender);
    }


     
    function canUnregisterObserver(address _observer) internal constant returns (bool) {
        return msg.sender == _observer || isOwner(msg.sender);
    }


     
    function transfer(address _to, uint _value) public returns (bool) {
        bool result = super.transfer(_to, _value);
        if (isObserver(_to)) {
            ITokenObserver(_to).notifyTokensReceived(msg.sender, _value);
        }

        return result;
    }


     
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        bool result = super.transferFrom(_from, _to, _value);
        if (isObserver(_to)) {
            ITokenObserver(_to).notifyTokensReceived(_from, _value);
        }

        return result;
    }


     
    function retrieveTokens(address _tokenContract) public only_owner {
        super.retrieveTokens(_tokenContract);
    }


     
    function () payable {
        revert();
    }
}