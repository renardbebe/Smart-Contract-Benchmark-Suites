 

pragma solidity ^0.4.24;

contract ERC20Interface {
    function name() public constant returns (string);
    function symbol() public constant returns (string);
    function decimals() public constant returns (uint8);
    function totalSupply() public constant returns (uint);
    function balanceOf(address _owner) public constant returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    function transferFrom(address _from, address _to, uint _value) public returns (bool);
    function approve(address _spender, uint _value) public returns (bool);
    function allowance(address _owner, address _spender) public constant returns (uint);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract WeduToken is ERC20Interface {
     
    string private TOKEN_NAME;
    string private TOKEN_SYMBOL;
    uint8 private DECIMAL;
    uint private WEDU_UNIT;

     
    address owner;
    mapping(address => bool) internal blackList;

     
    uint private totalSupplyValue;
    struct BalanceType {
        uint locked;
        uint unlocked;
    }

    mapping(address => mapping (address => uint)) internal allowed;
    mapping(address => BalanceType) internal balanceValue;


     
    modifier onlyOwner() { require(owner == msg.sender, "Not a owner"); _;}

     
    event ChangeNumberofToken(uint oldValue, uint newValue);

     
    constructor() public {
        TOKEN_NAME = "Educo-op";
        TOKEN_SYMBOL = "WEDU";

        DECIMAL = 18;
        WEDU_UNIT = 1000000000000000000;
        totalSupplyValue = 10000000000 * WEDU_UNIT;

        owner = msg.sender;
        balanceValue[owner].unlocked = totalSupplyValue;
    }

     
    function name() public constant returns (string){ return TOKEN_NAME; }
    function symbol() public constant returns (string){ return TOKEN_SYMBOL; }
    function decimals() public constant returns (uint8){ return DECIMAL; }
    function totalSupply() public constant returns (uint){ return totalSupplyValue; }

     
    function balanceOf(address _user) public constant returns (uint){ return balanceValue[_user].unlocked+balanceValue[_user].locked; }
    function balanceOfLocked(address _user) public constant returns (uint){ return balanceValue[_user].locked; }
    function balanceOfUnlocked(address _user) public constant returns (uint){ return balanceValue[_user].unlocked; }

     
    function lockBalance(address _who, uint _value) public onlyOwner {
         
        require(_value <= balanceValue[_who].unlocked, "Unsufficient balance");

        uint totalBalanceValue = balanceValue[_who].locked + balanceValue[_who].unlocked;

        balanceValue[_who].unlocked -= _value;
        balanceValue[_who].locked += _value;

        assert(totalBalanceValue == balanceValue[_who].locked + balanceValue[_who].unlocked);
    }

     
    function unlockBalance(address _who, uint _value) public onlyOwner {
         
        require(_value <= balanceValue[_who].locked, "Unsufficient balance");

        uint totalBalanceValue = balanceValue[_who].locked + balanceValue[_who].unlocked;

        balanceValue[_who].locked -= _value;
        balanceValue[_who].unlocked += _value;

        assert(totalBalanceValue == balanceValue[_who].locked + balanceValue[_who].unlocked);
    }

     
    function _transfer(address _from, address _to, uint _value) internal returns (bool){
         
        require(_from != address(0), "Address is wrong");
        require(_from != owner, "Owner uses the privateTransfer");
        require(_to != address(0), "Address is wrong");

         
        require(!blackList[_from], "Sender in blacklist");
        require(!blackList[_to], "Receiver in blacklist");

         
        require(_value <= balanceValue[_from].unlocked, "Unsufficient balance");
        require(balanceValue[_to].unlocked <= balanceValue[_to].unlocked + _value, "Overflow");

        uint previousBalances = balanceValue[_from].unlocked + balanceValue[_to].unlocked;

        balanceValue[_from].unlocked -= _value;
        balanceValue[_to].unlocked += _value;

        emit Transfer(_from, _to, _value);

        assert(balanceValue[_from].unlocked + balanceValue[_to].unlocked == previousBalances);
        return true;
    }

    function transfer(address _to, uint _value) public returns (bool){
        return _transfer(msg.sender, _to, _value);
    }

     
    function privateTransfer(address _to, uint _value) public onlyOwner returns (bool) {
         
        require(_to != address(0), "Address is wrong");

         
        require(_value <= balanceValue[owner].unlocked, "Unsufficient balance");
        require(balanceValue[_to].unlocked <= balanceValue[_to].unlocked + _value, "Overflow");

        uint previousBalances = balanceValue[owner].unlocked + balanceValue[_to].locked;

        balanceValue[owner].unlocked -= _value;
        balanceValue[_to].locked += _value;

        emit Transfer(msg.sender, _to, _value);

        assert(balanceValue[owner].unlocked + balanceValue[_to].locked == previousBalances);
        return true;
    }

     
    function multipleTransfer(address[] _tos, uint _nums, uint _submitBalance) public onlyOwner returns (bool){
         
        require(_tos.length == _nums, "Number of users who receives the token is not match");
        require(_submitBalance < 100000000 * WEDU_UNIT, "Too high submit balance");
        require(_nums < 256, "Two high number of users");
        require(_nums*_submitBalance <= balanceValue[owner].unlocked, "Unsufficient balance");

        balanceValue[owner].unlocked -= (_nums*_submitBalance);
        uint8 numIndex;
        for(numIndex=0; numIndex < _nums; numIndex++){
            require(balanceValue[_tos[numIndex]].unlocked == 0, "Already user has token");
            require(_tos[numIndex] != address(0));
            balanceValue[_tos[numIndex]].unlocked = _submitBalance;

            emit Transfer(owner, _tos[numIndex], _submitBalance);
        }
        return true;
    }

     
    function transferFrom(address _from, address _to, uint _value) public returns (bool){
         
        require(allowed[_from][msg.sender] <= balanceValue[_from].unlocked, "Unsufficient allowed balance");
        require(_value <= allowed[_from][msg.sender], "Unsufficient balance");

        allowed[_from][msg.sender] -= _value;
        return _transfer(_from, _to, _value);
    }

     
    function approve(address _spender, uint _value) public returns (bool){
         
        require(msg.sender != owner, "Owner uses the privateTransfer");
        require(_spender != address(0), "Address is wrong");
        require(_value <= balanceValue[msg.sender].unlocked, "Unsufficient balance");

         
        require(!blackList[msg.sender], "Sender in blacklist");
        require(!blackList[_spender], "Receiver in blacklist");

         
        require(allowed[msg.sender][_spender] == 0, "Already allowed token exists");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint){
         
        require(msg.sender == _owner || msg.sender == _spender);
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool){
         
        require(_spender != address(0), "Address is wrong");
        require(allowed[msg.sender][_spender] > 0, "Not approved until yet");

         
        require(!blackList[msg.sender], "Sender in blacklist");
        require(!blackList[_spender], "Receiver in blacklist");

        uint oldValue = allowed[msg.sender][_spender];
        require(_addedValue + oldValue <= balanceValue[msg.sender].unlocked, "Unsufficient balance");

        allowed[msg.sender][_spender] = _addedValue + oldValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _substractedValue) public returns (bool){
         
        require(_spender != address(0), "Address is wrong");
        require(allowed[msg.sender][_spender] > 0, "Not approved until yet");

         
        require(!blackList[msg.sender], "Sender in blacklist");
        require(!blackList[_spender], "Receiver in blacklist");

        uint oldValue = allowed[msg.sender][_spender];
        if (_substractedValue > oldValue){
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _substractedValue;
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function addBlackList(address _who) public onlyOwner {
        require(!blackList[_who], "Already, sender in blacklist");
        blackList[_who] = true;
    }

     
    function removalBlackList(address _who) public onlyOwner {
        require(blackList[_who], "Sender does not included in blacklist");
        blackList[_who] = false;
    }

     
    function tokenIssue(uint _value) public onlyOwner returns (bool) {
        require(totalSupplyValue <= totalSupplyValue + _value, "Overflow");
        uint oldTokenNum = totalSupplyValue;

        totalSupplyValue += _value;
        balanceValue[owner].unlocked += _value;

        emit ChangeNumberofToken(oldTokenNum, totalSupplyValue);
        return true;
    }

     
    function tokenBurn(uint _value) public onlyOwner returns (bool) {
        require(_value <= balanceValue[owner].unlocked, "Unsufficient balance");
        uint oldTokenNum = totalSupplyValue;

        totalSupplyValue -= _value;
        balanceValue[owner].unlocked -= _value;

        emit ChangeNumberofToken(oldTokenNum, totalSupplyValue);
        return true;
    }

     
    function ownerMigration (address _owner) public onlyOwner returns (address) {
        owner = _owner;
        return owner;
    }


     
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}