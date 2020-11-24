 

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

 
contract ViToken is ERC20Token, Owned {

    using SafeMath for uint256;

    string public constant name = "ViToken";
    string public constant symbol = "VIT";
    uint32 public constant decimals = 18;

     
    uint256 public initialSupply = 250000000;
     
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

     
     
    function ViToken() public {

        initialSupply = initialSupply * 10 ** uint256(decimals);

        totalSupply = initialSupply;
         
         
         
         
         
         
         
        maxSaleToken = totalSupply.mul(72).div(100);
         
        balances[msg.sender] = maxSaleToken;
         
        wallets = [
                0x787C3C7F5Cb7F4cAc0aAD6414F96de1A2ED994B0,  
                0xa6400BE140da2260db44a12b6c990BD02f08658a,  
                0xD697B23E5bD7dd817c2EE9DBF7C5cC7dc5354763,  
                0xA8500dADA9fA278B2F70D09FB8712C5983eD01bD,  
                0xd6e4CC2e33a0842c5070514C664E366561C23B48   
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

    modifier transfersAllowed(address _address) {
        if (fundingEnabled) {
            uint index = iWallets[uint(_address)];
            assert(index > 0);
        }

        require(transfersEnabled);
        _;
    }

    function transfer(address _to, uint256 _value) public transfersAllowed(msg.sender) returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed(_from) returns (bool) {
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

         
         
         
         
         
        totalProjectToken = totalSoldTokens.mul(28).div(72);

        totalSupply = totalSoldTokens.add(totalProjectToken);
         
         
        _transferProject(0xf1f815589e7B1Ba6cBfF04DCc1C2b898ECFfE4cb, totalSupply.mul(16).div(100));
         
        _transferProject(0x1c3a5aB190AF3f25aBfd797FDe49A3dB6f209B88, totalSupply.mul(10).div(100));
         
        _transferProject(0xe098854748CBC70f151fa555399365A42e360269, totalSupply.mul(2).div(100));

        fundingEnabled = false;

        Finalize();
    }

    function disableTransfers() external onlyOwner {
        require(transfersEnabled);

        transfersEnabled = false;

        DisableTransfers();
    }
}