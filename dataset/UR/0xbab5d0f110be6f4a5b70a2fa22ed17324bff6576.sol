 

pragma solidity ^0.4.17;

 

 
contract USDp {

    address public server;  
    address public populous;  

    uint256 public totalSupply;
    bytes32 public name; 
    uint8 public decimals; 
    bytes32 public symbol; 

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
     
     
    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );
     
    event Approval(
        address indexed _owner, 
        address indexed _spender, 
        uint256 _value
    );
    event EventMintTokens(bytes32 currency, address owner, uint amount);
    event EventDestroyTokens(bytes32 currency, address owner, uint amount);

     

    modifier onlyServer {
        require(isServer(msg.sender) == true);
        _;
    }

    modifier onlyServerOrOnlyPopulous {
        require(isServer(msg.sender) == true || isPopulous(msg.sender) == true);
        _;
    }

    modifier onlyPopulous {
        require(isPopulous(msg.sender) == true);
        _;
    }
     
    
     
    constructor ()
        public
    {
        populous = server = 0x63d509F7152769Ddf162eD048B83719fE1e31080;
        symbol = name = 0x55534470;  
        decimals = 6;  
         
        totalSupply = 0;  
    }

     
     
    function mint(uint amount, address owner) public onlyServerOrOnlyPopulous returns (bool success) {
        balances[owner] = safeAdd(balances[owner], amount);
        totalSupply = safeAdd(totalSupply, amount);
        emit EventMintTokens(symbol, owner, amount);
        return true;
    }

     
    function destroyTokens(uint amount) public onlyServerOrOnlyPopulous returns (bool success) {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        totalSupply = safeSub(totalSupply, amount);
        emit EventDestroyTokens(symbol, populous, amount);
        return true;
    }

     
    function destroyTokensFrom(uint amount, address from) public onlyServerOrOnlyPopulous returns (bool success) {
        require(balances[from] >= amount);
        balances[from] = safeSub(balances[from], amount);
        totalSupply = safeSub(totalSupply, amount);
        emit EventDestroyTokens(symbol, from, amount);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


     

     
    function isPopulous(address sender) public view returns (bool) {
        return sender == populous;
    }

         
    function changePopulous(address _populous) public {
        require(isServer(msg.sender) == true);
        populous = _populous;
    }

     
    
     
    function isServer(address sender) public view returns (bool) {
        return sender == server;
    }

     
    function changeServer(address _server) public {
        require(isServer(msg.sender) == true);
        server = _server;
    }


     

     
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

   
    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

   
    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
        return c;
    }
}