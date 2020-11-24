 

contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract EIP20 is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  

    function EIP20(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
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
}
contract RGEToken is EIP20 {
    
     
    string public name = 'Rouge';
    string public symbol = 'RGE';
    uint8 public decimals = 6;
    
     
    address owner; 
    address public crowdsale;
    uint public endTGE;
    string public version = 'v1';
    uint256 public totalSupply = 1000000000 * 10**uint(decimals);
    uint256 public   reserveY1 =  300000000 * 10**uint(decimals);
    uint256 public   reserveY2 =  200000000 * 10**uint(decimals);

    modifier onlyBy(address _address) {
        require(msg.sender == _address);
        _;
    }
    
    constructor(uint _endTGE) EIP20 (totalSupply, name, decimals, symbol) public {
        owner = msg.sender;
        endTGE = _endTGE;
        crowdsale = address(0);
        balances[owner] = 0;
        balances[crowdsale] = totalSupply;
    }
    
    function startCrowdsaleY0(address _crowdsale) onlyBy(owner) public {
        require(_crowdsale != address(0));
        require(crowdsale == address(0));
        require(now < endTGE);
        crowdsale = _crowdsale;
        balances[crowdsale] = totalSupply - reserveY1 - reserveY2;
        balances[address(0)] -= balances[crowdsale];
        emit Transfer(address(0), crowdsale, balances[crowdsale]);
    }

    function startCrowdsaleY1(address _crowdsale) onlyBy(owner) public {
        require(_crowdsale != address(0));
        require(crowdsale == address(0));
        require(reserveY1 > 0);
        require(now >= endTGE + 31536000);  
        crowdsale = _crowdsale;
        balances[crowdsale] = reserveY1;
        balances[address(0)] -= reserveY1;
        emit Transfer(address(0), crowdsale, reserveY1);
        reserveY1 = 0;
    }

    function startCrowdsaleY2(address _crowdsale) onlyBy(owner) public {
        require(_crowdsale != address(0));
        require(crowdsale == address(0));
        require(reserveY2 > 0);
        require(now >= endTGE + 63072000);  
        crowdsale = _crowdsale;
        balances[crowdsale] = reserveY2;
        balances[address(0)] -= reserveY2;
        emit Transfer(address(0), crowdsale, reserveY2);
        reserveY2 = 0;
    }

     
    function endCrowdsale() onlyBy(owner) public {
        require(crowdsale != address(0));
        require(now > endTGE);
        reserveY2 += balances[crowdsale];
        emit Transfer(crowdsale, address(0), balances[crowdsale]);
        balances[address(0)] += balances[crowdsale];
        balances[crowdsale] = 0;
        crowdsale = address(0);
    }

     

    address public factory;

    function setFactory(address _factory) onlyBy(owner) public {
        factory = _factory;
    }

    function newCampaign(uint32 _issuance, uint256 _value) public {
        transfer(factory,_value);
        require(factory.call(bytes4(keccak256("createCampaign(address,uint32,uint256)")),msg.sender,_issuance,_value));
    }

    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Transfer(msg.sender, address(0), _value);
        emit Burn(msg.sender, _value);
        return true;
    }

}