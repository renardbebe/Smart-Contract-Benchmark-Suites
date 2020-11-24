 

pragma solidity ^0.4.18;

 
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract IERC20Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
}

 
contract ERC20Token is IERC20Token {

    using SafeMath for uint256;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    modifier validAddress(address _address) {
        require(_address != 0x0);
        require(_address != address(this));
        _;
    }

    function _transfer(address _from, address _to, uint _value) internal validAddress(_to) {
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        _transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public validAddress(_spender) returns (bool success) {
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Owned {

    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier validAddress(address _address) {
        require(_address != 0x0);
        require(_address != address(this));
        _;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public validAddress(_newOwner) onlyOwner {
        require(_newOwner != owner);

        owner = _newOwner;
    }
}

 
contract BC2BToken is ERC20Token, Owned {

    using SafeMath for uint256;

    string public constant name = "BC2B";
    string public constant symbol = "BC2B";
    uint32 public constant decimals = 18;

     
    uint256 public initialSupply = 10000000;
     
    bool public fundingEnabled = true;
     
    uint256 public maxSaleToken;
     
    uint256 public totalSoldTokens;
     
    uint256 public totalProjectToken;
     
    address[] public wallets;
     
    bool public transfersEnabled = true; 

     
    uint[256] private nWallets;
     
    mapping(uint => uint) private iWallets;

    event Finalize();
    event DisableTransfers();

     
     
    function BC2BToken() public {

        initialSupply = initialSupply * 10 ** uint256(decimals);

        totalSupply = initialSupply;
         
         
         
         
         
         
         
        maxSaleToken = totalSupply.mul(60).div(100);
         
        balances[msg.sender] = maxSaleToken;
         
        wallets = [
                0xbED1c18C16868D7C34CEE770e10ae3175b4809Ce,
                0x6F8E76fd90153D4a73491044972a4edE1e216a26,
                0xB75D0fa5C82956CBA2724344B74261DC6dc74CDa
            ];
         
        nWallets[1] = uint(msg.sender);
        iWallets[uint(msg.sender)] = 1;

        for (uint index = 0; index < wallets.length; index++) {
            nWallets[2 + index] = uint(wallets[index]);
            iWallets[uint(wallets[index])] = index + 2;
        }
    }

    modifier validAddress(address _address) {
        require(_address != 0x0);
        require(_address != address(this));
        _;
    }

    modifier transfersAllowed() {
        require(transfersEnabled);
        _;
    }

    function transfer(address _to, uint256 _value) public transfersAllowed() returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed() returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function _transferProject(address _to, uint256 _value) private {
        balances[_to] = balances[_to].add(_value);

        Transfer(this, _to, _value);
    }

    function finalize() external onlyOwner {
        require(fundingEnabled);

        uint256 soldTokens = maxSaleToken;

        for (uint index = 1; index < nWallets.length; index++) {
            if (balances[address(nWallets[index])] > 0) {
                 
                 
                soldTokens = soldTokens.sub(balances[address(nWallets[index])]);

                Burn(address(nWallets[index]), balances[address(nWallets[index])]);
                 
                balances[address(nWallets[index])] = 0;
            }
        }

        totalSoldTokens = soldTokens;

         
         
         
         
         
        totalProjectToken = totalSoldTokens.mul(40).div(60);

        totalSupply = totalSoldTokens.add(totalProjectToken);
         
        _transferProject(0xB09Df01b913eb1975e16b408eDe9Ecb8360A1627, totalSupply.mul(40).div(100));

        fundingEnabled = false;

        Finalize();
    }

    function disableTransfers() external onlyOwner {
        require(transfersEnabled);

        transfersEnabled = false;

        DisableTransfers();
    }
}