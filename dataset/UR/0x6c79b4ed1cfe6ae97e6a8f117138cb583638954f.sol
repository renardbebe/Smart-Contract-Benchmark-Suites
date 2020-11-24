 

pragma solidity >=0.4.21 <0.6.0;

contract Owner {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes _extraData)
    external;
}

contract ERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    constructor (
        string _tokenName,
        string _tokenSymbol,
        uint8 _decimals,
        uint256 _totalSupply)
    public {
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value)
    internal {
        require(_to != 0x0);
        require(_from != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(
        address _to,
        uint256 _value)
    public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
    public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        
        allowance[_from][msg.sender] -= _value;
        
        _transfer(_from, _to, _value);
        
        return true;
    }

    function approve(
        address _spender,
        uint256 _value)
    public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        
        return true;
    }

    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes _extraData)
    public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(
        uint256 _value)
    public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(msg.sender, _value);

        return true;
    }

    function burnFrom(
        address _from,
        uint256 _value)
    public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(_from, _value);

        return true;
    }
}

contract Fyle is Owner, ERC20Token {
    
    mapping(address => string[]) private urls;
    event SendFyle(string _message);
    
    constructor (
        string _tokenName,
        string _tokenSymbol,
        uint8 _decimals,
        uint256 _totalSupply)
    ERC20Token(_tokenName, _tokenSymbol, _decimals, _totalSupply) public {
    }
    
    function mint(
        address _to, 
        uint256 _amount) 
    public onlyOwner returns (bool) {
        totalSupply = totalSupply + _amount;
        balanceOf[_to] = balanceOf[_to] + _amount;
        return true;
    }

    function sendFyle(
        address _from,
        address _to,
        string _url,
        string _message)
    onlyOwner public {
        urls[_to].push(_url);
        _transfer(_from, _to, 1);
        emit SendFyle(_message);
    }

    function getUrlAtIndexOf(
        address _address,
        uint256 _index)
    public view returns(string) {
        return urls[_address][_index];
    }

    function getUrlCountOf(
        address _address)
    public view returns(uint256) {
        return urls[_address].length;
    }

    function getMsgSender(
        )
    public view returns(address) {
        return msg.sender;
    }
}