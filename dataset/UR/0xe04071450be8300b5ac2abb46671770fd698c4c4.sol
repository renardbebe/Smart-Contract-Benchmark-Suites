 

pragma solidity >=0.4.0 <0.6.0;

 

contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        require( now > 1548979261 );
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract AtpcCoin is StandardToken {

     

    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'H1.2';
    uint256 public unitsOneEthCanBuy;      
    uint256 public totalEthInWei;
    address public fundsWallet;            
    address public owner;
    bool public isICOOver;
    bool public isICOActive;

    constructor() public {
        balances[msg.sender] = 190800000000000000000000000;
        totalSupply = 190800000000000000000000000;
        name = "ATPC Coin";
        decimals = 18;
        symbol = "ATPC";
        unitsOneEthCanBuy = 259;
        fundsWallet = msg.sender;
        owner = msg.sender;
        isICOOver = false;
        isICOActive = true;
    }

    modifier ownerFunc(){
      require(msg.sender == owner);
      _;
    }

    function transferAdmin(address _to, uint256 _value) ownerFunc returns (bool success) {
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    function close() public ownerFunc {
        selfdestruct(owner);
    }


    function changeICOState(bool isActive, bool isOver) public ownerFunc payable {
      isICOOver = isOver;
      isICOActive = isActive;
    }

    function changePrice(uint256 price) public ownerFunc payable {
      unitsOneEthCanBuy = price;
    }

    function() public payable {
        require(!isICOOver);
        require(isICOActive);

        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        emit Transfer(fundsWallet, msg.sender, amount);  

         
        fundsWallet.transfer(msg.value);
    }
    
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}