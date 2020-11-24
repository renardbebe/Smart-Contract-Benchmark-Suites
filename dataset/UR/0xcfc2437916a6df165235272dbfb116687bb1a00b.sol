 

pragma solidity ^0.4.23;

 



contract PlusCoin {
    address public owner;  
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;

    string public standard = 'PlusCoin 2.0';
    string public constant name = "PlusCoin";
    string public constant symbol = "PLCN";
    uint   public constant decimals = 18;
    uint public totalSupply;

    address public allowed_contract;

     
     
     
    
    event Sent(address from, address to, uint amount);
    event Buy(address indexed sender, uint eth, uint fbt);
    event Withdraw(address indexed sender, address to, uint eth);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
     

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    modifier onlyAllowedContract() {
        require(msg.sender == allowed_contract);
        _;
    }

     
     
     

     
    constructor() public {
        owner = msg.sender;
        totalSupply = 28272323624 * 1000000000000000000;
        balances[owner] = totalSupply;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
      if (newOwner != address(0)) {
        owner = newOwner;
      }
    }

    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }

 

	function setAllowedContract(address _contract_address) public
        onlyOwner
        returns (bool success)
    {
        allowed_contract = _contract_address;
        return true;
    }


    function withdrawEther(address _to) public 
        onlyOwner
    {
        _to.transfer(address(this).balance);
    }



     
    
    function transfer(address _to, uint256 _value) public
        returns (bool success) 
    {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public
        returns (bool success)
    {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public
        constant returns (uint256 remaining)
    {
      return allowed[_owner][_spender];
    }

}