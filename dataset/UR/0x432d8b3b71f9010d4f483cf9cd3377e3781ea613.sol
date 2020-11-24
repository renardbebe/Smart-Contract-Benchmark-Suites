 

pragma solidity ^0.4.24;

contract ERC20Token{
     
    uint256 public totalSupply;
    
    function balanceOf(address _owner) public view returns (uint256 balance);
    
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned{
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
contract SafeMath {
     
    constructor() public{
    }

        
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

     
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a - b;
        assert(b <= a && c <= a);
        return c;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a * b;
        assert(a == 0 || (c / a) == b);
        return c;
    }

}

contract MANXERC20 is SafeMath, ERC20Token, Owned {
    string public constant name = 'MacroChain Computing And Networking System';                               
    string public constant symbol = 'MANX';                                   
    uint8 public constant decimals = 18;                                      
    uint256 public constant INITIAL_SUPPLY = 10000000000 * 10 ** uint256(decimals);
    uint256 public totalSupply;
    string public version = '2';
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    modifier rejectTokensToContract(address _to) {
        require(_to != address(this));
        _;
    }
    
    constructor() public {
        totalSupply = INITIAL_SUPPLY;                               
        balances[msg.sender] = INITIAL_SUPPLY;                      
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }
    
    function transfer(address _to, uint256 _value) rejectTokensToContract(_to) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) rejectTokensToContract(_to) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = safeSub(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function approveAndCallN(address _spender, uint256 _value, uint256 _extraNum) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

         
        if(!_spender.call(abi.encodeWithSelector(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,uint256)"))), msg.sender, _value, this, _extraNum))) { revert(); }
        return true;
    }
    
    function claimTokens(address _token) onlyOwner public {
        require(_token != address(0));

        ERC20Token token = ERC20Token(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
    }


}