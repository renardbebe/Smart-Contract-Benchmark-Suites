 

pragma solidity ^0.4.21;

contract SafeMath {

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

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

contract Mintable is Ownable {
    mapping(address => bool) minters;

    modifier onlyMinter {
        require(minters[msg.sender] == true);
        _;
    }

    function Mintable() public {
        adjustMinter(msg.sender, true);
    }

    function adjustMinter(address minter, bool canMint) public onlyOwner {
        minters[minter] = canMint;
    }

    function mint(address _to, uint256 _value) public;

}


contract AkilosToken is EIP20Interface, Ownable, SafeMath, Mintable {

    mapping(address => uint256) public balances;

    mapping(address => mapping(address => uint256)) public allowed;

    string public name = "Akilos";

    uint8 public decimals = 18;

    string public symbol = "ALS";

    function AkilosToken() public {
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowance, _value);

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

    function mint(address _to, uint256 _value) public onlyMinter {
        totalSupply = safeAdd(totalSupply, _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(0x0, _to, _value);
    }
}

contract AkilosIco is Ownable, SafeMath {

    uint256 public startBlock;

    uint256 public endBlock;

    uint256 public maxGasPrice;

    uint256 public exchangeRate;

    uint256 public maxSupply;

    mapping(address => uint256) public participants;

    AkilosToken public token;

    address private wallet;

    bool private initialised;

    modifier participationOpen  {
        require(block.number >= startBlock);
        require(block.number <= endBlock);
        _;
    }

    function initialise(address _wallet, uint256 _startBlock, uint256 _endBlock, uint256 _maxGasPrice, uint256 _exchangeRate, uint256 _maxSupply) public onlyOwner returns (address tokenAddress) {

        if (token == address(0x0)) {
            token = new AkilosToken();
            token.transferOwner(owner);
        }

        wallet = _wallet;
        startBlock = _startBlock;
        endBlock = _endBlock;
        maxGasPrice = _maxGasPrice;
        exchangeRate = _exchangeRate;
        maxSupply = _maxSupply;
        initialised = true;

        return token;
    }


    function() public payable {
        participate(msg.sender, msg.value);
    }

    function participate(address participant, uint256 value) internal participationOpen {
        require(participant != address(0x0));

        require(tx.gasprice <= maxGasPrice);

        require(initialised);

        uint256 totalSupply = token.totalSupply();
        require(totalSupply < maxSupply);

        uint256 tokenCount = safeMul(value, exchangeRate);
        uint256 remaining = 0;

        uint256 newTotalSupply = safeAdd(totalSupply, tokenCount);
        if (newTotalSupply > maxSupply) {
            uint256 newTokenCount = newTotalSupply - maxSupply;

            remaining = safeDiv(tokenCount - newTokenCount, exchangeRate);
            tokenCount = newTokenCount;
        }

        if (remaining > 0) {
            msg.sender.transfer(remaining);
            value = safeSub(value, remaining);
        }

        msg.sender.transfer(value);

 

        safeAdd(participants[participant], tokenCount);

        token.mint(msg.sender, tokenCount);
    }
}