 

pragma solidity 0.4.25;

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TokenParameters {
    uint256 internal initialSupply = 828179381000000000000000000;

     
    address internal constant initialTokenOwnerAddress = 0x68433cFb33A7Fdbfa74Ea5ECad0Bc8b1D97d82E9;
}

contract TANToken is Owned, TokenParameters {
     
    string public standard = 'ERC-20';
    string public name = 'Taklimakan';
    string public symbol = 'TAN';
    uint8 public decimals = 18;

     
    mapping (address => uint256) private _balances;    
    mapping (address => mapping (address => uint256)) private _allowed;

     
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Destruction(uint256 _amount);  
    event NewTANToken(address _token);

     
    uint256 public totalSupply = 0;
    address private _admin;

     
    constructor()
        public
    {
        owner = msg.sender;
        _admin = msg.sender;
        mintToken(TokenParameters.initialTokenOwnerAddress, TokenParameters.initialSupply);
        emit NewTANToken(address(this));
    }

    modifier onlyOwnerOrAdmin() {
        require((msg.sender == owner) || (msg.sender == _admin));
        _;
    }

     
    function setAdmin(address newAdmin)
        external
        onlyOwner
    {
        require(newAdmin != address(0));
        _admin = newAdmin;
    }

     
    function balanceOf(address addr)
        public
        view
        returns (uint256)
    {
        return _balances[addr];
    }

     
    function allowance(address tokenOwner, address tokenSpender)
        public
        view
        returns (uint256)
    {
        return _allowed[tokenOwner][tokenSpender];
    }

     
    function transfer(address to, uint256 value)
        public
        returns (bool)
    {
        require(_balances[msg.sender] >= value, "Insufficient balance for transfer");

         
         
        _balances[msg.sender] -= value;

         
        _balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

     
    function mintToken(address tokenOwner, uint256 amount)
        internal
    {
         
        _balances[tokenOwner] += amount;
        totalSupply += amount;

         
        emit Transfer(address(0), tokenOwner, amount);
    }

     
    function approve(address spender, uint256 value)
        public
        returns (bool)
    {
        require(_balances[msg.sender] >= value, "Insufficient balance for approval");

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool)
    {
         
        require(value <= _allowed[from][msg.sender]);
        require(_balances[from] >= value);

         
         
        _balances[from] -= value;
         
         
        _balances[to] += value;

         
         
        _allowed[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

     
    function() public {
    }

     
    function destroy(uint256 amount)
        external
        onlyOwnerOrAdmin
    {
        require(amount <= _balances[msg.sender]);

         
         
        totalSupply -= amount;
        _balances[msg.sender] -= amount;
        emit Destruction(amount);
    }

     
    function multiTransfer(address[] _recipients, uint[] _tokenAmounts)
        external
        onlyOwnerOrAdmin
    {
        uint256 totalAmount = 0;
        uint256 len = _recipients.length;
        uint256 i;

         
        for (i=0; i<len; i++)
        {
            totalAmount += _tokenAmounts[i];
        }
        require(_balances[msg.sender] >= totalAmount);
        
         
        _balances[msg.sender] -= totalAmount;

        for (i=0; i<len; i++)
        {
             
            _balances[_recipients[i]] += _tokenAmounts[i];

             
            emit Transfer(msg.sender, _recipients[i], _tokenAmounts[i]);
        }
    }

}